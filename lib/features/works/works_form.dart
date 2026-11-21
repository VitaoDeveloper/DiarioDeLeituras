import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../data/database.dart';
import 'readings_providers.dart';
import 'works_providers.dart';

class WorksFormScreen extends ConsumerStatefulWidget {
  const WorksFormScreen({this.workId, super.key});

  final int? workId;

  @override
  ConsumerState<WorksFormScreen> createState() => _WorksFormScreenState();
}

class _WorksFormScreenState extends ConsumerState<WorksFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();

  Future<Work?>? _loadFuture;
  String _type = WorkType.livro;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.workId != null) {
      _loadFuture = ref.read(worksDaoProvider).findById(widget.workId!);
      _loadFuture!.then((work) {
        if (work != null && mounted) {
          setState(() => _fill(work));
        }
      });
    }
  }

  void _fill(Work work) {
    _titleController.text = work.title;
    _authorController.text = work.author;
    _genreController.text = work.genre;
    _yearController.text = work.year?.toString() ?? '';
    _pagesController.text = work.pages?.toString() ?? '';
    _type = work.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredTitle;
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final year = int.tryParse(value.trim());
    if (year == null || year < 0 || year > DateTime.now().year) {
      return AppStrings.invalidYear;
    }
    return null;
  }

  String? _validatePages(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pages = int.tryParse(value.trim());
    if (pages == null || pages <= 0) return AppStrings.invalidPages;
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final yearText = _yearController.text.trim();
      final pagesText = _pagesController.text.trim();
      final year = yearText.isEmpty ? null : int.parse(yearText);
      final pages = pagesText.isEmpty ? null : int.parse(pagesText);
      final now = DateTime.now();

      final dao = ref.read(worksDaoProvider);
      if (widget.workId == null) {
        await createWorkWithReading(
          db: ref.read(appDatabaseProvider),
          work: WorksCompanion(
            type: Value(_type),
            title: Value(_titleController.text.trim()),
            author: Value(_authorController.text.trim()),
            genre: Value(_genreController.text.trim()),
            year: Value(year),
            pages: Value(pages),
          ),
          reading: const ReadingWrite(status: WorkStatus.queroLer),
          now: now,
        );
      } else {
        final existing = await dao.findById(widget.workId!);
        if (existing == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loadError)),
            );
          }
          return;
        }
        await dao.updateWork(
          existing.copyWith(
            type: _type,
            title: _titleController.text.trim(),
            author: _authorController.text.trim(),
            genre: _genreController.text.trim(),
            year: Value(year),
            pages: Value(pages),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.workSaved)),
        );
        context.go('/works');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildForm(List<String> genres) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: AppStrings.title,
                border: OutlineInputBorder(),
              ),
              validator: _validateTitle,
              autofocus: widget.workId == null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: AppStrings.author,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: AppStrings.genre,
                border: OutlineInputBorder(),
              ),
            ),
            if (genres.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.genreSuggestions,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final genre in genres)
                    ActionChip(
                      label: Text(genre),
                      onPressed: () => _genreController.text = genre,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.year,
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateYear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pagesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.pages,
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePages,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: AppStrings.type,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: WorkType.livro,
                  child: Text(AppStrings.typeLivro),
                ),
                DropdownMenuItem(
                  value: WorkType.artigo,
                  child: Text(AppStrings.typeArtigo),
                ),
                DropdownMenuItem(
                  value: WorkType.outro,
                  child: Text(AppStrings.typeOutro),
                ),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.readingFieldsHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genres = ref.watch(genresProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workId == null ? AppStrings.newWork : AppStrings.editWork,
        ),
      ),
      body: widget.workId == null || _loadFuture == null
          ? _buildForm(genres)
          : FutureBuilder<Work?>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null) {
                  return const Center(child: Text(AppStrings.invalidWork));
                }
                return _buildForm(genres);
              },
            ),
    );
  }
}
