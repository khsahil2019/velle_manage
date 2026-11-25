-- Trustvly / DHANFLOW Full PostgreSQL Schema (Neon / Supabase / Vercel Postgres)
-- Note: Trustvly PHP API also auto-creates all 11 tables + 7 indexes automatically
-- on first connection (/api/health or any API request).

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    plan VARCHAR(20) NOT NULL DEFAULT 'free',
    plan_expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS credit_cards (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    total_limit BIGINT NOT NULL,
    available_limit BIGINT NOT NULL,
    category_tag VARCHAR(100) NOT NULL DEFAULT 'Active Pocket Debt',
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active SMALLINT NOT NULL DEFAULT 1,
    apr_bps INTEGER NOT NULL DEFAULT 3600,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS card_transactions (
    id VARCHAR(36) PRIMARY KEY,
    card_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    type VARCHAR(32) NOT NULL,
    amount BIGINT NOT NULL,
    note VARCHAR(255) NULL,
    txn_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS loans (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    emi_amount BIGINT NOT NULL,
    remaining_emis INTEGER NOT NULL DEFAULT 0,
    original_emis INTEGER NOT NULL,
    total_remaining BIGINT NOT NULL,
    note VARCHAR(255) NULL,
    is_active SMALLINT NOT NULL DEFAULT 1,
    apr_bps INTEGER NOT NULL DEFAULT 1600,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS personal_payables (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    amount BIGINT NOT NULL,
    note VARCHAR(255) NULL,
    is_settled SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS recoveries (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    total_original BIGINT NOT NULL,
    total_pending BIGINT NOT NULL,
    note VARCHAR(500) NULL,
    is_settled SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS recovery_payments (
    id VARCHAR(36) PRIMARY KEY,
    recovery_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    amount BIGINT NOT NULL,
    applied_to_card VARCHAR(36) NULL,
    note VARCHAR(255) NULL,
    payment_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS bullion_transactions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    metal VARCHAR(32) NOT NULL,
    grams_x10000 BIGINT NOT NULL,
    buy_rate_paise BIGINT NOT NULL,
    pre_gst_paise BIGINT NOT NULL,
    gst_paise BIGINT NOT NULL,
    total_paid_paise BIGINT NOT NULL,
    purchase_date TIMESTAMP NOT NULL,
    platform VARCHAR(50) NOT NULL DEFAULT 'Vault',
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS personal_assets (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(120) NOT NULL,
    category VARCHAR(32) NOT NULL DEFAULT 'other',
    quantity_label VARCHAR(80) NOT NULL DEFAULT '1 Unit',
    purchase_value_paise BIGINT NOT NULL DEFAULT 0,
    current_value_paise BIGINT NOT NULL DEFAULT 0,
    note VARCHAR(255) NULL,
    acquired_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS user_settings (
    user_id VARCHAR(36) PRIMARY KEY,
    gold_current_sell_paise BIGINT NULL,
    silver_current_sell_paise BIGINT NULL,
    debt_payoff_strategy VARCHAR(20) NOT NULL DEFAULT 'snowball',
    monthly_payment_capacity BIGINT NOT NULL DEFAULT 2500000,
    currency VARCHAR(8) NOT NULL DEFAULT 'INR',
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS activity_log (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    event_type VARCHAR(40) NOT NULL,
    description TEXT NOT NULL,
    delta_paise BIGINT NULL,
    related_entity_type VARCHAR(50) NULL,
    related_entity_id VARCHAR(36) NULL,
    related_entity_name VARCHAR(100) NULL,
    metadata_json TEXT NULL,
    is_reversed SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cards_user ON credit_cards (user_id, display_order);
CREATE INDEX IF NOT EXISTS idx_loans_user ON loans (user_id);
CREATE INDEX IF NOT EXISTS idx_payables_user ON personal_payables (user_id);
CREATE INDEX IF NOT EXISTS idx_recoveries_user ON recoveries (user_id);
CREATE INDEX IF NOT EXISTS idx_bullion_user ON bullion_transactions (user_id, purchase_date);
CREATE INDEX IF NOT EXISTS idx_assets_user ON personal_assets (user_id, acquired_date);
CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_log (user_id, created_at);
