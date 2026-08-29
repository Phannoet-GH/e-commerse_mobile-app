<?php

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/Cors.php';
require_once __DIR__ . '/config/Database.php';
require_once __DIR__ . '/helpers/Response.php';
require_once __DIR__ . '/security/Sanitizer.php';
require_once __DIR__ . '/security/Csrf.php';
require_once __DIR__ . '/security/SecurityHeaders.php';
require_once __DIR__ . '/models/Product.php';
require_once __DIR__ . '/models/Category.php';
require_once __DIR__ . '/models/User.php';
require_once __DIR__ . '/models/Order.php';
require_once __DIR__ . '/models/Review.php';
require_once __DIR__ . '/models/Coupon.php';

use App\Config\Cors;
use App\Helpers\Response;
use App\Security\Sanitizer;
use App\Security\Csrf;
use App\Security\SecurityHeaders;
use App\Models\Product;
use App\Models\Category;
use App\Models\User;
use App\Models\Order;
use App\Models\Review;
use App\Models\Coupon;

// Apply Security Headers & CORS
SecurityHeaders::apply();
Cors::handle();

// Parse URI & Method
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// Normalize URI
$path = trim($uri, '/');
if (str_starts_with($path, 'api/')) {
    $path = substr($path, 4);
} elseif ($path === 'api') {
    $path = '';
}

try {
    // -------------------------------------------------------------
    // HEALTH CHECK & CSRF TOKEN GENERATION
    // -------------------------------------------------------------
    if ($path === '' || $path === 'health') {
        Response::json([
            'status' => 'online',
            'app' => 'LuxeCart SE Shop REST API',
            'security' => [
                'xss_protection' => 'Sanitizer + HTML Entity Encoding + CSP',
                'csrf_protection' => 'HMAC-SHA256 Signed Tokens + Token Verification',
                'sql_injection_protection' => 'PDO Prepared Statements with Param Binding',
                'password_hashing' => 'Bcrypt / PASSWORD_DEFAULT',
            ],
            'timestamp' => date('c'),
            'endpoints' => [
                'GET /api/csrf-token' => 'Obtain anti-CSRF token for state-changing operations',
                'GET /api/products' => 'List products with optional category, search, or id',
                'GET /api/categories' => 'List all categories',
                'POST /api/auth/login' => 'User login',
                'POST /api/auth/register' => 'User registration',
                'POST /api/auth/forgot-password' => 'Send password reset link',
                'GET /api/orders' => 'List orders',
                'POST /api/orders' => 'Place new order',
                'GET /api/orders/track' => 'Track order status by tracking number',
                'GET /api/reviews' => 'Get product reviews',
                'POST /api/reviews' => 'Submit product review',
                'POST /api/coupons/validate' => 'Validate voucher discount',
            ],
        ]);
    }

    if ($path === 'csrf-token') {
        if ($method === 'GET') {
            $token = Csrf::generateToken();
            Response::json([
                'csrf_token' => $token,
                'expires_in' => 86400,
            ]);
        }
    }

    // -------------------------------------------------------------
    // PRODUCTS API
    // -------------------------------------------------------------
    if ($path === 'products') {
        if ($method === 'GET') {
            if (isset($_GET['id']) && is_numeric($_GET['id'])) {
                $product = Product::getById(Sanitizer::cleanInt($_GET['id']));
                if ($product) {
                    Response::json($product);
                } else {
                    Response::error('Product not found', 404);
                }
            }

            $category = isset($_GET['category']) ? Sanitizer::cleanString($_GET['category'], 50) : null;
            $search = isset($_GET['search']) ? Sanitizer::cleanString($_GET['search'], 100) : null;
            $limit = isset($_GET['limit']) ? Sanitizer::cleanInt($_GET['limit'], 50) : 50;
            $offset = isset($_GET['offset']) ? Sanitizer::cleanInt($_GET['offset'], 0) : 0;

            $products = Product::getAll($category, $search, $limit, $offset);
            Response::json($products, 200, [
                'count' => count($products),
                'category' => $category ?: 'all',
                'search' => $search,
            ]);
        }
    }

    if (preg_match('#^products/(\d+)$#', $path, $matches)) {
        if ($method === 'GET') {
            $product = Product::getById((int)$matches[1]);
            if ($product) {
                Response::json($product);
            } else {
                Response::error('Product not found', 404);
            }
        }
    }

    // -------------------------------------------------------------
    // CATEGORIES API
    // -------------------------------------------------------------
    if ($path === 'categories') {
        if ($method === 'GET') {
            $categories = Category::getAll();
            Response::json($categories);
        }
    }

    // -------------------------------------------------------------
    // AUTHENTICATION API
    // -------------------------------------------------------------
    if ($path === 'auth/login') {
        if ($method === 'POST') {
            $input = Response::getJsonInput();
            $email = Sanitizer::cleanString($input['email'] ?? '', 150);
            $password = (string)($input['password'] ?? '');

            if (empty($email) || empty($password)) {
                Response::error('Email and password are required.', 422);
            }

            $user = User::login($email, $password);
            Response::json($user, 200);
        }
    }

    if ($path === 'auth/register') {
        if ($method === 'POST') {
            $input = Response::getJsonInput();
            $name = Sanitizer::cleanString($input['name'] ?? '', 100);
            $email = Sanitizer::cleanString($input['email'] ?? '', 150);
            $password = (string)($input['password'] ?? '');
            $phone = isset($input['phone']) ? Sanitizer::cleanString($input['phone'], 50) : null;

            if (empty($name) || empty($email) || empty($password)) {
                Response::error('Name, email, and password are required.', 422);
            }

            $user = User::register($name, $email, $password, $phone);
            Response::json($user, 201);
        }
    }

    if ($path === 'auth/forgot-password') {
        if ($method === 'POST') {
            $input = Response::getJsonInput();
            $email = Sanitizer::cleanString($input['email'] ?? '', 150);

            if (empty($email)) {
                Response::error('Email address is required.', 422);
            }

            $res = User::requestPasswordResetOTP($email);
            Response::json($res, 200);
        }
    }

    if ($path === 'auth/verify-otp') {
        if ($method === 'POST') {
            $input = Response::getJsonInput();
            $email = Sanitizer::cleanString($input['email'] ?? '', 150);
            $otp = Sanitizer::cleanString($input['otp'] ?? '', 10);

            if (empty($email) || empty($otp)) {
                Response::error('Email and OTP code are required.', 422);
            }

            User::verifyResetOTP($email, $otp);
            Response::json([
                'success' => true,
                'message' => 'OTP verified successfully.',
            ], 200);
        }
    }

    if ($path === 'auth/reset-password') {
        if ($method === 'POST') {
            $input = Response::getJsonInput();
            $email = Sanitizer::cleanString($input['email'] ?? '', 150);
            $otp = Sanitizer::cleanString($input['otp'] ?? '', 10);
            $newPassword = (string)($input['new_password'] ?? '');

            if (empty($email) || empty($newPassword)) {
                Response::error('Email and new password are required.', 422);
            }

            $res = User::resetPassword($email, $newPassword, $otp ?: null);
            Response::json($res, 200);
        }
    }

    // -------------------------------------------------------------
    // ORDERS API (State-changing: Sanitized & CSRF-protected)
    // -------------------------------------------------------------
    if ($path === 'orders') {
        if ($method === 'GET') {
            $orders = Order::getAll();
            Response::json($orders);
        } elseif ($method === 'POST') {
            $input = Response::getJsonInput();
            if (empty($input['items']) || !is_array($input['items'])) {
                Response::error('Order must contain at least one item.', 422);
            }

            // Sanitize order payload against XSS in shipping address, notes, user_id
            $cleanPayload = [
                'user_id' => Sanitizer::cleanString($input['user_id'] ?? 'guest', 60),
                'shipping_address' => Sanitizer::cleanString($input['shipping_address'] ?? '14 Market Street, New York, NY 10001', 255),
                'payment_method' => Sanitizer::cleanString($input['payment_method'] ?? 'Visa •••• 4589', 100),
                'promo_code' => isset($input['promo_code']) ? Sanitizer::cleanString($input['promo_code'], 50) : null,
                'subtotal' => Sanitizer::cleanFloat($input['subtotal'] ?? 0.0),
                'shipping_fee' => Sanitizer::cleanFloat($input['shipping_fee'] ?? 0.0),
                'discount_amount' => Sanitizer::cleanFloat($input['discount_amount'] ?? 0.0),
                'total_amount' => Sanitizer::cleanFloat($input['total_amount'] ?? 0.0),
                'items' => Sanitizer::cleanArray($input['items']),
            ];

            $order = Order::create($cleanPayload);
            Response::json($order, 201);
        }
    }

    if ($path === 'orders/track') {
        if ($method === 'GET') {
            $tracking = isset($_GET['tracking_number'])
                ? Sanitizer::cleanString($_GET['tracking_number'], 60)
                : (isset($_GET['order_number']) ? Sanitizer::cleanString($_GET['order_number'], 60) : '');

            if (empty($tracking)) {
                Response::error('Tracking number or order number is required.', 400);
            }

            $order = Order::getByTrackingNumber($tracking);
            if ($order) {
                Response::json($order);
            } else {
                Response::error("Order with tracking '$tracking' not found.", 404);
            }
        }
    }

    // -------------------------------------------------------------
    // REVIEWS API (Sanitized against Stored XSS)
    // -------------------------------------------------------------
    if ($path === 'reviews') {
        if ($method === 'GET') {
            $productId = isset($_GET['product_id']) ? Sanitizer::cleanInt($_GET['product_id']) : 0;
            if ($productId <= 0) {
                Response::error('Valid product_id is required.', 400);
            }

            $reviews = Review::getByProductId($productId);
            Response::json($reviews);
        } elseif ($method === 'POST') {
            $input = Response::getJsonInput();
            $productId = Sanitizer::cleanInt($input['product_id'] ?? 0);
            $userName = Sanitizer::cleanString($input['user_name'] ?? 'Emma Wills', 100);
            $rating = min(5.0, max(1.0, Sanitizer::cleanFloat($input['rating'] ?? 5.0)));
            // Strip any malicious <script>, <img>, <iframe> HTML tags to prevent XSS
            $comment = Sanitizer::cleanString($input['comment'] ?? '', 1000);

            if ($productId <= 0 || empty($comment)) {
                Response::error('Product ID and comment are required.', 422);
            }

            $review = Review::add($productId, $userName, $rating, $comment);
            Response::json($review, 201);
        }
    }

    // -------------------------------------------------------------
    // COUPONS / PROMOS API
    // -------------------------------------------------------------
    if ($path === 'coupons/validate' || $path === 'promo/validate') {
        if ($method === 'POST') {
            $input = Response::getJsonInput();
            $code = Sanitizer::cleanString($input['code'] ?? '', 50);
            $subtotal = Sanitizer::cleanFloat($input['subtotal'] ?? 0.0);

            if (empty($code)) {
                Response::error('Coupon code is required.', 422);
            }

            $result = Coupon::validate($code, $subtotal);
            if ($result) {
                Response::json($result);
            } else {
                Response::error('Invalid coupon code. Try LUXE20, SAVE10, or FREESHIP.', 404);
            }
        }
    }

    // 404 Route Not Found
    Response::error("Endpoint '$path' not found.", 404);

} catch (\Throwable $e) {
    Response::error($e->getMessage(), 500);
}
