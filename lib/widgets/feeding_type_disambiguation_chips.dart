import 'package:flutter/material.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// '밥 120' 등 분유 vs 이유식 객관식 선택
class FeedingTypeDisambiguationChips extends StatelessWidget {
  const FeedingTypeDisambiguationChips({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<FeedingType> options;
  final void Function(FeedingType type) onSelected;

  static String _emoji(FeedingType t) {
    switch (t) {
      case FeedingType.formula:
        return '🍼';
      case FeedingType.breast:
        return '🤱';
      default:
        return '🍼';
    }
  }

  static String _label(FeedingType t) {
    switch (t) {
      case FeedingType.formula:
        return '분유 (젖병·ml)';
      case FeedingType.breast:
        return '모유';
      default:
        return '분유';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in options)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(t),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_emoji(t), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      _label(t),
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
          ),
      ],
    );
  }
}
