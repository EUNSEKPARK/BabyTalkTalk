import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chat_baby_time/services/nlp_analytics_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// NLP 분석 대시보드 (개발자/관리자용)
///
/// 설정 화면에서 숨겨진 진입점으로 접근.
/// 수집된 데이터를 요약 통계와 상세 로그로 보여줌.
class NlpAnalyticsScreen extends StatelessWidget {
  const NlpAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('NLP 분석 대시보드'),
        backgroundColor: AppTheme.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'CSV 내보내기',
            onPressed: () => _exportData(context, 'csv'),
          ),
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: 'JSON 내보내기',
            onPressed: () => _exportData(context, 'json'),
          ),
        ],
      ),
      body: Consumer<NlpAnalyticsService>(
        builder: (context, analytics, _) {
          if (analytics.totalLogs == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/empty_stats.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('수집된 데이터가 없습니다',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('채팅을 사용하면 NLP 분석 데이터가\n여기에 표시됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 핵심 지표 카드 ──
              _buildMetricsRow(analytics),
              const SizedBox(height: 16),

              // ── 카테고리별 정확도 ──
              _buildSectionTitle('카테고리별 정확도'),
              const SizedBox(height: 8),
              _buildCategoryAccuracy(analytics),
              const SizedBox(height: 20),

              // ── 시간대별 사용량 ──
              _buildSectionTitle('시간대별 사용량'),
              const SizedBox(height: 8),
              _buildHourlyChart(analytics),
              const SizedBox(height: 20),

              // ── 자주 쓰는 표현 ──
              _buildSectionTitle('자주 쓰는 표현 Top 10'),
              const SizedBox(height: 8),
              _buildTopExpressions(analytics),
              const SizedBox(height: 20),

              // ── 오인식 목록 (핵심 개선 포인트) ──
              _buildSectionTitle('오인식 / 수정된 입력 (개선 우선순위)'),
              const SizedBox(height: 8),
              _buildCorrectedList(analytics),
              const SizedBox(height: 20),

              // ── 취소된 입력 ──
              _buildSectionTitle('취소된 입력 (인식 실패)'),
              const SizedBox(height: 8),
              _buildCancelledList(analytics),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // ── 핵심 지표 ──

  Widget _buildMetricsRow(NlpAnalyticsService analytics) {
    return Row(
      children: [
        _buildMetricCard('총 로그', '${analytics.totalLogs}', Icons.list_alt, Colors.blue),
        const SizedBox(width: 8),
        _buildMetricCard(
          '자동저장율',
          '${(analytics.autoSaveRate * 100).toStringAsFixed(0)}%',
          Icons.flash_on,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          '수정율',
          '${(analytics.correctionRate * 100).toStringAsFixed(1)}%',
          Icons.edit,
          analytics.correctionRate > 0.1 ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          '평균 신뢰도',
          '${(analytics.avgConfidence * 100).toStringAsFixed(0)}%',
          Icons.speed,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── 카테고리별 정확도 ──

  Widget _buildCategoryAccuracy(NlpAnalyticsService analytics) {
    final acc = analytics.categoryAccuracy;
    final labels = {'feeding': '수유 🍼', 'sleep': '수면 😴', 'diaper': '기저귀 🧷', 'health': '건강 🌡️'};

    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: labels.entries.map((e) {
            final rate = acc[e.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(e.value, style: const TextStyle(fontSize: 13))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rate,
                        backgroundColor: Colors.grey[200],
                        color: rate >= 0.9 ? Colors.green : rate >= 0.7 ? Colors.orange : Colors.red,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${(rate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 시간대별 사용량 ──

  Widget _buildHourlyChart(NlpAnalyticsService analytics) {
    final hourly = analytics.hourlyUsage;
    final maxCount = hourly.values.isNotEmpty ? hourly.values.reduce((a, b) => a > b ? a : b) : 1;

    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (hour) {
              final count = hourly[hour] ?? 0;
              final height = maxCount > 0 ? (count / maxCount) * 80 : 0.0;
              final isActive = count > 0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isActive)
                      Text('$count', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    Container(
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary.withOpacity(0.7) : Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hour % 6 == 0)
                      Text('${hour}시', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── 자주 쓰는 표현 ──

  Widget _buildTopExpressions(NlpAnalyticsService analytics) {
    final top = analytics.topExpressions(limit: 10);
    if (top.isEmpty) return const Text('데이터 없음', style: TextStyle(color: Colors.grey));

    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: top.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final expr = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('$idx.', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  Expanded(child: Text('"${expr.key}"', style: const TextStyle(fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${expr.value}회', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 오인식 목록 ──

  Widget _buildCorrectedList(NlpAnalyticsService analytics) {
    final corrected = analytics.correctedLogs;
    if (corrected.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('오인식 없음! NLP가 잘 작동하고 있어요', style: TextStyle(fontSize: 13, color: Colors.green)),
          ],
        ),
      );
    }

    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: corrected.take(20).map((log) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit, size: 14, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('"${log.rawInput}"', style: const TextStyle(fontSize: 13)),
                        Text(
                          '인식: ${log.detectedCategory} → 수정: ${log.correctedCategory}  (신뢰도: ${(log.confidence * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 취소된 목록 ──

  Widget _buildCancelledList(NlpAnalyticsService analytics) {
    final cancelled = analytics.cancelledLogs;
    if (cancelled.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('취소 없음!', style: TextStyle(fontSize: 13, color: Colors.green)),
          ],
        ),
      );
    }

    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: cancelled.take(20).map((log) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.cancel, size: 14, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('"${log.rawInput}"', style: const TextStyle(fontSize: 13)),
                        Text(
                          '인식: ${log.detectedCategory} (${(log.confidence * 100).toStringAsFixed(0)}%) — 사용자가 취소',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 헬퍼 ──

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
    );
  }

  Future<void> _exportData(BuildContext context, String format) async {
    final analytics = context.read<NlpAnalyticsService>();
    final String content;
    final String fileName;

    if (format == 'csv') {
      content = await analytics.exportToCsv();
      fileName = 'nlp_analytics_${DateTime.now().millisecondsSinceEpoch}.csv';
    } else {
      content = await analytics.exportToJson();
      fileName = 'nlp_analytics_${DateTime.now().millisecondsSinceEpoch}.json';
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: 'NLP 분석 데이터');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
  }
}
