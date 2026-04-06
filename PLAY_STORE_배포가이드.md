# 아기톡톡 (ChatBabyTime) — Google Play Store 배포 가이드

> EdenBible 심사 경험을 바탕으로 작성된 배포 체크리스트입니다.

---

## 📋 1단계: 빌드 준비 (로컬)

### ✅ 키스토어 생성
```bash
keytool -genkey -v \
  -keystore ~/babytalk-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias babytalk
```

### ✅ key.properties 설정
`android/key.properties` 파일을 열고 실제 비밀번호를 입력하세요:
```properties
storePassword=실제비밀번호
keyPassword=실제비밀번호
keyAlias=babytalk
storeFile=/Users/pes/babytalk-release.jks
```

### ✅ 릴리스 빌드
```bash
# App Bundle (Play Store 권장)
flutter build appbundle --release

# 결과물: build/app/outputs/bundle/release/app-release.aab
```

---

## 📋 2단계: 스토어 에셋 준비

### 필수 에셋 (store_assets/ 폴더에 넣기)

| 에셋 | 규격 | 파일명 |
|------|------|--------|
| 앱 아이콘 | 512×512 PNG (32bit, 투명 가능) | `app_icon_512.png` |
| Feature Graphic | 1024×500 PNG/JPG | `feature_graphic_1024x500.png` |
| 폰 스크린샷 | 최소 2장, 16:9 또는 9:16 | `phone/` 폴더 |
| 7인치 태블릿 스크린샷 | 최소 1장 (권장) | `tablet_7inch/` 폴더 |
| 10인치 태블릿 스크린샷 | 최소 1장 (권장) | `tablet_10inch/` 폴더 |

**스크린샷 팁:** 에뮬레이터에서 캡처 후 Figma/Canva로 꾸미기
- 핵심 화면: 채팅 입력, 대시보드, 타임라인, 성장 일기, 통계

---

## 📋 3단계: Play Console 설정

### 스토어 등록정보

| 항목 | 권장 내용 |
|------|-----------|
| **앱 이름** | 아기톡톡 - 음성 육아 기록 |
| **짧은 설명** (80자) | 말 한마디로 끝나는 똑똑한 육아 기록. 음성으로 수유·수면·기저귀를 자동 분류합니다. |
| **카테고리** | 육아 (Parenting) |
| **태그** | 육아, 아기, 수유, 수면, 기록 |

### 긴 설명 (4000자) 작성 시 주의사항
- ❌ "AI 기반", "인공지능" 표현 → ✅ "똑똑한 음성 인식", "자동 분류"로 대체
- ❌ 과장 표현 (업계 최고, 1위 등)
- ✅ 핵심 기능 위주로 간결하게

---

## 📋 4단계: 심사 핵심 체크리스트

### 🚨 반드시 확인 (거절 위험)

#### 1. 개인정보처리방침
- [x] `PRIVACY_POLICY.md` 작성 완료
- [ ] GitHub Pages 또는 웹사이트에 게시하여 **공개 URL 확보**
- [ ] Play Console > 앱 콘텐츠 > 개인정보처리방침에 URL 입력
- [ ] 앱 내 설정 화면에서도 링크 제공

#### 2. 데이터 안전 섹션 (Data Safety)
Play Console에서 아래와 같이 신고해야 합니다:

| 질문 | 답변 |
|------|------|
| 데이터를 수집하나요? | **예** (사용자 동의 시) |
| 데이터를 공유하나요? | **아니요** |
| 수집 데이터 유형 | 앱 활동 > 앱 상호작용 (익명 텍스트 입력 데이터) |
| 수집은 선택 사항인가요? | **예** (사용자가 거부 가능) |
| 데이터 암호화? | **예** (Firebase 전송 시 TLS 암호화) |
| 데이터 삭제 요청? | **예** (설정에서 초기화 가능) |

#### 3. 콘텐츠 등급 질문지
| 질문 | 답변 |
|------|------|
| 앱의 대상 연령 | **모든 연령** (부모용 도구) |
| 아동을 대상으로 하나요? | **아니요** — 부모/보호자가 사용하는 육아 도구 |
| 폭력/성적 콘텐츠 | 없음 |
| 사용자 생성 콘텐츠 | 없음 (본인 기록만) |

> ⚠️ **중요:** "아동 대상 앱"으로 체크하면 COPPA/가족 정책이 적용되어 심사가 훨씬 까다로워집니다. 아기톡톡은 **부모가 사용하는 도구**이므로 "아동 대상 아님"으로 답변하세요.

#### 4. 권한 정당화 (Permission Declaration)
Play Console에서 민감 권한 사유를 설명해야 합니다:

| 권한 | 설명 (영문으로 입력) |
|------|---------------------|
| RECORD_AUDIO | Voice-based parenting record input. Users speak naturally (e.g., "breastfed for 10 minutes") and the app automatically categorizes the record. Microphone is only accessed when the user taps the voice input button. |

#### 5. 광고 관련
| 질문 | 답변 |
|------|------|
| 앱에 광고가 포함되나요? | **아니요** |

### ⚠️ 추가 주의사항

#### Midjourney 이미지 저작권
`assets/midjourney_session/` 폴더의 AI 생성 이미지:
- Midjourney **유료 구독** 시 상업적 사용 가능
- 구독 증빙을 보관해두세요
- 불안하면 직접 제작 이미지로 교체 권장

#### Firebase API 키
`firebase_options.dart`에 API 키가 하드코딩되어 있지만, Firebase 웹 API 키는 노출되어도 보안상 문제없습니다 (Firebase Security Rules로 보호). 단, Firestore Security Rules가 제대로 설정되어 있는지 확인하세요.

---

## 📋 5단계: 빌드 및 업로드

```bash
# 1. 클린 빌드
flutter clean && flutter pub get

# 2. App Bundle 빌드
flutter build appbundle --release

# 3. 빌드 결과 확인
ls -la build/app/outputs/bundle/release/app-release.aab

# 4. Play Console에 .aab 파일 업로드
#    Play Console > 프로덕션 > 새 릴리스 만들기
```

---

## 📋 6단계: 제출 전 최종 점검

- [ ] 키스토어 생성 및 key.properties 설정
- [ ] `flutter build appbundle --release` 성공
- [ ] 개인정보처리방침 웹 URL 확보 및 등록
- [ ] 스토어 에셋 (아이콘 512x512, feature graphic, 스크린샷 최소 2장)
- [ ] Data Safety 섹션 정확 신고
- [ ] 콘텐츠 등급 질문지 완료 ("아동 대상 아님"으로 답변)
- [ ] RECORD_AUDIO 권한 사유 설명 입력
- [ ] 스토어 설명에서 "AI" 표현 제거
- [ ] Midjourney 이미지 라이선스 확인
- [ ] Firestore Security Rules 확인
- [ ] 앱 내 설정 화면에 개인정보처리방침 링크 추가

---

## 🔗 참고: EdenBible과의 차이점

| 항목 | EdenBible | BabyTalkTalk |
|------|-----------|--------------|
| 데이터 수집 | 없음 (로컬 전용) | 있음 (NLP 익명 데이터, 동의 시) |
| 민감 권한 | 없음 | RECORD_AUDIO |
| Data Safety | "수집 없음" 간단 | 상세 신고 필요 |
| COPPA 리스크 | 없음 (18+ 타겟) | 있음 → "부모용 도구"로 명확히 |
| AI 용어 | 없음 | 스토어 설명에서 제거 필요 |
| 서드파티 | YouTube 썸네일만 | Firebase Firestore, Speech-to-Text |
