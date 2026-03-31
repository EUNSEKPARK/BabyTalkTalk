import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/pipeline/models/node_result.dart';

/// 의도 감지 노드
/// - 카테고리별 세부 의도 추출
/// - 수유 타입, 수량, 시간 추출
/// - 수면 상태 (시작/종료) 판단
/// - 기저귀 타입 판단
/// - 건강 정보 추출 (온도, 약, 예방접종)
class IntentDetectionNode {
  static const String nodeId = 'intent_detection';
  static const String nodeName = '의도 감지';

  static NodeResult<IntentDetectionResult> run({
    required String normalizedText,
    required RecordCategory category,
  }) {
    try {
      final result = IntentDetectionResult(category: category);

      switch (category) {
        case RecordCategory.feeding:
          _detectFeedingIntent(normalizedText, result);
          break;
        case RecordCategory.sleep:
          _detectSleepIntent(normalizedText, result);
          break;
        case RecordCategory.diaper:
          _detectDiaperIntent(normalizedText, result);
          break;
        case RecordCategory.health:
          _detectHealthIntent(normalizedText, result);
          break;
        case RecordCategory.babyfood:
          _detectBabyfoodIntent(normalizedText, result);
          break;
        case RecordCategory.snack:
          _detectSnackIntent(normalizedText, result);
          break;
        case RecordCategory.milestone:
        case RecordCategory.other:
          // 특별한 의도 감지 없음
          break;
      }

      return NodeResult.success(
        data: result,
        debugInfo: result.toDebugMap(),
      );
    } catch (e) {
      return NodeResult.failure(
        error: '의도 감지 실패: ${e.toString()}',
        debugInfo: {'error': e.toString()},
      );
    }
  }

  /// 수유 의도 감지
  static void _detectFeedingIntent(String text, IntentDetectionResult result) {
    // 수유 타입 감지
    if (text.contains('모유')) {
      result.feedingType = FeedingType.breast;
    } else if (text.contains('분유')) {
      result.feedingType = FeedingType.formula;
    } else {
      result.feedingType = FeedingType.formula; // 기본값
    }

    // 수량 추출 (ml, cc)
    final amountMatch = RegExp(r'(\d+)\s*(ml|cc)').firstMatch(text);
    if (amountMatch != null) {
      result.amountMl = int.tryParse(amountMatch.group(1) ?? '0');
    }

    // 수유 시간 추출 (분)
    final durationMatch = RegExp(r'(\d+)\s*(분|분간)').firstMatch(text);
    if (durationMatch != null) {
      result.durationMinutes = int.tryParse(durationMatch.group(1) ?? '0');
    }
  }

  /// 수면 의도 감지
  static void _detectSleepIntent(String text, IntentDetectionResult result) {
    // 수면 상태 감지 (시작 vs 종료)
    if (text.contains('깼') ||
        text.contains('깨') ||
        text.contains('일어났') ||
        text.contains('깸')) {
      result.sleepStatus = SleepStatus.end;
    } else if (text.contains('잤') ||
        text.contains('잠들') ||
        text.contains('낮잠') ||
        text.contains('밤잠')) {
      result.sleepStatus = SleepStatus.start;
    }

    // 수면 시간 추출
    final durationMatch = RegExp(r'(\d+)\s*(시간|분)').firstMatch(text);
    if (durationMatch != null) {
      final value = int.tryParse(durationMatch.group(1) ?? '0') ?? 0;
      final unit = durationMatch.group(2);
      if (unit == '시간') {
        result.durationMinutes = value * 60;
      } else {
        result.durationMinutes = value;
      }
    }
  }

  /// 기저귀 의도 감지
  static void _detectDiaperIntent(String text, IntentDetectionResult result) {
    final hasPee = text.contains('소변') ||
        text.contains('오줌') ||
        text.contains('쌔') ||
        text.contains('누');
    final hasPoop = text.contains('대변') ||
        text.contains('응가') ||
        text.contains('똥') ||
        text.contains('쌌');

    if (hasPee && hasPoop) {
      result.diaperType = DiaperType.both;
    } else if (hasPoop) {
      result.diaperType = DiaperType.poop;
    } else {
      result.diaperType = DiaperType.pee;
    }
  }

  /// 건강 의도 감지
  static void _detectHealthIntent(String text, IntentDetectionResult result) {
    // 체온 추출
    final tempMatch = RegExp(r'(\d{2}\.?\d?)\s*(도|°|℃)').firstMatch(text);
    if (tempMatch != null) {
      result.temperature = double.tryParse(tempMatch.group(1) ?? '0.0');
    }

    // 약 이름 추출 (간단한 패턴)
    if (text.contains('감기약')) {
      result.medicine = '감기약';
    } else if (text.contains('해열제')) {
      result.medicine = '해열제';
    } else if (text.contains('소화제')) {
      result.medicine = '소화제';
    } else if (text.contains('항생제')) {
      result.medicine = '항생제';
    } else {
      // 약 키워드로 시작하는 경우
      final medicineMatch = RegExp(r'약\s*[:：]\s*(.+?)(?:\.|,|$)', caseSensitive: false)
          .firstMatch(text);
      if (medicineMatch != null) {
        result.medicine = medicineMatch.group(1)?.trim();
      }
    }

    // 예방접종 감지
    if (text.contains('예방접종')) {
      result.memo = '예방접종';
    }
  }

  /// 이유식 의도 감지
  static void _detectBabyfoodIntent(String text, IntentDetectionResult result) {
    // 수량 추출
    final amountMatch = RegExp(r'(\d+)\s*(ml|cc|스푼|숟가락)').firstMatch(text);
    if (amountMatch != null) {
      result.amountMl = int.tryParse(amountMatch.group(1) ?? '0');
    }

    // 재료/메뉴 추출
    const ingredients = [
      '소고기',
      '닭고기',
      '생선',
      '계란',
      '감자',
      '고구마',
      '브로콜리',
      '당근',
      '옥수수',
      '시금치',
      '포도',
      '딸기',
      '바나나',
      '사과',
    ];

    final detectedIngredients = ingredients.where((ing) => text.contains(ing)).toList();
    if (detectedIngredients.isNotEmpty) {
      result.memo = detectedIngredients.join(', ');
    }
  }

  /// 간식 의도 감지
  static void _detectSnackIntent(String text, IntentDetectionResult result) {
    // 수량 추출
    final amountMatch = RegExp(r'(\d+)\s*개').firstMatch(text);
    if (amountMatch != null) {
      result.memo = '${amountMatch.group(1)}개';
    }

    // 간식 종류 추출
    const snacks = [
      '요거트',
      '요구르트',
      '치즈',
      '쿠키',
      '크래커',
      '바나나',
      '딸기',
      '포도',
      '수박',
      '당근',
      '옥수수',
    ];

    final detectedSnacks = snacks.where((snack) => text.contains(snack)).toList();
    if (detectedSnacks.isNotEmpty) {
      result.memo = detectedSnacks.join(', ');
    }
  }
}

/// 의도 감지 결과
class IntentDetectionResult {
  /// 카테고리
  final RecordCategory category;

  /// 수유 타입 (feeding 카테고리)
  FeedingType? feedingType;

  /// 수량 (ml)
  int? amountMl;

  /// 수유/수면 시간 (분)
  int? durationMinutes;

  /// 수면 상태 (sleep 카테고리)
  SleepStatus? sleepStatus;

  /// 기저귀 타입 (diaper 카테고리)
  DiaperType? diaperType;

  /// 체온 (health 카테고리)
  double? temperature;

  /// 약 이름 (health 카테고리)
  String? medicine;

  /// 메모/추가 정보
  String? memo;

  IntentDetectionResult({required this.category});

  /// 필드 추출 여부 확인
  bool get hasAnyExtractedField {
    return feedingType != null ||
        amountMl != null ||
        durationMinutes != null ||
        sleepStatus != null ||
        diaperType != null ||
        temperature != null ||
        medicine != null ||
        memo != null;
  }

  /// 디버그 정보로 변환
  Map<String, dynamic> toDebugMap() {
    return {
      'category': category.toString(),
      'feedingType': feedingType?.toString(),
      'amountMl': amountMl,
      'durationMinutes': durationMinutes,
      'sleepStatus': sleepStatus?.toString(),
      'diaperType': diaperType?.toString(),
      'temperature': temperature,
      'medicine': medicine,
      'memo': memo,
    };
  }

  @override
  String toString() {
    return 'IntentDetectionResult(category: $category, hasFields: $hasAnyExtractedField)';
  }
}
