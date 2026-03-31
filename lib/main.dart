import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/models/baby_profile.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/speech_service.dart';
import 'package:chat_baby_time/services/notification_service.dart';
import 'package:chat_baby_time/services/widget_sync_service.dart';
import 'package:chat_baby_time/services/nlp_analytics_service.dart';
import 'package:chat_baby_time/screens/main_screen.dart';
import 'package:chat_baby_time/screens/profile_setup_screen.dart';
import 'package:chat_baby_time/screens/splash_screen.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  await BabyTimeHomeWidget.ensureConfigured();
  recordService.addListener(() {
    BabyTimeHomeWidget.sync(recordService);
  });
  await BabyTimeHomeWidget.sync(recordService);

  final speechService = SpeechService();

  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.attachRecordService(recordService);

  // NLP 분석 데이터 수집 서비스
  final nlpAnalyticsService = NlpAnalyticsService();
  await nlpAnalyticsService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recordService),
        ChangeNotifierProvider.value(value: speechService),
        ChangeNotifierProvider.value(value: notificationService),
        ChangeNotifierProvider.value(value: nlpAnalyticsService),
      ],
      child: const ChatBabyTimeApp(),
    ),
  );
}

class ChatBabyTimeApp extends StatelessWidget {
  const ChatBabyTimeApp({super.key});

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
          : SplashScreen(
              nextRoute: hasProfile ? '/home' : '/setup',
            ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          case '/setup':
            return MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isInitialSetup: true));
          default:
            return MaterialPageRoute(builder: (_) => const MainScreen());
        }
      },
    );
  }
}
