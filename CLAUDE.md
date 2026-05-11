# JointU — CLAUDE.md

## Project Overview

JointU is a Jamaican freelance marketplace connecting clients who need work done with skilled workers. Think Upwork/Fiverr for Jamaica. Currency: **JMD**.

---

## Tech Stack

### Frontend
- Vanilla HTML/CSS/JS (no framework)
- Pages served as `.html` files

### Backend
- PHP (REST API under `api/`)
- JWT authentication

### Database
- PostgreSQL (schema: `jointu_schema_v9.sql`)
- UUID primary keys (`gen_random_uuid()` via `pgcrypto`)
- Auto-updating `updated_at` via `set_updated_at()` trigger function

### Deployment
- TBD

---

## Folder Structure

```
jointu/
├── api/
│   ├── admin/
│   ├── auth/
│   ├── config/
│   ├── includes/
│   ├── jobs/
│   ├── payments/
│   ├── proposals/
│   └── users/
├── assets/
├── css/
├── js/
│   └── main.js
├── pages/
│   ├── admin/
│   ├── auth/
│   ├── client/
│   └── worker/
├── uploads/
├── jointu_schema_v9.sql
└── index.html
```

---

## Roles

| Role | Description |
|------|-------------|
| `admin` | Platform administrator |
| `client` | Posts jobs, hires workers |
| `worker` | Bids on jobs, completes work |
| `business` | Business account (extended client) |

---

## Membership Plans

| Plan | Price (JMD/mo) | Bid Limit | Connects | Ads Suppressed |
|------|----------------|-----------|----------|---------------|
| Free | 0 | 20 | 20 | No |
| Premium | 2,500 | 60 | 60 | Yes |
| Elite | 5,000 | Unlimited | 999 | Yes |

---

## Key Data Models

### users
- UUID PK, role_id, plan_id, email, phone, password_hash, is_verified, is_active, is_disabled

### user_profiles
- user_id (FK), first_name, last_name, display_name, bio

### user_wallets
- user_id (FK), wallet_balance (≥ 0, NUMERIC 12,2)

### jobs
- id, client_id (FK → users), title, description, status (`open` default)

### proposals
- id, job_id, worker_id, bid_amount (> 0), status (`pending` default)
- UNIQUE (job_id, worker_id) — one bid per worker per job

### referrals
- id, proposal_id (UNIQUE), agreed_amount, commission_percent, status (`accepted`)
- Final record of a completed/accepted job with financial details

### orders
- id, proposal_id, payment_id, buyer_id, seller_id, total_amount, status (`pending`)

### payments
- id, user_id, payment_type, amount, status, method, transaction_ref (UNIQUE)

### conversations + messages
- conversations: client_id ↔ worker_id (UNIQUE pair, no self-chat)
- messages: text, soft-delete per side (is_deleted_by_sender/recipient)

### service_commissions
- Commission resolution priority: per-skill > per-category > platform default
- fee_type: `percent` or `flat`
- waive_below_jmd: jobs under this threshold pay no commission

### skill_categories (self-referencing hierarchy)
- Top-level: Trades, Creative Services, Digital Services, Domestic Services, Business Services

### user_skills
- proficiency_level: `beginner` | `intermediate` | `expert`
- Verification requires verified_by + verified_at

### badge_types / user_badges
- Seed badges: id_verified, phone_verified, email_verified, address_verified, payment_verified

### ads / ad_views / ad_clicks
- Admin-managed ads with view/click tracking (IP, session, user_agent)

---

## API Routes (PHP)

### Auth (`api/auth/`)
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Register, returns JWT |
| POST | `/api/auth/login` | Login, returns JWT |
| POST | `/api/auth/logout` | Invalidate token |

### Users (`api/users/`)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/users/me` | Current user profile |
| PUT | `/api/users/me` | Update profile |

### Jobs (`api/jobs/`)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/jobs` | List jobs (filterable) |
| POST | `/api/jobs` | Create job (client) |
| GET | `/api/jobs/:id` | Job detail |
| PUT | `/api/jobs/:id` | Update job |
| DELETE | `/api/jobs/:id` | Delete job |

### Proposals (`api/proposals/`)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/proposals?job_id=` | List proposals for job |
| POST | `/api/proposals` | Submit bid (worker) |
| PUT | `/api/proposals/:id` | Accept/reject bid |

### Payments (`api/payments/`)
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/payments` | Create payment |
| GET | `/api/payments` | Payment history |

### Admin (`api/admin/`)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/admin/users` | List all users |
| GET | `/api/admin/jobs` | List all jobs |
| GET | `/api/admin/ads` | Manage ads |
| GET | `/api/admin/commissions` | View/edit commission rules |

All authenticated routes require `Authorization: Bearer <token>` header.

---

## Pages

### Public
- `/index.html` — Landing page
- `/login.html` — Login
- `/signup.html` — Register
- `/resetpassword.html` — Password reset
- `/faq.html` — FAQ

### Client (authenticated)
- `/client-dashboard.html` — Overview
- `/client-post.html` — Post a job
- `/client-active-jobs.html` — Manage active jobs
- `/client-job-detail.html` — Job detail + proposals
- `/client-settings.html` — Profile/settings

### Worker (authenticated)
- `/worker-overview.html` — Dashboard
- `/workerfind_jobs.html` — Browse jobs
- `/worker-bids.html` — My bids/proposals
- `/worker_working.html` — Active job in progress
- `/worker-payments.html` — Earnings/payouts
- `/worker-portfolio.html` — Portfolio
- `/worker-history.html` — Completed jobs
- `/worker-messages.html` — Messaging
- `/worker-disputes.html` — Disputes
- `/worker-settings.html` — Profile/settings

### Admin (authenticated)
- `/admin-dashboard.html` — Platform overview
- `/admin-users.html` — User management
- `/admin-jobs.html` — Job moderation
- `/admin-ads.html` — Ad management
- `/admin-disputes.html` — Dispute resolution
- `/admin-market-rules.html` — Commission rules
- `/admin-settings.html` — Platform settings

---

## Security Requirements

- Passwords hashed (bcrypt, salt ≥ 10)
- JWT in httpOnly cookie or Authorization header
- All non-public routes protected by auth middleware (PHP)
- Input validated + sanitized before DB writes
- Parameterized queries only — no raw string interpolation into SQL

---

## DB Notes

- All PKs are UUID (`gen_random_uuid()` via pgcrypto extension)
- All tables have `created_at` / `updated_at` timestamps
- `updated_at` auto-updated via `set_updated_at()` trigger (defined once, reused)
- Partial unique indexes enforce single-active-record constraints (e.g., one primary address, one active membership)
- `wallet_balance` CHECK constraint prevents negatives at DB level
