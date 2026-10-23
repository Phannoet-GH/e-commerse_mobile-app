# 06. API Testing & Diagnostic Report

## 1. Executive Summary

This document provides technical documentation and automated test verification results for the **LuxeCart REST API** service. The backend operates as a decoupled, modular service with specialized endpoint handlers located in [`backend/api/`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/api) and data persistence powered by a dual MySQL 8.x / SQLite 3 engine.

| Testing Suite | Status | Pass Rate | Script | Purpose |
|---|---|---|---|---|
| **Core Endpoints Diagnostic** | ✅ PASSED | 16 / 16 (100%) | [`test_all_endpoints.php`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/test_all_endpoints.php) | Functional API contract validation |
| **Enterprise Security Suite** | ✅ PASSED | 11 / 11 (100%) | [`test_security.php`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/test_security.php) | XSS, CSRF & SQL injection protections |
| **Scramble & Fuzz Testing** | ✅ PASSED | 24 / 24 (100%) | [`test_scramble_api.php`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/test_scramble_api.php) | Malformed JSON, mutated types, overflows & boundary attacks |
| **Database Connectivity** | ✅ PASSED | 12 / 12 Tables | [`test_mysql.php`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/test_mysql.php) | MySQL InnoDB connection & schema validation |
| **Flutter Integration Tests** | ✅ PASSED | 23 / 23 Suites | `flutter test` | Presentation, provider state & client networking |

---

## 2. Test Execution Commands

From the standalone `backend/` directory:

```bash
# 1. Run core 16-endpoint functional diagnostic suite
php test_all_endpoints.php

# 2. Run enterprise security verification suite (XSS, CSRF, SQLi)
php test_security.php

# 3. Run comprehensive Scramble & Fuzz testing suite (24 cases)
php test_scramble_api.php

# 4. Check database engine health and row counts
php test_mysql.php
```

---

## 3. Scramble & Fuzz Testing Matrix (24 Cases)

The Scramble & Fuzz Testing Suite ([`backend/test_scramble_api.php`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/test_scramble_api.php)) verifies that the backend gracefully repels malformed payloads, corrupted data structures, type mutation attacks, and extreme boundaries without uncaught fatal errors (`500`) or memory leaks:

| # | Category | Test Scenario | Scrambled Input Payload | Expected Defense | Result |
|---|---|---|---|---|---|
| **01** | Payload Corruption | Malformed / Broken JSON Payload | `{"email": "broken_payload` | `422 Unprocessable / 400 Bad Request` | ✅ PASS |
| **02** | Payload Corruption | Non-JSON Plaintext Body on POST | `RAW_PLAINTEXT_DATA_NOT_JSON` | `422 Unprocessable` | ✅ PASS |
| **03** | Payload Corruption | Empty POST Body on Auth Login | `""` (Empty payload) | `422 Unprocessable Entity` | ✅ PASS |
| **04** | Type Mutation | Array Type Injection for Email | `{"email": ["injected", "array"]}` | `422 Unprocessable (No TypeError)` | ✅ PASS |
| **05** | Type Mutation | Boolean Type Injection for Password | `{"password": true}` | `401 Unauthorized / 422 Unprocessable` | ✅ PASS |
| **06** | Type Mutation | String Passed for Array in Orders | `{"items": "string_instead_of_array"}` | `422 Unprocessable (Array required)` | ✅ PASS |
| **07** | Type Mutation | Integer Injected for Coupon Code | `{"code": 999999, "subtotal": 100.0}` | `404 Not Found (Clean rejection)` | ✅ PASS |
| **08** | Boundary / Overflow | 10,000-char Buffer Overflow String | `{"name": "AAAA... (10,000 chars)"}` | `200 OK (Safely truncated)` | ✅ PASS |
| **09** | Boundary / Overflow | Negative Product ID Lookup | `GET /api/products?id=-9999` | `404 Product Not Found` | ✅ PASS |
| **10** | Boundary / Overflow | Astronomical Integer Overflow ID | `GET /api/products?id=99999999999999...` | `404 Product Not Found (No SQL crash)` | ✅ PASS |
| **11** | Boundary / Overflow | Extreme Negative Review Star Rating | `{"rating": -100.0}` | `201 Created (Clamped to 1.0 min)` | ✅ PASS |
| **12** | Boundary / Overflow | Extreme Positive Review Star Rating | `{"rating": 99999.0}` | `201 Created (Clamped to 5.0 max)` | ✅ PASS |
| **13** | Sanitization Defense | SQL Injection Scrambled Query | `GET /api/products?search=' OR '1'='1'` | `200 OK (Prepared statement bound)` | ✅ PASS |
| **14** | Sanitization Defense | Stored XSS Script Tag in Review | `{"comment": "<script>alert(1)</script>"}`| `201 Created (Script stripped/encoded)`| ✅ PASS |
| **15** | Sanitization Defense | SVG Event Handler XSS in Address | `{"recipient_name": "<svg onload=...>"}`| `201 Created (Event handler stripped)` | ✅ PASS |
| **16** | Sanitization Defense | Null Byte Character Injection | `{"user_id": "emma\0wills@example.com"}` | `201 Created (Null bytes stripped)` | ✅ PASS |
| **17** | Sanitization Defense | Unicode Emoji Storm in Profile | `{"name": "Emma 🌟👑💎🔥🚀"}` | `200 OK (UTF-8 multi-byte clean)` | ✅ PASS |
| **18** | Schema Integrity | Order Submission with Empty Items | `{"items": []}` | `422 (Order must have items)` | ✅ PASS |
| **19** | Schema Integrity | Register with All Empty Fields | `{"name": "", "email": "", "password": ""}` | `422 (Mandatory fields required)` | ✅ PASS |
| **20** | Schema Integrity | Non-Existent Coupon Code Lookup | `{"code": "INVALID_VOUCHER_XYZ"}` | `404 (Invalid coupon rejected)` | ✅ PASS |
| **21** | Schema Integrity | Tracking Non-Existent Order Number | `GET /api/orders/track?tracking_number=...`| `404 (Order not found)` | ✅ PASS |
| **22** | Schema Integrity | Add Wishlist Item with Product ID 0 | `{"product_id": 0}` | `400 (Valid product ID required)` | ✅ PASS |
| **23** | Routing Resilience | Completely Scrambled Route URI | `GET /api/x_scrambled_unknown_endpoint` | `404 Endpoint Not Found` | ✅ PASS |
| **24** | Routing Resilience | Path Traversal Injection in Route | `GET /api/../../etc/passwd` | `404 (Path normalized & rejected)` | ✅ PASS |

---

## 4. Core Endpoint Diagnostic Matrix (16 Cases)

| Test ID | HTTP Method | Endpoint | Description & Payload | Expected Status | Result |
|---|---|---|---|---|---|
| **TC-01** | `GET` | `/api/health` | System health status, uptime, active security shields | `200 OK` | ✅ PASS |
| **TC-02** | `GET` | `/api/csrf-token` | Obtain HMAC-SHA256 signed Anti-CSRF token | `200 OK` | ✅ PASS |
| **TC-03** | `GET` | `/api/categories` | Retrieve 7 catalog categories with icons & badge | `200 OK` | ✅ PASS |
| **TC-04** | `GET` | `/api/products` | Retrieve full catalog of 50 luxury items | `200 OK` | ✅ PASS |
| **TC-05** | `GET` | `/api/products?category=Apparel` | Filter products specifically for Apparel category | `200 OK` | ✅ PASS |
| **TC-06** | `GET` | `/api/products?search=hoodie` | Full-text substring search for 'hoodie' | `200 OK` | ✅ PASS |
| **TC-07** | `GET` | `/api/products?id=1` | Single product detail lookup by integer primary key | `200 OK` | ✅ PASS |
| **TC-08** | `POST` | `/api/coupons/validate` | Validate 20% discount coupon (`{"code": "LUXE20", "subtotal": 100.0}`) | `200 OK` | ✅ PASS |
| **TC-09** | `POST` | `/api/coupons/validate` | Validate \$10 discount voucher (`{"code": "SAVE10", "subtotal": 60.0}`) | `200 OK` | ✅ PASS |
| **TC-10** | `GET` | `/api/reviews?product_id=1` | Retrieve verified customer ratings and reviews | `200 OK` | ✅ PASS |
| **TC-11** | `GET` | `/api/addresses?user_id=...` | Retrieve customer's saved shipping addresses | `200 OK` | ✅ PASS |
| **TC-12** | `POST` | `/api/addresses` | Create and store new delivery address with default flag | `201 Created` | ✅ PASS |
| **TC-13** | `GET` | `/api/wishlists?user_id=...` | Retrieve emoji wishlist boards and saved product IDs | `200 OK` | ✅ PASS |
| **TC-14** | `POST` | `/api/favorites/toggle` | Fast 1-tap toggling of favorite state on product card | `200 OK` | ✅ PASS |
| **TC-15** | `POST` | `/api/auth/profile` | Update user personal details (name, phone) | `200 OK` | ✅ PASS |
| **TC-16** | `GET` | `/api/orders?user_id=...` | Retrieve order history for customer session | `200 OK` | ✅ PASS |

---

## 5. Enterprise Security Verification Matrix

Automated verification performed via [`backend/test_security.php`](file:///d:/YEAR%20IV/SEMESTER%20I/MA-II/Final_term/backend/test_security.php):

### 5.1 Cross-Site Scripting (XSS) Sanitization (5 / 5 Passed)
- `<script>` tags stripped and converted to safe HTML entities.
- `<img>` and `<svg>` event handlers (`onerror`, `onload`) stripped.
- `javascript:` pseudo-protocol URIs neutralized.
- Quotes, ampersands, and angle brackets safely encoded via `htmlspecialchars(..., ENT_QUOTES)`.

### 5.2 Anti-CSRF Token Security (4 / 4 Passed)
- HMAC-SHA256 signature verification.
- Tampered token payload rejected with `403 Forbidden`.
- Token replay across different user IDs blocked.
- Expired tokens (>24h) rejected.

### 5.3 SQL Injection (SQLi) Immunity
- 100% parameter binding on all PDO statements.
- Coerced integer and float filters (`cleanInt`, `cleanFloat`).
- Zero direct string interpolation in SQL queries.
