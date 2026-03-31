import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/widgets/guided_record_button_bar.dart';
import 'package:chat_baby_time/widgets/guided_record_button_section.dart';

void main() {
  group('GuidedRecordButtonBar.composePhrase', () {
    test('분유 + ml', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.feeding,
          feedingKind: FeedingType.formula,
          formulaMl: 120,
          timePrefix: '5분 전 ',
        ),
        '5분 전 분유 120ml 먹었어',
      );
    });

    test('모유 분·건너뛰기', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.feeding,
          feedingKind: FeedingType.breast,
          breastDurationMinutes: 12,
          timePrefix: '방금 ',
        ),
        '방금 모유 12분 수유했어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.feeding,
          feedingKind: FeedingType.breast,
          timePrefix: '15분 전 ',
        ),
        '15분 전 모유 수유했어',
      );
    });

    test('간식 g·건너뛰기', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.snack,
          snackGram: 25,
          timePrefix: '방금 ',
        ),
        '방금 간식 25g 먹었어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.snack,
          timePrefix: '',
        ),
        '간식 먹었어',
      );
    });

    test('수면 분·건너뛰기', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.sleep,
          sleepDurationMinutes: 45,
          timePrefix: '5분 전 ',
        ),
        '5분 전 45분 잤어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.sleep,
          timePrefix: '방금 ',
        ),
        '방금 잠들었어',
      );
    });

    test('건강 체온·약', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.health,
          healthKind: GuidedHealthKind.temperature,
          healthTemperature: 37.5,
          timePrefix: '방금 ',
        ),
        '방금 체온 37.5도 재었어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.health,
          healthKind: GuidedHealthKind.medicine,
          healthMedicineName: '해열제',
          timePrefix: '',
        ),
        '해열제 먹였어',
      );
    });

    test('기저귀 소변·응가·둘 다', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.diaper,
          diaperKind: DiaperType.pee,
          timePrefix: '방금 ',
        ),
        '방금 소변 기저귀 갈았어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.diaper,
          diaperKind: DiaperType.poop,
          timePrefix: '',
        ),
        '기저귀 갈았어 응가',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.diaper,
          diaperKind: DiaperType.both,
          timePrefix: '30분 전 ',
        ),
        '30분 전 소변 대변 기저귀 갈았어',
      );
    });

    test('이유식 그램·건너뛰기', () {
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.babyfood,
          babyfoodGram: 80,
          timePrefix: '방금 ',
        ),
        '방금 이유식 80g 먹었어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.babyfood,
          babyfoodGram: 120,
          timePrefix: '',
        ),
        '이유식 120g 먹었어',
      );
      expect(
        GuidedRecordButtonBar.composePhrase(
          category: RecordCategory.babyfood,
          babyfoodGram: null,
          timePrefix: '15분 전 ',
        ),
        '15분 전 이유식 먹었어',
      );
    });
  });

  group('GuidedRecordButtonBar.showsTimeRow', () {
    test('이유식은 그램 단계 전에는 시간 행 숨김', () {
      expect(
        GuidedRecordButtonBar.showsTimeRow(
          category: RecordCategory.babyfood,
          healthKind: null,
          healthExtraDone: true,
          feedingKind: null,
          formulaMlDone: true,
          breastDurationDone: true,
          diaperKind: null,
          babyfoodGramDone: false,
          snackGramDone: true,
          sleepDurationDone: true,
        ),
        false,
      );
      expect(
        GuidedRecordButtonBar.showsTimeRow(
          category: RecordCategory.babyfood,
          healthKind: null,
          healthExtraDone: true,
          feedingKind: null,
          formulaMlDone: true,
          breastDurationDone: true,
          diaperKind: null,
          babyfoodGramDone: true,
          snackGramDone: true,
          sleepDurationDone: true,
        ),
        true,
      );
    });

    test('모유는 수유 분 단계 전에는 시간 행 숨김', () {
      expect(
        GuidedRecordButtonBar.showsTimeRow(
          category: RecordCategory.feeding,
          healthKind: null,
          healthExtraDone: true,
          feedingKind: FeedingType.breast,
          formulaMlDone: true,
          breastDurationDone: false,
          diaperKind: null,
          babyfoodGramDone: true,
          snackGramDone: true,
          sleepDurationDone: true,
        ),
        false,
      );
    });

    test('간식·수면·건강 세부 전에는 시간 행 숨김', () {
      expect(
        GuidedRecordButtonBar.showsTimeRow(
          category: RecordCategory.snack,
          healthKind: null,
          healthExtraDone: true,
          feedingKind: null,
          formulaMlDone: true,
          breastDurationDone: true,
          diaperKind: null,
          babyfoodGramDone: true,
          snackGramDone: false,
          sleepDurationDone: true,
        ),
        false,
      );
      expect(
        GuidedRecordButtonBar.showsTimeRow(
          category: RecordCategory.sleep,
          healthKind: null,
          healthExtraDone: true,
          feedingKind: null,
          formulaMlDone: true,
          breastDurationDone: true,
          diaperKind: null,
          babyfoodGramDone: true,
          snackGramDone: true,
          sleepDurationDone: false,
        ),
        false,
      );
      expect(
        GuidedRecordButtonBar.showsTimeRow(
          category: RecordCategory.health,
          healthKind: GuidedHealthKind.temperature,
          healthExtraDone: false,
          feedingKind: null,
          formulaMlDone: true,
          breastDurationDone: true,
          diaperKind: null,
          babyfoodGramDone: true,
          snackGramDone: true,
          sleepDurationDone: true,
        ),
        false,
      );
    });
  });

  group('GuidedRecordButtonSection', () {
    testWidgets('수유→분유→120ml→방금 제출 문장', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuidedRecordButtonSection(
                padding: EdgeInsets.zero,
                onPhraseSubmit: (p) => submitted = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('수유'));
      await tester.pump();
      await tester.tap(find.text('분유'));
      await tester.pump();
      await tester.tap(find.text('120ml'));
      await tester.pump();
      await tester.tap(find.text('방금'));
      await tester.pump();

      expect(submitted, '방금 분유 120ml 먹었어');
    });

    testWidgets('수유→모유→건너뛰기→방금', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuidedRecordButtonSection(
                padding: EdgeInsets.zero,
                onPhraseSubmit: (p) => submitted = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('수유'));
      await tester.pump();
      await tester.tap(find.text('모유'));
      await tester.pump();
      await tester.tap(find.text('건너뛰기'));
      await tester.pump();
      await tester.tap(find.text('방금'));
      await tester.pump();

      expect(submitted, '방금 모유 수유했어');
    });

    testWidgets('이유식→80g→5분 전', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuidedRecordButtonSection(
                padding: EdgeInsets.zero,
                onPhraseSubmit: (p) => submitted = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('이유식'));
      await tester.pump();
      await tester.tap(find.text('80g'));
      await tester.pump();
      await tester.tap(find.text('5분 전'));
      await tester.pump();

      expect(submitted, '5분 전 이유식 80g 먹었어');
    });

    testWidgets('분유 직접 입력 ml → 방금', (tester) async {
      final binding = tester.view;
      binding.physicalSize = const Size(1400, 900);
      binding.devicePixelRatio = 1.0;
      addTearDown(binding.resetPhysicalSize);
      addTearDown(binding.resetDevicePixelRatio);

      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuidedRecordButtonSection(
                padding: EdgeInsets.zero,
                onPhraseSubmit: (p) => submitted = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('수유'));
      await tester.pump();
      await tester.tap(find.text('분유'));
      await tester.pump();
      await tester.ensureVisible(find.text('직접 입력'));
      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '95');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('방금'));
      await tester.pump();

      expect(submitted, '방금 분유 95ml 먹었어');
    });

    testWidgets('이유식 직접 입력 g → 방금', (tester) async {
      final binding = tester.view;
      binding.physicalSize = const Size(1400, 900);
      binding.devicePixelRatio = 1.0;
      addTearDown(binding.resetPhysicalSize);
      addTearDown(binding.resetDevicePixelRatio);

      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuidedRecordButtonSection(
                padding: EdgeInsets.zero,
                onPhraseSubmit: (p) => submitted = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('이유식'));
      await tester.pump();
      await tester.ensureVisible(find.text('직접 입력'));
      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '65');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('방금'));
      await tester.pump();

      expect(submitted, '방금 이유식 65g 먹었어');
    });
  });
}
