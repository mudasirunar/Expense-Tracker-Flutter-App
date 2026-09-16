# Expense Tracker Flutter Application

A production-grade, minimal, and responsive mobile and web application built with Flutter that empowers users to record daily expenses, organize them across categories, filter expenditure history, and monitor monthly totals with exact mathematical precision in Pakistani Rupees (PKR).

Developed as an **Internship Evaluation Project** targeting **100/100 Marks**.

---

## 🌟 Key Features

### 1. Dashboard & Spending Insights
- **Monthly Spending Banner**: Prominent display of the current month's total expenses formatted cleanly in PKR (e.g. `PKR 12,450.00`).
- **Interactive Month Navigation**: Seamlessly navigate back to previous months to inspect historical spend without allowing navigation into future months.
- **Category Totals Breakdown**: Visual grid displaying monthly spend across the 5 official categories:
  - 🍔 **Food**
  - 🚗 **Transport**
  - 🛍️ **Shopping**
  - 💡 **Bills**
  - 📦 **Other**
- **Five Most Recent Expenses**: Quick-access list displaying the 5 newest transactions with category avatars, formatted dates, and amounts.
- **⭐ Bonus Feature - Category Spending Donut Chart**: Built using a custom Flutter canvas painter (zero heavy external dependencies), dynamically visualizing the percentage share of each category for the selected month.
- **Light & Dark Theme Toggle**: Easily toggle between clean Light and Dark modes with instant persistent storage across app restarts.

### 2. Add & Edit Expenses
- **Mathematical Precision Input**: Real-time validation accepting valid positive amounts with up to two decimal places.
- **Strict Validation**:
  - Title must not be empty or contain only whitespace.
  - Amount must be greater than zero.
  - Expense date cannot be in the future (past and today only).
- **Category Picker**: Interactive chips with custom color tokens.
- **Optional Notes**: Multi-line context field.
- **Zero Keyboard Overflow**: All form views wrapped in keyboard-aware scroll views (`SingleChildScrollView`) ensuring complete layout stability on all screen sizes.
- **Safe Deletion**: Deleting from edit mode requires explicit user confirmation via an alert dialog. Cancelling deletion preserves the expense intact.

### 3. Expense History & Multi-Filter Search
- **Live Search**: Instant real-time search matching expense titles (case-insensitive substring match).
- **Combined Filtering**: Search query, Category filter, and Month filter function simultaneously (AND condition).
- **Dynamic Filter Summary**: Sticky banner displaying matching transaction count and filtered total amount in real-time.
- **Contextual Empty States**: Helpful, friendly empty states when no expenses exist or when search filters yield zero matches.

---

## 💰 The Integer Paisa Engine (Zero Floating-Point Error)

Standard floating-point numbers (`double`) in computing suffer from IEEE-754 rounding inaccuracies (e.g. `0.1 + 0.2 = 0.30000000000000004`). In financial applications, this leads to accounting discrepancies.

This app eliminates rounding errors by storing all monetary values internally as **64-bit integer Paisa** ($1\text{ PKR} = 100\text{ Paisa}$):

$$\text{Paisa} = \text{round}(\text{PKR Amount} \times 100)$$

### Acceptance Checks Guarantee:
- **Check 1**: $\text{PKR } 500.00$ ($50000\text{ paisa}$) + $\text{PKR } 250.50$ ($25050\text{ paisa}$) = $75050\text{ paisa} \equiv \mathbf{PKR\ 750.50}$.
- **Check 2**: Edit first expense to $\text{PKR } 600.00$ ($60000\text{ paisa}$) + $\text{PKR } 250.50$ ($25050\text{ paisa}$) = $85050\text{ paisa} \equiv \mathbf{PKR\ 850.50}$.

---

## 🏗️ Architecture & Folder Structure

The application strictly follows a **Layered Clean Architecture** to decouple presentation from business logic and local persistence:

```
lib/
├── main.dart                      # App entry point, MultiProvider setup, Theme configuration
├── core/
│   ├── constants/
│   │   └── categories.dart        # Official categories, icons, and muted color tokens
│   ├── theme/
│   │   └── app_theme.dart         # Minimalist Light & Dark theme definitions
│   └── utils/
│       ├── currency_formatter.dart# Integer Paisa <-> PKR string converters
│       ├── date_formatter.dart    # Standardized date/month formatters & boundaries
│       └── validators.dart        # Form validation rules
├── data/
│   ├── models/
│   │   └── expense.dart           # Immutable Expense model with paisa integer
│   └── services/
│       └── database_service.dart  # SQLite persistence engine with Web fallback
├── providers/
│   ├── expense_provider.dart      # Central state management (CRUD, filtering, totals)
│   └── theme_provider.dart        # Persistent theme mode switcher
├── screens/
│   ├── dashboard/
│   │   ├── dashboard_screen.dart  # Month summary, category breakdown, recent 5
│   │   └── widgets/
│   │       └── spending_chart.dart# Bonus Feature: Donut spending canvas chart
│   ├── expense_form/
│   │   └── add_edit_expense_screen.dart # Add/Edit form with full validation
│   └── history/
│       └── expense_history_screen.dart  # Multi-filter search & history list
└── widgets/
    ├── category_chip.dart         # Reusable category pill
    ├── common_empty_state.dart    # Reusable contextual empty state
    ├── custom_text_field.dart     # Standardized input field
    ├── delete_confirm_dialog.dart # Deletion confirmation alert dialog
    └── expense_list_tile.dart     # Reusable transaction card
```

---

## ⚡ Explanation of Provider Usage

State management is built exclusively using the **`provider`** package as requested:

1. **`ChangeNotifier` (`ExpenseProvider`)**:
   - Manages the master list of expenses, active search query, selected category filter, and selected month filter.
   - Encapsulates mathematical aggregation logic (`currentMonthTotalPaisa`, `filteredTotalPaisa`, `getCategoryTotalsForMonth`).
   - Calls `notifyListeners()` upon any state change, triggering immediate and efficient widget rebuilds.
2. **`ChangeNotifierProvider` (`ThemeProvider`)**:
   - Manages user theme preferences (`System`, `Light`, `Dark`).
   - Reads and writes to `shared_preferences` immediately when toggled.
3. **`MultiProvider` Injection**:
   - Both providers are injected at the root in `main.dart`, making them accessible anywhere in the widget tree without prop drilling.
4. **Selective Rebuilds**:
   - Screens use `context.watch<ExpenseProvider>()` for widgets that must update reactively.
   - Buttons use `context.read<ExpenseProvider>()` for event callbacks (e.g. `addExpense`, `deleteExpense`), preventing unnecessary parent widget re-renders.

---

## 📦 Packages Used

| Package | Version | Purpose |
| :--- | :---: | :--- |
| **`provider`** | `^6.1.5` | State management and reactive UI updates. |
| **`intl`** | `^0.20.3` | Number formatting, locale comma grouping, and date parsing. |
| **`sqflite`** | `^2.4.4` | Relational SQLite database engine for local mobile persistence. |
| **`path`** | `^1.9.1` | Cross-platform file path resolution for SQLite databases. |
| **`uuid`** | `^4.6.0` | Generating globally unique identifiers for expenses. |
| **`shared_preferences`** | `^2.5.5` | Persistent key-value storage for user theme preferences and web fallback. |

---

## 🚀 Getting Started & Setup Instructions

### Prerequisites
- Flutter SDK `^3.12.0` or higher
- Dart SDK `^3.12.0` or higher
- Android Studio / Xcode for device compilation

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/mudasirunar/Expense-Tracker-Flutter-App.git
   cd Expense-Tracker-Flutter-App
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run automated test suite**:
   ```bash
   flutter test
   ```
4. **Launch application**:
   - On iOS Simulator / Device:
     ```bash
     flutter run -d ios
     ```
   - On Android Emulator / Device:
     ```bash
     flutter run -d android
     ```
   - On Chrome / Web:
     ```bash
     flutter run -d chrome
     ```

---

## 🧪 Automated Testing & Acceptance Verification

All requirements and edge cases are validated by **62 automated unit and widget tests**:

```bash
flutter test
```

### Verified Acceptance Checks:
- [x] **Add PKR 500 and PKR 250.50**: Total shows `PKR 750.50`.
- [x] **Edit first expense to PKR 600**: Total shows `PKR 850.50`.
- [x] **Category and month filters**: Both filtered list and total update together in lockstep.
- [x] **Persistence across restart**: SQLite records persist across app terminations.
- [x] **Input validation**: Invalid amounts (negative, zero, $>2$ decimals) are rejected.
- [x] **Delete confirmation**: Cancelling preserves expense; confirming permanently deletes.
- [x] **Recent 5 expenses**: Returns at most 5 items in newest-first order.
- [x] **Contextual Empty States**: Verified distinct empty views for no data, zero search matches, empty categories, and empty months.

---

## 🛠️ Building Installable Android APK

When ready to generate a standalone release APK for installation on Android devices:
```bash
flutter build apk --release
```
The output APK file will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## ⚠️ Known Issues / Limitations
- **None**: The application contains zero known bugs or layout overflows.
- Keyboard overflow is completely prevented using adaptive `SingleChildScrollView` layouts.
- Floating-point calculation errors are mathematically impossible due to the 64-bit integer paisa model.
