# SpendWise — Smart Money & Value Comparison Mobile App

A modern **Flutter + Firebase** mobile application that combines everyday personal expense tracking with unit-price brand comparison, cheapest-shop discovery, and a Quality + Price Value Score engine.

## Core Features

### 1. Complete Money & Expense Tracking
- **Flexible Time Periods**: Filter spending & income by **Week, Month, 90 Days, Year, All Time, or Custom Date Range**.
- **Category Tracking + Inline Creation**: Log expenses/income by category and create custom categories directly inside the **Add Transaction** sheet.
- **Income & Net Balance**: Track income vs. expenses and total net balance across wallets.
- **Category Budgets & Alerts**: Monthly/weekly limits with color-coded progress bars and automatic dashboard alerts at ≥80% and >100%.
- **Recurring Bills & Subscriptions**: Track rent, utilities, and subscriptions with one-tap **Log Now** that records the expense and advances the next due date.
- **Multiple Accounts / Payment Methods**: Separate live balances for Bank, Credit Card, Debit Card, Cash, and Digital Wallets.
- **Receipt Notes, Photo Attachments & CSV Export**: Attach receipt notes/photos (uploaded to Firebase Storage) and export filtered transactions + unit prices to CSV.

### 2. Goods, Brand, Shop & Value Comparison
- **Brand Unit-Price Comparison (`/100g`, `/100ml`, `/pc`)**: Automatically normalizes any package size and multi-pack count (`g`, `kg`, `ml`, `L`, `pcs`) to compare brands apples-to-apples.
- **Cheapest Shop Finder by Category**: Uses a normalized **Category Price Index** (ratio of each shop's unit price to the cross-shop average per product) so expensive items don't skew shop rankings.
- **Best Value Engine (Quality + Experience + Price)**: Evaluates similar item types and brands (e.g., *Digestive vs. Marie vs. Cream Cracker vs. Chocolate Chip* across brands) with an adjustable **Price vs. Quality Weight** slider:
  - $\text{PriceScore} = \frac{\text{minUnitPrice}}{\text{unitPrice}} \times 100$
  - $\text{QualityScore} = \frac{\text{avg(Quality, Experience)}}{5} \times 100$
  - $\text{ValueScore} = w_p \cdot \text{PriceScore} + (1 - w_p) \cdot \text{QualityScore}$

## Firebase Architecture (Personal-First, Community-Ready)
- **Private ledger**: `users/{uid}/{transactions, categories, accounts, budgets, recurring_rules}` protected by [`firestore.rules`](firebase/firestore.rules).
- **Offline-first**: Cloud Firestore local persistence is enabled in [`lib/main.dart`](lib/main.dart).
- **Community-ready**: Opt-in anonymized price & rating observations mirror to `community_observations/{txId}` when `isPublicShared == true`, ready to power crowdsourced benchmarks without exposing private finances.

## Running Locally

```bash
# 1. Generate platform folders (android/ios) if needed
flutter create .

# 2. Install packages
flutter pub get

# 3. Run unit tests
flutter test

# 4. Run immediately in local seeded demo mode (no Firebase required yet)
flutter run
```

### Connecting Live Firebase
1. Create a Firebase project and enable **Authentication** (Anonymous / Email / Google), **Cloud Firestore**, and **Firebase Storage**.
2. Run `dart pub global activate flutterfire_cli && flutterfire configure`.
3. Import `firebase_options.dart` in `lib/main.dart` and pass `options: DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp(...)`.
4. Deploy security rules and indexes from `firebase/firestore.rules` and `firebase/firestore.indexes.json`.
