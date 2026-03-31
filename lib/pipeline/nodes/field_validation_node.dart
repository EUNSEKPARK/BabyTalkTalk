import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/pipeline/models/node_result.dart';

/// 필드 검증 노드
/// - BabyRecord 필드 유효성 검증
/// - 범위 체크 (수량, 체온 등)
/// - 필수 필드 확인
/// - 경고/에러 반환
class FieldValidationNode {
  static const String nodeId = 'field_validation';
  static const String nodeName = '필드 검증';

  static NodeResult<ValidationResult> run({
    required RecordCategory category,
    required int? amountMl,
    required int? durationMinutes,
    required double? temperature,
    required FeedingType? feedingType,
    required SleepStatus? sleepStatus,
    required DiaperType? diaperType,
    required String? medicine,
  }) {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // 카테고리별 검증
      switch (category) {
        case RecordCategory.feeding:
          _validateFeeding(
            amountMl,
            durationMinutes,
            feedingType,
            errors,
            warnings,
          );
          break;

        case RecordCategory.sleep:
          _validateSleep(sleepStatus, durationMinutes, errors, warnings);
          break;

        case RecordCategory.diaper:
          _validateDiaper(diaperType, errors, warnings);
          break;

        case RecordCategory.health:
          _validateHealth(temperature, medicine, errors, warnings);
          break;

        case RecordCategory.babyfood:
          _validateBabyfood(amountMl, errors, warnings);
          break;

        case RecordCategory.snack:
          _validateSnack(errors, warnings);
          break;

        case RecordCategory.milestone:
        case RecordCategory.other:
          // 최소한의 검증
          break;
      }

      final isValid = errors.isEmpty;

      final result = ValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        category: category,
      );

      if (!isValid) {
        return NodeResult.failure(
          error: errors.join(', '),
          suggestion: _generateSuggestion(category, errors),
          debugInfo: {
            'errors': errors,
            'warnings': warnings,
          },
        );
      }

      return NodeResult.success(
        data: result,
        debugInfo: {
          'warnings': warnings,
        },
      );
    } catch (e) {
      return NodeResult.failure(
        error: '필드 검증 실패: ${e.toString()}',
        debugInfo: {'error': e.toString()},
      );
    }
  }

  /// 수유 필드 검증
  static void _validateFeeding(
    int? amountMl,
    int? durationMinutes,
    FeedingType? feedingType,
    List<String> errors,
    List<String> warnings,
  ) {
    // 수유 타입은 기본값으로 처리되므로 필수 아님

    // 수량 검증
    if (amountMl != null) {
      if (amountMl < 10) {
        errors.add('수량이 너무 작음 (최소 10ml)');
      } else if (amountMl > 500) {
        warnings.add('수량이 매우 많음 (일반적으로 500ml 이하)');
      }
    } else if (feedingType == FeedingType.formula || feedingType == FeedingType.breast) {
      warnings.add('수량 정보가 없음');
    }

    // 수유 시간 검증
    if (durationMinutes != null && durationMinutes < 1) {
      warnings.add('수유 시간이 너무 짧음');
    }
  }

  /// 수면 필드 검증
  static void _validateSleep(
    SleepStatus? sleepStatus,
    int? durationMinutes,
    List<String> errors,
    List<String> warnings,
  ) {
    // 수면 상태는 필수
    if (sleepStatus == null) {
      errors.add('수면 상태 불명확 (시작/종료)');
    }

    // 수면 시간 검증
    if (durationMinutes != null) {
      if (durationMinutes < 1) {
        warnings.add('수면 시간이 너무 짧음 (최소 1분)');
      } else if (durationMinutes > 720) {
        // 12시간 이상
        warnings.add('수면 시간이 매우 길음');
      }
    }
  }

  /// 기저귀 필드 검증
  static void _validateDiaper(
    DiaperType? diaperType,
    List<String> errors,
    List<String> warnings,
  ) {
    // 기저귀 타입은 기본값(소변)으로 처리
    if (diaperType == null) {
      warnings.add('기저귀 타입 불명확');
    }
  }

  /// 건강 필드 검증
  static void _validateHealth(
    double? temperature,
    String? medicine,
    List<String> errors,
    List<String> warnings,
  ) {
    // 체온 검증
    if (temperature != null) {
      if (temperature < 34.0) {
        errors.add('체온이 너무 낮음 (최소 34°C)');
      } else if (temperature > 42.0) {
        errors.add('체온이 너무 높음 (최대 42°C)');
      } else if (temperature >= 38.0) {
        warnings.add('고열 상태 (38°C 이상)');
      }
    } else {
      warnings.add('체온 정보가 없음');
    }

    // 약 정보
    if (medicine == null || medicine.isEmpty) {
      warnings.add('약 정보가 없음');
    }
  }

  /// 이유식 필드 검증
  static void _validateBabyfood(
    int? amountMl,
    List<String> errors,
    List<String> warnings,
  ) {
    if (amountMl != null) {
      if (amountMl < 10) {
        errors.add('수량이 너무 작음 (최소 10ml)');
      } else if (amountMl > 300) {
        warnings.add('수량이 많음 (일반적으로 300ml 이하)');
      }
    } else {
      warnings.add('수량 정보가 없음');
    }
  }

  /// 간식 필드 검증
  static void _validateSnack(
    List<String> errors,
    List<String> warnings,
  ) {
    // 간식은 최소한의 검증
    warnings.add('간식 정보 확인 권장');
  }

  /// 제안 메시지 생성
  static String _generateSuggestion(
    RecordCategory category,
    List<String> errors,
  ) {
    switch (category) {
      case RecordCategory.feeding:
        return '수유 기록을 다시 입력해주세요. (예: 분유 150ml)';
      case RecordCategory.sleep:
        return '수면 상태를 명확히 해주세요. (예: 잠들었어, 깼어)';
      case RecordCategory.diaper:
        return '기저귀 기록을 다시 입력해주세요. (예: 대변 봤어)';
      case RecordCategory.health:
        return '건강 정보를 다시 입력해주세요. (예: 체온 37.5도)';
      case RecordCategory.babyfood:
        return '이유식 기록을 다시 입력해주세요. (예: 이유식 100ml)';
      case RecordCategory.snack:
        return '간식 기록을 다시 입력해주세요.';
      case RecordCategory.milestone:
      case RecordCategory.other:
        return '기록을 다시 입력해주세요.';
    }
  }
}

/// 검증 결과
class ValidationResult {
  /// 검증 성공 여부
  final bool isValid;

  /// 에러 목록
  final List<String> errors;

  /// 경고 목록
  final List<String> warnings;

  /// 카테고리
  final RecordCategory category;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.category,
  });

  /// 심각도 있는 에러인지 확인
  bool get hasSeriosError => errors.any((e) =>
      e.contains('필수') || e.contains('범위') || e.contains('없음'));

  /// 결과 요약
  String get summary {
    if (isValid && warnings.isEmpty) {
      return '모든 필드가 유효합니다.';
    } else if (isValid && warnings.isNotEmpty) {
      return '유효하지만 경고: ${warnings.join(', ')}';
    } else {
      return '에러: ${errors.join(', ')}';
    }
  }

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}
