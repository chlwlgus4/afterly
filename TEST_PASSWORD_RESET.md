# 비밀번호 찾기 이메일 발송 테스트 가이드

## ✅ 구현 확인

비밀번호 찾기 기능은 **Firebase Auth**를 사용하여 구현되어 있습니다.

- ✅ `AuthService.sendPasswordResetEmail()` 구현됨
- ✅ Firebase Auth의 `sendPasswordResetEmail()` 호출
- ✅ 에러 핸들링 포함
- ✅ UI 플로우 완성

---

## 🧪 테스트 방법

### 1단계: Firebase Console 확인

1. [Firebase Console - Authentication](https://console.firebase.google.com/project/afterly-app/authentication/users) 접속
2. 테스트할 이메일 계정이 존재하는지 확인
3. 없으면 먼저 앱에서 회원가입 진행

### 2단계: 앱에서 테스트

```bash
flutter run
```

1. 로그인 화면에서 **"비밀번호 찾기"** 클릭
2. 가입한 이메일 주소 입력
3. **"재설정 링크 보내기"** 클릭
4. 성공 메시지 확인: "이메일을 확인해주세요!"

### 3단계: 이메일 수신 확인

**확인 위치 (순서대로):**
1. 📧 받은편지함
2. 📧 스팸/정크 메일
3. 📧 프로모션 탭 (Gmail의 경우)
4. 📧 소셜 탭 (Gmail의 경우)

**발신자:**
- `noreply@afterly-app.firebaseapp.com`
- 또는 Firebase 기본 발신자

**제목:**
- "Reset your password for Afterly" (영문)
- 또는 Firebase Console에서 설정한 제목

---

## 🔧 문제 해결

### 이메일이 안 오는 경우

#### 1. 이메일 주소 확인
```
❌ 잘못된 경우: test@test (도메인 없음)
✅ 올바른 경우: test@test.com
```

#### 2. Firebase Console에서 사용자 확인
- [Authentication - Users](https://console.firebase.google.com/project/afterly-app/authentication/users)
- 해당 이메일 계정이 목록에 있는지 확인

#### 3. 계정 상태 확인
- 계정이 비활성화(disabled)되지 않았는지 확인
- "Disabled" 표시가 있으면 활성화 필요

#### 4. Firebase 이메일 설정 확인

[Firebase Console - Authentication - Templates](https://console.firebase.google.com/project/afterly-app/authentication/emails)

**Password reset 템플릿 확인:**
- ✅ 활성화되어 있는지
- ✅ 발신자 이메일 설정 확인
- ✅ "Test" 버튼으로 테스트 이메일 발송 가능

#### 5. 앱 로그 확인

터미널에서 앱 실행 중 에러 확인:
```bash
flutter run
```

이메일 발송 시 에러가 있으면 SnackBar에 표시됨:
- "사용자를 찾을 수 없습니다"
- "네트워크 연결을 확인해주세요"
- 기타 Firebase 에러 메시지

---

## 📧 이메일 템플릿 커스터마이징 (선택사항)

### Firebase Console 설정

1. [Authentication - Templates](https://console.firebase.google.com/project/afterly-app/authentication/emails)
2. **Password reset** 클릭
3. 수정 가능한 항목:
   - **Sender name**: 발신자 이름 (예: "Afterly")
   - **Sender email**: 발신자 이메일
   - **Subject**: 이메일 제목
   - **Email body**: 이메일 본문

### 한글 템플릿 예시

**제목:**
```
Afterly 비밀번호 재설정
```

**본문:**
```
안녕하세요,

Afterly 계정의 비밀번호 재설정을 요청하셨습니다.

아래 링크를 클릭하여 새 비밀번호를 설정하세요:

%LINK%

이 링크는 1시간 동안 유효합니다.

비밀번호 재설정을 요청하지 않으셨다면 이 이메일을 무시하셔도 됩니다.

감사합니다.
Afterly 팀
```

---

## ✅ 정상 작동 확인 체크리스트

- [ ] Firebase Console에 테스트 계정 존재
- [ ] 앱에서 "비밀번호 찾기" 화면 접근 가능
- [ ] 이메일 입력 후 "재설정 링크 보내기" 클릭
- [ ] 성공 메시지 표시됨
- [ ] 이메일 수신함에서 재설정 이메일 확인
- [ ] 이메일 링크 클릭 → Firebase 비밀번호 재설정 페이지 열림
- [ ] 새 비밀번호 설정 가능
- [ ] 새 비밀번호로 로그인 성공

---

## 🚨 빠른 테스트

**즉시 확인하려면:**

1. Firebase Console에서 직접 테스트:
   - [Templates](https://console.firebase.google.com/project/afterly-app/authentication/emails)
   - Password reset 템플릿
   - **"Send test email"** 버튼 클릭
   - 본인 이메일 입력
   - 이메일 수신 확인

2. 수신되면 → Firebase 설정 정상 ✅
3. 수신 안되면 → Firebase 이메일 설정 문제

---

## 💡 참고

Firebase는 자동으로 다음을 처리합니다:
- ✅ 이메일 발송
- ✅ 보안 링크 생성
- ✅ 링크 만료 처리 (1시간)
- ✅ 비밀번호 재설정 페이지 제공

앱은 단순히 Firebase에 이메일 발송을 요청하기만 하면 됩니다.
