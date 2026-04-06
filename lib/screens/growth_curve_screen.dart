import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class GrowthCurveScreen extends StatefulWidget {
  const GrowthCurveScreen({super.key});

  @override
  State<GrowthCurveScreen> createState() => _GrowthCurveScreenState();
}

class _GrowthCurveScreenState extends State<GrowthCurveScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _headController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _headController.dispose();
    super.dispose();
  }

  void _recordMeasurement() async {
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('올바른 숫자를 입력해주세요'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (height < 20 || height > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('키는 20~150cm 범위로 입력해주세요'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (weight < 1 || weight > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('몸무게는 1~30kg 범위로 입력해주세요'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final headCirc = double.tryParse(_headController.text.trim());

    final recordService = context.read<RecordService>();
    final success = await recordService.addGrowthMeasurement(
      heightCm: height,
      weightKg: weight,
      headCircCm: headCirc,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      _heightController.clear();
      _weightController.clear();
      _headController.clear();
      final headStr = headCirc != null ? ', 두위 ${headCirc}cm' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('기록 완료! 키 ${height}cm, 몸무게 ${weight}kg$headStr'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Map<String, String> _getWHOStandardForAge(int ageInMonths) {
    if (ageInMonths < 1) {
      return {'avgHeight': '50.5', 'heightMin': '48.5', 'heightMax': '52.5', 'avgWeight': '3.7', 'weightMin': '3.0', 'weightMax': '4.3', 'avgHeadCirc': '35.0', 'headCircMin': '33.0', 'headCircMax': '37.0'};
    } else if (ageInMonths < 3) {
      return {'avgHeight': '58.5', 'heightMin': '55.5', 'heightMax': '61.5', 'avgWeight': '5.8', 'weightMin': '4.8', 'weightMax': '6.8', 'avgHeadCirc': '39.0', 'headCircMin': '37.0', 'headCircMax': '41.0'};
    } else if (ageInMonths < 6) {
      return {'avgHeight': '66.0', 'heightMin': '62.5', 'heightMax': '69.5', 'avgWeight': '7.6', 'weightMin': '6.3', 'weightMax': '8.9', 'avgHeadCirc': '42.0', 'headCircMin': '40.0', 'headCircMax': '44.0'};
    } else if (ageInMonths < 9) {
      return {'avgHeight': '72.0', 'heightMin': '68.0', 'heightMax': '76.0', 'avgWeight': '8.8', 'weightMin': '7.3', 'weightMax': '10.3', 'avgHeadCirc': '44.0', 'headCircMin': '42.0', 'headCircMax': '46.0'};
    } else if (ageInMonths < 12) {
      return {'avgHeight': '77.0', 'heightMin': '72.5', 'heightMax': '81.5', 'avgWeight': '9.7', 'weightMin': '8.0', 'weightMax': '11.4', 'avgHeadCirc': '45.5', 'headCircMin': '43.5', 'headCircMax': '47.5'};
    } else {
      return {'avgHeight': '82.0', 'heightMin': '77.0', 'heightMax': '87.0', 'avgWeight': '10.8', 'weightMin': '8.9', 'weightMax': '12.7', 'avgHeadCirc': '46.5', 'headCircMin': '44.5', 'headCircMax': '48.5'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final profile = recordService.profile;
    final ageInMonths = profile?.ageInMonths ?? 0;
    final whoStandards = _getWHOStandardForAge(ageInMonths);
    final measurements = recordService.growthMeasurements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('성장곡선'),
        backgroundColor: AppTheme.background,
      ),
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input Form
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 측정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '키 (cm)',
                    hintText: '예: 60.5',
                    prefixIcon: Icon(Icons.straighten, color: AppTheme.primary),
                    labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '몸무게 (kg)',
                    hintText: '예: 4.2',
                    prefixIcon: Icon(Icons.scale, color: AppTheme.primary),
                    labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _headController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '두위 (cm) - 선택',
                    hintText: '예: 36.5',
                    prefixIcon: Icon(Icons.circle_outlined, color: AppTheme.secondary),
                    labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _recordMeasurement,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('기록하기'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Growth Charts
          if (measurements.isNotEmpty) ...[
            _buildGrowthChart(
              title: '키 성장 곡선',
              measurements: measurements,
              dataKey: 'heightCm',
              unit: 'cm',
              whoMin: double.tryParse(whoStandards['heightMin'] ?? '') ?? 0,
              whoMax: double.tryParse(whoStandards['heightMax'] ?? '') ?? 0,
              whoAvg: double.tryParse(whoStandards['avgHeight'] ?? '') ?? 0,
              color: AppTheme.primary,
              icon: Icons.straighten,
            ),
            const SizedBox(height: 16),
            _buildGrowthChart(
              title: '몸무게 성장 곡선',
              measurements: measurements,
              dataKey: 'weightKg',
              unit: 'kg',
              whoMin: double.tryParse(whoStandards['weightMin'] ?? '') ?? 0,
              whoMax: double.tryParse(whoStandards['weightMax'] ?? '') ?? 0,
              whoAvg: double.tryParse(whoStandards['avgWeight'] ?? '') ?? 0,
              color: AppTheme.tertiary,
              icon: Icons.scale,
            ),
            // Head circumference chart (only if data exists)
            if (measurements.any((m) => m['headCircCm'] != null)) ...[
              const SizedBox(height: 16),
              _buildGrowthChart(
                title: '두위 성장 곡선',
                measurements: measurements.where((m) => m['headCircCm'] != null).toList(),
                dataKey: 'headCircCm',
                unit: 'cm',
                whoMin: double.tryParse(whoStandards['headCircMin'] ?? '') ?? 0,
                whoMax: double.tryParse(whoStandards['headCircMax'] ?? '') ?? 0,
                whoAvg: double.tryParse(whoStandards['avgHeadCirc'] ?? '') ?? 0,
                color: AppTheme.secondary,
                icon: Icons.circle_outlined,
              ),
            ],
            const SizedBox(height: 24),
          ],

          // Saved Measurements
          if (measurements.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📏', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '측정 기록 (${measurements.length}회)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...measurements.take(10).map((m) {
                    final date = m['date'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('M/d').format(date),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.straighten, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m['heightCm']}cm',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.scale, size: 16, color: AppTheme.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m['weightKg']}kg',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (m['headCircCm'] != null) ...[
                                    const SizedBox(width: 16),
                                    Icon(Icons.circle_outlined, size: 16, color: AppTheme.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${m['headCircCm']}cm',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // WHO Standard Info Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.tertiary.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      'WHO 표준 범위',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.tertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (profile != null) ...[
                  _InfoRow(label: '나이', value: profile.ageText),
                  const SizedBox(height: 12),
                  _InfoRow(label: '평균 키', value: '${whoStandards["avgHeight"]} cm'),
                  const SizedBox(height: 12),
                  _InfoRow(label: '정상 범위 (키)', value: '${whoStandards["heightMin"]} ~ ${whoStandards["heightMax"]} cm'),
                  const SizedBox(height: 12),
                  _InfoRow(label: '평균 몸무게', value: '${whoStandards["avgWeight"]} kg'),
                  const SizedBox(height: 12),
                  _InfoRow(label: '정상 범위 (몸무게)', value: '${whoStandards["weightMin"]} ~ ${whoStandards["weightMax"]} kg'),
                  const SizedBox(height: 12),
                  _InfoRow(label: '평균 두위', value: '${whoStandards["avgHeadCirc"]} cm'),
                  const SizedBox(height: 12),
                  _InfoRow(label: '정상 범위 (두위)', value: '${whoStandards["headCircMin"]} ~ ${whoStandards["headCircMax"]} cm'),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'WHO 표준을 기반한 참고치입니다. 개인차가 크므로 의료진과 상담하시기 바랍니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGrowthChart({
    required String title,
    required List<Map<String, dynamic>> measurements,
    required String dataKey,
    required String unit,
    required double whoMin,
    required double whoMax,
    required double whoAvg,
    required Color color,
    required IconData icon,
  }) {
    final sorted = List<Map<String, dynamic>>.from(measurements)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final spots = <FlSpot>[];
    final dateLabels = <int, String>{};
    for (int i = 0; i < sorted.length; i++) {
      final value = (sorted[i][dataKey] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
      dateLabels[i] = DateFormat('M/d').format(sorted[i]['date'] as DateTime);
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final dataValues = spots.map((s) => s.y).toList();
    final allValues = [...dataValues, whoMin, whoMax];
    final minY = (allValues.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (allValues.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();
    final latestValue = spots.last.y;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    latestValue.toStringAsFixed(1),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.onSurface.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == minY || value == maxY) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (dateLabels.containsKey(idx)) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dateLabels[idx]!,
                              style: const TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: whoAvg,
                      color: color.withOpacity(0.4),
                      strokeWidth: 1,
                      dashArray: [8, 4],
                    ),
                    HorizontalLine(
                      y: whoMin,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                    HorizontalLine(
                      y: whoMax,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: spots.length > 2,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: AppTheme.surfaceContainer,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              Container(
                width: 16,
                height: 2,
                color: color.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                'WHO 평균 ${whoAvg}$unit',
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 1,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '정상 범위 ${whoMin}~${whoMax}$unit',
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
