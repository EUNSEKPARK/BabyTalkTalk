import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 예방접종 스케줄 화면
class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({super.key});
  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('vaccination_completed') ?? [];
    setState(() => _completed.addAll(list));
  }

  Future<void> _toggle(String key) async {
    setState(() {
      if (_completed.contains(key)) {
        _completed.remove(key);
      } else {
        _completed.add(key);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vaccination_completed', _completed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<RecordService>().profile;
    final birthDate = profile?.birthDate ?? DateTime.now();
    final completedCount = _completed.length;
    final totalCount = _vaccineSchedule.fold<int>(0, (s, g) => s + g.items.length);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('예방접종 스케줄'),
        backgroundColor: AppTheme.background,
      ),
      body: Column(
        children: [
          // 진행률
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64, height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: totalCount > 0 ? completedCount / totalCount : 0,
                        strokeWidth: 6,
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                      Center(
                        child: Text(
                          '$completedCount/$totalCount',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('접종 완료율', style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${profile?.name ?? '아기'}의 접종 기록을 관리하세요',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 접종 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _vaccineSchedule.length,
              itemBuilder: (ctx, idx) {
                final group = _vaccineSchedule[idx];
                final targetDate = birthDate.add(Duration(days: group.targetDays));
                final isPast = DateTime.now().isAfter(targetDate);
                final groupCompleted = group.items
                    .every((item) => _completed.contains(item.key));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 시기 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: groupCompleted
                                  ? AppTheme.primary.withOpacity(0.15)
                                  : isPast
                                      ? AppTheme.error.withOpacity(0.1)
                                      : AppTheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              group.period,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: groupCompleted
                                    ? AppTheme.primary
                                    : isPast
                                        ? AppTheme.error
                                        : AppTheme.onSecondary,
                              ),
                            ),
                          ),
                          if (groupCompleted) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
                          ],
                        ],
                      ),
                    ),
                    // 개별 접종
                    ...group.items.map((item) {
                      final done = _completed.contains(item.key);
                      return Card(
                        color: done
                            ? AppTheme.primaryContainer.withOpacity(0.15)
                            : AppTheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: done,
                            onChanged: (_) => _toggle(item.key),
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500,
                              color: done ? AppTheme.textSecondary : AppTheme.textPrimary,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                            style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                          ),
                          trailing: item.required_
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('필수', style: TextStyle(
                                    fontSize: 10, color: AppTheme.error, fontWeight: FontWeight.w600)),
                                )
                              : Text('선택', style: TextStyle(
                                  fontSize: 10, color: AppTheme.textHint)),
                          contentPadding: const EdgeInsets.only(left: 4, right: 12),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 한국 국가예방접종 데이터 =====

class _VaccineGroup {
  final String period;
  final int targetDays; // 출생일로부터 일수
  final List<_VaccineItem> items;
  const _VaccineGroup({required this.period, required this.targetDays, required this.items});
}

class _VaccineItem {
  final String key;
  final String name;
  final String description;
  final bool required_;
  const _VaccineItem({required this.key, required this.name, required this.description, this.required_ = true});
}

final _vaccineSchedule = [
  _VaccineGroup(period: '출생 시', targetDays: 0, items: [
    _VaccineItem(key: 'bcg', name: 'BCG (피내용)', description: '결핵 예방'),
    _VaccineItem(key: 'hepb_1', name: 'B형간염 1차', description: 'B형간염 예방'),
  ]),
  _VaccineGroup(period: '1개월', targetDays: 30, items: [
    _VaccineItem(key: 'hepb_2', name: 'B형간염 2차', description: 'B형간염 예방'),
  ]),
  _VaccineGroup(period: '2개월', targetDays: 60, items: [
    _VaccineItem(key: 'dtap_1', name: 'DTaP 1차', description: '디프테리아·파상풍·백일해'),
    _VaccineItem(key: 'ipv_1', name: 'IPV 1차', description: '폴리오'),
    _VaccineItem(key: 'hib_1', name: 'Hib 1차', description: 'b형 헤모필루스 인플루엔자'),
    _VaccineItem(key: 'pcv_1', name: 'PCV 1차', description: '폐렴구균'),
    _VaccineItem(key: 'rotavirus_1', name: '로타바이러스 1차', description: '로타바이러스 위장관염', required_: false),
  ]),
  _VaccineGroup(period: '4개월', targetDays: 120, items: [
    _VaccineItem(key: 'dtap_2', name: 'DTaP 2차', description: '디프테리아·파상풍·백일해'),
    _VaccineItem(key: 'ipv_2', name: 'IPV 2차', description: '폴리오'),
    _VaccineItem(key: 'hib_2', name: 'Hib 2차', description: 'b형 헤모필루스 인플루엔자'),
    _VaccineItem(key: 'pcv_2', name: 'PCV 2차', description: '폐렴구균'),
    _VaccineItem(key: 'rotavirus_2', name: '로타바이러스 2차', description: '로타바이러스 위장관염', required_: false),
  ]),
  _VaccineGroup(period: '6개월', targetDays: 180, items: [
    _VaccineItem(key: 'dtap_3', name: 'DTaP 3차', description: '디프테리아·파상풍·백일해'),
    _VaccineItem(key: 'ipv_3', name: 'IPV 3차', description: '폴리오'),
    _VaccineItem(key: 'hib_3', name: 'Hib 3차', description: 'b형 헤모필루스 인플루엔자'),
    _VaccineItem(key: 'pcv_3', name: 'PCV 3차', description: '폐렴구균'),
    _VaccineItem(key: 'hepb_3', name: 'B형간염 3차', description: 'B형간염 예방'),
    _VaccineItem(key: 'flu_1', name: '인플루엔자 1차', description: '독감 예방 (매년)', required_: false),
  ]),
  _VaccineGroup(period: '12개월', targetDays: 365, items: [
    _VaccineItem(key: 'mmr_1', name: 'MMR 1차', description: '홍역·유행성이하선염·풍진'),
    _VaccineItem(key: 'varicella', name: '수두', description: '수두 예방'),
    _VaccineItem(key: 'hepa_1', name: 'A형간염 1차', description: 'A형간염 예방'),
    _VaccineItem(key: 'je_1', name: '일본뇌염(불활성화) 1차', description: '일본뇌염 예방'),
    _VaccineItem(key: 'je_2', name: '일본뇌염(불활성화) 2차', description: '일본뇌염 예방'),
    _VaccineItem(key: 'hib_4', name: 'Hib 4차', description: 'b형 헤모필루스 인플루엔자'),
    _VaccineItem(key: 'pcv_4', name: 'PCV 4차', description: '폐렴구균'),
  ]),
  _VaccineGroup(period: '15~18개월', targetDays: 450, items: [
    _VaccineItem(key: 'dtap_4', name: 'DTaP 4차', description: '디프테리아·파상풍·백일해'),
    _VaccineItem(key: 'hepa_2', name: 'A형간염 2차', description: 'A형간염 예방'),
  ]),
  _VaccineGroup(period: '24개월', targetDays: 730, items: [
    _VaccineItem(key: 'je_3', name: '일본뇌염(불활성화) 3차', description: '일본뇌염 예방'),
  ]),
  _VaccineGroup(period: '4~6세', targetDays: 1460, items: [
    _VaccineItem(key: 'dtap_5', name: 'DTaP 5차', description: '디프테리아·파상풍·백일해'),
    _VaccineItem(key: 'ipv_4', name: 'IPV 4차', description: '폴리오'),
    _VaccineItem(key: 'mmr_2', name: 'MMR 2차', description: '홍역·유행성이하선염·풍진'),
    _VaccineItem(key: 'je_4', name: '일본뇌염(불활성화) 4차', description: '일본뇌염 예방'),
  ]),
];
