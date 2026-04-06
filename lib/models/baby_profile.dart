import 'package:hive/hive.dart';

part 'baby_profile.g.dart';

@HiveType(typeId: 5)
class BabyProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime birthDate;

  @HiveField(2)
  String? gender; // 'M', 'F', null

  @HiveField(3)
  double? birthWeight; // kg

  @HiveField(4)
  double? birthHeight; // cm

  @HiveField(5)
  int growthStageIndex; // 0: formula, 1: weaning, 2: toddler

  /// 고유 프로필 ID (멀티 아이 지원)
  @HiveField(6)
  String profileId;

  BabyProfile({
    required this.name,
    required this.birthDate,
    this.gender,
    this.birthWeight,
    this.birthHeight,
    this.growthStageIndex = 0,
    String? profileId,
  }) : profileId = profileId ?? _generateId();

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  /// 현재 개월수
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  /// 현재 일수
  int get ageInDays {
    return DateTime.now().difference(birthDate).inDays;
  }

  /// 나이 표시 문자열
  String get ageText {
    final months = ageInMonths;
    final days = ageInDays;
    if (months < 1) {
      return '생후 ${days}일';
    } else {
      final remainDays = days - (months * 30);
      return '생후 ${months}개월 ${remainDays > 0 ? "${remainDays}일" : ""}';
    }
  }
}
