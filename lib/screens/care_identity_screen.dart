import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:chat_baby_time/models/baby_profile.dart';
import 'package:chat_baby_time/services/care_onboarding_service.dart';
import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 튜토리얼·프로필 등록 후: 우리 아이 선택 + 메인 담당 / 초대 코드 / 혼자 사용
class CareIdentityScreen extends StatefulWidget {
  const CareIdentityScreen({super.key});

  @override
  State<CareIdentityScreen> createState() => _CareIdentityScreenState();
}

class _CareIdentityScreenState extends State<CareIdentityScreen> {
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _inviteExpanded = false;
  bool _finishing = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _goHome({bool? primaryCaregiver}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    context.read<FamilyService>().clearError();
    await CareOnboardingService.setPrimaryCaregiver(primaryCaregiver);
    await CareOnboardingService.markIdentityStepDone();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _onPrimaryPath() => _goHome(primaryCaregiver: true);

  Future<void> _onSoloPath() => _goHome(primaryCaregiver: null);

  Future<void> _onJoinWithCode() async {
    final fs = context.read<FamilyService>();
    final nickname = _nicknameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (nickname.isEmpty) {
      _snack('호칭을 입력해 주세요 (예: 엄마, 아빠)');
      return;
    }
    if (code.length != 6) {
      _snack('6자리 초대 코드를 입력해 주세요');
      return;
    }
    fs.clearError();
    final err = await fs.joinFamily(code, nickname);
    if (!mounted) return;
    if (err != null) {
      _snack(err);
      return;
    }
    await CareOnboardingService.setPrimaryCaregiver(false);
    await CareOnboardingService.markIdentityStepDone();
    if (!mounted) return;
    _snack('가족에 참여했어요!');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Widget _nicknameChips() {
    const presets = ['엄마', '아빠', '할머니', '할아버지'];
    return Wrap(
      spacing: 8,
      children: presets.map((name) {
        final selected = _nicknameController.text == name;
        return ChoiceChip(
          label: Text(name),
          selected: selected,
          onSelected: (_) {
            setState(() => _nicknameController.text = name);
          },
          selectedColor: AppTheme.primary.withOpacity(0.15),
          labelStyle: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _childCard(BabyProfile p, bool selected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.1)
                : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.child_care_rounded,
                color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final familyService = context.watch<FamilyService>();
    final profiles = recordService.allProfiles;
    final activeId = recordService.activeProfileId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('시작 설정'),
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '이 기기에서 어떻게 기록할까요?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '회원가입이 아니에요. 공유 코드가 있으면 입력하고,\n주로 돌봄하시는 분은 메인 담당을 선택해 주세요.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            if (profiles.length > 1) ...[
              Text(
                '우리 아이 선택',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              ...profiles.map((p) {
                final sel = p.profileId == activeId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _childCard(p, sel, () async {
                    if (!sel) {
                      await recordService.switchProfile(p.profileId);
                      if (mounted) setState(() {});
                    }
                  }),
                );
              }),
              const SizedBox(height: 20),
            ] else if (profiles.isNotEmpty) ...[
              Text(
                '기록할 아이',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                profiles.first.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
            ],

            _pathTile(
              icon: Icons.home_filled,
              title: '메인 육아 담당자예요',
              subtitle:
                  '이 기기에서 주로 기록해요. 가족을 초대할 때는 하단 「설정」탭에서 「가족 공유」를 연 뒤 '
                  '「새 가족 그룹 만들기」를 한 뒤, 초대 코드를 「복사」하거나 「공유」로 전달하면 됩니다.',
              onPressed: _finishing ? null : _onPrimaryPath,
            ),
            const SizedBox(height: 12),
            _pathTile(
              icon: Icons.vpn_key_rounded,
              title: '초대 코드로 함께 기록할게요',
              subtitle: '집에서 받은 6자리 코드로 가족 그룹에 참여해요.',
              onPressed: _finishing
                  ? null
                  : () {
                      familyService.clearError();
                      setState(() => _inviteExpanded = !_inviteExpanded);
                    },
              trailing: Icon(
                _inviteExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            if (_inviteExpanded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '나의 호칭',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _nicknameChips(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: '직접 입력 (예: 엄마, 아빠)',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '초대 코드',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '6자리',
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      ],
                    ),
                    if (familyService.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        familyService.error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: familyService.syncing ? null : _onJoinWithCode,
                      child: familyService.syncing
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('코드로 참여하기'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _pathTile(
              icon: Icons.person_outline_rounded,
              title: '일단 혼자 기록할게요',
              subtitle: '나중에 설정 → 가족 공유에서 언제든 연결할 수 있어요.',
              onPressed: _finishing ? null : _onSoloPath,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pathTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onPressed,
    Widget? trailing,
  }) {
    return Material(
      color: AppTheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
