import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_service.dart';
import 'app_drawer_button.dart';
import 'router.dart';
import 'strings.dart';

/// Tela de Configurações (exportar e importar dados), acessada pelo menu lateral.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showMessage(String message) {
    final context = rootScaffoldKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export(WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider).exportBackup();
      _showMessage(AppStrings.exportSuccess);
    } on BackupException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(AppStrings.exportError);
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(backupServiceProvider).pickBackup();
      if (data == null || !context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(AppStrings.importTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.importConfirmation),
              const SizedBox(height: 8),
              Text(
                AppStrings.importSummary(
                  data.workCount,
                  data.noteCount,
                  data.analysisCount,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.confirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(backupServiceProvider).importBackup(data);
      _showMessage(AppStrings.importSuccess);
    } on BackupException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(AppStrings.importError);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: const AppDrawerButton(),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text(AppStrings.exportData),
            onTap: () => _export(ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_open),
            title: const Text(AppStrings.importData),
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }
}
