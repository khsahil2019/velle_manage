-- ═══════════════════════════════════════════════════════════════
-- DHANFLOW Database Schema v1.0
-- MySQL 8.0+ / PlanetScale compatible
-- 
-- CRITICAL: All monetary values stored as BIGINT PAISE (₹ × 100)
--           All gram values stored as BIGINT × 10000 (4 decimal precision)
-- ═══════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET time_zone = '+05:30';

-- ── USERS ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id              CHAR(36)     NOT NULL PRIMARY KEY,
  email           VARCHAR(255) NOT NULL,
  name            VARCHAR(100) NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,
  plan            ENUM('free','pro','annual_pro') NOT NULL DEFAULT 'free',
  plan_expires_at DATETIME     DEFAULT NULL,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_email (email),
  INDEX idx_plan (plan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── CREDIT CARDS ───────────────────────────────────────────────
-- outstanding = total_limit - available_limit (computed on read)
-- Both stored as BIGINT paise for exact arithmetic
CREATE TABLE IF NOT EXISTS credit_cards (
  id              CHAR(36)     NOT NULL PRIMARY KEY,
  user_id         CHAR(36)     NOT NULL,
  name            VARCHAR(100) NOT NULL,
  total_limit     BIGINT       NOT NULL COMMENT 'Paise (₹ × 100)',
  available_limit BIGINT       NOT NULL COMMENT 'Paise (₹ × 100)',
  category_tag    VARCHAR(100) NOT NULL DEFAULT 'Active Pocket Debt',
  display_order   TINYINT      NOT NULL DEFAULT 0,
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  apr_bps         INT          NOT NULL DEFAULT 3600,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_cards_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_active (user_id, is_active),
  INDEX idx_display_order (user_id, display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── CARD TRANSACTIONS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS card_transactions (
  id        CHAR(36)     NOT NULL PRIMARY KEY,
  card_id   CHAR(36)     NOT NULL,
  user_id   CHAR(36)     NOT NULL,
  type      ENUM('PAYMENT','SPEND','LIMIT_INCREASE','LIMIT_DECREASE','AVL_UPDATE') NOT NULL,
  amount    BIGINT       NOT NULL COMMENT 'Paise, always positive',
  note      VARCHAR(255) DEFAULT NULL,
  txn_date  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_txn_card FOREIGN KEY (card_id) REFERENCES credit_cards(id) ON DELETE CASCADE,
  CONSTRAINT fk_txn_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_card_date (card_id, txn_date DESC),
  INDEX idx_user_date (user_id, txn_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── LOANS ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS loans (
  id               CHAR(36)     NOT NULL PRIMARY KEY,
  user_id          CHAR(36)     NOT NULL,
  name             VARCHAR(100) NOT NULL,
  emi_amount       BIGINT       NOT NULL COMMENT 'Paise per EMI',
  remaining_emis   SMALLINT     NOT NULL DEFAULT 0,
  original_emis    SMALLINT     NOT NULL,
  total_remaining  BIGINT       NOT NULL COMMENT 'Authoritative balance in paise',
  note             VARCHAR(255) DEFAULT NULL,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  apr_bps          INT          NOT NULL DEFAULT 1600,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_loans_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_active (user_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── PERSONAL PAYABLES ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS personal_payables (
  id          CHAR(36)     NOT NULL PRIMARY KEY,
  user_id     CHAR(36)     NOT NULL,
  name        VARCHAR(100) NOT NULL,
  amount      BIGINT       NOT NULL COMMENT 'Paise',
  note        VARCHAR(255) DEFAULT NULL,
  is_settled  TINYINT(1)   NOT NULL DEFAULT 0,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_payables_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_settled (user_id, is_settled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── RECOVERIES (KUL LENA) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS recoveries (
  id             CHAR(36)     NOT NULL PRIMARY KEY,
  user_id        CHAR(36)     NOT NULL,
  name           VARCHAR(100) NOT NULL,
  total_original BIGINT       NOT NULL COMMENT 'Initial amount owed, in paise',
  total_pending  BIGINT       NOT NULL COMMENT 'Current outstanding, in paise',
  note           VARCHAR(500) DEFAULT NULL,
  is_settled     TINYINT(1)   NOT NULL DEFAULT 0,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_recoveries_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_settled (user_id, is_settled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── RECOVERY PAYMENTS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recovery_payments (
  id               CHAR(36)     NOT NULL PRIMARY KEY,
  recovery_id      CHAR(36)     NOT NULL,
  user_id          CHAR(36)     NOT NULL,
  amount           BIGINT       NOT NULL COMMENT 'Paise',
  applied_to_card  CHAR(36)     DEFAULT NULL COMMENT 'NULL if cash-only recovery',
  note             VARCHAR(255) DEFAULT NULL,
  payment_date     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rp_recovery FOREIGN KEY (recovery_id) REFERENCES recoveries(id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_user     FOREIGN KEY (user_id)     REFERENCES users(id)     ON DELETE CASCADE,
  CONSTRAINT fk_rp_card     FOREIGN KEY (applied_to_card) REFERENCES credit_cards(id) ON DELETE SET NULL,
  INDEX idx_recovery_date (recovery_id, payment_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── BULLION TRANSACTIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bullion_transactions (
  id               CHAR(36)     NOT NULL PRIMARY KEY,
  user_id          CHAR(36)     NOT NULL,
  metal            VARCHAR(32)  NOT NULL,
  grams_x10000     BIGINT       NOT NULL COMMENT 'Grams × 10000 (4 decimal precision)',
  buy_rate_paise   BIGINT       NOT NULL COMMENT 'Pre-GST rate per gram, in paise',
  pre_gst_paise    BIGINT       NOT NULL COMMENT 'grams × rate, in paise',
  gst_paise        BIGINT       NOT NULL COMMENT '3% of pre_gst, in paise',
  total_paid_paise BIGINT       NOT NULL COMMENT 'pre_gst + gst, in paise',
  purchase_date    DATETIME     NOT NULL,
  platform         VARCHAR(50)  NOT NULL DEFAULT 'Vault',
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bullion_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_metal_date (user_id, metal, purchase_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── PERSONAL ASSETS VAULT ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS personal_assets (
  id                   CHAR(36)     NOT NULL PRIMARY KEY,
  user_id              CHAR(36)     NOT NULL,
  title                VARCHAR(120) NOT NULL,
  category             VARCHAR(32)  NOT NULL DEFAULT 'other',
  quantity_label       VARCHAR(80)  NOT NULL DEFAULT '1 Unit',
  purchase_value_paise BIGINT       NOT NULL DEFAULT 0,
  current_value_paise  BIGINT       NOT NULL DEFAULT 0,
  note                 VARCHAR(255) DEFAULT NULL,
  acquired_date        DATETIME     NOT NULL,
  created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_assets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_assets_user_cat (user_id, category, acquired_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── USER SETTINGS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_settings (
  user_id                    CHAR(36)       NOT NULL PRIMARY KEY,
  gold_current_sell_paise    BIGINT         DEFAULT NULL COMMENT 'Manual sell price input',
  silver_current_sell_paise  BIGINT         DEFAULT NULL,
  debt_payoff_strategy       ENUM('snowball','avalanche','custom') NOT NULL DEFAULT 'snowball',
  monthly_payment_capacity   BIGINT         DEFAULT NULL COMMENT 'Paise',
  currency                   CHAR(3)        NOT NULL DEFAULT 'INR',
  updated_at                 DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── ACTIVITY LOG ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS activity_log (
  id                  CHAR(36)     NOT NULL PRIMARY KEY,
  user_id             CHAR(36)     NOT NULL,
  event_type          VARCHAR(40)  NOT NULL,
  description         TEXT         NOT NULL,
  delta_paise         BIGINT       DEFAULT NULL,
  related_entity_type VARCHAR(50)  DEFAULT NULL,
  related_entity_id   CHAR(36)     DEFAULT NULL,
  related_entity_name VARCHAR(100) DEFAULT NULL,
  metadata_json       JSON         DEFAULT NULL,
  is_reversed         TINYINT(1)   NOT NULL DEFAULT 0,
  created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_date (user_id, created_at DESC),
  INDEX idx_event_type (user_id, event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════
-- SEED: Insert Sahil's initial data (run once per new account)
-- Replace 'USER_UUID_HERE' with actual user UUID after registration
-- ═══════════════════════════════════════════════════════════════
-- 
-- INSERT INTO credit_cards VALUES
--   (UUID(), 'USER_UUID', 'SBI Card',    13900000, 2238217, 'Covered by Sakshi EMIs', 0, 1, NOW(), NOW()),
--   (UUID(), 'USER_UUID', 'PNB Card',     5000000, 2554570, 'Active Pocket Debt',     1, 1, NOW(), NOW()),
--   ...
-- 
-- (All amounts are in paise: ₹1,39,000 = 13900000 paise)
