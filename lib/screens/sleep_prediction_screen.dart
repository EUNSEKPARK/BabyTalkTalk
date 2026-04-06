import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 수면 최적 시간 예측 (SweetSpot) 화면
class SleepPredictionScreen extends StatelessWidget {
  const SleepPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('수면 예측'),
        backgroundColor: AppTheme.background,
      ),
      body: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final profile = recordService.profile;
          if (profile == null) {
            return const Center(child: Text('프로필을 먼저 설정해주세요'));
          }

          final months = profile.ageInMonths;
          final analysis = _analyzeSleepPatterns(recordService);
          final recommendation = _getAgeRecommendation(months);
          final nextNap = _predictNextNap(recordService, months);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // SweetSpot 카드
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B68EE).withOpacity(0.15),
                      const Color(0xFF9B59B6).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      nextNap != null
                          ? '다음 수면 추천 시간'
                          : '수면 데이터를 수집 중이에요',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    if (nextNap != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('a h:mm', 'ko').format(nextNap),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (_) {
                        final diff = nextNap.difference(DateTime.now());
                        if (diff.isNegative) {
                          return Text('지금 재워도 좋아요!',
                            style: TextStyle(fontSize: 14, color: AppTheme.primary,
                              fontWeight: FontWeight.w600));
                        }
                        return Text(
                          '약 ${diff.inHours > 0 ? "${diff.inHours}시간 " : ""}${diff.inMinutes.remainder(60)}분 후',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        );
                      }),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text('3일 이상 수면 기록이 쌓이면\n최적 수면 시간을 예측해드려요',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 월령별 권장 수면
              Text('월령별 수면 가이드', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${profile.name} (${months}개월)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _InfoTile(label: '하루 총 수면', value: recommendation.totalSleep),
                    _InfoTile(label: '밤잠', value: recommendation.nightSleep),
                    _InfoTile(label: '낮잠 횟수', value: recommendation.naps),
                    _InfoTile(label: '깨어있는 시간', value: recommendation.wakeWindow),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 최근 수면 패턴 분석
              if (analysis.isNotEmpty) ...[
                Text('최근 수면 패턴', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 12),
                ...analysis.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(item.value, style: TextStyle(fontSize: 12,
                              color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              // 수면 팁
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B68EE).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7B68EE).withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('수면 팁', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ]),
                    const SizedBox(height: 8),
                    ...recommendation.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $tip', style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  DateTime? _predictNextNap(RecordService rs, int months) {
    final now = DateTime.now();
    final recentSleep = rs.records
        .where((r) => r.category == RecordCategory.sleep &&
            r.sleepStatus == SleepStatus.end &&
            now.difference(r.timestamp).inDays < 7)
        .toList();

    if (recentSleep.length < 3) return null;

    // 마지막 깨어남 시간
    final lastWake = recentSleep.first.timestamp;

    // 평균 깨어있는 시간 계산
    int totalWakeMinutes = 0;
    int count = 0;
    for (int i = 0; i < recentSleep.length - 1; i++) {
      final woke = recentSleep[i].timestamp;
      // 이 깨어남 이후 다음 잠듦 찾기
      final nextSleepStart = rs.records.where((r) =>
          r.category == RecordCategory.sleep &&
          r.sleepStatus == SleepStatus.start &&
          r.timestamp.isAfter(woke) &&
          r.timestamp.difference(woke).inHours < 8).toList();
      if (nextSleepStart.isNotEmpty) {
        totalWakeMinutes += nextSleepStart.last.timestamp.difference(woke).inMinutes;
        count++;
      }
    }

    if (count == 0) {
      // 월령 기반 기본 wake window 사용
      final defaultWake = _getDefaultWakeWindow(months);
      return lastWake.add(Duration(minutes: defaultWake));
    }

    final avgWake = totalWakeMinutes ~/ count;
    return lastWake.add(Duration(minutes: avgWake));
  }

  int _getDefaultWakeWindow(int months) {
    if (months < 3) return 60;
    if (months < 5) return 105;
    if (months < 7) return 150;
    if (months < 10) return 180;
    if (months < 15) return 210;
    return 300;
  }

  List<_AnalysisItem> _analyzeSleepPatterns(RecordService rs) {
    final now = DateTime.now();
    final weekRecords = rs.records
        .where((r) => r.category == RecordCategory.sleep &&
            now.difference(r.timestamp).inDays < 7)
        .toList();

    if (weekRecords.isEmpty) return [];

    final items = <_AnalysisItem>[];

    // 평균 수면 횟수
    final dayGroups = <String, int>{};
    for (final r in weekRecords.where((r) => r.sleepStatus == SleepStatus.start)) {
      final key = '${r.timestamp.month}/${r.timestamp.day}';
      dayGroups[key] = (dayGroups[key] ?? 0) + 1;
    }
    if (dayGroups.isNotEmpty) {
      final avg = dayGroups.values.reduce((a, b) => a + b) / dayGroups.length;
      items.add(_AnalysisItem(emoji: '😴', title: '일 평균 수면 횟수',
        value: '${avg.toStringAsFixed(1)}회 (최근 7일)'));
    }

    // 평균 밤잠 시작 시간
    final nightStarts = weekRecords
        .where((r) => r.sleepStatus == SleepStatus.start && r.timestamp.hour >= 18)
        .map((r) => r.timestamp.hour * 60 + r.timestamp.minute)
        .toList();
    if (nightStarts.isNotEmpty) {
      final avgMin = nightStarts.reduce((a, b) => a + b) ~/ nightStarts.length;
      items.add(_AnalysisItem(emoji: '🌙', title: '평균 밤잠 시작',
        value: '${avgMin ~/ 60}시 ${avgMin % 60}분'));
    }

    // 평균 아침 기상
    final morningWakes = weekRecords
        .where((r) => r.sleepStatus == SleepStatus.end && r.timestamp.hour < 12)
        .map((r) => r.timestamp.hour * 60 + r.timestamp.minute)
        .toList();
    if (morningWakes.isNotEmpty) {
      final avgMin = morningWakes.reduce((a, b) => a + b) ~/ morningWakes.length;
      items.add(_AnalysisItem(emoji: '☀️', title: '평균 기상 시간',
        value: '${avgMin ~/ 60}시 ${avgMin % 60}분'));
    }

    return items;
  }

  _SleepRecommendation _getAgeRecommendation(int months) {
    if (months < 3) {
      return _SleepRecommendation(
        totalSleep: '14~17시간', nightSleep: '8~9시간', naps: '4~5회',
        wakeWindow: '45분~1시간',
        tips: ['신생아는 배고플 때 깨는 것이 정상이에요', '밤과 낮의 구분을 알려주세요 — 낮에는 밝게, 밤에는 어둡게',
          '수면 신호(하품, 눈 비비기)를 잘 관찰하세요']);
    } else if (months < 6) {
      return _SleepRecommendation(
        totalSleep: '12~15시간', nightSleep: '10~11시간', naps: '3~4회',
        wakeWindow: '1.5~2.5시간',
        tips: ['일정한 수면 루틴을 만들기 시작하세요', '잠자리 의식(목욕 → 자장가 → 불끄기)을 도입하세요',
          '배고프지 않은데 깨면 5분 정도 기다려보세요']);
    } else if (months < 12) {
      return _SleepRecommendation(
        totalSleep: '12~15시간', nightSleep: '10~12시간', naps: '2~3회',
        wakeWindow: '2~3.5시간',
        tips: ['낮잠 시간이 줄어드는 것은 정상이에요', '밤중 수유를 줄여가도 좋은 시기입니다',
          '분리 불안이 시작될 수 있어요 — 안정감을 주세요']);
    } else {
      return _SleepRecommendation(
        totalSleep: '11~14시간', nightSleep: '10~12시간', naps: '1~2회',
        wakeWindow: '3~5.5시간',
        tips: ['낮잠이 1회로 줄어들 수 있어요', '낮잠은 오후 3시 전에 끝내는 것이 좋아요',
          '충분한 신체 활동이 숙면에 도움이 됩니다']);
    }
  }
}

class _AnalysisItem {
  final String emoji;
  final String title;
  final String value;
  const _AnalysisItem({required this.emoji, required this.title, required this.value});
}

class _SleepRecommendation {
  final String totalSleep;
  final String nightSleep;
  final String naps;
  final String wakeWindow;
  final List<String> tips;
  const _SleepRecommendation({
    required this.totalSleep, required this.nightSleep,
    required this.naps, required this.wakeWindow, required this.tips});
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
