import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/screens/dashboard/widgets/spending_chart.dart';

void main() {
  testWidgets('MonthlySpendingChart renders empty state when total is 0', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MonthlySpendingChart(
          categoryTotals: {
            ExpenseCategory.food: 0,
            ExpenseCategory.transport: 0,
            ExpenseCategory.shopping: 0,
            ExpenseCategory.bills: 0,
            ExpenseCategory.other: 0,
          },
          totalPaisa: 0,
        ),
      ),
    ));

    expect(find.text('Spending Distribution'), findsOneWidget);
    expect(find.text('No spending data for this month'), findsOneWidget);
  });

  testWidgets('MonthlySpendingChart renders categories with calculated percentages', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MonthlySpendingChart(
          categoryTotals: {
            ExpenseCategory.food: 50000,      // 50%
            ExpenseCategory.transport: 50000, // 50%
            ExpenseCategory.shopping: 0,
            ExpenseCategory.bills: 0,
            ExpenseCategory.other: 0,
          },
          totalPaisa: 100000,
        ),
      ),
    ));

    expect(find.text('Spending Distribution'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('50.0%'), findsNWidgets(2)); // Both food and transport are 50.0%
    expect(find.text('PKR 1,000.00'), findsOneWidget); // Center total
  });

  testWidgets('MonthlySpendingChart renders clean <0.1% label for tiny values without breaking UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MonthlySpendingChart(
          categoryTotals: {
            ExpenseCategory.food: 999950,     // 99.995%
            ExpenseCategory.transport: 50,    // 0.005% -> <0.1%
            ExpenseCategory.shopping: 0,
            ExpenseCategory.bills: 0,
            ExpenseCategory.other: 0,
          },
          totalPaisa: 1000000,
        ),
      ),
    ));

    expect(find.text('Spending Distribution'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('<0.1%'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
  });

  testWidgets('MonthlySpendingChart renders single category smoothly without errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MonthlySpendingChart(
          categoryTotals: {
            ExpenseCategory.food: 250000,
            ExpenseCategory.transport: 0,
            ExpenseCategory.shopping: 0,
            ExpenseCategory.bills: 0,
            ExpenseCategory.other: 0,
          },
          totalPaisa: 250000,
        ),
      ),
    ));

    expect(find.text('Spending Distribution'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('PKR 2,500.00'), findsOneWidget);
  });

  testWidgets('MonthlySpendingChart expands center summary smoothly for huge amounts without errors', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MonthlySpendingChart(
          categoryTotals: {
            ExpenseCategory.food: 5000000000,
            ExpenseCategory.transport: 7368766400,
            ExpenseCategory.shopping: 0,
            ExpenseCategory.bills: 0,
            ExpenseCategory.other: 0,
          },
          totalPaisa: 12368766400, // PKR 123,687,664.00
        ),
      ),
    ));

    final exception = tester.takeException();
    if (exception is FlutterError) {
      debugPrint(exception.toStringDeep());
    }
    expect(exception, isNull);
  });
}

