import 'package:hive/hive.dart';

part 'baby_record.g.dart';

/// 육아 기록 카테고리
@HiveType(typeId: 0)
enum RecordCategory {
  @HiveField(0)
  feeding, // 수유 (모유/분유)
  @HiveField(1)
  sleep, // 수면
  @HiveField(2)
  diaper, // 기저귀
  @HiveField(3)
  milestone, // 성장 기록
  @HiveField(4)
  health, // 건강 (체온, 약 등)
  @HiveField(5)
  other, // 기타
  @HiveField(6)
  babyfood, // 이유식
  @HiveField(7)
  snack, // 간식
  @HiveField(8)
  bath, // 목욕
  @HiveField(9)
  pumping, // 유축
  @HiveField(10)
  tummytime, // 터미타임
}

/// 수유 타입
@HiveType(typeId: 1)
enum FeedingType {
  @HiveField(0)
  breast, // 모유
  @HiveField(1)
  formula, // 분유
  @HiveField(2)
  babyfood, // 이유식
  @HiveField(3)
  snack, // 간식
}

/// 기저귀 타입
@HiveType(typeId: 2)
enum DiaperType {
  @HiveField(0)
  pee, // 소변
  @HiveField(1)
  poop, // 대변
  @HiveField(2)
  both, // 둘 다
}

/// 수면 상태
@HiveType(typeId: 3)
enum SleepStatus {
  @HiveField(0)
  start, // 잠듦
  @HiveField(1)
  end, // 깸
}

/// 육아 기록 모델
@HiveType(typeId: 4)
class BabyRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  RecordCategory category;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  String? rawInput; // 사용자 원본 입력 텍스트

  // 수유 관련
  @HiveField(4)
  FeedingType? feedingType;

  @HiveField(5)
  int? amountMl; // ml 단위

  @HiveField(6)
  int? durationMinutes; // 수유 시간 (분)

  // 수면 관련
  @HiveField(7)
  SleepStatus? sleepStatus;

  // 기저귀 관련
  @HiveField(8)
  DiaperType? diaperType;

  // 건강 관련
  @HiveField(9)
  double? temperature; // 체온

  @HiveField(10)
  String? medicine; // 약 이름

  // 공통
  @HiveField(11)
  String? memo; // 메모

  @HiveField(12)
  DateTime createdAt;

  /// 입력 소스: 'chat' (채팅), 'voice' (음성), 'quick' (빠른 입력)
  @HiveField(13)
  String? inputSource;

  /// 기록 작성자 UID (가족 공유용)
  @HiveField(14)
  String? authorId;

  /// 기록 작성자 닉네임 ("엄마", "아빠" 등)
  @HiveField(15)
  String? authorName;

  /// 연결된 아기 프로필 ID (멀티 아이 지원)
  @HiveField(16)
  String? profileId;

  /// 첨부 사진 경로 (로컬)
  @HiveField(17)
  String? photoPath;

  BabyRecord({
    required this.id,
    required this.category,
    required this.timestamp,
    this.rawInput,
    this.feedingType,
    this.amountMl,
    this.durationMinutes,
    this.sleepStatus,
    this.diaperType,
    this.temperature,
    this.medicine,
    this.memo,
    this.inputSource,
    this.authorId,
    this.authorName,
    this.profileId,
    this.photoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 입력 소스 아이콘
  String get inputSourceIcon {
    switch (inputSource) {
      case 'voice':
        return '🎙️';
      case 'quick':
        return '⚡';
      case 'guided':
        return '🔘';
      case 'widget':
        return '📱';
      case 'chat':
      default:
        return '💬';
    }
  }

  /// 입력 소스 한글 이름
  String get inputSourceName {
    switch (inputSource) {
      case 'voice':
        return '음성';
      case 'quick':
        return '빠른입력';
      case 'guided':
        return '버튼입력';
      case 'widget':
        return '위젯';
      case 'chat':
      default:
        return '채팅';
    }
  }

  /// 카테고리 한글 이름
  String get categoryName {
    switch (category) {
      case RecordCategory.feeding:
        return '수유';
      case RecordCategory.sleep:
        return '수면';
      case RecordCategory.diaper:
        return '기저귀';
      case RecordCategory.milestone:
        return '성장';
      case RecordCategory.health:
        return '건강';
      case RecordCategory.babyfood:
        return '이유식';
      case RecordCategory.snack:
        return '간식';
      case RecordCategory.bath:
        return '목욕';
      case RecordCategory.pumping:
        return '유축';
      case RecordCategory.tummytime:
        return '터미타임';
      case RecordCategory.other:
        return '기타';
    }
  }

  /// 카테고리 아이콘 이모지
  String get categoryEmoji {
    switch (category) {
      case RecordCategory.feeding:
        return '🍼';
      case RecordCategory.sleep:
        return '😴';
      case RecordCategory.diaper:
        return '🧷';
      case RecordCategory.milestone:
        return '⭐';
      case RecordCategory.health:
        return '🌡️';
      case RecordCategory.babyfood:
        return '🥣';
      case RecordCategory.snack:
        return '🍪';
      case RecordCategory.bath:
        return '🛁';
      case RecordCategory.pumping:
        return '🍶';
      case RecordCategory.tummytime:
        return '👶';
      case RecordCategory.other:
        return '📝';
    }
  }

  /// 기록 요약 텍스트
  String get summary {
    switch (category) {
      case RecordCategory.feeding:
        final type = feedingType == FeedingType.breast ? '모유' : '분유';
        final amount = amountMl != null ? ' ${amountMl}ml' : '';
        final dur = durationMinutes != null ? ' ${durationMinutes}분' : '';
        return '$type$amount$dur';
      case RecordCategory.babyfood:
        final amount = amountMl != null ? ' ${amountMl}ml' : '';
        final memoStr = memo != null ? ' [$memo]' : '';
        return '이유식$amount$memoStr';
      case RecordCategory.snack:
        final gram = amountMl != null ? ' ${amountMl}g' : '';
        final memoStr = memo != null ? ' [$memo]' : '';
        return '간식$gram$memoStr';
      case RecordCategory.sleep:
        final memoStr = memo != null && memo!.isNotEmpty ? '${memo!} ' : '';
        final durStr = durationMinutes != null
            ? (durationMinutes! >= 60
                ? '${durationMinutes! ~/ 60}시간${durationMinutes! % 60 > 0 ? ' ${durationMinutes! % 60}분' : ''}'
                : '${durationMinutes}분')
            : '';
        final statusStr = sleepStatus == SleepStatus.start ? '잠듦' : '깨어남';
        return '$memoStr$statusStr${durStr.isNotEmpty ? ' ($durStr)' : ''}';
      case RecordCategory.diaper:
        final type = diaperType == DiaperType.pee
            ? '소변'
            : diaperType == DiaperType.poop
                ? '대변'
                : '소변+대변';
        final stoolDetail = memo != null && memo!.isNotEmpty ? ' · $memo' : '';
        return '기저귀 교체 ($type$stoolDetail)';
      case RecordCategory.health:
        final temp = temperature != null ? '체온 ${temperature}°C' : '';
        final med = medicine != null ? '약: $medicine' : '';
        return [temp, med].where((s) => s.isNotEmpty).join(', ');
      case RecordCategory.milestone:
        return memo ?? '성장 기록';
      case RecordCategory.bath:
        final dur = durationMinutes != null ? ' ${durationMinutes}분' : '';
        final memoStr = memo != null && memo!.isNotEmpty ? ' · $memo' : '';
        return '목욕$dur$memoStr';
      case RecordCategory.pumping:
        final amount = amountMl != null ? ' ${amountMl}ml' : '';
        final dur = durationMinutes != null ? ' ${durationMinutes}분' : '';
        return '유축$amount$dur';
      case RecordCategory.tummytime:
        final dur = durationMinutes != null ? ' ${durationMinutes}분' : '';
        return '터미타임$dur';
      case RecordCategory.other:
        return memo ?? '기타 기록';
    }
  }
}
