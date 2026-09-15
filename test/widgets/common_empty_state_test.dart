import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/widgets/common_empty_state.dart';

void main() {
  testWidgets('CommonEmptyState displays title, message, and handles action button', (tester) async {
    bool actionClicked = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommonEmptyState(
          title: 'No Expenses Found',
          message: 'Try changing your search query or clear filters.',
          actionLabel: 'Clear Filters',
          onAction: () {
            actionClicked = true;
          },
        ),
      ),
    ));

    expect(find.text('No Expenses Found'), findsOneWidget);
    expect(find.text('Try changing your search query or clear filters.'), findsOneWidget);
    expect(find.text('Clear Filters'), findsOneWidget);

    await tester.tap(find.text('Clear Filters'));
    expect(actionClicked, isTrue);
  });
}
