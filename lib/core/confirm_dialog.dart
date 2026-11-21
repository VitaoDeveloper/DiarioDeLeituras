import 'package:flutter/material.dart';

import 'strings.dart';

/// Mostra um diálogo de confirmação e retorna `true` somente ao confirmar.
///
/// `showDialog` usa o Navigator raiz por padrão. Os botões precisam usar o
/// `BuildContext` do builder para fechar a rota do diálogo; usar o contexto da
/// tela chamadora fecha o Navigator do branch e deixa o diálogo aberto.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String? confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel ?? AppStrings.delete),
        ),
      ],
    ),
  );
}
