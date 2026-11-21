import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm_dialog.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../works/works_providers.dart';
import 'notes_providers.dart';

class NotesFormScreen extends ConsumerStatefulWidget {
  const NotesFormScreen({this.noteId, super.key});

  final int? noteId;

  @override
  ConsumerState<NotesFormScreen> createState() => _NotesFormScreenState();
}

class _QuoteDraft {
  _QuoteDraft({
    this.original,
    String text = '',
    String page = '',
    String comment = '',
  })  : textController = TextEditingController(text: text),
        pageController = TextEditingController(text: page),
        commentController = TextEditingController(text: comment);

  final Quote? original;
  final TextEditingController textController;
  final TextEditingController pageController;
  final TextEditingController commentController;

  void dispose() {
    textController.dispose();
    pageController.dispose();
    commentController.dispose();
  }
}

class _NotesFormScreenState extends ConsumerState<NotesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _summaryController = TextEditingController();
  final _thesisController = TextEditingController();
  final _conceptsController = TextEditingController();
  final _critiqueController = TextEditingController();

  Future<Note?>? _loadFuture;
  List<_QuoteDraft> _quotes = [];
  Set<int> _originalQuoteIds = const <int>{};
  int? _workId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadFuture = ref.read(notesDaoProvider).findById(widget.noteId!);
      _loadFuture!.then((note) async {
        if (note == null || !mounted) return;
        setState(() => _fill(note));
        try {
          final quotes = await ref.read(quotesDaoProvider).getByNote(note.id);
          if (!mounted) return;
          setState(() {
            _quotes = [
              for (final quote in quotes)
                _QuoteDraft(
                  original: quote,
                  text: quote.content,
                  page: quote.page?.toString() ?? '',
                  comment: quote.comment ?? '',
                ),
            ];
            _originalQuoteIds = quotes.map((quote) => quote.id).toSet();
          });
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loadError)),
            );
          }
        }
      });
    } else {
      final works = ref.read(worksProvider).value ?? const <Work>[];
      if (works.isNotEmpty) _workId = works.first.id;
    }
  }

  void _fill(Note note) {
    _workId = note.workId;
    _labelController.text = note.label;
    _summaryController.text = note.summary;
    _thesisController.text = note.thesis;
    _conceptsController.text = note.concepts;
    _critiqueController.text = note.critique;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _summaryController.dispose();
    _thesisController.dispose();
    _conceptsController.dispose();
    _critiqueController.dispose();
    for (final draft in _quotes) {
      draft.dispose();
    }
    super.dispose();
  }

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _validateOptionalPositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return AppStrings.invalidPages;
    return null;
  }

  void _addQuote() => setState(() => _quotes.add(_QuoteDraft()));

  Future<void> _removeQuote(int index) async {
    final draft = _quotes[index];
    if (draft.original != null) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: AppStrings.deleteQuoteTitle,
        content: const Text(AppStrings.deleteQuoteBody),
        confirmLabel: AppStrings.removeQuote,
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      draft.dispose();
      _quotes.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectWork)),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      Note? existing;
      if (widget.noteId != null) {
        existing = await ref.read(notesDaoProvider).findById(widget.noteId!);
        if (existing == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loadError)),
            );
          }
          return;
        }
      }

      final quotes = [
        for (final draft in _quotes)
          QuoteWrite(
            original: draft.original,
            content: draft.textController.text.trim(),
            page: draft.pageController.text.trim().isEmpty
                ? null
                : int.parse(draft.pageController.text.trim()),
            comment: draft.commentController.text.trim().isEmpty
                ? null
                : draft.commentController.text.trim(),
          ),
      ];

      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        await writeNote(
          db: db,
          existing: existing,
          workId: _workId!,
          label: _labelController.text.trim(),
          summary: _summaryController.text.trim(),
          thesis: _thesisController.text.trim(),
          concepts: _conceptsController.text.trim(),
          critique: _critiqueController.text.trim(),
          quotes: quotes,
          originalQuoteIds: _originalQuoteIds,
          now: now,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.noteSaved)),
        );
        context.go('/notes');
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

  Future<void> _deleteNote() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: AppStrings.deleteNoteTitle,
      content: const Text(AppStrings.deleteNoteBody),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(notesDaoProvider).deleteNote(widget.noteId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.noteDeleted)),
        );
        context.go('/notes');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.deleteError)),
        );
      }
    }
  }

  Widget _quoteCard(int index) {
    final draft = _quotes[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.quoteTitle(index + 1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeQuote(index),
                  icon: const Icon(Icons.delete),
                  tooltip: AppStrings.removeQuote,
                ),
              ],
            ),
            TextFormField(
              controller: draft.textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.quoteText,
                border: OutlineInputBorder(),
              ),
              validator: (value) => _validateRequired(
                value,
                AppStrings.requiredQuoteText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.pageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.quotePage,
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateOptionalPositiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: draft.commentController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.quoteComment,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<Work> works) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _workId,
              decoration: const InputDecoration(
                labelText: AppStrings.noteWork,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final work in works)
                  DropdownMenuItem<int>(
                    value: work.id,
                    child: Text(
                      work.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _workId = value),
              validator: (value) =>
                  value == null ? AppStrings.selectWork : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: AppStrings.label,
                border: OutlineInputBorder(),
              ),
              autofocus: widget.noteId == null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.summary,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _thesisController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.thesis,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conceptsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.concepts,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _critiqueController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.critique,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.quotes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _addQuote,
                  icon: const Icon(Icons.add),
                  tooltip: AppStrings.addQuote,
                ),
              ],
            ),
            for (var index = 0; index < _quotes.length; index++) ...[
              _quoteCard(index),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: _addQuote,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addQuote),
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
    final worksAsync = ref.watch(worksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.noteId == null ? AppStrings.newNote : AppStrings.editNote,
        ),
        actions: [
          if (widget.noteId != null)
            IconButton(
              onPressed: _deleteNote,
              icon: const Icon(Icons.delete),
              tooltip: AppStrings.delete,
            ),
        ],
      ),
      body: worksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(AppStrings.loadError)),
        data: (works) {
          if (works.isEmpty) {
            return const Center(child: Text(AppStrings.needWorkForNote));
          }
          if (widget.noteId == null || _loadFuture == null) {
            return _buildForm(works);
          }
          return FutureBuilder<Note?>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data == null) {
                return const Center(child: Text(AppStrings.invalidNote));
              }
              return _buildForm(works);
            },
          );
        },
      ),
    );
  }
}
