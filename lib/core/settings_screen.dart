import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/backup_service.dart';
import 'app_drawer_button.dart';
import 'confirm_dialog.dart';
import 'strings.dart';

/// Tela de Configurações (exportar e importar dados), acessada pelo menu lateral.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider).exportBackup();
      _showMessage(context, AppStrings.exportSuccess);
    } on BackupException catch (error) {
      _showMessage(context, error.message);
    } catch (error) {
      debugPrint('Falha ao exportar backup: $error');
      _showMessage(context, AppStrings.exportError);
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(backupServiceProvider).pickBackup();
      if (data == null || !context.mounted) return;
      final confirmed = await showConfirmDialog(
        context: context,
        title: AppStrings.importTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.importConfirmation),
            const SizedBox(height: 8),
            Text(
              AppStrings.importSummary(
                data.workCount,
                data.readingCount,
                data.noteCount,
                data.analysisCount,
              ),
            ),
          ],
        ),
        confirmLabel: AppStrings.confirm,
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(backupServiceProvider).importBackup(data);
      if (!context.mounted) return;
      _showMessage(context, AppStrings.importSuccess);
      context.go('/works');
    } on BackupException catch (error) {
      _showMessage(context, error.message);
    } catch (error) {
      debugPrint('Falha ao importar backup: $error');
      _showMessage(context, AppStrings.importError);
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
            onTap: () => _export(context, ref),
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
