import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📊 외부 데이터셋 기반 NLP 파서 정확도 테스트
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 데이터: ChatBabyTImeSenetence 레포의 라벨링된 데이터
/// - gold CSV: 수동 검증된 69개 문장
/// - full CSV: 규칙 기반 5,108개 문장
///
/// 라벨 매핑 (외부 → NLP 파서):
///   FEEDING_BOTTLE/FEEDING_BREAST → feeding
///   SLEEP → sleep
///   DIAPER/DIAPER_PEE/DIAPER_POO → diaper
///   TEMPERATURE/MEDICATION/VACCINATION/SPITUP → health
///   GROWTH → milestone
///   BATH/OUTING → other
///   CRYING → (무시 — 보조 라벨)
///   APP_META → (무시 — 앱 메타)
///   OTHER → other

void main() {
  /// 외부 라벨 → 파서 RecordCategory 매핑
  RecordCategory? mapLabel(String label) {
    switch (label) {
      case 'FEEDING_BOTTLE':
      case 'FEEDING_BREAST':
        return RecordCategory.feeding;
      case 'SLEEP':
        return RecordCategory.sleep;
      case 'DIAPER':
      case 'DIAPER_PEE':
      case 'DIAPER_POO':
        return RecordCategory.diaper;
      case 'TEMPERATURE':
      case 'MEDICATION':
      case 'VACCINATION':
      case 'SPITUP':
        return RecordCategory.health;
      case 'GROWTH':
        return RecordCategory.milestone;
      case 'BATH':
      case 'OUTING':
        return RecordCategory.other;
      case 'OTHER':
        return RecordCategory.other;
      case 'CRYING':
      case 'APP_META':
        return null; // 보조 라벨 — 매칭 체크에서 제외
      default:
        return null;
    }
  }

  /// 파서 결과에서 카테고리 추출
  RecordCategory? extractCategory(ParseResult result) {
    if (result.record?.category != null) return result.record!.category;
    if (result.pendingRecord?.category != null) return result.pendingRecord!.category;
    if (result.needsFeedingTypeDisambiguation) return RecordCategory.feeding;
    if (result.needsMedicineTypeDisambiguation) return RecordCategory.health;
    if (result.needsStoolDetailInput) return RecordCategory.diaper;
    if (result.needsDisambiguation && result.disambiguationOptions != null && result.disambiguationOptions!.isNotEmpty) {
      return result.disambiguationOptions!.first.category;
    }
    return null;
  }

  /// CSV 파싱 (간단한 CSV — 쉼표 포함 텍스트 없음)
  List<Map<String, String>> parseCsv(String path) {
    final lines = File(path).readAsLinesSync();
    if (lines.isEmpty) return [];
    final headers = lines[0].split(',');
    return lines.skip(1).where((l) => l.trim().isNotEmpty).map((line) {
      // id,text,labels,source — text에 쉼표가 포함될 수 있으므로 주의
      final parts = line.split(',');
      if (parts.length < 4) return <String, String>{};
      final id = parts[0];
      final source = parts.last;
      final labels = parts[parts.length - 2];
      // text는 id 뒤부터 labels 앞까지
      final text = parts.sublist(1, parts.length - 2).join(',');
      return {'id': id, 'text': text, 'labels': labels, 'source': source};
    }).where((m) => m.isNotEmpty).toList();
  }

  /// 테스트 실행 함수
  void runDatasetTest(String name, List<Map<String, String>> data) {
    var total = 0;
    var matched = 0;
    var skipped = 0;
    final failures = <String>[];
    final catStats = <String, List<int>>{}; // [matched, total]

    for (final row in data) {
      final text = row['text'] ?? '';
      final labelsStr = row['labels'] ?? '';
      if (text.isEmpty || labelsStr.isEmpty) continue;

      // 외부 라벨 → 파서 카테고리 집합
      final externalLabels = labelsStr.split('|');
      final expectedCategories = externalLabels
          .map(mapLabel)
          .where((c) => c != null)
          .cast<RecordCategory>()
          .toSet();

      // 모든 라벨이 CRYING/APP_META뿐이면 → other로 기대
      if (expectedCategories.isEmpty) {
        if (externalLabels.every((l) => l == 'CRYING' || l == 'APP_META' || l == 'OTHER')) {
          expectedCategories.add(RecordCategory.other);
        } else {
          skipped++;
          continue;
        }
      }

      total++;
      final result = NlpParser.parse(text);
      final actual = extractCategory(result);

      // 파서의 primary 카테고리가 기대 카테고리 중 하나와 일치하면 성공
      // babyfood/snack은 외부 데이터에 없으므로 feeding과 매칭 허용
      var isMatch = actual != null && expectedCategories.contains(actual);
      // 추가: babyfood/snack → feeding 매핑 허용 (외부 데이터에 babyfood/snack 구분 없음)
      if (!isMatch && actual != null) {
        if ((actual == RecordCategory.babyfood || actual == RecordCategory.snack) &&
            expectedCategories.contains(RecordCategory.feeding)) {
          isMatch = true;
        }
        // SPITUP → health, 하지만 파서가 feeding으로 잡을 수도 (먹다 토함)
        if (actual == RecordCategory.feeding &&
            externalLabels.contains('SPITUP')) {
          isMatch = true;
        }
        // GROWTH → milestone, 하지만 파서가 health로 잡을 수도 (검진)
        if (actual == RecordCategory.health &&
            externalLabels.contains('GROWTH')) {
          isMatch = true;
        }
        // other 계열: BATH/OUTING이 있는데 파서가 다른 primary를 잡은 경우
        // → 복합문에서 다른 카테고리가 primary면 OK
        if (expectedCategories.length > 1 && actual != null) {
          // 복합문에서 파서가 잡은 카테고리가 보조 라벨과 일치하면 OK
          final allMapped = externalLabels.map(mapLabel).where((c) => c != null).toSet();
          if (allMapped.contains(actual)) isMatch = true;
        }
      }

      // 카테고리별 통계
      final primaryLabel = externalLabels.first;
      catStats.putIfAbsent(primaryLabel, () => [0, 0]);
      catStats[primaryLabel]![1]++;

      if (isMatch) {
        matched++;
        catStats[primaryLabel]![0]++;
      } else {
        if (failures.length < 50) {
          failures.add(
            '  ❌ "${text.length > 60 ? '${text.substring(0, 60)}...' : text}" '
            '→ 파서: ${actual?.name ?? "null"}, 기대: $labelsStr',
          );
        }
      }
    }

    final pct = total > 0 ? (matched / total * 100).toStringAsFixed(1) : '0';
    print('\n━━━ $name ━━━');
    print('  전체: $matched/$total ($pct%) [스킵: $skipped]');
    print('');

    // 카테고리별 정확도
    print('  ── 카테고리별 (primary label 기준) ──');
    final sortedCats = catStats.entries.toList()
      ..sort((a, b) => b.value[1].compareTo(a.value[1]));
    for (final entry in sortedCats) {
      final p = entry.value[0];
      final t = entry.value[1];
      final cpct = t > 0 ? (p / t * 100).round() : 0;
      print('  ${entry.key}: $p/$t ($cpct%)');
    }

    if (failures.isNotEmpty) {
      print('');
      print('  ── 실패 샘플 (최대 50건) ──');
      for (final f in failures) print(f);
    }
    print('');
  }

  test('📊 Gold 데이터셋 테스트 (수동 검증 69건)', () {
    final goldPath = '/Users/pes/Desktop/Github/ChatBabyTImeSenetence/data/baby_chat_labeled_gold.csv';
    final data = parseCsv(goldPath);
    print('\n  Gold 데이터 로드: ${data.length}건');
    runDatasetTest('Gold 데이터 (수동 검증)', data);
  });

  test('📊 Full 데이터셋 테스트 (규칙 기반 5,108건)', () {
    final fullPath = '/Users/pes/Desktop/Github/ChatBabyTImeSenetence/data/baby_chat_labeled.csv';
    final data = parseCsv(fullPath);
    print('\n  Full 데이터 로드: ${data.length}건');
    runDatasetTest('Full 데이터 (규칙 기반)', data);
  });
}
