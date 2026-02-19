# Afterly

Afterly는 피부 관리샵용 Before/After 촬영·비교·분석 앱입니다.  
촬영 시 얼굴 가이드와 안정성 조건을 확인하고, 전/후 이미지를 비교/분석해 변화를 기록합니다.

## 주요 기능

- 고객별 촬영 세션 관리
- 카메라 얼굴 가이드(각도/거리/안정성) + 자동 촬영 카운트다운
- Before/After 비교 모드
  - 토글
  - 슬라이더
  - 오버레이
- 온디바이스 분석(턱 라인, 좌우 균형, 피부 톤 균일도)
- 이미지 저장(비교본/단일본)
- Firebase Auth/Firestore/Storage 연동
- 소셜 로그인(Google, Apple)
- 로그인 보안 강화
  - SMS 기반 2단계 인증(MFA) 등록/로그인
  - App Check + Functions 기반 비밀번호 재설정 보호

## 최근 추가 기능

- 자동 정렬/보정 파이프라인
  - After 업로드 완료 시 Before/After 정렬본 생성
  - 얼굴 기울기 보정(roll), 얼굴 중심 정사각 크롭, 512x512 정규화
  - 조명 차이 완화를 위한 완만한 톤 정규화
  - `alignedBeforeUrl` / `alignedAfterUrl` 저장
- 비교/분석/미리보기/저장에서 정렬본 우선 사용(없으면 원본 fallback)

## 기술 스택

- Flutter 3.x / Dart 3.x
- Riverpod, go_router
- camera, google_mlkit_face_detection, sensors_plus
- image, http, path_provider
- Firebase: Auth, Firestore, Storage

## 실행 방법

1. 의존성 설치

```bash
flutter pub get
```

2. Firebase 설정 확인

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

3. 앱 실행

```bash
flutter run
```

## 문서

- 앱 전체 가이드: `docs/APP_GUIDE.md`
- 분석 기능 상세: `docs/ANALYSIS_FEATURE.md`
- Firebase/소셜 로그인 설정: `docs/FIREBASE_SETUP.md`

## 프로젝트 구조 (요약)

```text
lib/
├── screens/      # 화면(UI)
├── services/     # 분석/정렬/업로드 등 비즈니스 로직
├── models/       # 데이터 모델
├── providers/    # 상태관리(Riverpod)
└── utils/        # 공통 유틸/가이드 필터
```
