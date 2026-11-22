import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/stats/stats_providers.dart';

import 'surpresa.dart';
import 'settings_screen.dart';
import '../features/analyses/analysis_form.dart';
import '../features/analyses/analyses_screen.dart';
import '../features/notes/notes_form.dart';
import '../features/notes/notes_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/works/work_detail_screen.dart';
import '../features/works/works_form.dart';
import '../features/works/works_screen.dart';
import 'strings.dart';

int? _workIdFrom(GoRouterState state) {
  return int.tryParse(state.pathParameters['workId'] ?? '');
}

int? _analysisIdFrom(GoRouterState state) {
  return int.tryParse(state.pathParameters['analysisId'] ?? '');
}

int? _noteIdFrom(GoRouterState state) {
  return int.tryParse(state.pathParameters['noteId'] ?? '');
}

Widget _invalidWorkScreen() {
  return Scaffold(
    appBar: AppBar(title: const Text(AppStrings.workDetails)),
    body: const Center(child: Text(AppStrings.invalidWork)),
  );
}

Widget _invalidNoteScreen() {
  return Scaffold(
    appBar: AppBar(title: const Text(AppStrings.editNote)),
    body: const Center(child: Text(AppStrings.invalidNote)),
  );
}

Widget _invalidAnalysisScreen() {
  return Scaffold(
    appBar: AppBar(title: const Text(AppStrings.editAnalysis)),
    body: const Center(child: Text(AppStrings.invalidAnalysis)),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/works',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _ScaffoldWithDrawer(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/works',
              builder: (context, state) => const WorksScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const WorksFormScreen(),
                ),
                GoRoute(
                  path: ':workId',
                  builder: (context, state) {
                    final workId = _workIdFrom(state);
                    if (workId == null) return _invalidWorkScreen();
                    return WorkDetailScreen(workId: workId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final workId = _workIdFrom(state);
                        if (workId == null) return _invalidWorkScreen();
                        return WorksFormScreen(workId: workId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              builder: (context, state) => const NotesScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const NotesFormScreen(),
                ),
                GoRoute(
                  path: ':noteId/edit',
                  builder: (context, state) {
                    final noteId = _noteIdFrom(state);
                    if (noteId == null) return _invalidNoteScreen();
                    return NotesFormScreen(noteId: noteId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analyses',
              builder: (context, state) => const AnalysesScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const AnalysisFormScreen(),
                ),
                GoRoute(
                  path: ':analysisId/edit',
                  builder: (context, state) {
                    final analysisId = _analysisIdFrom(state);
                    if (analysisId == null) return _invalidAnalysisScreen();
                    return AnalysisFormScreen(analysisId: analysisId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Chave do Scaffold raiz, usada pelas telas para abrir o menu lateral.
final rootScaffoldKey = GlobalKey<ScaffoldState>();

void openAppDrawer() {
  rootScaffoldKey.currentState?.openDrawer();
}

class _ScaffoldWithDrawer extends ConsumerWidget {
  const _ScaffoldWithDrawer({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final colors = Theme.of(context).colorScheme;

    void goBranch(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
      Navigator.of(context).pop();
    }

    return Scaffold(
      key: rootScaffoldKey,
      body: navigationShell,
      drawer: NavigationDrawer(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: goBranch,
        children: [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const LogoComSurpresa(size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.appTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    streak.current == 0
                        ? AppStrings.noStreak
                        : AppStrings.streakLabel(streak.current),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: Text(AppStrings.works),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: Text(AppStrings.notes),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: Text(AppStrings.analyses),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: Text(AppStrings.stats),
          ),
          const Divider(),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: const Text(AppStrings.settings),
            backgroundColor: colors.surface,
          ),
        ],
      ),
    );
  }
}
