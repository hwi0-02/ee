-- ====================== EGODA SCHEMA + SEED (SAFE) ======================
SET NAMES utf8mb4;
SET time_zone = '+09:00';

CREATE DATABASE IF NOT EXISTS `hotel`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `hotel`;

START TRANSACTION;
SET FOREIGN_KEY_CHECKS=0;

-- 1) 사용자
CREATE TABLE IF NOT EXISTS `app_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `phone` varchar(20)  NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `date_of_birth` date NOT NULL,
  `address` text NOT NULL,
  `created_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `role` ENUM('USER','ADMIN','BUSINESS') NOT NULL DEFAULT 'USER',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_phone` (`phone`),
  UNIQUE KEY `uq_user_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) 호텔
CREATE TABLE IF NOT EXISTS `Hotel` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `business_id` BIGINT NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` varchar(255) NOT NULL,
  `star_rating` int NOT NULL,
  `description` text NULL,
  `country` varchar(50) NOT NULL,
  `status` ENUM('PENDING','APPROVED','SUSPENDED') NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (`id`),
  KEY `idx_hotel_user` (`user_id`),
  CONSTRAINT `FK_User_TO_Hotel_1`
    FOREIGN KEY (`user_id`) REFERENCES `app_user`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3) 호텔 이미지
CREATE TABLE IF NOT EXISTS `hotel_image` (
  `id`       BIGINT NOT NULL AUTO_INCREMENT,
  `hotel_id` BIGINT NOT NULL,
  `url`      TEXT   NOT NULL,
  `sort_no`  INT    NOT NULL DEFAULT 0,
  `is_cover` BOOLEAN NOT NULL DEFAULT FALSE,
  `caption`  VARCHAR(255) NULL,
  `alt_text` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_himg_hotel` (`hotel_id`),
  UNIQUE KEY `uq_hotel_sort` (`hotel_id`,`sort_no`),
  CONSTRAINT `fk_himg_hotel`
    FOREIGN KEY (`hotel_id`) REFERENCES `Hotel`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE INDEX IF NOT EXISTS idx_himg_cover_sort
  ON `hotel_image` (`hotel_id`, `is_cover`, `sort_no`);

-- 4) 편의시설 마스터
CREATE TABLE IF NOT EXISTS `Amenity` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text NULL,
  `icon_url` varchar(255) NULL,
  `fee_type` ENUM('FREE','PAID','HOURLY') NOT NULL DEFAULT 'FREE',
  `fee_amount` int NULL,
  `fee_unit` VARCHAR(50) NULL,
  `operating_hours` varchar(255) NULL,
  `location` varchar(255) NULL,
  `is_active` boolean NOT NULL DEFAULT true,
  `category` ENUM('IN_ROOM','IN_HOTEL','LEISURE','FNB','BUSINESS','OTHER')
              NOT NULL DEFAULT 'OTHER',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5) 호텔-편의시설 매핑
CREATE TABLE IF NOT EXISTS `Hotel_Amenity` (
  `hotel_id` BIGINT NOT NULL,
  `amenity_id` BIGINT NOT NULL,
  PRIMARY KEY (`hotel_id`,`amenity_id`),
  KEY `idx_ha_amenity` (`amenity_id`),
  CONSTRAINT `FK_Hotel_TO_Hotel_Amenity_1`
    FOREIGN KEY (`hotel_id`) REFERENCES `Hotel` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `FK_Amenity_TO_Hotel_Amenity_1`
    FOREIGN KEY (`amenity_id`) REFERENCES `Amenity` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6) 객실
CREATE TABLE IF NOT EXISTS `Room` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `hotel_id` BIGINT NOT NULL,
  `name` varchar(100) NOT NULL,
  `room_size` varchar(50) NOT NULL,
  `capacity_min` int NOT NULL,
  `capacity_max` int NOT NULL,
  `check_in_time` time NOT NULL,
  `check_out_time` time NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_room_hotel` (`hotel_id`),
  CONSTRAINT `FK_Hotel_TO_Room_1`
    FOREIGN KEY (`hotel_id`) REFERENCES `Hotel` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7) 객실 이미지
CREATE TABLE IF NOT EXISTS `room_image` (
  `id`       BIGINT NOT NULL AUTO_INCREMENT,
  `room_id`  BIGINT NOT NULL,
  `url`      TEXT   NOT NULL,
  `sort_no`  INT    NOT NULL DEFAULT 0,
  `is_cover` BOOLEAN NOT NULL DEFAULT FALSE,
  `caption`  VARCHAR(255) NULL,
  `alt_text` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_rimg_room` (`room_id`),
  UNIQUE KEY `uq_room_sort` (`room_id`,`sort_no`),
  CONSTRAINT `fk_rimg_room`
    FOREIGN KEY (`room_id`) REFERENCES `Room`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE INDEX IF NOT EXISTS idx_rimg_cover_sort
  ON `room_image` (`room_id`, `is_cover`, `sort_no`);

-- 8) 객실 재고
CREATE TABLE IF NOT EXISTS `Room_Inventory` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `room_id` BIGINT NOT NULL,
  `date` date NOT NULL,
  `total_quantity` int NOT NULL,
  `available_quantity` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_room_day` (`room_id`,`date`),
  KEY `idx_inv_room` (`room_id`),
  CONSTRAINT `FK_Room_TO_Room_Inventory_1`
    FOREIGN KEY (`room_id`) REFERENCES `Room` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9) 객실 요금 정책
CREATE TABLE IF NOT EXISTS `Room_Price_Policy` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `room_id` BIGINT NOT NULL,
  `season_type` ENUM('PEAK','OFF_PEAK','HOLIDAY') NOT NULL DEFAULT 'OFF_PEAK',
  `day_type`    ENUM('WEEKDAY','FRI','SAT','SUN') NOT NULL,
  `start_date` date NOT NULL,
  `end_date`   date NOT NULL,
  `price` int  NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_rpp_room` (`room_id`),
  CONSTRAINT `FK_Room_TO_Room_Price_Policy_1`
    FOREIGN KEY (`room_id`) REFERENCES `Room` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10) 예약
CREATE TABLE IF NOT EXISTS `Reservation` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `room_id` BIGINT NOT NULL,
  `transaction_id` varchar(255) NULL,
  `num_adult` int NOT NULL DEFAULT 0,
  `num_kid`   int NOT NULL DEFAULT 0,
  `start_date` timestamp NOT NULL,
  `end_date`   timestamp NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('PENDING','COMPLETED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `expires_at` timestamp NULL,
  PRIMARY KEY (`id`),
  KEY `idx_res_user` (`user_id`),
  KEY `idx_res_room` (`room_id`),
  CONSTRAINT `FK_User_TO_Reservation_1`
    FOREIGN KEY (`user_id`) REFERENCES `app_user` (`id`),
  CONSTRAINT `FK_Room_TO_Reservation_1`
    FOREIGN KEY (`room_id`) REFERENCES `Room` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `Reservation` -- 1) 예약에 '잡은 객실 수' 칼럼 추가
  ADD COLUMN `num_rooms` INT NOT NULL DEFAULT 1 AFTER `room_id`;
  CREATE INDEX idx_res_status_expires ON `Reservation` (`status`, `expires_at`);

-- 11) 결제
CREATE TABLE `payment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `reservation_id` bigint(20) NOT NULL,
  `payment_method` varchar(50) NOT NULL DEFAULT 'CARD',             -- ★ 기본값
  `base_price` int(11) NOT NULL DEFAULT 0,                          -- ★ 기본값
  `total_price` int(11) GENERATED ALWAYS AS                         -- ★ 생성 칼럼
      (base_price + tax - discount) STORED,
  `tax` int(11) NOT NULL DEFAULT 0,
  `discount` int(11) NOT NULL DEFAULT 0,
  `status` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `refunded_at` timestamp NULL DEFAULT NULL,
  `receipt_url` varchar(512) DEFAULT NULL,
  `amount` int(11) NOT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `order_id` varchar(255) DEFAULT NULL,
  `order_name` varchar(255) DEFAULT NULL,
  `payment_key` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_receipt_url` (`receipt_url`),
  KEY `idx_pay_res` (`reservation_id`),
  CONSTRAINT `FK_Reservation_TO_Payment_1`
    FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12) 쿠폰
CREATE TABLE IF NOT EXISTS `Coupon` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `name` varchar(255) NOT NULL,
  `code` varchar(255) NOT NULL,
  `discount_type` ENUM('PERCENTAGE','FIXED_AMOUNT') NOT NULL,
  `discount_value` int NOT NULL,
  `min_spend` int NOT NULL DEFAULT 0,
  `valid_from` datetime NOT NULL,
  `valid_to`   datetime NULL,
  `is_active` boolean NOT NULL DEFAULT true,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_coupon_code` (`code`),
  KEY `idx_coupon_user` (`user_id`),
  CONSTRAINT `FK_User_TO_Coupon_1`
    FOREIGN KEY (`user_id`) REFERENCES `app_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13) 리뷰
CREATE TABLE IF NOT EXISTS `Review` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `reservation_id` BIGINT NOT NULL,
  `wrote_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `star_rating` int NOT NULL DEFAULT 5,
  `content` text NULL,
  `image` text NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_review_reservation` (`reservation_id`),
  CONSTRAINT `FK_Reservation_TO_Review_1`
    FOREIGN KEY (`reservation_id`) REFERENCES `Reservation` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================== SEED ==============================

-- 유저
INSERT INTO app_user (id, name, phone, email, password, date_of_birth, address, role)
VALUES
  (1,'관리자','010-0000-0000','admin@egoda.local','{noop}pw','1990-01-01','Seoul','ADMIN')
ON DUPLICATE KEY UPDATE name=VALUES(name), role=VALUES(role);

INSERT INTO app_user (id, name, phone, email, password, date_of_birth, address, role)
VALUES
  (2,'오너','010-1111-1111','owner@egoda.local','{noop}pw','1990-01-01','Seoul','BUSINESS')
ON DUPLICATE KEY UPDATE name=VALUES(name), role=VALUES(role);

-- 호텔 (APPROVED)
INSERT INTO `Hotel` (id, user_id, business_id, name, address, star_rating, description, country, status)
VALUES
  (1, 2, 1001, '서울 스카이 호텔', '서울특별시 중구 을지로 100', 4, '시내 중심 합리적 숙소', 'KR', 'APPROVED'),
  (2, 2, 1002, '부산 오션 뷰',     '부산광역시 해운대구 해운대로 200', 4, '해운대 오션뷰 호텔', 'KR', 'APPROVED')
ON DUPLICATE KEY UPDATE name=VALUES(name), address=VALUES(address), status=VALUES(status);

-- 호텔 이미지(대표 우선)
INSERT INTO hotel_image (hotel_id, url, sort_no, is_cover)
VALUES
  (1,'https://picsum.photos/seed/seoul1/1200/720',0,1),
  (1,'https://picsum.photos/seed/seoul2/600/360',1,0),
  (2,'https://picsum.photos/seed/busan1/1200/720',0,1)
ON DUPLICATE KEY UPDATE url=VALUES(url), is_cover=VALUES(is_cover);

-- 객실
INSERT INTO `Room` (id, hotel_id, name, room_size, capacity_min, capacity_max, check_in_time, check_out_time)
VALUES
  (1,1,'디럭스 더블','26㎡',1,2,'15:00:00','11:00:00'),
  (2,1,'트윈','24㎡',1,2,'15:00:00','11:00:00'),
  (3,2,'오션 디럭스 더블','28㎡',1,2,'15:00:00','11:00:00')
ON DUPLICATE KEY UPDATE name=VALUES(name), room_size=VALUES(room_size);

-- 객실 이미지(대표만)
INSERT INTO room_image (room_id, url, sort_no, is_cover)
VALUES
  (1,'https://picsum.photos/seed/r1a/480/320',0,1),
  (2,'https://picsum.photos/seed/r2a/480/320',0,1),
  (3,'https://picsum.photos/seed/r3a/480/320',0,1)
ON DUPLICATE KEY UPDATE url=VALUES(url), is_cover=VALUES(is_cover);

-- 객실 요금 정책 (어제~+180일)
INSERT INTO `Room_Price_Policy` (room_id, season_type, day_type, start_date, end_date, price)
VALUES
  (1,'OFF_PEAK','WEEKDAY', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), DATE_ADD(CURRENT_DATE(), INTERVAL 180 DAY), 120000),
  (2,'OFF_PEAK','WEEKDAY', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), DATE_ADD(CURRENT_DATE(), INTERVAL 180 DAY),  90000),
  (3,'OFF_PEAK','WEEKDAY', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), DATE_ADD(CURRENT_DATE(), INTERVAL 180 DAY),  80000)
ON DUPLICATE KEY UPDATE price=VALUES(price), end_date=VALUES(end_date);

-- (옵션) 오늘 재고
INSERT INTO `Room_Inventory` (room_id, `date`, total_quantity, available_quantity)
VALUES
  (1, CURRENT_DATE(), 5, 3),
  (2, CURRENT_DATE(), 5, 5),
  (3, CURRENT_DATE(), 5, 4)
ON DUPLICATE KEY UPDATE available_quantity=VALUES(available_quantity);

-- (옵션) 편의시설 + 매핑
INSERT INTO `Amenity` (id, name, fee_type, is_active, category)
VALUES
  (1,'무료 Wi-Fi','FREE',true,'IN_HOTEL'),
  (2,'조식','PAID',true,'FNB'),
  (3,'수영장','FREE',true,'LEISURE'),
  (4,'피트니스 센터','FREE',true,'LEISURE')
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT IGNORE INTO `Hotel_Amenity` (hotel_id, amenity_id) VALUES
  (1,1),(1,2),(2,1),(2,4);

SET FOREIGN_KEY_CHECKS=1;
COMMIT;

-- 빠른 검증
SELECT h.id, h.name, MIN(rpp.price) AS lowestPrice
FROM `Hotel` h
LEFT JOIN `Room` r ON r.hotel_id=h.id
LEFT JOIN `Room_Price_Policy` rpp ON rpp.room_id=r.id
GROUP BY h.id, h.name;
