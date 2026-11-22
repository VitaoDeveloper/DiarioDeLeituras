import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/core/confirm_dialog.dart';
import 'package:reading_management/core/strings.dart';

class _BranchScreen extends StatelessWidget {
  const _BranchScreen(this.onConfirmed);

  final ValueChanged<bool?> onConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branch')),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final confirmed = await showConfirmDialog(
              context: context,
              title: AppStrings.deleteReadingTitle,
              content: const Text(AppStrings.deleteReadingBody),
            );
            onConfirmed(confirmed);
          },
          child: const Text(AppStrings.delete),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('confirmar diálogo não remove a rota do navigator do branch',
      (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => _BranchScreen((value) => confirmed = value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.delete),
      ),
    );
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Branch'), findsOneWidget);
  });
}
