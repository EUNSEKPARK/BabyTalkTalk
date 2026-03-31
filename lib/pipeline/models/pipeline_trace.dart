/// 파이프라인 스텝 정보
class PipelineStep {
  /// 노드 아이디
  final String nodeId;

  /// 노드 이름
  final String nodeName;

  /// 실행 성공 여부
  final bool success;

  /// 결과 데이터 (JSON 직렬화 가능)
  final dynamic data;

  /// 에러 메시지
  final String? error;

  /// 재질문 텍스트
  final String? suggestion;

  /// 디버그 정보
  final Map<String, dynamic> debugInfo;

  /// 실행 시간 (밀리초)
  final int durationMs;

  PipelineStep({
    required this.nodeId,
    required this.nodeName,
    required this.success,
    this.data,
    this.error,
    this.suggestion,
    Map<String, dynamic>? debugInfo,
    this.durationMs = 0,
  }) : debugInfo = debugInfo ?? {};

  @override
  String toString() {
    return 'PipelineStep($nodeId: $nodeName, success: $success, durationMs: $durationMs)';
  }
}

/// 파이프라인 실행 추적 정보
class PipelineTrace {
  /// 각 스텝의 실행 결과
  final List<PipelineStep> steps;

  /// 전체 시작 시간
  final DateTime startTime;

  /// 전체 종료 시간
  DateTime? endTime;

  PipelineTrace({
    List<PipelineStep>? steps,
    DateTime? startTime,
  })  : steps = steps ?? [],
        startTime = startTime ?? DateTime.now();

  /// 스텝 추가
  void addStep(PipelineStep step) {
    steps.add(step);
  }

  /// 추적 완료 표시
  void complete() {
    endTime = DateTime.now();
  }

  /// 전체 실행 시간 (밀리초)
  int get totalDurationMs {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMilliseconds;
  }

  /// 성공한 스텝 개수
  int get successCount => steps.where((s) => s.success).length;

  /// 실패한 스텝 개수
  int get failureCount => steps.where((s) => !s.success).length;

  /// 첫 실패 스텝 찾기
  PipelineStep? get firstFailure {
    for (final s in steps) {
      if (!s.success) return s;
    }
    return null;
  }

  /// 예쁜 출력 (디버깅용)
  String prettyPrint() {
    final buffer = StringBuffer();
    buffer.writeln('═' * 60);
    buffer.writeln('NLP Pipeline Trace');
    buffer.writeln('═' * 60);
    buffer.writeln('Start Time: $startTime');
    if (endTime != null) {
      buffer.writeln('End Time: $endTime');
      buffer.writeln('Total Duration: ${totalDurationMs}ms');
    }
    buffer.writeln('Steps: ${steps.length} (${successCount} success, ${failureCount} failed)');
    buffer.writeln('─' * 60);

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final status = step.success ? '✓' : '✗';
      buffer.writeln('$i. [$status] ${step.nodeId}: ${step.nodeName} (${step.durationMs}ms)');
      if (step.data != null) {
        buffer.writeln('   Data: ${step.data}');
      }
      if (step.error != null) {
        buffer.writeln('   Error: ${step.error}');
      }
      if (step.suggestion != null) {
        buffer.writeln('   Suggestion: ${step.suggestion}');
      }
      if (step.debugInfo.isNotEmpty) {
        buffer.writeln('   Debug: ${step.debugInfo}');
      }
    }

    buffer.writeln('═' * 60);
    return buffer.toString();
  }

  /// JSON 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalDurationMs': totalDurationMs,
      'steps': steps.map((step) {
        return {
          'nodeId': step.nodeId,
          'nodeName': step.nodeName,
          'success': step.success,
          'data': step.data,
          'error': step.error,
          'suggestion': step.suggestion,
          'durationMs': step.durationMs,
          'debugInfo': step.debugInfo,
        };
      }).toList(),
    };
  }
}
