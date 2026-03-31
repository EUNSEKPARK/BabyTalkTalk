import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/speech_service.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/widgets/category_disambiguation_chips.dart';
import 'package:chat_baby_time/widgets/feeding_type_disambiguation_chips.dart';
import 'package:chat_baby_time/utils/time_utils.dart';
import 'package:chat_baby_time/screens/record_detail_screen.dart';
import 'package:chat_baby_time/screens/chat_screen.dart';
import 'package:chat_baby_time/widgets/record_edit_sheet.dart';
import 'package:chat_baby_time/widgets/guided_record_button_section.dart';
import 'package:chat_baby_time/services/nlp_analytics_service.dart';

/// 카테고리 아이콘 정보
class _CategoryInfo {
  final String label;
  final String imagePath;
  final RecordCategory? category;
  final String quickInput;

  const _CategoryInfo({
    required this.label,
    required this.imagePath,
    this.category,
    required this.quickInput,
  });
}

const _categories = [
  _CategoryInfo(label: '모유', imagePath: 'assets/images/icon_breastfeeding.png', category: RecordCategory.feeding, quickInput: '모유 수유'),
  _CategoryInfo(label: '분유', imagePath: 'assets/images/icon_bottle.png', category: RecordCategory.feeding, quickInput: '분유 먹음'),
  _CategoryInfo(label: '이유식', imagePath: 'assets/images/icon_babyfood.png', category: RecordCategory.babyfood, quickInput: '이유식 먹음'),
  _CategoryInfo(label: '간식', imagePath: 'assets/images/icon_snack.png', category: RecordCategory.snack, quickInput: '간식 먹음'),
  _CategoryInfo(label: '기저귀', imagePath: 'assets/images/icon_diaper.png', category: RecordCategory.diaper, quickInput: '기저귀 갈았어'),
  _CategoryInfo(label: '수면', imagePath: 'assets/images/icon_sleep.png', category: RecordCategory.sleep, quickInput: '잠들었어'),
  _CategoryInfo(label: '유축', imagePath: 'assets/images/icon_pump.png', category: RecordCategory.feeding, quickInput: '유축'),
  _CategoryInfo(label: '체온', imagePath: 'assets/images/icon_temperature.png', category: RecordCategory.health, quickInput: '체온 재었어'),
  _CategoryInfo(label: '약', imagePath: 'assets/images/icon_medicine.png', category: RecordCategory.health, quickInput: '약 먹었어'),
  _CategoryInfo(label: '목욕', imagePath: 'assets/images/icon_bath.png', category: RecordCategory.other, quickInput: '목욕했어'),
  _CategoryInfo(label: '외출', imagePath: 'assets/images/icon_outing.png', category: RecordCategory.other, quickInput: '외출'),
  _CategoryInfo(label: '병원', imagePath: 'assets/images/icon_hospital.png', category: RecordCategory.health, quickInput: '병원 갔어'),
];

class RecordHomeScreen extends StatefulWidget {
  const RecordHomeScreen({super.key});

  @override
  State<RecordHomeScreen> createState() => _RecordHomeScreenState();
}

class _RecordHomeScreenState extends State<RecordHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  bool _showInput = false;

  // 녹음 모드 펄스 애니메이션
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _applyRecordFromParse(
    ParseResult result,
    String inputSource, {
    VoidCallback? onSuccess,
  }) {
    if (result.isSuccess && result.record != null) {
      final record = result.record!;
      record.inputSource = inputSource;
      context.read<RecordService>().addRecord(record);

      // ── NLP 분석 로그 (Firestore 업로드) ──
      final analytics = context.read<NlpAnalyticsService>();
      analytics.logParse(
        rawInput: record.rawInput ?? '',
        inputSource: inputSource,
        detectedCategory: record.category.name,
        confidence: result.confidence,
        scores: {},
        detectedSubType: record.feedingType?.name ?? record.diaperType?.name,
        appAction: result.confidence > 0.7 ? 'autoSaved' : 'confirmCard',
        responseTimeMs: 0,
      );

      onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${record.categoryEmoji} ${record.summary} 기록 완료!',
            style: const TextStyle(color: AppTheme.onSurface),
          ),
          backgroundColor: AppTheme.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '기록을 이해하지 못했어요. 다시 입력해주세요.',
            style: TextStyle(color: AppTheme.onSurface),
          ),
          backgroundColor: AppTheme.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showFeedingTypeDisambiguationSheet(
    String rawText,
    ParseResult result,
    String inputSource, {
    VoidCallback? onSuccess,
  }) {
    final opts = result.feedingTypeDisambiguationOptions;
    if (opts == null || opts.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$rawText"',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                FeedingTypeDisambiguationChips(
                  options: opts,
                  onSelected: (t) {
                    Navigator.pop(ctx);
                    final pending = result.pendingRawInput ?? rawText;
                    final r = NlpParser.parseWithFeedingType(pending, t);
                    _applyRecordFromParse(r, inputSource, onSuccess: onSuccess);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryDisambiguationSheet(
    String rawText,
    ParseResult result,
    String inputSource, {
    VoidCallback? onSuccess,
  }) {
    final opts = result.disambiguationOptions;
    if (opts == null || opts.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$rawText"',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                CategoryDisambiguationChips(
                  options: opts,
                  onSelected: (cat) {
                    Navigator.pop(ctx);
                    final pending = result.pendingRawInput ?? rawText;
                    final r = NlpParser.parseWithCategory(pending, cat);
                    if (r.needsFeedingTypeDisambiguation) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        _showFeedingTypeDisambiguationSheet(
                          pending,
                          r,
                          inputSource,
                          onSuccess: onSuccess,
                        );
                      });
                      return;
                    }
                    _applyRecordFromParse(r, inputSource, onSuccess: onSuccess);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteRecord(BabyRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('기록 삭제', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text('${record.categoryEmoji} ${record.summary}\n\n이 기록을 삭제할까요?\n삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<RecordService>().deleteRecord(record.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${record.categoryEmoji} 기록이 삭제되었어요.',
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            backgroundColor: AppTheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showMedicineTypeDisambiguationSheet(
    String rawText,
    ParseResult result,
    String inputSource, {
    VoidCallback? onSuccess,
  }) {
    final opts = result.medicineTypeOptions;
    if (opts == null || opts.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '어떤 약을 먹었나요?',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opts.map((opt) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        final pending = result.pendingRawInput ?? rawText;
                        final r = NlpParser.parseWithMedicineType(
                          pending,
                          opt.medicineName,
                        );
                        _applyRecordFromParse(r, inputSource, onSuccess: onSuccess);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.healthBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.healthColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          opt.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.healthColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStoolDetailSheet(
    String rawText,
    ParseResult result,
    String inputSource, {
    VoidCallback? onSuccess,
  }) {
    final consistencyOpts = result.stoolConsistencyOptions;
    final colorOpts = result.stoolColorOptions;
    final pending = result.pendingRecord;
    if (consistencyOpts == null || pending == null) return;

    String? selectedConsistency;
    String? selectedColor;
    final chipColor = const Color(0xFFFFE5A0); // diaper color

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: 20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '💩 대변 상태는 어땠나요?',
                      style: TextStyle(
                        fontSize: 16, height: 1.35,
                        color: AppTheme.onSurface, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '묽기',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: consistencyOpts.map((opt) {
                        final isSelected = selectedConsistency == opt.value;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedConsistency = isSelected ? null : opt.value;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFB300).withOpacity(0.2)
                                  : chipColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFFB300)
                                    : chipColor.withOpacity(0.5),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFE65100)
                                    : AppTheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (colorOpts != null && colorOpts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '색깔',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: colorOpts.map((opt) {
                          final isSelected = selectedColor == opt.value;
                          final dotColor = _stoolColorDot(opt.value);
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedColor = isSelected ? null : opt.value;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFB300).withOpacity(0.2)
                                    : chipColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFB300)
                                      : chipColor.withOpacity(0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black26, width: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFE65100)
                                          : AppTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              // 건너뛰기 → 상세 없이 그냥 저장
                              final r = ParseResult.success(
                                pending,
                                confidence: 0.9,
                                message: '기저귀 교체(${pending.diaperType == DiaperType.poop ? "대변" : "소변+대변"}) 기록',
                              );
                              _applyRecordFromParse(r, inputSource, onSuccess: onSuccess);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('건너뛰기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              final memoItems = <String>[];
                              if (selectedConsistency != null && selectedConsistency != '보통') {
                                memoItems.add(selectedConsistency!);
                              }
                              if (selectedColor != null) {
                                memoItems.add(selectedColor!);
                              }
                              final memo = memoItems.isNotEmpty ? memoItems.join(', ') : null;
                              final updated = BabyRecord(
                                id: pending.id,
                                category: pending.category,
                                timestamp: pending.timestamp,
                                rawInput: pending.rawInput,
                                diaperType: pending.diaperType,
                                memo: memo,
                              );
                              final typeName = pending.diaperType == DiaperType.poop ? '대변' : '소변+대변';
                              final memoText = memo != null ? ' ($memo)' : '';
                              final r = ParseResult.success(
                                updated,
                                confidence: 0.9,
                                message: '기저귀 교체($typeName)$memoText 기록',
                              );
                              _applyRecordFromParse(r, inputSource, onSuccess: onSuccess);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFFB5A7), Color(0xFFFF9A8C)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('확인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _stoolColorDot(String colorName) {
    switch (colorName) {
      case '노란색': return const Color(0xFFFFD54F);
      case '갈색': return const Color(0xFF8D6E63);
      case '녹색': return const Color(0xFF66BB6A);
      case '검은색': return const Color(0xFF424242);
      case '빨간색': return const Color(0xFFEF5350);
      case '흰색': return const Color(0xFFF5F5F5);
      default: return const Color(0xFFBDBDBD);
    }
  }

  void _showAmountDisambiguationSheet(
    String rawText,
    ParseResult result,
    String inputSource, {
    VoidCallback? onSuccess,
  }) {
    final opts = result.amountOptions;
    final pending = result.pendingRecord;
    if (opts == null || opts.isEmpty || pending == null) return;

    final isBreast = pending.feedingType == FeedingType.breast;
    final title = isBreast ? '모유 수유 시간이 어느 정도였나요?' : '분유 양은 얼마였나요?';
    final chipColor = const Color(0xFFFFB5A7); // feeding color

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, height: 1.35,
                    color: AppTheme.onSurface, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: opts.map((opt) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        // 선택한 값으로 레코드 완성
                        final updated = BabyRecord(
                          id: pending.id,
                          category: pending.category,
                          timestamp: pending.timestamp,
                          rawInput: pending.rawInput,
                          feedingType: pending.feedingType,
                          amountMl: opt.amountMl,
                          durationMinutes: opt.durationText != null
                              ? int.tryParse(opt.durationText!)
                              : pending.durationMinutes,
                          memo: pending.memo,
                        );
                        final typeName = isBreast ? '모유' : '분유';
                        final desc = opt.amountMl != null
                            ? '${opt.amountMl}ml'
                            : opt.durationText != null
                                ? '${opt.durationText}분'
                                : '';
                        final r = ParseResult.success(
                          updated,
                          confidence: 0.9,
                          message: '수유($typeName) $desc 기록',
                        );
                        _applyRecordFromParse(r, inputSource, onSuccess: onSuccess);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: chipColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: chipColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: chipColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleQuickInput(String text) {
    final result = NlpParser.parse(text);
    if (result.needsStoolDetailInput) {
      _showStoolDetailSheet(text, result, 'quick');
      return;
    }
    if (result.needsAmountInput) {
      _showAmountDisambiguationSheet(text, result, 'quick');
      return;
    }
    if (result.needsMedicineTypeDisambiguation) {
      _showMedicineTypeDisambiguationSheet(text, result, 'quick');
      return;
    }
    if (result.needsFeedingTypeDisambiguation) {
      _showFeedingTypeDisambiguationSheet(text, result, 'quick');
      return;
    }
    if (result.needsDisambiguation) {
      _showCategoryDisambiguationSheet(text, result, 'quick');
      return;
    }
    _applyRecordFromParse(result, 'quick');
  }

  void _handleTextSubmit(String text, {String source = 'chat'}) {
    if (text.trim().isEmpty) return;
    final result = NlpParser.parse(text);
    final onTextSuccess = () {
      if (!mounted) return;
      _inputController.clear();
      setState(() => _showInput = false);
    };
    if (result.needsStoolDetailInput) {
      _showStoolDetailSheet(
        text,
        result,
        source,
        onSuccess: onTextSuccess,
      );
      return;
    }
    if (result.needsAmountInput) {
      _showAmountDisambiguationSheet(
        text,
        result,
        source,
        onSuccess: onTextSuccess,
      );
      return;
    }
    if (result.needsMedicineTypeDisambiguation) {
      _showMedicineTypeDisambiguationSheet(
        text,
        result,
        source,
        onSuccess: onTextSuccess,
      );
      return;
    }
    if (result.needsFeedingTypeDisambiguation) {
      _showFeedingTypeDisambiguationSheet(
        text,
        result,
        source,
        onSuccess: onTextSuccess,
      );
      return;
    }
    if (result.needsDisambiguation) {
      _showCategoryDisambiguationSheet(
        text,
        result,
        source,
        onSuccess: onTextSuccess,
      );
      return;
    }
    _applyRecordFromParse(
      result,
      source,
      onSuccess: () {
        if (!mounted) return;
        if (result.isSuccess && result.record != null) {
          onTextSuccess();
        }
      },
    );
  }

  void _handleVoiceInput() async {
    final speechService = context.read<SpeechService>();

    // 이미 녹음 중이면 중지
    if (speechService.isListening) {
      await speechService.stopListening();
      _pulseController.stop();
      _pulseController.reset();
      return;
    }

    if (!speechService.isAvailable) {
      await speechService.initialize();
    }
    if (!speechService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              speechService.errorMessage ?? '음성 인식을 사용할 수 없습니다.',
              style: const TextStyle(color: AppTheme.onError),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // 녹음 시작 → 애니메이션 시작
    _pulseController.repeat(reverse: true);

    await speechService.startListening(
      onResult: (text) {
        if (mounted && text.isNotEmpty) {
          _pulseController.stop();
          _pulseController.reset();
          _handleTextSubmit(text, source: 'voice');
        }
      },
      onError: (error) {
        if (mounted) {
          _pulseController.stop();
          _pulseController.reset();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error,
                style: const TextStyle(color: AppTheme.onError),
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final speechService = context.watch<SpeechService>();
    final profile = recordService.profile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // === Header: 나이 + 버튼 ===
            _buildHeader(profile, speechService),

            // === 녹음 모드 인디케이터 배너 ===
            if (speechService.isListening)
              _buildRecordingBanner(),

            // === Content ===
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // === 카테고리 아이콘 바 ===
                  _buildCategoryBar(),

                  const SizedBox(height: 10),

                  // === 단계형 버튼 입력 (채팅과 동일 플로우) ===
                  GuidedRecordButtonSection(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    onPhraseSubmit: (phrase) =>
                        _handleTextSubmit(phrase, source: 'guided'),
                  ),

                  const SizedBox(height: 16),

                  // === 마지막 기록 요약 ===
                  _buildLastRecordsSummary(recordService),

                  const SizedBox(height: 20),

                  // === 오늘 기록 타임라인 ===
                  _buildDaySection(recordService, DateTime.now(), '오늘'),

                  // === 어제 기록 ===
                  _buildDaySection(
                    recordService,
                    DateTime.now().subtract(const Duration(days: 1)),
                    '어제',
                  ),

                  // === 그저께 ===
                  _buildDaySection(
                    recordService,
                    DateTime.now().subtract(const Duration(days: 2)),
                    null,
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),

            // === 하단 입력바 (음성/텍스트) ===
            if (_showInput) _buildInputBar(),
          ],
        ),
      ),
      floatingActionButton: _showInput
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _showInput = true),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: AppTheme.onPrimary, size: 28),
            ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(dynamic profile, SpeechService speechService) {
    final ageText = profile != null
        ? '${profile.ageInMonths}개월 ${profile.ageInDays % 30}일 (D+${profile.ageInDays})'
        : '아기톡톡';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          // 아바타 이미지
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.25),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/baby_avatar_default.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ageText,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                // 녹음 중 상태 텍스트
                if (speechService.isListening)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '음성 녹음 중...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF8E8E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: AppTheme.onSurfaceVariant,
            tooltip: '채팅 모드',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
          // 마이크 버튼 — 녹음 중이면 빨간색으로 변경
          GestureDetector(
            onTap: _handleVoiceInput,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: speechService.isListening
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                      )
                    : null,
                color: speechService.isListening ? null : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: speechService.isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  speechService.isListening
                      ? Icons.stop_rounded
                      : Icons.mic_none_rounded,
                  color: speechService.isListening
                      ? Colors.white
                      : AppTheme.onSurfaceVariant,
                  size: speechService.isListening ? 24 : 22,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppTheme.onSurfaceVariant,
            onPressed: () => setState(() => _showInput = !_showInput),
          ),
        ],
      ),
    );
  }

  // ─── 녹음 모드 배너 ───
  Widget _buildRecordingBanner() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.08 + _pulseAnimation.value * 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.error.withOpacity(0.2 + _pulseAnimation.value * 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.error.withOpacity(_pulseAnimation.value),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '음성 녹음 중... 말씀해주세요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error.withOpacity(0.7 + _pulseAnimation.value * 0.3),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _handleVoiceInput,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '중지',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF8E8E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Category Icon Bar ───
  Widget _buildCategoryBar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => _handleQuickInput(cat.quickInput),
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceContainerHigh,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(cat.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 마지막 기록 요약 (기저귀/수유/잠) ───
  Widget _buildLastRecordsSummary(RecordService recordService) {
    final lastFeeding = recordService.lastFeedingRecord;
    final lastSleep = recordService.lastSleepRecord;
    final lastDiaper = recordService.lastDiaperRecord;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (lastDiaper != null)
            Expanded(child: _buildLastRecordChip(
              '마지막 기저귀',
              TimeUtils.elapsedSince(lastDiaper.timestamp),
              lastDiaper.diaperType == DiaperType.poop ? '대변' :
              lastDiaper.diaperType == DiaperType.pee ? '소변' : '소변+대변',
              AppTheme.tertiary,
            )),
          if (lastFeeding != null) ...[
            const SizedBox(width: 8),
            Expanded(child: _buildLastRecordChip(
              '마지막 수유',
              TimeUtils.elapsedSince(lastFeeding.timestamp),
              lastFeeding.amountMl != null ? '${lastFeeding.amountMl}ml' : '',
              AppTheme.primary,
            )),
          ],
          if (lastSleep != null) ...[
            const SizedBox(width: 8),
            Expanded(child: _buildLastRecordChip(
              '마지막 잠',
              TimeUtils.elapsedSince(lastSleep.timestamp),
              lastSleep.sleepStatus == SleepStatus.start ? '수면중' : '깨어남',
              AppTheme.secondary,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildLastRecordChip(String title, String elapsed, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            elapsed,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  // ─── 날짜 섹션 ───
  Widget _buildDaySection(RecordService recordService, DateTime date, String? label) {
    final records = recordService.getRecordsForDate(date);
    if (records.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final dayLabel = label ?? DateFormat('M월 d일 (E)', 'ko_KR').format(date);

    // 일간 합계
    final totalMl = records
        .where((r) => r.category == RecordCategory.feeding && r.amountMl != null)
        .fold<int>(0, (sum, r) => sum + r.amountMl!);

    final profile = recordService.profile;
    final dPlus = profile != null ? 'D+${date.difference(profile.birthDate).inDays}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: AppTheme.surfaceContainerLow,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? DateFormat('M월 d일 (E)', 'ko_KR').format(date)
                          : dayLabel,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (label != null)
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (totalMl > 0)
                Text(
                  '${totalMl}ml',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (dPlus.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  dPlus,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 기록 리스트
        ...records.map((record) => _buildRecordTile(record)),
      ],
    );
  }

  // ─── 개별 기록 타일 ───
  Widget _buildRecordTile(BabyRecord record) {
    final timeStr = DateFormat('hh:mm', 'ko_KR').format(record.timestamp);
    final amPm = record.timestamp.hour < 12 ? 'AM' : 'PM';

    // 카테고리별 색상
    Color dotColor;
    switch (record.category) {
      case RecordCategory.feeding:
        dotColor = AppTheme.primary;
        break;
      case RecordCategory.sleep:
        dotColor = AppTheme.secondary;
        break;
      case RecordCategory.diaper:
        dotColor = AppTheme.tertiary;
        break;
      case RecordCategory.health:
        dotColor = AppTheme.healthColor;
        break;
      case RecordCategory.babyfood:
        dotColor = AppTheme.babyfoodColor;
        break;
      case RecordCategory.snack:
        dotColor = AppTheme.snackColor;
        break;
      default:
        dotColor = AppTheme.onSurfaceVariant;
    }

    // 제목
    String title;
    Color titleColor;
    switch (record.category) {
      case RecordCategory.feeding:
        final typeStr = record.feedingType == FeedingType.breast ? '모유' : '분유';
        title = typeStr;
        titleColor = AppTheme.primary;
        break;
      case RecordCategory.babyfood:
        title = '이유식';
        titleColor = AppTheme.babyfoodColor;
        break;
      case RecordCategory.snack:
        title = '간식';
        titleColor = AppTheme.snackColor;
        break;
      case RecordCategory.sleep:
        title = record.sleepStatus == SleepStatus.start ? '잠듦' : '깨어남';
        titleColor = AppTheme.secondary;
        break;
      case RecordCategory.diaper:
        final dType = record.diaperType == DiaperType.poop ? '대변' :
            record.diaperType == DiaperType.pee ? '소변' : '소변+대변';
        final stoolMemo = record.memo != null && record.memo!.isNotEmpty ? ' · ${record.memo}' : '';
        title = '$dType$stoolMemo';
        titleColor = AppTheme.tertiary;
        break;
      case RecordCategory.health:
        title = record.temperature != null ? '체온 ${record.temperature}°C' :
            record.medicine != null ? '약 ${record.medicine}' : '건강';
        titleColor = AppTheme.healthColor;
        break;
      default:
        title = record.categoryName;
        titleColor = AppTheme.onSurface;
    }

    // 서브텍스트
    String? subtitle;
    if (record.amountMl != null) subtitle = '${record.amountMl} ml';
    if (record.durationMinutes != null) {
      subtitle = (subtitle != null ? '$subtitle · ' : '') + '${record.durationMinutes}분';
    }
    if (record.memo != null && record.memo!.isNotEmpty) {
      subtitle = (subtitle != null ? '$subtitle\n' : '') + record.memo!;
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => RecordEditSheet(record: record),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    amPm,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 도트
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // 입력 소스 배지
                      if (record.inputSource != null) ...[
                        const SizedBox(width: 6),
                        Builder(
                          builder: (context) {
                            final src = record.inputSource!;
                            final Color bg;
                            final Color fg;
                            final IconData icon;
                            if (src == 'voice') {
                              bg = const Color(0xFFFF8E8E).withOpacity(0.15);
                              fg = const Color(0xFFFF8E8E);
                              icon = Icons.mic;
                            } else if (src == 'quick') {
                              bg = AppTheme.tertiary.withOpacity(0.15);
                              fg = AppTheme.tertiary;
                              icon = Icons.bolt;
                            } else if (src == 'guided') {
                              bg = AppTheme.primaryFixed.withOpacity(0.2);
                              fg = AppTheme.primary;
                              icon = Icons.touch_app_outlined;
                            } else {
                              bg = AppTheme.primary.withOpacity(0.15);
                              fg = AppTheme.primary;
                              icon = Icons.chat_bubble_outline;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 9, color: fg),
                                  const SizedBox(width: 2),
                                  Text(
                                    record.inputSourceName,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: fg,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 삭제 버튼
            GestureDetector(
              onTap: () => _confirmDeleteRecord(record),
              child: Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 하단 텍스트 입력바 ───
  Widget _buildInputBar() {
    final speechService = context.watch<SpeechService>();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: speechService.isListening
          ? const Color(0xFFFF6B6B).withOpacity(0.05)
          : AppTheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: speechService.isListening
                    ? AppTheme.error.withOpacity(0.08)
                    : AppTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: speechService.isListening
                    ? Border.all(color: AppTheme.error.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: TextField(
                controller: _inputController,
                autofocus: true,
                enabled: !speechService.isListening,
                decoration: InputDecoration(
                  hintText: speechService.isListening
                      ? '듣고 있어요...'
                      : '예: 분유 120ml 먹었어',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: TextStyle(
                    color: speechService.isListening
                        ? AppTheme.error.withOpacity(0.6)
                        : AppTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
                onSubmitted: _handleTextSubmit,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          GestureDetector(
            onTap: () => _handleTextSubmit(_inputController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: AppTheme.onPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 4),
          // 마이크 버튼 (하단 입력바)
          GestureDetector(
            onTap: _handleVoiceInput,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: speechService.isListening
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                      )
                    : null,
                color: speechService.isListening
                    ? null
                    : AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                boxShadow: speechService.isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                speechService.isListening
                    ? Icons.stop_rounded
                    : Icons.mic_none_rounded,
                color: speechService.isListening
                    ? Colors.white
                    : AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 닫기 버튼
          GestureDetector(
            onTap: () {
              // 녹음 중이면 먼저 중지
              if (speechService.isListening) {
                _handleVoiceInput();
              }
              setState(() => _showInput = false);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppTheme.onSurfaceVariant, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
