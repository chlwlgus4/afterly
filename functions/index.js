const crypto = require("crypto");
const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const EMAIL_COOLDOWN_MS = 60 * 1000;
const EMAIL_WINDOW_MS = 24 * 60 * 60 * 1000;
const EMAIL_MAX_PER_WINDOW = 5;
const IP_COOLDOWN_MS = 5 * 1000;
const IP_WINDOW_MS = 60 * 60 * 1000;
const IP_MAX_PER_WINDOW = 30;
const PHONE_COOLDOWN_MS = 30 * 1000;
const PHONE_WINDOW_MS = 24 * 60 * 60 * 1000;
const PHONE_MAX_PER_WINDOW = 10;

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

async function enforceRateLimit({
  scope,
  key,
  now,
  cooldownMs,
  windowMs,
  maxPerWindow,
}) {
  const docRef = db.collection("auth_rate_limits").doc(`${scope}_${key}`);

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(docRef);
    const data = snapshot.data();

    if (!data) {
      tx.set(docRef, {
        scope,
        requestCount: 1,
        windowStartedAtMs: now,
        lastRequestedAtMs: now,
        updatedAtMs: now,
      });
      return;
    }

    const lastRequestedAtMs = data.lastRequestedAtMs || 0;
    if (now - lastRequestedAtMs < cooldownMs) {
      throw new HttpsError("resource-exhausted", "요청이 너무 빠릅니다.");
    }

    const windowStartedAtMs = data.windowStartedAtMs || now;
    const isNewWindow = now - windowStartedAtMs >= windowMs;
    const requestCount = isNewWindow ? 1 : (data.requestCount || 0) + 1;

    if (!isNewWindow && requestCount > maxPerWindow) {
      throw new HttpsError("resource-exhausted", "요청 한도를 초과했습니다.");
    }

    tx.set(
      docRef,
      {
        scope,
        requestCount,
        windowStartedAtMs: isNewWindow ? now : windowStartedAtMs,
        lastRequestedAtMs: now,
        updatedAtMs: now,
      },
      { merge: true }
    );
  });
}

function normalizePhone(rawPhone) {
  if (typeof rawPhone !== "string") return "";

  const trimmed = rawPhone.trim();
  if (!trimmed) return "";

  // Keep leading + and strip all other non-digit characters.
  const hasPlus = trimmed.startsWith("+");
  const digits = trimmed.replace(/\D/g, "");
  if (!digits) return "";

  if (hasPlus) return `+${digits}`;
  if (digits.startsWith("00")) return `+${digits.substring(2)}`;
  if (digits.startsWith("0")) return `+82${digits.substring(1)}`; // KR local fallback
  return `+${digits}`;
}

function isLikelyE164(phone) {
  return /^\+[1-9]\d{7,14}$/.test(phone);
}

async function sendPasswordResetOob({ webApiKey, email }) {
  const endpoint =
    `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${webApiKey}`;

  let response;
  try {
    response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        requestType: "PASSWORD_RESET",
        email,
      }),
    });
  } catch (error) {
    logger.error("Identity Toolkit call failed", error);
    throw new HttpsError("unavailable", "인증 서버 연결에 실패했습니다.");
  }

  if (!response.ok) {
    const errorPayload = await response.json().catch(() => ({}));
    const apiErrorCode = errorPayload?.error?.message || "UNKNOWN";

    // 계정 존재 여부 노출 방지
    if (apiErrorCode === "EMAIL_NOT_FOUND") {
      return;
    }
    if (apiErrorCode === "TOO_MANY_ATTEMPTS_TRY_LATER") {
      throw new HttpsError(
        "resource-exhausted",
        "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
      );
    }

    logger.error("sendOobCode failed", { apiErrorCode });
    throw new HttpsError("internal", "비밀번호 재설정 요청 처리에 실패했습니다.");
  }
}

async function verifyPhoneSmsCode({ webApiKey, verificationId, smsCode }) {
  const endpoint =
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=${webApiKey}`;

  let response;
  try {
    response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sessionInfo: verificationId,
        code: smsCode,
        returnSecureToken: false,
      }),
    });
  } catch (error) {
    logger.error("signInWithPhoneNumber call failed", error);
    throw new HttpsError("unavailable", "인증 서버 연결에 실패했습니다.");
  }

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const apiErrorCode = payload?.error?.message || "UNKNOWN";
    if (
      apiErrorCode === "INVALID_CODE" ||
      apiErrorCode === "INVALID_SESSION_INFO" ||
      apiErrorCode === "SESSION_EXPIRED"
    ) {
      throw new HttpsError("invalid-argument", "인증번호가 올바르지 않거나 만료되었습니다.");
    }
    if (apiErrorCode === "TOO_MANY_ATTEMPTS_TRY_LATER") {
      throw new HttpsError(
        "resource-exhausted",
        "인증 시도가 너무 많습니다. 잠시 후 다시 시도해주세요."
      );
    }
    logger.error("signInWithPhoneNumber failed", { apiErrorCode });
    throw new HttpsError("internal", "휴대폰 인증 검증에 실패했습니다.");
  }

  const verifiedPhone = normalizePhone(payload?.phoneNumber || "");
  if (!isLikelyE164(verifiedPhone)) {
    throw new HttpsError("internal", "휴대폰 인증 결과를 확인할 수 없습니다.");
  }

  return verifiedPhone;
}

exports.requestPasswordReset = onCall(
  {
    region: "asia-northeast3",
    enforceAppCheck: true,
    secrets: ["AFTERLY_WEB_API_KEY"],
  },
  async (request) => {
    logger.warn("Deprecated requestPasswordReset endpoint called", {
      ip: request.rawRequest.ip || "unknown",
    });
    throw new HttpsError(
      "failed-precondition",
      "보안 정책이 변경되었습니다. 휴대폰 본인인증 기반 재설정 경로를 사용해주세요."
    );
  }
);

exports.requestPasswordResetWithPhone = onCall(
  {
    region: "asia-northeast3",
    enforceAppCheck: true,
    secrets: ["AFTERLY_WEB_API_KEY"],
  },
  async (request) => {
    const rawEmail = request.data?.email;
    const rawPhoneNumber = request.data?.phoneNumber;
    const rawVerificationId = request.data?.verificationId;
    const rawSmsCode = request.data?.smsCode;

    const email =
      typeof rawEmail === "string" ? rawEmail.trim().toLowerCase() : "";
    const phoneNumber = normalizePhone(rawPhoneNumber);
    const verificationId =
      typeof rawVerificationId === "string" ? rawVerificationId.trim() : "";
    const smsCode = typeof rawSmsCode === "string" ? rawSmsCode.trim() : "";

    if (!EMAIL_REGEX.test(email)) {
      throw new HttpsError("invalid-argument", "유효한 이메일 형식이 아닙니다.");
    }
    if (!isLikelyE164(phoneNumber)) {
      throw new HttpsError("invalid-argument", "유효한 휴대폰 번호 형식이 아닙니다.");
    }
    if (!verificationId || !smsCode) {
      throw new HttpsError("invalid-argument", "휴대폰 인증 정보가 필요합니다.");
    }

    const webApiKey = process.env.AFTERLY_WEB_API_KEY;
    if (!webApiKey) {
      throw new HttpsError(
        "failed-precondition",
        "AFTERLY_WEB_API_KEY 시크릿이 설정되지 않았습니다."
      );
    }

    const now = Date.now();
    const emailHash = sha256(email);
    const phoneHash = sha256(phoneNumber);
    const ipAddress = request.rawRequest.ip || "unknown";
    const ipHash = sha256(ipAddress);

    await enforceRateLimit({
      scope: "password_reset_email",
      key: emailHash,
      now,
      cooldownMs: EMAIL_COOLDOWN_MS,
      windowMs: EMAIL_WINDOW_MS,
      maxPerWindow: EMAIL_MAX_PER_WINDOW,
    });

    await enforceRateLimit({
      scope: "password_reset_phone",
      key: phoneHash,
      now,
      cooldownMs: PHONE_COOLDOWN_MS,
      windowMs: PHONE_WINDOW_MS,
      maxPerWindow: PHONE_MAX_PER_WINDOW,
    });

    await enforceRateLimit({
      scope: "password_reset_ip",
      key: ipHash,
      now,
      cooldownMs: IP_COOLDOWN_MS,
      windowMs: IP_WINDOW_MS,
      maxPerWindow: IP_MAX_PER_WINDOW,
    });

    const verifiedPhone = await verifyPhoneSmsCode({
      webApiKey,
      verificationId,
      smsCode,
    });

    if (verifiedPhone !== phoneNumber) {
      throw new HttpsError(
        "permission-denied",
        "입력한 휴대폰 번호와 인증 결과가 일치하지 않습니다."
      );
    }

    let userRecord = null;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (error) {
      if (error?.code === "auth/user-not-found") {
        // 계정 존재 여부 노출 방지
        return { ok: true };
      }
      logger.error("getUserByEmail failed", error);
      throw new HttpsError("internal", "계정 조회 중 오류가 발생했습니다.");
    }

    const enrolledFactors = userRecord.multiFactor?.enrolledFactors || [];
    const hasMatchingMfaPhone = enrolledFactors.some((factor) => {
      if (factor.factorId !== "phone") return false;
      return normalizePhone(factor.phoneNumber || "") === phoneNumber;
    });

    if (!hasMatchingMfaPhone) {
      throw new HttpsError(
        "permission-denied",
        "계정 정보와 휴대폰 인증 정보가 일치하지 않습니다."
      );
    }

    await sendPasswordResetOob({ webApiKey, email });
    return { ok: true };
  }
);
