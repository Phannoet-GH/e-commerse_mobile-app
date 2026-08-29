@echo off
echo ===================================================
echo   LuxeCart SE Shop - PHP REST API Backend
echo ===================================================
echo Database: SQLite (Auto-initialized at backend/data/ecommerce.db)
echo Server running at: http://localhost:8000
echo Endpoints:
echo   - GET  http://localhost:8000/api/products
echo   - GET  http://localhost:8000/api/categories
echo   - POST http://localhost:8000/api/auth/login
echo   - POST http://localhost:8000/api/auth/register
echo   - GET  http://localhost:8000/api/orders
echo   - POST http://localhost:8000/api/orders
echo   - POST http://localhost:8000/api/coupons/validate
echo ===================================================
php -S 0.0.0.0:8000 backend/index.php

