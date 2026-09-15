import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/services/database_service.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expense_form/add_edit_expense_screen.dart';
import 'screens/history/expense_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent services
  final prefs = await SharedPreferences.getInstance();
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    MyApp(
      databaseService: databaseService,
      prefs: prefs,
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.databaseService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(databaseService)..loadExpenses(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Builder(
              builder: (navContext) => DashboardScreen(
                onNavigateToHistory: () {
                  Navigator.of(navContext).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpenseHistoryScreen(),
                    ),
                  );
                },
                onAddExpensePressed: () {
                  Navigator.of(navContext).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditExpenseScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
