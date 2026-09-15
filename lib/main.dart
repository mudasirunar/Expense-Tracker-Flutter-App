import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Enable true edge-to-edge mode so status bar seamlessly matches app background
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
          final isDark = themeProvider.isCurrentlyDark(context);
          final overlayStyle = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          );
          SystemChrome.setSystemUIOverlayStyle(overlayStyle);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: MaterialApp(
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
            ),
          );
        },
      ),
    );
  }
}
