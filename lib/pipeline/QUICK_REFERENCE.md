# NLP Pipeline Quick Reference

## File Structure

```
lib/pipeline/
├── ARCHITECTURE.md                          # Detailed architecture documentation
├── QUICK_REFERENCE.md                       # This file
├── growth_stage.dart                        # GrowthStage enum (formula/weaning/toddler)
├── nlp_pipeline.dart                        # Main NlpPipeline class
│
├── models/                                  # Data structures
│   ├── node_result.dart                     # NodeResult<T> - generic result wrapper
│   ├── pipeline_result.dart                 # PipelineResult - final output with trace
│   ├── pipeline_trace.dart                  # PipelineTrace/PipelineStep - execution log
│   └── sentence_analysis_result.dart        # SentenceAnalysisResult - sentence structure
│
├── keywords/
│   └── stage_keywords.dart                  # StageKeywords - keyword database by stage
│
└── nodes/                                   # Pipeline nodes (6 implemented, 3 reserved)
    ├── [1] input_normalization_node.dart    # Emoji removal, whitespace, typo correction
    ├── [2] sentence_analysis_node.dart      # Single/multi, completeness, subject detection
    ├── [3] type_classification_node.dart    # Keyword matching → RecordCategory
    ├── [4] intent_detection_node.dart       # Category-specific intent extraction
    ├── [5] record_normalization_node.dart   # Time/unit parsing, range validation
    └── [6] field_validation_node.dart       # Category-specific field validation
```

## Quick Start

### Basic Usage

```dart
// Create pipeline for a growth stage
final pipeline = NlpPipeline(growthStage: GrowthStage.weaning);

// Run on user input
final result = pipeline.run("분유 150ml 먹었어");

if (result.success) {
  final record = result.record;  // BabyRecord object
  // Save to database
} else {
  print("Error: ${result.error}");
  print("Suggestion: ${result.suggestion}");
}
```

### Multi-Sentence Handling

```dart
final result = pipeline.run("분유 150ml 먹었어. 낮잠 2시간 잤어");
// Automatically splits and processes each sentence

if (result.records != null) {
  // Handle multiple records
  for (final record in result.records!) {
    // Save each record
  }
}
```

### Disambiguation

```dart
if (result.needsDisambiguation) {
  // Show options to user
  final options = result.disambiguationOptions;

  // After user selects, re-run with context
  final finalResult = pipeline.runWithContext(
    "100ml 먹었어",
    {'category': RecordCategory.babyfood},
  );
}
```

### Access Execution Trace

```dart
// Debug pipeline execution
print(result.trace.prettyPrint());

// Or get JSON format
final json = result.trace.toJson();
```

## Key Classes

### NlpPipeline

```dart
class NlpPipeline {
  NlpPipeline({required GrowthStage growthStage});

  // Main methods
  PipelineResult run(String rawInput);
  PipelineResult runWithContext(String rawInput, Map<String, dynamic> context);
}
```

### PipelineResult

```dart
class PipelineResult {
  bool success;
  BabyRecord? record;           // Single record
  List<BabyRecord>? records;    // Multiple records
  bool needsDisambiguation;
  List<dynamic>? disambiguationOptions;
  String? disambiguationField;
  double confidence;            // 0.0 - 1.0
  PipelineTrace trace;

  // Factories
  factory PipelineResult.success({required BabyRecord record, ...});
  factory PipelineResult.successMulti({required List<BabyRecord> records, ...});
  factory PipelineResult.failure({required String failedNodeId, ...});
  factory PipelineResult.disambiguationRequired({...});
}
```

### GrowthStage

```dart
enum GrowthStage {
  formula,   // 0-5 months: breast/formula feeding focus
  weaning,   // 5-15 months: add babyfood, ingredients
  toddler,   // 15+ months: shift to meals, reduced feeding
}
```

## Node Reference

| Node | Input | Output | Purpose |
|------|-------|--------|---------|
| 1. InputNormalization | Raw text | NormalizedInput | Clean input, fix typos, convert numerals |
| 2. SentenceAnalysis | Text | SentenceAnalysisResult | Detect structure, completeness, subject |
| 3. TypeClassification | Text + Analysis | ClassificationResult | Score keywords → category |
| 4. IntentDetection | Text + Category | IntentDetectionResult | Extract amounts, types, specifics |
| 5. RecordNormalization | Intent data | NormalizedValues | Parse times, normalize units |
| 6. FieldValidation | All fields | ValidationResult | Validate ranges, generate suggestions |

## Growth Stage Keywords Summary

### Formula Stage (0-5m)
- **Enabled**: feeding, sleep, diaper, health, other
- **Disabled**: babyfood, snack
- Focus: Breast/formula quantities, sleep/diaper tracking

### Weaning Stage (5-15m)
- **Enabled**: feeding, babyfood, snack, sleep, diaper, health, other
- New keywords: 이유식(3.0), 간식(3.0), ingredients (소고기, 감자, etc.)
- Focus: Introduction to solids, snack tracking

### Toddler Stage (15m+)
- **Enabled**: feeding, babyfood, snack, sleep, diaper, health, other
- New keywords: 밥(3.0), 국(2.0), 메뉴(2.5)
- Reduced: 분유(1.5), 모유(1.5)
- Focus: Meals, reduced milk feeding

## Keyword Matching

Keywords have weights (0.0 - 3.0):
- 3.0: High relevance (분유, 모유, 이유식, 간식, 기저귀, 체온)
- 2.5: Medium relevance (젖병, 깼어, 응가, 예방접종, 과일)
- 2.0: Lower relevance (젖, 먹음, 약, 국, 우유)
- 1.0-1.5: Low relevance (먹었, 먹임, 감기약)

Confidence = min(score / 12.0, 1.0)

## RecordCategory Values

```dart
enum RecordCategory {
  feeding,      // 수유 (breast/formula)
  babyfood,     // 이유식 (0-5m: disabled, 5m+: enabled)
  snack,        // 간식 (0-5m: disabled, 5m+: enabled)
  sleep,        // 수면
  diaper,       // 기저귀
  health,       // 건강 (온도, 약, 예방접종)
  milestone,    // 성장 기록
  other,        // 기타
}
```

## Common Input Patterns

| Input | Category | Result |
|-------|----------|--------|
| "분유 150ml 먹었어" | feeding | amount: 150ml |
| "모유 30분" | feeding | duration: 30min |
| "이유식 100ml 소고기" | babyfood | amount: 100ml, memo: 소고기 |
| "간식 요거트" | snack | memo: 요거트 |
| "낮잠 2시간 잤어" | sleep | status: start, duration: 120min |
| "깼어" | sleep | status: end |
| "대변 봤어" | diaper | type: poop |
| "체온 37.5도" | health | temperature: 37.5 |
| "예방접종 했어" | health | memo: 예방접종 |

## Error Handling

Common errors and their suggestions:

| Error | Suggestion |
|-------|-----------|
| "의도 표현으로 감지됨" | 실제 기록 아님 (해야, 먹을래 등) |
| "체온이 범위를 벗어남" | 체온을 다시 입력해주세요. (34-42°C) |
| "수량이 너무 작음" | 수량을 다시 입력해주세요. (최소 10ml) |
| "수면 상태 불명확" | 수면 상태를 명확히 해주세요. (잠들었어, 깼어) |

## Confidence Levels

- **≥0.9**: High confidence → Auto-save
- **0.7-0.9**: Medium confidence → Show preview for confirmation
- **<0.7**: Low confidence → Ask user to rephrase
- **Disambiguation**: Return multiple options, ask user to select

## Debug Output Example

```
============================================================
NLP Pipeline Trace
============================================================
Start Time: 2024-01-15 14:30:45.123456
End Time: 2024-01-15 14:30:45.175234
Total Duration: 51ms
Steps: 6 (6 success, 0 failed)
────────────────────────────────────────────────────────────
0. [✓] input_normalization: 입력 정규화 (5ms)
   Data: 분유 150ml 먹었어
   Debug: {corrections: 0, removedEmojis: 0}

1. [✓] sentence_analysis: 문장 분석 (3ms)
   Data: SentenceAnalysisResult(count: single, completeness: complete, ...)
   Debug: {segmentCount: 1, completeness: complete, verbs: 1}

2. [✓] type_classification: 타입 분류 (8ms)
   Data: ClassificationResult(category: feeding, confidence: 0.95, ...)
   Debug: {topScore: "11.50", confidence: "0.95"}

3. [✓] intent_detection: 의도 감지 (7ms)
   Data: IntentDetectionResult(category: feeding, hasFields: true)
   Debug: {feedingType: FeedingType.formula, amountMl: 150}

4. [✓] record_normalization: 기록 정규화 (4ms)
   Data: NormalizedValues(timestamp: 2024-01-15 14:30:45, amountMl: 150)

5. [✓] field_validation: 필드 검증 (6ms)
   Data: ValidationResult(isValid: true)
============================================================
```

## Imports

Add these to your Dart files:

```dart
import 'package:chat_baby_time/pipeline/nlp_pipeline.dart';
import 'package:chat_baby_time/pipeline/growth_stage.dart';
import 'package:chat_baby_time/pipeline/models/pipeline_result.dart';
import 'package:chat_baby_time/pipeline/keywords/stage_keywords.dart';
```

## Tips

1. **Always check** `result.success` and `result.trace` for debugging
2. **Handle disambiguation** when `result.needsDisambiguation` is true
3. **Use context** when rerunning after user clarification
4. **Cache keywords** by creating a single `StageKeywords` instance per stage
5. **Batch process** multiple inputs sequentially, not in parallel (not thread-safe)
6. **Confidence matters**: Show confirmation UI for scores < 0.8

## Known Limitations

- No real-time input processing (processes complete sentences only)
- Keyword-based classification (no ML models)
- Korean language only
- No speech-to-text integration (external)
- No context retention between multiple runs (except via `runWithContext`)
