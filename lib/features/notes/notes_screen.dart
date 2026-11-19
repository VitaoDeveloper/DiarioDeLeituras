import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_drawer_button.dart';
import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../works/works_providers.dart';
import 'notes_providers.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNote() {
    final works = ref.read(worksProvider).value ?? const <Work>[];
    if (works.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.needWorkForNote)),
      );
      return;
    }
    context.go('/notes/new');
  }

  Widget _buildGroups(List<Work> works, List<Note> notes) {
    if (notes.isEmpty) {
      return const Center(child: Text(AppStrings.noNotes));
    }

    final worksById = {for (final work in works) work.id: work};
    final query = _searchController.text.trim().toLowerCase();
    final groups = <Work, List<Note>>{};

    for (final note in notes) {
      final work = worksById[note.workId];
      if (work == null) continue;
      if (query.isNotEmpty) {
        final searchable = [
          note.label,
          note.summary,
          note.thesis,
          note.concepts,
          note.critique,
          work.title,
          work.author,
        ].join(' ').toLowerCase();
        if (!searchable.contains(query)) continue;
      }
      groups.putIfAbsent(work, () => []).add(note);
    }

    if (groups.isEmpty) {
      return const Center(child: Text(AppStrings.noNotesFilter));
    }

    final sortedWorks = groups.keys.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return ListView.builder(
      itemCount: sortedWorks.length,
      itemBuilder: (context, index) {
        final work = sortedWorks[index];
        final workNotes = groups[work]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                work.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final note in workNotes)
              ListTile(
                title: Text(
                  note.label.isEmpty
                      ? AppStrings.noteWithoutLabel
                      : note.label,
                ),
                subtitle: Text(
                  note.summary.isEmpty ? AppStrings.noSummary : note.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(formatDate(note.updatedAt)),
                onTap: () => context.go('/notes/${note.id}/edit'),
              ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final worksAsync = ref.watch(worksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notes),
        leading: const AppDrawerButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: AppStrings.searchNotes,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: worksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text(AppStrings.loadError)),
              data: (works) => notesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text(AppStrings.loadError)),
                data: (notes) => _buildGroups(works, notes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
