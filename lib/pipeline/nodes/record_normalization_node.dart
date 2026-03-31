import 'package:chat_baby_time/pipeline/models/node_result.dart';

/// 기록 정규화 노드
/// - 시간 파싱 (상대/절대)
/// - 단위 정규화 (cc → ml)
/// - 기본값 설정
class RecordNormalizationNode {
  static const String nodeId = 'record_normalization';
  static const String nodeName = '기록 정규화';

  static NodeResult<NormalizedValues> run({
    required DateTime? timestamp,
    required int? amountMl,
    required int? durationMinutes,
    required double? temperature,
    required String? memo,
  }) {
    try {
      // 1. 시간 정규화
      final normalizedTimestamp = timestamp ?? DateTime.now();

      // 2. 수량 정규화 (cc → ml, 범위 검증)
      final normalizedAmount = _normalizeAmount(amountMl);

      // 3. 시간 정규화 (분 단위)
      final normalizedDuration = durationMinutes;

      // 4. 체온 정규화
      final normalizedTemperature = _normalizeTemperature(temperature);

      // 5. 메모 정규화
      final normalizedMemo = _normalizeMemo(memo);

      final result = NormalizedValues(
        timestamp: normalizedTimestamp,
        amountMl: normalizedAmount,
        durationMinutes: normalizedDuration,
        temperature: normalizedTemperature,
        memo: normalizedMemo,
      );

      return NodeResult.success(data: result);
    } catch (e) {
      return NodeResult.failure(
        error: '기록 정규화 실패: ${e.toString()}',
        debugInfo: {'error': e.toString()},
      );
    }
  }

  /// 시간 파싱 (상대/절대)
  static DateTime parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return DateTime.now();
    }

    // 절대 시간 (예: 오후 2시, 14:30)
    if (timeString.contains('오전') || timeString.contains('오후')) {
      return _parseAbsoluteTime(timeString);
    }

    // 상대 시간 (예: 30분 전, 2시간 전)
    if (timeString.contains('분') || timeString.contains('시간')) {
      return _parseRelativeTime(timeString);
    }

    // 단순 표현 (방금, 아까)
    if (timeString.contains('방금')) {
      return DateTime.now();
    }
    if (timeString.contains('아까') || timeString.contains('아니까')) {
      return DateTime.now().subtract(const Duration(minutes: 10));
    }

    return DateTime.now();
  }

  /// 절대 시간 파싱
  static DateTime _parseAbsoluteTime(String timeString) {
    final now = DateTime.now();
    final hour = _extractNumber(timeString) ?? now.hour;
    var parsedHour = hour;

    if (timeString.contains('오전') && hour == 12) {
      parsedHour = 0;
    } else if (timeString.contains('오후') && hour != 12) {
      parsedHour = hour + 12;
    }

    return DateTime(now.year, now.month, now.day, parsedHour);
  }

  /// 상대 시간 파싱
  static DateTime _parseRelativeTime(String timeString) {
    final number = _extractNumber(timeString);
    if (number == null) return DateTime.now();

    if (timeString.contains('분')) {
      return DateTime.now().subtract(Duration(minutes: number));
    } else if (timeString.contains('시간')) {
      return DateTime.now().subtract(Duration(hours: number));
    }

    return DateTime.now();
  }

  /// 수량 정규화
  static int? _normalizeAmount(int? amount) {
    if (amount == null) return null;

    // cc를 ml로 변환 (1cc = 1ml)
    // 범위 검증: 10ml ~ 500ml
    if (amount < 10) return null;
    if (amount > 500) return 500; // 상한선

    return amount;
  }

  /// 체온 정규화
  static double? _normalizeTemperature(double? temp) {
    if (temp == null) return null;

    // 범위: 34°C ~ 42°C
    if (temp < 34.0 || temp > 42.0) {
      return null; // 유효하지 않은 범위
    }

    return temp;
  }

  /// 메모 정규화
  static String? _normalizeMemo(String? memo) {
    if (memo == null || memo.isEmpty) return null;
    return memo.trim();
  }

  /// 텍스트에서 숫자 추출
  static int? _extractNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}

/// 정규화된 값들
class NormalizedValues {
  /// 타임스탬프
  final DateTime timestamp;

  /// 수량 (ml)
  final int? amountMl;

  /// 시간 (분)
  final int? durationMinutes;

  /// 체온 (°C)
  final double? temperature;

  /// 메모
  final String? memo;

  NormalizedValues({
    required this.timestamp,
    this.amountMl,
    this.durationMinutes,
    this.temperature,
    this.memo,
  });

  @override
  String toString() {
    return 'NormalizedValues('
        'timestamp: ${timestamp.toString().substring(0, 16)}, '
        'amountMl: $amountMl, '
        'durationMinutes: $durationMinutes, '
        'temperature: $temperature'
        ')';
  }
}
