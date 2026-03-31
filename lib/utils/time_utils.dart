import 'package:intl/intl.dart';

class TimeUtils {
  /// "오후 2:30" 형식
  static String formatTime(DateTime dt) {
    return DateFormat('a h:mm', 'ko_KR').format(dt);
  }

  /// "3월 21일 (토)" 형식
  static String formatDate(DateTime dt) {
    return DateFormat('M월 d일 (E)', 'ko_KR').format(dt);
  }

  /// "2026.03.21" 형식
  static String formatDateShort(DateTime dt) {
    return DateFormat('yyyy.MM.dd').format(dt);
  }

  /// "오후 2:30" 또는 "N분 전"
  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24 &&
        dt.day == now.day) {
      return formatTime(dt);
    } else {
      return '${formatDate(dt)} ${formatTime(dt)}';
    }
  }

  /// 경과 시간 텍스트
  static String elapsedSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 경과';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 ${diff.inMinutes % 60}분 경과';
    } else {
      return '${diff.inDays}일 경과';
    }
  }
}
