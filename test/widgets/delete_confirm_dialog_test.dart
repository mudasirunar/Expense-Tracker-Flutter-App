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

      expect(find.text('Delete Expense?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
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

    testWidgets('renders cleanly in landscape mode without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

      expect(find.text('Delete Expense?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
