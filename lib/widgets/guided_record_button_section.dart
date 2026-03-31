import 'package:flutter/material.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/widgets/guided_record_button_bar.dart';

/// 단계형 버튼 입력 상태를 캡슐화하고 [GuidedRecordButtonBar]에 연결합니다.
class GuidedRecordButtonSection extends StatefulWidget {
  const GuidedRecordButtonSection({
    super.key,
    required this.onPhraseSubmit,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 4),
  });

  final void Function(String phrase) onPhraseSubmit;
  final EdgeInsets padding;

  @override
  State<GuidedRecordButtonSection> createState() =>
      _GuidedRecordButtonSectionState();
}

class _GuidedRecordButtonSectionState extends State<GuidedRecordButtonSection> {
  RecordCategory? _category;
  GuidedHealthKind? _healthKind;
  bool _healthExtraDone = false;
  double? _healthTemperature;
  String? _healthMedicineName;

  FeedingType? _feedingKind;
  bool _formulaMlDone = false;
  int? _formulaMl;
  bool _breastDurationDone = false;
  int? _breastDurationMinutes;

  DiaperType? _diaperType;
  bool _babyfoodGramDone = false;
  int? _babyfoodGram;

  bool _snackGramDone = false;
  int? _snackGram;

  bool _sleepDurationDone = false;
  int? _sleepDurationMinutes;

  void _resetAll() {
    _category = null;
    _healthKind = null;
    _healthExtraDone = false;
    _healthTemperature = null;
    _healthMedicineName = null;
    _feedingKind = null;
    _formulaMlDone = false;
    _formulaMl = null;
    _breastDurationDone = false;
    _breastDurationMinutes = null;
    _diaperType = null;
    _babyfoodGramDone = false;
    _babyfoodGram = null;
    _snackGramDone = false;
    _snackGram = null;
    _sleepDurationDone = false;
    _sleepDurationMinutes = null;
  }

  bool _showsTimeRow() {
    return GuidedRecordButtonBar.showsTimeRow(
      category: _category,
      healthKind: _healthKind,
      healthExtraDone: _healthExtraDone,
      feedingKind: _feedingKind,
      formulaMlDone: _formulaMlDone,
      breastDurationDone: _breastDurationDone,
      diaperKind: _diaperType,
      babyfoodGramDone: _babyfoodGramDone,
      snackGramDone: _snackGramDone,
      sleepDurationDone: _sleepDurationDone,
    );
  }

  void _disposeControllerLater(TextEditingController c) {
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  Future<void> _promptCustomFormulaMl() async {
    final controller = TextEditingController();
    final ml = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('분유 양 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 ~ 1000',
            suffixText: 'ml',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 1000) {
                Navigator.pop(ctx, v);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('1~1000 사이 숫자를 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || ml == null) return;
    setState(() {
      _formulaMl = ml;
      _formulaMlDone = true;
    });
  }

  Future<void> _promptCustomBabyfoodGram() async {
    final controller = TextEditingController();
    final g = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이유식 그램 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 ~ 1000',
            suffixText: 'g',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.babyfoodColor,
              foregroundColor: AppTheme.onTertiary,
            ),
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 1000) {
                Navigator.pop(ctx, v);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('1~1000 사이 숫자를 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || g == null) return;
    setState(() {
      _babyfoodGram = g;
      _babyfoodGramDone = true;
    });
  }

  Future<void> _promptCustomBreastMinutes() async {
    final controller = TextEditingController();
    final m = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모유 수유 시간 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 ~ 180',
            suffixText: '분',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 180) {
                Navigator.pop(ctx, v);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('1~180 사이 숫자를 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || m == null) return;
    setState(() {
      _breastDurationMinutes = m;
      _breastDurationDone = true;
    });
  }

  Future<void> _promptCustomSnackGram() async {
    final controller = TextEditingController();
    final g = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('간식 그램 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 ~ 1000',
            suffixText: 'g',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.snackColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 1000) {
                Navigator.pop(ctx, v);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('1~1000 사이 숫자를 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || g == null) return;
    setState(() {
      _snackGram = g;
      _snackGramDone = true;
    });
  }

  Future<void> _promptCustomSleepMinutes() async {
    final controller = TextEditingController();
    final m = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수면 시간 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1 ~ 720',
            suffixText: '분',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.sleepColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 720) {
                Navigator.pop(ctx, v);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('1~720 사이 숫자를 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || m == null) return;
    setState(() {
      _sleepDurationMinutes = m;
      _sleepDurationDone = true;
    });
  }

  Future<void> _promptCustomHealthTemperature() async {
    final controller = TextEditingController();
    final t = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('체온 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: '35.0 ~ 42.0',
            suffixText: '°C',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.healthColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (v != null && v >= 35.0 && v <= 42.0) {
                Navigator.pop(ctx, v);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('35.0~42.0 사이로 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || t == null) return;
    setState(() {
      _healthTemperature = t;
      _healthExtraDone = true;
    });
  }

  Future<void> _promptCustomHealthMedicine() async {
    final controller = TextEditingController();
    final name = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('약 이름 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: '예: 오메가3, 한방약',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.healthColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final s = controller.text.trim();
              if (s.length >= 2 && s.length <= 40) {
                Navigator.pop(ctx, s);
              } else {
                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(
                    content: Text('2~40자로 입력해 주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _disposeControllerLater(controller);
    if (!mounted || name == null) return;
    setState(() {
      _healthMedicineName = name;
      _healthExtraDone = true;
    });
  }

  void _popStep() {
    setState(() {
      if (!_showsTimeRow()) {
        if (_category == RecordCategory.feeding &&
            _feedingKind == FeedingType.formula &&
            !_formulaMlDone) {
          _feedingKind = null;
          _formulaMlDone = false;
          _formulaMl = null;
          return;
        }
        if (_category == RecordCategory.feeding &&
            _feedingKind == FeedingType.breast &&
            !_breastDurationDone) {
          _feedingKind = null;
          _breastDurationDone = false;
          _breastDurationMinutes = null;
          return;
        }
        if (_category == RecordCategory.feeding && _feedingKind == null) {
          _resetAll();
          return;
        }
        if (_category == RecordCategory.health && _healthKind == null) {
          _category = null;
          return;
        }
        if (_category == RecordCategory.health && !_healthExtraDone) {
          _healthKind = null;
          _healthTemperature = null;
          _healthMedicineName = null;
          return;
        }
        if (_category == RecordCategory.diaper && _diaperType == null) {
          _category = null;
          return;
        }
        if (_category == RecordCategory.babyfood && !_babyfoodGramDone) {
          _category = null;
          return;
        }
        if (_category == RecordCategory.snack && !_snackGramDone) {
          _category = null;
          return;
        }
        if (_category == RecordCategory.sleep && !_sleepDurationDone) {
          _category = null;
          return;
        }
        return;
      }

      if (_category == RecordCategory.feeding &&
          _feedingKind == FeedingType.formula &&
          _formulaMlDone) {
        _formulaMlDone = false;
        _formulaMl = null;
        return;
      }
      if (_category == RecordCategory.feeding &&
          _feedingKind == FeedingType.breast &&
          _breastDurationDone) {
        _breastDurationDone = false;
        _breastDurationMinutes = null;
        return;
      }
      if (_category == RecordCategory.feeding && _feedingKind != null) {
        _feedingKind = null;
        _formulaMlDone = false;
        _formulaMl = null;
        _breastDurationDone = false;
        _breastDurationMinutes = null;
        return;
      }
      if (_category == RecordCategory.health) {
        if (_healthExtraDone) {
          _healthExtraDone = false;
          _healthTemperature = null;
          _healthMedicineName = null;
          return;
        }
        _healthKind = null;
        return;
      }
      if (_category == RecordCategory.diaper && _diaperType != null) {
        _diaperType = null;
        return;
      }
      if (_category == RecordCategory.babyfood && _babyfoodGramDone) {
        _babyfoodGramDone = false;
        _babyfoodGram = null;
        return;
      }
      if (_category == RecordCategory.snack && _snackGramDone) {
        _snackGramDone = false;
        _snackGram = null;
        return;
      }
      if (_category == RecordCategory.sleep && _sleepDurationDone) {
        _sleepDurationDone = false;
        _sleepDurationMinutes = null;
        return;
      }
      _resetAll();
    });
  }

  void _submitPhrase(String phrase) {
    setState(_resetAll);
    widget.onPhraseSubmit(phrase);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: GuidedRecordButtonBar(
        category: _category,
        healthKind: _healthKind,
        healthExtraDone: _healthExtraDone,
        healthTemperature: _healthTemperature,
        healthMedicineName: _healthMedicineName,
        feedingKind: _feedingKind,
        formulaMlDone: _formulaMlDone,
        formulaMl: _formulaMl,
        breastDurationDone: _breastDurationDone,
        breastDurationMinutes: _breastDurationMinutes,
        diaperKind: _diaperType,
        babyfoodGramDone: _babyfoodGramDone,
        babyfoodGram: _babyfoodGram,
        snackGramDone: _snackGramDone,
        snackGram: _snackGram,
        sleepDurationDone: _sleepDurationDone,
        sleepDurationMinutes: _sleepDurationMinutes,
        onCategoryTap: (c) => setState(() {
          _category = c;
          _healthKind = null;
          _healthExtraDone = false;
          _healthTemperature = null;
          _healthMedicineName = null;
          _feedingKind = null;
          _formulaMlDone = false;
          _formulaMl = null;
          _breastDurationDone = false;
          _breastDurationMinutes = null;
          _diaperType = null;
          _babyfoodGramDone = false;
          _babyfoodGram = null;
          _snackGramDone = false;
          _snackGram = null;
          _sleepDurationDone = false;
          _sleepDurationMinutes = null;
        }),
        onHealthKindTap: (k) => setState(() {
          _healthKind = k;
          _healthExtraDone = false;
          _healthTemperature = null;
          _healthMedicineName = null;
        }),
        onHealthTemperatureTap: (t) => setState(() {
          _healthTemperature = t;
          _healthExtraDone = true;
        }),
        onCustomHealthTemperatureTap: _promptCustomHealthTemperature,
        onHealthMedicineTap: (name) => setState(() {
          _healthMedicineName = name;
          _healthExtraDone = true;
        }),
        onCustomHealthMedicineTap: _promptCustomHealthMedicine,
        onFeedingKindTap: (t) => setState(() {
          _feedingKind = t;
          if (t == FeedingType.breast) {
            _formulaMlDone = true;
            _formulaMl = null;
            _breastDurationDone = false;
            _breastDurationMinutes = null;
          } else {
            _formulaMlDone = false;
            _formulaMl = null;
            _breastDurationDone = true;
            _breastDurationMinutes = null;
          }
        }),
        onFormulaMlTap: (ml) => setState(() {
          _formulaMl = ml;
          _formulaMlDone = true;
        }),
        onDiaperTypeTap: (t) => setState(() => _diaperType = t),
        onBabyfoodGramTap: (g) => setState(() {
          _babyfoodGram = g;
          _babyfoodGramDone = true;
        }),
        onCustomFormulaMlTap: _promptCustomFormulaMl,
        onCustomBabyfoodGramTap: _promptCustomBabyfoodGram,
        onBreastDurationTap: (m) => setState(() {
          _breastDurationMinutes = m;
          _breastDurationDone = true;
        }),
        onCustomBreastMinutesTap: _promptCustomBreastMinutes,
        onSnackGramTap: (g) => setState(() {
          _snackGram = g;
          _snackGramDone = true;
        }),
        onCustomSnackGramTap: _promptCustomSnackGram,
        onSleepDurationTap: (m) => setState(() {
          _sleepDurationMinutes = m;
          _sleepDurationDone = true;
        }),
        onCustomSleepMinutesTap: _promptCustomSleepMinutes,
        onTimePhrase: _submitPhrase,
        onPopStep: _popStep,
      ),
    );
  }
}
