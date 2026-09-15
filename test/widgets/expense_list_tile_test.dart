import 'package:flutter/cupertino.dart';
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

  testWidgets('ExpenseListTile handles huge amounts on narrow screen without RenderFlex overflow', (tester) async {
    // Simulate a compact mobile screen width (e.g. 360 x 800)
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final hugeExpense = Expense(
      title: 'Very Long Purchase Title For Major Project Hardware',
      amountPaisa: 9999999999, // PKR 99,999,999.99
      category: ExpenseCategory.transport,
      date: DateTime(2026, 9, 15),
      notes: 'Company fleet overhaul expenses note',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseListTile(
          expense: hugeExpense,
          onTap: () {},
        ),
      ),
    ));

    expect(find.text('Transport'), findsOneWidget);
    final exception = tester.takeException();
    if (exception is FlutterError) {
      for (final d in exception.diagnostics) {
        debugPrint('DIAG: ${d.toString()}');
      }
    }
    expect(exception, isNull);
  });

  testWidgets('ExpenseListTile shows category chip when showCategoryChip is true, hides when false', (tester) async {
    final expense = Expense(
      title: 'Groceries',
      amountPaisa: 120000,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 15),
    );

    // 1. When showCategoryChip is true (All categories view)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseListTile(
          expense: expense,
          showCategoryChip: true,
          onDelete: () {},
        ),
      ),
    ));

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Sep 15, 2026'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);

    // 2. When showCategoryChip is false (Specific category filtered view)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseListTile(
          expense: expense,
          showCategoryChip: false,
          onDelete: () {},
        ),
      ),
    ));

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Food'), findsNothing); // Chip is hidden
    expect(find.text('Sep 15, 2026'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
  });
}



