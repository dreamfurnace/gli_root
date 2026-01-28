-- Add missing category column to news_articles table
ALTER TABLE news_articles ADD COLUMN IF NOT EXISTS category varchar(20) DEFAULT 'etc' NOT NULL;

-- Create partners table if not exists
CREATE TABLE IF NOT EXISTS partners (
    id uuid NOT NULL PRIMARY KEY,
    title_ko varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    subtitle_ko varchar(300) NOT NULL,
    subtitle_en varchar(300) NOT NULL,
    category varchar(20) NOT NULL,
    description_ko text NOT NULL,
    description_en text NOT NULL,
    achievements_ko text NOT NULL,
    achievements_en text NOT NULL,
    partnership_type varchar(20) NOT NULL,
    logo_url varchar(200) NOT NULL,
    website_url varchar(200) NULL,
    country varchar(100) NULL,
    status varchar(20) NOT NULL,
    "order" integer NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

-- Create indexes for partners table if not exist
CREATE INDEX IF NOT EXISTS partners_status_69b27f_idx ON partners (status, is_active);
CREATE INDEX IF NOT EXISTS partners_categor_acff9b_idx ON partners (category, created_at DESC);
CREATE INDEX IF NOT EXISTS partners_order_71209b_idx ON partners ("order", is_active);

-- Insert migration records
INSERT INTO django_migrations (app, name, applied)
SELECT 'solana_auth', '0018_newsarticle_category', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM django_migrations
    WHERE app = 'solana_auth' AND name = '0018_newsarticle_category'
);

INSERT INTO django_migrations (app, name, applied)
SELECT 'solana_auth', '0019_add_partner_model', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM django_migrations
    WHERE app = 'solana_auth' AND name = '0019_add_partner_model'
);
