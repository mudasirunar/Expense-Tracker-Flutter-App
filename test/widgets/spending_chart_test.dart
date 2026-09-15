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
}
