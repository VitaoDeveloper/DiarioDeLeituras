import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text(AppStrings.works)),
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
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.statusFilter,
                      isDense: true,
                    ),
                    initialValue: _status,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(AppStrings.all),
                      ),
                      for (final status in WorkStatus.values)
                        DropdownMenuItem<String?>(
                          value: status,
                          child: Text(
                            AppStrings.workStatusLabel(status),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.typeFilter,
                      isDense: true,
                    ),
                    initialValue: _type,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(AppStrings.all),
                      ),
                      for (final type in WorkType.values)
                        DropdownMenuItem<String?>(
                          value: type,
                          child: Text(
                            AppStrings.workTypeLabel(type),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _type = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.genreFilter,
                      isDense: true,
                    ),
                    initialValue: _genre,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(AppStrings.all),
                      ),
                      for (final genre in genres)
                        DropdownMenuItem<String?>(
                          value: genre,
                          child: Text(
                            genre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _genre = value),
                  ),
                ),
              ],
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
