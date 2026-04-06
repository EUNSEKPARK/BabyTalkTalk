import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/speech_service.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/services/nlp_analytics_service.dart';
import 'package:chat_baby_time/widgets/analytics_consent_dialog.dart';
import 'package:chat_baby_time/widgets/category_disambiguation_chips.dart';
import 'package:chat_baby_time/widgets/feeding_type_disambiguation_chips.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/utils/time_utils.dart';
import 'package:chat_baby_time/screens/record_detail_screen.dart';
import 'package:chat_baby_time/pipeline/nlp_pipeline.dart';
import 'package:chat_baby_time/pipeline/growth_stage.dart';
import 'package:chat_baby_time/pipeline/models/pipeline_result.dart';
import 'package:chat_baby_time/widgets/record_edit_sheet.dart';
import 'package:chat_baby_time/widgets/guided_record_button_section.dart';
import 'package:uuid/uuid.dart';

// Chat message model
enum ChatMessageType {
  greeting,
  userMessage,
  aiResponse,
  recordConfirm,
  aiFollowUp,
  categoryDisambiguation,
  feedingTypeDisambiguation,
  medicineTypeDisambiguation,  // 약 종류 선택
  amountDisambiguation,        // 수유량/시간 선택
  stoolDetailDisambiguation,   // 대변 묽기/색깔 선택
  reQuestion,  // 재질문
}

enum ChatSender { user, ai }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;
  final ChatMessageType messageType;
  final BabyRecord? record; // For record confirmation cards
  final bool? autoSaved; // Whether record was auto-saved (confidence > 0.7)
  final String? pendingRawInput;
  final List<CategoryDisambiguationOption>? disambiguationOptions;
  final List<FeedingType>? feedingTypeDisambiguationOptions;
  final List<MedicineTypeOption>? medicineTypeDisambiguationOptions;
  final List<AmountOption>? amountDisambiguationOptions;
  final List<StoolDetailOption>? stoolConsistencyOptions;
  final List<StoolDetailOption>? stoolColorOptions;
  final BabyRecord? pendingRecord;
  final bool disambiguationUsed;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.messageType,
    this.record,
    this.autoSaved,
    this.pendingRawInput,
    this.disambiguationOptions,
    this.feedingTypeDisambiguationOptions,
    this.medicineTypeDisambiguationOptions,
    this.amountDisambiguationOptions,
    this.stoolConsistencyOptions,
    this.stoolColorOptions,
    this.pendingRecord,
    this.disambiguationUsed = false,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTodaysSummary = true;
  bool _isLoading = false;
  bool _hasInputText = false;
  String _currentInputSource = 'chat'; // 'chat', 'voice', 'quick', 'guided'
  int _growthStageIndex = 0; // Current growth stage from profile
  final _uuid = const Uuid();

  // 녹음 모드 펄스 애니메이션
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _inputController.addListener(() {
      final hasText = _inputController.text.isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });
    // context.read can't be called in initState directly,
    // so defer to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() async {
    final recordService = context.read<RecordService>();
    final profile = recordService.profile;
    if (profile != null) {
      _growthStageIndex = profile.growthStageIndex;
    }

    final today = DateTime.now();
    final isNewDay = _isFirstMessageToday();

    // 데이터 수집 동의 팝업 (최초 1회)
    _showConsentIfNeeded();

    // Show greeting at start of day
    if (isNewDay) {
      final yesterdayRecords = recordService.getRecordsForDate(
        today.subtract(const Duration(days: 1)),
      );

      String greetingText = '🌅 좋은 아침이에요! ';
      if (recordService.profile != null) {
        greetingText += '${recordService.profile!.name} ';
      }
      greetingText += '${recordService.profile?.ageText ?? ''} — ';

      // Yesterday's summary
      if (yesterdayRecords.isNotEmpty) {
        final feeding = yesterdayRecords
            .where((r) => r.category == RecordCategory.feeding)
            .length;
        final sleep = yesterdayRecords
            .where((r) => r.category == RecordCategory.sleep)
            .length;
        final diaper = yesterdayRecords
            .where((r) => r.category == RecordCategory.diaper)
            .length;

        greetingText += '어제 요약: ';
        if (feeding > 0) greetingText += '🍼 수유 $feeding회 | ';
        if (sleep > 0) greetingText += '😴 수면 $sleep회 | ';
        if (diaper > 0) greetingText += '🧷 기저귀 $diaper회 | ';
        greetingText = greetingText.replaceAll(RegExp(r' \| $'), '') + '.';
      }
      greetingText += ' 오늘도 화이팅! 💪';

      setState(() {
        _messages.add(
          ChatMessage(
            id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: greetingText,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.greeting,
          ),
        );
      });

      _autoScroll();
    }
  }

  bool _isFirstMessageToday() {
    final today = DateTime.now();
    for (final msg in _messages) {
      if (msg.timestamp.year == today.year &&
          msg.timestamp.month == today.month &&
          msg.timestamp.day == today.day) {
        return false;
      }
    }
    return true;
  }

  void _autoScroll() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 데이터 수집 동의 팝업 (최초 1회)
  Future<void> _showConsentIfNeeded() async {
    final analytics = context.read<NlpAnalyticsService>();
    if (analytics.isConsentShown) return;

    // 약간의 딜레이 후 표시 (앱 로드 완료 후)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final agreed = await AnalyticsConsentDialog.show(context);
    await analytics.setConsent(agreed);
  }

  // 현재 진행 중인 로그 ID (확인 카드 → 저장/취소 추적용)
  String? _currentLogId;

  void _handleTextSubmit(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.user,
      text: text,
      timestamp: DateTime.now(),
      messageType: ChatMessageType.userMessage,
    );

    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
      _isLoading = true;
    });

    _autoScroll();

    // Parse input (시간 측정)
    final stopwatch = Stopwatch()..start();
    final result = NlpParser.parse(text);
    stopwatch.stop();

    // 새 파이프라인으로 파싱 시도
    final pipelineResult = NlpParser.parseWithPipeline(
      text,
      growthStageIndex: _growthStageIndex,
    );

    if (result.needsStoolDetailInput) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'stool_disamb_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: result.message,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.stoolDetailDisambiguation,
            pendingRawInput: result.pendingRawInput,
            stoolConsistencyOptions: result.stoolConsistencyOptions,
            stoolColorOptions: result.stoolColorOptions,
            pendingRecord: result.pendingRecord,
          ),
        );
      });
      _autoScroll();
      return;
    }

    if (result.needsAmountInput) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'amount_disamb_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: result.message,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.amountDisambiguation,
            pendingRawInput: result.pendingRawInput,
            amountDisambiguationOptions: result.amountOptions,
            pendingRecord: result.pendingRecord,
          ),
        );
      });
      _autoScroll();
      return;
    }

    if (result.needsMedicineTypeDisambiguation) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'med_disamb_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: result.message,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.medicineTypeDisambiguation,
            pendingRawInput: result.pendingRawInput,
            medicineTypeDisambiguationOptions: result.medicineTypeOptions,
          ),
        );
      });
      _autoScroll();
      return;
    }

    if (result.needsFeedingTypeDisambiguation) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'feed_disamb_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: result.message,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.feedingTypeDisambiguation,
            pendingRawInput: result.pendingRawInput,
            feedingTypeDisambiguationOptions:
                result.feedingTypeDisambiguationOptions,
          ),
        );
      });
      _autoScroll();
      return;
    }

    if (result.needsDisambiguation) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'disamb_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: result.message,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.categoryDisambiguation,
            pendingRawInput: result.pendingRawInput,
            disambiguationOptions: result.disambiguationOptions,
          ),
        );
      });
      _autoScroll();
      return;
    }

    if (result.isSuccess && result.record != null) {
      await _handleParseResult(result, text, stopwatch.elapsedMilliseconds);
    } else {
      // 파이프라인 재질문 처리
      if (!pipelineResult.isSuccess && pipelineResult.message.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _messages.add(
            ChatMessage(
              id: _uuid.v4(),
              sender: ChatSender.ai,
              text: pipelineResult.message,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.reQuestion,
              pendingRawInput: text,
            ),
          );
        });
      } else {
        setState(() {
          _isLoading = false;
          _messages.add(
            ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              sender: ChatSender.ai,
              text: result.message.isNotEmpty
                  ? result.message
                  : '기록을 이해하지 못했어요. 다시 말씀해 주세요.',
              timestamp: DateTime.now(),
              messageType: ChatMessageType.aiResponse,
            ),
          );
        });
      }
      _autoScroll();
    }
  }

  Future<void> _handleParseResult(
    ParseResult result,
    String text,
    int responseTimeMs,
  ) async {
    if (!result.isSuccess || result.record == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final record = result.record!;
    record.inputSource = _currentInputSource;
    final recordService = context.read<RecordService>();

    final analytics = context.read<NlpAnalyticsService>();
    final appAction = result.confidence > 0.7
        ? 'autoSaved'
        : result.confidence >= 0.3
            ? 'confirmCard'
            : 'rejected';

    final nlpLog = analytics.logParse(
      rawInput: text,
      inputSource: _currentInputSource,
      detectedCategory: record.category.name,
      confidence: result.confidence,
      scores: {
        'feeding': 0,
        'sleep': 0,
        'diaper': 0,
        'health': 0,
      },
      detectedSubType: _getSubType(record),
      appAction: appAction,
      responseTimeMs: responseTimeMs,
    );
    _currentLogId = nlpLog?.id;

    if (result.confidence > 0.7) {
      final saved = await recordService.addRecord(record);
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '기록 저장에 실패했습니다. 다시 시도해주세요.',
              style: TextStyle(color: AppTheme.onError),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'confirm_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: '${record.categoryEmoji} ${record.categoryName} 기록 완료!',
            timestamp: DateTime.now(),
            messageType: ChatMessageType.recordConfirm,
            record: record,
            autoSaved: true,
          ),
        );
      });

      await _addFriendlyFollowUp(recordService, record);
    } else if (result.confidence >= 0.3) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: 'confirm_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: '이렇게 기록할까요?',
            timestamp: DateTime.now(),
            messageType: ChatMessageType.recordConfirm,
            record: record,
            autoSaved: false,
          ),
        );
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }

    _autoScroll();
  }

  Future<void> _applyCategoryDisambiguation(
    ChatMessage message,
    RecordCategory category,
  ) async {
    final raw = message.pendingRawInput;
    final options = message.disambiguationOptions;
    if (raw == null || options == null || message.disambiguationUsed) return;

    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx < 0) return;

    setState(() => _isLoading = true);

    final result = NlpParser.parseWithCategory(raw, category);
    if (result.needsFeedingTypeDisambiguation) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages[idx] = ChatMessage(
          id: message.id,
          sender: ChatSender.ai,
          text: result.message,
          timestamp: DateTime.now(),
          messageType: ChatMessageType.feedingTypeDisambiguation,
          pendingRawInput: result.pendingRawInput,
          feedingTypeDisambiguationOptions:
              result.feedingTypeDisambiguationOptions,
          disambiguationUsed: true,
        );
      });
      _autoScroll();
      return;
    }

    if (!mounted) return;
    setState(() {
      _messages[idx] = ChatMessage(
        id: message.id,
        sender: ChatSender.ai,
        text: '${_categoryKorean(category)}(으)로 기록할게요.',
        timestamp: DateTime.now(),
        messageType: ChatMessageType.aiResponse,
        disambiguationUsed: true,
      );
    });

    await _handleParseResult(result, raw, 0);
  }

  Future<void> _applyFeedingTypeDisambiguation(
    ChatMessage message,
    FeedingType feedingType,
  ) async {
    final raw = message.pendingRawInput;
    final opts = message.feedingTypeDisambiguationOptions;
    if (raw == null || opts == null) return;

    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx < 0) return;

    setState(() {
      _isLoading = true;
      _messages[idx] = ChatMessage(
        id: message.id,
        sender: ChatSender.ai,
        text: '${_feedingTypeChosenLabel(feedingType)}(으)로 기록할게요.',
        timestamp: DateTime.now(),
        messageType: ChatMessageType.aiResponse,
        disambiguationUsed: true,
      );
    });

    final result = NlpParser.parseWithFeedingType(raw, feedingType);
    await _handleParseResult(result, raw, 0);
  }

  String _feedingTypeChosenLabel(FeedingType t) {
    switch (t) {
      case FeedingType.formula:
        return '분유';
      case FeedingType.breast:
        return '모유';
      default:
        return '분유';
    }
  }

  String _categoryKorean(RecordCategory c) {
    switch (c) {
      case RecordCategory.feeding:
        return '수유';
      case RecordCategory.babyfood:
        return '이유식';
      case RecordCategory.snack:
        return '간식';
      case RecordCategory.sleep:
        return '수면';
      case RecordCategory.diaper:
        return '기저귀';
      case RecordCategory.health:
        return '건강';
      case RecordCategory.milestone:
        return '성장';
      case RecordCategory.bath:
        return '목욕';
      case RecordCategory.pumping:
        return '유축';
      case RecordCategory.tummytime:
        return '터미타임';
      case RecordCategory.other:
        return '기타';
    }
  }

  /// 서브타입 추출 (로그용)
  String? _getSubType(BabyRecord record) {
    switch (record.category) {
      case RecordCategory.feeding:
        return record.feedingType?.name;
      case RecordCategory.sleep:
        return record.sleepStatus?.name;
      case RecordCategory.diaper:
        return record.diaperType?.name;
      default:
        return null;
    }
  }

  Future<void> _addFriendlyFollowUp(
    RecordService recordService,
    BabyRecord record,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    String followUpText = '';

    switch (record.category) {
      case RecordCategory.feeding:
        final todayFeeding = recordService.todayRecords
            .where((r) => r.category == RecordCategory.feeding)
            .length;
        final totalMl = recordService.todayTotalFeedingMl;
        followUpText = '오늘 총 이유식/분유 ${totalMl}ml! ';
        if (todayFeeding > 1) {
          followUpText += '이미 $todayFeeding회 먹었네요 😊';
        } else {
          followUpText += '첫 끼니네요! 😊';
        }
        break;

      case RecordCategory.sleep:
        final lastSleep = recordService.lastSleepRecord;
        if (lastSleep != null &&
            lastSleep.sleepStatus == SleepStatus.end &&
            lastSleep != record) {
          final diff = record.timestamp.difference(lastSleep.timestamp);
          final hours = diff.inHours;
          final minutes = diff.inMinutes % 60;
          followUpText =
              '${hours}시간 ${minutes}분을 주무셨네요! 푹 주무셨어요 😴';
        } else {
          followUpText = '좋은 수면이 되길 바라요! 🌙';
        }
        break;

      case RecordCategory.diaper:
        final todayDiapers = recordService.todayDiaperCount;
        followUpText = '오늘 기저귀 $todayDiapers회 갈았어요! 잘하고 있어요 👏';
        break;

      case RecordCategory.health:
        if (record.temperature != null) {
          followUpText = '체온 기록해주셨군요! 😊';
        } else if (record.medicine != null) {
          followUpText = '약 먹는 거 잘했어요! 💪';
        } else {
          followUpText = '건강 기록 감사합니다! 😊';
        }
        break;

      default:
        followUpText = '기록해주셔서 감사합니다! 😊';
        break;
    }

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'followup_${DateTime.now().millisecondsSinceEpoch}',
            sender: ChatSender.ai,
            text: followUpText,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.aiFollowUp,
          ),
        );
      });
    }

    _autoScroll();
  }

  void _handleRecordConfirmation(ChatMessage message, bool confirm) async {
    if (message.record == null) return;

    final recordService = context.read<RecordService>();
    final analytics = context.read<NlpAnalyticsService>();
    final record = message.record!;

    if (confirm) {
      // ── 분석 로그: 사용자가 "저장" 눌렀음 ──
      if (_currentLogId != null) {
        analytics.logConfirm(_currentLogId!);
      }

      // Save the record
      final saved = await recordService.addRecord(record);
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '저장에 실패했습니다.',
              style: TextStyle(color: AppTheme.onError),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      // Update the message to show confirmed state
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx >= 0) {
          _messages[idx] = ChatMessage(
            id: message.id,
            sender: message.sender,
            text: message.text,
            timestamp: message.timestamp,
            messageType: ChatMessageType.recordConfirm,
            record: record,
            autoSaved: true,
          );
        }
      });

      // Add friendly follow-up
      await _addFriendlyFollowUp(recordService, record);
    } else {
      // ── 분석 로그: 사용자가 "취소" 눌렀음 (인식 실패) ──
      if (_currentLogId != null) {
        analytics.logCancel(_currentLogId!);
      }

      // Remove the confirmation message
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
    }

    _autoScroll();
  }

  void _handleRecordEdit(ChatMessage message) {
    if (message.record == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RecordEditSheet(record: message.record!),
    );
  }

  void _handleRecordDelete(ChatMessage message) async {
    if (message.record == null) return;

    final recordService = context.read<RecordService>();
    final success = await recordService.deleteRecord(message.record!.id);

    if (success) {
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '기록이 삭제되었습니다' : '삭제에 실패했습니다',
            style: TextStyle(
              color: success ? AppTheme.onSurface : AppTheme.onError,
            ),
          ),
          backgroundColor:
              success ? AppTheme.surfaceContainerHigh : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _handleVoiceInput() async {
    final speechService = context.read<SpeechService>();

    if (speechService.isListening) {
      await speechService.stopListening();
      _pulseController.stop();
      _pulseController.reset();
      _currentInputSource = 'chat'; // 리셋
      return;
    }

    if (!speechService.isAvailable) {
      await speechService.initialize();
    }

    if (!speechService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              speechService.errorMessage ??
                  '음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.',
              style: const TextStyle(color: AppTheme.onError),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    _currentInputSource = 'voice';
    _pulseController.repeat(reverse: true);

    await speechService.startListening(
      onResult: (text) {
        if (mounted && text.isNotEmpty) {
          _pulseController.stop();
          _pulseController.reset();
          _handleTextSubmit(text);
          _currentInputSource = 'chat'; // 리셋
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error,
                style: const TextStyle(color: AppTheme.onError),
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final speechService = context.watch<SpeechService>();
    final todayRecords = recordService.todayRecords;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Baby profile
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/baby_avatar_default.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recordService.profile?.name ?? '아기톡톡',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        if (speechService.isListening)
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFF6B6B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '음성 녹음 중...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFF8E8E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else if (recordService.profile != null)
                          Text(
                            recordService.profile!.ageText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 상단 녹음 버튼
                  GestureDetector(
                    onTap: _handleVoiceInput,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: speechService.isListening
                            ? const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                              )
                            : null,
                        color: speechService.isListening
                            ? null
                            : AppTheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        boxShadow: speechService.isListening
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          speechService.isListening
                              ? Icons.stop_rounded
                              : Icons.mic_none,
                          color: speechService.isListening
                              ? Colors.white
                              : AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Menu button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: AppTheme.primary),
                    color: AppTheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      switch (value) {
                        case 'clear':
                          setState(() => _messages.clear());
                          _initializeChat();
                          break;
                        case 'today_summary':
                          setState(() => _showTodaysSummary = !_showTodaysSummary);
                          break;
                        case 'close':
                          Navigator.pop(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'today_summary',
                        child: Row(
                          children: [
                            Icon(
                              _showTodaysSummary
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: AppTheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showTodaysSummary ? '요약 숨기기' : '요약 보기',
                              style: const TextStyle(color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep, size: 18, color: AppTheme.onSurface),
                            SizedBox(width: 8),
                            Text('대화 초기화', style: TextStyle(color: AppTheme.onSurface)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 18, color: AppTheme.onSurface),
                            SizedBox(width: 8),
                            Text('채팅 닫기', style: TextStyle(color: AppTheme.onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.surfaceContainerHigh),

            // Today's summary bento card (collapsible)
            if (_showTodaysSummary && todayRecords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => setState(() => _showTodaysSummary = false),
                  child: _buildTodaysSummaryCard(recordService),
                ),
              ),

            // Chat list
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/empty_records.png',
                              width: 160,
                              height: 160,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '아기 기록을 입력해보세요',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            ),

            // 단계형 버튼 입력 (종류 → 시간)
            if (!speechService.isListening)
              GuidedRecordButtonSection(
                onPhraseSubmit: (phrase) {
                  _currentInputSource = 'guided';
                  _handleTextSubmit(phrase);
                  _currentInputSource = 'chat';
                },
              ),

            // Smart input bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 녹음 모드 인디케이터
                  if (speechService.isListening)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1 + _pulseAnimation.value * 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.3 + _pulseAnimation.value * 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.error.withOpacity(_pulseAnimation.value),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '음성 녹음 중...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.error.withOpacity(0.7 + _pulseAnimation.value * 0.3),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _handleVoiceInput,
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  Row(
                    children: [
                      // Text input
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: speechService.isListening
                                ? AppTheme.error.withOpacity(0.08)
                                : AppTheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                            border: speechService.isListening
                                ? Border.all(color: AppTheme.error.withOpacity(0.3), width: 1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  enabled: !speechService.isListening,
                                  decoration: InputDecoration(
                                    hintText: speechService.isListening
                                        ? '듣고 있어요...'
                                        : '베비에게 말해보세요...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintStyle: TextStyle(
                                      color: speechService.isListening
                                          ? AppTheme.error.withOpacity(0.6)
                                          : AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 14,
                                  ),
                                  onSubmitted: (text) {
                                    if (text.isNotEmpty) {
                                      _currentInputSource = 'chat';
                                      _handleTextSubmit(text);
                                    }
                                  },
                                ),
                              ),
                              if (_hasInputText)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _currentInputSource = 'chat';
                                      _handleTextSubmit(_inputController.text);
                                    },
                                    child: const Icon(
                                      Icons.send,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mic button with recording state
                      GestureDetector(
                        onTap: _handleVoiceInput,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: speechService.isListening ? 52 : 48,
                          height: speechService.isListening ? 52 : 48,
                          decoration: BoxDecoration(
                            gradient: speechService.isListening
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                                  )
                                : const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                                  ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: speechService.isListening
                                    ? const Color(0xFFFF6B6B).withOpacity(0.4)
                                    : AppTheme.primary.withOpacity(0.3),
                                blurRadius: speechService.isListening ? 16 : 12,
                                spreadRadius: speechService.isListening ? 4 : 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              speechService.isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic,
                              color: Colors.white,
                              size: speechService.isListening ? 28 : 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSummaryCard(RecordService recordService) {
    final todayRecords = recordService.todayRecords;
    final feeding = todayRecords
        .where((r) => r.category == RecordCategory.feeding)
        .length;
    final sleep =
        todayRecords.where((r) => r.category == RecordCategory.sleep).length;
    final diaper =
        todayRecords.where((r) => r.category == RecordCategory.diaper).length;
    final totalMl = recordService.todayTotalFeedingMl;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (feeding > 0)
            _buildSummaryChip('🍼', '수유 $feeding회${totalMl > 0 ? '\n${totalMl}ml' : ''}'),
          if (sleep > 0)
            _buildSummaryChip('😴', '수면 $sleep회'),
          if (diaper > 0)
            _buildSummaryChip('🧷', '기저귀 $diaper회'),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String emoji, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.messageType == ChatMessageType.stoolDetailDisambiguation) {
      return _buildStoolDetailCard(message);
    }
    if (message.messageType == ChatMessageType.amountDisambiguation) {
      return _buildAmountDisambiguationCard(message);
    }
    if (message.messageType == ChatMessageType.medicineTypeDisambiguation) {
      return _buildMedicineTypeDisambiguationCard(message);
    }
    if (message.messageType == ChatMessageType.feedingTypeDisambiguation) {
      return _buildFeedingTypeDisambiguationCard(message);
    }
    if (message.messageType == ChatMessageType.categoryDisambiguation) {
      return _buildCategoryDisambiguationCard(message);
    }
    if (message.messageType == ChatMessageType.recordConfirm) {
      return _buildRecordConfirmCard(message);
    }
    if (message.messageType == ChatMessageType.reQuestion) {
      return _buildReQuestionMessage(message);
    }

    final isUser = message.sender == ChatSender.user;

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 60 : 12,
        right: isUser ? 12 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryContainer],
                    )
                  : null,
              color: isUser ? null : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 16),
              ),
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : AppTheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            TimeUtils.formatRelativeTime(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineTypeDisambiguationCard(ChatMessage message) {
    final opts = message.medicineTypeDisambiguationOptions;
    if (opts == null || opts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.healthColor.withOpacity(0.25)),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opts.map((opt) {
              return GestureDetector(
                onTap: message.disambiguationUsed
                    ? null
                    : () => _applyMedicineTypeDisambiguation(message, opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: message.disambiguationUsed
                        ? AppTheme.surfaceContainerHigh
                        : AppTheme.healthBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: message.disambiguationUsed
                          ? AppTheme.onSurfaceVariant.withOpacity(0.2)
                          : AppTheme.healthColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: message.disambiguationUsed
                          ? AppTheme.onSurfaceVariant
                          : AppTheme.healthColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            TimeUtils.formatRelativeTime(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _applyMedicineTypeDisambiguation(
    ChatMessage message,
    MedicineTypeOption selected,
  ) {
    final rawInput = message.pendingRawInput ?? '';
    final result = NlpParser.parseWithMedicineType(rawInput, selected.medicineName);

    if (result.isSuccess && result.record != null) {
      final record = result.record!;
      record.inputSource = _currentInputSource;
      context.read<RecordService>().addRecord(record);

      setState(() {
        // 선택 완료 표시
        final idx = _messages.indexOf(message);
        if (idx >= 0) {
          _messages[idx] = ChatMessage(
            id: message.id,
            sender: message.sender,
            text: message.text,
            timestamp: message.timestamp,
            messageType: message.messageType,
            pendingRawInput: message.pendingRawInput,
            medicineTypeDisambiguationOptions:
                message.medicineTypeDisambiguationOptions,
            disambiguationUsed: true,
          );
        }

        // 확인 메시지
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            sender: ChatSender.ai,
            text: result.message,
            timestamp: DateTime.now(),
            messageType: ChatMessageType.recordConfirm,
            record: record,
            autoSaved: true,
          ),
        );
      });
      _autoScroll();
    }
  }

  Widget _buildStoolDetailCard(ChatMessage message) {
    final consistencyOpts = message.stoolConsistencyOptions;
    final colorOpts = message.stoolColorOptions;
    final pending = message.pendingRecord;
    if (consistencyOpts == null || consistencyOpts.isEmpty || pending == null) {
      return const SizedBox.shrink();
    }
    if (message.disambiguationUsed) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '💩 ${message.text}',
            style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return _StoolDetailChipsWidget(
      message: message,
      consistencyOptions: consistencyOpts,
      colorOptions: colorOpts ?? [],
      pendingRecord: pending,
      onComplete: (consistency, color) => _applyStoolDetail(message, consistency, color),
      onSkip: () => _applyStoolDetail(message, null, null),
    );
  }

  Future<void> _applyStoolDetail(ChatMessage message, String? consistency, String? color) async {
    final pending = message.pendingRecord;
    if (pending == null) return;
    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx < 0) return;

    final memoItems = <String>[];
    if (consistency != null && consistency != '보통') memoItems.add(consistency);
    if (color != null) memoItems.add(color);
    final memo = memoItems.isNotEmpty ? memoItems.join(', ') : null;

    final updated = BabyRecord(
      id: pending.id,
      category: pending.category,
      timestamp: pending.timestamp,
      rawInput: pending.rawInput,
      diaperType: pending.diaperType,
      memo: memo,
    );

    final typeName = pending.diaperType == DiaperType.poop ? '대변' : '소변+대변';
    final memoText = memo != null ? ' ($memo)' : '';
    final result = ParseResult.success(
      updated,
      confidence: 0.9,
      message: '기저귀 교체($typeName)$memoText 기록',
    );

    setState(() {
      _messages[idx] = ChatMessage(
        id: message.id,
        sender: ChatSender.ai,
        text: '${consistency ?? '보통'}${color != null ? ' · $color' : ''} 선택됨',
        timestamp: message.timestamp,
        messageType: message.messageType,
        pendingRawInput: message.pendingRawInput,
        stoolConsistencyOptions: message.stoolConsistencyOptions,
        stoolColorOptions: message.stoolColorOptions,
        pendingRecord: message.pendingRecord,
        disambiguationUsed: true,
      );
    });

    if (result.isSuccess && result.record != null) {
      final record = result.record!;
      final recordService = context.read<RecordService>();
      await recordService.addRecord(record);
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'confirm_${DateTime.now().millisecondsSinceEpoch}',
              sender: ChatSender.ai,
              text: '${record.categoryEmoji} ${record.categoryName} 기록 완료!',
              timestamp: DateTime.now(),
              messageType: ChatMessageType.recordConfirm,
              record: record,
              autoSaved: true,
            ),
          );
        });
        await _addFriendlyFollowUp(recordService, record);
      }
    }
  }

  Widget _buildAmountDisambiguationCard(ChatMessage message) {
    final opts = message.amountDisambiguationOptions;
    if (opts == null || opts.isEmpty) {
      return const SizedBox.shrink();
    }

    const chipColor = Color(0xFFFFB5A7); // feeding color

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: chipColor.withOpacity(0.25)),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opts.map((opt) {
              return GestureDetector(
                onTap: message.disambiguationUsed
                    ? null
                    : () => _applyAmountDisambiguation(message, opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: message.disambiguationUsed
                        ? AppTheme.surfaceContainerHigh
                        : chipColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: message.disambiguationUsed
                          ? AppTheme.onSurfaceVariant.withOpacity(0.2)
                          : chipColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: message.disambiguationUsed
                          ? AppTheme.onSurfaceVariant
                          : chipColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            TimeUtils.formatRelativeTime(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _applyAmountDisambiguation(
    ChatMessage message,
    AmountOption selected,
  ) {
    final pending = message.pendingRecord;
    if (pending == null) return;

    final isBreast = pending.feedingType == FeedingType.breast;
    final updated = BabyRecord(
      id: pending.id,
      category: pending.category,
      timestamp: pending.timestamp,
      rawInput: pending.rawInput,
      feedingType: pending.feedingType,
      amountMl: selected.amountMl,
      durationMinutes: selected.durationText != null
          ? int.tryParse(selected.durationText!)
          : pending.durationMinutes,
      memo: pending.memo,
    );

    updated.inputSource = _currentInputSource;
    context.read<RecordService>().addRecord(updated);

    final typeName = isBreast ? '모유' : '분유';
    final desc = selected.amountMl != null
        ? '${selected.amountMl}ml'
        : selected.durationText != null
            ? '${selected.durationText}분'
            : '';

    setState(() {
      final idx = _messages.indexOf(message);
      if (idx >= 0) {
        _messages[idx] = ChatMessage(
          id: message.id,
          sender: message.sender,
          text: message.text,
          timestamp: message.timestamp,
          messageType: message.messageType,
          pendingRawInput: message.pendingRawInput,
          amountDisambiguationOptions: message.amountDisambiguationOptions,
          pendingRecord: message.pendingRecord,
          disambiguationUsed: true,
        );
      }

      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          sender: ChatSender.ai,
          text: '수유($typeName) $desc 기록 완료',
          timestamp: DateTime.now(),
          messageType: ChatMessageType.recordConfirm,
          record: updated,
          autoSaved: true,
        ),
      );
    });
    _autoScroll();
  }

  Widget _buildFeedingTypeDisambiguationCard(ChatMessage message) {
    final opts = message.feedingTypeDisambiguationOptions;
    if (opts == null || opts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FeedingTypeDisambiguationChips(
            options: opts,
            onSelected: (t) => _applyFeedingTypeDisambiguation(message, t),
          ),
          const SizedBox(height: 4),
          Text(
            TimeUtils.formatRelativeTime(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDisambiguationCard(ChatMessage message) {
    final opts = message.disambiguationOptions;
    if (opts == null || opts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          CategoryDisambiguationChips(
            options: opts,
            onSelected: (c) => _applyCategoryDisambiguation(message, c),
          ),
          const SizedBox(height: 4),
          Text(
            TimeUtils.formatRelativeTime(message.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordConfirmCard(ChatMessage message) {
    final record = message.record!;
    final isAutoSaved = message.autoSaved ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(48),
            bottomRight: const Radius.circular(48),
            topRight: const Radius.circular(24),
            bottomLeft: const Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Text(
                  record.categoryEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAutoSaved
                            ? '${record.categoryName} 기록 완료!'
                            : '이렇게 기록할까요?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      if (isAutoSaved)
                        Row(
                          children: [
                            Text(
                              '인식 정확도: 높음 ✓',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (record.inputSource != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                record.inputSource == 'voice'
                                    ? Icons.mic
                                    : record.inputSource == 'quick'
                                        ? Icons.bolt
                                        : record.inputSource == 'guided'
                                            ? Icons.touch_app_outlined
                                            : Icons.chat_bubble_outline,
                                size: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                record.inputSourceName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Record details
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecordDetailRow('🕐', TimeUtils.formatTime(record.timestamp)),
                  if (record.amountMl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildRecordDetailRow('📏', '${record.amountMl}ml'),
                    ),
                  if (record.temperature != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildRecordDetailRow('🌡️', '${record.temperature}°C'),
                    ),
                  if (record.medicine != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildRecordDetailRow('💊', record.medicine!),
                    ),
                  if (record.summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildRecordDetailRow('📝', record.summary),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            if (!isAutoSaved)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleRecordConfirmation(message, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleRecordConfirmation(message, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primaryContainer
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '저장!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleRecordEdit(message),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '수정',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleRecordDelete(message),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '삭제',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetailRow(String icon, String label) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReQuestionMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 48),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // light orange
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, size: 16, color: Color(0xFFE65100)),
              SizedBox(width: 4),
              Text(
                '추가 정보가 필요해요',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4E342E)),
          ),
        ],
      ),
    );
  }
}

/// 대변 상세 선택 (묽기 + 색깔) StatefulWidget
class _StoolDetailChipsWidget extends StatefulWidget {
  final ChatMessage message;
  final List<StoolDetailOption> consistencyOptions;
  final List<StoolDetailOption> colorOptions;
  final BabyRecord pendingRecord;
  final void Function(String? consistency, String? color) onComplete;
  final VoidCallback onSkip;

  const _StoolDetailChipsWidget({
    required this.message,
    required this.consistencyOptions,
    required this.colorOptions,
    required this.pendingRecord,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<_StoolDetailChipsWidget> createState() => _StoolDetailChipsWidgetState();
}

class _StoolDetailChipsWidgetState extends State<_StoolDetailChipsWidget> {
  String? _selectedConsistency;
  String? _selectedColor;

  Color _dotColor(String name) {
    switch (name) {
      case '노란색': return const Color(0xFFFFD54F);
      case '갈색': return const Color(0xFF8D6E63);
      case '녹색': return const Color(0xFF66BB6A);
      case '검은색': return const Color(0xFF424242);
      case '빨간색': return const Color(0xFFEF5350);
      case '흰색': return const Color(0xFFF5F5F5);
      default: return const Color(0xFFBDBDBD);
    }
  }

  @override
  Widget build(BuildContext context) {
    const chipColor = Color(0xFFFFE5A0);
    const selectedBorder = Color(0xFFFFB300);
    const selectedText = Color(0xFFE65100);

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: const Text(
              '💩 대변 상태는 어땠나요?',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppTheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          // 묽기
          const Text('묽기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: widget.consistencyOptions.map((opt) {
              final isSelected = _selectedConsistency == opt.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedConsistency = isSelected ? null : opt.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBorder.withOpacity(0.2) : chipColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? selectedBorder : chipColor.withOpacity(0.5), width: isSelected ? 2 : 1),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? selectedText : AppTheme.onSurface),
                  ),
                ),
              );
            }).toList(),
          ),
          // 색깔
          if (widget.colorOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('색깔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: widget.colorOptions.map((opt) {
                final isSelected = _selectedColor == opt.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = isSelected ? null : opt.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedBorder.withOpacity(0.2) : chipColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSelected ? selectedBorder : chipColor.withOpacity(0.5), width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: _dotColor(opt.value), shape: BoxShape.circle, border: Border.all(color: Colors.black26, width: 0.5)),
                        ),
                        const SizedBox(width: 5),
                        Text(opt.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? selectedText : AppTheme.onSurface)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          // 버튼 행
          Row(
            children: [
              GestureDetector(
                onTap: widget.onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('건너뛰기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onComplete(_selectedConsistency, _selectedColor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFB5A7), Color(0xFFFF9A8C)]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('확인', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            TimeUtils.formatRelativeTime(widget.message.timestamp),
            style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
