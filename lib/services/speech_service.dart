import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 음성 인식(STT) 서비스
class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;
  String _lastResult = '';
  double _confidence = 0.0;
  String? _errorMessage;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastResult => _lastResult;
  double get confidence => _confidence;
  String? get errorMessage => _errorMessage;

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 음성 인식 초기화
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );

      if (!_isAvailable) {
        _errorMessage = '음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.';
      }
    } catch (e) {
      _isAvailable = false;
      _errorMessage = '음성 인식 초기화 실패: 마이크 권한을 확인해주세요.';
      debugPrint('Speech init error: $e');
    }

    notifyListeners();
    return _isAvailable;
  }

  /// 음성 인식 시작
  Future<void> startListening({
    required Function(String text) onResult,
    Function(String error)? onError,
  }) async {
    _errorMessage = null;

    if (!_isAvailable) {
      await initialize();
    }

    if (!_isAvailable) {
      _errorMessage = '음성 인식을 사용할 수 없습니다.';
      notifyListeners();
      onError?.call(_errorMessage!);
      return;
    }

    _isListening = true;
    _lastResult = '';
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _lastResult = result.recognizedWords;
          _confidence = result.confidence;
          notifyListeners();

          if (result.finalResult) {
            if (_lastResult.isEmpty) {
              _errorMessage = '음성을 인식하지 못했습니다. 다시 시도해주세요.';
              onError?.call(_errorMessage!);
            } else {
              onResult(_lastResult);
            }
            _isListening = false;
            notifyListeners();
          }
        },
        localeId: 'ko_KR',
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
        listenFor: const Duration(seconds: 15),
      );
    } catch (e) {
      _isListening = false;
      _errorMessage = '음성 인식 시작 실패. 다시 시도해주세요.';
      notifyListeners();
      onError?.call(_errorMessage!);
      debugPrint('Speech listen error: $e');
    }
  }

  /// 음성 인식 중지
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Speech stop error: $e');
    }
    _isListening = false;
    notifyListeners();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _onError(dynamic error) {
    _isListening = false;

    // Provide user-friendly error messages
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('no match') || errorStr.contains('nomatch')) {
      _errorMessage = '음성을 인식하지 못했습니다. 다시 말씀해주세요.';
    } else if (errorStr.contains('network')) {
      _errorMessage = '네트워크 오류입니다. 인터넷 연결을 확인해주세요.';
    } else if (errorStr.contains('permission')) {
      _errorMessage = '마이크 권한이 필요합니다. 설정에서 허용해주세요.';
    } else if (errorStr.contains('busy') || errorStr.contains('client')) {
      _errorMessage = '음성 인식이 사용 중입니다. 잠시 후 다시 시도해주세요.';
    } else {
      _errorMessage = '음성 인식 오류가 발생했습니다. 다시 시도해주세요.';
    }

    notifyListeners();
    debugPrint('Speech error: $error');
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
