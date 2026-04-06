import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 엄마 건강 추적 화면
class MomHealthScreen extends StatefulWidget {
  const MomHealthScreen({super.key});
  @override
  State<MomHealthScreen> createState() => _MomHealthScreenState();
}

class _MomHealthScreenState extends State<MomHealthScreen> {
  List<MomHealthEntry> _entries = [];
  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mom_health_entries');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _entries = list.map((e) => MomHealthEntry.fromJson(e)).toList();
        _entries.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mom_health_entries',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  MomHealthEntry? get _todayEntry {
    try {
      return _entries.firstWhere((e) =>
          e.date.year == _today.year &&
          e.date.month == _today.month &&
          e.date.day == _today.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateToday(MomHealthEntry entry) async {
    setState(() {
      _entries.removeWhere((e) =>
          e.date.year == entry.date.year &&
          e.date.month == entry.date.month &&
          e.date.day == entry.date.day);
      _entries.insert(0, entry);
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayEntry ??
        MomHealthEntry(date: DateTime(_today.year, _today.month, _today.day));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('엄마 건강'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 오늘 기록 카드
          Text('오늘의 컨디션', style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 12),

          // 기분
          _SectionCard(
            title: '기분',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.map((m) {
                final isSelected = today.mood == m.value;
                return GestureDetector(
                  onTap: () => _updateToday(today.copyWith(mood: m.value)),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? m.color.withOpacity(0.2) : AppTheme.surfaceContainerHigh,
                          border: isSelected ? Border.all(color: m.color, width: 2) : null,
                        ),
                        child: Center(child: Text(m.emoji, style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(height: 4),
                      Text(m.label, style: TextStyle(fontSize: 10,
                        color: isSelected ? m.color : AppTheme.textHint,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // 수분 섭취
          _SectionCard(
            title: '수분 섭취',
            trailing: Text('${today.waterCups}잔 (${today.waterCups * 250}ml)',
              style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            child: Row(
              children: [
                IconButton(
                  onPressed: today.waterCups > 0
                      ? () => _updateToday(today.copyWith(waterCups: today.waterCups - 1))
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.textSecondary,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(8, (i) {
                      final filled = i < today.waterCups;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          filled ? Icons.water_drop : Icons.water_drop_outlined,
                          size: 24,
                          color: filled ? const Color(0xFF81D4FA) : AppTheme.surfaceContainerHigh,
                        ),
                      );
                    }),
                  ),
                ),
                IconButton(
                  onPressed: today.waterCups < 12
                      ? () => _updateToday(today.copyWith(waterCups: today.waterCups + 1))
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 수면
          _SectionCard(
            title: '엄마 수면 시간',
            child: Slider(
              value: today.sleepHours,
              min: 0, max: 12, divisions: 24,
              label: '${today.sleepHours.toStringAsFixed(1)}시간',
              activeColor: AppTheme.primary,
              onChanged: (v) => _updateToday(today.copyWith(sleepHours: v)),
            ),
          ),

          const SizedBox(height: 12),

          // 유축량
          _SectionCard(
            title: '유축량 (ml)',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: today.pumpingMl.toDouble(),
                    min: 0, max: 500, divisions: 50,
                    label: '${today.pumpingMl}ml',
                    activeColor: AppTheme.tertiary,
                    onChanged: (v) => _updateToday(today.copyWith(pumpingMl: v.toInt())),
                  ),
                ),
                Text('${today.pumpingMl}ml', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 메모
          _SectionCard(
            title: '오늘의 메모',
            child: TextField(
              decoration: InputDecoration(
                hintText: '몸 상태, 약 복용 등을 기록해요',
                filled: true,
                fillColor: AppTheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              controller: TextEditingController(text: today.memo),
              onChanged: (v) => _updateToday(today.copyWith(memo: v)),
            ),
          ),

          const SizedBox(height: 24),

          // 최근 기록
          if (_entries.length > 1) ...[
            Text('최근 기록', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 12),
            ..._entries.skip(1).take(7).map((entry) {
              final moodData = _moods.firstWhere(
                (m) => m.value == entry.mood,
                orElse: () => _moods[2],
              );
              return Card(
                color: AppTheme.surfaceContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(DateFormat('M/d').format(entry.date),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                      const SizedBox(width: 12),
                      Text(moodData.emoji, style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text('수분 ${entry.waterCups}잔', style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      Text('수면 ${entry.sleepHours.toStringAsFixed(1)}h', style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                      if (entry.pumpingMl > 0) ...[
                        const SizedBox(width: 8),
                        Text('유축 ${entry.pumpingMl}ml', style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MoodOption {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _MoodOption({required this.emoji, required this.label, required this.value, required this.color});
}

const _moods = [
  _MoodOption(emoji: '😢', label: '힘듦', value: 'bad', color: Color(0xFFEF9A9A)),
  _MoodOption(emoji: '😐', label: '보통', value: 'soso', color: Color(0xFFFFE082)),
  _MoodOption(emoji: '🙂', label: '괜찮음', value: 'ok', color: Color(0xFFA5D6A7)),
  _MoodOption(emoji: '😊', label: '좋음', value: 'good', color: Color(0xFF81D4FA)),
  _MoodOption(emoji: '🥰', label: '최고', value: 'great', color: Color(0xFFCE93D8)),
];

class MomHealthEntry {
  final DateTime date;
  final String mood;
  final int waterCups;
  final double sleepHours;
  final int pumpingMl;
  final String memo;

  MomHealthEntry({
    required this.date,
    this.mood = 'ok',
    this.waterCups = 0,
    this.sleepHours = 0,
    this.pumpingMl = 0,
    this.memo = '',
  });

  MomHealthEntry copyWith({
    String? mood,
    int? waterCups,
    double? sleepHours,
    int? pumpingMl,
    String? memo,
  }) {
    return MomHealthEntry(
      date: date,
      mood: mood ?? this.mood,
      waterCups: waterCups ?? this.waterCups,
      sleepHours: sleepHours ?? this.sleepHours,
      pumpingMl: pumpingMl ?? this.pumpingMl,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'mood': mood,
    'waterCups': waterCups,
    'sleepHours': sleepHours,
    'pumpingMl': pumpingMl,
    'memo': memo,
  };

  factory MomHealthEntry.fromJson(Map<String, dynamic> j) => MomHealthEntry(
    date: DateTime.parse(j['date']),
    mood: j['mood'] ?? 'ok',
    waterCups: j['waterCups'] ?? 0,
    sleepHours: (j['sleepHours'] as num?)?.toDouble() ?? 0,
    pumpingMl: j['pumpingMl'] ?? 0,
    memo: j['memo'] ?? '',
  );
}
