# 아기톡톡 — Google Play Console 심사 준비 종합 가이드

> 생성일: 2026-04-13 | 프로젝트 분석 기반 자동 생성

---

## 현재 상태 요약

| 항목 | 상태 | 비고 |
|------|------|------|
| 앱 빌드 설정 (build.gradle) | ✅ 완료 | 릴리스 서명 설정 포함 |
| key.properties | ✅ 완료 | 비밀번호 입력됨 (.gitignore 확인 필수) |
| AndroidManifest.xml | ✅ 완료 | 권한 선언 적절 |
| Firestore Security Rules | ✅ 완료 | 인증 기반 접근 제어 설정됨 |
| 개인정보처리방침 (한/영) | ✅ 작성됨 | ⚠️ 공개 URL 미확보 |
| 앱 내 개인정보처리방침 링크 | ❌ 미구현 | 설정 화면에 링크 없음 |
| 스토어 스크린샷 | ❌ 미준비 | phone/tablet 폴더 모두 비어 있음 |
| Feature Graphic (1024×500) | ❌ 미준비 | store_assets에 없음 |
| 앱 아이콘 512×512 | ⚠️ 확인 필요 | assets/에 app_icon.png 존재, 512px 여부 확인 |
| 스토어 등록정보 텍스트 | ❌ 미작성 | 아래에 작성 완료 |

---

## 🔴 심사 거절 위험 — 반드시 해결

### 1. 개인정보처리방침 공개 URL 확보

Play Console에 **접근 가능한 웹 URL**이 반드시 필요합니다.

**방법 A: GitHub Pages (무료, 추천)**
```bash
# 1. GitHub에 저장소 생성 (예: babytalk-privacy)
# 2. privacy_policy.html 파일 업로드
# 3. Settings > Pages > Deploy from main branch
# → URL: https://[사용자명].github.io/babytalk-privacy/
```

**방법 B: Firebase Hosting**
```bash
firebase init hosting
# public/ 폴더에 privacy_policy.html 복사
firebase deploy
```

> 이 저장소에 `privacy_policy.html` 파일을 함께 생성해 두었습니다.

### 2. 앱 내 설정 화면에 개인정보처리방침 링크 추가

Google Play 정책상 앱 내에서도 개인정보처리방침에 접근할 수 있어야 합니다.
`settings_screen.dart`에 아래 항목을 추가해야 합니다:

```dart
// 설정 화면 하단에 추가
ListTile(
  leading: Icon(Icons.privacy_tip_outlined),
  title: Text('개인정보처리방침'),
  trailing: Icon(Icons.open_in_new),
  onTap: () => launchUrl(Uri.parse('https://[YOUR_URL]/privacy_policy.html')),
)
```

### 3. 스토어 스크린샷 준비 (최소 2장 필수)

`store_assets/phone/` 폴더가 비어 있습니다. 최소 **폰 스크린샷 2장**이 필요합니다.

**권장 스크린샷 구성 (5장):**
1. 채팅 입력 화면 — "음성으로 간편하게 기록"
2. 대시보드 — "한눈에 보는 오늘의 육아"
3. 통계 화면 — "수유·수면 패턴 분석"
4. 성장 일기 — "소중한 순간을 기록"
5. 타임라인 — "하루를 한눈에"

**스크린샷 규격:**
- 폰: 1080×1920 이상 (9:16 비율)
- 7인치 태블릿: 1200×1920 (선택)
- 10인치 태블릿: 1600×2560 (선택)

### 4. Feature Graphic 제작

- 규격: **1024×500 PNG/JPG**
- 내용: 앱 아이콘 + 앱 이름 + 핵심 카피
- 도구: Canva, Figma 등

---

## 🟡 Play Console 입력 항목

### 스토어 등록정보

| 항목 | 값 |
|------|-----|
| **앱 이름** | 아기톡톡 - 음성 육아 기록 |
| **카테고리** | 육아 (Parenting) |
| **태그** | 육아, 아기, 수유, 수면, 기록 |
| **이메일** | pes1228@gmail.com |
| **개인정보처리방침 URL** | (GitHub Pages URL 입력) |

### 짧은 설명 (80자 이내)

> 말 한마디로 끝나는 똑똑한 육아 기록. 음성으로 수유·수면·기저귀를 자동 분류합니다.

### 긴 설명 (한국어)

아래 `STORE_LISTING_긴설명.txt` 파일에 별도 작성되어 있습니다.

---

## 🟡 Data Safety (데이터 안전) 섹션

Play Console > 앱 콘텐츠 > 데이터 안전에서 아래와 같이 입력하세요.

### 개요

| 질문 | 답변 |
|------|------|
| 앱이 필수 사용자 데이터를 수집 또는 공유하나요? | **예** |
| 모든 사용자 데이터가 전송 중에 암호화되나요? | **예** (Firebase TLS) |
| 사용자가 데이터 삭제를 요청할 수 있나요? | **예** (설정 > 데이터 초기화) |

### 데이터 유형

| 카테고리 | 데이터 유형 | 수집 | 공유 | 필수/선택 | 용도 |
|----------|------------|------|------|-----------|------|
| 앱 활동 | 앱 상호작용 | ✅ | ❌ | 선택 | 분석 (서비스 개선) |

### 상세 설명 (영문으로 입력)

> This app optionally collects anonymized text input data (with explicit user consent) to improve natural language recognition accuracy. No personally identifiable information such as baby names, birthdates, or personal details is ever collected. Users can opt out at any time from the Settings screen. All data is transmitted via TLS encryption and can be deleted through the app's data reset function.

---

## 🟡 콘텐츠 등급 질문지 (IARC)

| 질문 | 답변 |
|------|------|
| 앱 카테고리 | 유틸리티 / 육아 도구 |
| 폭력적 콘텐츠 | 없음 |
| 성적 콘텐츠 | 없음 |
| 사용자 생성 콘텐츠(UGC) | 없음 (본인 기록만 가능) |
| 사용자 간 커뮤니케이션 | 없음 |
| 위치 정보 공유 | 없음 |
| 디지털 구매 | 없음 |
| 광고 포함 | 아니요 |
| 마리화나/약물 언급 | 없음 |
| 욕설/비속어 | 없음 |

**예상 등급:** 전체이용가 (Everyone)

---

## 🟡 대상 연령 & 가족 정책

| 질문 | 답변 | 주의사항 |
|------|------|---------|
| 앱의 대상 연령 | 만 18세 이상 (부모/보호자) | |
| 아동을 대상으로 하나요? | **아니요** | ⚠️ "예"를 선택하면 COPPA/가족 정책 적용 |
| 의도치 않게 아동의 관심을 끌 수 있나요? | **아니요** — 육아 기록/통계 도구 | |

> ⚠️ **핵심:** "아기" 관련 앱이지만, 사용자는 **부모**입니다. "아동 대상 아님"으로 반드시 답변하세요.

---

## 🟡 권한 정당화 (Permission Declaration)

Play Console에서 민감한 권한에 대해 사유를 영문으로 설명해야 합니다.

| 권한 | 설명 (영문) |
|------|------------|
| **RECORD_AUDIO** | Core feature: Voice-based parenting record input. Users speak naturally (e.g., "breastfed for 10 minutes") and the app automatically categorizes the record into feeding, sleep, diaper, etc. The microphone is only activated when the user explicitly taps the voice input button. |
| **SCHEDULE_EXACT_ALARM** | Used to schedule precise feeding/sleep reminder notifications based on the baby's last recorded activity time. Exact timing is essential so parents don't miss feeding windows. |
| **POST_NOTIFICATIONS** | Sends feeding and sleep reminder notifications to help parents maintain regular care schedules. Users can enable/disable this in Settings. |
| **READ_MEDIA_IMAGES** | Allows users to select photos from their gallery as cover images for growth diary entries. Only accessed when the user explicitly chooses to add a photo. |

---

## 🟡 광고 관련

| 질문 | 답변 |
|------|------|
| 앱에 광고가 포함되나요? | **아니요** |
| 광고 SDK가 포함되어 있나요? | **아니요** |

---

## 🔵 추가 확인 사항

### Firebase API 키 보안
`firebase_options.dart`에 API 키가 하드코딩되어 있지만, Firebase 웹 API 키는 공개되어도 Firestore Security Rules로 보호됩니다. Rules 파일(`firestore.rules`)이 인증 기반으로 올바르게 설정되어 있음을 확인했습니다.

### Midjourney 이미지 저작권
`assets/midjourney_session/` 폴더에 AI 생성 이미지가 포함되어 있습니다.
- Midjourney **유료 구독** 중이라면 상업적 사용 가능
- 구독 증빙(결제 영수증)을 보관해두세요
- 심사에서 문제가 될 경우 직접 제작 이미지로 교체 권장

### 스토어 설명 "AI" 표현 주의
- ❌ "AI 기반", "인공지능", "AI가 분류" → 심사 시 추가 설명 요구 가능
- ✅ "똑똑한 음성 인식", "자동 분류", "음성으로 간편하게" 사용

---

## 📋 제출 전 최종 체크리스트

- [ ] `flutter clean && flutter pub get && flutter build appbundle --release` 성공
- [ ] key.properties에 실제 키스토어 경로/비밀번호 확인
- [ ] **개인정보처리방침 웹 URL 확보** (GitHub Pages 등)
- [ ] **앱 내 설정 화면에 개인정보처리방침 링크 추가**
- [ ] **스토어 스크린샷 최소 2장** (1080×1920 이상)
- [ ] **Feature Graphic** (1024×500)
- [ ] 앱 아이콘 512×512 PNG 준비
- [ ] Play Console > 스토어 등록정보 입력 (이름, 짧은/긴 설명)
- [ ] Play Console > Data Safety 섹션 작성
- [ ] Play Console > 콘텐츠 등급 질문지 완료
- [ ] Play Console > 대상 연령 설정 ("아동 대상 아님")
- [ ] Play Console > 권한 정당화 입력 (RECORD_AUDIO 등)
- [ ] 긴 설명에서 "AI" 표현 제거 확인
- [ ] Midjourney 이미지 라이선스 확인
- [ ] .aab 파일 Play Console 업로드
- [ ] 내부 테스트 트랙에서 먼저 테스트 → 프로덕션 제출
