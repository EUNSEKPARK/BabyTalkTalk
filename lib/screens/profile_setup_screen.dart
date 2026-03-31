import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/models/baby_profile.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ProfileSetupScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  DateTime _birthDate = DateTime.now();
  String? _gender;
  int _growthStage = 0;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = context.read<RecordService>().profile;
    if (profile != null) {
      _nameController.text = profile.name;
      _birthDate = profile.birthDate;
      _gender = profile.gender;
      _growthStage = profile.growthStageIndex;
      _weightController.text = profile.birthWeight?.toString() ?? '';
      _heightController.text = profile.birthHeight?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim().isEmpty ? '우리 아기' : _nameController.text.trim();
    
    final profile = BabyProfile(
      name: name,
      birthDate: _birthDate,
      gender: _gender,
      birthWeight: _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null,
      birthHeight: _heightController.text.isNotEmpty
          ? double.tryParse(_heightController.text)
          : null,
      growthStageIndex: _growthStage,
    );

    await context.read<RecordService>().saveProfile(profile);

    if (!mounted) return;
    if (widget.isInitialSetup) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pop(context);
    }
  }

  void _skipSetup() async {
    final profile = BabyProfile(
      name: '우리 아기',
      birthDate: DateTime.now(),
      growthStageIndex: 0,
    );
    await context.read<RecordService>().saveProfile(profile);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isInitialSetup
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                TextButton(
                  onPressed: _skipSetup,
                  child: const Text('건너뛰기', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                ),
              ],
            )
          : AppBar(title: const Text('아기 정보')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isInitialSetup) ...
                [
                  const SizedBox(height: 20),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/onboarding_profile.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '아기톡톡에 오신 걸 환영해요!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      '아기 정보를 알면 더 잘 도와드릴 수 있어요',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

              // 이름
              _buildLabel('아기 이름'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: '예: 하율이',
                ),
              ),
              const SizedBox(height: 20),

              // 생년월일
              _buildLabel('생년월일 *'),
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('yyyy년 M월 d일').format(_birthDate),
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppTheme.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 성별
              _buildLabel('성별'),
              Row(
                children: [
                  Expanded(
                    child: _GenderButton(
                      label: '남자',
                      emoji: '👦',
                      isSelected: _gender == 'M',
                      onTap: () => setState(() => _gender = 'M'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderButton(
                      label: '여자',
                      emoji: '👧',
                      isSelected: _gender == 'F',
                      onTap: () => setState(() => _gender = 'F'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 성장 단계
              _buildLabel('성장 단계 *'),
              Row(
                children: [
                  Expanded(
                    child: _GrowthStageButton(
                      label: '분유기',
                      emoji: '🍼',
                      isSelected: _growthStage == 0,
                      onTap: () => setState(() => _growthStage = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GrowthStageButton(
                      label: '이유식기',
                      emoji: '🥣',
                      isSelected: _growthStage == 1,
                      onTap: () => setState(() => _growthStage = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GrowthStageButton(
                      label: '유아식기',
                      emoji: '🍚',
                      isSelected: _growthStage == 2,
                      onTap: () => setState(() => _growthStage = 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 출생 체중
              _buildLabel('출생 체중 (kg)'),
              TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '예: 3.2'),
              ),
              const SizedBox(height: 20),

              // 출생 신장
              _buildLabel('출생 신장 (cm)'),
              TextField(
                controller: _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '예: 50'),
              ),
              const SizedBox(height: 40),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.isInitialSetup ? '시작하기' : '저장',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthStageButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _GrowthStageButton({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
