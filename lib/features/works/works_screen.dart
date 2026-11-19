import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_drawer_button.dart';
import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../stats/stats_providers.dart';
import 'works_providers.dart';

class WorksScreen extends ConsumerStatefulWidget {
  const WorksScreen({super.key});

  @override
  ConsumerState<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends ConsumerState<WorksScreen> {
  final _searchController = TextEditingController();
  String? _status;
  String? _type;
  String? _genre;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _streakIndicator(StreakInfo streak) {
    return ListTile(
      leading: const Icon(Icons.local_fire_department_outlined),
      title: Text(
        streak.current == 0
            ? AppStrings.noStreak
            : AppStrings.streakLabel(streak.current),
      ),
      subtitle: streak.atRisk ? const Text(AppStrings.readTodayHint) : null,
      onTap: () => context.go('/stats'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worksAsync = ref.watch(worksProvider);
    final genres = ref.watch(genresProvider);
    final streak = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.works),
        leading: const AppDrawerButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/works/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _streakIndicator(streak),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: AppStrings.searchWorks,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final filterWidth = wide
                    ? (constraints.maxWidth - 16) / 3
                    : (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: filterWidth,
                      child: DropdownMenu<String?>(
                        label: const Text(AppStrings.statusFilter),
                        initialSelection: _status,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: AppStrings.all,
                          ),
                          for (final status in WorkStatus.values)
                            DropdownMenuEntry<String?>(
                              value: status,
                              label: AppStrings.workStatusLabel(status),
                            ),
                        ],
                        onSelected: (value) => setState(() => _status = value),
                      ),
                    ),
                    SizedBox(
                      width: filterWidth,
                      child: DropdownMenu<String?>(
                        label: const Text(AppStrings.typeFilter),
                        initialSelection: _type,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: AppStrings.all,
                          ),
                          for (final type in WorkType.values)
                            DropdownMenuEntry<String?>(
                              value: type,
                              label: AppStrings.workTypeLabel(type),
                            ),
                        ],
                        onSelected: (value) => setState(() => _type = value),
                      ),
                    ),
                    SizedBox(
                      width: filterWidth,
                      child: DropdownMenu<String?>(
                        label: const Text(AppStrings.genreFilter),
                        initialSelection: _genre,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: AppStrings.all,
                          ),
                          for (final genre in genres)
                            DropdownMenuEntry<String?>(
                              value: genre,
                              label: genre,
                            ),
                        ],
                        onSelected: (value) => setState(() => _genre = value),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: worksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text(AppStrings.loadError)),
              data: (works) {
                final query = _searchController.text.trim().toLowerCase();
                final visible = works.where((work) {
                  if (_status != null && work.status != _status) return false;
                  if (_type != null && work.type != _type) return false;
                  if (_genre != null && work.genre != _genre) return false;
                  if (query.isEmpty) return true;
                  return work.title.toLowerCase().contains(query) ||
                      work.author.toLowerCase().contains(query);
                }).toList();

                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      works.isEmpty
                          ? AppStrings.noWorks
                          : AppStrings.noWorksFilter,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final work = visible[index];
                    return ListTile(
                      title: Text(work.title),
                      subtitle: Text(
                        '${work.author} • '
                        '${AppStrings.workTypeLabel(work.type)} • '
                        '${AppStrings.workStatusLabel(work.status)}',
                      ),
                      trailing: Text(
                        work.rating == null
                            ? AppStrings.noRatingValue
                            : formatRating(work.rating!),
                      ),
                      onTap: () => context.go('/works/${work.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
