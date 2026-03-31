import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/constants/growth_diary_assets.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 성장 일기 카드용 썸네일 (앱 에셋 또는 업로드 사진)
class GrowthDiaryThumbnail extends StatelessWidget {
  const GrowthDiaryThumbnail({
    super.key,
    required this.date,
    this.width = 140,
    this.height = 175,
    this.borderRadius = 16,
    this.showCameraHint = true,
    this.onTap,
  });

  final DateTime date;
  final double width;
  final double height;
  final double borderRadius;
  final bool showCameraHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordService>(
      builder: (context, recordService, _) {
        final cover = recordService.diaryCoverForDate(date);
        final radius = BorderRadius.circular(borderRadius);

        Widget imageLayer;
        if (cover.filePath != null) {
          final fallbackAsset =
              kGrowthDiaryCoverAssets[defaultDiaryCoverAssetIndex(date)];
          imageLayer = Image.file(
            File(cover.filePath!),
            fit: BoxFit.cover,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => Image.asset(
              fallbackAsset,
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
          );
        } else if (cover.asset != null) {
          imageLayer = Image.asset(
            cover.asset!,
            fit: BoxFit.cover,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        } else {
          imageLayer = _placeholder();
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              width: width,
              height: height,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: radius,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: imageLayer),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  if (showCameraHint && onTap != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppTheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.auto_stories_outlined,
          color: AppTheme.onSurfaceVariant,
          size: 40,
        ),
      ),
    );
  }
}
