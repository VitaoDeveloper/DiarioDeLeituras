import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../notes/notes_providers.dart';
import 'reading_session_form.dart';
import 'works_providers.dart';

class WorkDetailScreen extends ConsumerWidget {
  const WorkDetailScreen({required this.workId, super.key});

  final int workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workAsync = ref.watch(workProvider(workId));
    final sessionsAsync = ref.watch(sessionsForWorkProvider(workId));
    final notesAsync = ref.watch(notesForWorkProvider(workId));
    final analyses = ref.watch(analysesForWorkProvider(workId));

    Future<void> openSessionDialog(
      Work work,
      List<ReadingSession> sessions, {
      ReadingSession? session,
    }) async {
      final total = sessions
          .where((item) => item.id != session?.id)
          .fold<int>(0, (sum, item) => sum + item.pagesRead);
      await showDialog<bool>(
        context: context,
        builder: (_) => ReadingSessionFormDialog(
          work: work,
          currentTotal: total,
          session: session,
        ),
      );
    }

    Future<void> confirmDeleteSession(ReadingSession session) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(AppStrings.deleteSessionTitle),
          content: const Text(AppStrings.deleteSessionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(readingSessionsDaoProvider).deleteSession(session.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.deleteError)),
          );
        }
      }
    }

    Future<void> confirmDeleteWork(Work work) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(AppStrings.deleteWorkTitle),
          content: const Text(AppStrings.deleteWorkBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(worksDaoProvider).deleteWork(work.id);
        if (context.mounted) context.go('/works');
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.deleteError)),
          );
        }
      }
    }

    Widget dataRow(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 140, child: Text(label)),
              Expanded(child: Text(value)),
            ],
          ),
        );

    return workAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.workDetails)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.workDetails)),
        body: const Center(child: Text(AppStrings.loadError)),
      ),
      data: (work) {
        if (work == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.workDetails)),
            body: const Center(child: Text(AppStrings.invalidWork)),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(work.title),
            actions: [
              IconButton(
                onPressed: () => context.go('/works/${work.id}/edit'),
                icon: const Icon(Icons.edit),
                tooltip: AppStrings.editWork,
              ),
              IconButton(
                onPressed: () => confirmDeleteWork(work),
                icon: const Icon(Icons.delete),
                tooltip: AppStrings.delete,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dataRow(
                          AppStrings.author,
                          work.author.isEmpty ? AppStrings.noRatingValue : work.author,
                        ),
                        dataRow(
                          AppStrings.type,
                          AppStrings.workTypeLabel(work.type),
                        ),
                        dataRow(
                          AppStrings.status,
                          AppStrings.workStatusLabel(work.status),
                        ),
                        dataRow(
                          AppStrings.genre,
                          work.genre.isEmpty ? AppStrings.noRatingValue : work.genre,
                        ),
                        dataRow(
                          AppStrings.year,
                          work.year?.toString() ?? AppStrings.noRatingValue,
                        ),
                        dataRow(
                          AppStrings.rating,
                          work.rating == null
                              ? AppStrings.noRatingValue
                              : formatRating(work.rating!),
                        ),
                        dataRow(
                          AppStrings.startedAt,
                          work.startedAt == null
                              ? AppStrings.noRatingValue
                              : formatDate(work.startedAt!),
                        ),
                        dataRow(
                          AppStrings.finishedAt,
                          work.finishedAt == null
                              ? AppStrings.noRatingValue
                              : formatDate(work.finishedAt!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                sessionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text(AppStrings.loadError)),
                  data: (sessions) {
                    final total = sessions.fold<int>(
                      0,
                      (sum, session) => sum + session.pagesRead,
                    );
                    final overflow =
                        work.pages != null && total > work.pages!;
                    final progress = work.pages == null || work.pages == 0
                        ? 0.0
                        : (total / work.pages!).clamp(0.0, 1.0);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.progress,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              work.pages == null
                                  ? '$total ${AppStrings.pagesWithoutTotal}'
                                  : '${AppStrings.pagesProgress} ${work.pages} '
                                      '(${(progress * 100).round()}%)',
                            ),
                            if (work.pages != null) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: progress),
                            ],
                            if (overflow) ...[
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.pagesOverflow,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () =>
                                  openSessionDialog(work, sessions),
                              icon: const Icon(Icons.add),
                              label: const Text(AppStrings.registerSession),
                            ),
                            if (sessions.isEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(AppStrings.noSessions),
                            ] else ...[
                              const SizedBox(height: 8),
                              for (final session in sessions)
                                ListTile(
                                  title: Text(
                                    '${formatDate(session.date)} • '
                                    '${session.pagesRead} ${AppStrings.pages.toLowerCase()}',
                                  ),
                                  subtitle: session.note == null
                                      ? null
                                      : Text(session.note!),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => openSessionDialog(
                                          work,
                                          sessions,
                                          session: session,
                                        ),
                                        icon: const Icon(Icons.edit),
                                        tooltip: AppStrings.editSession,
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            confirmDeleteSession(session),
                                        icon: const Icon(Icons.delete),
                                        tooltip: AppStrings.delete,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.linkedNotes,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                notesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text(AppStrings.loadError),
                  data: (notes) => notes.isEmpty
                      ? const Text(AppStrings.noLinkedNotes)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final note in notes)
                              Text(
                                '• ${note.label.isEmpty ? AppStrings.noteWithoutLabel : note.label}',
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.linkedAnalyses,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (analyses.isEmpty)
                  const Text(AppStrings.noLinkedAnalyses)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final analysis in analyses)
                        Text('• ${analysis.title}'),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
