# 개인정보처리방침 — 아기톡톡 (ChatBabyTime)

**시행일:** 2026년 4월 1일
**개발자:** PARK EUN (pes1228@gmail.com)

---

## 1. 수집하는 개인정보 항목

아기톡톡은 서비스 제공을 위해 아래 정보를 처리합니다.

### 1-1. 기기 내 저장 (로컬 전용)
| 항목 | 목적 | 저장 위치 |
|------|------|-----------|
| 아기 이름, 생년월일, 성별, 출생 체중/신장 | 프로필 표시 및 성장 단계 계산 | Hive (기기 내 DB) |
| 육아 기록 (수유, 수면, 기저귀, 이유식 등) | 기록 관리 및 통계 | Hive (기기 내 DB) |
| 성장 일기 내용 및 표지 이미지 | 성장 일기 기능 | Hive (기기 내 DB) |
| 앱 설정 (알림, 테마 등) | 사용자 환경설정 | SharedPreferences |

위 데이터는 **사용자의 기기에만 저장**되며, 외부 서버로 전송되지 않습니다.

### 1-2. 선택적 수집 (사용자 동의 시)
| 항목 | 목적 | 저장 위치 |
|------|------|-----------|
| 텍스트 입력 내용 (익명화) | 자연어 인식 정확도 개선 | Firebase Firestore |
| AI 인식 결과 (익명화) | 파싱 알고리즘 개선 | Firebase Firestore |
| 수정 내역 (익명화) | 오인식 패턴 분석 | Firebase Firestore |

- 위 데이터는 **앱 최초 실행 시 동의 팝업**을 통해 사용자가 명시적으로 동의한 경우에만 수집됩니다.
- **개인 식별이 불가능한 익명 데이터**만 수집하며, 아기 이름·생년월일 등 개인정보는 포함되지 않습니다.
- 설정 화면에서 **언제든지 수집을 중단**할 수 있습니다.

## 2. 개인정보의 이용 목적

- 육아 기록 입력, 조회, 통계 제공
- 음성 인식을 통한 편리한 기록 입력
- 알림 및 위젯을 통한 기록 리마인더
- (선택 동의 시) 자연어 인식 정확도 개선

## 3. 접근 권한

| 권한 | 용도 | 필수 여부 |
|------|------|-----------|
| 마이크 (RECORD_AUDIO) | 음성으로 육아 기록 입력 | 선택 (음성 입력 시에만 요청) |
| 인터넷 (INTERNET) | Firebase 동기화, 데이터 수집 (동의 시) | 필수 |
| 알림 (POST_NOTIFICATIONS) | 수유·수면 리마인더 알림 | 선택 |
| 사진 접근 (READ_MEDIA_IMAGES) | 성장 일기 표지 이미지 선택 | 선택 (일기 작성 시에만 요청) |
| 진동 (VIBRATE) | 알림 진동 | 자동 |
| 부팅 완료 (RECEIVE_BOOT_COMPLETED) | 기기 재시작 후 예약 알림 복원 | 자동 |

모든 선택 권한은 해당 기능 사용 시에만 요청되며, 거부해도 앱의 핵심 기능은 정상 작동합니다.

## 4. 개인정보의 보관 및 파기

- **로컬 데이터:** 앱 삭제 시 기기에서 완전히 삭제됩니다.
- **수집 동의 데이터:** 익명화된 상태로 저장되며, 수집 목적 달성 후 지체 없이 파기합니다.
- 사용자는 설정 화면에서 **데이터 초기화** 기능을 통해 직접 모든 데이터를 삭제할 수 있습니다.

## 5. 개인정보의 제3자 제공

아기톡톡은 사용자의 개인정보를 **제3자에게 제공하지 않습니다.**

단, 아래 서비스를 기술적으로 이용합니다:
- **Google Firebase (Firestore):** 익명 NLP 데이터 저장 (동의 시에만)
- **Google Speech-to-Text:** 음성 인식 처리 (기기 내장 엔진 사용)

## 6. 아동 개인정보 보호

아기톡톡은 **부모(보호자)가 사용하는 육아 도구**이며, 아동이 직접 사용하도록 설계되지 않았습니다. 앱에 입력되는 아기 정보는 기기에만 로컬 저장되며 외부로 전송되지 않습니다.

## 7. 개인정보처리방침 변경

본 방침이 변경되는 경우 앱 내 공지를 통해 안내합니다.

## 8. 문의처

개인정보 관련 문의: **pes1228@gmail.com**

---

# Privacy Policy — 아기톡톡 (ChatBabyTime)

**Effective Date:** April 1, 2026
**Developer:** PARK EUN (pes1228@gmail.com)

---

## 1. Information We Collect

### 1-1. Stored Locally on Device Only
| Data | Purpose | Storage |
|------|---------|---------|
| Baby name, birthdate, gender, birth weight/height | Profile display & growth stage calculation | Hive (on-device DB) |
| Parenting records (feeding, sleep, diaper, baby food, etc.) | Record management & statistics | Hive (on-device DB) |
| Growth diary entries & cover images | Growth diary feature | Hive (on-device DB) |
| App settings (notifications, theme, etc.) | User preferences | SharedPreferences |

This data is stored **exclusively on your device** and is never transmitted to external servers.

### 1-2. Optional Collection (With User Consent)
| Data | Purpose | Storage |
|------|---------|---------|
| Text input (anonymized) | Improve natural language recognition accuracy | Firebase Firestore |
| AI recognition results (anonymized) | Improve parsing algorithms | Firebase Firestore |
| Correction history (anonymized) | Analyze misrecognition patterns | Firebase Firestore |

- This data is collected **only with explicit user consent** via an opt-in dialog shown on first launch.
- Only **anonymous, non-identifiable data** is collected — no baby names, birthdates, or personal information is included.
- You can **opt out at any time** from the Settings screen.

## 2. How We Use Information

- Provide parenting record input, viewing, and statistics
- Enable voice-based convenient record entry
- Send reminders via notifications and widgets
- (With consent) Improve natural language recognition accuracy

## 3. Permissions

| Permission | Purpose | Required |
|------------|---------|----------|
| Microphone (RECORD_AUDIO) | Voice input for parenting records | Optional (requested only when using voice input) |
| Internet (INTERNET) | Firebase sync, data collection (if consented) | Required |
| Notifications (POST_NOTIFICATIONS) | Feeding/sleep reminder alerts | Optional |
| Photos (READ_MEDIA_IMAGES) | Select cover images for growth diary | Optional (requested only when writing diary) |
| Vibration (VIBRATE) | Notification vibration | Automatic |
| Boot Completed (RECEIVE_BOOT_COMPLETED) | Restore scheduled notifications after device restart | Automatic |

All optional permissions are requested only when the corresponding feature is used. Denying them does not affect core functionality.

## 4. Data Retention and Deletion

- **Local data:** Completely deleted when the app is uninstalled.
- **Consented data:** Stored in anonymized form and deleted promptly after the collection purpose is fulfilled.
- Users can delete all data directly through the **Data Reset** function in Settings.

## 5. Third-Party Sharing

ChatBabyTime does **not share personal information with third parties.**

The following services are used for technical purposes only:
- **Google Firebase (Firestore):** Anonymous NLP data storage (only with consent)
- **Google Speech-to-Text:** Voice recognition processing (uses on-device engine)

## 6. Children's Privacy

ChatBabyTime is a **parenting tool designed for parents/guardians**, not for direct use by children. Baby information entered in the app is stored locally on the device only and is never transmitted externally.

## 7. Changes to This Policy

Any changes to this policy will be communicated through in-app notifications.

## 8. Contact Us

For privacy-related inquiries: **pes1228@gmail.com**
