import 'package:chat_baby_time/models/baby_record.dart';

/// 루틴 조건 타입
enum RoutineTriggerType {
  /// 매일 고정 시각 (예: 매일 08:00)
  fixedTime,

  /// 마지막 기록 이후 N분 경과
  sinceLastRecord,
}

/// 스누즈(다시 알림) 정책
class SnoozePolicy {
  /// 스누즈 간격(분)
  final int intervalMinutes;

  /// 최대 스누즈 횟수 (0이면 무제한)
  final int maxCount;

  const SnoozePolicy({
    this.intervalMinutes = 10,
    this.maxCount = 3,
  });

  Map<String, dynamic> toJson() => {
        'intervalMinutes': intervalMinutes,
        'maxCount': maxCount,
      };

  factory SnoozePolicy.fromJson(Map<String, dynamic> j) => SnoozePolicy(
        intervalMinutes: (j['intervalMinutes'] as int?) ?? 10,
        maxCount: (j['maxCount'] as int?) ?? 3,
      );
}

/// 카테고리별 기본값 맵 (예: 수유 → amountMl: 160)
class RecordDefaults {
  final FeedingType? feedingType;
  final int? amountMl;
  final int? durationMinutes;
  final DiaperType? diaperType;
  final SleepStatus? sleepStatus;

  const RecordDefaults({
    this.feedingType,
    this.amountMl,
    this.durationMinutes,
    this.diaperType,
    this.sleepStatus,
  });

  Map<String, dynamic> toJson() => {
        if (feedingType != null) 'feedingType': feedingType!.index,
        if (amountMl != null) 'amountMl': amountMl,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (diaperType != null) 'diaperType': diaperType!.index,
        if (sleepStatus != null) 'sleepStatus': sleepStatus!.index,
      };

  factory RecordDefaults.fromJson(Map<String, dynamic> j) {
    FeedingType? ft;
    final ftIdx = j['feedingType'] as int?;
    if (ftIdx != null && ftIdx >= 0 && ftIdx < FeedingType.values.length) {
      ft = FeedingType.values[ftIdx];
    }
    DiaperType? dt;
    final dtIdx = j['diaperType'] as int?;
    if (dtIdx != null && dtIdx >= 0 && dtIdx < DiaperType.values.length) {
      dt = DiaperType.values[dtIdx];
    }
    SleepStatus? ss;
    final ssIdx = j['sleepStatus'] as int?;
    if (ssIdx != null && ssIdx >= 0 && ssIdx < SleepStatus.values.length) {
      ss = SleepStatus.values[ssIdx];
    }
    return RecordDefaults(
      feedingType: ft,
      amountMl: (j['amountMl'] as int?),
      durationMinutes: (j['durationMinutes'] as int?),
      diaperType: dt,
      sleepStatus: ss,
    );
  }
}

/// 개별 루틴 정의
class Routine {
  /// 고유 ID (UUID)
  final String id;

  /// 사용자가 지정한 루틴 이름 (예: "분유 수유", "기저귀 체크")
  final String name;

  /// 대상 기록 카테고리
  final RecordCategory targetCategory;

  /// 트리거 조건 타입
  final RoutineTriggerType triggerType;

  /// fixedTime → 시:분, sinceLastRecord → 사용 안함
  final int? fixedHour;
  final int? fixedMinute;

  /// sinceLastRecord → 간격(분)
  final int? intervalMinutes;

  /// 스마트 간격 사용 여부 (최근 기록 5개 평균으로 자동 계산)
  final bool useSmartInterval;

  /// 빠른 기록 시 사용할 기본값
  final RecordDefaults defaults;

  /// 스누즈 정책
  final SnoozePolicy snoozePolicy;

  /// 활성 상태
  final bool enabled;

  /// 알림 제목/본문 커스텀 (null이면 자동 생성)
  final String? notificationTitle;
  final String? notificationBody;

  /// 알림 ID (flutter_local_notifications용, id 해시로 생성)
  int get notificationId => id.hashCode.abs() % 100000 + 10000;

  const Routine({
    required this.id,
    required this.name,
    required this.targetCategory,
    required this.triggerType,
    this.fixedHour,
    this.fixedMinute,
    this.intervalMinutes,
    this.useSmartInterval = false,
    this.defaults = const RecordDefaults(),
    this.snoozePolicy = const SnoozePolicy(),
    this.enabled = true,
    this.notificationTitle,
    this.notificationBody,
  });

  Routine copyWith({
    String? name,
    RecordCategory? targetCategory,
    RoutineTriggerType? triggerType,
    int? fixedHour,
    int? fixedMinute,
    int? intervalMinutes,
    bool? useSmartInterval,
    RecordDefaults? defaults,
    SnoozePolicy? snoozePolicy,
    bool? enabled,
    String? notificationTitle,
    String? notificationBody,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      targetCategory: targetCategory ?? this.targetCategory,
      triggerType: triggerType ?? this.triggerType,
      fixedHour: fixedHour ?? this.fixedHour,
      fixedMinute: fixedMinute ?? this.fixedMinute,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      useSmartInterval: useSmartInterval ?? this.useSmartInterval,
      defaults: defaults ?? this.defaults,
      snoozePolicy: snoozePolicy ?? this.snoozePolicy,
      enabled: enabled ?? this.enabled,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetCategory': targetCategory.index,
        'triggerType': triggerType.index,
        'fixedHour': fixedHour,
        'fixedMinute': fixedMinute,
        'intervalMinutes': intervalMinutes,
        'useSmartInterval': useSmartInterval,
        'defaults': defaults.toJson(),
        'snoozePolicy': snoozePolicy.toJson(),
        'enabled': enabled,
        'notificationTitle': notificationTitle,
        'notificationBody': notificationBody,
      };

  factory Routine.fromJson(Map<String, dynamic> j) {
    final catIdx = j['targetCategory'] as int? ?? 0;
    final trigIdx = j['triggerType'] as int? ?? 0;
    return Routine(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      targetCategory: catIdx < RecordCategory.values.length
          ? RecordCategory.values[catIdx]
          : RecordCategory.feeding,
      triggerType: trigIdx < RoutineTriggerType.values.length
          ? RoutineTriggerType.values[trigIdx]
          : RoutineTriggerType.sinceLastRecord,
      fixedHour: j['fixedHour'] as int?,
      fixedMinute: j['fixedMinute'] as int?,
      intervalMinutes: j['intervalMinutes'] as int?,
      useSmartInterval: j['useSmartInterval'] as bool? ?? false,
      defaults: j['defaults'] is Map
          ? RecordDefaults.fromJson(Map<String, dynamic>.from(j['defaults']))
          : const RecordDefaults(),
      snoozePolicy: j['snoozePolicy'] is Map
          ? SnoozePolicy.fromJson(
              Map<String, dynamic>.from(j['snoozePolicy']))
          : const SnoozePolicy(),
      enabled: j['enabled'] as bool? ?? true,
      notificationTitle: j['notificationTitle'] as String?,
      notificationBody: j['notificationBody'] as String?,
    );
  }

  /// 카테고리에 맞는 기본 루틴 프리셋들
  static List<Routine> defaultRoutines() {
    return [
      Routine(
        id: 'default_feeding',
        name: '수유 알림',
        targetCategory: RecordCategory.feeding,
        triggerType: RoutineTriggerType.sinceLastRecord,
        intervalMinutes: 180, // 3시간
        useSmartInterval: true,
        defaults: const RecordDefaults(
          feedingType: FeedingType.formula,
          amountMl: 160,
        ),
        snoozePolicy: const SnoozePolicy(intervalMinutes: 10, maxCount: 3),
        notificationTitle: '수유 시간이에요 🍼',
        notificationBody: '마지막 수유 후 시간이 됐어요. 아기 배가 고플 수 있어요.',
      ),
      Routine(
        id: 'default_diaper',
        name: '기저귀 체크',
        targetCategory: RecordCategory.diaper,
        triggerType: RoutineTriggerType.sinceLastRecord,
        intervalMinutes: 120, // 2시간
        useSmartInterval: false,
        defaults: const RecordDefaults(diaperType: DiaperType.pee),
        snoozePolicy: const SnoozePolicy(intervalMinutes: 15, maxCount: 2),
        notificationTitle: '기저귀 확인해 보세요 🧷',
        notificationBody: '마지막 기저귀 교체 후 시간이 됐어요.',
      ),
      Routine(
        id: 'default_sleep',
        name: '수면 체크',
        targetCategory: RecordCategory.sleep,
        triggerType: RoutineTriggerType.sinceLastRecord,
        intervalMinutes: 150, // 2시간 30분
        useSmartInterval: false,
        defaults: const RecordDefaults(sleepStatus: SleepStatus.start),
        snoozePolicy: const SnoozePolicy(intervalMinutes: 10, maxCount: 2),
        notificationTitle: '낮잠 시간일 수 있어요 😴',
        notificationBody: '아기가 졸린 신호를 보내는지 확인해 보세요.',
      ),
    ];
  }
}
