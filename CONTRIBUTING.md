# JointU — Contributor Guide

How to work on this project without breaking things.

---

## Prerequisites

- [Git](https://git-scm.com/downloads) installed
- Access granted to the repo (you received and accepted an invite)
- A GitHub account

---

## First-Time Setup

Clone the repo to your machine:

```bash
git clone https://github.com/jojo6550/jointu.git
cd jointu
```

Confirm your identity:

```bash
git config user.name "Your Name"
git config user.email "your@email.com"
```

---

## The Golden Rule

**Never push directly to `main`.** It is blocked. All changes go through a Pull Request (PR).

---

## Workflow: Step by Step

### 1. Sync with latest `main` before starting work

```bash
git checkout main
git pull origin main
```

Always start from an up-to-date `main`.

### 2. Create a new branch

Name your branch after what you're working on:

```bash
git checkout -b feature/your-feature-name
```

**Branch naming conventions:**

| Prefix | Use for |
|--------|---------|
| `feature/` | New feature or page |
| `fix/` | Bug fix |
| `update/` | Improving existing code |
| `style/` | UI/CSS only changes |

Examples:
```
feature/worker-dashboard
fix/login-redirect
update/job-card-layout
style/mobile-nav
```

### 3. Make your changes

Edit files, write code, save.

Check what you changed:
```bash
git status
git diff
```

### 4. Stage and commit your changes

Stage specific files (preferred):
```bash
git add pages/worker/worker-dashboard.html
git add css/style.css
```

Or stage everything changed:
```bash
git add .
```

Commit with a clear message:
```bash
git commit -m "feat: add worker dashboard overview page"
```

**Commit message format:**

```
type: short description of what changed
```

| Type | Use for |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `style` | Visual/CSS only |
| `update` | Enhancement to existing feature |
| `chore` | Config, cleanup, non-functional |

Keep it under 72 characters. Say what changed, not how.

### 5. Push your branch to GitHub

```bash
git push origin feature/your-feature-name
```

First time pushing this branch? Git may prompt you to set upstream — just run the command it suggests.

### 6. Open a Pull Request

1. Go to the repo on GitHub
2. You'll see a banner: **"Compare & pull request"** — click it
3. Fill in:
   - **Title**: what this PR does (e.g. `Add worker dashboard page`)
   - **Description**: what changed, why, anything reviewers should know
4. Click **Create pull request**

A lead will review it. You may get feedback — see below.

---

## Responding to Review Feedback

If a reviewer requests changes:

1. Read the comments on the PR
2. Make the fixes locally on the **same branch**
3. Commit and push again:
   ```bash
   git add .
   git commit -m "fix: address review feedback"
   git push origin feature/your-feature-name
   ```
4. The PR updates automatically — no need to open a new one

---

## After Your PR is Merged

Clean up your local branch:

```bash
git checkout main
git pull origin main
git branch -d feature/your-feature-name
```

Start fresh for your next task from step 1.

---

## Common Issues

**"Your branch is behind main"**
```bash
git checkout main
git pull origin main
git checkout feature/your-branch
git merge main
```
Resolve any conflicts, then push.

**Committed to `main` by accident**
```bash
git checkout -b feature/rescue-branch
git checkout main
git reset --hard origin/main
```
Your work is now on `feature/rescue-branch`.

**Forgot to pull before starting**
```bash
git fetch origin
git merge origin/main
```

---

## File Structure Reference

```
jointu/
├── api/          ← PHP backend (REST endpoints)
├── assets/       ← Images, icons
├── css/          ← Stylesheets
├── js/           ← JavaScript
├── pages/
│   ├── admin/    ← Admin pages
│   ├── auth/     ← Login, signup
│   ├── client/   ← Client-facing pages
│   └── worker/   ← Worker-facing pages
└── index.html    ← Landing page
```

Put files in the right folder. Don't create new top-level folders without checking with a lead.

---

## Questions?

Ask in the team chat or tag a project lead in your PR.
