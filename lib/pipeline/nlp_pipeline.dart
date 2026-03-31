import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/pipeline/growth_stage.dart';
import 'package:chat_baby_time/pipeline/models/node_result.dart';
import 'package:chat_baby_time/pipeline/models/pipeline_result.dart';
import 'package:chat_baby_time/pipeline/models/pipeline_trace.dart';
import 'package:chat_baby_time/pipeline/nodes/field_validation_node.dart';
import 'package:chat_baby_time/pipeline/nodes/input_normalization_node.dart';
import 'package:chat_baby_time/pipeline/nodes/intent_detection_node.dart';
import 'package:chat_baby_time/pipeline/nodes/record_normalization_node.dart';
import 'package:chat_baby_time/pipeline/nodes/sentence_analysis_node.dart';
import 'package:chat_baby_time/pipeline/nodes/type_classification_node.dart';
import 'package:uuid/uuid.dart';

/// 메인 NLP 파이프라인 실행자
/// 9개 노드를 순차 실행하여 입력을 BabyRecord로 변환
///
/// 파이프라인 노드:
/// 1. InputNormalizationNode - 이모지 제거, 공백 정리, 오타 수정
/// 2. SentenceAnalysisNode - 단일/다중 문장, 완성도 분석
/// 3. TypeClassificationNode - 카테고리 분류
/// 4. IntentDetectionNode - 카테고리별 세부 의도 추출
/// 5. RecordNormalizationNode - 시간, 단위 정규화
/// 6. FieldValidationNode - 필드 유효성 검증
/// 7-9. (예약용)
class NlpPipeline {
  /// 성장 단계
  final GrowthStage growthStage;

  /// UUID 생성기
  static const Uuid _uuid = Uuid();

  NlpPipeline({required this.growthStage});

  /// 파이프라인 실행
  ///
  /// 입력: 사용자 원본 텍스트
  /// 출력: PipelineResult (성공/실패, 기록, 추적 정보)
  PipelineResult run(String rawInput) {
    final trace = PipelineTrace();
    var stopwatch = Stopwatch()..start();

    try {
      // Node 1: Input Normalization
      final normalizationResult = InputNormalizationNode.run(rawInput);
      trace.addStep(
        PipelineStep(
          nodeId: InputNormalizationNode.nodeId,
          nodeName: InputNormalizationNode.nodeName,
          success: normalizationResult.success,
          data: normalizationResult.data?.text,
          error: normalizationResult.error,
          debugInfo: normalizationResult.debugInfo,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );

      if (!normalizationResult.success || normalizationResult.data == null) {
        trace.complete();
        return PipelineResult.failure(
          failedNodeId: InputNormalizationNode.nodeId,
          error: normalizationResult.error ?? '정규화 실패',
          trace: trace,
        );
      }

      final normalizedText = normalizationResult.data!.text;
      stopwatch.reset();

      // Node 2: Sentence Analysis
      final sentenceAnalysisResult = SentenceAnalysisNode.run(normalizedText);
      trace.addStep(
        PipelineStep(
          nodeId: SentenceAnalysisNode.nodeId,
          nodeName: SentenceAnalysisNode.nodeName,
          success: sentenceAnalysisResult.success,
          data: sentenceAnalysisResult.data?.toString(),
          error: sentenceAnalysisResult.error,
          debugInfo: sentenceAnalysisResult.debugInfo,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );

      if (!sentenceAnalysisResult.success ||
          sentenceAnalysisResult.data == null) {
        trace.complete();
        return PipelineResult.failure(
          failedNodeId: SentenceAnalysisNode.nodeId,
          error: sentenceAnalysisResult.error ?? '문장 분석 실패',
          trace: trace,
        );
      }

      final sentenceAnalysis = sentenceAnalysisResult.data!;
      stopwatch.reset();

      // 다중 문장 처리
      if (sentenceAnalysis.isMultiSentence) {
        return _processMultipleSentences(
          sentenceAnalysis.segments,
          normalizedText,
          trace,
        );
      }

      // Node 3: Type Classification
      final classificationResult = TypeClassificationNode.run(
        normalizedText: normalizedText,
        sentenceAnalysis: sentenceAnalysis,
        growthStage: growthStage,
      );
      trace.addStep(
        PipelineStep(
          nodeId: TypeClassificationNode.nodeId,
          nodeName: TypeClassificationNode.nodeName,
          success: classificationResult.success,
          data: classificationResult.data?.toString(),
          error: classificationResult.error,
          debugInfo: classificationResult.debugInfo,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );

      if (!classificationResult.success ||
          classificationResult.data == null) {
        trace.complete();
        return PipelineResult.failure(
          failedNodeId: TypeClassificationNode.nodeId,
          error: classificationResult.error ?? '분류 실패',
          trace: trace,
        );
      }

      final classificationData = classificationResult.data!;

      // 명확화 필요 확인
      if (classificationData.needsDisambiguation) {
        trace.complete();
        return PipelineResult.disambiguationRequired(
          disambiguationField: 'category',
          options: [
            classificationData.category,
            if (classificationData.secondaryCategory != null)
              classificationData.secondaryCategory!,
          ],
          trace: trace,
          confidence: classificationData.confidence,
        );
      }

      stopwatch.reset();

      // Node 4: Intent Detection
      final intentResult = IntentDetectionNode.run(
        normalizedText: normalizedText,
        category: classificationData.category,
      );
      trace.addStep(
        PipelineStep(
          nodeId: IntentDetectionNode.nodeId,
          nodeName: IntentDetectionNode.nodeName,
          success: intentResult.success,
          data: intentResult.data?.toString(),
          error: intentResult.error,
          debugInfo: intentResult.debugInfo,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );

      if (!intentResult.success || intentResult.data == null) {
        trace.complete();
        return PipelineResult.failure(
          failedNodeId: IntentDetectionNode.nodeId,
          error: intentResult.error ?? '의도 감지 실패',
          trace: trace,
        );
      }

      final intentData = intentResult.data!;
      stopwatch.reset();

      // Node 5: Record Normalization
      final normalizationRecordResult = RecordNormalizationNode.run(
        timestamp: DateTime.now(),
        amountMl: intentData.amountMl,
        durationMinutes: intentData.durationMinutes,
        temperature: intentData.temperature,
        memo: intentData.memo,
      );
      trace.addStep(
        PipelineStep(
          nodeId: RecordNormalizationNode.nodeId,
          nodeName: RecordNormalizationNode.nodeName,
          success: normalizationRecordResult.success,
          data: normalizationRecordResult.data?.toString(),
          error: normalizationRecordResult.error,
          debugInfo: normalizationRecordResult.debugInfo,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );

      if (!normalizationRecordResult.success ||
          normalizationRecordResult.data == null) {
        trace.complete();
        return PipelineResult.failure(
          failedNodeId: RecordNormalizationNode.nodeId,
          error:
              normalizationRecordResult.error ?? '기록 정규화 실패',
          trace: trace,
        );
      }

      final normalizedValues = normalizationRecordResult.data!;
      stopwatch.reset();

      // Node 6: Field Validation
      final validationResult = FieldValidationNode.run(
        category: classificationData.category,
        amountMl: normalizedValues.amountMl,
        durationMinutes: normalizedValues.durationMinutes,
        temperature: normalizedValues.temperature,
        feedingType: intentData.feedingType,
        sleepStatus: intentData.sleepStatus,
        diaperType: intentData.diaperType,
        medicine: intentData.medicine,
      );
      trace.addStep(
        PipelineStep(
          nodeId: FieldValidationNode.nodeId,
          nodeName: FieldValidationNode.nodeName,
          success: validationResult.success,
          data: validationResult.data?.toString(),
          error: validationResult.error,
          suggestion: validationResult.suggestion,
          debugInfo: validationResult.debugInfo,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );

      if (!validationResult.success) {
        trace.complete();
        return PipelineResult.failure(
          failedNodeId: FieldValidationNode.nodeId,
          error: validationResult.error ?? '필드 검증 실패',
          suggestion: validationResult.suggestion,
          trace: trace,
        );
      }

      // BabyRecord 생성
      final record = BabyRecord(
        id: _uuid.v4(),
        category: classificationData.category,
        timestamp: normalizedValues.timestamp,
        rawInput: rawInput,
        feedingType: intentData.feedingType,
        amountMl: normalizedValues.amountMl,
        durationMinutes: normalizedValues.durationMinutes,
        sleepStatus: intentData.sleepStatus,
        diaperType: intentData.diaperType,
        temperature: normalizedValues.temperature,
        medicine: intentData.medicine,
        memo: normalizedValues.memo,
        inputSource: 'chat',
      );

      trace.complete();

      return PipelineResult.success(
        record: record,
        trace: trace,
        confidence: classificationData.confidence,
      );
    } catch (e) {
      trace.complete();
      return PipelineResult.failure(
        failedNodeId: 'unknown',
        error: '파이프라인 실행 중 오류: ${e.toString()}',
        trace: trace,
      );
    }
  }

  /// 다중 문장 처리
  PipelineResult _processMultipleSentences(
    List<String> segments,
    String normalizedText,
    PipelineTrace trace,
  ) {
    final records = <BabyRecord>[];

    for (final segment in segments) {
      if (segment.isEmpty) continue;

      // 각 세그먼트에 대해 파이프라인 재실행
      final segmentResult = run(segment);

      if (segmentResult.success && segmentResult.record != null) {
        records.add(segmentResult.record!);
      }
    }

    if (records.isEmpty) {
      trace.complete();
      return PipelineResult.failure(
        failedNodeId: 'multi_sentence_processing',
        error: '다중 문장 처리 실패',
        trace: trace,
      );
    }

    trace.complete();

    return PipelineResult.successMulti(
      records: records,
      trace: trace,
      confidence: 0.8,
    );
  }

  /// 컨텍스트와 함께 파이프라인 재실행
  /// 사용자 재질문 응답 후 추가 정보를 적용하여 다시 실행
  ///
  /// 예: feedingType을 명확화한 후 재실행
  PipelineResult runWithContext(
    String rawInput,
    Map<String, dynamic> context,
  ) {
    final trace = PipelineTrace();

    try {
      // 컨텍스트 정보를 기반으로 기본 처리
      // 예: category가 명확화되었다면 분류 노드 스킵

      // 전체 파이프라인 실행하되, 컨텍스트 정보 적용
      var result = run(rawInput);

      // 컨텍스트 정보 병합
      if (result.success && result.record != null) {
        final record = result.record!;

        // 컨텍스트에서 필드 정보 추출 및 적용
        final updatedRecord = BabyRecord(
          id: record.id,
          category: context['category'] as RecordCategory? ?? record.category,
          timestamp: context['timestamp'] as DateTime? ?? record.timestamp,
          rawInput: record.rawInput,
          feedingType: context['feedingType'] as FeedingType? ?? record.feedingType,
          amountMl: context['amountMl'] as int? ?? record.amountMl,
          durationMinutes: context['durationMinutes'] as int? ?? record.durationMinutes,
          sleepStatus: context['sleepStatus'] as SleepStatus? ?? record.sleepStatus,
          diaperType: context['diaperType'] as DiaperType? ?? record.diaperType,
          temperature: context['temperature'] as double? ?? record.temperature,
          medicine: context['medicine'] as String? ?? record.medicine,
          memo: context['memo'] as String? ?? record.memo,
          inputSource: record.inputSource,
          createdAt: record.createdAt,
        );

        return PipelineResult.success(
          record: updatedRecord,
          trace: result.trace,
          confidence: result.confidence,
        );
      }

      return result;
    } catch (e) {
      trace.complete();
      return PipelineResult.failure(
        failedNodeId: 'unknown',
        error: '컨텍스트 파이프라인 실행 중 오류: ${e.toString()}',
        trace: trace,
      );
    }
  }
}
