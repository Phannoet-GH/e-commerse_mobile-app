<?php

namespace App\Models;

use App\Config\Database;

class Coupon {
    public static function validate(string $code, float $subtotal): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM coupons WHERE UPPER(code) = UPPER(:code) AND is_active = 1 LIMIT 1");
        $stmt->execute([':code' => trim($code)]);
        $coupon = $stmt->fetch();

        if (!$coupon) {
            return null;
        }

        $minAmount = (float)$coupon['min_order_amount'];
        if ($subtotal < $minAmount) {
            throw new \Exception("Minimum order amount of \$$minAmount required for code '{$coupon['code']}'.");
        }

        $discountAmount = 0.0;
        $type = $coupon['discount_type'];
        $val = (float)$coupon['discount_value'];

        if ($type === 'percent') {
            $discountAmount = $subtotal * ($val / 100.0);
        } elseif ($type === 'fixed') {
            $discountAmount = min($subtotal, $val);
        } elseif ($type === 'freeship') {
            $discountAmount = 0.0; // Handled as 0 shipping fee
        }

        return [
            'code' => $coupon['code'],
            'discount_type' => $type,
            'discount_value' => $val,
            'discount_amount' => round($discountAmount, 2),
            'is_free_shipping' => $type === 'freeship',
        ];
    }
}

