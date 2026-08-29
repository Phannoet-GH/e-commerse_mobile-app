<?php

namespace App\Models;

use App\Config\Database;
use PDO;

class Order {
    public static function create(array $data): array {
        $pdo = Database::getConnection();

        $orderId = 'ord_' . time() . '_' . bin2hex(random_bytes(3));
        $orderNumber = '#LX-' . rand(100000, 999999);
        $trackingNumber = 'TRK-' . rand(1000000, 9999999);

        $subtotal = (float)($data['subtotal'] ?? 0.0);
        $shippingFee = (float)($data['shipping_fee'] ?? 0.0);
        $discountAmount = (float)($data['discount_amount'] ?? 0.0);
        $totalAmount = (float)($data['total_amount'] ?? ($subtotal - $discountAmount + $shippingFee));

        $pdo->beginTransaction();

        try {
            $stmt = $pdo->prepare("
                INSERT INTO orders (
                    id, order_number, user_id, total_amount, subtotal, 
                    shipping_fee, discount_amount, promo_code, 
                    shipping_address, payment_method, status, tracking_number
                ) VALUES (
                    :id, :order_number, :user_id, :total_amount, :subtotal,
                    :shipping_fee, :discount_amount, :promo_code,
                    :shipping_address, :payment_method, 'Processing', :tracking_number
                )
            ");

            $stmt->execute([
                ':id' => $orderId,
                ':order_number' => $orderNumber,
                ':user_id' => $data['user_id'] ?? 'guest',
                ':total_amount' => $totalAmount,
                ':subtotal' => $subtotal,
                ':shipping_fee' => $shippingFee,
                ':discount_amount' => $discountAmount,
                ':promo_code' => $data['promo_code'] ?? null,
                ':shipping_address' => $data['shipping_address'] ?? '14 Market Street, New York, NY 10001',
                ':payment_method' => $data['payment_method'] ?? 'Visa •••• 4589',
                ':tracking_number' => $trackingNumber,
            ]);

            // Insert order items
            if (!empty($data['items']) && is_array($data['items'])) {
                $itemStmt = $pdo->prepare("
                    INSERT INTO order_items (
                        order_id, product_id, product_name, product_image, 
                        quantity, price, selected_size, selected_color
                    ) VALUES (
                        :order_id, :product_id, :product_name, :product_image,
                        :quantity, :price, :selected_size, :selected_color
                    )
                ");

                foreach ($data['items'] as $item) {
                    $itemStmt->execute([
                        ':order_id' => $orderId,
                        ':product_id' => (int)($item['product_id'] ?? ($item['product']['id'] ?? 1)),
                        ':product_name' => $item['product_name'] ?? ($item['product']['name'] ?? 'Product'),
                        ':product_image' => $item['product_image'] ?? ($item['product']['image_url'] ?? ($item['product']['image'] ?? '')),
                        ':quantity' => (int)($item['quantity'] ?? ($item['qty'] ?? 1)),
                        ':price' => (float)($item['price'] ?? ($item['product']['price'] ?? 0.0)),
                        ':selected_size' => $item['selected_size'] ?? ($item['size'] ?? 'M'),
                        ':selected_color' => $item['selected_color'] ?? ($item['color'] ?? 'Default'),
                    ]);
                }
            }

            $pdo->commit();

            return self::getById($orderId);
        } catch (\Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public static function getById(string $orderId): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $orderId]);
        $order = $stmt->fetch();

        if (!$order) return null;

        $itemsStmt = $pdo->prepare("SELECT * FROM order_items WHERE order_id = :order_id");
        $itemsStmt->execute([':order_id' => $orderId]);
        $order['items'] = $itemsStmt->fetchAll();

        return self::formatOrder($order);
    }

    public static function getByTrackingNumber(string $trackingNumber): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE tracking_number = :tracking OR order_number = :tracking LIMIT 1");
        $stmt->execute([':tracking' => trim($trackingNumber)]);
        $order = $stmt->fetch();

        if (!$order) return null;

        $itemsStmt = $pdo->prepare("SELECT * FROM order_items WHERE order_id = :order_id");
        $itemsStmt->execute([':order_id' => $order['id']]);
        $order['items'] = $itemsStmt->fetchAll();

        return self::formatOrder($order);
    }

    public static function getAll(): array {
        $pdo = Database::getConnection();
        $stmt = $pdo->query("SELECT * FROM orders ORDER BY created_at DESC");
        $orders = $stmt->fetchAll();

        $result = [];
        foreach ($orders as $order) {
            $itemsStmt = $pdo->prepare("SELECT * FROM order_items WHERE order_id = :order_id");
            $itemsStmt->execute([':order_id' => $order['id']]);
            $order['items'] = $itemsStmt->fetchAll();
            $result[] = self::formatOrder($order);
        }

        return $result;
    }

    private static function formatOrder(array $row): array {
        return [
            'id' => $row['id'],
            'order_number' => $row['order_number'],
            'user_id' => $row['user_id'],
            'total_amount' => (float)$row['total_amount'],
            'subtotal' => (float)$row['subtotal'],
            'shipping_fee' => (float)$row['shipping_fee'],
            'discount_amount' => (float)$row['discount_amount'],
            'promo_code' => $row['promo_code'],
            'shipping_address' => $row['shipping_address'],
            'payment_method' => $row['payment_method'],
            'status' => $row['status'],
            'tracking_number' => $row['tracking_number'],
            'created_at' => $row['created_at'],
            'items' => array_map(function ($item) {
                return [
                    'id' => (int)$item['id'],
                    'product_id' => (int)$item['product_id'],
                    'product_name' => $item['product_name'],
                    'product_image' => $item['product_image'],
                    'quantity' => (int)$item['quantity'],
                    'price' => (float)$item['price'],
                    'selected_size' => $item['selected_size'],
                    'selected_color' => $item['selected_color'],
                ];
            }, $row['items'] ?? []),
        ];
    }
}

