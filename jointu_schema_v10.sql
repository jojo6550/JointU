-- ============================================================
-- JOINTU DATABASE SCHEMA v10 — PostgreSQL
-- Changes from v9:
--   1. user_profiles: ADD business_type (Business account type)
--   2. jobs: ADD budget, deadline, location_parish, connects_cost
--   3. job_attachments: NEW table (file uploads per job)
--   4. proposals: ADD cover_letter
--   5. conversations: ADD job_id (per-job threads, UNIQUE per trio)
--   6. notifications: ADD is_read, read_at
--   7. orders: no change (created before reviews — ordering preserved)
--   8. reviews: ADD order_id FK; UNIQUE per (reviewer, order) not per pair
--   9. wallet_transactions: NEW ledger table for wallet debit/credit history
-- All previous v9 tables and constraints preserved unchanged unless noted.
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
-- v10: ADD business_type for 'business' role accounts.
-- ============================================================

CREATE TABLE user_profiles (
    user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    first_name    VARCHAR(80),
    last_name     VARCHAR(80),
    display_name  VARCHAR(160),
    bio           TEXT,
    business_type VARCHAR(50),
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER WALLETS
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
-- WALLET TRANSACTIONS
-- v10: NEW — ledger of every wallet credit and debit.
-- direction: 'credit' = money in, 'debit' = money out.
-- reference_id: optional pointer to the payment/order that
--   triggered this transaction (polymorphic, no FK enforced).
-- ============================================================

CREATE TABLE wallet_transactions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount       NUMERIC(12,2) NOT NULL,
    direction    VARCHAR(6)    NOT NULL,
    reference_id UUID,
    description  TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_wallet_tx_direction    CHECK (direction IN ('credit', 'debit')),
    CONSTRAINT chk_wallet_tx_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_wallet_transactions_user_id    ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX idx_wallet_transactions_reference  ON wallet_transactions(reference_id);

-- ============================================================
-- USER ADDRESSES
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

CREATE UNIQUE INDEX idx_user_addresses_one_primary
    ON user_addresses(user_id)
    WHERE is_primary = TRUE;

CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);

CREATE TRIGGER trg_user_addresses_updated_at
    BEFORE UPDATE ON user_addresses
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- USER CONTACTS
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

CREATE INDEX idx_user_contacts_user_id ON user_contacts(user_id);
CREATE INDEX idx_user_contacts_value   ON user_contacts(contact_value);

CREATE TRIGGER trg_user_contacts_updated_at
    BEFORE UPDATE ON user_contacts
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- WORKER SERVICE AREAS
-- ============================================================

CREATE TABLE worker_service_areas (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    country      VARCHAR(100) NOT NULL DEFAULT 'Jamaica',
    state_parish VARCHAR(100),
    city         VARCHAR(100),
    is_global    BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_service_area_valid CHECK (
        is_global = TRUE
        OR state_parish IS NOT NULL
        OR city IS NOT NULL
    )
);

CREATE INDEX idx_worker_service_areas_user_id  ON worker_service_areas(user_id);
CREATE INDEX idx_worker_service_areas_location ON worker_service_areas(state_parish, city);
CREATE INDEX idx_worker_service_areas_global   ON worker_service_areas(is_global);

CREATE UNIQUE INDEX uq_worker_service_area_unique
    ON worker_service_areas(user_id, state_parish, city)
    WHERE is_global = FALSE;

CREATE UNIQUE INDEX uq_worker_service_area_global
    ON worker_service_areas(user_id)
    WHERE is_global = TRUE;

CREATE TRIGGER trg_worker_service_areas_updated_at
    BEFORE UPDATE ON worker_service_areas
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- BADGE TYPES
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

CREATE INDEX idx_user_skills_verified
    ON user_skills(skill_id)
    WHERE is_verified = TRUE;

CREATE TRIGGER trg_user_skills_updated_at
    BEFORE UPDATE ON user_skills
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- JOBS
-- v10: ADD budget, deadline, location_parish, connects_cost.
-- budget: client's estimated spend (informational, not binding).
-- deadline: requested completion date.
-- location_parish: where the work takes place (optional).
-- connects_cost: how many connects a worker spends to bid.
-- ============================================================

CREATE TABLE jobs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id        UUID REFERENCES users(id),
    title            VARCHAR(200) NOT NULL,
    description      TEXT,
    budget           NUMERIC(12,2),
    deadline         DATE,
    location_parish  VARCHAR(100),
    connects_cost    SMALLINT    DEFAULT 1,
    status           VARCHAR(30) DEFAULT 'open',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_job_budget_positive    CHECK (budget IS NULL OR budget > 0),
    CONSTRAINT chk_job_connects_positive  CHECK (connects_cost >= 1)
);

CREATE INDEX idx_jobs_client_id       ON jobs(client_id);
CREATE INDEX idx_jobs_status          ON jobs(status);
CREATE INDEX idx_jobs_location_parish ON jobs(location_parish);

CREATE TRIGGER trg_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- JOB ATTACHMENTS
-- v10: NEW — files uploaded by the client when posting a job.
-- file_type: 'image', 'video', 'document', etc.
-- ============================================================

CREATE TABLE job_attachments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id     UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    file_path  TEXT NOT NULL,
    file_name  VARCHAR(255),
    file_type  VARCHAR(50),
    file_size  INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_attachment_file_size CHECK (file_size IS NULL OR file_size > 0)
);

CREATE INDEX idx_job_attachments_job_id ON job_attachments(job_id);

-- ============================================================
-- JOB SKILLS
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
-- v10: ADD cover_letter — worker's message to the client.
-- ============================================================

CREATE TABLE proposals (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id       UUID REFERENCES jobs(id) ON DELETE CASCADE,
    worker_id    UUID REFERENCES users(id),
    bid_amount   NUMERIC(12,2) NOT NULL,
    cover_letter TEXT,
    status       VARCHAR(30) DEFAULT 'pending',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_bid_amount_positive  CHECK (bid_amount > 0),
    CONSTRAINT uq_proposals_job_worker  UNIQUE (job_id, worker_id)
);

CREATE INDEX idx_proposals_job_id    ON proposals(job_id);
CREATE INDEX idx_proposals_worker_id ON proposals(worker_id);

CREATE TRIGGER trg_proposals_updated_at
    BEFORE UPDATE ON proposals
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- REFERRALS
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
-- v10: ADD job_id to conversations so each job gets its own
-- thread. UNIQUE enforced per (client, worker, job) trio.
-- job_id NOT NULL — all conversations on this platform are
-- job-scoped.
-- ============================================================

CREATE TABLE conversations (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id  UUID NOT NULL REFERENCES users(id),
    worker_id  UUID NOT NULL REFERENCES users(id),
    job_id     UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_conversations_trio   UNIQUE (client_id, worker_id, job_id),
    CONSTRAINT chk_conversation_no_self CHECK  (client_id <> worker_id)
);

CREATE INDEX idx_conversations_client_id ON conversations(client_id);
CREATE INDEX idx_conversations_worker_id ON conversations(worker_id);
CREATE INDEX idx_conversations_job_id    ON conversations(job_id);

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
-- v10: ADD is_read, read_at for unread-count and mark-as-read.
-- is_sent: notification dispatched (push/email/SMS).
-- is_read: user opened/acknowledged it in the UI.
-- ============================================================

CREATE TABLE notifications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             VARCHAR(200),
    body              TEXT,
    notification_type VARCHAR(20) DEFAULT 'info',
    target_user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    is_sent           BOOLEAN   DEFAULT FALSE,
    is_read           BOOLEAN   DEFAULT FALSE,
    read_at           TIMESTAMP,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_notification_read_date CHECK (read_at IS NULL OR is_read = TRUE)
);

CREATE INDEX idx_notifications_user_unsent
    ON notifications(target_user_id, is_sent)
    WHERE is_sent = FALSE;

CREATE INDEX idx_notifications_user_unread
    ON notifications(target_user_id, is_read)
    WHERE is_read = FALSE;

-- ============================================================
-- REVIEWS
-- v10: ADD order_id FK — reviews are scoped per order, not per
-- user pair. This allows reviewing a worker across multiple
-- separate jobs. UNIQUE per (reviewer, order) prevents double-
-- reviewing the same order.
-- ============================================================

CREATE TABLE reviews (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reviewer_id      UUID REFERENCES users(id),
    reviewed_user_id UUID REFERENCES users(id),
    order_id         UUID NOT NULL REFERENCES orders(id),
    stars            INT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    comment          TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_review_no_self     CHECK (reviewer_id <> reviewed_user_id),
    CONSTRAINT uq_review_per_order    UNIQUE (reviewer_id, order_id)
);

CREATE INDEX idx_reviews_reviewer_id      ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewed_user_id ON reviews(reviewed_user_id);
CREATE INDEX idx_reviews_order_id         ON reviews(order_id);

-- ============================================================
-- SERVICE COMMISSIONS
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
    CONSTRAINT chk_commission_default_exclusive
        CHECK (
            is_default = FALSE
            OR (is_default = TRUE AND skill_category_id IS NULL AND skill_id IS NULL)
        ),
    CONSTRAINT chk_commission_skill_needs_category
        CHECK (skill_id IS NULL OR skill_category_id IS NOT NULL),
    CONSTRAINT uq_commission_per_category_skill
        UNIQUE (skill_category_id, skill_id)
);

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
    ('Free',    20,   20,  FALSE, 0, 0,       FALSE),
    ('Premium', 60,   60,  FALSE, 1, 2500.00, TRUE),
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
    ('Trades',            'Physical skilled trades and technical work'),
    ('Creative Services', 'Design, media, and creative production'),
    ('Digital Services',  'Software, web, and technology services'),
    ('Domestic Services', 'Household and personal services'),
    ('Business Services', 'Administrative and professional services');

INSERT INTO skills (category_id, name, description)
SELECT id, 'Plumbing',               'Pipe installation, repair, and maintenance'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Electrical Wiring',      'Residential and commercial electrical work'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Carpentry',              'Woodwork, furniture, and structural carpentry'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Tiling',                 'Floor and wall tile installation'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Painting',               'Interior and exterior painting'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Welding',                'Metal fabrication and welding'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'AC Repair',              'Air conditioning installation and servicing'
FROM skill_categories WHERE name = 'Trades'
UNION ALL
SELECT id, 'Graphic Design',         'Logos, branding, and print design'
FROM skill_categories WHERE name = 'Creative Services'
UNION ALL
SELECT id, 'Photography',            'Commercial and event photography'
FROM skill_categories WHERE name = 'Creative Services'
UNION ALL
SELECT id, 'Video Editing',          'Post-production video and audio editing'
FROM skill_categories WHERE name = 'Creative Services'
UNION ALL
SELECT id, 'Web Development',        'Frontend, backend, and full-stack development'
FROM skill_categories WHERE name = 'Digital Services'
UNION ALL
SELECT id, 'Mobile App Development', 'iOS and Android app development'
FROM skill_categories WHERE name = 'Digital Services'
UNION ALL
SELECT id, 'Social Media Management','Content creation and account management'
FROM skill_categories WHERE name = 'Digital Services'
UNION ALL
SELECT id, 'Cleaning',               'Residential and commercial cleaning'
FROM skill_categories WHERE name = 'Domestic Services'
UNION ALL
SELECT id, 'Landscaping',            'Garden design, lawn care, and tree trimming'
FROM skill_categories WHERE name = 'Domestic Services'
UNION ALL
SELECT id, 'Childcare',              'Babysitting and nanny services'
FROM skill_categories WHERE name = 'Domestic Services'
UNION ALL
SELECT id, 'Data Entry',             'Typing, spreadsheet, and database entry'
FROM skill_categories WHERE name = 'Business Services'
UNION ALL
SELECT id, 'Accounting',             'Bookkeeping and financial reporting'
FROM skill_categories WHERE name = 'Business Services'
UNION ALL
SELECT id, 'Event Planning',         'Corporate and personal event coordination'
FROM skill_categories WHERE name = 'Business Services';

-- ============================================================
-- SEED DATA: service_commissions
-- ============================================================

INSERT INTO service_commissions
    (skill_category_id, skill_id, label, fee_type, fee_value, waive_below_jmd, is_default, notes)
VALUES
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
