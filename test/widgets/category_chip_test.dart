import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/widgets/category_chip.dart';

void main() {
  testWidgets('CategoryChip displays label and responds to tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CategoryChip(
          category: ExpenseCategory.food,
          isSelected: false,
          onTap: () {
            tapped = true;
          },
        ),
      ),
    ));

    expect(find.text('Food'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);

    await tester.tap(find.byType(CategoryChip));
    expect(tapped, isTrue);
  });
}
