import 'package:flutter/material.dart';
import 'package:chat_baby_time/services/speech_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 메인 화면 하단의 스마트 입력바
/// 텍스트 입력 + 음성 입력 버튼을 제공
class SmartInputBar extends StatefulWidget {
  final TextEditingController controller;
  final SpeechService speechService;
  final Function(String text) onSubmit;

  const SmartInputBar({
    super.key,
    required this.controller,
    required this.speechService,
    required this.onSubmit,
  });

  @override
  State<SmartInputBar> createState() => _SmartInputBarState();
}

class _SmartInputBarState extends State<SmartInputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showHint = true;

  final List<String> _hints = [
    '베비에게 말해보세요...',
    '"분유 120ml 먹었어"',
    '"아기 방금 잠들었어"',
    '"기저귀 갈았어 응가"',
    '"오늘 수유 몇 번 했지?"',
  ];
  int _currentHint = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    widget.controller.addListener(() {
      setState(() {
        _showHint = widget.controller.text.isEmpty;
      });
    });

    // 힌트 텍스트 순환
    _cycleHints();
  }

  void _cycleHints() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentHint = (_currentHint + 1) % _hints.length;
        });
        _cycleHints();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startVoiceInput() async {
    if (widget.speechService.isListening) {
      await widget.speechService.stopListening();
      return;
    }

    _pulseController.repeat(reverse: true);

    await widget.speechService.startListening(
      onResult: (text) {
        widget.controller.text = text;
        _pulseController.stop();
        _pulseController.reset();
        // 음성 입력 완료 후 자동 제출
        if (text.isNotEmpty) {
          widget.onSubmit(text);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.speechService.isListening;
    final partialText = widget.speechService.lastResult;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 음성 인식 중 텍스트 표시
          if (isListening && partialText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        partialText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 입력바
          Row(
            children: [
              // 텍스트 입력 필드
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onSubmitted: widget.onSubmit,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: _showHint ? _hints[_currentHint] : '',
                    hintStyle: TextStyle(
                      color: AppTheme.textHint.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    suffixIcon: widget.controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {
                              widget.onSubmit(widget.controller.text);
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 음성 입력 버튼
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(
                                  alpha: 0.3 + (_pulseController.value * 0.2),
                                ),
                                blurRadius:
                                    10 + (_pulseController.value * 10),
                                spreadRadius: _pulseController.value * 5,
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  );
                },
                child: FloatingActionButton(
                  mini: true,
                  elevation: isListening ? 0 : 2,
                  backgroundColor:
                      isListening ? AppTheme.error : AppTheme.primary,
                  onPressed: _startVoiceInput,
                  child: Icon(
                    isListening ? Icons.stop : Icons.mic_rounded,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
