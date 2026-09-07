# LuxeCart SE Shop — PHP REST API Backend

A self-hosted, modular PHP 8.x REST API powering the LuxeCart mobile e-commerce application.

---

## 📚 Detailed Documentation

- **[01. System Architecture (docs/01_ARCHITECTURE.md)](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/01_ARCHITECTURE.md)** — Architectural diagrams, security pipeline & database failover.
- **[02. REST API Specification (docs/02_API_SPECIFICATION.md)](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/02_API_SPECIFICATION.md)** — Comprehensive OpenAPI specification, headers, request/response bodies, and status codes.
- **[03. Database Schema & Migrations (docs/03_DATABASE_SCHEMA.md)](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/03_DATABASE_SCHEMA.md)** — Full 12-table ERD and Migration Engine CLI guide.
- **[05. Deployment Runbook (docs/05_DEPLOYMENT_RUNBOOK.md)](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/se_shop_e_commerce_app/docs/05_DEPLOYMENT_RUNBOOK.md)** — Step-by-step evaluator setup and test guide.

---

## 🌟 Features

- **Dual Database Persistence Engine**: Supports **MySQL 8.x / MariaDB** (Production InnoDB) with automated zero-config fallback to **SQLite** (`backend/data/ecommerce.db`).
- **Atomic Database Migration Engine**: 10 versioned migration scripts supporting `status`, `up`, `rollback`, and `fresh --seed`.
- **Enterprise Security Pipeline**:
  - **CSRF**: HMAC-SHA256 token verification via `X-CSRF-Token` header.
  - **SQLi**: 100% parameter-bound PDO prepared statements.
  - **XSS**: Strict string sanitization and Content Security Policy (CSP) headers.
  - **Bcrypt**: Salted password hashing via `PASSWORD_DEFAULT`.
- **CORS & JSON Compliant**: Works directly with Flutter Mobile (Android/iOS), Web, Windows Desktop, and curl/Postman.

---

## 🚀 Quick Start

### 1. Database Setup & Seeding
```bash
# Check status
php backend/db/migrate.php status

# Fresh migration & seed 50 luxury products
php backend/db/migrate.php fresh --seed
```

### 2. Start the Server
```bash
# In the project root:
php -S 0.0.0.0:8000 backend/index.php
```
*(On Windows, you can also double-click `backend/run.bat`)*

### 3. Run Automated Diagnostics & Security Suites
```bash
# Verify all 10 core endpoints
php backend/test_all_endpoints.php

# Run security test suite (CSRF, SQL Injection, XSS)
php backend/test_security.php
```

---

## 📡 API Endpoints Summary

| Method | Endpoint | Description | Auth / Security |
|---|---|---|---|
| `GET` | `/api/health` | Health status & active security shields | Public |
| `GET` | `/api/csrf-token` | Obtain HMAC anti-CSRF token | Public |
| `GET` | `/api/products` | List products with search & category filters | Public |
| `GET` | `/api/products/{id}` | Single product details | Public |
| `GET` | `/api/categories` | List product categories | Public |
| `POST` | `/api/auth/login` | Authenticate customer credentials | Public |
| `POST` | `/api/auth/register` | Register customer account | Public |
| `POST` | `/api/auth/forgot-password` | Request password reset OTP | Public |
| `POST` | `/api/auth/verify-otp` | Validate 6-digit reset code | Public |
| `POST` | `/api/auth/reset-password` | Reset password using verified OTP | Public |
| `GET` | `/api/orders` | List customer order history | Public |
| `POST` | `/api/orders` | Place new order & generate tracking ID | Requires `X-CSRF-Token` |
| `GET` | `/api/orders/track` | Live delivery milestones & driver details | Public |
| `GET` | `/api/reviews` | List product reviews | Public |
| `POST` | `/api/reviews` | Submit product review | Requires `X-CSRF-Token` |
| `POST` | `/api/coupons/validate` | Validate promo discount (`LUXE20`, `SAVE10`) | Public |
