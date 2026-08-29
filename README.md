# ✨ LuxeCart — Modern Luxury E-Commerce Mobile Platform

A state-of-the-art mobile e-commerce application crafted with **Flutter (Material 3 + Frosted Glassmorphism)** and a self-hosted **PHP 8.x REST API** with **MySQL** database support, dynamic migration engine, and comprehensive security protections (CSRF, PDO prepared statements, XSS prevention, and Bcrypt password hashing).

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
- **⚡ Enterprise Database Migration Engine**: Full CLI migration tool supporting `up`, `down` / `rollback`, `status`, and `fresh --seed`.

---

## 🏗️ Architecture & Project Structure

```
se_shop_e_commerce_app/
├── backend/                             # Self-Hosted PHP 8.x REST API & MySQL Layer
│   ├── api/index.php                   # Secure Router & Security Interceptor
│   ├── config/Database.php             # Dual MySQL & SQLite Fallback Connection
│   ├── db/
│   │   ├── migrate.php                 # CLI Database Migration Tool
│   │   ├── MigrationRunner.php         # Migration Runner with Batch Tracking
│   │   ├── schema.sql                  # MySQL 5.7/8.x Schema
│   │   ├── seed.php                    # 50 Products & Coupon Seed Script
│   │   └── migrations/                 # 9 Atomic Versioned Migrations
│   ├── middleware/CsrfMiddleware.php   # CSRF Security Protection
│   ├── models/                         # Active Record Models (Product, User, Order...)
│   └── test_all_endpoints.php          # 10/10 Endpoint Diagnostic Suite
├── lib/                                # Flutter Mobile Client
│   ├── app/
│   │   ├── ecommerce_app.dart          # Root App Orchestrator & Routing
│   │   ├── app_providers.dart          # Global MultiProvider
│   │   └── main_shell.dart             # Frosted Glass Capsule Navigation Shell
│   ├── core/                           # Design System, Theme Tokens & Widgets
│   ├── data/
│   │   ├── models/                     # Data Models (Product, Order, WishlistBoard...)
│   │   ├── services/                   # ApiService & LocalStorageService
│   │   └── mock/                       # 50 Mock Products & Fallback Catalog
│   ├── providers/
│   │   ├── home_provider.dart          # Cart, Favorites, Wishlists, Orders & Search
│   │   └── session_provider.dart       # User Auth & Guest Lifecycle
│   └── presentation/                   # Screens & UI Views
│       ├── splash/                     # Animated SplashScreen
│       ├── onboarding/                 # 3-Slide Carousel Onboarding
│       ├── home/                       # HomeScreen with Flash Deals & Banners
│       ├── explore/                    # Search & Category Filters
│       ├── product_detail/             # Gallery, Specs, Size/Color Pickers
│       ├── cart/                       # Bag, Shipping Bar, Promo & Checkout
│       ├── favorite/                   # Dual Favorites & Curated Wishlists
│       ├── orders/                     # Order History & Live Dispatch Tracking
│       └── account/                    # Profile, Auth, Address Book & FAQs
└── test/
    └── widget_test.dart                # 15 Passing Flutter Test Suites
```

---

## 🚀 Quick Start Guide

### 1. Flutter Mobile App

```bash
# Install dependencies
flutter pub get

# Run static analyzer
flutter analyze

# Run all test suites
flutter test

# Run app
flutter run
```

---

### 2. Backend & Database Migrations

```bash
# Check migration status
php backend/db/migrate.php status

# Run pending migrations
php backend/db/migrate.php up

# Reset database, re-run all migrations & seed 50 products
php backend/db/migrate.php fresh --seed

# Start PHP Built-in Server
php -S localhost:8000 backend/api/index.php

# Run full API endpoint diagnostics
php backend/test_all_endpoints.php
```

---

## 🛡️ Security & Quality

- **Prepared Statements**: All database operations use PDO prepared statements to eliminate SQL injection.
- **CSRF Token Validation**: Enforced across state-modifying endpoints (`/api/auth/*`, `/api/orders/*`, `/api/coupons/validate`).
- **XSS Protection**: HTML entities sanitized with `htmlspecialchars`.
- **Password Security**: Passwords hashed using standard `PASSWORD_BCRYPT`.
- **List Safety**: All Dart collections are instantiated as growable mutable structures.

---

## 📄 License
MIT License. Built for SE Final Term 2026.
