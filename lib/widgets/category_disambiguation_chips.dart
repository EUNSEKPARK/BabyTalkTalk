import 'package:flutter/material.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// NLP 객관식 카테고리 선택 (채팅·바텀시트 공용)
class CategoryDisambiguationChips extends StatelessWidget {
  const CategoryDisambiguationChips({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<CategoryDisambiguationOption> options;
  final void Function(RecordCategory category) onSelected;

  static String _emoji(RecordCategory c) {
    switch (c) {
      case RecordCategory.feeding:
        return '🍼';
      case RecordCategory.babyfood:
        return '🥣';
      case RecordCategory.snack:
        return '🍪';
      case RecordCategory.sleep:
        return '😴';
      case RecordCategory.diaper:
        return '🧷';
      case RecordCategory.health:
        return '🌡️';
      case RecordCategory.milestone:
        return '⭐';
      case RecordCategory.other:
        return '📝';
    }
  }

  static String _label(RecordCategory c) {
    switch (c) {
      case RecordCategory.feeding:
        return '수유';
      case RecordCategory.babyfood:
        return '이유식';
      case RecordCategory.snack:
        return '간식';
      case RecordCategory.sleep:
        return '수면';
      case RecordCategory.diaper:
        return '기저귀';
      case RecordCategory.health:
        return '건강';
      case RecordCategory.milestone:
        return '성장';
      case RecordCategory.other:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        return Material(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => onSelected(o.category),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_emoji(o.category), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    _label(o.category),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
