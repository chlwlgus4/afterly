# Afterly - 앱 전체 가이드

## 개요

Afterly는 피부 관리샵에서 고객의 **Before/After 사진을 촬영하고 비교 분석**하는 앱입니다.
동일한 조건(각도, 거리, 안정성)에서 촬영하여 관리 전후를 정확하게 비교할 수 있습니다.

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.29.2 (Dart 3.7.2) |
| 플랫폼 | iOS 15.5+, Android |
| 상태관리 | Riverpod (flutter_riverpod) |
| 네비게이션 | go_router |
| 데이터베이스 | SQLite (sqflite) - 로컬 전용 |
| 얼굴 감지 | google_mlkit_face_detection |
| 카메라 | camera 패키지 |
| 흔들림 감지 | sensors_plus (가속도계) |
| 이미지 분석 | image 패키지 (Dart) |

---

## 화면 구성

### 1. 홈 화면 (`/`)

- **고객 목록**: 등록된 고객 카드 리스트
- **고객 카드**: 이름, 최근 촬영일, 촬영 횟수
- **After 촬영 대기 알림**: Before만 촬영된 세션이 있으면 주황색 알림 배지 표시
- **고객 상세**: 카드 탭 → 바텀시트 (새 촬영, 이전 기록 열기)
- **새 고객**: FAB 버튼으로 고객 추가 → 바로 촬영 시작

### 2. 카메라 화면 (`/camera/:customerId/:sessionId/:type`)

- **전/후면 카메라 전환**: 우상단 카메라 전환 버튼
- **얼굴 가이드**: 사람 얼굴 형태의 베지어 곡선 가이드
  - 글로우 효과 + 두꺼운 외곽선 (3.0~3.5px)
  - 보조선: 중앙 세로선, 눈 위치 가로선, 코 위치 가로선
  - 상태별 색상 변화: 빨간색(얼굴 미감지) → 주황색(조정 필요) → 초록색(준비 완료)
- **자동 촬영**: canShoot 상태 1초 유지 → 3초 카운트다운 → 자동 촬영
- **수동 촬영**: 하단 셔터 버튼 (canShoot 상태일 때만 활성화)
- **촬영 완료 다이얼로그**: 재촬영 / 나중에 After 촬영(Before만) / 다음 단계

### 3. 비교 화면 (`/comparison/:sessionId`)

- **3가지 비교 모드** (상단 버튼으로 순환):
  - **토글 모드**: 탭하여 Before/After 전환
  - **슬라이더 모드**: 좌우 드래그로 Before/After 경계 이동
  - **오버레이 모드**: Before를 After 위에 반투명 겹침 (투명도 슬라이더)
- **가이드라인 오버레이**: 카메라와 동일한 얼굴 가이드 표시 (초록색)
- **Heatmap**: 변화 부위를 색상으로 시각화 (파→초→빨)
- **분석 버튼**: 하단 "분석하기" 버튼으로 이미지 분석 실행

### 4. 분석 결과 화면 (`/analysis/:sessionId`)

- **이미지 미리보기**: Before/After 나란히 표시
- **분석 요약**: 전체 변화를 요약한 텍스트
- **상세 점수 카드**: 원형 프로그래스 + 점수 + 설명
  - 얼굴 라인 변화 (턱 라인)
  - 좌우 균형 (대칭성)
  - 피부 톤 균일도
- **네비게이션**: 비교 다시보기 / 홈으로

---

## 촬영 조건 (Face Guide Filter)

얼굴 감지 후 EMA(지수이동평균) 스무딩 + 히스테리시스로 안정적 판정:

| 조건 | ON 임계값 | OFF 임계값 | 설명 |
|------|-----------|------------|------|
| Roll (좌우 기울기) | ≤ 3° | ≥ 4.5° | 고개 똑바로 |
| Yaw (좌우 회전) | ≤ 5° | ≥ 7° | 정면 응시 |
| Pitch (상하 기울기) | ≤ 5° | ≥ 7° | 고개 수평 |
| Face Ratio | 0.30~0.45 | - | 적정 거리 |
| 밝기 | 80~200 | - | 적정 조명 |
| 안정성 | 가속도 변화 < 1.5 | - | 흔들림 없음 |

- **EMA 스무딩**: alpha = 0.2 (급격한 값 변화 방지)
- **히스테리시스**: ON/OFF 임계값 분리로 상태 깜빡임 방지
- **자동 촬영**: 모든 조건 충족 1초 유지 → 3초 카운트다운

---

## 데이터 구조

### Customer (고객)
```
id: INTEGER (PK)
name: TEXT
createdAt: TEXT (ISO8601)
lastShootingAt: TEXT (ISO8601, nullable)
```

### ShootingSession (촬영 세션)
```
id: INTEGER (PK)
customerId: INTEGER (FK → customers)
beforeImagePath: TEXT (nullable)
afterImagePath: TEXT (nullable)
jawlineScore: REAL (nullable)
symmetryScore: REAL (nullable)
skinToneScore: REAL (nullable)
summary: TEXT (nullable)
createdAt: TEXT (ISO8601)
```

---

## 이미지 저장

- **저장 위치**: `앱 Documents 디렉토리/images/`
- **파일명 형식**: `{before|after}_{sessionId}_{timestamp}.jpg`
- **저장 방식**: 바이트 직접 쓰기 (`readAsBytes` → `writeAsBytes`)
- **저장 검증**: 파일 존재 + 파일 크기 > 0 확인

---

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── app.dart                     # GoRouter + MaterialApp 테마
├── models/
│   ├── customer.dart            # 고객 모델
│   └── shooting_session.dart    # 촬영 세션 모델
├── providers/
│   ├── database_provider.dart   # DatabaseService Provider
│   ├── customer_provider.dart   # 고객 목록 AsyncNotifier
│   └── session_provider.dart    # 세션 목록 FamilyAsyncNotifier
├── services/
│   ├── database_service.dart    # SQLite CRUD
│   └── image_analysis_service.dart  # 이미지 분석 (Isolate)
├── screens/
│   ├── home/
│   │   └── home_screen.dart     # 홈 (고객 목록)
│   ├── camera/
│   │   ├── camera_screen.dart   # 카메라 촬영
│   │   └── widgets/
│   │       └── face_guide_overlay.dart  # 얼굴 가이드 UI
│   ├── comparison/
│   │   └── comparison_screen.dart  # 전후 비교
│   └── analysis/
│       └── analysis_screen.dart    # 분석 결과
└── utils/
    ├── constants.dart           # 색상, 텍스트 스타일
    ├── face_guide_filter.dart   # EMA + 히스테리시스 필터
    ├── face_guide_metrics.dart  # 가이드 메트릭 데이터 클래스
    └── face_guide_painter.dart  # 공용 얼굴 가이드 페인터
```

---

## 빌드 & 실행

### iOS
```bash
flutter build ios --no-codesign
# 또는 Xcode에서 직접 실행 (디바이스 필요)
```
- 최소 배포 타겟: iOS 15.5
- Info.plist 권한: 카메라, 모션, 로컬 네트워크

### Android
```bash
flutter build apk
# 또는
flutter run
```
- AndroidManifest.xml에 CAMERA 권한 설정 필요
