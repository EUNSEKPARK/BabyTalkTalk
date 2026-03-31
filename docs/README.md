# ChatBabyTime - 채팅으로 끝나는 육아 기록

AI 기반 음성/텍스트 입력으로 육아 기록을 자동 분류하는 차세대 육아 앱

## 핵심 기능

### 스마트 텍스트 입력
자연어로 입력하면 AI가 자동 파싱하여 기록합니다.
- "분유 120ml 먹었어" → 수유(분유) 120ml 기록
- "아기 방금 잠들었어" → 수면(잠듦) 기록
- "기저귀 갈았어 응가" → 기저귀(대변) 기록
- "체온 37.5도" → 건강(체온 37.5°C) 기록
- "오후 2시에 이유식" → 수유(이유식) 오후 2시 기록

### 핸즈프리 음성 기록
speech_to_text를 활용한 한국어 음성 인식으로 손을 쓰지 않고도 기록 가능

### 빠른 액션 칩
자주 사용하는 기록을 원터치로 입력

### 대시보드
- 오늘의 수유/수면/기저귀 횟수 요약
- 주간 활동 차트 (fl_chart)
- 마지막 기록 타이머

## 기술 스택

| 구분 | 기술 |
|------|------|
| Framework | Flutter 3.x |
| State Management | Provider |
| Local DB | Hive |
| Speech Recognition | speech_to_text |
| NLP | 한국어 규칙 기반 파서 |
| Charts | fl_chart |

## 시작하기

```bash
# 의존성 설치
flutter pub get

# Hive 코드 생성 (이미 생성됨)
# flutter pub run build_runner build

# 앱 실행
flutter run
```

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── models/
│   ├── baby_record.dart         # 육아 기록 모델
│   ├── baby_record.g.dart       # Hive TypeAdapter (생성됨)
│   ├── baby_profile.dart        # 아기 프로필 모델
│   └── baby_profile.g.dart      # Hive TypeAdapter (생성됨)
├── services/
│   ├── nlp_parser.dart          # 한국어 NLP 파서 (핵심!)
│   ├── record_service.dart      # 데이터 관리 서비스
│   └── speech_service.dart      # 음성 인식 서비스
├── screens/
│   ├── home_screen.dart         # 메인 화면 (타임라인)
│   ├── dashboard_screen.dart    # 대시보드 (통계)
│   ├── record_detail_screen.dart # 기록 상세/수정
│   └── profile_setup_screen.dart # 아기 프로필 설정
├── widgets/
│   ├── smart_input_bar.dart     # 스마트 입력바
│   ├── record_card.dart         # 기록 카드
│   ├── quick_action_chips.dart  # 빠른 액션 칩
│   └── today_summary_card.dart  # 오늘 요약 카드
└── utils/
    ├── app_theme.dart           # 앱 테마/디자인 시스템
    └── time_utils.dart          # 시간 유틸리티
```

## NLP 파서 지원 입력 패턴

### 시간 인식
- "방금", "지금" → 현재 시각
- "30분 전" → 30분 전
- "2시간 전" → 2시간 전
- "오후 3시 30분" → 15:30
- "14:00" → 14:00

### 수유 키워드
분유, 모유, 이유식, 간식, ml, 먹, 수유 등

### 수면 키워드
잠, 자, 수면, 깨, 일어나, 낮잠 등

### 기저귀 키워드
기저귀, 응가, 똥, 소변, 대변 등

### 건강 키워드
체온, 열, 약, 병원 등

## 향후 로드맵

- [ ] 위젯 (홈 화면에서 바로 기록)
- [ ] 알림 (다음 수유 시간 예측)
- [ ] 클라우드 백업
- [ ] 다인 공동 육아 (부모/조부모 공유)
- [ ] WHO 성장 곡선 대비 그래프
- [ ] NFC 태그 연동
