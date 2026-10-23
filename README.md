# ✨ LuxeCart — Modern Luxury E-Commerce Mobile Platform

A state-of-the-art mobile e-commerce platform crafted with **Flutter (Material 3 + Frosted Glassmorphism)** and a self-hosted **PHP 8.x REST API** with **MySQL** database support, dynamic migration engine, and comprehensive security protections (CSRF HMAC-SHA256, PDO prepared statements, XSS prevention, and Bcrypt password hashing).

---

## 📚 Complete Project Documentation Suite

Comprehensive engineering and academic documentation is available in the [`docs/`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs) directory:

| Document | Description | Key Topics |
|---|---|---|
| **[01. System Architecture](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/01_ARCHITECTURE.md)** | Tier breakdown, component diagrams & resilience | Flutter client, PHP 8 REST API, MySQL/SQLite dual persistence, offline-first fallback, threat model. |
| **[02. REST API Specification](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/02_API_SPECIFICATION.md)** | Full endpoint reference & schemas | All 10 endpoints, CSRF token handshake, query filters, JSON payloads, and error status codes. |
| **[03. Database Schema & Migrations](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/03_DATABASE_SCHEMA.md)** | Mermaid ERD & data dictionary | 12 tables, foreign keys, cascade deletes, CLI migration runner (`status`, `up`, `rollback`, `fresh --seed`). |
| **[04. Mobile Client Architecture](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/04_MOBILE_CLIENT.md)** | Design tokens, state & UX flows | Material 3, frosted glass tokens, Google Fonts Outfit, `SessionProvider`, `HomeProvider`, guest checkout. |
| **[05. Deployment & Evaluation Runbook](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/05_DEPLOYMENT_RUNBOOK.md)** | Turnkey instructor setup & verification | Step-by-step evaluation guide, test suites execution, demo accounts, and coupon codes. |

---

## 🌟 Key Features

- **🛍️ 50 Curated Luxury Products**: Across Apparel, Footwear, Electronics, Accessories, Bags, and Fine Jewelry with high-resolution photography, variants, and verified reviews.
- **✨ Animated Splash & 3-Slide Onboarding**: Radiant brand immersion with fluid capsule indicators, skip options, and guest/member access.
- **❤️ Favorites & 📋 Wishlists Separation**: Rapid 1-tap liked items separated from custom emoji boards with 1-tap *Add Board to Cart*.
- **⚡ Live Flash Deals**: Dynamic real-time ticking countdown timer and discount pills.
- **🚚 Free Shipping Progress Bar**: Real-time progress calculating distance to the \$100 VIP free shipping threshold.
- **🔒 Auth-Gated Checkout & Guest Resumption**: Unsigned users are seamlessly prompted to Sign Up / Sign In without losing cart contents; checkout auto-resumes upon authentication.
- **💳 4-Step Secure Checkout**: Address selector, delivery speed calculation, payment methods, and fail-safe async order placement.
- **📦 Live Dispatch Tracking**: Real-time package milestone tracking, courier driver profile (*Marcus King*), and 1-tap direct calling.
- **⚡ Enterprise Database Migration Engine**: Full CLI migration tool supporting `up`, `rollback`, `status`, and `fresh --seed`.

---

## 🏗️ Architecture & Project Structure

```
Final_term/
├── backend/                            # Independent PHP 8.x REST API Backend
│   ├── api/                           # Dedicated Modular API Endpoints
│   │   ├── auth.php                   # Authentication & User Profile
│   │   ├── products.php               # Catalog & Product Detail
│   │   ├── categories.php             # Category Filter API
│   │   ├── orders.php                 # Orders & Package Tracking
│   │   ├── addresses.php              # Shipping Address Management
│   │   ├── wishlists.php              # Wishlist Boards & Favorites
│   │   ├── reviews.php                # Product Reviews & Ratings
│   │   ├── coupons.php                # Promo Codes & Discounts
│   │   └── health.php                 # System Status & CSRF Tokens
│   ├── config/                        # Database Connection & CORS Settings
│   ├── data/ecommerce.db              # Auto-provisioned SQLite Fallback Database
│   ├── db/                            # Versioned Migrations & 50-Product Seeder
│   ├── models/                        # Active Record Data Models
│   ├── security/                      # CSRF Guard, Input Sanitizer, CSP Headers
│   ├── index.php                      # REST API Router & Dispatcher
│   ├── run.bat                        # 1-Click Server Startup Script
│   └── test_all_endpoints.php         # 16-Endpoint Diagnostic Suite
├── se_shop_e_commerce_app/             # Flutter Mobile Client Tier
│   ├── docs/                          # Comprehensive Technical Documentation
│   │   ├── 01_ARCHITECTURE.md         # System Architecture & Component Design
│   │   ├── 02_API_SPECIFICATION.md    # REST API Reference & Schemas
│   │   ├── 03_DATABASE_SCHEMA.md      # Database ERD & Migration Engine
│   │   ├── 04_MOBILE_CLIENT.md        # Flutter Design System & State Management
│   │   └── 05_DEPLOYMENT_RUNBOOK.md   # Evaluator Setup & Test Runbook
│   ├── lib/                           # Flutter Source (Presentation, State & Models)
│   └── test/                          # 23 Passing Flutter Test Suites
└── SE Shop.fig                         # Figma Mobile UI/UX Design System
```

---

## 🚀 Quick Start Guide

For full step-by-step evaluator instructions, please refer to **[05. Deployment & Evaluation Runbook](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/05_DEPLOYMENT_RUNBOOK.md)**.

### 1. Backend & Database Setup
```bash
# Navigate to the backend directory:
cd ../backend

# 1. Reset database, run all 10 migrations & seed 50 luxury products
php db/migrate.php fresh --seed

# 2. Start PHP Built-in Server on port 8000 (or double-click run.bat)
php -S 0.0.0.0:8000 index.php

# 3. Run backend diagnostic test suite (16/16 endpoints pass)
php test_all_endpoints.php

# 4. Run automated security test suite (CSRF, SQLi, XSS)
php test_security.php

# 5. Run Scramble & Fuzz testing suite (24 resilience & boundary tests)
php test_scramble_api.php
```

### 2. Flutter Mobile Application
```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Run static analyzer (0 issues)
flutter analyze

# 3. Run all test suites (23/23 tests pass)
flutter test

# 4. Run app on Chrome, Windows Desktop, or Android
flutter run -d chrome
```

---

## 🛡️ Security & Quality

- **Prepared Statements**: All database operations use PDO prepared statements to eliminate SQL injection.
- **CSRF Token Validation**: Enforced across state-modifying endpoints (`/api/auth/*`, `/api/orders`, `/api/reviews`, `/api/coupons/validate`).
- **XSS Protection**: HTML entities sanitized with `htmlspecialchars` and strict CSP headers.
- **Password Security**: Passwords hashed using standard `PASSWORD_BCRYPT`.
- **Offline-First Resilience**: Automatic fallback to local catalog mock data if network connectivity drops.

---

## 📄 License
MIT License. Built for SE Final Term 2026.
