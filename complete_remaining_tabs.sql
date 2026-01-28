-- ========================================================================
-- Tab 6: Service Management
-- ========================================================================

-- 1. 서비스 카테고리 테이블
CREATE TABLE IF NOT EXISTS service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    description TEXT,
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. 서비스 예약 테이블
CREATE TABLE IF NOT EXISTS service_bookings (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES solana_users(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES service_categories(id) ON DELETE SET NULL,
    service_name VARCHAR(200) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    booking_date DATE NOT NULL,
    booking_time TIME,
    status VARCHAR(20) DEFAULT 'PENDING' NOT NULL,
    total_price_usd DECIMAL(20, 2) DEFAULT 0 NOT NULL,
    paid_price_glil DECIMAL(20, 8) DEFAULT 0 NOT NULL,
    location VARCHAR(200),
    notes TEXT,
    confirmation_code VARCHAR(50) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_service_bookings_user ON service_bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_date ON service_bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_service_bookings_status ON service_bookings(status);

-- ========================================================================
-- Tab 8: Notice
-- ========================================================================

-- 3. 공지사항 테이블
CREATE TABLE IF NOT EXISTS notices (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    title_en VARCHAR(200),
    content TEXT NOT NULL,
    content_en TEXT,
    category VARCHAR(50) DEFAULT 'GENERAL' NOT NULL,
    is_important BOOLEAN DEFAULT FALSE NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    author VARCHAR(100),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(category);
CREATE INDEX IF NOT EXISTS idx_notices_published ON notices(published_at);
CREATE INDEX IF NOT EXISTS idx_notices_important ON notices(is_important);

-- 4. 공지사항 읽음 상태 테이블
CREATE TABLE IF NOT EXISTS notice_read_status (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES solana_users(id) ON DELETE CASCADE,
    notice_id INTEGER NOT NULL REFERENCES notices(id) ON DELETE CASCADE,
    read_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(user_id, notice_id)
);

CREATE INDEX IF NOT EXISTS idx_notice_read_user ON notice_read_status(user_id);
CREATE INDEX IF NOT EXISTS idx_notice_read_notice ON notice_read_status(notice_id);

-- ========================================================================
-- Django 마이그레이션 히스토리
-- ========================================================================

INSERT INTO django_migrations (app, name, applied)
VALUES ('solana_auth', '0021_remaining_tabs_service_notice', NOW())
ON CONFLICT DO NOTHING;

-- ========================================================================
-- 샘플 데이터
-- ========================================================================

-- 서비스 카테고리 샘플
INSERT INTO service_categories (name, name_en, description, icon, display_order)
VALUES
    ('골프', 'Golf', '프리미엄 골프장 예약 서비스', '⛳', 1),
    ('호텔', 'Hotel', '럭셔리 호텔 및 리조트 예약', '🏨', 2),
    ('레스토랑', 'Restaurant', '고급 레스토랑 예약', '🍽️', 3),
    ('스파', 'Spa', '프리미엄 스파 서비스', '💆', 4),
    ('컨시어지', 'Concierge', '개인 맞춤 컨시어지 서비스', '🎩', 5)
ON CONFLICT DO NOTHING;

-- 공지사항 샘플
INSERT INTO notices (title, content, category, is_important, is_pinned, author, published_at)
VALUES
    ('GLI Platform 서비스 오픈 안내',
     'GLI Platform이 정식으로 오픈되었습니다. 많은 이용 부탁드립니다.',
     'ANNOUNCEMENT', TRUE, TRUE, 'GLI Team', NOW() - INTERVAL '7 days'),

    ('2FA 보안 인증 필수 안내',
     '보안 강화를 위해 2단계 인증(2FA) 설정을 권장합니다.',
     'SECURITY', TRUE, FALSE, 'Security Team', NOW() - INTERVAL '5 days'),

    ('정기 시스템 점검 안내',
     '매주 월요일 02:00-04:00 정기 시스템 점검이 진행됩니다.',
     'MAINTENANCE', FALSE, FALSE, 'Tech Team', NOW() - INTERVAL '3 days'),

    ('신규 토큰 상장 안내',
     'GLIL 토큰이 신규 거래소에 상장되었습니다.',
     'UPDATE', FALSE, FALSE, 'GLI Team', NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;
