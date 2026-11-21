import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import 'readings_providers.dart';

class ReadingFormDialog extends ConsumerStatefulWidget {
  const ReadingFormDialog({
    required this.work,
    required this.number,
    this.reading,
    super.key,
  });

  final Work work;
  final int number;
  final Reading? reading;

  @override
  ConsumerState<ReadingFormDialog> createState() => _ReadingFormDialogState();
}

class _ReadingFormDialogState extends ConsumerState<ReadingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String _status = WorkStatus.queroLer;
  double? _rating;
  DateTime? _startedAt;
  DateTime? _finishedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reading = widget.reading;
    if (reading != null) {
      _status = reading.status;
      _rating = reading.rating;
      _startedAt = reading.startedAt;
      _finishedAt = reading.finishedAt;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = (isStart ? _startedAt : _finishedAt) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startedAt = picked;
        } else {
          _finishedAt = picked;
        }
      });
    }
  }

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required bool isStart,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${value == null ? AppStrings.noRatingValue : formatDate(value)}',
          ),
        ),
        TextButton(
          onPressed: () => _pickDate(isStart: isStart),
          child: const Text(AppStrings.chooseDate),
        ),
        IconButton(
          onPressed: () => setState(() {
            if (isStart) {
              _startedAt = null;
            } else {
              _finishedAt = null;
            }
          }),
          icon: const Icon(Icons.clear),
          tooltip: AppStrings.clearDate,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final data = ReadingWrite(
        status: _status,
        rating: _rating,
        startedAt: _startedAt,
        finishedAt: _finishedAt,
      );
      final db = ref.read(appDatabaseProvider);
      final reading = widget.reading;
      if (reading == null) {
        await addReading(
          db: db,
          workId: widget.work.id,
          reading: data,
          now: now,
        );
      } else {
        await saveReading(db: db, reading: reading, data: data, now: now);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reading == null ? AppStrings.readingAdded : AppStrings.readingSaved,
          ),
        ),
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
        '${widget.reading == null ? AppStrings.newReading : AppStrings.editReading}'
        ' • ${AppStrings.readingLabel(widget.number)}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: AppStrings.status,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: WorkStatus.queroLer,
                    child: Text(AppStrings.statusQueroLer),
                  ),
                  DropdownMenuItem(
                    value: WorkStatus.lendo,
                    child: Text(AppStrings.statusLendo),
                  ),
                  DropdownMenuItem(
                    value: WorkStatus.lido,
                    child: Text(AppStrings.statusLido),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double?>(
                initialValue: _rating,
                decoration: const InputDecoration(
                  labelText: AppStrings.rating,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<double?>(
                    value: null,
                    child: Text(AppStrings.noRating),
                  ),
                  for (var step = 1; step <= 10; step++)
                    DropdownMenuItem<double?>(
                      value: step / 2,
                      child: Text(formatRating(step / 2)),
                    ),
                ],
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 12),
              _dateRow(
                label: AppStrings.startedAt,
                value: _startedAt,
                isStart: true,
              ),
              _dateRow(
                label: AppStrings.finishedAt,
                value: _finishedAt,
                isStart: false,
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
