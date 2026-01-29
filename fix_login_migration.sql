-- Migration 0020: Add MyPage fields to solana_users table
-- Add avatar_url field
ALTER TABLE solana_users ADD COLUMN IF NOT EXISTS avatar_url varchar(200) NULL;

-- Add kyc_verified field
ALTER TABLE solana_users ADD COLUMN IF NOT EXISTS kyc_verified boolean NOT NULL DEFAULT false;

-- Add level field
ALTER TABLE solana_users ADD COLUMN IF NOT EXISTS level integer NOT NULL DEFAULT 1;

-- Add membership_tier field
ALTER TABLE solana_users ADD COLUMN IF NOT EXISTS membership_tier varchar(10) NOT NULL DEFAULT 'BASIC';

-- Add points field
ALTER TABLE solana_users ADD COLUMN IF NOT EXISTS points integer NOT NULL DEFAULT 0;

-- Insert migration record for 0020
INSERT INTO django_migrations (app, name, applied)
SELECT 'solana_auth', '0020_solanauser_avatar_url_solanauser_kyc_verified_and_more', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM django_migrations
    WHERE app = 'solana_auth' AND name = '0020_solanauser_avatar_url_solanauser_kyc_verified_and_more'
);
