import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm_dialog.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../works/works_providers.dart';
import 'analyses_providers.dart';

class AnalysisFormScreen extends ConsumerStatefulWidget {
  const AnalysisFormScreen({this.analysisId, super.key});

  final int? analysisId;

  @override
  ConsumerState<AnalysisFormScreen> createState() => _AnalysisFormScreenState();
}

class _AnalysisFormScreenState extends ConsumerState<AnalysisFormScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  Future<Analysis?>? _loadFuture;
  Set<int> _selectedWorkIds = <int>{};
  bool _loaded = true;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.analysisId != null) {
      _loaded = false;
      _loadFuture = ref.read(analysesDaoProvider).findById(widget.analysisId!);
      _loadFuture!.then((analysis) async {
        if (analysis == null) {
          if (mounted) setState(() => _loaded = true);
          return;
        }
        _titleController.text = analysis.title;
        _bodyController.text = analysis.body;
        try {
          final links = await ref
              .read(analysisWorksDaoProvider)
              .getByAnalysis(analysis.id);
          if (!mounted) return;
          setState(() {
            _selectedWorkIds = links.map((link) => link.workId).toSet();
            _loaded = true;
          });
        } catch (_) {
          if (mounted) {
            setState(() => _loaded = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loadError)),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<bool> _save({required bool leave}) async {
    if (_saving) return false;
    if (_saved) {
      if (leave && mounted) context.go('/analyses');
      return true;
    }
    if (!_loaded) {
      if (leave && mounted) context.go('/analyses');
      return true;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      final isEmptyNew = widget.analysisId == null &&
          _bodyController.text.trim().isEmpty &&
          _selectedWorkIds.isEmpty;
      if (isEmptyNew) {
        if (leave && mounted) context.go('/analyses');
        return true;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.requiredTitle)),
        );
      }
      return false;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      Analysis? existing;
      if (widget.analysisId != null) {
        existing = await ref
            .read(analysesDaoProvider)
            .findById(widget.analysisId!);
        if (existing == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loadError)),
            );
          }
          return false;
        }
      }

      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        await writeAnalysis(
          db: db,
          existing: existing,
          title: title,
          body: _bodyController.text,
          workIds: _selectedWorkIds,
          now: now,
        );
      });

      _saved = true;
      if (leave && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.analysisSaved)),
        );
        context.go('/analyses');
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveError)),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final analysisId = widget.analysisId;
    if (analysisId == null) return;
    final confirmed = await showConfirmDialog(
      context: context,
      title: AppStrings.deleteAnalysisTitle,
      content: const Text(AppStrings.deleteAnalysisBody),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(analysesDaoProvider).deleteAnalysis(analysisId);
      _saved = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.analysisDeleted)),
        );
        context.go('/analyses');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.deleteError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _editor(List<Work> works) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: AppStrings.title,
              border: OutlineInputBorder(),
            ),
            autofocus: widget.analysisId == null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: AppStrings.analysisBody,
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.linkedWorks,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (works.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(AppStrings.noWorks),
            )
          else
            for (final work in works)
              CheckboxListTile(
                title: Text(work.title),
                subtitle: Text(
                  '${AppStrings.workTypeLabel(work.type)} • ${work.author}',
                ),
                value: _selectedWorkIds.contains(work.id),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selectedWorkIds.add(work.id);
                  } else {
                    _selectedWorkIds.remove(work.id);
                  }
                }),
              ),
          const SizedBox(height: 16),
          Text(
            AppStrings.autoSaveHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worksAsync = ref.watch(worksProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _save(leave: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.analysisId == null
                ? AppStrings.newAnalysis
                : AppStrings.editAnalysis,
          ),
          leading: BackButton(
            onPressed: _saving ? null : () => _save(leave: true),
          ),
          actions: [
            IconButton(
              onPressed: _saving ? null : () => _save(leave: true),
              icon: const Icon(Icons.check),
              tooltip: AppStrings.save,
            ),
            if (widget.analysisId != null)
              IconButton(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete),
                tooltip: AppStrings.delete,
              ),
          ],
        ),
        body: worksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text(AppStrings.loadError)),
          data: (works) {
            if (widget.analysisId == null || _loadFuture == null) {
              return _editor(works);
            }
            return FutureBuilder<Analysis?>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null) {
                  return const Center(child: Text(AppStrings.invalidAnalysis));
                }
                return _editor(works);
              },
            );
          },
        ),
      ),
    );
  }
}
