import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/utils/time_utils.dart';

class RecordDetailScreen extends StatefulWidget {
  final BabyRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  late DateTime _timestamp;
  late RecordCategory _category;

  // 수유
  late FeedingType _feedingType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // 수면
  late SleepStatus _sleepStatus;

  // 기저귀
  late DiaperType _diaperType;

  // 건강
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _medicineController = TextEditingController();

  // 메모
  final TextEditingController _memoController = TextEditingController();

  // 사진
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _timestamp = r.timestamp;
    _category = r.category;
    _feedingType = r.feedingType ?? FeedingType.formula;
    _amountController.text = r.amountMl?.toString() ?? '';
    _durationController.text = r.durationMinutes?.toString() ?? '';
    _sleepStatus = r.sleepStatus ?? SleepStatus.start;
    _diaperType = r.diaperType ?? DiaperType.pee;
    _tempController.text = r.temperature?.toString() ?? '';
    _medicineController.text = r.medicine ?? '';
    _memoController.text = r.memo ?? '';
    _photoPath = r.photoPath;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _tempController.dispose();
    _medicineController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() async {
    final updated = BabyRecord(
      id: widget.record.id,
      category: _category,
      timestamp: _timestamp,
      rawInput: widget.record.rawInput,
      feedingType: _category == RecordCategory.feeding ? _feedingType : null,
      amountMl: _amountController.text.isNotEmpty
          ? int.tryParse(_amountController.text)
          : null,
      durationMinutes: _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null,
      sleepStatus: _category == RecordCategory.sleep ? _sleepStatus : null,
      diaperType: _category == RecordCategory.diaper ? _diaperType : null,
      temperature: _tempController.text.isNotEmpty
          ? double.tryParse(_tempController.text)
          : null,
      medicine:
          _medicineController.text.isNotEmpty ? _medicineController.text : null,
      memo: _memoController.text.isNotEmpty ? _memoController.text : null,
      photoPath: _photoPath,
      createdAt: widget.record.createdAt,
    );

    final success = await context.read<RecordService>().updateRecord(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '기록이 수정되었습니다' : '수정 중 오류가 발생했습니다'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '기록 삭제',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        content: Text(
          '이 ${widget.record.categoryName} 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '취소',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<RecordService>().deleteRecord(widget.record.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '기록이 삭제되었습니다' : '삭제 중 오류가 발생했습니다'),
                    backgroundColor: success ? AppTheme.surfaceContainer : AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: Text(
              '삭제',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time != null) {
      setState(() {
        _timestamp = DateTime(
          _timestamp.year,
          _timestamp.month,
          _timestamp.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _delete,
            tooltip: '삭제',
          ),
          TextButton(
            onPressed: _save,
            child: const Text(
              '저장',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 원본 입력 표시
            if (widget.record.rawInput != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${widget.record.rawInput}"',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 시간 선택
            _buildSectionTitle('시간'),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      TimeUtils.formatTime(_timestamp),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit,
                      size: 18,
                      color: AppTheme.textHint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 카테고리 선택
            _buildSectionTitle('카테고리'),
            Wrap(
              spacing: 8,
              children: RecordCategory.values
                  .where((c) => c != RecordCategory.milestone)
                  .map((c) => ChoiceChip(
                        label: Text(_categoryLabel(c)),
                        selected: _category == c,
                        selectedColor: AppTheme.primary.withOpacity(0.2),
                        onSelected: (selected) {
                          if (selected) setState(() => _category = c);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // 카테고리별 상세 필드
            ..._buildCategoryFields(),

            // 사진
            _buildSectionTitle('사진'),
            _buildPhotoSection(),
            const SizedBox(height: 20),

            // 메모
            _buildSectionTitle('메모'),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '추가 메모를 입력하세요',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;

      // Copy to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/photos');
      if (!photoDir.existsSync()) photoDir.createSync(recursive: true);
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path).copy('${photoDir.path}/$fileName');

      setState(() => _photoPath = savedFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진을 가져올 수 없습니다'), backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.gallery); },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppTheme.error),
                  title: Text('사진 삭제', style: TextStyle(color: AppTheme.error)),
                  onTap: () { Navigator.pop(ctx); setState(() => _photoPath = null); },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_photoPath != null && File(_photoPath!).existsSync()) {
      return GestureDetector(
        onTap: _showPhotoOptions,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.file(File(_photoPath!), width: double.infinity, height: 200, fit: BoxFit.cover),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceContainerHigh, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.textHint),
            const SizedBox(height: 8),
            Text('사진 추가', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  List<Widget> _buildCategoryFields() {
    switch (_category) {
      case RecordCategory.feeding:
        return [
          _buildSectionTitle('수유 종류'),
          Wrap(
            spacing: 8,
            children: [FeedingType.breast, FeedingType.formula].map((t) {
              return ChoiceChip(
                label: Text(_feedingLabel(t)),
                selected: _feedingType == t,
                selectedColor: AppTheme.feedingColor.withOpacity(0.3),
                onSelected: (s) {
                  if (s) setState(() => _feedingType = t);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('양 (ml)'),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '예: 120'),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('시간 (분)'),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '예: 15'),
          ),
          const SizedBox(height: 20),
        ];
      case RecordCategory.sleep:
        return [
          _buildSectionTitle('수면 상태'),
          Wrap(
            spacing: 8,
            children: SleepStatus.values.map((s) {
              return ChoiceChip(
                label: Text(s == SleepStatus.start ? '잠듦' : '깨어남'),
                selected: _sleepStatus == s,
                selectedColor: AppTheme.sleepColor.withOpacity(0.3),
                onSelected: (sel) {
                  if (sel) setState(() => _sleepStatus = s);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ];
      case RecordCategory.diaper:
        return [
          _buildSectionTitle('기저귀 종류'),
          Wrap(
            spacing: 8,
            children: DiaperType.values.map((d) {
              return ChoiceChip(
                label: Text(_diaperLabel(d)),
                selected: _diaperType == d,
                selectedColor: AppTheme.diaperColor.withOpacity(0.3),
                onSelected: (s) {
                  if (s) setState(() => _diaperType = d);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ];
      case RecordCategory.health:
        return [
          _buildSectionTitle('체온 (°C)'),
          TextField(
            controller: _tempController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '예: 37.5'),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('약'),
          TextField(
            controller: _medicineController,
            decoration: const InputDecoration(hintText: '약 이름'),
          ),
          const SizedBox(height: 20),
        ];
      case RecordCategory.babyfood:
        return [
          _buildSectionTitle('양 (ml)'),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '예: 100'),
          ),
          const SizedBox(height: 20),
        ];
      default:
        return [const SizedBox(height: 20)];
    }
  }

  String _categoryLabel(RecordCategory c) {
    switch (c) {
      case RecordCategory.feeding:
        return '🍼 수유';
      case RecordCategory.babyfood:
        return '🥣 이유식';
      case RecordCategory.snack:
        return '🍪 간식';
      case RecordCategory.sleep:
        return '😴 수면';
      case RecordCategory.diaper:
        return '🧷 기저귀';
      case RecordCategory.health:
        return '🌡️ 건강';
      case RecordCategory.bath:
        return '🛁 목욕';
      case RecordCategory.pumping:
        return '🍼 유축';
      case RecordCategory.tummytime:
        return '👶 터미타임';
      case RecordCategory.other:
        return '📝 기타';
      default:
        return '';
    }
  }

  String _feedingLabel(FeedingType t) {
    switch (t) {
      case FeedingType.breast:
        return '모유';
      case FeedingType.formula:
        return '분유';
      default:
        return '분유';
    }
  }

  String _diaperLabel(DiaperType d) {
    switch (d) {
      case DiaperType.pee:
        return '소변';
      case DiaperType.poop:
        return '대변';
      case DiaperType.both:
        return '소변+대변';
    }
  }
}
