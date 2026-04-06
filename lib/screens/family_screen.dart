import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 가족 공유 설정 화면
///
/// - 가족 그룹 생성 (초대 코드 발급)
/// - 초대 코드로 가족 참여
/// - 가족 구성원 목록
/// - 가족 탈퇴
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyService = context.watch<FamilyService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('가족 공유'),
        backgroundColor: AppTheme.background,
      ),
      body: familyService.syncing
          ? const Center(child: CircularProgressIndicator())
          : familyService.isInFamily
              ? _buildFamilyView(context, familyService)
              : _buildJoinOrCreateView(context, familyService),
    );
  }

  // ===== 가족이 없을 때: 생성 or 참여 =====

  Widget _buildJoinOrCreateView(BuildContext context, FamilyService fs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 설명
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.family_restroom,
                      size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  '함께 기록해요!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '엄마, 아빠가 함께 아기의 하루를\n실시간으로 기록하고 공유할 수 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 닉네임 입력 (공통)
          Text(
            '나의 호칭',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _buildNicknameChips(),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: '직접 입력 (예: 엄마, 아빠, 할머니)',
              filled: true,
              fillColor: AppTheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 24),

          // 새 가족 만들기
          FilledButton.icon(
            onPressed: () => _createFamily(fs),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('새 가족 그룹 만들기'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 구분선
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('또는',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 16),

          // 초대 코드로 참여
          Text(
            '초대 코드 입력',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '6자리 코드',
                    counterText: '',
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _joinFamily(fs),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('참여'),
              ),
            ],
          ),

          if (fs.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(fs.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNicknameChips() {
    final presets = ['엄마', '아빠', '할머니', '할아버지'];
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

  // ===== 가족이 있을 때: 정보 + 멤버 + 관리 =====

  Widget _buildFamilyView(BuildContext context, FamilyService fs) {
    final group = fs.familyGroup!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 초대 코드 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  '초대 코드',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  group.inviteCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCodeActionButton(
                      icon: Icons.copy,
                      label: '복사',
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: group.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('초대 코드가 복사되었어요!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildCodeActionButton(
                      icon: Icons.share,
                      label: '공유',
                      onTap: () {
                        Share.share(
                          '아기톡톡에서 함께 육아 기록해요!\n'
                          '초대 코드: ${group.inviteCode}\n\n'
                          '앱을 설치하고 [가족 공유]에서 코드를 입력하세요.',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 가족 구성원
          Text(
            '가족 구성원 (${group.members.length}명)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),

          ...group.members.map((member) {
            final isMe = member.uid == fs.uid;
            final isOwner = member.role == 'owner';
            return Card(
              color: AppTheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isMe
                      ? AppTheme.primary.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  child: Text(
                    _nicknameEmoji(member.nickname),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.nickname,
                      style: TextStyle(
                        fontWeight:
                            isMe ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '나',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    ],
                  ],
                ),
                subtitle: Text(
                  _formatJoinDate(member.joinedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 사용 방법 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      '공유 기록 안내',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '가족이 기록한 내용이 실시간으로 동기화됩니다.\n'
                  '각 기록에 누가 작성했는지 표시되어\n'
                  '엄마, 아빠가 번갈아 기록해도 한눈에 볼 수 있어요.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 가족 탈퇴
          OutlinedButton.icon(
            onPressed: () => _confirmLeave(context, fs),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('가족 그룹 나가기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[400],
              side: BorderSide(color: Colors.red[300]!),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ===== 액션 =====

  Future<void> _createFamily(FamilyService fs) async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showSnack('호칭을 입력해주세요 (예: 엄마, 아빠)');
      return;
    }
    final err = await fs.createFamily(nickname);
    if (err != null) {
      _showSnack(err);
    }
  }

  Future<void> _joinFamily(FamilyService fs) async {
    final nickname = _nicknameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (nickname.isEmpty) {
      _showSnack('호칭을 입력해주세요 (예: 엄마, 아빠)');
      return;
    }
    if (code.length != 6) {
      _showSnack('6자리 초대 코드를 입력해주세요');
      return;
    }
    final err = await fs.joinFamily(code, nickname);
    if (err != null) {
      _showSnack(err);
    } else {
      _showSnack('가족에 참여했어요!');
    }
  }

  Future<void> _confirmLeave(BuildContext context, FamilyService fs) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가족 그룹 나가기'),
        content: const Text(
          '가족 그룹에서 나가면 공유 기록을 더 이상 받을 수 없어요.\n'
          '로컬에 저장된 기록은 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (result == true) {
      await fs.leaveFamily();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  String _nicknameEmoji(String nickname) {
    if (nickname.contains('엄마') || nickname.contains('맘')) return '👩';
    if (nickname.contains('아빠') || nickname.contains('파파')) return '👨';
    if (nickname.contains('할머니')) return '👵';
    if (nickname.contains('할아버지')) return '👴';
    if (nickname.contains('이모') || nickname.contains('고모')) return '👩‍🦰';
    return '👤';
  }

  String _formatJoinDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 참여';
  }
}
