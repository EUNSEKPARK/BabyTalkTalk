import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

void main() {
  group('시간 "반" 파싱 — 채팅/음성 입력 동등성', () {
    // === 핵심 버그 재현 케이스 ===
    test('"8시반 정우 잤어" → 분 = 30', () {
      final result = NlpParser.parse('8시반 정우 잤어');
      expect(result.isSuccess, true);
      expect(result.record?.category, RecordCategory.sleep);
      expect(result.record?.timestamp.minute, 30,
          reason: '"8시반"은 30분이어야 합니다');
    });

    test('"8시 30분 정우 잤어" (음성 STT 형태) → 분 = 30', () {
      final result = NlpParser.parse('8시 30분 정우 잤어');
      expect(result.record?.timestamp.minute, 30);
    });

    // === 띄어쓰기 변형 ===
    test('"8시 반 정우 잤어" (띄어쓰기) → 분 = 30', () {
      final result = NlpParser.parse('8시 반 정우 잤어');
      expect(result.record?.timestamp.minute, 30);
    });

    test('"8시반잤어" (붙여쓰기) → 분 = 30', () {
      final result = NlpParser.parse('8시반잤어');
      expect(result.record?.timestamp.minute, 30);
    });

    // === 자모 분리 (키보드 IME 버그) ===
    test('"8시바ㄴ 정우 잤어" (자모 분리) → 분 = 30', () {
      final result = NlpParser.parse('8시바ㄴ 정우 잤어');
      expect(result.record?.timestamp.minute, 30,
          reason: '자모 분리된 "바ㄴ"도 "반"으로 처리해야 합니다');
    });

    // === 오전/오후 + 반 ===
    test('"오후 8시반 잤어" → 20:30', () {
      final result = NlpParser.parse('오후 8시반 잤어');
      expect(result.record?.timestamp.hour, 20);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"오전 8시반 분유 120ml 먹었어" → 08:30 수유', () {
      final result = NlpParser.parse('오전 8시반 분유 120ml 먹었어');
      expect(result.isSuccess, true);
      expect(result.record?.category, RecordCategory.feeding);
      expect(result.record?.timestamp.hour, 8);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"밤 10시반 잤어" → 22:30', () {
      final result = NlpParser.parse('밤 10시반 잤어');
      expect(result.record?.timestamp.hour, 22);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"아침 7시반 깼어" → 07:30', () {
      final result = NlpParser.parse('아침 7시반 깼어');
      expect(result.record?.timestamp.hour, 7);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"저녁 6시반 이유식 100ml 먹였어" → 18:30 수유', () {
      final result = NlpParser.parse('저녁 6시반 이유식 100ml 먹였어');
      expect(result.isSuccess, true);
      expect(result.record?.category, RecordCategory.feeding);
      expect(result.record?.timestamp.hour, 18);
      expect(result.record?.timestamp.minute, 30);
    });

    // === 접미사 변형 ===
    test('"3시반에 낮잠 잤어" → 분 = 30', () {
      final result = NlpParser.parse('3시반에 낮잠 잤어');
      expect(result.record?.timestamp.minute, 30);
    });

    test('"4시반부터 낮잠" → 분 = 30', () {
      final result = NlpParser.parse('4시반부터 낮잠');
      expect(result.record?.timestamp.minute, 30);
    });

    test('"12시반쯤 깼어" → 분 = 30', () {
      final result = NlpParser.parse('12시반쯤 깼어');
      expect(result.record?.timestamp.minute, 30);
    });

    // === 다양한 카테고리 ===
    test('"2시반 분유 120ml 먹었어" → 수유, 분 = 30', () {
      final result = NlpParser.parse('2시반 분유 120ml 먹었어');
      expect(result.record?.category, RecordCategory.feeding);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"5시반 기저귀 갈았어" → 기저귀, 분 = 30', () {
      final result = NlpParser.parse('5시반 기저귀 갈았어');
      expect(result.record?.category, RecordCategory.diaper);
      expect(result.record?.timestamp.minute, 30);
    });

    test('"3시반 체온 37.5도" → 건강, 분 = 30', () {
      final result = NlpParser.parse('3시반 체온 37.5도');
      expect(result.record?.category, RecordCategory.health);
      expect(result.record?.timestamp.minute, 30);
    });

    // === 채팅 vs 음성 동등성 ===
    test('채팅("N시반")과 음성("N시 30분") 결과 동일', () {
      for (final hour in [1, 3, 7, 8, 10, 12]) {
        final chatResult = NlpParser.parse('${hour}시반 잤어');
        final voiceResult = NlpParser.parse('${hour}시 30분 잤어');

        expect(chatResult.record?.timestamp.minute, 30,
            reason: '채팅 "${hour}시반" → 30분');
        expect(voiceResult.record?.timestamp.minute, 30,
            reason: '음성 "${hour}시 30분" → 30분');
        expect(
          chatResult.record?.timestamp.minute,
          voiceResult.record?.timestamp.minute,
          reason: '채팅과 음성 결과가 동일해야 합니다 (${hour}시)',
        );
      }
    });
  });
}
