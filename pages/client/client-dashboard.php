<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Client Dashboard — JointU</title>
<link rel="stylesheet" href="../../css/style.css">
<link href="https://fonts.googleapis.com/css2?family=Fraunces:wght@600;700&family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
<div class="app">

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="sidebar-logo"><a href="../../index.php" class="logo">Joint<span>U</span></a></div>
    <nav class="sidebar-nav">
      <a href="../client/client-dashboard.php" class="active"><span>◻</span> Overview</a>
      <a href="client-post.php"><span>➕</span> Post a Job</a>
      <a href="client-active-jobs.php"><span>📋</span> My Jobs</a>
      <a href="client-messages.php"><span>💬</span> Messages</a>
      <a href="client-payments.php"><span>💳</span> Payments</a>
      <a href="client-disputes.php"><span>⚠</span> Disputes</a>
      <a href="../client/client-settings.php"><span>⚙</span> Settings</a>
    </nav>
    <div class="sidebar-upgrade">
      <strong>Go Premium</strong>
      <p>Get priority visibility and top workers faster.</p>
      <a href="#" class="btn btn-mint btn-sm btn-full">Upgrade Plan</a>
    </div>
  </aside>

  <!-- MAIN -->
  <main class="app-main">
    <div class="app-header">
      <div class="app-header-title">
        <h2>Good morning, Sarah! 👋</h2>
        <p>Here's what's happening with your projects today.</p>
      </div>
      <div class="app-header-actions">
        <a href="client-post.php" class="btn btn-primary btn-sm">+ Post New Job</a>
      </div>
    </div>

    <div class="app-content-wide">

      <!-- STATS -->
      <div class="stats-grid mb-24">
        <div class="stat-card" data-animate>
          <div class="stat-icon stat-icon-ink">📋</div>
          <div class="stat-val">4</div>
          <div class="stat-label">Active Jobs</div>
          <div class="stat-delta up">↑ 2 new this week</div>
        </div>
        <div class="stat-card" data-animate>
          <div class="stat-icon stat-icon-mint">🔧</div>
          <div class="stat-val">23</div>
          <div class="stat-label">Total Bids Received</div>
          <div class="stat-delta up">↑ 8 new today</div>
        </div>
        <div class="stat-card" data-animate>
          <div class="stat-icon stat-icon-ink">💰</div>
          <div class="stat-val">$86k</div>
          <div class="stat-label">Total Spent (JMD)</div>
          <div class="stat-delta stable">This year</div>
        </div>
        <div class="stat-card" data-animate>
          <div class="stat-icon stat-icon-mint">⭐</div>
          <div class="stat-val">12</div>
          <div class="stat-label">Workers Hired</div>
          <div class="stat-delta stable">All time</div>
        </div>
      </div>

      <div class="d-grid grid-2col-wide">

        <!-- ACTIVE JOBS -->
        <div>
          <div class="card mb-20">
            <div class="card-header">
              <div><div class="card-title">Active Jobs</div><div class="card-sub">Your current postings and progress</div></div>
              <a href="client-active-jobs.php" class="btn btn-ghost btn-sm">View All</a>
            </div>
            <div class="d-flex flex-col gap-14">

              <!-- Job 1 -->
              <div class="card-light">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:10px">
                  <div>
                    <div style="font-size:.65rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--mint);margin-bottom:2px">ELECTRICAL</div>
                    <div class="text-lg-2-700">Full House Rewiring</div>
                    <div class="text-sm-muted">📍 Kingston · Posted 5h ago</div>
                  </div>
                  <span class="badge badge-amber">🔄 In Progress</span>
                </div>
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
                  <span style="font-size:.72rem;color:var(--muted)">Completion</span>
                  <span class="text-sm-2-muted-700">80%</span>
                </div>
                <div class="progress-track" class="mb-12"><div class="progress-fill" class="w-80"></div></div>
                <div style="display:flex;align-items:center;justify-content:space-between">
                  <div class="d-flex items-center gap-8">
                    <div class="avatar" style="width:28px;height:28px;font-size:.7rem">KW</div>
                    <span style="font-size:.8rem;font-weight:600">Keno W. · <span class="text-mint">★ 4.9</span></span>
                  </div>
                  <div class="d-flex gap-8">
                    <a href="client-messages.php" class="btn btn-ghost btn-sm">💬 Chat</a>
                    <button class="btn btn-primary btn-sm">Release Payment</button>
                  </div>
                </div>
              </div>

              <!-- Job 2 -->
              <div class="card-light">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:10px">
                  <div>
                    <div style="font-size:.65rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--mint);margin-bottom:2px">PLUMBING</div>
                    <div class="text-lg-2-700">Fix Leaking Garden Pipe</div>
                    <div class="text-sm-muted">📍 St. Andrew · Posted 2h ago</div>
                  </div>
                  <span class="badge badge-blue">📢 Accepting Bids</span>
                </div>
                <div style="font-size:.8rem;color:var(--muted);margin-bottom:12px">📋 <strong style="color:var(--ink)">3</strong> bids received so far</div>
                <div class="d-flex gap-8">
                  <a href="client-active-jobs.php" class="btn btn-primary btn-sm">Review Bids</a>
                  <button class="btn btn-ghost btn-sm">Edit Job</button>
                </div>
              </div>

              <!-- Job 3 -->
              <div class="card-light">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:10px">
                  <div>
                    <div style="font-size:.65rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--mint);margin-bottom:2px">GRAPHIC DESIGN</div>
                    <div class="text-lg-2-700">Logo & Brand Identity</div>
                    <div class="text-sm-muted">📍 St. James · Posted 1d ago</div>
                  </div>
                  <span class="badge badge-green">✓ Completed</span>
                </div>
                <div style="font-size:.8rem;color:var(--muted);margin-bottom:12px">Worker: Elena P. · JMD 45,000 paid</div>
                <div class="d-flex gap-8">
                  <button class="btn btn-ghost btn-sm">Leave Review</button>
                  <button class="btn btn-ghost btn-sm">View Work</button>
                </div>
              </div>

            </div>
          </div>

          <!-- BROWSE WORKERS -->
          <div class="card">
            <div class="card-header">
              <div><div class="card-title">Recommended Workers</div><div class="card-sub">Based on your recent jobs</div></div>
              <a href="client-workers.php" class="btn btn-ghost btn-sm">Browse All</a>
            </div>
            <div style="display:flex;flex-direction:column;gap:0">
              <div class="worker-row">
                <div class="avatar">MW</div>
                <div class="flex-1">
                  <div class="text-lg-700">Mikhail W.</div>
                  <div class="text-sm-muted">Electrical · St. Andrew · ★ 4.9</div>
                </div>
                <div class="d-flex items-center gap-8">
                  <span class="badge badge-green">Available</span>
                  <a href="#" class="btn btn-primary btn-sm">Invite</a>
                </div>
              </div>
              <div class="worker-row">
                <div class="avatar">DJ</div>
                <div class="flex-1">
                  <div class="text-lg-700">Dante J.</div>
                  <div class="text-sm-muted">Plumbing · Kingston · ★ 4.7</div>
                </div>
                <div class="d-flex items-center gap-8">
                  <span class="badge badge-green">Available</span>
                  <a href="#" class="btn btn-primary btn-sm">Invite</a>
                </div>
              </div>
              <div class="worker-row">
                <div class="avatar">KW</div>
                <div class="flex-1">
                  <div class="text-lg-700">Keneisha W.</div>
                  <div class="text-sm-muted">Domestic · St. James · ★ 4.6</div>
                </div>
                <div class="d-flex items-center gap-8">
                  <span class="badge badge-amber">Busy</span>
                  <a href="#" class="btn btn-ghost btn-sm">View</a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- RIGHT COLUMN -->
        <div style="display:flex;flex-direction:column;gap:16px">

          <!-- Recent Activity -->
          <div class="card">
            <div class="card-header"><div class="card-title">Recent Activity</div></div>
            <div style="display:flex;flex-direction:column;gap:10px">
              <div class="alert alert-success" class="text-sm-2">Keno W. marked "Rewiring" 80% complete.</div>
              <div class="alert alert-info" class="text-sm-2">3 new bids on "Garden Pipe" job.</div>
              <div class="alert alert-warn" class="text-sm-2">Payment reminder: "Logo Design" balance due.</div>
              <div class="alert alert-error" class="text-sm-2">Dispute opened on "AC Repair" job.</div>
            </div>
          </div>

          <!-- Spending Summary -->
          <div class="card">
            <div class="card-header"><div class="card-title">Spending This Month</div></div>
            <div style="display:flex;flex-direction:column;gap:12px">
              <div>
                <div class="flex-sb-mb-4">
                  <span style="font-size:.8rem;color:var(--muted)">Electrical</span>
                  <span class="text-sm-2-muted-700">JMD 80,000</span>
                </div>
                <div class="progress-track"><div class="progress-fill" class="w-80"></div></div>
              </div>
              <div>
                <div class="flex-sb-mb-4">
                  <span style="font-size:.8rem;color:var(--muted)">Design</span>
                  <span class="text-sm-2-muted-700">JMD 45,000</span>
                </div>
                <div class="progress-track"><div class="progress-fill" style="width:45%"></div></div>
              </div>
              <div>
                <div class="flex-sb-mb-4">
                  <span style="font-size:.8rem;color:var(--muted)">Plumbing</span>
                  <span class="text-sm-2-muted-700">JMD 6,500</span>
                </div>
                <div class="progress-track"><div class="progress-fill" style="width:7%"></div></div>
              </div>
              <div style="border-top:1px solid var(--border);padding-top:10px;display:flex;justify-content:space-between">
                <span style="font-size:.85rem;font-weight:600">Total</span>
                <span style="font-size:.95rem;font-weight:800">JMD 131,500</span>
              </div>
            </div>
          </div>

          <!-- Quick Post Job -->
          <div style="background:var(--ink);border-radius:var(--r-lg);padding:20px">
            <div style="font-weight:700;color:var(--white);margin-bottom:6px">🚀 Need something done?</div>
            <div style="font-size:.82rem;color:rgba(255,255,255,.55);margin-bottom:14px">Post a job and get bids from local professionals within hours.</div>
            <a href="client-post.php" class="btn btn-mint btn-full btn-sm">Post a Job Now</a>
          </div>

        </div>
      </div>

    </div>
  </main>
</div>
<script src="../../js/main.js"></script>
</body>
</html>






