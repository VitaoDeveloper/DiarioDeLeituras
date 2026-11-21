import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm_dialog.dart';
import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../notes/notes_providers.dart';
import 'reading_form.dart';
import 'reading_session_form.dart';
import 'readings_providers.dart';
import 'works_providers.dart';

class WorkDetailScreen extends ConsumerWidget {
  const WorkDetailScreen({required this.workId, super.key});

  final int workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workAsync = ref.watch(workProvider(workId));
    final readingsAsync = ref.watch(readingsForWorkProvider(workId));
    final notesAsync = ref.watch(notesForWorkProvider(workId));
    final analyses = ref.watch(analysesForWorkProvider(workId));

    void showMessage(String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }

    Future<void> openReadingDialog(
      Work work, {
      Reading? reading,
      required int number,
    }) async {
      await showDialog<bool>(
        context: context,
        builder: (_) => ReadingFormDialog(
          work: work,
          reading: reading,
          number: number,
        ),
      );
    }

    Future<void> confirmDeleteReading(Reading reading, int count) async {
      if (count <= 1) {
        showMessage(AppStrings.lastReadingError);
        return;
      }
      final confirmed = await showConfirmDialog(
        context: context,
        title: AppStrings.deleteReadingTitle,
        content: const Text(AppStrings.deleteReadingBody),
      );
      if (confirmed != true) return;
      try {
        await deleteReading(
          db: ref.read(appDatabaseProvider),
          readingId: reading.id,
        );
      } on LastReadingException {
        showMessage(AppStrings.lastReadingError);
        return;
      } catch (error) {
        debugPrint('Falha ao excluir leitura: $error');
        showMessage(AppStrings.deleteError);
      }
    }

    Future<void> confirmDeleteSession(ReadingSession session) async {
      final confirmed = await showConfirmDialog(
        context: context,
        title: AppStrings.deleteSessionTitle,
        content: const Text(AppStrings.deleteSessionBody),
      );
      if (confirmed != true) return;
      try {
        await ref.read(readingSessionsDaoProvider).deleteSession(session.id);
      } catch (error) {
        debugPrint('Falha ao excluir sessão: $error');
        showMessage(AppStrings.deleteError);
      }
    }

    Future<void> confirmDeleteWork(Work work) async {
      final confirmed = await showConfirmDialog(
        context: context,
        title: AppStrings.deleteWorkTitle,
        content: const Text(AppStrings.deleteWorkBody),
      );
      if (confirmed != true) return;
      try {
        await ref.read(worksDaoProvider).deleteWork(work.id);
        if (context.mounted) context.go('/works');
      } catch (error) {
        debugPrint('Falha ao excluir obra: $error');
        showMessage(AppStrings.deleteError);
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
                          work.author.isEmpty
                              ? AppStrings.noRatingValue
                              : work.author,
                        ),
                        dataRow(
                          AppStrings.type,
                          AppStrings.workTypeLabel(work.type),
                        ),
                        dataRow(
                          AppStrings.genre,
                          work.genre.isEmpty
                              ? AppStrings.noRatingValue
                              : work.genre,
                        ),
                        dataRow(
                          AppStrings.year,
                          work.year?.toString() ?? AppStrings.noRatingValue,
                        ),
                        dataRow(
                          AppStrings.pages,
                          work.pages?.toString() ?? AppStrings.noRatingValue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                readingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text(AppStrings.loadError)),
                  data: (readings) {
                    final nextNumber = readings.fold<int>(
                      0,
                      (max, item) => item.number > max ? item.number : max,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.readings,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => openReadingDialog(
                                work,
                                number: nextNumber + 1,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text(AppStrings.newReading),
                            ),
                          ],
                        ),
                        if (readings.isEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(AppStrings.noReadings),
                        ] else ...[
                          const SizedBox(height: 8),
                          for (final reading in readings)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReadingSection(
                                work: work,
                                reading: reading,
                                onEdit: () => openReadingDialog(
                                  work,
                                  reading: reading,
                                  number: reading.number,
                                ),
                                onDelete: () => confirmDeleteReading(
                                  reading,
                                  readings.length,
                                ),
                                onDeleteSession: confirmDeleteSession,
                              ),
                            ),
                        ],
                      ],
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

class _ReadingSection extends ConsumerWidget {
  const _ReadingSection({
    required this.work,
    required this.reading,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteSession,
  });

  final Work work;
  final Reading reading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(ReadingSession session) onDeleteSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsForReadingProvider(reading.id));

    Future<void> openSessionDialog(
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
          reading: reading,
          currentTotal: total,
          session: session,
        ),
      );
    }

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 140, child: Text(label)),
              Expanded(child: Text(value)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.readingLabel(reading.number),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: AppStrings.editReading,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  tooltip: AppStrings.delete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            row(
              AppStrings.status,
              AppStrings.workStatusLabel(reading.status),
            ),
            row(
              AppStrings.rating,
              reading.rating == null
                  ? AppStrings.noRatingValue
                  : formatRating(reading.rating!),
            ),
            row(
              AppStrings.startedAt,
              reading.startedAt == null
                  ? AppStrings.noRatingValue
                  : formatDate(reading.startedAt!),
            ),
            row(
              AppStrings.finishedAt,
              reading.finishedAt == null
                  ? AppStrings.noRatingValue
                  : formatDate(reading.finishedAt!),
            ),
            const SizedBox(height: 16),
            sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text(AppStrings.loadError)),
              data: (sessions) {
                final total = sessions.fold<int>(
                  0,
                  (sum, session) => sum + session.pagesRead,
                );
                final overflow = work.pages != null && total > work.pages!;
                final progress = work.pages == null || work.pages == 0
                    ? 0.0
                    : (total / work.pages!).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.progress,
                      style: Theme.of(context).textTheme.titleSmall,
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
                      onPressed: () => openSessionDialog(sessions),
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
                                  sessions,
                                  session: session,
                                ),
                                icon: const Icon(Icons.edit),
                                tooltip: AppStrings.editSession,
                              ),
                              IconButton(
                                onPressed: () => onDeleteSession(session),
                                icon: const Icon(Icons.delete),
                                tooltip: AppStrings.delete,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
