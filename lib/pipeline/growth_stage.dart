/// 성장 단계 enum
enum GrowthStage {
  formula, // 분유기 (0~5개월)
  weaning, // 이유식기 (5~15개월)
  toddler, // 유아식기 (15개월~)
}

/// GrowthStage 확장 메서드
extension GrowthStageExtension on GrowthStage {
  /// 한글 이름
  String get koreanName {
    switch (this) {
      case GrowthStage.formula:
        return '분유기';
      case GrowthStage.weaning:
        return '이유식기';
      case GrowthStage.toddler:
        return '유아식기';
    }
  }

  /// 월령 범위 설명
  String get ageRange {
    switch (this) {
      case GrowthStage.formula:
        return '0~5개월';
      case GrowthStage.weaning:
        return '5~15개월';
      case GrowthStage.toddler:
        return '15개월~';
    }
  }
}
