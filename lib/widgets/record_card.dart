import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/utils/time_utils.dart';

/// 타임라인에 표시되는 기록 카드
/// - 왼쪽 스와이프 → 삭제
/// - 오른쪽 스와이프 → 수정 / 복사(재생성)
/// - 탭 → 상세 보기
class RecordCard extends StatefulWidget {
  final BabyRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;

  const RecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
    this.onCopy,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  late AnimationController _animController;
  late Animation<double> _animOffset;
  bool _showingActions = false;

  // 스와이프 임계값
  static const double _editThreshold = 60;
  static const double _copyThreshold = 120;
  static const double _deleteThreshold = -80;
  static const double _maxDrag = 140;

  Color get _categoryColor {
    switch (widget.record.category) {
      case RecordCategory.feeding:
        return AppTheme.feedingColor;
      case RecordCategory.sleep:
        return AppTheme.sleepColor;
      case RecordCategory.diaper:
        return AppTheme.diaperColor;
      case RecordCategory.health:
        return AppTheme.healthColor;
      case RecordCategory.milestone:
        return AppTheme.milestoneColor;
      case RecordCategory.babyfood:
        return AppTheme.babyfoodColor;
      case RecordCategory.snack:
        return AppTheme.snackColor;
      case RecordCategory.bath:
        return AppTheme.bathColor;
      case RecordCategory.pumping:
        return AppTheme.pumpingColor;
      case RecordCategory.tummytime:
        return AppTheme.tummytimeColor;
      case RecordCategory.other:
        return AppTheme.otherColor;
    }
  }

  /// 카테고리별 미드저니 아이콘 이미지 경로
  String _categoryIconPath(BabyRecord record) {
    switch (record.category) {
      case RecordCategory.feeding:
        final ft = record.feedingType;
        if (ft == FeedingType.breast) return 'assets/images/icon_breastfeeding.png';
        return 'assets/images/icon_bottle.png'; // formula default
      case RecordCategory.babyfood:
        return 'assets/images/icon_babyfood.png';
      case RecordCategory.snack:
        return 'assets/images/icon_snack.png';
      case RecordCategory.sleep:
        return 'assets/images/icon_sleep.png';
      case RecordCategory.diaper:
        return 'assets/images/icon_diaper.png';
      case RecordCategory.health:
        if (record.temperature != null) return 'assets/images/icon_temperature.png';
        if (record.medicine != null && record.medicine!.isNotEmpty) return 'assets/images/icon_medicine.png';
        return 'assets/images/icon_hospital.png';
      case RecordCategory.milestone:
        return 'assets/images/icon_outing.png';
      case RecordCategory.bath:
        return 'assets/images/icon_bath.png';
      case RecordCategory.pumping:
        return 'assets/images/icon_breastfeeding.png';
      case RecordCategory.tummytime:
        return 'assets/images/icon_outing.png';
      case RecordCategory.other:
        return 'assets/images/icon_bath.png';
    }
  }

  Color get _categoryBg {
    switch (widget.record.category) {
      case RecordCategory.feeding:
        return AppTheme.feedingBg;
      case RecordCategory.sleep:
        return AppTheme.sleepBg;
      case RecordCategory.diaper:
        return AppTheme.diaperBg;
      case RecordCategory.health:
        return AppTheme.healthBg;
      case RecordCategory.milestone:
        return AppTheme.milestoneBg;
      case RecordCategory.babyfood:
        return AppTheme.babyfoodBg;
      case RecordCategory.snack:
        return AppTheme.snackBg;
      case RecordCategory.bath:
        return AppTheme.bathBg;
      case RecordCategory.pumping:
        return AppTheme.pumpingBg;
      case RecordCategory.tummytime:
        return AppTheme.tummytimeBg;
      case RecordCategory.other:
        return AppTheme.otherBg;
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animOffset = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _snapBack() {
    _animOffset = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragExtent = 0;
          _showingActions = false;
        });
      }
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent <= _deleteThreshold) {
      // 왼쪽 충분히 밀었으면 → 삭제 확인
      _snapBack();
      _confirmDelete();
    } else if (_dragExtent >= _copyThreshold && widget.onCopy != null) {
      // 오른쪽 많이 밀었으면 → 복사
      HapticFeedback.lightImpact();
      _snapBack();
      widget.onCopy!();
    } else if (_dragExtent >= _editThreshold && widget.onEdit != null) {
      // 오른쪽 조금 밀었으면 → 수정
      HapticFeedback.lightImpact();
      _snapBack();
      widget.onEdit!();
    } else {
      _snapBack();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('기록 삭제', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text('이 기록을 삭제할까요?\n삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deleteAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          // === 스와이프 배경 레이어 ===
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // 오른쪽 스와이프 시 보이는 영역 (수정/복사)
                  Expanded(
                    child: Container(
                      color: _dragExtent >= _copyThreshold
                          ? AppTheme.copyAction
                          : _dragExtent >= _editThreshold
                              ? AppTheme.editAction
                              : AppTheme.editAction.withOpacity(0.3),
                      padding: const EdgeInsets.only(left: 20),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _dragExtent >= _copyThreshold
                                ? Icons.copy_rounded
                                : Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _dragExtent >= _copyThreshold ? '복사' : '수정',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 왼쪽 스와이프 시 보이는 영역 (삭제)
                  Expanded(
                    child: Container(
                      color: _dragExtent <= _deleteThreshold
                          ? AppTheme.deleteAction
                          : AppTheme.deleteAction.withOpacity(0.3),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '삭제',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === 메인 카드 (드래그 가능) ===
          _SwipeAnimatedBuilder(
            listenable: _animController,
            builder: (context, child) {
              final offset =
                  _animController.isAnimating ? _animOffset.value : _dragExtent;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(
                    color: _categoryColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // 카테고리 아이콘 (이미지)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _categoryBg,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Center(
                        child: Image.asset(
                          _categoryIconPath(widget.record),
                          width: 30,
                          height: 30,
                          errorBuilder: (_, __, ___) => Text(
                            widget.record.categoryEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 내용
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 카테고리 이름 (컬러 라벨)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _categoryBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.record.categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _categoryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 입력 소스 표시
                              _InputSourceBadge(record: widget.record),
                              // 작성자 표시 (가족 공유 시)
                              if (widget.record.authorName != null &&
                                  widget.record.authorName!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.record.authorName!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple[400],
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // 시간
                              Text(
                                TimeUtils.formatTime(widget.record.timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.record.summary,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (widget.record.memo != null &&
                              widget.record.memo!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.record.memo!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (widget.record.photoPath != null &&
                              File(widget.record.photoPath!).existsSync())
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.photo_outlined, size: 14, color: AppTheme.textHint),
                                  const SizedBox(width: 4),
                                  Text('사진 첨부됨', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 스와이프 힌트 아이콘
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력 소스 배지 (음성/빠른입력/채팅)
class _InputSourceBadge extends StatelessWidget {
  final BabyRecord record;

  const _InputSourceBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    final src = record.inputSource;
    final Color color;
    final IconData icon;

    if (src == 'voice') {
      color = const Color(0xFFFF8E8E);
      icon = Icons.mic_rounded;
    } else if (src == 'quick') {
      color = AppTheme.milestoneColor;
      icon = Icons.bolt_rounded;
    } else if (src == 'guided') {
      color = AppTheme.primary;
      icon = Icons.touch_app_outlined;
    } else {
      color = AppTheme.secondary;
      icon = Icons.chat_bubble_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            record.inputSourceName,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// _SwipeAnimatedBuilder 대체 (AnimatedWidget 패턴)
class _SwipeAnimatedBuilder extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext, Widget?) builder;

  const _SwipeAnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
