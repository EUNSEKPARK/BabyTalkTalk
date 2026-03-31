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

  /// 한글 숫자 매핑
  static final Map<String, String> koreanNumeralMap = {
    '영': '0',
    '일': '1',
    '이': '2',
    '삼': '3',
    '사': '4',
    '오': '5',
    '육': '6',
    '일곱': '7',
    '팔': '8',
    '구': '9',
    '십': '10',
    '백': '100',
    '천': '1000',
    '만': '10000',
  };

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

  /// 한글 숫자 변환
  static String _convertKoreanNumerals(String text) {
    var result = text;

    // 복합 한글 숫자 (백이십 → 120)
    result = _convertComplexKoreanNumerals(result);

    // 단순 한글 숫자
    koreanNumeralMap.forEach((korean, numeral) {
      result = result.replaceAll(korean, numeral);
    });

    return result;
  }

  /// 복합 한글 숫자 변환 (예: 백이십 → 120)
  static String _convertComplexKoreanNumerals(String text) {
    // 백이십 → 120
    text = text.replaceAll(RegExp(r'백이십'), '120');
    // 백오십 → 150
    text = text.replaceAll(RegExp(r'백오십'), '150');
    // 이백 → 200
    text = text.replaceAll(RegExp(r'이백'), '200');
    // 삼백 → 300
    text = text.replaceAll(RegExp(r'삼백'), '300');
    // 오백 → 500
    text = text.replaceAll(RegExp(r'오백'), '500');

    return text;
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
