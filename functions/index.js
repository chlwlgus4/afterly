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

exports.requestPasswordReset = onCall(
  {
    region: "asia-northeast3",
    enforceAppCheck: true,
    secrets: ["AFTERLY_WEB_API_KEY"],
  },
  async (request) => {
    const rawEmail = request.data?.email;
    const email = typeof rawEmail === "string" ? rawEmail.trim().toLowerCase() : "";

    if (!EMAIL_REGEX.test(email)) {
      throw new HttpsError("invalid-argument", "유효한 이메일 형식이 아닙니다.");
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
      scope: "password_reset_ip",
      key: ipHash,
      now,
      cooldownMs: IP_COOLDOWN_MS,
      windowMs: IP_WINDOW_MS,
      maxPerWindow: IP_MAX_PER_WINDOW,
    });

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
        return { ok: true };
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

    return { ok: true };
  }
);
