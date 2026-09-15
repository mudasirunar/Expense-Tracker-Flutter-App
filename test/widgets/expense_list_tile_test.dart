import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/widgets/expense_list_tile.dart';

void main() {
  testWidgets('ExpenseListTile renders title, formatted amount, category and notes', (tester) async {
    final expense = Expense(
      title: 'Dinner with team',
      amountPaisa: 75050,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 15),
      notes: 'Celebration dinner',
    );

    bool tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseListTile(
          expense: expense,
          onTap: () {
            tapped = true;
          },
        ),
      ),
    ));

    expect(find.text('Dinner with team'), findsOneWidget);
    expect(find.text('PKR 750.50'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Celebration dinner'), findsOneWidget);

    await tester.tap(find.byType(ExpenseListTile));
    expect(tapped, isTrue);
  });
}
