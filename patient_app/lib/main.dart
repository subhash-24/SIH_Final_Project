import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/design_system.dart';
import 'state/app_state.dart';
import 'screens/welcome_screen.dart';
import 'screens/language_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/patient_details_screen.dart';
import 'screens/before_begin_screen.dart';
import 'screens/voice_interview_screen.dart';
import 'screens/transcript_screen.dart';
import 'screens/medical_history_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/ayush_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/success_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for tablet intake
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Full screen — kiosk mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ArogyaSaathiApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(path: '/welcome', builder: (ctx, _) => const WelcomeScreen()),
    GoRoute(path: '/language', builder: (ctx, _) => const LanguageScreen()),
    GoRoute(path: '/consent', builder: (ctx, _) => const ConsentScreen()),
    GoRoute(path: '/patient-details', builder: (ctx, _) => const PatientDetailsScreen()),
    GoRoute(path: '/before-begin', builder: (ctx, _) => const BeforeBeginScreen()),
    GoRoute(path: '/voice-interview', builder: (ctx, _) => const VoiceInterviewScreen()),
    GoRoute(path: '/transcript', builder: (ctx, _) => const TranscriptScreen()),
    GoRoute(path: '/medical-history', builder: (ctx, _) => const MedicalHistoryScreen()),
    GoRoute(path: '/documents', builder: (ctx, _) => const DocumentsScreen()),
    GoRoute(path: '/ayush', builder: (ctx, _) => const AyushScreen()),
    GoRoute(path: '/summary', builder: (ctx, _) => const SummaryScreen()),
    GoRoute(path: '/success', builder: (ctx, _) => const SuccessScreen()),
  ],
);

class ArogyaSaathiApp extends StatelessWidget {
  const ArogyaSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arogya-Saathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}
