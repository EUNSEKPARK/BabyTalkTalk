/// NLP 분석 로그 데이터 모델
///
/// 사용자 입력 → NLP 파싱 결과 → 사용자 수정 여부를 모두 기록하여
/// 추후 NLP 엔진 개선에 활용합니다.

class NlpLog {
  final String id;
  final DateTime timestamp;

  // ── 입력 정보 ──
  final String rawInput;          // 원본 입력 텍스트
  final String inputSource;       // "keyboard" | "voice" | "quickAction"

  // ── NLP 파싱 결과 ──
  final String detectedCategory;  // feeding | sleep | diaper | health | other
  final double confidence;
  final Map<String, double> scores; // {feeding: 4.5, sleep: 0, diaper: 0, health: 0}
  final String? detectedSubType;  // feedingType, sleepStatus, diaperType 등
  final String? parsedTimeSource; // "현재시간", "8시 추론", "30분 전" 등

  // ── 앱 동작 ──
  final String appAction;         // "autoSaved" | "confirmCard" | "rejected"

  // ── 사용자 수정 ──
  final bool wasEdited;           // 사용자가 카테고리를 수정했는지
  final String? correctedCategory; // 수정된 카테고리 (null = 수정 안함)
  final bool wasConfirmed;        // 확인 카드에서 "저장" 눌렀는지
  final bool wasCancelled;        // 확인 카드에서 "취소" 눌렀는지

  // ── 사용 패턴 ──
  final int hourOfDay;            // 입력 시각 (0~23)
  final int dayOfWeek;            // 요일 (1=월 ~ 7=일)
  final int inputLength;          // 입력 글자 수
  final int responseTimeMs;       // 파싱 소요 시간 (ms)

  // ── 메타 ──
  final String appVersion;
  final String deviceId;          // 익명 디바이스 ID (UUID)

  NlpLog({
    required this.id,
    required this.timestamp,
    required this.rawInput,
    required this.inputSource,
    required this.detectedCategory,
    required this.confidence,
    required this.scores,
    this.detectedSubType,
    this.parsedTimeSource,
    required this.appAction,
    this.wasEdited = false,
    this.correctedCategory,
    this.wasConfirmed = false,
    this.wasCancelled = false,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.inputLength,
    required this.responseTimeMs,
    required this.appVersion,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'rawInput': rawInput,
    'inputSource': inputSource,
    'detectedCategory': detectedCategory,
    'confidence': confidence,
    'scores': scores,
    'detectedSubType': detectedSubType,
    'parsedTimeSource': parsedTimeSource,
    'appAction': appAction,
    'wasEdited': wasEdited,
    'correctedCategory': correctedCategory,
    'wasConfirmed': wasConfirmed,
    'wasCancelled': wasCancelled,
    'hourOfDay': hourOfDay,
    'dayOfWeek': dayOfWeek,
    'inputLength': inputLength,
    'responseTimeMs': responseTimeMs,
    'appVersion': appVersion,
    'deviceId': deviceId,
  };

  factory NlpLog.fromJson(Map<String, dynamic> json) => NlpLog(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    rawInput: json['rawInput'] as String,
    inputSource: json['inputSource'] as String,
    detectedCategory: json['detectedCategory'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    scores: Map<String, double>.from(
      (json['scores'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
    ),
    detectedSubType: json['detectedSubType'] as String?,
    parsedTimeSource: json['parsedTimeSource'] as String?,
    appAction: json['appAction'] as String,
    wasEdited: json['wasEdited'] as bool? ?? false,
    correctedCategory: json['correctedCategory'] as String?,
    wasConfirmed: json['wasConfirmed'] as bool? ?? false,
    wasCancelled: json['wasCancelled'] as bool? ?? false,
    hourOfDay: json['hourOfDay'] as int,
    dayOfWeek: json['dayOfWeek'] as int,
    inputLength: json['inputLength'] as int,
    responseTimeMs: json['responseTimeMs'] as int,
    appVersion: json['appVersion'] as String,
    deviceId: json['deviceId'] as String,
  );

  /// 수정 정보 업데이트된 새 로그 반환
  NlpLog copyWithCorrection({
    String? correctedCategory,
    bool? wasConfirmed,
    bool? wasCancelled,
  }) => NlpLog(
    id: id,
    timestamp: timestamp,
    rawInput: rawInput,
    inputSource: inputSource,
    detectedCategory: detectedCategory,
    confidence: confidence,
    scores: scores,
    detectedSubType: detectedSubType,
    parsedTimeSource: parsedTimeSource,
    appAction: appAction,
    wasEdited: correctedCategory != null,
    correctedCategory: correctedCategory,
    wasConfirmed: wasConfirmed ?? this.wasConfirmed,
    wasCancelled: wasCancelled ?? this.wasCancelled,
    hourOfDay: hourOfDay,
    dayOfWeek: dayOfWeek,
    inputLength: inputLength,
    responseTimeMs: responseTimeMs,
    appVersion: appVersion,
    deviceId: deviceId,
  );
}
