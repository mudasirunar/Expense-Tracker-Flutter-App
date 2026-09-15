import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/widgets/delete_confirm_dialog.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('DeleteConfirmDialog Widget Tests', () {
    testWidgets('shows dialog with confirmation title and message', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DeleteConfirmDialog.show(context),
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Expense'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this expense? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancelling dialog returns false and preserves expense', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await DeleteConfirmDialog.show(context);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirming dialog returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await DeleteConfirmDialog.show(context);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
