# LuxeCart SE Shop - PHP REST API Backend

A self-hosted, modular PHP 8.x REST API powering the LuxeCart mobile e-commerce application.

---

## Features
- **Zero-Setup SQLite Out-of-the-Box**: Auto-initializes SQLite database in `backend/data/ecommerce.db` on first run.
- **MySQL / MariaDB Production Support**: Set environment variables (`DB_TYPE=mysql`, `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).
- **RESTful Endpoints**:
  - `GET /api/products` (supports `?category=Apparel`, `?search=hoodie`, `?id=1`, `?limit=20`)
  - `GET /api/products/{id}`
  - `GET /api/categories`
  - `POST /api/auth/login`
  - `POST /api/auth/register`
  - `POST /api/auth/forgot-password`
  - `GET /api/orders`
  - `POST /api/orders` (places order and generates tracking ID)
  - `GET /api/orders/track?tracking_number=TRK-XXXXX`
  - `GET /api/reviews?product_id=1`
  - `POST /api/reviews`
  - `POST /api/coupons/validate` (`LUXE20`, `SAVE10`, `FREESHIP`)
  - `GET /api/health`
- **CORS & JSON Compliant**: Works directly with Flutter Web, Mobile (Android/iOS), Desktop, and curl/Postman.

---

## Quick Start

### 1. Run with Built-in PHP Server
```bash
# In the project root:
php -S 0.0.0.0:8000 backend/index.php
```
Or on Windows simply double-click `backend/run.bat`.

### 2. Re-Seed Sample Database
```bash
php backend/db/seed.php
```

---

## API Endpoints Reference

### 1. Products
```http
GET http://localhost:8000/api/products
GET http://localhost:8000/api/products?category=Apparel
GET http://localhost:8000/api/products?search=hoodie
GET http://localhost:8000/api/products/1
```

### 2. Categories
```http
GET http://localhost:8000/api/categories
```

### 3. Authentication
```http
POST http://localhost:8000/api/auth/login
Content-Type: application/json

{
  "email": "emma.wills@email.com",
  "password": "password123"
}
```

```http
POST http://localhost:8000/api/auth/register
Content-Type: application/json

{
  "name": "Sophia Laurent",
  "email": "sophia@example.com",
  "password": "securepassword",
  "phone": "+1 555 123 4567"
}
```

### 4. Orders
```http
POST http://localhost:8000/api/orders
Content-Type: application/json

{
  "user_id": "usr_demo_1001",
  "shipping_address": "14 Market Street, Apt 4B, New York, NY 10001",
  "payment_method": "Visa •••• 4589",
  "subtotal": 114.98,
  "shipping_fee": 0.0,
  "discount_amount": 22.99,
  "promo_code": "LUXE20",
  "items": [
    {
      "product_id": 1,
      "quantity": 1,
      "selected_size": "L",
      "price": 64.99
    },
    {
      "product_id": 6,
      "quantity": 1,
      "selected_size": "M",
      "price": 49.99
    }
  ]
}
```

```http
GET http://localhost:8000/api/orders/track?tracking_number=TRK-1000001
```

### 5. Validate Voucher Coupon
```http
POST http://localhost:8000/api/coupons/validate
Content-Type: application/json

{
  "code": "LUXE20",
  "subtotal": 100.00
}
```

