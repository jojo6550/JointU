# JointU — File Structure

```
jointu/
├── index.php                          # Landing page
├── rules.json                         # (untracked) Platform rules config
│
├── api/                               # PHP REST API
│   ├── admin/                         # Admin endpoints
│   ├── auth/                          # Auth endpoints (register, login, logout)
│   ├── config/                        # DB config, env
│   ├── includes/                      # Shared middleware (auth guard, helpers)
│   ├── jobs/                          # Job CRUD endpoints
│   ├── payments/
│   │   └── demo.php                   # Payment demo/test
│   ├── proposals/                     # Bid/proposal endpoints
│   └── users/                         # User profile endpoints
│
├── css/
│   └── style.css                      # Global stylesheet
│
├── js/
│   └── main.js                        # Global JS
│
├── pages/
│   ├── public/
│   │   └── faq.php
│   │
│   ├── auth/
│   │   ├── login.php
│   │   ├── signup.php
│   │   └── resetpassword.php
│   │
│   ├── client/
│   │   ├── client-dashboard.php       # Overview
│   │   ├── client-post.php            # Post a job
│   │   ├── client-active-jobs.php     # Manage active jobs
│   │   ├── client-completed-jobs.php
│   │   ├── client-job-detail.php      # Job detail + proposals
│   │   ├── client-workers.php         # Browse workers
│   │   ├── client-messages.php
│   │   ├── client-payments.php
│   │   ├── client-disputes.php
│   │   └── client-settings.php
│   │
│   ├── worker/
│   │   ├── worker-overview.php        # Dashboard
│   │   ├── workerfind_jobs.php        # Browse jobs
│   │   ├── worker-bids.php            # My proposals
│   │   ├── worker_working.php         # Active job in progress
│   │   ├── worker-payments.php        # Earnings/payouts
│   │   ├── worker-portfolio.php
│   │   ├── worker-history.php         # Completed jobs
│   │   ├── worker-messages.php
│   │   ├── worker-disputes.php
│   │   ├── worker-settings.php
│   │   └── workersidebar.php          # Shared sidebar component
│   │
│   └── admin/
│       ├── admin-dashboard.php        # Platform overview
│       ├── admin-users.php            # User management
│       ├── admin-jobs.php             # Job moderation
│       ├── admin-ads.php              # Ad management
│       ├── admin-disputes.php
│       ├── admin-market-rules.php     # Commission rules
│       └── admin-settings.php
│
├── uploads/                           # User-uploaded files
│
├── jointu_schema_v9.sql               # DB schema v9
├── jointu_schema_v10.sql              # DB schema v10 (current)
│
└── docs/
    ├── CLAUDE.md                      # Dev instructions
    ├── CONTRIBUTING.md
    ├── CSS_REFACTORING_SUMMARY.md
    ├── JointU DATABASE FLOW GUIDE.docx
    └── JointUI.pdf
```

## API Routes Summary

| Area | Base Path |
|------|-----------|
| Auth | `api/auth/` |
| Users | `api/users/` |
| Jobs | `api/jobs/` |
| Proposals | `api/proposals/` |
| Payments | `api/payments/` |
| Admin | `api/admin/` |

## Page Access Matrix

| Page group | Auth required | Role |
|------------|--------------|------|
| `pages/public/` | No | Anyone |
| `pages/auth/` | No | Anyone |
| `pages/client/` | Yes | client / business |
| `pages/worker/` | Yes | worker |
| `pages/admin/` | Yes | admin |
