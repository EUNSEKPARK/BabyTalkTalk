# Firebase 연동 가이드 (NLP 분석 데이터 수집)

## 1단계: Firebase 프로젝트 생성

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 로그인
firebase login

# Firebase 프로젝트 생성 (또는 기존 프로젝트 선택)
firebase projects:create chatbabytime
```

## 2단계: Flutter 앱에 Firebase 연결

```bash
# 프로젝트 루트에서 실행
flutterfire configure --project=chatbabytime
```

이 명령어가 자동으로:
- `firebase_options.dart` 생성
- Android: `google-services.json` 배치
- iOS: `GoogleService-Info.plist` 배치

## 3단계: pubspec.yaml에 의존성 추가

```yaml
dependencies:
  firebase_core: ^3.8.0
  cloud_firestore: ^5.5.0
```

```bash
flutter pub get
```

## 4단계: main.dart에 Firebase 초기화 추가

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (기존 Hive 초기화 앞에 추가)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ... 기존 코드 ...
}
```

## 5단계: nlp_analytics_service.dart에서 Firestore 활성화

`lib/services/nlp_analytics_service.dart` 파일에서 TODO 주석 해제:

```dart
// 파일 상단에 import 추가
import 'package:cloud_firestore/cloud_firestore.dart';

// _uploadLog 메서드에서 주석 해제:
Future<void> _uploadLog(NlpLog log) async {
  try {
    await FirebaseFirestore.instance
        .collection('nlp_logs')
        .doc(log.id)
        .set(log.toJson(), SetOptions(merge: true));

    _pendingLogs.removeWhere((l) => l.id == log.id);
    _savePendingLogs();
  } catch (e) {
    debugPrint('[NlpAnalytics] upload failed: $e');
  }
}
```

## 6단계: Firestore 보안 규칙

Firebase Console > Firestore > Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // NLP 로그: 쓰기만 허용 (읽기는 관리자만)
    match /nlp_logs/{logId} {
      allow create, update: if true;
      allow read, delete: if false;
    }
  }
}
```

## 7단계: Firestore 인덱스 (분석 쿼리용)

Firebase Console > Firestore > Indexes에서 복합 인덱스 추가:

| 컬렉션 | 필드 1 | 필드 2 | 쿼리 범위 |
|---------|--------|--------|-----------|
| nlp_logs | wasEdited (ASC) | timestamp (DESC) | Collection |
| nlp_logs | detectedCategory (ASC) | timestamp (DESC) | Collection |
| nlp_logs | wasCancelled (ASC) | timestamp (DESC) | Collection |

## 데이터 구조 (Firestore)

```
nlp_logs/
  {logId}/
    id: "uuid"
    timestamp: "2024-01-15T14:30:00"
    rawInput: "분유 120ml 먹었어"
    inputSource: "keyboard"
    detectedCategory: "feeding"
    confidence: 0.95
    scores: {feeding: 7.5, sleep: 0, diaper: 0, health: 0}
    detectedSubType: "formula"
    appAction: "autoSaved"
    wasEdited: false
    correctedCategory: null
    wasConfirmed: false
    wasCancelled: false
    hourOfDay: 14
    dayOfWeek: 1
    inputLength: 12
    responseTimeMs: 3
    appVersion: "1.0.0"
    deviceId: "anonymous-uuid"
```

## 분석 쿼리 예시

Firebase Console 또는 Python으로 분석:

```python
# pip install firebase-admin
import firebase_admin
from firebase_admin import firestore

db = firestore.client()

# 오인식 목록 조회
corrected = db.collection('nlp_logs') \
    .where('wasEdited', '==', True) \
    .order_by('timestamp', direction='DESCENDING') \
    .limit(100) \
    .get()

for doc in corrected:
    d = doc.to_dict()
    print(f'"{d["rawInput"]}" → {d["detectedCategory"]} → {d["correctedCategory"]}')

# 취소율 계산
cancelled = db.collection('nlp_logs').where('wasCancelled', '==', True).get()
total = db.collection('nlp_logs').get()
print(f'취소율: {len(cancelled)}/{len(total)} = {len(cancelled)/len(total)*100:.1f}%')
```
