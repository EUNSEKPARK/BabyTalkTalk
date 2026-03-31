import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'beta_generator/mass_test_generator.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🏭 대량 베타 테스트 v3 (100 페르소나 × 10,000+ 문장)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///
/// 실행: flutter test test/beta_mass_test.dart
///
/// 생성된 문장은 seed 기반이므로 재현 가능합니다.
/// 결과는 test/beta_logs/ 에 자동 저장됩니다.
///
void main() {
  final catMap = <String, RecordCategory>{
    'feeding': RecordCategory.feeding,
    'sleep': RecordCategory.sleep,
    'diaper': RecordCategory.diaper,
    'health': RecordCategory.health,
    'babyfood': RecordCategory.babyfood,
    'snack': RecordCategory.snack,
    'milestone': RecordCategory.milestone,
    'other': RecordCategory.other,
  };

  RecordCategory? extractCategory(ParseResult result) {
    if (result.record?.category != null) return result.record!.category;
    if (result.pendingRecord?.category != null) return result.pendingRecord!.category;
    if (result.needsFeedingTypeDisambiguation) return RecordCategory.feeding;
    if (result.needsMedicineTypeDisambiguation) return RecordCategory.health;
    if (result.needsStoolDetailInput) return RecordCategory.diaper;
    if (result.needsDisambiguation && result.disambiguationOptions!.isNotEmpty) {
      return result.disambiguationOptions!.first.category;
    }
    return null;
  }

  String resultLabel(ParseResult result) {
    if (result.record != null) return '확정';
    if (result.pendingRecord != null) {
      if (result.needsAmountInput) return '양/시간 질문';
      if (result.needsStoolDetailInput) return '대변상세 질문';
      return 'pending';
    }
    if (result.needsFeedingTypeDisambiguation) return '수유타입 질문';
    if (result.needsMedicineTypeDisambiguation) return '약종류 질문';
    if (result.needsDisambiguation) return '객관식';
    return 'unknown';
  }

  // ═══════════════════════════════════════════════════════════
  //  테스트 케이스 생성 (seed=42 → 재현 가능)
  // ═══════════════════════════════════════════════════════════
  final testCases = generateMassTestCases(
    sentencesPerPersona: 500,
    otherNonRecordRatio: 0.15,
    seed: 42,
  );

  // ═══════════════════════════════════════════════════════════
  //  페르소나 그룹별 flutter_test 등록
  // ═══════════════════════════════════════════════════════════
  final grouped = <String, List<GeneratedTestCase>>{};
  for (final tc in testCases) {
    final key = '${tc.personaId} ${tc.personaName}';
    grouped.putIfAbsent(key, () => []).add(tc);
  }

  for (final entry in grouped.entries) {
    group('🧪 ${entry.key}', () {
      for (var i = 0; i < entry.value.length; i++) {
        final tc = entry.value[i];
        test('#${i + 1} "${tc.input}" → ${tc.expectedCategory}', () {
          final result = NlpParser.parse(tc.input);
          final expected = catMap[tc.expectedCategory];
          final actual = extractCategory(result);
          expect(
            actual,
            expected,
            reason: '❌ "${tc.input}" → 기대: ${tc.expectedCategory}, '
                '실제: ${actual?.name ?? "null"} '
                '[${resultLabel(result)}] '
                '(${(result.confidence * 100).round()}%)',
          );
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  📊 전체 시뮬레이션 결과 요약 + 로그 저장
  // ═══════════════════════════════════════════════════════════
  test('📊 대량 베타 테스트 전체 결과 + 로그 저장', () {
    var total = 0;
    var passed = 0;

    // 페르소나별 통계
    final personaStats = <String, List<int>>{}; // [passed, total]
    // 카테고리별 통계
    final catStats = <String, List<int>>{};
    // 실패 목록
    final failures = <Map<String, String>>[];
    // 전체 결과 (샘플링)
    final sampleResults = <String>[];

    final catEmoji = {
      'feeding': '🍼', 'sleep': '😴', 'diaper': '🧷',
      'health': '🏥', 'babyfood': '🥣', 'snack': '🍎',
      'other': '📝', 'milestone': '⭐',
    };

    final catNames = {
      'feeding': '🍼 수유', 'sleep': '😴 수면', 'diaper': '🧷 기저귀',
      'health': '🏥 건강', 'babyfood': '🥣 이유식', 'snack': '🍎 간식',
      'other': '📝 기타', 'milestone': '⭐ 성장',
    };

    for (final tc in testCases) {
      total++;
      final expected = catMap[tc.expectedCategory];
      final result = NlpParser.parse(tc.input);
      final actual = extractCategory(result);
      final label = resultLabel(result);
      final ok = actual == expected;
      final emoji = catEmoji[actual?.name] ?? '❓';
      final confPct = result.confidence > 0
          ? '${(result.confidence * 100).round()}%'
          : (result.pendingRecord != null ? '확정' : '0%');

      final personaKey = '${tc.personaId} ${tc.personaName}';
      personaStats.putIfAbsent(personaKey, () => [0, 0]);
      personaStats[personaKey]![1]++;
      catStats.putIfAbsent(tc.expectedCategory, () => [0, 0]);
      catStats[tc.expectedCategory]![1]++;

      if (ok) {
        passed++;
        personaStats[personaKey]![0]++;
        catStats[tc.expectedCategory]![0]++;
      } else {
        failures.add({
          'persona': personaKey,
          'input': tc.input,
          'expected': tc.expectedCategory,
          'actual': actual?.name ?? 'null',
          'label': label,
          'confidence': confPct,
        });
      }

      // 결과 샘플 (처음 500개 + 모든 실패)
      if (total <= 500 || !ok) {
        final mark = ok ? '✅' : '❌';
        sampleResults.add(
          '  $mark [$personaKey] "${tc.input}" → $emoji ${tc.expectedCategory} '
          '${ok ? "" : "(실제: ${actual?.name})"} [$label] ($confPct)',
        );
      }
    }

    final pct = (passed / total * 100).toStringAsFixed(1);
    final now = DateTime.now();
    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // ─── 콘솔 출력 ───
    print('\n');
    print('━' * 90);
    print('  🏭 대량 베타 테스트 결과 v3 (100 페르소나 × ${testCases.length} 문장)');
    print('━' * 90);
    print('  전체: $passed/$total ($pct%)');
    print('  실패: ${failures.length}개');
    print('');

    // 페르소나별 요약 (실패가 있는 페르소나만 표시)
    final failedPersonas = personaStats.entries
        .where((e) => e.value[0] < e.value[1])
        .toList()
      ..sort((a, b) => (a.value[0] / a.value[1]).compareTo(b.value[0] / b.value[1]));

    if (failedPersonas.isNotEmpty) {
      print('  ── 실패 발생 페르소나 (${failedPersonas.length}명) ──');
      for (final entry in failedPersonas.take(20)) {
        final p = entry.value[0];
        final t = entry.value[1];
        final tpct = (p / t * 100).round();
        print('  ${entry.key}: $p/$t ($tpct%)');
      }
      if (failedPersonas.length > 20) {
        print('  ... 외 ${failedPersonas.length - 20}명');
      }
      print('');
    }

    // 카테고리별 정확도
    print('  ── 카테고리별 정확도 ──');
    for (final cat in catStats.keys) {
      final p = catStats[cat]![0];
      final t = catStats[cat]![1];
      final cpct = t > 0 ? (p / t * 100).round() : 0;
      final eName = catNames[cat] ?? cat;
      final bar = '█' * (cpct ~/ 5) + '░' * (20 - cpct ~/ 5);
      print('  $eName: $p/$t ($cpct%) $bar');
    }

    if (failures.isNotEmpty) {
      print('');
      print('  ── 실패 샘플 (최대 50개) ──');
      for (final f in failures.take(50)) {
        print('  ❌ [${f['persona']}] "${f['input']}" → 기대: ${f['expected']}, 실제: ${f['actual']} [${f['label']}] (${f['confidence']})');
      }
      if (failures.length > 50) {
        print('  ... 외 ${failures.length - 50}건');
      }
    } else {
      print('');
      print('  🎉 10,000+ 문장 전체 통과!');
    }
    print('━' * 90);

    // ─── 로그 파일 저장 ───
    final logDir = Directory('test/beta_logs');
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }

    // 1) 전체 요약 로그
    final summaryBuf = StringBuffer();
    summaryBuf.writeln('━' * 50);
    summaryBuf.writeln('🏭 대량 베타 테스트 결과 v3');
    summaryBuf.writeln('실행 시각: $now');
    summaryBuf.writeln('Seed: 42');
    summaryBuf.writeln('━' * 50);
    summaryBuf.writeln('');
    summaryBuf.writeln('전체: $passed/$total ($pct%)');
    summaryBuf.writeln('실패: ${failures.length}개');
    summaryBuf.writeln('');

    summaryBuf.writeln('── 카테고리별 정확도 ──');
    for (final cat in catStats.keys) {
      final p = catStats[cat]![0];
      final t = catStats[cat]![1];
      final cpct = t > 0 ? (p / t * 100).round() : 0;
      final eName = catNames[cat] ?? cat;
      summaryBuf.writeln('  $eName: $p/$t ($cpct%)');
    }
    summaryBuf.writeln('');

    summaryBuf.writeln('── 페르소나별 정확도 ──');
    for (final entry in personaStats.entries) {
      final p = entry.value[0];
      final t = entry.value[1];
      final tpct = (p / t * 100).round();
      summaryBuf.writeln('  ${entry.key}: $p/$t ($tpct%)');
    }

    File('test/beta_logs/mass_summary_$timestamp.log')
        .writeAsStringSync(summaryBuf.toString());

    // 2) 실패 전용 로그 (전체)
    if (failures.isNotEmpty) {
      final failBuf = StringBuffer();
      failBuf.writeln('━' * 50);
      failBuf.writeln('❌ 대량 테스트 실패 항목 (NLP 파서 개선용)');
      failBuf.writeln('실행 시각: $now');
      failBuf.writeln('총 실패: ${failures.length}/$total ($pct% 통과)');
      failBuf.writeln('━' * 50);
      failBuf.writeln('');

      // 카테고리별 실패 분류
      final failByCategory = <String, List<Map<String, String>>>{};
      for (final f in failures) {
        failByCategory.putIfAbsent(f['expected']!, () => []).add(f);
      }

      for (final cat in failByCategory.keys) {
        final catFails = failByCategory[cat]!;
        final eName = catNames[cat] ?? cat;
        failBuf.writeln('── $eName 실패 (${catFails.length}건) ──');
        for (final f in catFails) {
          failBuf.writeln('  ❌ [${f['persona']}] "${f['input']}" → 실제: ${f['actual']} [${f['label']}] (${f['confidence']})');
        }
        failBuf.writeln('');
      }

      failBuf.writeln('');
      failBuf.writeln('💡 이 파일을 Claude에게 붙여넣기하면 자동 개선 가능');

      File('test/beta_logs/mass_failures_$timestamp.log')
          .writeAsStringSync(failBuf.toString());
    }

    // 3) 전체 입력 로그 (샘플)
    final sampleBuf = StringBuffer();
    sampleBuf.writeln('━' * 50);
    sampleBuf.writeln('📋 대량 테스트 입력 로그 (샘플 + 전체 실패)');
    sampleBuf.writeln('실행 시각: $now');
    sampleBuf.writeln('━' * 50);
    sampleBuf.writeln('');
    for (final row in sampleResults) {
      sampleBuf.writeln(row);
    }

    File('test/beta_logs/mass_samples_$timestamp.log')
        .writeAsStringSync(sampleBuf.toString());

    // 4) 실패 패턴 분석 로그
    if (failures.isNotEmpty) {
      final patternBuf = StringBuffer();
      patternBuf.writeln('━' * 50);
      patternBuf.writeln('🔍 실패 패턴 분석');
      patternBuf.writeln('실행 시각: $now');
      patternBuf.writeln('━' * 50);
      patternBuf.writeln('');

      // expected→actual 매핑별 카운트
      final confusionMap = <String, int>{};
      for (final f in failures) {
        final key = '${f['expected']} → ${f['actual']}';
        confusionMap[key] = (confusionMap[key] ?? 0) + 1;
      }

      final sortedConfusion = confusionMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      patternBuf.writeln('── 혼동 패턴 (기대 → 실제) ──');
      for (final entry in sortedConfusion) {
        patternBuf.writeln('  ${entry.key}: ${entry.value}건');
      }
      patternBuf.writeln('');

      // 실패가 많은 페르소나 Top 10
      patternBuf.writeln('── 실패 다발 페르소나 Top 10 ──');
      final personaFailCount = <String, int>{};
      for (final f in failures) {
        personaFailCount[f['persona']!] =
            (personaFailCount[f['persona']!] ?? 0) + 1;
      }
      final sortedPersonaFails = personaFailCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedPersonaFails.take(10)) {
        patternBuf.writeln('  ${entry.key}: ${entry.value}건');
      }

      File('test/beta_logs/mass_patterns_$timestamp.log')
          .writeAsStringSync(patternBuf.toString());
    }

    print('');
    print('  📁 로그 저장 완료 → test/beta_logs/');
    print('     mass_summary_$timestamp.log    (전체 요약)');
    print('     mass_samples_$timestamp.log    (입력 샘플)');
    if (failures.isNotEmpty) {
      print('     mass_failures_$timestamp.log   (실패 항목)');
      print('     mass_patterns_$timestamp.log   (실패 패턴 분석)');
    }
    print('');
  });
}
