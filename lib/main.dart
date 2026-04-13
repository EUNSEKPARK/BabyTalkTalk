import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/models/baby_profile.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/speech_service.dart';
import 'package:chat_baby_time/services/notification_service.dart';
import 'package:chat_baby_time/services/widget_sync_service.dart';
import 'package:chat_baby_time/services/nlp_analytics_service.dart';
import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/services/sync_queue_service.dart';
import 'package:chat_baby_time/screens/main_screen.dart';
import 'package:chat_baby_time/screens/profile_setup_screen.dart';
import 'package:chat_baby_time/screens/tutorial_screen.dart';
import 'package:chat_baby_time/screens/care_identity_screen.dart';
import 'package:chat_baby_time/services/care_onboarding_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics 설정
  if (!kDebugMode) {
    // Flutter 프레임워크 에러 → Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Dart 비동기 에러 → Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Hive 초기화
  await Hive.initFlutter();

  // 타입 어댑터 등록
  Hive.registerAdapter(RecordCategoryAdapter());
  Hive.registerAdapter(FeedingTypeAdapter());
  Hive.registerAdapter(DiaperTypeAdapter());
  Hive.registerAdapter(SleepStatusAdapter());
  Hive.registerAdapter(BabyRecordAdapter());
  Hive.registerAdapter(BabyProfileAdapter());

  // 서비스 초기화
  final recordService = RecordService();
  await recordService.init();

  // 위젯 구성
  await BabyTimeHomeWidget.ensureConfigured();

  // 알림 서비스 (루틴 엔진 포함)
  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.attachRecordService(recordService);
  recordService.attachNotificationService(notificationService);

  // 위젯에서 생성된 pending 기록 흡수
  await BabyTimeHomeWidget.processPendingWidgetRecords(recordService);

  // 위젯 동기화 (루틴 엔진 정보 포함)
  recordService.addListener(() {
    BabyTimeHomeWidget.sync(
      recordService,
      routineScheduler: notificationService.routineScheduler,
    );
  });
  await BabyTimeHomeWidget.sync(
    recordService,
    routineScheduler: notificationService.routineScheduler,
  );

  final speechService = SpeechService();

  // NLP 분석 데이터 수집 서비스
  final nlpAnalyticsService = NlpAnalyticsService();
  await nlpAnalyticsService.init();

  // 가족 공유 서비스
  final familyService = FamilyService();
  await familyService.init();

  // 오프라인 동기화 큐
  final syncQueueService = SyncQueueService();
  await syncQueueService.init();
  syncQueueService.attachFamilyService(familyService);

  // 가족 동기화 연결
  recordService.attachFamilyService(familyService);
  familyService.onRecordsSync = (records) {
    recordService.mergeFamilyRecords(records);
  };

  // RecordService → Firestore 업로드 (기록 추가 시)
  recordService.addListener(() {
    if (familyService.isInFamily) {
      for (final record in recordService.records) {
        if (record.authorId == null) {
          record.authorId = familyService.uid;
          record.authorName = familyService.myNickname;
        }
      }
    }
  });

  // 앱 시작 시 오프라인 큐 flush 시도
  syncQueueService.flush();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recordService),
        ChangeNotifierProvider.value(value: speechService),
        ChangeNotifierProvider.value(value: notificationService),
        ChangeNotifierProvider.value(value: nlpAnalyticsService),
        ChangeNotifierProvider.value(value: familyService),
        ChangeNotifierProvider.value(value: syncQueueService),
        ChangeNotifierProvider.value(
            value: notificationService.routineScheduler),
      ],
      child: const ChatBabyTimeApp(),
    ),
  );
}

class ChatBabyTimeApp extends StatefulWidget {
  const ChatBabyTimeApp({super.key});

  @override
  State<ChatBabyTimeApp> createState() => _ChatBabyTimeAppState();
}

class _ChatBabyTimeAppState extends State<ChatBabyTimeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final recordService = context.read<RecordService>();
    final notificationService = context.read<NotificationService>();
    BabyTimeHomeWidget.processPendingWidgetRecords(recordService).then((n) {
      if (n > 0) {
        BabyTimeHomeWidget.sync(
          recordService,
          routineScheduler: notificationService.routineScheduler,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final hasProfile = recordService.hasProfile;
    final initialized = recordService.initialized;

    return MaterialApp(
      title: '아기톡톡',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
      home: !initialized
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _InitialRouteDecider(
              hasProfile: hasProfile,
            ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          case '/setup':
            return MaterialPageRoute(
                builder: (_) =>
                    const ProfileSetupScreen(isInitialSetup: true));
          case '/care_identity':
            return MaterialPageRoute(
                builder: (_) => const CareIdentityScreen());
          default:
            return MaterialPageRoute(builder: (_) => const MainScreen());
        }
      },
    );
  }
}

/// 스플래시 없이 바로 튜토리얼 체크 → 적절한 화면으로 이동
class _InitialRouteDecider extends StatefulWidget {
  final bool hasProfile;
  const _InitialRouteDecider({required this.hasProfile});

  @override
  State<_InitialRouteDecider> createState() => _InitialRouteDeciderState();
}

class _InitialRouteDeciderState extends State<_InitialRouteDecider> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final shouldShowTutorial = await TutorialScreen.shouldShow();
    final careDone = await CareOnboardingService.isIdentityStepDone();
    if (!mounted) return;

    void goNext(BuildContext navCtx) {
      if (!widget.hasProfile) {
        Navigator.pushReplacementNamed(navCtx, '/setup');
        return;
      }
      if (!careDone) {
        Navigator.pushReplacementNamed(navCtx, '/care_identity');
        return;
      }
      Navigator.pushReplacementNamed(navCtx, '/home');
    }

    if (shouldShowTutorial) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => TutorialScreen(
            onComplete: () => goNext(ctx),
          ),
        ),
      );
    } else {
      goNext(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 튜토리얼 체크 중 잠깐 표시되는 빈 화면
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const SizedBox.shrink(),
    );
  }
}
