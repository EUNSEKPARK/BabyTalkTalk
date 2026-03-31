import 'package:flutter/material.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 건강 카테고리 2단계: 체온 vs 약
enum GuidedHealthKind {
  temperature,
  medicine,
}

/// 채팅·홈 공용: 카테고리 → 세부(수유·이유식·간식·수면·기저귀·건강) → 시간
class GuidedRecordButtonBar extends StatelessWidget {
  const GuidedRecordButtonBar({
    super.key,
    required this.category,
    required this.healthKind,
    required this.healthExtraDone,
    required this.healthTemperature,
    required this.healthMedicineName,
    required this.feedingKind,
    required this.formulaMlDone,
    required this.formulaMl,
    required this.breastDurationDone,
    required this.breastDurationMinutes,
    required this.diaperKind,
    required this.babyfoodGramDone,
    required this.babyfoodGram,
    required this.snackGramDone,
    required this.snackGram,
    required this.sleepDurationDone,
    required this.sleepDurationMinutes,
    required this.onCategoryTap,
    required this.onHealthKindTap,
    required this.onHealthTemperatureTap,
    required this.onCustomHealthTemperatureTap,
    required this.onHealthMedicineTap,
    required this.onCustomHealthMedicineTap,
    required this.onFeedingKindTap,
    required this.onFormulaMlTap,
    required this.onDiaperTypeTap,
    required this.onBabyfoodGramTap,
    required this.onCustomFormulaMlTap,
    required this.onCustomBabyfoodGramTap,
    required this.onBreastDurationTap,
    required this.onCustomBreastMinutesTap,
    required this.onSnackGramTap,
    required this.onCustomSnackGramTap,
    required this.onSleepDurationTap,
    required this.onCustomSleepMinutesTap,
    required this.onTimePhrase,
    required this.onPopStep,
  });

  final RecordCategory? category;
  final GuidedHealthKind? healthKind;
  /// 체온·약 세부(값 또는 건너뛰기)까지 끝났는지
  final bool healthExtraDone;
  final double? healthTemperature;
  /// 약 이름(건너뛰기 시 null → "약 먹였어")
  final String? healthMedicineName;
  /// 수유일 때만: 모유/분유 선택 전이면 null
  final FeedingType? feedingKind;
  /// 분유 선택 후 ml 단계를 지났는지 (모유는 breastDurationDone으로 처리)
  final bool formulaMlDone;
  /// 분유 ml. '양 나중에'면 null이어도 formulaMlDone true
  final int? formulaMl;
  /// 모유: 수유 시간(분) 단계를 지났는지
  final bool breastDurationDone;
  /// 모유 분. 건너뛰기면 null이어도 breastDurationDone은 true
  final int? breastDurationMinutes;
  /// 기저귀일 때만: 소변/대변/둘 다 선택 전이면 null
  final DiaperType? diaperKind;
  /// 이유식: 그램 단계를 지났는지 ('양 나중에'도 true)
  final bool babyfoodGramDone;
  /// 이유식 그램. 건너뛰기면 null이어도 babyfoodGramDone은 true
  final int? babyfoodGram;
  final bool snackGramDone;
  final int? snackGram;
  final bool sleepDurationDone;
  final int? sleepDurationMinutes;

  final void Function(RecordCategory category) onCategoryTap;
  final void Function(GuidedHealthKind kind) onHealthKindTap;
  /// null이면 체온 숫자 없이
  final void Function(double? celsius) onHealthTemperatureTap;
  final VoidCallback onCustomHealthTemperatureTap;
  /// null이면 "약 먹였어"만
  final void Function(String? medicineName) onHealthMedicineTap;
  final VoidCallback onCustomHealthMedicineTap;
  final void Function(FeedingType type) onFeedingKindTap;
  /// [ml]이 null이면 건너뛰기
  final void Function(int? ml) onFormulaMlTap;
  final void Function(DiaperType type) onDiaperTypeTap;
  /// [grams]이 null이면 그램 없이 일반 문장
  final void Function(int? grams) onBabyfoodGramTap;
  final VoidCallback onCustomFormulaMlTap;
  final VoidCallback onCustomBabyfoodGramTap;
  /// [minutes] null이면 건너뛰기(모유 수유했어)
  final void Function(int? minutes) onBreastDurationTap;
  final VoidCallback onCustomBreastMinutesTap;
  final void Function(int? grams) onSnackGramTap;
  final VoidCallback onCustomSnackGramTap;
  /// [minutes] null이면 잠들었어만
  final void Function(int? minutes) onSleepDurationTap;
  final VoidCallback onCustomSleepMinutesTap;
  final void Function(String phrase) onTimePhrase;
  final VoidCallback onPopStep;

  static const _timeOptions = <({String label, String phrase})>[
    (label: '방금', phrase: '방금 '),
    (label: '5분 전', phrase: '5분 전 '),
    (label: '15분 전', phrase: '15분 전 '),
    (label: '30분 전', phrase: '30분 전 '),
    (label: '1시간 전', phrase: '1시간 전 '),
  ];

  static const _formulaMlOptions = [60, 90, 120, 140, 160, 180, 200];

  /// 초기 이유식 단계에서 자주 쓰는 그램 후보
  static const babyfoodGramPresets = [20, 30, 50, 80, 100, 120, 150];

  static const _snackGramPresets = [10, 20, 30, 50, 80, 100];

  static const _breastMinutePresets = [5, 10, 15, 20, 30];

  static const _sleepMinutePresets = [20, 30, 45, 60, 90, 120];

  static const _temperaturePresets = [36.5, 37.0, 37.5, 37.8, 38.0];

  static String _formatTemperature(double t) {
    if (t == t.roundToDouble()) return t.toInt().toString();
    return t.toStringAsFixed(1);
  }

  /// 시간 행을 보여도 되는지 (위젯과 동일 조건)
  static bool showsTimeRow({
    required RecordCategory? category,
    required GuidedHealthKind? healthKind,
    required bool healthExtraDone,
    required FeedingType? feedingKind,
    required bool formulaMlDone,
    required bool breastDurationDone,
    required DiaperType? diaperKind,
    required bool babyfoodGramDone,
    required bool snackGramDone,
    required bool sleepDurationDone,
  }) {
    if (category == null) return false;
    if (category == RecordCategory.health) {
      if (healthKind == null) return false;
      if (!healthExtraDone) return false;
    }
    if (category == RecordCategory.feeding && feedingKind == null) return false;
    if (category == RecordCategory.feeding &&
        feedingKind == FeedingType.formula &&
        !formulaMlDone) {
      return false;
    }
    if (category == RecordCategory.feeding &&
        feedingKind == FeedingType.breast &&
        !breastDurationDone) {
      return false;
    }
    if (category == RecordCategory.diaper && diaperKind == null) return false;
    if (category == RecordCategory.babyfood && !babyfoodGramDone) {
      return false;
    }
    if (category == RecordCategory.snack && !snackGramDone) return false;
    if (category == RecordCategory.sleep && !sleepDurationDone) return false;
    return true;
  }

  static String composePhrase({
    required RecordCategory category,
    GuidedHealthKind? healthKind,
    FeedingType? feedingKind,
    int? formulaMl,
    int? breastDurationMinutes,
    DiaperType? diaperKind,
    int? babyfoodGram,
    int? snackGram,
    int? sleepDurationMinutes,
    double? healthTemperature,
    String? healthMedicineName,
    required String timePrefix,
  }) {
    if (category == RecordCategory.health) {
      if (healthKind == GuidedHealthKind.temperature) {
        if (healthTemperature != null) {
          final s = _formatTemperature(healthTemperature);
          return '${timePrefix}체온 ${s}도 재었어';
        }
        return '${timePrefix}체온 재었어';
      }
      if (healthKind == GuidedHealthKind.medicine) {
        if (healthMedicineName != null && healthMedicineName.isNotEmpty) {
          return '${timePrefix}$healthMedicineName 먹였어';
        }
        return '${timePrefix}약 먹였어';
      }
      return '${timePrefix}체온 재었어';
    }
    if (category == RecordCategory.feeding && feedingKind != null) {
      if (feedingKind == FeedingType.breast) {
        if (breastDurationMinutes != null) {
          return '${timePrefix}모유 ${breastDurationMinutes}분 수유했어';
        }
        return '${timePrefix}모유 수유했어';
      }
      if (feedingKind == FeedingType.formula) {
        if (formulaMl != null) {
          return '${timePrefix}분유 ${formulaMl}ml 먹었어';
        }
        return '${timePrefix}분유 먹었어';
      }
    }
    switch (category) {
      case RecordCategory.babyfood:
        if (babyfoodGram != null) {
          return '${timePrefix}이유식 ${babyfoodGram}g 먹었어';
        }
        return '${timePrefix}이유식 먹었어';
      case RecordCategory.sleep:
        if (sleepDurationMinutes != null) {
          return '${timePrefix}${sleepDurationMinutes}분 잤어';
        }
        return '${timePrefix}잠들었어';
      case RecordCategory.diaper:
        switch (diaperKind) {
          case DiaperType.pee:
            return '${timePrefix}소변 기저귀 갈았어';
          case DiaperType.poop:
            return '${timePrefix}기저귀 갈았어 응가';
          case DiaperType.both:
            return '${timePrefix}소변 대변 기저귀 갈았어';
          case null:
            return '${timePrefix}기저귀 갈았어';
        }
      case RecordCategory.snack:
        if (snackGram != null) {
          return '${timePrefix}간식 ${snackGram}g 먹었어';
        }
        return '${timePrefix}간식 먹었어';
      default:
        return '${timePrefix}분유 먹었어';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (category == null) ...[
          _hintRow('종류를 고르면 다음 단계가 나와요'),
          _buildCategoryRow(),
        ] else if (category == RecordCategory.health && healthKind == null)
          _buildHealthKindRow()
        else if (category == RecordCategory.health &&
            healthKind == GuidedHealthKind.temperature &&
            !healthExtraDone)
          _buildTemperatureRow()
        else if (category == RecordCategory.health &&
            healthKind == GuidedHealthKind.medicine &&
            !healthExtraDone)
          _buildMedicineRow()
        else if (category == RecordCategory.feeding && feedingKind == null)
          _buildFeedingKindRow()
        else if (category == RecordCategory.feeding &&
            feedingKind == FeedingType.breast &&
            !breastDurationDone)
          _buildBreastDurationRow()
        else if (category == RecordCategory.feeding &&
            feedingKind == FeedingType.formula &&
            !formulaMlDone)
          _buildFormulaMlRow()
        else if (category == RecordCategory.diaper && diaperKind == null)
          _buildDiaperKindRow()
        else if (category == RecordCategory.babyfood && !babyfoodGramDone)
          _buildBabyfoodGramRow()
        else if (category == RecordCategory.snack && !snackGramDone)
          _buildSnackGramRow()
        else if (category == RecordCategory.sleep && !sleepDurationDone)
          _buildSleepDurationRow(),
        if (showsTimeRow(
          category: category,
          healthKind: healthKind,
          healthExtraDone: healthExtraDone,
          feedingKind: feedingKind,
          formulaMlDone: formulaMlDone,
          breastDurationDone: breastDurationDone,
          diaperKind: diaperKind,
          babyfoodGramDone: babyfoodGramDone,
          snackGramDone: snackGramDone,
          sleepDurationDone: sleepDurationDone,
        ))
          _buildTimeRow(),
      ],
    );
  }

  Widget _buildTemperatureRow() {
    final color = AppTheme.healthColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('체온을 골라 주세요 (프리셋·직접 입력·건너뛰기)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in _temperaturePresets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: '${_formatTemperature(t)}°',
                    color: color,
                    onTap: () => onHealthTemperatureTap(t),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '건너뛰기',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onHealthTemperatureTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomHealthTemperatureTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineRow() {
    final color = AppTheme.healthColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('어떤 약인가요? (프리셋·직접 입력·건너뛰기)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final o in defaultMedicineTypeOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: o.label,
                    color: color,
                    onTap: () => onHealthMedicineTap(o.medicineName),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '건너뛰기',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onHealthMedicineTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomHealthMedicineTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreastDurationRow() {
    const color = Color(0xFFFFB5A7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('대략 몇 분 수유했나요? (프리셋·직접 입력·건너뛰기)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final m in _breastMinutePresets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: '${m}분',
                    color: color,
                    onTap: () => onBreastDurationTap(m),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '건너뛰기',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onBreastDurationTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomBreastMinutesTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSnackGramRow() {
    final color = AppTheme.snackColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('대략 몇 g 먹었나요? (프리셋·직접 입력·건너뛰기)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final g in _snackGramPresets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: '${g}g',
                    color: color,
                    onTap: () => onSnackGramTap(g),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '건너뛰기',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onSnackGramTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomSnackGramTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepDurationRow() {
    final color = AppTheme.sleepColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('대략 얼마나 잤나요? (프리셋·직접 입력·건너뛰기)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final m in _sleepMinutePresets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: m >= 60 ? '${m ~/ 60}시간' : '${m}분',
                    color: color,
                    onTap: () => onSleepDurationTap(m),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '건너뛰기',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onSleepDurationTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomSleepMinutesTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryChip(
            asset: 'assets/images/icon_bottle.png',
            emoji: '🍼',
            label: '수유',
            onTap: () => onCategoryTap(RecordCategory.feeding),
          ),
          _categoryChip(
            asset: null,
            emoji: '🥣',
            label: '이유식',
            onTap: () => onCategoryTap(RecordCategory.babyfood),
          ),
          _categoryChip(
            asset: null,
            emoji: '🍪',
            label: '간식',
            onTap: () => onCategoryTap(RecordCategory.snack),
          ),
          _categoryChip(
            asset: 'assets/images/icon_sleep.png',
            emoji: '😴',
            label: '수면',
            onTap: () => onCategoryTap(RecordCategory.sleep),
          ),
          _categoryChip(
            asset: 'assets/images/icon_diaper.png',
            emoji: '🧷',
            label: '기저귀',
            onTap: () => onCategoryTap(RecordCategory.diaper),
          ),
          _categoryChip(
            asset: 'assets/images/icon_temperature.png',
            emoji: '🌡️',
            label: '건강',
            onTap: () => onCategoryTap(RecordCategory.health),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedingKindRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('모유인가요, 분유인가요?'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _pill(
                icon: Icons.child_care_outlined,
                label: '모유',
                color: AppTheme.feedingColor,
                onTap: () => onFeedingKindTap(FeedingType.breast),
              ),
              _pill(
                icon: Icons.local_drink_outlined,
                label: '분유',
                color: AppTheme.feedingColor,
                onTap: () => onFeedingKindTap(FeedingType.formula),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaMlRow() {
    const color = Color(0xFFFFB5A7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('얼마나 먹었나요? (프리셋·직접 입력·양 나중에)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final ml in _formulaMlOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: '${ml}ml',
                    color: color,
                    onTap: () => onFormulaMlTap(ml),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '양 나중에',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onFormulaMlTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomFormulaMlTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBabyfoodGramRow() {
    final color = AppTheme.babyfoodColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('대략 몇 g 먹었나요? (프리셋·직접 입력·양 나중에)'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final g in babyfoodGramPresets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: '${g}g',
                    color: color,
                    onTap: () => onBabyfoodGramTap(g),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  label: '양 나중에',
                  color: AppTheme.onSurfaceVariant,
                  onTap: () => onBabyfoodGramTap(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _pill(
                  icon: Icons.edit_outlined,
                  label: '직접 입력',
                  color: AppTheme.primary,
                  onTap: onCustomBabyfoodGramTap,
                ),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiaperKindRow() {
    final color = AppTheme.diaperColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('소변, 응가(대변), 둘 다 중에 골라주세요'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _pill(
                icon: Icons.water_drop_outlined,
                label: '소변',
                color: color,
                onTap: () => onDiaperTypeTap(DiaperType.pee),
              ),
              _pill(
                icon: Icons.sentiment_dissatisfied_outlined,
                label: '응가',
                color: color,
                onTap: () => onDiaperTypeTap(DiaperType.poop),
              ),
              _pill(
                icon: Icons.layers_outlined,
                label: '둘 다',
                color: color,
                onTap: () => onDiaperTypeTap(DiaperType.both),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthKindRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow('체온 또는 약을 골라주세요'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _pill(
                icon: Icons.thermostat_outlined,
                label: '체온',
                color: AppTheme.healthColor,
                onTap: () => onHealthKindTap(GuidedHealthKind.temperature),
              ),
              _pill(
                icon: Icons.medication_outlined,
                label: '약',
                color: AppTheme.healthColor,
                onTap: () => onHealthKindTap(GuidedHealthKind.medicine),
              ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    final c = category!;
    final title = switch (c) {
      RecordCategory.feeding => feedingKind == FeedingType.breast
          ? (breastDurationMinutes != null
              ? '모유(${breastDurationMinutes}분) — 언제였나요?'
              : '모유 — 언제였나요?')
          : '분유 — 언제였나요?',
      RecordCategory.babyfood => babyfoodGram != null
          ? '이유식(${babyfoodGram}g) — 언제 먹었나요?'
          : '이유식 — 언제 먹었나요?',
      RecordCategory.snack => snackGram != null
          ? '간식(${snackGram}g) — 언제 먹었나요?'
          : '간식 — 언제 먹었나요?',
      RecordCategory.sleep => sleepDurationMinutes != null
          ? '수면(약 ${sleepDurationMinutes}분) — 언제였나요?'
          : '수면 — 언제 잠들었나요?',
      RecordCategory.diaper => switch (diaperKind) {
          DiaperType.pee => '소변 기저귀 — 언제 갈았나요?',
          DiaperType.poop => '응가(대변) — 언제 갈았나요?',
          DiaperType.both => '소변+대변 — 언제 갈았나요?',
          null => '기저귀 — 언제 갈았나요?',
        },
      RecordCategory.health => healthKind == GuidedHealthKind.medicine
          ? '약 — 언제 먹였나요?'
          : healthTemperature != null
              ? '체온(${_formatTemperature(healthTemperature!)}°) — 언제 재었나요?'
              : '체온 — 언제 재었나요?',
      _ => '시간을 골라주세요',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow(title),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final o in _timeOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill(
                    label: o.label,
                    color: AppTheme.primary,
                    onTap: () => onTimePhrase(
                      composePhrase(
                        category: c,
                        healthKind: healthKind,
                        feedingKind: feedingKind,
                        formulaMl: formulaMl,
                        breastDurationMinutes: breastDurationMinutes,
                        diaperKind: diaperKind,
                        babyfoodGram: babyfoodGram,
                        snackGram: snackGram,
                        sleepDurationMinutes: sleepDurationMinutes,
                        healthTemperature: healthTemperature,
                        healthMedicineName: healthMedicineName,
                        timePrefix: o.phrase,
                      ),
                    ),
                  ),
                ),
              _backChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hintRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _categoryChip({
    String? asset,
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (asset != null)
                  ClipOval(
                    child: Image.asset(
                      asset,
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  )
                else
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill({
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backChip() {
    return Material(
      color: AppTheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPopStep,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 16, color: AppTheme.onSurfaceVariant),
              SizedBox(width: 4),
              Text(
                '다시',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
