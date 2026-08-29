-- ===================================================
-- LuxeCart SE Shop - MySQL Database Schema
-- Compatible with MySQL 5.7+, MySQL 8.x, and MariaDB
-- ===================================================

CREATE DATABASE IF NOT EXISTS `se_shop_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `se_shop_db`;

-- 1. Categories Table
CREATE TABLE IF NOT EXISTS `categories` (
    `id` VARCHAR(50) PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `icon` VARCHAR(100) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `accent_color` VARCHAR(20) DEFAULT '0xFFFF2D6F',
    `badge` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Products Table
CREATE TABLE IF NOT EXISTS `products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `brand` VARCHAR(100) NOT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    `original_price` DECIMAL(10, 2) DEFAULT NULL,
    `category` VARCHAR(100) NOT NULL,
    `image_url` TEXT NOT NULL,
    `rating` DECIMAL(3, 1) DEFAULT 5.0,
    `reviews_count` INT DEFAULT 0,
    `description` TEXT DEFAULT NULL,
    `sizes` JSON DEFAULT NULL,
    `colors` JSON DEFAULT NULL,
    `specs` JSON DEFAULT NULL,
    `badge` VARCHAR(50) DEFAULT NULL,
    `in_stock` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_category` (`category`),
    INDEX `idx_name` (`name`),
    INDEX `idx_price` (`price`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Users Table
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(60) PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(191) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(50) DEFAULT NULL,
    `avatar_url` TEXT DEFAULT NULL,
    `role` VARCHAR(50) DEFAULT 'customer',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Addresses Table
CREATE TABLE IF NOT EXISTS `addresses` (
    `id` VARCHAR(60) PRIMARY KEY,
    `user_id` VARCHAR(60) DEFAULT NULL,
    `recipient_name` VARCHAR(150) NOT NULL,
    `street` VARCHAR(255) NOT NULL,
    `city` VARCHAR(100) NOT NULL,
    `state` VARCHAR(50) NOT NULL,
    `zip_code` VARCHAR(30) NOT NULL,
    `country` VARCHAR(100) DEFAULT 'United States',
    `phone` VARCHAR(50) DEFAULT NULL,
    `is_default` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Orders Table
CREATE TABLE IF NOT EXISTS `orders` (
    `id` VARCHAR(60) PRIMARY KEY,
    `order_number` VARCHAR(50) NOT NULL UNIQUE,
    `user_id` VARCHAR(60) DEFAULT 'guest',
    `total_amount` DECIMAL(10, 2) NOT NULL,
    `subtotal` DECIMAL(10, 2) NOT NULL,
    `shipping_fee` DECIMAL(10, 2) DEFAULT 0.00,
    `discount_amount` DECIMAL(10, 2) DEFAULT 0.00,
    `promo_code` VARCHAR(50) DEFAULT NULL,
    `shipping_address` TEXT NOT NULL,
    `payment_method` VARCHAR(100) NOT NULL,
    `status` VARCHAR(50) DEFAULT 'Processing',
    `tracking_number` VARCHAR(60) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_orders` (`user_id`),
    INDEX `idx_tracking` (`tracking_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Order Items Table
CREATE TABLE IF NOT EXISTS `order_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_id` VARCHAR(60) NOT NULL,
    `product_id` INT NOT NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `product_image` TEXT DEFAULT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    `price` DECIMAL(10, 2) NOT NULL,
    `selected_size` VARCHAR(50) DEFAULT NULL,
    `selected_color` VARCHAR(50) DEFAULT NULL,
    INDEX `idx_order_items` (`order_id`),
    CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Reviews Table
CREATE TABLE IF NOT EXISTS `reviews` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` INT NOT NULL,
    `user_name` VARCHAR(150) NOT NULL,
    `rating` DECIMAL(2, 1) NOT NULL,
    `comment` TEXT NOT NULL,
    `date` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_product_reviews` (`product_id`),
    CONSTRAINT `fk_reviews_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Coupons Table
CREATE TABLE IF NOT EXISTS `coupons` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `discount_type` VARCHAR(20) NOT NULL, -- 'percent', 'fixed', 'freeship'
    `discount_value` DECIMAL(10, 2) NOT NULL,
    `min_order_amount` DECIMAL(10, 2) DEFAULT 0.00,
    `is_active` TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

