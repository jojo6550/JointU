-- ============================================================
-- JOINTU DATABASE SCHEMA v8 — PostgreSQL
-- Changes from v7:
--   - NEW: skill_categories (self-referencing, nested hierarchy)
--   - NEW: skills (master catalogue, linked to categories)
--   - NEW: user_skills (worker ↔ skill mapping with proficiency
--           and optional admin verification)
--   - NEW: job_skills (job ↔ skill requirements, hard vs preferred)
--   - NEW: service_commissions (admin-managed commission rates
--           per skill_category, with optional per-skill override
--           and a platform-wide default fallback)
-- All previous v6 tables and constraints preserved unchanged.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- UTILITY: auto-update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ============================================================
-- ROLES
-- ============================================================

CREATE TABLE roles (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(30) UNIQUE NOT NULL
);

-- ============================================================
-- MEMBERSHIP PLANS
-- ============================================================

CREATE TABLE membership_plans (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_name          VARCHAR(50) UNIQUE NOT NULL,
    monthly_bid_limit  INT,
    monthly_connects   INT           DEFAULT 0,
    can_unlimited_bids BOOLEAN       DEFAULT FALSE,
    priority_rank      INT           DEFAULT 0,
    price_jmd          NUMERIC(12,2) DEFAULT 0,
    suppress_ads       BOOLEAN       DEFAULT FALSE,
    is_active          BOOLEAN       DEFAULT TRUE,
    created_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_membership_plans_updated_at
    BEFORE UPDATE ON membership_plans
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id       UUID REFERENCES roles(id),
    plan_id       UUID REFERENCES membership_plans(id),
    email         VARCHAR(150) UNIQUE,
    phone         VARCHAR(30)  UNIQUE,
    password_hash TEXT NOT NULL,
    is_verified   BOOLEAN   DEFAULT FALSE,
    is_active     BOOLEAN   DEFAULT TRUE,
    is_disabled   BOOLEAN   DEFAULT FALSE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_users_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_plan_id ON users(plan_id);

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER PROFILES
-- ============================================================

CREATE TABLE user_profiles (
    user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    first_name   VARCHAR(80),
    last_name    VARCHAR(80),
    display_name VARCHAR(160),
    bio          TEXT,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER WALLETS
-- ============================================================
--  this table tracks users' wallet balances for payments and refunds.
--  balance cannot go negative, enforced by a check constraint.
--  updated_at allows tracking when the balance last changed.
--  For simplicity, we store only the current balance here. A full transaction
--  history would be in a separate table (not implemented in this schema).
--  In a real application, wallet operations would be handled via stored procedures
--  to ensure atomic updates and proper logging.
--  Note: For security and audit purposes, consider implementing wallet changes
--  through a ledger table that records each transaction (credits and debits) with references
-- ============================================================
CREATE TABLE user_wallets (
    user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    wallet_balance NUMERIC(12,2) DEFAULT 0,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_wallet_non_negative CHECK (wallet_balance >= 0)
);

CREATE TRIGGER trg_user_wallets_updated_at
    BEFORE UPDATE ON user_wallets
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER ADDRESSES
-- A user may have multiple addresses (home, work, etc.).
-- Only one address per user may be flagged is_primary = TRUE,
-- enforced via partial unique index.
-- is Primary = TRUE → this is the main address used for billing, verification, etc.
-- ============================================================

CREATE TABLE user_addresses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    street        VARCHAR(255) NOT NULL,
    city          VARCHAR(100) NOT NULL,
    state_parish  VARCHAR(100) NOT NULL,
    country       VARCHAR(100) NOT NULL DEFAULT 'Jamaica',
    is_primary    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Only one primary address allowed per user
CREATE UNIQUE INDEX idx_user_addresses_one_primary
    ON user_addresses(user_id)
    WHERE is_primary = TRUE;

CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);

CREATE TRIGGER trg_user_addresses_updated_at
    BEFORE UPDATE ON user_addresses
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER CONTACTS
-- A user can have multiple contact methods (email, phone).
-- contact_type: 'email' or 'phone'
-- contact_value: the actual email address or phone number.
-- is_primary: only one primary contact per type (enforced by partial unique index).
-- is_verified: whether the contact has been verified (e.g., via OTP for phone, confirmation email for email).
-- ============================================================


CREATE TABLE user_contacts (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_type  VARCHAR(20) NOT NULL,
    contact_value VARCHAR(150) NOT NULL,
    is_primary    BOOLEAN DEFAULT FALSE,
    is_verified   BOOLEAN DEFAULT FALSE,
    verified_at   TIMESTAMP,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_contact_type CHECK (contact_type IN ('email','phone')),
    CONSTRAINT uq_contact_value UNIQUE (contact_value)
);

CREATE UNIQUE INDEX idx_user_contacts_one_primary
ON user_contacts(user_id, contact_type)
WHERE is_primary = TRUE;

CREATE INDEX idx_user_contacts_user_id 
ON user_contacts(user_id);

CREATE INDEX idx_user_contacts_value 
ON user_contacts(contact_value);

CREATE TRIGGER trg_user_contacts_updated_at
BEFORE UPDATE ON user_contacts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();



-- ============================================================
-- WORKER SERVICE AREAS (v9 ADDITION)
-- Defines where a worker is willing to work (NOT residence)
-- Supports:
--   - Multiple locations per worker
--   - Global availability
--   - Clean filtering (no enums)
-- ============================================================

CREATE TABLE worker_service_areas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    country         VARCHAR(100) NOT NULL DEFAULT 'Jamaica',
    state_parish    VARCHAR(100),
    city            VARCHAR(100),
    is_global       BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Prevent invalid empty rows unless global
    CONSTRAINT chk_service_area_valid
        CHECK (
            is_global = TRUE
            OR state_parish IS NOT NULL
            OR city IS NOT NULL
        )
);

-- ============================================================
-- INDEXES (IMPORTANT FOR PERFORMANCE)
-- ============================================================

CREATE INDEX idx_worker_service_areas_user_id
ON worker_service_areas(user_id);

CREATE INDEX idx_worker_service_areas_location
ON worker_service_areas(state_parish, city);

CREATE INDEX idx_worker_service_areas_global
ON worker_service_areas(is_global);

-- Prevent duplicate service areas per user
CREATE UNIQUE INDEX uq_worker_service_area_unique
ON worker_service_areas(user_id, state_parish, city)
WHERE is_global = FALSE;

-- Only ONE global row per user
CREATE UNIQUE INDEX uq_worker_service_area_global
ON worker_service_areas(user_id)
WHERE is_global = TRUE;

-- ============================================================
-- TRIGGER (CONSISTENT WITH YOUR SYSTEM)
-- ============================================================

CREATE TRIGGER trg_worker_service_areas_updated_at
BEFORE UPDATE ON worker_service_areas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- BADGE TYPES
-- Defines the catalogue of available verification badges.
-- Seed examples: 'id_verified', 'phone_verified',
--   'email_verified', 'address_verified', 'payment_verified'
-- ============================================================

CREATE TABLE badge_types (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(60)  UNIQUE NOT NULL,
    label       VARCHAR(100) NOT NULL,
    description TEXT,
    icon_path   TEXT,
    is_active   BOOLEAN   DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_badge_types_updated_at
    BEFORE UPDATE ON badge_types
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER BADGES
-- Records which verification badges a user holds,
-- who granted them, and when they expire (if ever).
-- ============================================================

CREATE TABLE user_badges (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_type_id UUID NOT NULL REFERENCES badge_types(id),
    granted_by    UUID REFERENCES users(id),
    granted_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at    TIMESTAMP,
    revoked_at    TIMESTAMP,
    revoke_reason TEXT,
    CONSTRAINT uq_user_badge         UNIQUE (user_id, badge_type_id),
    CONSTRAINT chk_badge_expiry      CHECK  (expires_at IS NULL OR expires_at > granted_at),
    CONSTRAINT chk_badge_revoke_date CHECK  (revoked_at IS NULL OR revoked_at >= granted_at)
);

CREATE INDEX idx_user_badges_user_id       ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge_type_id ON user_badges(badge_type_id);
CREATE INDEX idx_user_badges_granted_by    ON user_badges(granted_by);

CREATE INDEX idx_user_badges_active
    ON user_badges(user_id)
    WHERE revoked_at IS NULL;

CREATE VIEW user_active_badges AS
SELECT
    ub.user_id,
    bt.code,
    bt.label,
    bt.icon_path,
    ub.granted_at,
    ub.expires_at
FROM user_badges ub
JOIN badge_types bt ON bt.id = ub.badge_type_id
WHERE ub.revoked_at IS NULL
  AND (ub.expires_at IS NULL OR ub.expires_at > CURRENT_TIMESTAMP)
  AND bt.is_active = TRUE;

-- ============================================================
-- USER MEMBERSHIPS
-- Tracks which membership plan a user is subscribed to, with
-- start/end dates and status. A user can have multiple records over time but only one active membership at a time, enforced
-- via a partial unique index on (user_id) where status = 'active'.
-- start_date and end_date allow for historical tracking of membership periods.
-- status can be 'active', 'expired', 'cancelled', etc. to reflect the current state of the membership.
-- ============================================================

CREATE TABLE user_memberships (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_id    UUID REFERENCES membership_plans(id),
    start_date DATE NOT NULL,
    end_date   DATE,
    status     VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_membership_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE UNIQUE INDEX idx_user_memberships_one_active
    ON user_memberships(user_id)
    WHERE status = 'active';

CREATE INDEX idx_user_memberships_user_id ON user_memberships(user_id);
CREATE INDEX idx_user_memberships_plan_id ON user_memberships(plan_id);

CREATE TRIGGER trg_user_memberships_updated_at
    BEFORE UPDATE ON user_memberships
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- MEMBERSHIP TRANSFERS
-- Records transfers of active memberships between users, with details on the transfer reason, fee, and status.
-- from_user_id and to_user_id reference the users involved in the transfer.
-- transfer_reason allows recording why the transfer is happening (e.g., "gift", "sale", "account takeover").
-- transfer_fee can be used if the platform charges a fee for transferring memberships.
-- ============================================================

CREATE TABLE membership_transfers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    membership_id   UUID REFERENCES user_memberships(id),
    from_user_id    UUID REFERENCES users(id),
    to_user_id      UUID REFERENCES users(id),
    transfer_reason TEXT,
    transfer_fee    NUMERIC(10,2) DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'pending',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_no_self_transfer          CHECK (from_user_id <> to_user_id),
    CONSTRAINT chk_transfer_fee_non_negative CHECK (transfer_fee >= 0)
);

CREATE INDEX idx_membership_transfers_membership_id ON membership_transfers(membership_id);
CREATE INDEX idx_membership_transfers_from_user_id  ON membership_transfers(from_user_id);
CREATE INDEX idx_membership_transfers_to_user_id    ON membership_transfers(to_user_id);

CREATE TRIGGER trg_membership_transfers_updated_at
    BEFORE UPDATE ON membership_transfers
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- SKILL CATEGORIES
-- Self-referencing: parent_id NULL = top-level category.
-- Example hierarchy: Trades > Plumbing, Trades > Electrical
-- Links to category_pricing_rules for minimum bid floors.
-- ============================================================

CREATE TABLE skill_categories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id   UUID REFERENCES skill_categories(id) ON DELETE SET NULL,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   BOOLEAN   DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_skill_categories_name UNIQUE (name)
);

CREATE INDEX idx_skill_categories_parent_id ON skill_categories(parent_id);

CREATE TRIGGER trg_skill_categories_updated_at
    BEFORE UPDATE ON skill_categories
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- SKILLS
-- Master catalogue of skills workers can claim and jobs
-- can require. Linked to skill_categories.
-- Admin manages this list via CRUD in the admin panel.
-- ============================================================

CREATE TABLE skills (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES skill_categories(id) ON DELETE SET NULL,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   BOOLEAN   DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_skills_name UNIQUE (name)
);

CREATE INDEX idx_skills_category_id ON skills(category_id);
CREATE INDEX idx_skills_is_active   ON skills(is_active);

CREATE TRIGGER trg_skills_updated_at
    BEFORE UPDATE ON skills
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER SKILLS
-- Connects workers to the skills they offer.
-- proficiency_level: 'beginner' | 'intermediate' | 'expert'
-- verified_by: admin or system user that confirmed the skill.
-- DB constraint: cannot mark verified without verifier + date.
-- ============================================================

CREATE TABLE user_skills (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_id          UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    proficiency_level VARCHAR(20) DEFAULT 'intermediate',
    years_experience  SMALLINT    DEFAULT 0,
    is_verified       BOOLEAN     DEFAULT FALSE,
    verified_by       UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at       TIMESTAMP,
    created_at        TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_skills_pair        UNIQUE (user_id, skill_id),
    CONSTRAINT chk_proficiency_level      CHECK  (proficiency_level IN ('beginner', 'intermediate', 'expert')),
    CONSTRAINT chk_years_non_negative     CHECK  (years_experience >= 0),
    CONSTRAINT chk_verified_has_verifier  CHECK  (
        is_verified = FALSE
        OR (is_verified = TRUE AND verified_by IS NOT NULL AND verified_at IS NOT NULL)
    )
);

CREATE INDEX idx_user_skills_user_id  ON user_skills(user_id);
CREATE INDEX idx_user_skills_skill_id ON user_skills(skill_id);

-- Fast lookup of verified skills only (used in ranking + trust score)
CREATE INDEX idx_user_skills_verified
    ON user_skills(skill_id)
    WHERE is_verified = TRUE;

CREATE TRIGGER trg_user_skills_updated_at
    BEFORE UPDATE ON user_skills
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- JOBS
-- ============================================================

CREATE TABLE jobs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID REFERENCES users(id),
    title       VARCHAR(200) NOT NULL,
    description TEXT,
    status      VARCHAR(30) DEFAULT 'open',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_jobs_client_id ON jobs(client_id);
CREATE INDEX idx_jobs_status    ON jobs(status);

CREATE TRIGGER trg_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- JOB SKILLS
-- Skills a client requires (or prefers) for a job posting.
-- is_required = TRUE  → hard requirement, workers without it
--                        should rank lower or be filtered out.
-- is_required = FALSE → nice-to-have / preferred.
-- Must be inserted after both jobs and skills tables exist.
-- ============================================================

CREATE TABLE job_skills (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id            UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    skill_id          UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    is_required       BOOLEAN     DEFAULT TRUE,
    proficiency_level VARCHAR(20) DEFAULT 'intermediate',
    CONSTRAINT uq_job_skills_pair  UNIQUE (job_id, skill_id),
    CONSTRAINT chk_job_proficiency CHECK  (proficiency_level IN ('beginner', 'intermediate', 'expert'))
);

CREATE INDEX idx_job_skills_job_id   ON job_skills(job_id);
CREATE INDEX idx_job_skills_skill_id ON job_skills(skill_id);

-- ============================================================
-- PROPOSALS
-- ============================================================

CREATE TABLE proposals (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id     UUID REFERENCES jobs(id) ON DELETE CASCADE,
    worker_id  UUID REFERENCES users(id),
    bid_amount NUMERIC(12,2) NOT NULL,
    status     VARCHAR(30) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_bid_amount_positive CHECK (bid_amount > 0),
    CONSTRAINT uq_proposals_job_worker UNIQUE (job_id, worker_id)
);

CREATE INDEX idx_proposals_job_id    ON proposals(job_id);
CREATE INDEX idx_proposals_worker_id ON proposals(worker_id);

CREATE TRIGGER trg_proposals_updated_at
    BEFORE UPDATE ON proposals
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- REFERRALS
-- client_id / worker_id removed — derivable from proposal_id
-- So this table is the final record of a completed job, with all the financial details needed for payments and reporting.
-- agreed_amount: the final agreed price for the job, which may
-- differ from the original bid_amount in the proposal.
-- commission_percent: the % of the agreed_amount that the platform
-- charges as a commission fee, based on the service_commissions table.
-- ============================================================

CREATE TABLE referrals (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id        UUID UNIQUE REFERENCES proposals(id),
    agreed_amount      NUMERIC(12,2) NOT NULL,
    commission_percent NUMERIC(5,2)  NOT NULL,
    status             VARCHAR(30) DEFAULT 'accepted',
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_referral_amount_positive CHECK (agreed_amount > 0),
    CONSTRAINT chk_commission_percent_range CHECK (commission_percent BETWEEN 0 AND 100)
);

CREATE INDEX idx_referrals_proposal_id ON referrals(proposal_id);

CREATE TRIGGER trg_referrals_updated_at
    BEFORE UPDATE ON referrals
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- MESSAGING
-- Circular dependency fix: last_message_id removed from
-- conversations; use the view below instead.
-- ============================================================

CREATE TABLE conversations (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id  UUID REFERENCES users(id),
    worker_id  UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_conversations_pair    UNIQUE (client_id, worker_id),
    CONSTRAINT chk_conversation_no_self CHECK  (client_id <> worker_id)
);

CREATE INDEX idx_conversations_client_id ON conversations(client_id);
CREATE INDEX idx_conversations_worker_id ON conversations(worker_id);

CREATE TRIGGER trg_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE messages (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id         UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id               UUID REFERENCES users(id),
    message_text            TEXT,
    message_type            VARCHAR(20) DEFAULT 'text',
    is_deleted_by_sender    BOOLEAN DEFAULT FALSE,
    is_deleted_by_recipient BOOLEAN DEFAULT FALSE,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_conversation_id      ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id            ON messages(sender_id);
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at DESC);

CREATE VIEW conversation_latest_message AS
SELECT DISTINCT ON (conversation_id)
    conversation_id,
    id          AS message_id,
    sender_id,
    message_text,
    created_at  AS last_message_at
FROM messages
ORDER BY conversation_id, created_at DESC;

-- ============================================================
-- ADS
-- ============================================================

CREATE TABLE ads (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        VARCHAR(150) NOT NULL,
    image_path   TEXT,
    redirect_url TEXT,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    status       VARCHAR(20) DEFAULT 'active',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ad_dates CHECK (end_date >= start_date)
);

CREATE INDEX idx_ads_active_dates ON ads(status, start_date, end_date);

CREATE TRIGGER trg_ads_updated_at
    BEFORE UPDATE ON ads
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE ad_views (
    id             BIGSERIAL PRIMARY KEY,
    ad_id          UUID REFERENCES ads(id) ON DELETE CASCADE,
    viewer_user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
    session_id     VARCHAR(100),
    ip_address     INET,
    user_agent     VARCHAR(255),
    viewed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_views_ad_id          ON ad_views(ad_id);
CREATE INDEX idx_ad_views_viewer_user_id ON ad_views(viewer_user_id);

CREATE TABLE ad_clicks (
    id              BIGSERIAL PRIMARY KEY,
    ad_id           UUID REFERENCES ads(id) ON DELETE CASCADE,
    clicker_user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
    session_id      VARCHAR(100),
    ip_address      INET,
    user_agent      VARCHAR(255),
    clicked_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_clicks_ad_id           ON ad_clicks(ad_id);
CREATE INDEX idx_ad_clicks_clicker_user_id ON ad_clicks(clicker_user_id);

-- ============================================================
-- PAYMENTS
-- ============================================================

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id),
    payment_type    VARCHAR(30),
    amount          NUMERIC(12,2) NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending',
    method          VARCHAR(50),
    transaction_ref VARCHAR(100) UNIQUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_payment_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status  ON payments(status);

CREATE TRIGGER trg_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- ORDERS
-- Linked to a proposal so the order is traceable to a
-- specific job and worker.
-- ============================================================

CREATE TABLE orders (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id  UUID REFERENCES proposals(id),
    payment_id   UUID REFERENCES payments(id),
    buyer_id     UUID REFERENCES users(id),
    seller_id    UUID REFERENCES users(id),
    total_amount NUMERIC(12,2) NOT NULL,
    status       VARCHAR(30) DEFAULT 'pending',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_order_amount_positive CHECK (total_amount > 0),
    CONSTRAINT chk_order_no_self_deal    CHECK (buyer_id <> seller_id)
);

CREATE INDEX idx_orders_proposal_id ON orders(proposal_id);
CREATE INDEX idx_orders_payment_id  ON orders(payment_id);
CREATE INDEX idx_orders_buyer_id    ON orders(buyer_id);
CREATE INDEX idx_orders_seller_id   ON orders(seller_id);

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             VARCHAR(200),
    body              TEXT,
    notification_type VARCHAR(20) DEFAULT 'info',
    target_user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    is_sent           BOOLEAN DEFAULT FALSE,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_unsent
    ON notifications(target_user_id, is_sent)
    WHERE is_sent = FALSE;

-- ============================================================
-- REVIEWS
-- ============================================================

CREATE TABLE reviews (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reviewer_id      UUID REFERENCES users(id),
    reviewed_user_id UUID REFERENCES users(id),
    stars            INT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    comment          TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_review_no_self CHECK (reviewer_id <> reviewed_user_id),
    CONSTRAINT uq_reviews_pair    UNIQUE (reviewer_id, reviewed_user_id)
);

CREATE INDEX idx_reviews_reviewer_id      ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewed_user_id ON reviews(reviewed_user_id);

-- ============================================================
-- SEED DATA: roles
-- ============================================================

INSERT INTO roles (role_name) VALUES
    ('admin'),
    ('client'),
    ('worker'),
    ('business');

-- ============================================================
-- SEED DATA: membership plans
-- ============================================================

INSERT INTO membership_plans
    (plan_name, monthly_bid_limit, monthly_connects, can_unlimited_bids, priority_rank, price_jmd, suppress_ads)
VALUES
    ('Free',    20,  20,  FALSE, 0, 0,       FALSE),
    ('Premium', 60,  60,  FALSE, 1, 2500.00, TRUE),
    ('Elite',   NULL, 999, TRUE,  2, 5000.00, TRUE);

-- ============================================================
-- SEED DATA: badge types
-- ============================================================

INSERT INTO badge_types (code, label, description) VALUES
    ('id_verified',      'ID Verified',      'Government-issued ID confirmed'),
    ('phone_verified',   'Phone Verified',   'Mobile number confirmed via OTP'),
    ('email_verified',   'Email Verified',   'Email address confirmed'),
    ('address_verified', 'Address Verified', 'Physical address confirmed'),
    ('payment_verified', 'Payment Verified', 'Payment method on file confirmed');

-- ============================================================
-- SEED DATA: skill categories and skills
-- ============================================================

INSERT INTO skill_categories (name, description) VALUES
    ('Trades',             'Physical skilled trades and technical work'),
    ('Creative Services',  'Design, media, and creative production'),
    ('Digital Services',   'Software, web, and technology services'),
    ('Domestic Services',  'Household and personal services'),
    ('Business Services',  'Administrative and professional services');

INSERT INTO skills (category_id, name, description)
SELECT id, 'Plumbing',          'Pipe installation, repair, and maintenance'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Electrical Wiring', 'Residential and commercial electrical work'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Carpentry',         'Woodwork, furniture, and structural carpentry'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Tiling',            'Floor and wall tile installation'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Painting',          'Interior and exterior painting'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Welding',           'Metal fabrication and welding'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'AC Repair',         'Air conditioning installation and servicing'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Graphic Design',    'Logos, branding, and print design'
FROM skill_categories WHERE name = 'Creative Services'
UNION ALL
SELECT id, 'Photography',       'Commercial and event photography'
FROM skill_categories WHERE name = 'Creative Services'
UNION ALL
SELECT id, 'Video Editing',     'Post-production video and audio editing'
FROM skill_categories WHERE name = 'Creative Services'
UNION ALL
SELECT id, 'Web Development',   'Frontend, backend, and full-stack development'
FROM skill_categories WHERE name = 'Digital Services'
UNION ALL
SELECT id, 'Mobile App Development', 'iOS and Android app development'
FROM skill_categories WHERE name = 'Digital Services'
UNION ALL
SELECT id, 'Social Media Management', 'Content creation and account management'
FROM skill_categories WHERE name = 'Digital Services'
UNION ALL
SELECT id, 'Cleaning',          'Residential and commercial cleaning'
FROM skill_categories WHERE name = 'Domestic Services'
UNION ALL
SELECT id, 'Landscaping',       'Garden design, lawn care, and tree trimming'
FROM skill_categories WHERE name = 'Domestic Services'
UNION ALL
SELECT id, 'Childcare',         'Babysitting and nanny services'
FROM skill_categories WHERE name = 'Domestic Services'
UNION ALL
SELECT id, 'Data Entry',        'Typing, spreadsheet, and database entry'
FROM skill_categories WHERE name = 'Business Services'
UNION ALL
SELECT id, 'Accounting',        'Bookkeeping and financial reporting'
FROM skill_categories WHERE name = 'Business Services'
UNION ALL
SELECT id, 'Event Planning',    'Corporate and personal event coordination'
FROM skill_categories WHERE name = 'Business Services';

-- ============================================================
-- SERVICE COMMISSIONS
-- Admin-managed commission rates the platform charges on
-- completed jobs. Resolution order (most specific wins):
--   1. Per-skill row     (skill_id IS NOT NULL)
--   2. Per-category row  (skill_category_id IS NOT NULL, skill_id IS NULL)
--   3. Platform default  (both NULL, is_default = TRUE)
--
-- fee_type: 'percent' deducts a % of agreed_amount;
--           'flat'    deducts a fixed JMD amount.
-- waive_below_jmd: jobs under this value pay no commission.
-- updated_by: the admin user who last changed the rate.
-- ============================================================

CREATE TABLE service_commissions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_category_id   UUID REFERENCES skill_categories(id) ON DELETE CASCADE,
    skill_id            UUID REFERENCES skills(id) ON DELETE CASCADE,
    label               VARCHAR(150),
    fee_type            VARCHAR(10)   NOT NULL DEFAULT 'percent',
    fee_value           NUMERIC(8,2)  NOT NULL,
    waive_below_jmd     NUMERIC(12,2) DEFAULT 0,
    is_active           BOOLEAN       DEFAULT TRUE,
    is_default          BOOLEAN       DEFAULT FALSE,
    notes               TEXT,
    updated_by          UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_commission_fee_type
        CHECK (fee_type IN ('percent', 'flat')),
    CONSTRAINT chk_commission_fee_value_positive
        CHECK (fee_value > 0),
    CONSTRAINT chk_commission_percent_max
        CHECK (fee_type <> 'percent' OR fee_value <= 100),
    CONSTRAINT chk_commission_waive_non_negative
        CHECK (waive_below_jmd >= 0),
    -- A default row must not also target a category or skill
    CONSTRAINT chk_commission_default_exclusive
        CHECK (
            is_default = FALSE
            OR (is_default = TRUE AND skill_category_id IS NULL AND skill_id IS NULL)
        ),
    -- A skill-level row must also reference its category
    CONSTRAINT chk_commission_skill_needs_category
        CHECK (skill_id IS NULL OR skill_category_id IS NOT NULL),
    -- One row per (category, skill) combination
    CONSTRAINT uq_commission_per_category_skill
        UNIQUE (skill_category_id, skill_id)
);

-- Enforce exactly one platform-wide default row
CREATE UNIQUE INDEX idx_service_commissions_one_default
    ON service_commissions (is_default)
    WHERE is_default = TRUE;

CREATE INDEX idx_service_commissions_category_id ON service_commissions(skill_category_id);
CREATE INDEX idx_service_commissions_skill_id    ON service_commissions(skill_id);
CREATE INDEX idx_service_commissions_updated_by  ON service_commissions(updated_by);
CREATE INDEX idx_service_commissions_active      ON service_commissions(is_active);

CREATE TRIGGER trg_service_commissions_updated_at
    BEFORE UPDATE ON service_commissions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- VIEW: v_resolved_commission
-- Resolves the correct commission for any skill, applying
-- priority: per-skill > per-category > platform default.
-- Admin can query this to preview what rate will apply.
-- ============================================================

CREATE VIEW v_resolved_commission AS
SELECT
    s.id                        AS skill_id,
    s.name                      AS skill_name,
    sc.name                     AS category_name,
    COALESCE(
        (SELECT fee_type  FROM service_commissions
         WHERE skill_id = s.id AND is_active = TRUE LIMIT 1),
        (SELECT fee_type  FROM service_commissions
         WHERE skill_category_id = s.category_id
           AND skill_id IS NULL AND is_active = TRUE LIMIT 1),
        (SELECT fee_type  FROM service_commissions
         WHERE is_default = TRUE AND is_active = TRUE LIMIT 1)
    )                           AS resolved_fee_type,
    COALESCE(
        (SELECT fee_value FROM service_commissions
         WHERE skill_id = s.id AND is_active = TRUE LIMIT 1),
        (SELECT fee_value FROM service_commissions
         WHERE skill_category_id = s.category_id
           AND skill_id IS NULL AND is_active = TRUE LIMIT 1),
        (SELECT fee_value FROM service_commissions
         WHERE is_default = TRUE AND is_active = TRUE LIMIT 1)
    )                           AS resolved_fee_value,
    COALESCE(
        (SELECT waive_below_jmd FROM service_commissions
         WHERE skill_id = s.id AND is_active = TRUE LIMIT 1),
        (SELECT waive_below_jmd FROM service_commissions
         WHERE skill_category_id = s.category_id
           AND skill_id IS NULL AND is_active = TRUE LIMIT 1),
        (SELECT waive_below_jmd FROM service_commissions
         WHERE is_default = TRUE AND is_active = TRUE LIMIT 1)
    )                           AS resolved_waive_below_jmd
FROM skills s
JOIN skill_categories sc ON sc.id = s.category_id;

-- ============================================================
-- SEED DATA: service_commissions
-- Platform default + one rate per skill category.
-- Admin can edit all values via CRUD panel.
-- ============================================================

INSERT INTO service_commissions
    (skill_category_id, skill_id, label, fee_type, fee_value, waive_below_jmd, is_default, notes)
VALUES
    -- Platform-wide fallback (no category or skill)
    (NULL, NULL,
     'Platform default', 'percent', 8.00, 1500.00, TRUE,
     'Applies to any job not covered by a category or skill-specific rate');

INSERT INTO service_commissions
    (skill_category_id, skill_id, label, fee_type, fee_value, waive_below_jmd, notes)
SELECT
    id, NULL,
    name || ' — category rate', 'percent', rate, waive, note
FROM (VALUES
    ('Trades',            10.00, 2000.00, 'Higher rate reflects reliable repeat work'),
    ('Creative Services',  9.00, 1500.00, 'Standard creative services rate'),
    ('Digital Services',   8.00, 1500.00, 'Standard digital services rate'),
    ('Domestic Services',  7.00, 1000.00, 'Lower rate encourages entry-level workers'),
    ('Business Services',  8.00, 1500.00, 'Standard business services rate')
) AS t(cat_name, rate, waive, note)
JOIN skill_categories ON skill_categories.name = t.cat_name;
