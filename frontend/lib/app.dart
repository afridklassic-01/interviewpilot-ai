import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/interview/interview_complete_screen.dart';
import 'screens/interview/interview_screen.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/results/question_review_screen.dart';
import 'screens/results/results_screen.dart';
import 'state/interview_session.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

/// Route names used across the app.
class AppRoutes {
  AppRoutes._();

  static const landing = '/';
  static const dashboard = '/dashboard';
  static const interview = '/interview';
  static const interviewComplete = '/interview/complete';
  static const results = '/results';
  static const review = '/results/review';
}

/// Root application widget.
class InterviewPilotApp extends StatefulWidget {
  const InterviewPilotApp({super.key, this.session});

  /// Optional injected session (tests supply a mock backend here).
  final InterviewSession? session;

  @override
  State<InterviewPilotApp> createState() => _InterviewPilotAppState();
}

class _InterviewPilotAppState extends State<InterviewPilotApp> {
  late final InterviewSession _session = widget.session ?? InterviewSession();

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: MaterialApp(
        title: 'InterviewPilot AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.landing,
        onGenerateRoute: (settings) {
          final page = switch (settings.name) {
            AppRoutes.landing => const LandingScreen(),
            AppRoutes.dashboard => const DashboardScreen(),
            AppRoutes.interview => const InterviewScreen(),
            AppRoutes.interviewComplete => const InterviewCompleteScreen(),
            AppRoutes.results => const ResultsScreen(),
            AppRoutes.review => const QuestionReviewScreen(),
            _ => const LandingScreen(),
          };
          return _premiumRoute(page, settings);
        },
      ),
    );
  }
}

/// Smooth fade + subtle lift transition for every page change.
Route<T> _premiumRoute<T>(Widget page, RouteSettings settings) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (_, _, _) => page,
    transitionDuration: AppTokens.slow,
    reverseTransitionDuration: AppTokens.medium,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
