/// 파이프라인 노드의 제네릭 결과 클래스
class NodeResult<T> {
  /// 노드 실행 성공 여부
  final bool success;

  /// 결과 데이터
  final T? data;

  /// 에러 메시지
  final String? error;

  /// 재질문 텍스트 (사용자에게 다시 묻기 위한 제안)
  final String? suggestion;

  /// 디버그 정보
  final Map<String, dynamic> debugInfo;

  NodeResult({
    required this.success,
    this.data,
    this.error,
    this.suggestion,
    Map<String, dynamic>? debugInfo,
  }) : debugInfo = debugInfo ?? {};

  /// 성공한 결과 생성
  factory NodeResult.success({
    required T data,
    Map<String, dynamic>? debugInfo,
  }) {
    return NodeResult(
      success: true,
      data: data,
      debugInfo: debugInfo,
    );
  }

  /// 실패한 결과 생성
  factory NodeResult.failure({
    required String error,
    String? suggestion,
    Map<String, dynamic>? debugInfo,
  }) {
    return NodeResult(
      success: false,
      error: error,
      suggestion: suggestion,
      debugInfo: debugInfo,
    );
  }

  /// 결과를 다른 타입으로 변환 (성공 시)
  NodeResult<R> map<R>(R Function(T) mapper) {
    if (!success || data == null) {
      return NodeResult(
        success: false,
        error: error,
        suggestion: suggestion,
        debugInfo: debugInfo,
      );
    }
    return NodeResult.success(
      data: mapper(data as T),
      debugInfo: debugInfo,
    );
  }

  @override
  String toString() {
    return 'NodeResult<$T>(success: $success, data: $data, error: $error, suggestion: $suggestion)';
  }
}
