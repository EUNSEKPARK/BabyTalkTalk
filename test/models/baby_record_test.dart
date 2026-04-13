import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/models/baby_record.dart';

void main() {
  group('BabyRecord', () {
    test('기본 생성 시 createdAt이 자동 설정됨', () {
      final before = DateTime.now();
      final record = BabyRecord(
        id: 'test-1',
        category: RecordCategory.feeding,
        timestamp: DateTime(2026, 4, 13, 10, 0),
      );
      final after = DateTime.now();

      expect(record.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(record.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('수유 기록 summary 정상 출력', () {
      final record = BabyRecord(
        id: 'feed-1',
        category: RecordCategory.feeding,
        timestamp: DateTime.now(),
        feedingType: FeedingType.formula,
        amountMl: 120,
        durationMinutes: 15,
      );
      expect(record.summary, '분유 120ml 15분');
    });

    test('모유 수유 summary', () {
      final record = BabyRecord(
        id: 'feed-2',
        category: RecordCategory.feeding,
        timestamp: DateTime.now(),
        feedingType: FeedingType.breast,
        durationMinutes: 20,
      );
      expect(record.summary, '모유 20분');
    });

    test('기저귀 소변 summary', () {
      final record = BabyRecord(
        id: 'diaper-1',
        category: RecordCategory.diaper,
        timestamp: DateTime.now(),
        diaperType: DiaperType.pee,
      );
      expect(record.summary, '기저귀 교체 (소변)');
    });

    test('기저귀 대변 + 메모 summary', () {
      final record = BabyRecord(
        id: 'diaper-2',
        category: RecordCategory.diaper,
        timestamp: DateTime.now(),
        diaperType: DiaperType.poop,
        memo: '묽은 변',
      );
      expect(record.summary, '기저귀 교체 (대변 · 묽은 변)');
    });

    test('수면 시작 summary', () {
      final record = BabyRecord(
        id: 'sleep-1',
        category: RecordCategory.sleep,
        timestamp: DateTime.now(),
        sleepStatus: SleepStatus.start,
      );
      expect(record.summary, '잠듦');
    });

    test('수면 종료 + 시간 summary', () {
      final record = BabyRecord(
        id: 'sleep-2',
        category: RecordCategory.sleep,
        timestamp: DateTime.now(),
        sleepStatus: SleepStatus.end,
        durationMinutes: 90,
      );
      expect(record.summary, '깨어남 (1시간 30분)');
    });

    test('건강 기록 체온 + 약 summary', () {
      final record = BabyRecord(
        id: 'health-1',
        category: RecordCategory.health,
        timestamp: DateTime.now(),
        temperature: 37.5,
        medicine: '타이레놀',
      );
      expect(record.summary, '체온 37.5°C, 약: 타이레놀');
    });

    test('이유식 summary', () {
      final record = BabyRecord(
        id: 'bf-1',
        category: RecordCategory.babyfood,
        timestamp: DateTime.now(),
        amountMl: 80,
        memo: '당근죽',
      );
      expect(record.summary, '이유식 80ml [당근죽]');
    });

    test('목욕 summary', () {
      final record = BabyRecord(
        id: 'bath-1',
        category: RecordCategory.bath,
        timestamp: DateTime.now(),
        durationMinutes: 10,
      );
      expect(record.summary, '목욕 10분');
    });

    test('유축 summary', () {
      final record = BabyRecord(
        id: 'pump-1',
        category: RecordCategory.pumping,
        timestamp: DateTime.now(),
        amountMl: 150,
        durationMinutes: 20,
      );
      expect(record.summary, '유축 150ml 20분');
    });

    test('터미타임 summary', () {
      final record = BabyRecord(
        id: 'tt-1',
        category: RecordCategory.tummytime,
        timestamp: DateTime.now(),
        durationMinutes: 5,
      );
      expect(record.summary, '터미타임 5분');
    });

    test('기타 기록 메모 없으면 기본값', () {
      final record = BabyRecord(
        id: 'other-1',
        category: RecordCategory.other,
        timestamp: DateTime.now(),
      );
      expect(record.summary, '기타 기록');
    });
  });

  group('BabyRecord 카테고리/소스 매핑', () {
    test('모든 카테고리 이름이 비어있지 않음', () {
      for (final cat in RecordCategory.values) {
        final record = BabyRecord(
          id: 'cat-${cat.index}',
          category: cat,
          timestamp: DateTime.now(),
        );
        expect(record.categoryName.isNotEmpty, true, reason: 'categoryName for $cat');
        expect(record.categoryEmoji.isNotEmpty, true, reason: 'categoryEmoji for $cat');
      }
    });

    test('inputSource 매핑 정상', () {
      final sources = ['voice', 'quick', 'guided', 'widget', 'chat', null];
      final expectedIcons = ['🎙️', '⚡', '🔘', '📱', '💬', '💬'];
      final expectedNames = ['음성', '빠른입력', '버튼입력', '위젯', '채팅', '채팅'];

      for (int i = 0; i < sources.length; i++) {
        final record = BabyRecord(
          id: 'src-$i',
          category: RecordCategory.feeding,
          timestamp: DateTime.now(),
          inputSource: sources[i],
        );
        expect(record.inputSourceIcon, expectedIcons[i]);
        expect(record.inputSourceName, expectedNames[i]);
      }
    });
  });
}
