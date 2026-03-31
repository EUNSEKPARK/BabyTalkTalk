# ChatBabyTime (아기톡톡) 전체 재설계 문서 v2

## 1. 개요

기존 키워드 가중치 스코어링 방식의 NLP 파서를 **노드 기반 파이프라인 아키텍처**로 전면 재설계한다.
첨부된 다이어그램의 설계 철학(각 단계별 입출력 노출, 단계별 재질문, 검증 실패 시 원인 포함 재생성)을 육아 기록 앱에 맞게 적용한다.

---

## 2. UX 변경사항

### 2.1 스플래시 화면 삭제
- `splash_screen.dart` 제거
- `main.dart`에서 `initialRoute`를 바로 프로필 체크 → `/home` 또는 `/setup`으로 분기

```dart
// 변경 전
initialRoute: '/'  // → SplashScreen

// 변경 후
home: hasProfile ? const MainScreen() : const ProfileSetupScreen(isInitialSetup: true),
```

### 2.2 아이 이름 입력 선택사항 (스킵 가능)
- `profile_setup_screen.dart`의 이름 필수 검증 제거
- "건너뛰기" 버튼 추가
- 이름 미입력 시 기본값: "우리 아기"

```dart
// 변경 전
if (_nameController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('아기 이름을 입력해주세요')),
  );
  return;
}

// 변경 후
final name = _nameController.text.trim().isEmpty ? '우리 아기' : _nameController.text.trim();
```

- 상단에 "건너뛰기" TextButton 추가:
```dart
AppBar(
  actions: [
    if (widget.isInitialSetup)
      TextButton(
        onPressed: () => _skipSetup(),
        child: Text('건너뛰기'),
      ),
  ],
)

void _skipSetup() async {
  final profile = BabyProfile(
    name: '우리 아기',
    birthDate: DateTime.now(),
  );
  await context.read<RecordService>().saveProfile(profile);
  if (!mounted) return;
  Navigator.pushReplacementNamed(context, '/home');
}
```

### 2.3 리스트에서 수정/삭제 (상세 페이지 없이)
- `record_card.dart`에 스와이프 동작 추가
  - 왼쪽 스와이프: 삭제 (Dismissible)
  - 오른쪽 스와이프 또는 롱프레스: 인라인 수정 모달
- `record_home_screen.dart`와 `chat_screen.dart`의 레코드 목록에서 직접 수정/삭제

```dart
// RecordCard를 Dismissible로 감싸기
Dismissible(
  key: Key(record.id),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 20),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (direction) => _showDeleteConfirm(context),
  onDismissed: (direction) {
    context.read<RecordService>().deleteRecord(record.id);
  },
  child: RecordCard(record: record, onEdit: () => _showEditSheet(record)),
)
```

- 수정 BottomSheet:
```dart
void _showEditSheet(BabyRecord record) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => RecordEditSheet(record: record),
  );
}
```

### 2.4 성장 단계(카테고리) 선택

프로필 설정 또는 설정 화면에서 현재 성장 단계를 선택:

| 단계 | 설명 | 주요 키워드 |
|------|------|------------|
| **분유기** (0~5개월) | 분유/모유 위주 시기 | 분유, 모유, 수유, 젖병, 직수, 유축, 잠, 기저귀 |
| **이유식기** (5~15개월) | 이유식 도입 시기 | 분유 + 이유식, 죽, 미음, 퓨레, 반찬 재료 |
| **유아식기** (15개월~) | 일반식 전환 시기 | 밥, 메뉴, 간식, 과일, 우유, 반찬, 국 |

```dart
enum GrowthStage {
  formula,    // 분유기
  weaning,    // 이유식기
  toddler,    // 유아식기
}
```

**키워드 가중치가 성장 단계에 따라 동적으로 변경됨:**

```dart
// 분유기: '밥' 키워드 비활성, '분유/모유' 가중치 최대
// 이유식기: '이유식/죽/미음' 키워드 활성화, '분유' 가중치 유지
// 유아식기: '밥/메뉴/반찬' 키워드 활성화, '분유' 가중치 감소

Map<String, double> getActiveKeywords(GrowthStage stage) {
  switch (stage) {
    case GrowthStage.formula:
      return {
        '분유': 3.0, '모유': 3.0, '수유': 3.0, '젖병': 2.5,
        '직수': 3.0, '유축': 3.0,
        // 이유식/유아식 키워드 비활성
      };
    case GrowthStage.weaning:
      return {
        '분유': 3.0, '모유': 3.0, '수유': 3.0,
        '이유식': 3.0, '죽': 2.5, '미음': 2.5, '퓨레': 2.5,
        // 재료 키워드 활성화
        '소고기': 2.5, '감자': 2.0, '브로콜리': 2.0,
      };
    case GrowthStage.toddler:
      return {
        '밥': 3.0, '메뉴': 2.5, '반찬': 2.5, '국': 2.0,
        '간식': 3.0, '과일': 2.5, '우유': 2.5,
        '빵': 2.0, '과자': 2.0,
        // 분유 가중치 감소
        '분유': 1.5,
      };
  }
}
```

---

## 3. 전체 파이프라인 재설계

### 3.1 파이프라인 흐름도

```
┌──────────────────────────────────────────────────────────────────────┐
│                    전반부: 입력 분석 및 정규화                          │
│                                                                      │
│  [입력]     [1.입력     [2.문장구조  [3.유형    [4.의도    [5.데이터   │
│  채팅/음성 → 정규화]  → 분석]    → 분류]  → 파악]  → 정규화]         │
│                                                                      │
│         FAIL → 원인 포함 재질문 루프 (최대 3회)                       │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    후반부: 기록 생성 및 검증                           │
│                                                                      │
│  [6.기록     [7.필드     [8.최종     [9.결과                          │
│   생성]   → 검증]    → 확인]    → 저장]                              │
│                                                                      │
│         FAIL → 재질문 루프 (최대 2회)                                 │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.2 노드 색상 범례 (첨부 이미지 기준)

| 색상 | 노드 유형 | 해당 노드 |
|------|----------|----------|
| 파란색 | LLM/로직 프롬프트 노드 | 1.입력정규화, 2.문장구조분석, 3.유형분류, 4.의도파악, 5.데이터정규화 |
| 주황색 | 검증 노드 | 7.필드검증, 8.최종확인 |
| 초록색 | 생성/변형 노드 | 6.기록생성 |
| 빨간색 | 입출력/결과 노드 | 입력, 9.결과저장 |

---

## 4. 각 노드 상세 설계

### 노드 1: 입력 정규화 (InputNormalization)

**목적:** 원시 텍스트를 파이프라인이 처리할 수 있는 깨끗한 형태로 변환

**입력:** 사용자 원문 (채팅 텍스트 또는 음성인식 결과)

**처리:**
```
1. 이모티콘/특수문자 제거: ㅋㅎㅠㅜㅡ, !!!, ~~~
2. 연속 공백 정리
3. 한글 글자 사이 과도한 띄어쓰기 복원: "분 유" → "분유"
4. 숫자 정규화: "백이십" → "120", "삼십칠도오" → "37.5도"
5. 오타 사전 매핑: "기저기" → "기저귀", "먹엇어" → "먹었어"
6. 음성인식 오류 보정: "기차갈" → "기저귀 갈"
```

**출력:**
```dart
class NormalizedInput {
  final String original;      // 원본
  final String normalized;    // 정규화된 텍스트
  final List<String> corrections;  // 적용된 보정 목록
  final bool hasNumericContent;    // 숫자 포함 여부
}
```

### 노드 2: 문장 구조 분석 (SentenceAnalysis)

**목적:** 입력이 온전한 문장인지, 어떤 구조를 가지고 있는지 분석

**분석 항목:**

#### 2.1 문장 수 판별
```
단문장: "분유 먹었어"
다문장: "분유 먹고 잠들었어"
       "3시에 분유 먹었고 4시에 잠들었어"
```

**다문장 분리 기준:**
- 접속조사: "~하고", "~그리고", "~그다음", "~후에"
- 시간 마커: "N시에 ... N시에 ..."
- 나열: "먹고, 자고, 갈았어"

#### 2.2 문장 완성도 판별
```
완전한 문장:  "분유 120ml 먹었어"     → 주어(생략가능) + 목적어 + 수량 + 서술어
부분 문장:    "분유 먹었어"           → 목적어 + 서술어 (수량 누락)
조각/파편:    "분유"                  → 키워드만
             "120"                   → 숫자만
             "ㅋ"                    → 의미 없음
```

**출력:**
```dart
enum SentenceCompleteness {
  complete,     // 완전한 문장 (행위+대상+수량/상태)
  partial,      // 부분 문장 (핵심 정보 일부 누락)
  fragment,     // 조각/파편 (키워드 1~2개만)
  noise,        // 의미 없음 (ㅋ, ㅎ, 네, 아 등)
}

enum SentenceCount {
  single,       // 단문장
  multi,        // 다문장
}

class SentenceAnalysisResult {
  final SentenceCount count;
  final SentenceCompleteness completeness;
  final List<String> segments;          // 다문장이면 분리된 각 문장
  final List<String> missingFields;     // 누락된 정보 목록
  final String? detectedSubject;        // 감지된 주어 (아기/엄마/남편)
}
```

**완전한 문장 판별 기준:**
```
[먹다 계열] 완전: 뭘 + 얼마나 + 먹었다 → "분유 120ml 먹었어"
            부분: 뭘 + 먹었다           → "분유 먹었어" (양 누락)
            조각: 뭘                     → "분유" (서술어 누락)

[자다 계열] 완전: 잠들었다/깼다          → "잠들었어" (자체로 완전)
            부분: 잠                     → "잠" (상태 불명)

[기저귀 계열] 완전: 뭘 + 했다            → "응가 했어" / "기저귀 갈았어"
              부분: 뭘                   → "응가" (서술어 누락이나 추론 가능)
```

### 노드 3: 유형 분류 (TypeClassification)

**목적:** 입력이 어떤 종류의 육아 활동인지 분류

**대분류 (먹고/자고/싸고):**
```
먹기(feeding): 분유, 모유, 이유식, 간식, 밥, 우유, 과일...
자기(sleep):   잠들었어, 깼어, 낮잠, 밤잠, 재웠어...
싸기(diaper):  기저귀, 응가, 소변, 대변, 쌌어...
건강(health):  체온, 약, 병원, 기침, 열...
기타(other):   목욕, 외출, 산책...
```

**성장 단계별 키워드 맵 적용:**
```dart
class TypeClassificationResult {
  final RecordCategory primaryType;     // 1순위 분류
  final RecordCategory? secondaryType;  // 2순위 (복합 입력 시)
  final double confidence;              // 분류 신뢰도
  final Map<RecordCategory, double> scores;  // 전체 스코어
  final bool needsDisambiguation;       // 객관식 필요 여부
  final String? ambiguityReason;        // 애매한 이유
}
```

**분류 로직 개선:**
```
기존: 모든 키워드 가중치 합산 → 최고점 선택
개선: 성장 단계 필터 → 키워드 스코어링 → 패턴 매칭 → 문맥 분석 → 최종 판별
```

### 노드 4: 의도 파악 (IntentDetection)

**목적:** 분류된 유형 내에서 구체적으로 어떤 기록을 남기려는 것인지 파악

**먹기 의도:**
```
분유기:    분유 수유 / 모유 수유 / 유축
이유식기:  분유 수유 / 모유 수유 / 이유식 (죽/미음/퓨레)
유아식기:  밥 (+ 메뉴) / 간식 / 과일 / 우유 / 빵
```

**자기 의도:**
```
잠듦 시작 / 깨어남 / 낮잠 / 밤잠
```

**싸기 의도:**
```
소변 / 대변 / 소변+대변 / 변 상태 (묽은/딱딱한/녹색)
```

**출력:**
```dart
class IntentResult {
  final String intent;              // "formula_feeding", "sleep_start" 등
  final Map<String, dynamic> extractedFields;  // 추출된 필드값
  // 예: {feedingType: formula, amount: 120, unit: ml}
  // 예: {sleepStatus: start}
  // 예: {diaperType: poop, stoolColor: yellow}
  final List<String> missingRequired;  // 필수인데 누락된 필드
  final List<String> optionalMissing;  // 선택인데 누락된 필드
}
```

### 노드 5: 기록용 데이터 정규화 (RecordNormalization)

**목적:** 추출된 정보를 BabyRecord 형태로 변환

**처리:**
```
1. 시간 파싱: "오후 2시" → DateTime(14:00)
2. 수량 단위 통일: "100cc" → 100ml
3. 기본값 설정: 시간 미입력 → 현재 시간
4. 타입 매핑: "응가" → DiaperType.poop
```

**출력:** `BabyRecord` (저장 전 상태)

### 노드 6: 기록 생성 (RecordGeneration)

**목적:** 최종 BabyRecord 객체 생성

### 노드 7: 필드 검증 (FieldValidation)

**목적:** 생성된 기록의 각 필드가 유효한지 검증

**검증 규칙:**
```dart
class ValidationRule {
  // 수유
  static bool validateFeeding(BabyRecord r) {
    if (r.feedingType == null) return false;  // 수유 타입 필수
    if (r.feedingType == FeedingType.formula && r.amountMl == null) {
      // 분유는 양(ml) 권장 (필수는 아님)
      return true; // warning으로 처리
    }
    if (r.amountMl != null && (r.amountMl! < 10 || r.amountMl! > 500)) {
      return false;  // 비정상 범위
    }
    return true;
  }

  // 수면
  static bool validateSleep(BabyRecord r) {
    if (r.sleepStatus == null) return false;  // 잠듦/깸 필수
    return true;
  }

  // 기저귀
  static bool validateDiaper(BabyRecord r) {
    if (r.diaperType == null) return false;  // 소변/대변 필수
    return true;
  }

  // 건강
  static bool validateHealth(BabyRecord r) {
    if (r.temperature != null && (r.temperature! < 34.0 || r.temperature! > 42.0)) {
      return false;  // 비정상 체온 범위
    }
    return true;
  }
}
```

**검증 실패 시:**
```dart
class ValidationError {
  final String nodeId;        // 어느 노드에서 실패했는지
  final String field;         // 어떤 필드가 문제인지
  final String reason;        // 왜 실패했는지
  final String suggestion;    // 재질문 문구
}

// 예시:
// ValidationError(
//   nodeId: 'field_validation',
//   field: 'feedingType',
//   reason: '수유 타입을 파악할 수 없습니다',
//   suggestion: '모유인가요, 분유인가요?',
// )
```

### 노드 8: 최종 확인 (FinalConfirmation)

**목적:** 사용자에게 최종 기록을 보여주고 확인

**확인 카드 표시:**
```
┌─────────────────────────┐
│ 🍼 분유 120ml           │
│ 📅 오후 2:00            │
│                         │
│  [수정]  [확인]  [취소]  │
└─────────────────────────┘
```

### 노드 9: 결과 저장 (ResultSave)

**목적:** Hive DB에 최종 저장

---

## 5. 재질문 (Re-questioning) 시스템

### 5.1 단계별 재질문

각 노드에서 실패 시, 해당 노드의 오류를 사용자에게 질문으로 변환:

```
노드 2 실패 (문장구조):
  입력: "120"
  질문: "120ml를 말씀하시는 건가요? 뭘 먹었는지 알려주세요. (예: 분유 120ml)"

노드 3 실패 (유형분류):
  입력: "밥 먹었어"
  질문: "밥은 이유식인가요, 유아식(밥)인가요?" [이유식] [밥/유아식]

노드 4 실패 (의도파악):
  입력: "먹였어"
  질문: "뭘 먹였나요?" [분유] [모유] [이유식] [간식]

노드 7 실패 (필드검증):
  입력: "분유 먹었어"
  질문: "얼마나 먹었나요?" [60ml] [80ml] [100ml] [120ml] [직접입력]
```

### 5.2 재질문 루프

```dart
class ReQuestionLoop {
  static const int maxRetries = 3;  // 전반부 최대 재시도
  static const int maxValidationRetries = 2;  // 후반부 최대 재시도

  int currentRetry = 0;
  List<ValidationError> errors = [];

  /// 재질문이 필요한지 판단
  bool needsReQuestion(PipelineResult result) {
    return result.hasError && currentRetry < maxRetries;
  }

  /// 다음 질문 생성
  String generateQuestion(ValidationError error) {
    currentRetry++;
    return error.suggestion;
  }
}
```

---

## 6. 파이프라인 실행 구조

### 6.1 PipelineNode 인터페이스

```dart
abstract class PipelineNode<TInput, TOutput> {
  final String nodeId;
  final String nodeName;

  PipelineNode(this.nodeId, this.nodeName);

  /// 노드 실행
  NodeResult<TOutput> execute(TInput input);

  /// 실행 결과를 사용자에게 노출할 수 있는 형태로 변환
  String describe(NodeResult<TOutput> result);
}

class NodeResult<T> {
  final bool success;
  final T? data;
  final ValidationError? error;
  final Duration executionTime;
  final Map<String, dynamic> debugInfo;  // 디버그용 중간 데이터

  NodeResult({
    required this.success,
    this.data,
    this.error,
    required this.executionTime,
    this.debugInfo = const {},
  });
}
```

### 6.2 파이프라인 실행기

```dart
class NlpPipeline {
  final GrowthStage growthStage;
  final List<PipelineNode> nodes;

  NlpPipeline({required this.growthStage}) : nodes = [
    InputNormalizationNode(),
    SentenceAnalysisNode(),
    TypeClassificationNode(growthStage),
    IntentDetectionNode(growthStage),
    RecordNormalizationNode(),
    RecordGenerationNode(),
    FieldValidationNode(),
    FinalConfirmationNode(),
  ];

  /// 전체 파이프라인 실행
  PipelineResult run(String rawInput) {
    final trace = PipelineTrace();
    dynamic currentData = rawInput;

    for (final node in nodes) {
      final result = node.execute(currentData);
      trace.addStep(node.nodeId, result);

      if (!result.success) {
        return PipelineResult(
          success: false,
          failedNode: node.nodeId,
          error: result.error,
          trace: trace,
        );
      }

      currentData = result.data;
    }

    return PipelineResult(
      success: true,
      record: currentData as BabyRecord,
      trace: trace,
    );
  }
}
```

### 6.3 파이프라인 추적 (디버깅/테스트용)

```dart
class PipelineTrace {
  final List<PipelineStep> steps = [];

  void addStep(String nodeId, NodeResult result) {
    steps.add(PipelineStep(
      nodeId: nodeId,
      success: result.success,
      data: result.data,
      error: result.error,
      executionTime: result.executionTime,
      debugInfo: result.debugInfo,
    ));
  }

  /// 각 단계별 결과를 보기 좋게 출력
  String prettyPrint() {
    final buf = StringBuffer();
    for (final step in steps) {
      final icon = step.success ? '✅' : '❌';
      buf.writeln('$icon [${step.nodeId}] ${step.executionTime.inMilliseconds}ms');
      if (step.debugInfo.isNotEmpty) {
        step.debugInfo.forEach((k, v) => buf.writeln('   $k: $v'));
      }
      if (!step.success && step.error != null) {
        buf.writeln('   ⚠️ ${step.error!.reason}');
        buf.writeln('   💬 ${step.error!.suggestion}');
      }
    }
    return buf.toString();
  }
}
```

---

## 7. 성장 단계별 키워드 상세

### 7.1 분유기 (GrowthStage.formula)

**주요 활동:** 분유/모유 수유, 잠, 기저귀

| 카테고리 | 핵심 키워드 | 가중치 |
|---------|-----------|--------|
| 수유 | 분유, 모유, 수유, 젖병, 직수, 유축, 젖, ml, cc | 3.0 |
| 수면 | 잠, 잠들었어, 깼어, 낮잠, 밤잠, 재웠어, 기상 | 3.0 |
| 기저귀 | 기저귀, 응가, 소변, 대변, 쌌어, 갈았어 | 3.0 |
| 건강 | 체온, 열, 약, 병원, 예방접종 | 3.0 |

**비활성 키워드:** 밥, 메뉴, 반찬, 국, 과일 (이 시기에 해당 안됨)

### 7.2 이유식기 (GrowthStage.weaning)

**주요 활동:** 분유 + 이유식 (죽/미음/퓨레), 잠, 기저귀

| 카테고리 | 핵심 키워드 | 가중치 |
|---------|-----------|--------|
| 수유(분유) | 분유, 모유, 수유, 젖병 | 3.0 |
| 이유식 | 이유식, 죽, 미음, 퓨레 + 모든 재료명 | 3.0 |
| 수면 | (분유기와 동일) | 3.0 |
| 기저귀 | (분유기와 동일) | 3.0 |
| 건강 | (분유기와 동일) + 알레르기 관련 강화 | 3.0 |

**특이사항:**
- "밥"이 나오면 → "이유식(죽)"으로 분류 (유아식이 아닌)
- 재료명(소고기, 감자 등) 인식 강화

### 7.3 유아식기 (GrowthStage.toddler)

**주요 활동:** 밥(일반식), 간식, 과일, 우유, 잠, 기저귀/배변훈련

| 카테고리 | 핵심 키워드 | 가중치 |
|---------|-----------|--------|
| 밥/식사 | 밥, 메뉴, 반찬, 국, 찌개, 밥상 | 3.0 |
| 간식 | 간식, 과일, 과자, 빵, 요거트 | 3.0 |
| 우유 | 우유, 우유병, 생우유 | 2.5 |
| 수면 | (동일) | 3.0 |
| 기저귀 | (동일) + 배변훈련, 변기 | 3.0 |
| 건강 | (동일) | 3.0 |

**특이사항:**
- "밥"이 나오면 → "식사(일반식)"으로 분류
- "분유"는 가중치 감소 (1.5)
- 메뉴명 인식: "카레 먹었어", "국수 먹었어"

---

## 8. 실사용자 입력 케이스 분류

### 8.1 완전한 문장 케이스
```
"오후 2시에 분유 120ml 먹었어"        → feeding(formula, 120ml, 14:00)
"방금 잠들었어"                       → sleep(start, now)
"아까 기저귀 갈았어 응가"              → diaper(poop, recent)
"체온 37.5도"                         → health(temp=37.5)
"이유식 소고기 죽 먹였어"              → babyfood(beef porridge)
```

### 8.2 부분 문장 케이스
```
"분유 먹었어"                          → feeding(formula, amount=?) → "얼마나 먹었나요?"
"잠들었어"                            → sleep(start) → 완전한 문장으로 처리 가능
"기저귀 갈았어"                        → diaper(type=?) → "소변인가요 대변인가요?"
"약 먹였어"                           → health(medicine=?) → "무슨 약인가요?"
```

### 8.3 조각/파편 케이스
```
"분유"                                → "분유 수유 기록인가요? 얼마나 먹었나요?"
"120"                                 → "120ml 분유를 말씀하시는 건가요?"
"응가"                                → "응가(대변) 기록할게요" → 바로 기록 가능
"잠"                                  → "잠들었나요, 깼나요?" [잠듦] [깨어남]
```

### 8.4 다문장 케이스
```
"분유 120ml 먹고 잠들었어"             → [feeding(formula,120ml), sleep(start)]
"3시에 이유식 먹였고 4시에 잠들었어"    → [babyfood(15:00), sleep(start,16:00)]
"기저귀 갈고 분유 먹였어"              → [diaper(?), feeding(formula,?)]
```

### 8.5 감정/노이즈 포함 케이스
```
"드디어 잠들었다 ㅠㅠ"                 → sleep(start) - 감정 제거 후 파싱
"또 깼어 ㅜㅜ 짜증나"                 → sleep(end) - 감정 제거 후 파싱
"겨우 분유 100ml 먹었어..."           → feeding(formula, 100ml)
"에효 기저귀 또 갈아야해"              → diaper(?) - 의도/예정 표현 감지
```

### 8.6 엄마 본인 (오탐 방지) 케이스
```
"나 밥 먹어야겠다"                    → other (본인 참조 감지)
"남편이 약 먹었어"                    → other (타인 참조 감지)
"커피 마셨어"                         → other (아기와 무관)
"드라마 보다가 잠들뻔"                → other (본인 참조)
```

---

## 9. 데이터 모델 변경

### 9.1 BabyProfile 확장

```dart
@HiveType(typeId: 5)
class BabyProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime birthDate;

  @HiveField(2)
  String? gender;

  @HiveField(3)
  double? birthWeight;

  @HiveField(4)
  double? birthHeight;

  // 신규 필드
  @HiveField(5)
  int growthStageIndex;  // GrowthStage.index (0: formula, 1: weaning, 2: toddler)

  GrowthStage get growthStage => GrowthStage.values[growthStageIndex];
  set growthStage(GrowthStage stage) => growthStageIndex = stage.index;
}
```

### 9.2 RecordCategory 확장 (유아식기 대응)

```dart
enum RecordCategory {
  feeding,      // 수유 (모유/분유)
  sleep,        // 수면
  diaper,       // 기저귀
  milestone,    // 성장 기록
  health,       // 건강
  other,        // 기타
  babyfood,     // 이유식
  snack,        // 간식
  meal,         // 식사 (유아식기 밥) - 신규
  milk,         // 우유 (유아식기) - 신규
}
```

---

## 10. 파일 구조 변경

```
lib/
├── pipeline/                           # 신규 파이프라인 디렉토리
│   ├── pipeline.dart                   # PipelineNode, NlpPipeline
│   ├── nodes/
│   │   ├── input_normalization.dart    # 노드 1
│   │   ├── sentence_analysis.dart      # 노드 2
│   │   ├── type_classification.dart    # 노드 3
│   │   ├── intent_detection.dart       # 노드 4
│   │   ├── record_normalization.dart   # 노드 5
│   │   ├── record_generation.dart      # 노드 6
│   │   ├── field_validation.dart       # 노드 7
│   │   └── final_confirmation.dart     # 노드 8
│   ├── models/
│   │   ├── pipeline_result.dart
│   │   ├── pipeline_trace.dart
│   │   ├── node_result.dart
│   │   └── validation_error.dart
│   ├── keywords/
│   │   ├── formula_stage_keywords.dart
│   │   ├── weaning_stage_keywords.dart
│   │   └── toddler_stage_keywords.dart
│   └── requestion/
│       └── requestion_loop.dart
├── models/
│   ├── baby_record.dart                # RecordCategory에 meal, milk 추가
│   ├── baby_profile.dart               # growthStage 추가
│   └── growth_stage.dart               # 신규: GrowthStage enum
├── services/
│   ├── nlp_parser.dart                 # 기존 유지 (하위호환) → 내부적으로 pipeline 호출
│   └── ...
└── screens/
    ├── profile_setup_screen.dart       # 이름 스킵 + 성장단계 선택
    └── ...
```

---

## 11. 마이그레이션 전략

1. **1단계:** 기존 `nlp_parser.dart`를 유지하면서 `pipeline/` 디렉토리 신규 생성
2. **2단계:** `NlpParser.parse()` 내부에서 `NlpPipeline.run()`을 호출하도록 래핑
3. **3단계:** 기존 테스트를 파이프라인으로 마이그레이션하며 결과 비교
4. **4단계:** UI 변경 (스플래시 삭제, 이름 스킵, 리스트 수정/삭제, 카테고리 선택)
5. **5단계:** 기존 `nlp_parser.dart` 제거 후 파이프라인 직접 호출

---

## 12. 핵심 개선 포인트 요약

| 항목 | 기존 | 개선 |
|------|------|------|
| 아키텍처 | 단일 함수 (1852줄) | 9개 독립 노드 파이프라인 |
| 문장 분석 | 없음 | 완전/부분/조각 판별 |
| 유형 분류 | 고정 키워드 가중치 | 성장 단계별 동적 키워드 |
| 오류 처리 | 객관식 또는 기타 저장 | 단계별 원인 분석 + 재질문 |
| 디버깅 | 로그만 | 전체 트레이스 (각 노드 입출력) |
| 수정/삭제 | 상세 페이지 | 리스트 인라인 |
| 온보딩 | 스플래시 + 이름 필수 | 바로 시작 + 이름 선택 |
| 카테고리 | 고정 | 분유기/이유식기/유아식기 선택 |
