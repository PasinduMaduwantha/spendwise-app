# SpendWise — User Guide

Welcome to **SpendWise**, your smart personal money tracker & product value-comparison app. SpendWise starts **completely clean** (no dummy transactions, budgets, or bills) and saves all your entries automatically on your device.

---

## 1. Getting Started (First Launch)

1. **Choose Your Currency**: On the **Home** screen, tap the currency chip in the top-right corner (`$`, `Rs`, `€`, `£`, `₹`) to match your local currency.
2. **Check Your Starter Wallets**: Open the **Plan** tab → **Accounts & Wallets**. You start with `Cash Wallet`, `Bank Account`, and `Card` at `0.00`. Tap **+ Add Account** anytime to add a wallet with an opening balance.
3. **Log Your First Entry**: Tap the **+ Add** button at the bottom right to record an income or expense.

---

## 2. Tracking Everyday Expenses & Income

### Logging a Transaction
1. Tap **+ Add** on any screen.
2. Select **Expense** or **Income**.
3. Enter a **Title** (e.g., *Munchee Cream Cracker 400g*, *Monthly Salary*), **Amount**, and optional **Shop / Merchant**.
4. Pick a **Category** — or tap **+ New Category** right inside the form to create a custom category immediately.
5. Select the **Account / Payment Method** used (Cash, Bank, Card, or custom wallet).
6. Optionally add a **Receipt Note** or tap **Attach Receipt Photo** to link a receipt image from your phone gallery.
7. Tap **Save Transaction**.

### Viewing Spending by Time Period & Category
- Open the **Home** tab and switch time periods at the top: **This Week**, **This Month**, **90 Days**, **This Year**, or **All Time**.
- View your **Total Balance**, **Period Income**, **Period Expenses**, **Net Cashflow**, and the interactive **Spending by Category** donut chart.

### Searching, Filtering & Exporting CSV
- Open the **Ledger** tab to browse all entries.
- Filter by keyword (title, brand, shop, or note), **Category**, or **Account**.
- **Swipe left** on any transaction card to delete it.
- Tap the **Download icon** in the top-right corner of **Ledger** to export your filtered transactions (including normalized unit prices and ratings) to a **CSV** spreadsheet.

---

## 3. Comparing Goods, Brands, Shops & Best Value

This is SpendWise's signature feature. Whenever you buy groceries or household goods, toggle ON **"Track Product for Brand / Shop / Value Comparison"** inside the **+ Add** sheet:

| Field | What to Enter | Example |
| --- | --- | --- |
| **Product Group** | Broad product you want to compare across types/brands | `Biscuits`, `Fresh Milk`, `Basmati Rice`, `Coffee` |
| **Type** | Specific sub-type or flavor | `Digestive`, `Marie`, `Cream Cracker`, `Chocolate Chip` |
| **Brand** | Manufacturer or brand name | `Munchee`, `Maliban`, `McVitie's` |
| **Shop / Merchant** | Store where you bought it | `Keells`, `Cargills`, `Arpico`, `Local Mart` |
| **Pack Size + Unit + Packs** | Net weight/volume/count (`g`, `kg`, `ml`, `L`, `pcs`) | `400` `g` × `1` pack (or `250` `ml` × `2` packs) |
| **Quality Rating (1–5 ★)** | Taste, freshness, ingredients, or durability | `4.5 ★` |
| **Experience Rating (1–5 ★)** | Packaging, satisfaction, willingness to buy again | `4.5 ★` |

SpendWise automatically displays the **Normalized Unit Price** live as you type (`per 100g`, `per 100ml`, or `per pc`).

### Using the 3 Smart Compare Tabs (`Compare`)

#### A. Brands `/100g` · `/100ml`
- Pick any **Product Group** (e.g., `Biscuits` or `Fresh Milk`).
- SpendWise ranks every brand from **cheapest normalized unit price** to most expensive, showing the best shop and **% savings** vs. the priciest option.

#### B. Cheapest Shops
- Pick **All Categories** or a specific category (e.g., `Snacks & Biscuits`, `Dairy`, `Groceries`).
- SpendWise calculates a **Category Price Index** for each shop (comparing each product's unit price against the cross-shop average for that same product) so expensive items don't skew the comparison.
- The #1 shop shows how much cheaper it is on average (e.g., **11.5% cheaper**) along with its best-deal items.

#### C. Best Value (Price + Quality & Experience)
- Pick a **Product Group** (e.g., `Biscuits` containing *Digestive*, *Marie*, *Cream Cracker*, and *Chocolate Chip* across multiple brands).
- Adjust the **Price Weight vs. Quality & Exp** slider to match your priority:
  - Slide right for **Budget-first** (e.g., `70% Price / 30% Quality`).
  - Keep center for **Balanced** (`50% Price / 50% Quality`).
  - Slide left for **Quality-first** (e.g., `30% Price / 70% Quality`).
- SpendWise computes a **0–100 Value Score**:
  $$\text{ValueScore} = w_p \cdot \left(\frac{\text{minUnitPrice}}{\text{unitPrice}} \times 100\right) + (1 - w_p) \cdot \left(\frac{\text{avg(Quality, Experience)}}{5} \times 100\right)$$
- Instantly see:
  1. **Most Valuable Type** (e.g., *Digestive* vs. *Marie*)
  2. **Most Valuable Brand** (e.g., *Brand A* vs. *Brand B*)
  3. **Full ranked list** with Price Score, Quality ★, and Experience ★ breakdown.

---

## 4. Budgets, Recurring Bills & Accounts (`Plan`)

- **Category Budgets**: Tap **Set Limit** to set a monthly budget per category. Progress bars turn **green** (<80%), **amber** (80–99%), and **red** (≥100%), and alerts automatically appear on the **Home** screen.
- **Recurring Bills & Subscriptions**: Tap **Add Bill** for rent, internet, or subscriptions. When a bill is due, tap **Log now** to record the expense in one tap and advance the next due date automatically.
- **Accounts & Wallets**: Track live balances across Cash, Bank, Card, and Digital Wallets. Tap **Add Account** to add more.
- **Reset All Data**: Need a clean slate? Tap the **sweep/reset icon** in the top-right corner of **Plan** to wipe all entries and start fresh.

---

## 5. Recommended 2-Minute Test Walkthrough

1. Open **SpendWise** → pick your currency on **Home**.
2. Tap **+ Add** → log **3 Biscuit purchases** with **Track Product** enabled:
   - *Purchase 1*: Group `Biscuits`, Type `Marie`, Brand `Brand A`, Shop `Shop 1`, `300 g`, Price `1.50`, Quality `3.5★`, Experience `3.5★`.
   - *Purchase 2*: Group `Biscuits`, Type `Digestive`, Brand `Brand B`, Shop `Shop 1`, `400 g`, Price `2.20`, Quality `5.0★`, Experience `4.5★`.
   - *Purchase 3*: Group `Biscuits`, Type `Digestive`, Brand `Brand C`, Shop `Shop 2`, `400 g`, Price `3.10`, Quality `4.5★`, Experience `4.5★`.
3. Open **Compare** and explore all 3 tabs:
   - **Brands /100g**: See `Brand A` win on pure price per 100g.
   - **Cheapest Shops**: See `Shop 1` crowned cheapest shop for `Snacks & Biscuits`.
   - **Best Value**: Watch `Brand B · Digestive` win overall Value Score, then slide the Price/Quality slider to see rankings adapt live!
4. Open **Plan** → set a budget for `Snacks & Biscuits` (e.g., `5.00`) → return to **Home** to see the live budget overspend alert and donut chart!
