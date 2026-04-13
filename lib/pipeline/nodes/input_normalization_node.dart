import 'package:chat_baby_time/pipeline/models/node_result.dart';

/// 입력 정규화 노드
/// - 이모지 제거
/// - 공백 정리
/// - 오타 수정
/// - 한글 숫자 변환
class InputNormalizationNode {
  static const String nodeId = 'input_normalization';
  static const String nodeName = '입력 정규화';

  /// 일반적인 오타 매핑
  static final Map<String, String> typoMap = {
    '기저기': '기저귀',
    '먹엇어': '먹었어',
    '먹엣': '먹었',
    '먹엇': '먹었',
    '자엇': '잤',
    '자엣': '잤',
    '깻': '깼',
    '깣': '깼',
    '똥싸': '똥쌌',
    '수면': '잠',
    '모유수유': '모유',
    '분유수유': '분유',
    '뽀로로': '', // 잡음 제거
    '프로로': '', // 잡음 제거
  };

  /// 한글 숫자 매핑 (단위 컨텍스트에서만 사용)
  /// 주의: 단독 사용 시 "이유식"→"2유식" 등의 오변환 발생하므로
  /// _convertKoreanNumerals()에서 단위와 결합된 경우만 변환
  static final Map<String, int> koreanDigitMap = {
    '일': 1,
    '이': 2,
    '삼': 3,
    '사': 4,
    '오': 5,
    '육': 6,
    '칠': 7,
    '팔': 8,
    '구': 9,
  };

  /// 한글 자릿수 매핑
  static final Map<String, int> koreanPlaceMap = {
    '십': 10,
    '백': 100,
    '천': 1000,
  };

  /// 안전한 한글 숫자 단위 (이 단위 앞에서만 한글 숫자 변환 적용)
  static const List<String> safeUnits = [
    'ml', 'cc', '도', '°', '℃', '분', '시간', '개', '숟가락', '스푼', '번',
  ];

  /// 입력 정규화 실행
  static NodeResult<NormalizedInput> run(String rawInput) {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 이모지 제거
      var normalized = _removeEmojis(rawInput);

      // 2. 공백 정리
      normalized = _normalizeWhitespace(normalized);

      // 3. 오타 수정
      final corrections = <String>[];
      normalized = _correctTypos(normalized, corrections);

      // 4. 한글 숫자 변환
      normalized = _convertKoreanNumerals(normalized);

      // 5. 반복 문자 정리 (예: 아~~, 으~~~)
      normalized = _removeRepeatedCharacters(normalized);

      stopwatch.stop();

      final result = NormalizedInput(
        text: normalized,
        corrections: corrections,
        originalLength: rawInput.length,
        normalizedLength: normalized.length,
      );

      return NodeResult.success(
        data: result,
        debugInfo: {
          'corrections': corrections.length,
          'removedEmojis': rawInput.length - normalized.length,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return NodeResult.failure(
        error: '입력 정규화 실패: ${e.toString()}',
        debugInfo: {'error': e.toString()},
      );
    }
  }

  /// 이모지 제거
  static String _removeEmojis(String text) {
    // 이모지 범위: U+1F300 ~ U+1F9FF, U+2600 ~ U+27BF 등
    return text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]',
        unicode: true,
      ),
      '',
    );
  }

  /// 공백 정규화 (연속 공백 → 단일 공백, 앞뒤 공백 제거)
  static String _normalizeWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 오타 수정
  static String _correctTypos(
    String text,
    List<String> corrections,
  ) {
    var result = text;
    typoMap.forEach((typo, correction) {
      if (result.contains(typo)) {
        result = result.replaceAll(typo, correction);
        corrections.add('$typo → $correction');
      }
    });
    return result;
  }

  /// 한글 숫자 변환 (단위 컨텍스트에서만 안전하게 변환)
  ///
  /// "백오십ml" → "150ml", "삼십분" → "30분" 처리
  /// "이유식", "오줌" 같은 일반 단어는 변환하지 않음
  static String _convertKoreanNumerals(String text) {
    var result = text;

    // 단위 앞의 한글 숫자 조합을 찾아서 변환
    final unitPattern = safeUnits.map(RegExp.escape).join('|');

    // 패턴: 한글숫자조합 + 단위
    // 예: "백오십ml", "이백cc", "삼십분", "오도"
    final koreanDigits = koreanDigitMap.keys.join('|');
    final koreanPlaces = koreanPlaceMap.keys.join('|');
    final koreanNumChars = '(?:$koreanDigits|$koreanPlaces)';

    final regex = RegExp('($koreanNumChars+)\\s*($unitPattern)');

    result = result.replaceAllMapped(regex, (match) {
      final koreanNum = match.group(1)!;
      final unit = match.group(2)!;
      final parsed = _parseKoreanNumber(koreanNum);
      if (parsed != null && parsed > 0) {
        return '$parsed$unit';
      }
      return match.group(0)!; // 파싱 실패 시 원본 유지
    });

    return result;
  }

  /// 한글 숫자열을 정수로 파싱
  ///
  /// "백오십" → 150, "이백삼십" → 230, "삼십" → 30, "오" → 5
  static int? _parseKoreanNumber(String koreanNum) {
    if (koreanNum.isEmpty) return null;

    int total = 0;
    int current = 0;

    for (int i = 0; i < koreanNum.length;) {
      bool matched = false;

      // 2글자 매칭 먼저 시도 (없음 - 현재는 모두 1글자)
      // 1글자 매칭
      final char = koreanNum[i];

      if (koreanDigitMap.containsKey(char)) {
        current = koreanDigitMap[char]!;
        matched = true;
        i += 1;
      } else if (koreanPlaceMap.containsKey(char)) {
        final place = koreanPlaceMap[char]!;
        if (current == 0) {
          // "백" = 1 * 100, "십" = 1 * 10
          current = 1;
        }
        total += current * place;
        current = 0;
        matched = true;
        i += 1;
      }

      if (!matched) {
        return null; // 파싱할 수 없는 문자
      }
    }

    total += current; // 남은 1의 자리 수 추가
    return total > 0 ? total : null;
  }

  /// 반복 문자 정리 (아~~~ → 아, 으~~~ → 으)
  static String _removeRepeatedCharacters(String text) {
    return text.replaceAll(RegExp(r'([가-힣])\1{2,}'), '\$1');
  }
}

/// 정규화된 입력 정보
class NormalizedInput {
  /// 정규화된 텍스트
  final String text;

  /// 적용된 오타 수정 목록
  final List<String> corrections;

  /// 원본 텍스트 길이
  final int originalLength;

  /// 정규화된 텍스트 길이
  final int normalizedLength;

  NormalizedInput({
    required this.text,
    required this.corrections,
    required this.originalLength,
    required this.normalizedLength,
  });

  /// 정규화 여부 확인
  bool get wasModified => originalLength != normalizedLength || corrections.isNotEmpty;

  @override
  String toString() => text;
}
