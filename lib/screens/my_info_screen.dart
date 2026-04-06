import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chat_baby_time/models/baby_profile.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 내 정보 화면 — 멀티 아이 관리, 가족 역할 표시
class MyInfoScreen extends StatelessWidget {
  const MyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: AppTheme.background,
      ),
      body: Consumer2<RecordService, FamilyService>(
        builder: (context, recordService, familyService, _) {
          final profiles = recordService.allProfiles;
          final activeId = recordService.activeProfileId;
          final isInFamily = familyService.isInFamily;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── 가족 공유 상태 ──
              if (isInFamily) ...[
                Text(
                  '가족 공유',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                _FamilyStatusCard(familyService: familyService),
                const SizedBox(height: 28),
              ],

              // ── 아이 목록 ──
              Row(
                children: [
                  Text(
                    '아이 목록',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddChildSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('추가'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profiles.isEmpty)
                Card(
                  color: AppTheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '등록된 아이가 없습니다.\n위의 추가 버튼을 눌러 아이를 등록해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                ...profiles.map((profile) => _ChildCard(
                      profile: profile,
                      isActive: profile.profileId == activeId,
                      recordCount:
                          recordService.recordCountForProfile(profile.profileId),
                      canDelete: profiles.length > 1,
                    )),
            ],
          );
        },
      ),
    );
  }

  static void _showAddChildSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _ChildEditScreen(isNew: true),
      ),
    );
  }
}

/// 가족 공유 상태 카드
class _FamilyStatusCard extends StatelessWidget {
  final FamilyService familyService;
  const _FamilyStatusCard({required this.familyService});

  @override
  Widget build(BuildContext context) {
    final group = familyService.familyGroup;
    if (group == null) return const SizedBox.shrink();

    final uid = familyService.uid;
    final isOwner = group.ownerId == uid;
    final myNickname = familyService.myNickname;
    final members = group.members;

    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOwner
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOwner ? '관리자' : '멤버',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOwner
                          ? AppTheme.primary
                          : AppTheme.onSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  myNickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '초대 코드: ${group.inviteCode}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: members.map((m) {
                final isMe = m.uid == uid;
                return Chip(
                  avatar: Icon(
                    isMe ? Icons.person : Icons.person_outline,
                    size: 16,
                    color: isMe ? AppTheme.primary : AppTheme.textHint,
                  ),
                  label: Text(
                    m.nickname,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                      color: isMe
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  backgroundColor: isMe
                      ? AppTheme.primaryContainer.withOpacity(0.3)
                      : AppTheme.surfaceContainerHigh,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아이 카드
class _ChildCard extends StatelessWidget {
  final BabyProfile profile;
  final bool isActive;
  final int recordCount;
  final bool canDelete;

  const _ChildCard({
    required this.profile,
    required this.isActive,
    required this.recordCount,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    final genderEmoji = profile.gender == 'M'
        ? '👦'
        : profile.gender == 'F'
            ? '👧'
            : '👶';

    return Card(
      color: isActive
          ? AppTheme.primaryContainer.withOpacity(0.25)
          : AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isActive ? null : () => _switchTo(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아바타
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.surfaceContainerHigh,
                ),
                child: Center(
                  child: Text(genderEmoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '현재',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.ageText} · 기록 $recordCount건',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '생일: ${DateFormat('yyyy. M. d').format(profile.birthDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // 액션 버튼들
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editProfile(context);
                      break;
                    case 'switch':
                      _switchTo(context);
                      break;
                    case 'delete':
                      _confirmDelete(context);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('정보 수정'),
                      ],
                    ),
                  ),
                  if (!isActive)
                    const PopupMenuItem(
                      value: 'switch',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('이 아이로 전환'),
                        ],
                      ),
                    ),
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchTo(BuildContext context) {
    context.read<RecordService>().switchProfile(profile.profileId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.name}(으)로 전환했어요'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChildEditScreen(
          isNew: false,
          existingProfile: profile,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('아이 삭제'),
        content: Text(
          '${profile.name}의 프로필과 모든 기록(${recordCount}건)이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await context
                  .read<RecordService>()
                  .deleteProfile(profile.profileId);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

/// 아이 추가/수정 화면
class _ChildEditScreen extends StatefulWidget {
  final bool isNew;
  final BabyProfile? existingProfile;

  const _ChildEditScreen({
    required this.isNew,
    this.existingProfile,
  });

  @override
  State<_ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<_ChildEditScreen> {
  final _nameController = TextEditingController();
  DateTime _birthDate = DateTime.now();
  String? _gender;
  int _growthStage = 0;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      final p = widget.existingProfile!;
      _nameController.text = p.name;
      _birthDate = p.birthDate;
      _gender = p.gender;
      _growthStage = p.growthStageIndex;
      _weightController.text = p.birthWeight?.toString() ?? '';
      _heightController.text = p.birthHeight?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim().isEmpty
        ? '우리 아기'
        : _nameController.text.trim();

    final recordService = context.read<RecordService>();

    if (widget.isNew) {
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
      await recordService.addNewProfile(profile);
    } else {
      final updated = BabyProfile(
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
        profileId: widget.existingProfile!.profileId,
      );
      await recordService.updateProfile(updated);
    }

    if (!mounted) return;
    Navigator.pop(context);
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.isNew ? '아이 추가' : '정보 수정'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름
              _buildLabel('아기 이름'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: '예: 하율이'),
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
                        style: const TextStyle(
                            fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.textHint),
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
                    child: _StageButton(
                      label: '분유기',
                      emoji: '🍼',
                      isSelected: _growthStage == 0,
                      onTap: () => setState(() => _growthStage = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StageButton(
                      label: '이유식기',
                      emoji: '🥣',
                      isSelected: _growthStage == 1,
                      onTap: () => setState(() => _growthStage = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StageButton(
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
                    widget.isNew ? '추가하기' : '저장',
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
          border:
              isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
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

class _StageButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _StageButton({
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
          border:
              isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
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
