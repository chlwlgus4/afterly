# Firebase 소셜 로그인 설정 가이드

## ✅ 이미 완료된 작업

- Firebase 프로젝트 생성 (`afterly-app`)
- Authentication, Firestore, Storage 활성화
- Firebase SDK 설정 (iOS + Android)
- 앱 코드에 소셜 로그인 구현 완료

## 📱 Google Sign-In 설정

### 1. Firebase Console 설정

1. [Firebase Console](https://console.firebase.google.com/project/afterly-app/authentication/providers) 접속
2. Authentication → Sign-in method → Google 클릭
3. **사용 설정** 토글을 ON으로 변경
4. 프로젝트 공개용 이름: `Afterly`
5. 프로젝트 지원 이메일 선택
6. **저장** 클릭

### 2. iOS 추가 설정

Google Sign-In이 iOS에서 작동하려면 추가 설정이 필요합니다:

#### 방법 1: Firebase Console에서 자동 다운로드
1. Firebase Console → 프로젝트 설정 → iOS 앱
2. **GoogleService-Info.plist 다운로드** 클릭
3. 다운로드한 파일을 `ios/Runner/GoogleService-Info.plist`로 교체
4. `REVERSED_CLIENT_ID` 값을 확인

#### 방법 2: Google Cloud Console에서 OAuth 클라이언트 생성
1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=afterly-app) 접속
2. **사용자 인증 정보 만들기** → **OAuth 클라이언트 ID**
3. 애플리케이션 유형: **iOS**
4. 번들 ID: `com.afterly.afterly`
5. 생성 후 클라이언트 ID 복사

#### Info.plist URL Scheme 추가

`ios/Runner/Info.plist` 파일에 다음 추가:

```xml
<!-- Google Sign-In URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- GoogleService-Info.plist의 REVERSED_CLIENT_ID 값 -->
            <string>com.googleusercontent.apps.189389362900-xxxxxxxx</string>
        </array>
    </dict>
</array>
```

**주의**: `REVERSED_CLIENT_ID` 값은 GoogleService-Info.plist에서 확인하거나, Google Cloud Console에서 생성한 클라이언트 ID를 역순으로 작성해야 합니다.

### 3. Android 설정

Android는 이미 `google-services.json`이 설정되어 있으므로 추가 작업이 필요 없습니다. ✅

### 4. 테스트

```bash
flutter run
```

로그인 화면에서 **Google로 로그인** 버튼을 눌러 테스트합니다.

---

## 🍎 Apple Sign-In 설정 (iOS Only)

### 1. Apple Developer 계정 필요

Apple Sign-In은 유료 Apple Developer 계정이 필요합니다.

### 2. Xcode에서 Capability 추가

1. Xcode에서 프로젝트 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Runner 타겟 선택 → **Signing & Capabilities** 탭

3. **+ Capability** 클릭 → **Sign in with Apple** 추가

4. Bundle Identifier가 `com.afterly.afterly`인지 확인

5. Signing 설정:
   - **Automatically manage signing** 체크
   - Team 선택 (Apple Developer 계정)

### 3. Firebase Console에서 Apple 활성화

1. [Firebase Console](https://console.firebase.google.com/project/afterly-app/authentication/providers) 접속
2. Authentication → Sign-in method → Apple 클릭
3. **사용 설정** 토글을 ON으로 변경
4. **저장** 클릭

### 4. 테스트

```bash
flutter run
```

iOS 기기나 시뮬레이터에서 **Apple로 로그인** 버튼을 눌러 테스트합니다.

---

## 🔒 Firestore Security Rules

현재는 테스트 모드로 설정되어 있습니다. 프로덕션 배포 전 보안 규칙을 업데이트해야 합니다:

### Firebase Console → Firestore Database → Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 인증된 사용자만 자신의 데이터 접근 가능
    match /customers/{customerId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.userId;
    }

    match /shooting_sessions/{sessionId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### Firebase Console → Storage → Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      // 인증된 사용자만 자신의 폴더에 접근 가능
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

---

## 🧪 최종 테스트 체크리스트

### 기본 기능
- [ ] 이메일/비밀번호 회원가입
- [ ] 이메일/비밀번호 로그인
- [ ] 로그아웃
- [ ] 고객 추가
- [ ] Before 촬영
- [ ] After 촬영
- [ ] 이미지 Firebase Storage에 업로드 확인
- [ ] 비교 화면 이미지 표시
- [ ] 분석 화면 표시

### 소셜 로그인
- [ ] Google 로그인 (iOS)
- [ ] Google 로그인 (Android)
- [ ] Apple 로그인 (iOS only)

### 데이터 확인
- [ ] Firebase Console → Firestore에서 고객 데이터 확인
- [ ] Firebase Console → Storage에서 이미지 확인
- [ ] Firebase Console → Authentication에서 사용자 확인

---

## 📞 문제 해결

### Google Sign-In 오류

**오류**: "Sign in with Google failed"
- GoogleService-Info.plist가 최신 버전인지 확인
- Info.plist의 URL Scheme가 올바른지 확인
- Firebase Console에서 Google Sign-In이 활성화되어 있는지 확인

### Apple Sign-In 오류

**오류**: "Apple Sign-In is only available on iOS"
- iOS 기기나 시뮬레이터에서만 사용 가능
- Xcode에서 Sign in with Apple capability가 추가되어 있는지 확인

### 이미지 업로드 실패

**오류**: "Failed to upload image"
- 인터넷 연결 확인
- Firebase Storage Rules 확인
- 사용자가 로그인되어 있는지 확인

---

## 🎉 완료!

모든 설정이 완료되면 Afterly 앱의 모든 기능을 사용할 수 있습니다!
