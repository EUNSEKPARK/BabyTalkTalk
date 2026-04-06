import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// PDF 성장 리포트 내보내기 화면
class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({super.key});
  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  bool _isGenerating = false;
  String _period = '1week'; // 1week, 1month, all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('성장 리포트 PDF'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 설명 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('📄', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text('성장 리포트', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '아기의 성장 기록을 PDF로 내보내요.\n소아과 방문 시 의사에게 보여줄 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 기간 선택
          Text('기간 선택', style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('최근 1주'),
                selected: _period == '1week',
                selectedColor: AppTheme.primary.withOpacity(0.2),
                onSelected: (s) { if (s) setState(() => _period = '1week'); },
              ),
              ChoiceChip(
                label: const Text('최근 1개월'),
                selected: _period == '1month',
                selectedColor: AppTheme.primary.withOpacity(0.2),
                onSelected: (s) { if (s) setState(() => _period = '1month'); },
              ),
              ChoiceChip(
                label: const Text('전체 기록'),
                selected: _period == 'all',
                selectedColor: AppTheme.primary.withOpacity(0.2),
                onSelected: (s) { if (s) setState(() => _period = 'all'); },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 리포트 내용 미리보기
          Consumer<RecordService>(
            builder: (context, rs, _) {
              final profile = rs.profile;
              final records = _getFilteredRecords(rs);
              final measurements = rs.growthMeasurements;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('리포트에 포함될 내용', style: TextStyle(fontSize: 16,
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
                        _InfoLine(icon: Icons.child_care, text: '아기 프로필: ${profile?.name ?? "미설정"} (${profile?.ageText ?? ""})'),
                        const SizedBox(height: 8),
                        _InfoLine(icon: Icons.straighten, text: '성장 측정 기록: ${measurements.length}회'),
                        const SizedBox(height: 8),
                        _InfoLine(icon: Icons.restaurant, text: '수유 기록: ${records.where((r) => r.category == RecordCategory.feeding).length}건'),
                        const SizedBox(height: 8),
                        _InfoLine(icon: Icons.bedtime, text: '수면 기록: ${records.where((r) => r.category == RecordCategory.sleep).length}건'),
                        const SizedBox(height: 8),
                        _InfoLine(icon: Icons.baby_changing_station, text: '기저귀 기록: ${records.where((r) => r.category == RecordCategory.diaper).length}건'),
                        const SizedBox(height: 8),
                        _InfoLine(icon: Icons.monitor_heart, text: '건강 기록: ${records.where((r) => r.category == RecordCategory.health).length}건'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PDF 생성 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : () => _generateAndShare(rs),
                      icon: _isGenerating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(_isGenerating ? '생성 중...' : 'PDF 생성 및 공유'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<BabyRecord> _getFilteredRecords(RecordService rs) {
    final now = DateTime.now();
    final allRecords = rs.records;
    switch (_period) {
      case '1week':
        return allRecords.where((r) => now.difference(r.timestamp).inDays < 7).toList();
      case '1month':
        return allRecords.where((r) => now.difference(r.timestamp).inDays < 30).toList();
      default:
        return allRecords;
    }
  }

  Future<void> _generateAndShare(RecordService rs) async {
    setState(() => _isGenerating = true);

    try {
      final profile = rs.profile;
      final records = _getFilteredRecords(rs);
      final measurements = rs.growthMeasurements;

      final pdf = pw.Document();
      final koreanFont = await PdfGoogleFonts.notoSansKRRegular();
      final koreanFontBold = await PdfGoogleFonts.notoSansKRBold();

      final periodLabel = _period == '1week' ? '최근 1주' : _period == '1month' ? '최근 1개월' : '전체 기록';
      final dateStr = DateFormat('yyyy.MM.dd').format(DateTime.now());

      // 표지
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: koreanFont, bold: koreanFontBold),
        build: (ctx) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('아기톡톡', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#7C4DFF'))),
              pw.SizedBox(height: 12),
              pw.Text('성장 리포트', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#7C4DFF')),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(children: [
                  pw.Text('이름: ${profile?.name ?? "-"}', style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 4),
                  pw.Text('나이: ${profile?.ageText ?? "-"}', style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 4),
                  pw.Text('생년월일: ${profile?.birthDate != null ? DateFormat('yyyy.MM.dd').format(profile!.birthDate) : "-"}',
                    style: const pw.TextStyle(fontSize: 14)),
                ]),
              ),
              pw.SizedBox(height: 16),
              pw.Text('기간: $periodLabel', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 4),
              pw.Text('생성일: $dateStr', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ],
          ),
        ),
      ));

      // 성장 측정 페이지
      if (measurements.isNotEmpty) {
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: koreanFont, bold: koreanFontBold),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('성장 측정 기록', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#7C4DFF'))),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#EDE7F6')),
                cellHeight: 28,
                headers: ['날짜', '키 (cm)', '몸무게 (kg)', '두위 (cm)'],
                data: measurements.take(30).map((m) {
                  final date = m['date'] as DateTime;
                  final headCirc = m['headCircCm'];
                  return [
                    DateFormat('yyyy.MM.dd').format(date),
                    '${m['heightCm']}',
                    '${m['weightKg']}',
                    headCirc != null ? '$headCirc' : '-',
                  ];
                }).toList(),
              ),
            ],
          ),
        ));
      }

      // 기록 요약 페이지
      final feedingRecords = records.where((r) => r.category == RecordCategory.feeding).toList();
      final sleepRecords = records.where((r) => r.category == RecordCategory.sleep).toList();
      final diaperRecords = records.where((r) => r.category == RecordCategory.diaper).toList();
      final healthRecords = records.where((r) => r.category == RecordCategory.health).toList();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: koreanFont, bold: koreanFontBold),
        build: (ctx) => [
          pw.Text('기록 요약', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#7C4DFF'))),
          pw.SizedBox(height: 16),

          // 수유 요약
          _buildPdfSection('수유', '${feedingRecords.length}건', [
            if (feedingRecords.isNotEmpty) ...[
              '모유: ${feedingRecords.where((r) => r.feedingType == FeedingType.breast).length}건',
              '분유: ${feedingRecords.where((r) => r.feedingType == FeedingType.formula).length}건',
              () {
                final amounts = feedingRecords.where((r) => r.amountMl != null).map((r) => r.amountMl!);
                if (amounts.isEmpty) return '평균 수유량: -';
                final avg = amounts.reduce((a, b) => a + b) / amounts.length;
                return '평균 수유량: ${avg.toStringAsFixed(0)}ml';
              }(),
            ],
          ]),
          pw.SizedBox(height: 12),

          // 수면 요약
          _buildPdfSection('수면', '${sleepRecords.length}건', [
            '잠듦: ${sleepRecords.where((r) => r.sleepStatus == SleepStatus.start).length}건',
            '깨어남: ${sleepRecords.where((r) => r.sleepStatus == SleepStatus.end).length}건',
          ]),
          pw.SizedBox(height: 12),

          // 기저귀 요약
          _buildPdfSection('기저귀', '${diaperRecords.length}건', [
            '소변: ${diaperRecords.where((r) => r.diaperType == DiaperType.pee).length}건',
            '대변: ${diaperRecords.where((r) => r.diaperType == DiaperType.poop).length}건',
            '혼합: ${diaperRecords.where((r) => r.diaperType == DiaperType.both).length}건',
          ]),
          pw.SizedBox(height: 12),

          // 건강 요약
          if (healthRecords.isNotEmpty)
            _buildPdfSection('건강', '${healthRecords.length}건', [
              ...healthRecords.take(10).map((r) {
                final parts = <String>[];
                if (r.temperature != null) parts.add('${r.temperature}°C');
                if (r.medicine != null) parts.add(r.medicine!);
                return '${DateFormat('M/d HH:mm').format(r.timestamp)}: ${parts.join(', ')}';
              }),
            ]),

          pw.SizedBox(height: 24),

          // 일별 기록 상세
          pw.Text('일별 기록 상세', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#7C4DFF'))),
          pw.SizedBox(height: 12),

          // Group by date
          ..._groupRecordsByDate(records).entries.take(14).map((entry) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: PdfColor.fromHex('#EDE7F6'),
                  child: pw.Text(entry.key, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
                ...entry.value.take(20).map((r) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: pw.Text(
                    '${DateFormat('HH:mm').format(r.timestamp)} ${r.categoryEmoji} ${r.summary}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                )),
                pw.SizedBox(height: 8),
              ],
            );
          }),
        ],
      ));

      // Share/print
      if (mounted) {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: '${profile?.name ?? "아기"}_성장리포트_$dateStr.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 생성 중 오류: $e'), backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  pw.Widget _buildPdfSection(String title, String count, List<String> details) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(count, style: pw.TextStyle(fontSize: 14, color: PdfColor.fromHex('#7C4DFF'),
                fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...details.map((d) => pw.Text(d, style: const pw.TextStyle(fontSize: 10))),
          ],
        ],
      ),
    );
  }

  Map<String, List<BabyRecord>> _groupRecordsByDate(List<BabyRecord> records) {
    final map = <String, List<BabyRecord>>{};
    for (final r in records) {
      final key = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(r.timestamp);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
      ],
    );
  }
}
