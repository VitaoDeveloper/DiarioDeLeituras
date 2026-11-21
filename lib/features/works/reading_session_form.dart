import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import 'works_providers.dart';

class ReadingSessionFormDialog extends ConsumerStatefulWidget {
  const ReadingSessionFormDialog({
    required this.work,
    required this.reading,
    required this.currentTotal,
    this.session,
    super.key,
  });

  final Work work;
  final Reading reading;
  final int currentTotal;
  final ReadingSession? session;

  @override
  ConsumerState<ReadingSessionFormDialog> createState() =>
      _ReadingSessionFormDialogState();
}

class _ReadingSessionFormDialogState
    extends ConsumerState<ReadingSessionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pagesController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _date = session?.date ?? DateTime.now();
    _pagesController.text = session?.pagesRead.toString() ?? '';
    _noteController.text = session?.note ?? '';
  }

  @override
  void dispose() {
    _pagesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _validatePages(String? value) {
    final pages = int.tryParse(value?.trim() ?? '');
    if (pages == null || pages <= 0) return AppStrings.invalidPagesRead;
    // Em edição, `currentTotal` já desconta a página da sessão atual.
    final total = widget.work.pages;
    if (total != null && widget.currentTotal + pages > total) {
      return AppStrings.pagesOverflowValidation;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final pages = int.parse(_pagesController.text.trim());
      final noteText = _noteController.text.trim();
      final note = noteText.isEmpty ? null : noteText;
      final dao = ref.read(readingSessionsDaoProvider);
      final session = widget.session;

      if (session == null) {
        await dao.insertSession(
          ReadingSessionsCompanion(
            workId: Value(widget.work.id),
            readingId: Value(widget.reading.id),
            date: Value(_date),
            pagesRead: Value(pages),
            note: Value(note),
          ),
        );
      } else {
        await dao.updateSession(
          session.copyWith(date: _date, pagesRead: pages, note: Value(note)),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.sessionSaved)),
      );
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.session == null
            ? AppStrings.registerSession
            : AppStrings.editSession,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.sessionDate}: ${formatDate(_date)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text(AppStrings.chooseDate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pagesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.pagesRead,
                  border: OutlineInputBorder(),
                ),
                validator: _validatePages,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: AppStrings.sessionNote,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
