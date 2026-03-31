import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/pipeline/models/pipeline_trace.dart';

/// 파이프라인 실행 결과
class PipelineResult {
  /// 전체 실행 성공 여부
  final bool success;

  /// 단일 기록 (성공 시)
  final BabyRecord? record;

  /// 다중 기록 (멀티 센텐스 처리 시)
  final List<BabyRecord>? records;

  /// 실패한 노드 ID
  final String? failedNodeId;

  /// 에러 메시지
  final String? error;

  /// 사용자 재질문 제안
  final String? suggestion;

  /// 파이프라인 실행 추적 정보
  final PipelineTrace trace;

  /// 명확화(disambiguation) 필요 여부
  final bool needsDisambiguation;

  /// 명확화 옵션 (예: [FeedingType.breast, FeedingType.formula])
  final List<dynamic>? disambiguationOptions;

  /// 명확화 필드명 (예: 'feedingType')
  final String? disambiguationField;

  /// 신뢰도 (0.0 ~ 1.0)
  final double confidence;

  PipelineResult({
    required this.success,
    this.record,
    this.records,
    this.failedNodeId,
    this.error,
    this.suggestion,
    required this.trace,
    this.needsDisambiguation = false,
    this.disambiguationOptions,
    this.disambiguationField,
    this.confidence = 1.0,
  });

  /// 성공한 결과 생성 (단일 기록)
  factory PipelineResult.success({
    required BabyRecord record,
    required PipelineTrace trace,
    double confidence = 1.0,
  }) {
    return PipelineResult(
      success: true,
      record: record,
      trace: trace,
      confidence: confidence,
    );
  }

  /// 성공한 결과 생성 (다중 기록)
  factory PipelineResult.successMulti({
    required List<BabyRecord> records,
    required PipelineTrace trace,
    double confidence = 1.0,
  }) {
    return PipelineResult(
      success: true,
      records: records,
      trace: trace,
      confidence: confidence,
    );
  }

  /// 실패한 결과 생성
  factory PipelineResult.failure({
    required String failedNodeId,
    required String error,
    String? suggestion,
    required PipelineTrace trace,
  }) {
    return PipelineResult(
      success: false,
      failedNodeId: failedNodeId,
      error: error,
      suggestion: suggestion,
      trace: trace,
    );
  }

  /// 명확화가 필요한 결과 생성
  factory PipelineResult.disambiguationRequired({
    required String disambiguationField,
    required List<dynamic> options,
    required PipelineTrace trace,
    double confidence = 0.5,
  }) {
    return PipelineResult(
      success: false,
      needsDisambiguation: true,
      disambiguationField: disambiguationField,
      disambiguationOptions: options,
      trace: trace,
      confidence: confidence,
    );
  }

  /// 신뢰도가 낮은 경우 명확화 필요 확인
  bool get shouldAskForConfirmation => confidence < 0.7;

  /// 결과 요약 문자열
  String get summary {
    if (needsDisambiguation) {
      return '명확화 필요: $disambiguationField';
    }
    if (!success) {
      return 'Failed at $failedNodeId: $error';
    }
    if (record != null) {
      return '${record!.categoryName} 기록 생성 (신뢰도: ${(confidence * 100).toStringAsFixed(0)}%)';
    }
    if (records != null && records!.isNotEmpty) {
      return '${records!.length}개 기록 생성 (신뢰도: ${(confidence * 100).toStringAsFixed(0)}%)';
    }
    return 'Success';
  }

  /// JSON 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'record': record != null ? _babyRecordToJson(record!) : null,
      'records': records?.map(_babyRecordToJson).toList(),
      'failedNodeId': failedNodeId,
      'error': error,
      'suggestion': suggestion,
      'needsDisambiguation': needsDisambiguation,
      'disambiguationField': disambiguationField,
      'disambiguationOptions': disambiguationOptions,
      'confidence': confidence,
      'trace': trace.toJson(),
    };
  }

  /// BabyRecord를 JSON으로 변환 (Hive 객체 대응)
  static Map<String, dynamic> _babyRecordToJson(BabyRecord record) {
    return {
      'id': record.id,
      'category': record.category.toString(),
      'timestamp': record.timestamp.toIso8601String(),
      'rawInput': record.rawInput,
      'feedingType': record.feedingType?.toString(),
      'amountMl': record.amountMl,
      'durationMinutes': record.durationMinutes,
      'sleepStatus': record.sleepStatus?.toString(),
      'diaperType': record.diaperType?.toString(),
      'temperature': record.temperature,
      'medicine': record.medicine,
      'memo': record.memo,
      'inputSource': record.inputSource,
      'createdAt': record.createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PipelineResult(success: $success, summary: $summary)';
  }
}
