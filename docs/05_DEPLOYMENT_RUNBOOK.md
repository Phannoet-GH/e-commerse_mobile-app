# 05. Deployment & Evaluation Runbook

## 1. Overview for Evaluators & Instructors

This runbook provides complete, reproducible, step-by-step instructions to initialize the database, start the PHP backend server, run all automated test suites (API, security, and Flutter client tests), and launch the LuxeCart application for grading and evaluation.

---

## 2. System Prerequisites

Ensure the following runtimes are installed on your host machine:

| Component | Minimum Version | Verification Command |
|---|---|---|
| **PHP** | `8.2.x` or higher with `pdo`, `pdo_mysql`, `pdo_sqlite` extensions | `php -v` |
| **MySQL / MariaDB** | `8.0+` or `10.4+` (Optional: SQLite fallback is built-in) | `mysql -V` |
| **Flutter SDK** | `3.12.x` or higher (Channel stable) | `flutter --version` |
| **Dart SDK** | `3.x` or higher (Bundled with Flutter) | `dart --version` |

---

## 3. Quick-Start Setup in 5 Steps

### Step 1: Clone & Configure Environment

Navigate to the project directory:
```bash
cd "d:/YEAR IV/SEMESTER I/MA-II/Final_term/se_shop_e_commerce_app"
```

Verify or update the backend configuration in [`backend/.env`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/backend/.env):
```ini
# MySQL Configuration (Default for Evaluation)
DB_TYPE=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=se_shop_db
DB_USERNAME=root
DB_PASSWORD=

# Anti-CSRF App Secret
APP_SECRET=luxecart_super_secret_key_2026_se_final
```
> [!TIP]
> **Zero-Setup SQLite Alternative**: If you do not have MySQL running, simply change `DB_TYPE=sqlite`. The database will automatically initialize in `backend/data/ecommerce.db` with zero external dependencies!

---

### Step 2: Initialize Database Migrations & Seeds

Execute the atomic migration runner with the fresh seed flag to prepare 50 luxury products, categories, coupons, and demo accounts:

```bash
php backend/db/migrate.php fresh --seed
```

**Expected Console Output**:
```text
[LuxeCart Migration Runner] Driver: mysql
Dropping existing tables...
Migrating: 2026_01_01_000001_create_categories_table.php (up)... Done.
Migrating: 2026_01_01_000002_create_products_table.php (up)... Done.
...
Migrating: 2026_01_01_000010_create_password_resets_table.php (up)... Done.
Seeding database with 50 curated luxury products & coupons...
Database seeded successfully!
```

---

### Step 3: Start the Backend REST API Server

Start the lightweight PHP built-in server listening on port `8000`:

#### On Windows (PowerShell):
```powershell
php -S 0.0.0.0:8000 backend/index.php
```
*(Or simply double-click [`backend/run.bat`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/backend/run.bat))*

#### On macOS / Linux:
```bash
php -S 0.0.0.0:8000 backend/index.php
```

Confirm health in another terminal or browser:
```bash
curl http://localhost:8000/api/health
```

---

### Step 4: Run Automated Backend & Security Test Suites

The backend includes three automated diagnostic suites:

#### 1. All Endpoints Diagnostic (16/16 Verification)
```bash
php test_all_endpoints.php
```
**Expected Result**: All 16 endpoints respond with `200 OK` / `201 Created`.

#### 2. Enterprise Security Test Suite (SQLi, CSRF, XSS)
```bash
php test_security.php
```
**Expected Result**:
- `[PASS]` CSRF Protection: Rejects state modifications lacking `X-CSRF-Token`.
- `[PASS]` SQL Injection: Blocked via PDO prepared statements.
- `[PASS]` XSS Mitigation: Malicious HTML entities neutralized.

#### 3. Scramble & Fuzz Testing Suite (24/24 Resilience & Boundary Verification)
```bash
php test_scramble_api.php
```
**Expected Result**:
- `[PASS]` 24/24 mutated payloads, malformed JSON, corrupted types, buffer overflows, and boundary values repelled gracefully without uncaught 500 errors.

---

### Step 5: Run Flutter Client Tests & Launch Application

#### 1. Static Analysis (Zero Lints Verification)
```bash
flutter analyze
```
*Expected: "No issues found!"*

#### 2. Automated Widget & Unit Test Suites (23 Tests)
```bash
flutter test
```
*Expected: "All tests passed! (23 tests)"*

#### 3. Launching the Application

Run on your preferred target platform:

```bash
# Launch in Google Chrome (Web with DevicePreview)
flutter run -d chrome

# Launch on Windows Desktop
flutter run -d windows

# Launch on connected Android device or emulator
flutter run -d android
```

---

## 4. Evaluator Demo Credentials & Test Scenarios

### 4.1 Demo Accounts
| Account Type | Email | Password | Role |
|---|---|---|---|
| **Member Account** | `emma.wills@email.com` | `password123` | Customer with order history |
| **Admin Account** | `admin@luxecart.com` | `admin123` | Store Administrator |
| **Guest Mode** | *(No credentials)* | *(None)* | Tap *"Continue as Guest"* on onboarding |

### 4.2 Test Promo Codes (Cart Checkout)
- `LUXE20`: Applies a **20% discount** to the entire order.
- `SAVE10`: Applies a **\$10 flat deduction** (order minimum \$50).
- `FREESHIP`: Reduces shipping fee to **\$0.00**.

### 4.3 Pre-Seeded Order Tracking
- Use tracking code **`TRK-1000001`** in the Orders tab or track lookup screen to view real-time delivery milestones and driver contact (*Marcus King*).

---

## 5. Troubleshooting & FAQ

### Q1: "SQLSTATE[HY000] [2002] Connection refused" when connecting to MySQL
- **Solution**: Verify your local MySQL service is running. If MySQL is not installed or configured, switch to zero-setup SQLite by editing [`backend/.env`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/backend/.env):
  ```ini
  DB_TYPE=sqlite
  ```
  Then run `php backend/db/migrate.php fresh --seed`.

### Q2: Mobile emulator cannot reach `http://localhost:8000`
- **Solution**: Android emulators map the host machine to `10.0.2.2`. Update `baseUrl` in [`lib/data/services/api_service.dart`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/lib/data/services/api_service.dart) or keep the built-in offline failover which seamlessly serves `MockData.products`.

### Q3: How to reset the database to a clean state?
- Run `php backend/db/migrate.php fresh --seed`. This drops all tables, recreates schema definitions, and re-inserts all 50 products and initial fixtures.
