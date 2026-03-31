import 'package:flutter/material.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 데이터 수집 동의 팝업
///
/// 앱 최초 실행 시 표시됩니다.
/// 동의하면 NLP 입력/결과 데이터를 익명으로 수집합니다.
class AnalyticsConsentDialog extends StatelessWidget {
  const AnalyticsConsentDialog({super.key});

  /// 다이얼로그 표시. true=동의, false=거부
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AnalyticsConsentDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '서비스 개선 참여',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '아기톡톡을 더 똑똑하게 만들기 위해\n'
            '채팅 인식 데이터를 익명으로 수집합니다.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),

          // 수집 항목 설명
          _buildInfoItem(
            icon: Icons.chat_bubble_outline,
            title: '수집 항목',
            desc: '입력한 텍스트, AI 인식 결과, 수정 내역',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.shield_outlined,
            title: '개인정보 보호',
            desc: '개인 식별 불가능한 익명 데이터만 수집',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.settings_outlined,
            title: '언제든 변경 가능',
            desc: '설정에서 수집을 끌 수 있어요',
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '참여해 주시면 "분유 먹었어" 같은 표현을\n더 정확하게 인식할 수 있게 됩니다!',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '다음에 할게요',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('참여할게요!', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
