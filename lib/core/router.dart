import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        return _ScaffoldWithNavigationBar(navigationShell: navigationShell);
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
      ],
    ),
  ],
);

class _ScaffoldWithNavigationBar extends StatelessWidget {
  const _ScaffoldWithNavigationBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: AppStrings.works,
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: AppStrings.notes,
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: AppStrings.analyses,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: AppStrings.stats,
          ),
        ],
      ),
    );
  }
}
