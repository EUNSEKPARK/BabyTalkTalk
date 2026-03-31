/// 성장 일기 카드 썸네일용 앱 내 에셋 (일러스트·온보딩 등)
const List<String> kGrowthDiaryCoverAssets = [
  'assets/images/milestone_celebration.png',
  'assets/images/growth_curve_header.png',
  'assets/images/onboarding_welcome.png',
  'assets/images/onboarding_feature.png',
  'assets/images/onboarding_profile.png',
  'assets/images/empty_diary.png',
  'assets/images/baby_avatar_default.png',
  'assets/images/tab_statistics.png',
];

/// 날짜별로 고르게 섞인 기본 에셋 인덱스
int defaultDiaryCoverAssetIndex(DateTime date) {
  final key =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  if (kGrowthDiaryCoverAssets.isEmpty) return 0;
  return key.hashCode.abs() % kGrowthDiaryCoverAssets.length;
}
