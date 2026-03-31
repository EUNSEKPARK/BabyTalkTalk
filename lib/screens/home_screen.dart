import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/speech_service.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/utils/time_utils.dart';
import 'package:chat_baby_time/widgets/quick_action_chips.dart';
import 'package:chat_baby_time/widgets/record_card.dart';
import 'package:chat_baby_time/widgets/smart_input_bar.dart';
import 'package:chat_baby_time/widgets/today_summary_card.dart';
import 'package:chat_baby_time/screens/record_detail_screen.dart';
import 'package:chat_baby_time/screens/dashboard_screen.dart';
import 'package:chat_baby_time/screens/profile_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _TimelinePage(),
      const DashboardScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_rounded),
            label: '타임라인',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: '대시보드',
          ),
        ],
      ),
    );
  }
}

class _TimelinePage extends StatefulWidget {
  const _TimelinePage();

  @override
  State<_TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<_TimelinePage> {
  final TextEditingController _inputController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleTextSubmit(String text) async {
    if (text.trim().isEmpty) return;

    final result = NlpParser.parse(text);

    if (result.isSuccess && result.record != null) {
      // 파싱 결과 확인 스낵바 표시
      if (!mounted) return;

      final confirmed = await _showParseConfirmation(result);
      if (confirmed == true) {
        final service = context.read<RecordService>();
        await service.addRecord(result.record!);
        _inputController.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.record!.categoryEmoji} ${result.message}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showParseConfirmation(ParseResult result) {
    final record = result.record!;
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '이렇게 기록할까요?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            // 파싱 결과 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    record.categoryEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.summary,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.formatTime(record.timestamp),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 신뢰도 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  result.confidence > 0.7
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 16,
                  color: result.confidence > 0.7
                      ? AppTheme.success
                      : AppTheme.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  '인식 정확도: ${(result.confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: result.confidence > 0.7
                        ? AppTheme.success
                        : AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('수정할래요'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('저장!'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecordService>();
    final speechService = context.watch<SpeechService>();
    final records = service.getRecordsForDate(_selectedDate);

    return SafeArea(
      child: Column(
        children: [
          // 앱바 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                // 아기 프로필
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSetupScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.profile?.name ?? '아기톡톡',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (service.profile != null)
                            Text(
                              service.profile!.ageText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 날짜 선택
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isToday
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: _isToday
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isToday
                              ? '오늘'
                              : TimeUtils.formatDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isToday
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 오늘 요약 카드
          if (_isToday) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TodaySummaryCard(),
            ),
            const SizedBox(height: 12),
          ],

          // 빠른 액션 칩
          if (_isToday)
            QuickActionChips(
              onAction: (text) => _handleTextSubmit(text),
            ),

          // 타임라인
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/empty_records.png',
                              width: 180,
                              height: 180,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isToday
                                ? '오늘 첫 기록을 남겨보세요!'
                                : '이 날의 기록이 없어요',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (_isToday) ...[
                            const SizedBox(height: 8),
                            Text(
                              '아래에서 말하거나 입력하면 자동으로 기록돼요',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      return RecordCard(
                        record: records[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordDetailScreen(
                                record: records[index],
                              ),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordDetailScreen(
                                record: records[index],
                              ),
                            ),
                          );
                        },
                        onCopy: () async {
                          final original = records[index];
                          final copy = BabyRecord(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            category: original.category,
                            timestamp: DateTime.now(),
                            rawInput: original.rawInput,
                            inputSource: 'quick',
                            feedingType: original.feedingType,
                            amountMl: original.amountMl,
                            durationMinutes: original.durationMinutes,
                            sleepStatus: original.sleepStatus,
                            diaperType: original.diaperType,
                            temperature: original.temperature,
                            medicine: original.medicine,
                            memo: original.memo,
                          );
                          await service.addRecord(copy);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('기록이 복사되었어요!'),
                                backgroundColor: AppTheme.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        onDelete: () async {
                          await service.deleteRecord(records[index].id);
                        },
                      );
                    },
                  ),
          ),

          // 입력바
          if (_isToday)
            SmartInputBar(
              controller: _inputController,
              speechService: speechService,
              onSubmit: _handleTextSubmit,
            ),
        ],
      ),
    );
  }
}
