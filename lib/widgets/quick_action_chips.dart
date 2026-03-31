import 'package:flutter/material.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 빠른 기록을 위한 액션 칩 목록 (미드저니 아이콘 버전)
class QuickActionChips extends StatelessWidget {
  final Function(String text) onAction;

  const QuickActionChips({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('분유', '분유 먹었어', AppTheme.feedingBg, AppTheme.feedingColor, 'assets/images/icon_bottle.png'),
      _QuickAction('모유', '모유 수유했어', AppTheme.feedingBg, AppTheme.feedingColor, 'assets/images/icon_breastfeeding.png'),
      _QuickAction('이유식', '이유식 먹었어', AppTheme.babyfoodBg, AppTheme.babyfoodColor, 'assets/images/icon_babyfood.png'),
      _QuickAction('간식', '간식 먹었어', AppTheme.snackBg, AppTheme.snackColor, 'assets/images/icon_snack.png'),
      _QuickAction('잠듦', '아기 잠들었어', AppTheme.sleepBg, AppTheme.sleepColor, 'assets/images/icon_sleep.png'),
      _QuickAction('기저귀', '기저귀 갈았어', AppTheme.diaperBg, AppTheme.diaperColor, 'assets/images/icon_diaper.png'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () => onAction(action.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: action.bgColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: action.accentColor.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.accentColor.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      action.iconPath,
                      width: 22,
                      height: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final String text;
  final Color bgColor;
  final Color accentColor;
  final String iconPath;

  const _QuickAction(this.label, this.text, this.bgColor, this.accentColor, this.iconPath);
}
