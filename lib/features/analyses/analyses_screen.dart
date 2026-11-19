import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_drawer_button.dart';
import '../../core/formatters.dart';
import '../../core/strings.dart';
import 'analyses_providers.dart';

class AnalysesScreen extends ConsumerStatefulWidget {
  const AnalysesScreen({super.key});

  @override
  ConsumerState<AnalysesScreen> createState() => _AnalysesScreenState();
}

class _AnalysesScreenState extends ConsumerState<AnalysesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysesAsync = ref.watch(analysesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.analyses),
        leading: const AppDrawerButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/analyses/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: AppStrings.searchAnalyses,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: analysesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text(AppStrings.loadError)),
              data: (analyses) {
                final query = _searchController.text.trim().toLowerCase();
                final visible = analyses
                    .where(
                      (analysis) =>
                          analysis.title.toLowerCase().contains(query),
                    )
                    .toList();

                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      analyses.isEmpty
                          ? AppStrings.noAnalyses
                          : AppStrings.noAnalysesFilter,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final analysis = visible[index];
                    return ListTile(
                      title: Text(analysis.title),
                      subtitle: Text(
                        '${AppStrings.updatedAt}: ${formatDate(analysis.updatedAt)}',
                      ),
                      onTap: () =>
                          context.go('/analyses/${analysis.id}/edit'),
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
