import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 수유 / 수면 실시간 타이머 화면
class TimerScreen extends StatefulWidget {
  final RecordCategory initialCategory;
  const TimerScreen({super.key, this.initialCategory = RecordCategory.feeding});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late RecordCategory _category;
  bool _isRunning = false;
  DateTime? _startTime;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // 수유 전용: 좌/우 가슴
  String? _breastSide; // 'left', 'right'
  Duration _leftTime = Duration.zero;
  Duration _rightTime = Duration.zero;

  // 수유 타입
  FeedingType _feedingType = FeedingType.breast;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
      if (_category == RecordCategory.feeding &&
          _feedingType == FeedingType.breast) {
        _breastSide = 'left';
        _leftTime = Duration.zero;
        _rightTime = Duration.zero;
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
        if (_breastSide == 'left') {
          _leftTime += const Duration(seconds: 1);
        } else if (_breastSide == 'right') {
          _rightTime += const Duration(seconds: 1);
        }
      });
    });
  }

  void _pause() {
    setState(() => _isRunning = false);
    _ticker?.cancel();
  }

  void _resume() {
    final pausedElapsed = _elapsed;
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now().subtract(pausedElapsed);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
        if (_breastSide == 'left') {
          _leftTime += const Duration(seconds: 1);
        } else if (_breastSide == 'right') {
          _rightTime += const Duration(seconds: 1);
        }
      });
    });
  }

  void _switchBreast() {
    if (_breastSide == null) return;
    setState(() {
      _breastSide = _breastSide == 'left' ? 'right' : 'left';
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    setState(() => _isRunning = false);

    final minutes = _elapsed.inMinutes;
    if (minutes < 1 && _elapsed.inSeconds < 30) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('30초 미만은 기록되지 않아요'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final recordService = context.read<RecordService>();
    String? memo;

    if (_breastSide != null) {
      memo = '왼쪽 ${_leftTime.inMinutes}분, 오른쪽 ${_rightTime.inMinutes}분';
    }

    SleepStatus? sleepStatus;
    if (_category == RecordCategory.sleep) {
      sleepStatus = SleepStatus.end;
      // 잠듦 기록 먼저 추가 (시작 시간)
      await recordService.addRecord(BabyRecord(
        id: const Uuid().v4(),
        category: RecordCategory.sleep,
        timestamp: _startTime!,
        sleepStatus: SleepStatus.start,
        inputSource: 'timer',
      ));
    }

    final record = BabyRecord(
      id: const Uuid().v4(),
      category: _category,
      timestamp: DateTime.now(),
      durationMinutes: max(minutes, 1),
      feedingType:
          _category == RecordCategory.feeding ? _feedingType : null,
      sleepStatus: sleepStatus,
      memo: memo,
      inputSource: 'timer',
    );

    await recordService.addRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${record.categoryName} ${_elapsed.inMinutes}분 기록 완료!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _reset();
    }
  }

  int max(int a, int b) => a > b ? a : b;

  void _reset() {
    setState(() {
      _elapsed = Duration.zero;
      _startTime = null;
      _breastSide = null;
      _leftTime = Duration.zero;
      _rightTime = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('타이머'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 카테고리 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CategoryChip(
                    label: '수유', emoji: '🍼',
                    isActive: _category == RecordCategory.feeding,
                    onTap: () => setState(() => _category = RecordCategory.feeding),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: '수면', emoji: '😴',
                    isActive: _category == RecordCategory.sleep,
                    onTap: () => setState(() => _category = RecordCategory.sleep),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: '유축', emoji: '🍶',
                    isActive: _category == RecordCategory.pumping,
                    onTap: () => setState(() => _category = RecordCategory.pumping),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: '터미타임', emoji: '👶',
                    isActive: _category == RecordCategory.tummytime,
                    onTap: () => setState(() => _category = RecordCategory.tummytime),
                  ),
                ],
              ),
            ),

            // 수유 타입 선택 (수유일 때만)
            if (_category == RecordCategory.feeding) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('모유'),
                    selected: _feedingType == FeedingType.breast,
                    selectedColor: AppTheme.primaryContainer,
                    onSelected: (_) =>
                        setState(() => _feedingType = FeedingType.breast),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('분유'),
                    selected: _feedingType == FeedingType.formula,
                    selectedColor: AppTheme.primaryContainer,
                    onSelected: (_) =>
                        setState(() => _feedingType = FeedingType.formula),
                  ),
                ],
              ),
            ],

            const Spacer(),

            // 타이머 디스플레이
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                color: AppTheme.textPrimary,
                letterSpacing: 4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),

            // 좌우 가슴 표시 (모유일 때)
            if (_category == RecordCategory.feeding &&
                _feedingType == FeedingType.breast &&
                _startTime != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BreastIndicator(
                    label: '왼쪽',
                    time: _formatDuration(_leftTime),
                    isActive: _breastSide == 'left',
                    onTap: () => setState(() => _breastSide = 'left'),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _switchBreast,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _BreastIndicator(
                    label: '오른쪽',
                    time: _formatDuration(_rightTime),
                    isActive: _breastSide == 'right',
                    onTap: () => setState(() => _breastSide = 'right'),
                  ),
                ],
              ),
            ],

            const Spacer(),

            // 컨트롤 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_startTime != null)
                    _CircleButton(
                      icon: Icons.stop_rounded,
                      label: '저장',
                      color: AppTheme.primary,
                      onTap: _stop,
                    ),
                  if (_startTime == null)
                    _CircleButton(
                      icon: Icons.play_arrow_rounded,
                      label: '시작',
                      color: AppTheme.primary,
                      size: 80,
                      onTap: _start,
                    )
                  else if (_isRunning)
                    _CircleButton(
                      icon: Icons.pause_rounded,
                      label: '일시정지',
                      color: AppTheme.tertiary,
                      size: 80,
                      onTap: _pause,
                    )
                  else
                    _CircleButton(
                      icon: Icons.play_arrow_rounded,
                      label: '계속',
                      color: AppTheme.primary,
                      size: 80,
                      onTap: _resume,
                    ),
                  if (_startTime != null)
                    _CircleButton(
                      icon: Icons.refresh_rounded,
                      label: '초기화',
                      color: AppTheme.textSecondary,
                      onTap: () {
                        _ticker?.cancel();
                        _reset();
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: AppTheme.primary, width: 1.5)
              : null,
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BreastIndicator extends StatelessWidget {
  final String label;
  final String time;
  final bool isActive;
  final VoidCallback onTap;

  const _BreastIndicator({
    required this.label,
    required this.time,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryContainer.withOpacity(0.4)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border:
              isActive ? Border.all(color: AppTheme.primary, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    this.size = 56,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(
          fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
