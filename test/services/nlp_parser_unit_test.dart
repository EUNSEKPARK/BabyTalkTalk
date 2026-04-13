import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

void main() {
  group('NlpParser.parse - 카테고리 감지', () {
    test('분유 120ml → 수유(분유)', () {
      final result = NlpParser.parse('분유 120ml 먹었어');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.feeding);
      expect(result.record!.feedingType, FeedingType.formula);
      expect(result.record!.amountMl, 120);
    });

    test('모유 수유 15분 → 수유(모유)', () {
      final result = NlpParser.parse('모유 수유 15분');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.feeding);
      expect(result.record!.feedingType, FeedingType.breast);
      expect(result.record!.durationMinutes, 15);
    });

    test('기저귀 갈았어 응가 → 기저귀(대변)', () {
      final result = NlpParser.parse('기저귀 갈았어 응가');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.diaper);
      expect(result.record!.diaperType, DiaperType.poop);
    });

    test('기저귀 쉬 → 기저귀(소변)', () {
      final result = NlpParser.parse('기저귀 쉬했어');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.diaper);
      expect(result.record!.diaperType, DiaperType.pee);
    });

    test('아기 잠들었어 → 수면(시작)', () {
      final result = NlpParser.parse('아기 잠들었어');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.sleep);
      expect(result.record!.sleepStatus, SleepStatus.start);
    });

    test('아기 깼어 → 수면(종료)', () {
      final result = NlpParser.parse('아기 깼어');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.sleep);
      expect(result.record!.sleepStatus, SleepStatus.end);
    });

    test('체온 37.5도 → 건강', () {
      final result = NlpParser.parse('체온 37.5도');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.health);
      expect(result.record!.temperature, 37.5);
    });

    test('이유식 80ml 당근죽 → 이유식', () {
      final result = NlpParser.parse('이유식 80ml 당근죽');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.babyfood);
    });

    test('목욕 10분 → 목욕', () {
      final result = NlpParser.parse('목욕 10분');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.bath);
      expect(result.record!.durationMinutes, 10);
    });

    test('빈 입력 → 실패', () {
      final result = NlpParser.parse('');
      expect(result.isSuccess, false);
    });

    test('공백만 입력 → 실패', () {
      final result = NlpParser.parse('   ');
      expect(result.isSuccess, false);
    });
  });

  group('NlpParser.parse - 시간 파싱', () {
    test('오후 2시에 분유 → 14시 타임스탬프', () {
      final result = NlpParser.parse('오후 2시에 분유 100ml');
      expect(result.isSuccess, true);
      expect(result.record!.timestamp.hour, 14);
    });

    test('오전 8시 30분 모유 → 8시 30분', () {
      final result = NlpParser.parse('오전 8시 30분 모유 수유');
      expect(result.isSuccess, true);
      expect(result.record!.timestamp.hour, 8);
      expect(result.record!.timestamp.minute, 30);
    });
  });

  group('NlpParser.parse - 엣지 케이스', () {
    test('유축 150ml 20분 → 유축 or 수유', () {
      final result = NlpParser.parse('유축 150ml 20분');
      expect(result.isSuccess, true);
      // 유축은 pumping 카테고리
      expect(
        result.record!.category == RecordCategory.pumping ||
        result.record!.category == RecordCategory.feeding,
        true,
      );
    });

    test('완분 100 → 분유 수유', () {
      final result = NlpParser.parse('완분 100');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.feeding);
    });

    test('터미타임 5분 → 터미타임', () {
      final result = NlpParser.parse('터미타임 5분');
      expect(result.isSuccess, true);
      expect(result.record!.category, RecordCategory.tummytime);
    });
  });
}
