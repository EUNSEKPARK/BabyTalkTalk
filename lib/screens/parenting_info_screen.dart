import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';

class ParentingInfoScreen extends StatelessWidget {
  const ParentingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final profile = recordService.profile;
    final ageInMonths = profile?.ageInMonths ?? 0;
    final tips = _getTipsForAge(ageInMonths);

    return Scaffold(
      appBar: AppBar(
        title: const Text('육아 정보'),
        backgroundColor: AppTheme.background,
      ),
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null) ...[
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name}을(를) 위한 맞춤 정보',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.ageText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          ...tips.map((tip) => Column(
            children: [
              _TipCard(
                icon: tip['icon']!,
                title: tip['title']!,
                summary: tip['summary']!,
                details: tip['details']!,
              ),
              const SizedBox(height: 16),
            ],
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Map<String, String>> _getTipsForAge(int ageInMonths) {
    if (ageInMonths < 3) {
      return [
        {
          'icon': '🍼',
          'title': '수유 가이드',
          'summary': '신생아~3개월 수유 방법',
          'details': '• 2-3시간마다 수유가 필요합니다\n• 양쪽 유방을 고르게 수유하세요\n• 수유 후 트림을 꼭 시켜주세요\n• 아기의 입이 유두 전체를 감싸도록 합니다',
        },
        {
          'icon': '😴',
          'title': '수면 교육',
          'summary': '신생아 수면 패턴 이해하기',
          'details': '• 신생아는 하루 16-20시간 자야 합니다\n• 낮과 밤의 구분을 천천히 가르칩니다\n• 조용하고 어두운 환경을 만들어주세요\n• 안전한 수면 환경을 유지하세요',
        },
        {
          'icon': '🏥',
          'title': '예방접종 일정',
          'summary': '출생 후 필수 예방접종',
          'details': '• 출생 직후: B형간염, BCG\n• 1개월: B형간염 2차\n• 2개월: 종합백신, 폐렴구균\n• 보건소에서 무료 예방접종을 받을 수 있습니다',
        },
      ];
    } else if (ageInMonths < 6) {
      return [
        {
          'icon': '🍼',
          'title': '수유 가이드',
          'summary': '3-6개월 아기 수유 패턴',
          'details': '• 4시간 간격으로 수유하는 패턴이 생깁니다\n• 아기가 손을 입에 넣으면 수유 신호입니다\n• 모유 수유는 계속 권장됩니다\n• 이유식 준비를 시작하세요',
        },
        {
          'icon': '😴',
          'title': '수면 교육',
          'summary': '낮 수면 일정 정하기',
          'details': '• 낮에 2-3회 낮잠 시간을 정합니다\n• 밤에 더 길게 자는 패턴이 생깁니다\n• 아기가 스스로 자는 법을 배워야 합니다\n• 안전한 수면 환경을 유지하세요',
        },
        {
          'icon': '🥄',
          'title': '이유식 시작',
          'summary': '5-6개월 이유식 준비',
          'details': '• 아기가 관심 보일 때 시작합니다\n• 쌀미음부터 시작하는 것이 좋습니다\n• 한 가지씩만 3-5일 간격으로 소개합니다\n• 알레르기 반응을 관찰하세요',
        },
      ];
    } else if (ageInMonths < 9) {
      return [
        {
          'icon': '🍼',
          'title': '혼합 수유 가이드',
          'summary': '6-9개월 혼합 수유',
          'details': '• 이유식과 함께 모유/분유를 계속합니다\n• 하루 3-4회 이유식을 줍니다\n• 모유는 하루 2-3회 수유합니다\n• 수유 시간과 양을 기록하세요',
        },
        {
          'icon': '😴',
          'title': '수면 루틴',
          'summary': '일관된 수면 루틴 만들기',
          'details': '• 낮잠은 2회로 줄어듭니다\n• 밤에는 6-8시간 연속 수면합니다\n• 잠자리 의식을 만드세요 (책 읽기, 노래 부르기)\n• 아기가 스스로 자게 하는 연습을 합니다',
        },
        {
          'icon': '🥄',
          'title': '이유식 다양화',
          'summary': '단백질과 철분 풍부한 음식',
          'details': '• 이제 계란, 생선, 육류를 소개합니다\n• 곡물, 채소, 과일을 다양하게 줍니다\n• 아기의 반응을 잘 관찰하세요\n• 한 끼에 여러 식재료를 섞기 시작합니다',
        },
      ];
    } else {
      return [
        {
          'icon': '🍼',
          'title': '이유식 중심 식사',
          'summary': '9-12개월 이유식 중심',
          'details': '• 하루 3회 정규식을 먹습니다\n• 모유/분유는 1-2회 정도 줍니다\n• 손으로 집어먹는 핑거푸드를 줍니다\n• 아기가 먹는 것에 관심을 보입니다',
        },
        {
          'icon': '😴',
          'title': '수면 패턴',
          'summary': '일관된 수면 시간표',
          'details': '• 밤에는 10-12시간 연속 수면합니다\n• 낮잠은 1-2회입니다\n• 분리불안이 생길 수 있으므로 안심을 줍니다\n• 일정한 취침 시간을 유지하세요',
        },
        {
          'icon': '🏥',
          'title': '예방접종 일정',
          'summary': '12개월 이후 예방접종',
          'details': '• 12개월: MMR, 수두 예방접종\n• 18개월: 4차 종합백신, 폐렴구균 추가\n• 정기적인 건강검진을 하세요\n• 소아과 의사와 상담하세요',
        },
      ];
    }
  }
}

class _TipCard extends StatefulWidget {
  final String icon;
  final String title;
  final String summary;
  final String details;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.details,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          title: Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.summary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppTheme.primary,
          ),
          collapsedTextColor: AppTheme.onSurface,
          textColor: AppTheme.onSurface,
          iconColor: AppTheme.primary,
          backgroundColor: AppTheme.surfaceContainerHigh.withOpacity(0.5),
          collapsedBackgroundColor: AppTheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppTheme.surfaceContainerHigh),
                  const SizedBox(height: 12),
                  Text(
                    widget.details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
