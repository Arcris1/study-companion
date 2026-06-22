import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/onboarding/api_key_setup_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/notebook/notebook_detail_screen.dart';
import '../presentation/screens/notebook/create_notebook_screen.dart';
import '../presentation/screens/note/note_import_screen.dart';
import '../presentation/screens/note/note_detail_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/quiz/quiz_config_screen.dart';
import '../presentation/screens/quiz/quiz_screen.dart';
import '../presentation/screens/quiz/quiz_results_screen.dart';
import '../presentation/screens/quiz/quiz_history_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/flashcard/flashcard_deck_list_screen.dart';
import '../presentation/screens/flashcard/flashcard_study_screen.dart';
import '../presentation/screens/flashcard/flashcard_stats_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/ai_prompts_screen.dart';
import '../presentation/screens/analytics/analytics_dashboard_screen.dart';
import '../presentation/screens/weakness/weakness_screen.dart';
import '../presentation/screens/quiz/focus_mode_screen.dart';
import '../presentation/screens/planner/daily_planner_screen.dart';

// ─── Transition helpers ────────────────────────────────────────────────────

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideRightPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideUpPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String apiKeySetup = '/api-key';
  static const String home = '/';
  static const String createNotebook = '/create-notebook';
  static const String notebookDetail = '/notebook/:id';
  static const String noteImport = '/notebook/:notebookId/import';
  static const String noteDetail = '/note/:id';
  static const String chat = '/notebook/:notebookId/chat/:sessionId';
  static const String quizConfig = '/notebook/:notebookId/quiz-config';
  static const String quiz = '/quiz/:id';
  static const String quizResults = '/quiz/:quizId/results/:attemptId';
  static const String quizHistory = '/quiz/:quizId/history';
  static const String flashcardDecks = '/notebook/:notebookId/flashcards';
  static const String flashcardStudy = '/flashcard-deck/:deckId/study';
  static const String flashcardStats = '/flashcard-deck/:deckId/stats';
  static const String search = '/search';
  static const String analytics = '/analytics';
  static const String weakness = '/weakness/:notebookId';
  static const String focusQuiz = '/focus-quiz/:notebookId/:topic';
  static const String planner = '/planner';
  static const String settings = '/settings';
  static const String aiPrompts = '/settings/ai-prompts';
}

GoRouter createRouter({bool showOnboarding = false}) {
  return GoRouter(
    initialLocation: showOnboarding ? AppRoutes.onboarding : AppRoutes.home,
    routes: [
      // ── Onboarding (fade) ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.apiKeySetup,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: ApiKeySetupScreen(
            isFirstRun: state.uri.queryParameters['first'] == '1',
          ),
        ),
      ),

      // ── Home (fade) ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),

      // ── Modal screens (slide up) ─────────────────────────────────
      GoRoute(
        path: AppRoutes.createNotebook,
        pageBuilder: (context, state) => _slideUpPage(
          key: state.pageKey,
          child: const CreateNotebookScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.noteImport,
        pageBuilder: (context, state) {
          final notebookId = int.parse(state.pathParameters['notebookId']!);
          return _slideUpPage(
            key: state.pageKey,
            child: NoteImportScreen(notebookId: notebookId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizConfig,
        pageBuilder: (context, state) {
          final notebookId = int.parse(state.pathParameters['notebookId']!);
          return _slideUpPage(
            key: state.pageKey,
            child: QuizConfigScreen(notebookId: notebookId),
          );
        },
      ),

      // ── Drill-down screens (slide from right) ────────────────────
      GoRoute(
        path: AppRoutes.notebookDetail,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideRightPage(
            key: state.pageKey,
            child: NotebookDetailScreen(notebookId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.noteDetail,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideRightPage(
            key: state.pageKey,
            child: NoteDetailScreen(noteId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) {
          final notebookId = int.parse(state.pathParameters['notebookId']!);
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: ChatScreen(notebookId: notebookId, sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quiz,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideRightPage(
            key: state.pageKey,
            child: QuizScreen(quizId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizResults,
        pageBuilder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          final attemptId = int.parse(state.pathParameters['attemptId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: QuizResultsScreen(quizId: quizId, attemptId: attemptId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizHistory,
        pageBuilder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: QuizHistoryScreen(quizId: quizId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardDecks,
        pageBuilder: (context, state) {
          final notebookId = int.parse(state.pathParameters['notebookId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: FlashcardDeckListScreen(notebookId: notebookId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardStudy,
        pageBuilder: (context, state) {
          final deckId = int.parse(state.pathParameters['deckId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: FlashcardStudyScreen(deckId: deckId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardStats,
        pageBuilder: (context, state) {
          final deckId = int.parse(state.pathParameters['deckId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: FlashcardStatsScreen(deckId: deckId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.weakness,
        pageBuilder: (context, state) {
          final notebookId = int.parse(state.pathParameters['notebookId']!);
          return _slideRightPage(
            key: state.pageKey,
            child: WeaknessScreen(notebookId: notebookId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.focusQuiz,
        pageBuilder: (context, state) {
          final notebookId = int.parse(state.pathParameters['notebookId']!);
          final topic = Uri.decodeComponent(state.pathParameters['topic']!);
          return _slideRightPage(
            key: state.pageKey,
            child: FocusModeScreen(notebookId: notebookId, topic: topic),
          );
        },
      ),

      // ── Settings, search, analytics (fade 250ms) ─────────────────
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const SearchScreen(),
          duration: const Duration(milliseconds: 250),
        ),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const AnalyticsDashboardScreen(),
          duration: const Duration(milliseconds: 250),
        ),
      ),
      GoRoute(
        path: AppRoutes.planner,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const DailyPlannerScreen(),
          duration: const Duration(milliseconds: 250),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const SettingsScreen(),
          duration: const Duration(milliseconds: 250),
        ),
      ),
      GoRoute(
        path: AppRoutes.aiPrompts,
        pageBuilder: (context, state) => _slideRightPage(
          key: state.pageKey,
          child: const AiPromptsScreen(),
        ),
      ),
    ],
  );
}
