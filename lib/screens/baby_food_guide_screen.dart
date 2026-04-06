import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 이유식 식단 가이드 화면
class BabyFoodGuideScreen extends StatefulWidget {
  const BabyFoodGuideScreen({super.key});
  @override
  State<BabyFoodGuideScreen> createState() => _BabyFoodGuideScreenState();
}

class _BabyFoodGuideScreenState extends State<BabyFoodGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 아기 월령에 맞는 탭 자동 선택
    final months = context.read<RecordService>().profile?.ageInMonths ?? 6;
    int initialTab = 0;
    if (months >= 12) initialTab = 3;
    else if (months >= 9) initialTab = 2;
    else if (months >= 7) initialTab = 1;
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('이유식 가이드'),
        backgroundColor: AppTheme.background,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '초기\n(5~6개월)'),
            Tab(text: '중기\n(7~8개월)'),
            Tab(text: '후기\n(9~11개월)'),
            Tab(text: '완료기\n(12개월~)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _stages.map((stage) => _StageView(stage: stage)).toList(),
      ),
    );
  }
}

class _StageView extends StatelessWidget {
  final _FoodStage stage;
  const _StageView({required this.stage});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 개요 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: stage.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: stage.color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(stage.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(stage.title, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 12),
              Text(stage.overview, style: TextStyle(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.restaurant, label: '횟수', value: stage.frequency),
              _InfoRow(icon: Icons.straighten, label: '양', value: stage.amount),
              _InfoRow(icon: Icons.texture, label: '질감', value: stage.texture),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 추천 식재료
        Text('추천 식재료', style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 12),

        ...stage.foodGroups.map((group) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(group.groupName, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.foods.map((food) => Chip(
                label: Text(food, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.surfaceContainer,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
        )),

        const SizedBox(height: 24),

        // 주의 식품
        if (stage.avoid.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.error.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Text('주의 식품', style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppTheme.error)),
                ]),
                const SizedBox(height: 8),
                ...stage.avoid.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: AppTheme.error)),
                      Expanded(child: Text(a, style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],

        // 알레르기 팁
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.onSecondary),
                const SizedBox(width: 8),
                Text('알레르기 팁', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppTheme.onSecondary)),
              ]),
              const SizedBox(height: 8),
              Text(
                '새로운 식재료는 한 번에 하나씩, 3일 간격으로 시도하세요. 발진, 구토, 설사 등의 반응이 나타나면 즉시 중단하고 소아과를 방문하세요.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Expanded(child: Text(value, style: TextStyle(
            fontSize: 12, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }
}

// ===== 데이터 =====

class _FoodGroup {
  final String groupName;
  final List<String> foods;
  const _FoodGroup({required this.groupName, required this.foods});
}

class _FoodStage {
  final String title;
  final String emoji;
  final Color color;
  final String overview;
  final String frequency;
  final String amount;
  final String texture;
  final List<_FoodGroup> foodGroups;
  final List<String> avoid;
  const _FoodStage({
    required this.title, required this.emoji, required this.color,
    required this.overview, required this.frequency, required this.amount,
    required this.texture, required this.foodGroups, required this.avoid,
  });
}

final _stages = [
  _FoodStage(
    title: '초기 이유식', emoji: '🥄', color: Color(0xFFA5D6A7),
    overview: '모유/분유 외 처음 음식을 접하는 시기입니다. 쌀미음부터 시작해서 천천히 다양한 맛을 알려주세요.',
    frequency: '1일 1회', amount: '1~2큰술부터 시작', texture: '고운 미음/퓨레',
    foodGroups: [
      _FoodGroup(groupName: '곡류', foods: ['쌀', '찹쌀', '오트밀']),
      _FoodGroup(groupName: '채소', foods: ['감자', '고구마', '애호박', '브로콜리', '당근']),
      _FoodGroup(groupName: '과일', foods: ['사과', '배', '바나나', '아보카도']),
    ],
    avoid: ['꿀 (12개월 전 절대 금지 — 보툴리누스 중독 위험)', '소금, 설탕 등 조미료', '우유 (음료로 사용 금지, 조리용만 소량 가능)', '견과류 (질식 및 알레르기 위험)'],
  ),
  _FoodStage(
    title: '중기 이유식', emoji: '🥣', color: Color(0xFF81D4FA),
    overview: '질감을 점차 높이고 다양한 식재료를 시도합니다. 단백질 식품을 본격적으로 도입하세요.',
    frequency: '1일 2회', amount: '30~80g씩', texture: '으깬 죽 / 알갱이가 있는 퓨레',
    foodGroups: [
      _FoodGroup(groupName: '곡류', foods: ['쌀', '찹쌀', '오트밀', '보리', '현미']),
      _FoodGroup(groupName: '채소', foods: ['감자', '고구마', '애호박', '브로콜리', '당근', '시금치', '비트', '양배추', '콩나물']),
      _FoodGroup(groupName: '과일', foods: ['사과', '배', '바나나', '자두', '수박', '참외']),
      _FoodGroup(groupName: '단백질', foods: ['소고기', '닭가슴살', '달걀 노른자', '두부', '흰살생선']),
    ],
    avoid: ['꿀', '조미료 (소금, 설탕)', '날생선, 조개류', '가공식품 (소시지, 햄 등)'],
  ),
  _FoodStage(
    title: '후기 이유식', emoji: '🍲', color: Color(0xFFFFE082),
    overview: '잇몸으로 씹을 수 있는 정도의 질감으로 올립니다. 세 끼를 규칙적으로 먹는 습관을 만들어주세요.',
    frequency: '1일 3회', amount: '80~120g씩', texture: '잘게 다진 무른밥 / 부드러운 덩어리',
    foodGroups: [
      _FoodGroup(groupName: '곡류', foods: ['무른밥', '국수', '식빵', '팬케이크']),
      _FoodGroup(groupName: '채소', foods: ['감자', '고구마', '애호박', '브로콜리', '당근', '시금치', '파프리카', '양파', '무', '미역']),
      _FoodGroup(groupName: '과일', foods: ['사과', '배', '바나나', '딸기', '블루베리', '키위', '포도']),
      _FoodGroup(groupName: '단백질', foods: ['소고기', '돼지고기', '닭고기', '달걀 전체', '두부', '흰살생선', '연어', '치즈', '요거트']),
    ],
    avoid: ['꿀 (12개월 전)', '딱딱한 견과류 (으깨서 소량 가능)', '자극적인 양념'],
  ),
  _FoodStage(
    title: '완료기 이유식', emoji: '🍚', color: Color(0xFFFFAB91),
    overview: '성인 식사와 유사한 형태로 전환합니다. 다양한 식감과 맛을 경험하게 해주세요.',
    frequency: '1일 3회 + 간식 1~2회', amount: '밥 1/3~1/2공기씩', texture: '진밥 / 부드러운 반찬',
    foodGroups: [
      _FoodGroup(groupName: '곡류', foods: ['진밥', '국수', '빵', '떡', '감자', '고구마']),
      _FoodGroup(groupName: '채소', foods: ['거의 모든 채소 가능', '나물류', '해조류']),
      _FoodGroup(groupName: '과일', foods: ['대부분의 과일 가능', '말린 과일 (소량)']),
      _FoodGroup(groupName: '단백질', foods: ['소고기', '돼지고기', '닭고기', '생선류', '달걀', '두부', '치즈', '우유 (음료 가능)']),
      _FoodGroup(groupName: '간식', foods: ['고구마 스틱', '과일', '떡', '요거트', '치즈']),
    ],
    avoid: ['꿀 (12개월 이후 가능)', '카페인 (초콜릿, 차)', '전체 견과류 (질식 주의, 분쇄 후 가능)'],
  ),
];
