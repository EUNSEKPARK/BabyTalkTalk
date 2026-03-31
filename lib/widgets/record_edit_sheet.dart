import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:intl/intl.dart';

/// 리스트에서 직접 수정할 수 있는 바텀시트
class RecordEditSheet extends StatefulWidget {
  final BabyRecord record;

  const RecordEditSheet({super.key, required this.record});

  @override
  State<RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends State<RecordEditSheet> {
  // State for all editable fields
  late RecordCategory _category;
  late DateTime _timestamp;
  late TextEditingController _memoController;
  late TextEditingController _amountController;
  late TextEditingController _durationController;
  late TextEditingController _tempController;
  late TextEditingController _medicineController;
  FeedingType? _feedingType;
  SleepStatus? _sleepStatus;
  DiaperType? _diaperType;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _category = r.category;
    _timestamp = r.timestamp;
    _feedingType = r.feedingType;
    _sleepStatus = r.sleepStatus;
    _diaperType = r.diaperType;
    _memoController = TextEditingController(text: r.memo ?? '');
    _amountController = TextEditingController(text: r.amountMl?.toString() ?? '');
    _durationController = TextEditingController(text: r.durationMinutes?.toString() ?? '');
    _tempController = TextEditingController(text: r.temperature?.toString() ?? '');
    _medicineController = TextEditingController(text: r.medicine ?? '');
  }

  @override
  void dispose() {
    _memoController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _tempController.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  void _save() async {
    final r = widget.record;
    r.category = _category;
    r.timestamp = _timestamp;
    r.memo = _memoController.text.isEmpty ? null : _memoController.text;
    r.amountMl = int.tryParse(_amountController.text);
    r.durationMinutes = int.tryParse(_durationController.text);
    r.temperature = double.tryParse(_tempController.text);
    r.medicine = _medicineController.text.isEmpty ? null : _medicineController.text;
    r.feedingType = _feedingType;
    r.sleepStatus = _sleepStatus;
    r.diaperType = _diaperType;

    await context.read<RecordService>().updateRecord(r);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time != null) {
      setState(() {
        _timestamp = DateTime(
          _timestamp.year, _timestamp.month, _timestamp.day,
          time.hour, time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Text(widget.record.categoryEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Text('기록 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('a h:mm', 'ko').format(_timestamp),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, size: 14, color: AppTheme.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category-specific fields
            if (_category == RecordCategory.feeding || _category == RecordCategory.babyfood) ...[
              // Feeding type selector
              if (_category == RecordCategory.feeding)
                _buildChipSelector<FeedingType>(
                  label: '수유 타입',
                  options: [FeedingType.breast, FeedingType.formula],
                  labels: ['모유', '분유'],
                  selected: _feedingType,
                  onSelect: (v) => setState(() => _feedingType = v),
                ),
              // Amount
              _buildTextField('양 (ml)', _amountController, TextInputType.number),
              // Duration
              if (_feedingType == FeedingType.breast)
                _buildTextField('시간 (분)', _durationController, TextInputType.number),
            ],

            if (_category == RecordCategory.sleep)
              _buildChipSelector<SleepStatus>(
                label: '수면 상태',
                options: [SleepStatus.start, SleepStatus.end],
                labels: ['잠듦', '깨어남'],
                selected: _sleepStatus,
                onSelect: (v) => setState(() => _sleepStatus = v),
              ),

            if (_category == RecordCategory.diaper)
              _buildChipSelector<DiaperType>(
                label: '기저귀',
                options: [DiaperType.pee, DiaperType.poop, DiaperType.both],
                labels: ['소변', '대변', '둘 다'],
                selected: _diaperType,
                onSelect: (v) => setState(() => _diaperType = v),
              ),

            if (_category == RecordCategory.health) ...[
              _buildTextField('체온 (°C)', _tempController, const TextInputType.numberWithOptions(decimal: true)),
              _buildTextField('약', _medicineController, TextInputType.text),
            ],

            // Memo
            _buildTextField('메모', _memoController, TextInputType.text),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildChipSelector<T>({
    required String label,
    required List<T> options,
    required List<String> labels,
    required T? selected,
    required void Function(T) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: List.generate(options.length, (i) {
              final isSelected = selected == options[i];
              return ChoiceChip(
                label: Text(labels[i]),
                selected: isSelected,
                onSelected: (_) => onSelect(options[i]),
                selectedColor: AppTheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
