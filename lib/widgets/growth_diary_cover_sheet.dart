import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:chat_baby_time/constants/growth_diary_assets.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 성장 일기 날짜 카드 — 사진 업로드 / 앱 이미지 선택 / 기본으로
Future<void> showGrowthDiaryCoverSheet(
  BuildContext context,
  RecordService recordService,
  DateTime date,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              DateFormat('M월 d일', 'ko_KR').format(date),
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '일기 표지',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 사진 선택'),
              subtitle: const Text('기기에 있는 사진을 이 날짜 표지로 저장해요'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: false,
                  withData: false,
                );
                if (result == null || result.files.isEmpty) return;
                final path = result.files.single.path;
                if (path == null) return;
                final ok = await recordService.setDiaryCoverFromPickedFile(date, path);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(recordService.lastError ?? '사진을 저장하지 못했어요'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              '앱 안 이미지',
              style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kGrowthDiaryCoverAssets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (c, i) {
                  final path = kGrowthDiaryCoverAssets[i];
                  return Material(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await recordService.setDiaryCoverAsset(date, i);
                      },
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('날짜 기본 이미지로'),
              subtitle: const Text('업로드·선택을 취소하고 자동 표지로 돌려요'),
              onTap: () async {
                Navigator.pop(ctx);
                await recordService.clearDiaryCoverToDefault(date);
              },
            ),
          ],
        ),
      );
    },
  );
}
