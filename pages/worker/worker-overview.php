<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Overview — JointU Worker</title>
<link rel="stylesheet" href="../../css/style.css">
<link href="https://fonts.googleapis.com/css2?family=Fraunces:wght@600;700&family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
<div class="app">
  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="sidebar-logo"><a href="../../index.php" class="logo">Joint<span>U</span></a></div>
    <div class="connects-bar">
      <div class="connects-label">Connects <span>18 / 20</span></div>
      <div class="connects-track"><div class="connects-fill"></div></div>
      <a class="connects-more" href="#">+ Get More Bids</a>
    </div>
    <nav class="sidebar-nav">
      <a href="../worker/worker-overview.php" class="active"><span>◻</span> Overview</a>
      <a href="../worker/workerfind_jobs.php"><span>⌕</span> Find Jobs</a>
      <a href="../worker/worker-bids.php"><span>📄</span> My Bids</a>
      <a href="../worker/worker_working.php"><span>🏗</span> Working On</a>
      <a href="../worker/worker-history.php"><span>📋</span> History</a>
      <a href="../worker/worker-portfolio.php"><span>🖼</span> Portfolio</a>
      <a href="../worker/worker-messages.php"><span>💬</span> Messages</a>
      <a href="../worker/worker-payments.php"><span>💰</span> Payments</a>
      <a href="../worker/worker-disputes.php"><span>⚠</span> Disputes</a>
      <a href="../worker/worker-settings.php"><span>⚙</span> Settings</a>
    </nav>
  </aside>

  <!-- MAIN -->
  <main class="app-main">
    <div class="app-header">
      <div class="app-header-title">
        <h2>Mawnin', Keno! 👋</h2>
        <p>Ready to find your next project in St. Andrew?</p>
      </div>
      <div class="app-header-actions">
        <a href="../worker/workerfind_jobs.php" class="btn btn-primary btn-sm">Browse New Jobs</a>
      </div>
    </div>
    <div class="app-content-wide">
      <!-- STATS -->
      <div class="stats-grid mb-24">
        <div class="stat-card">
          <div class="stat-icon stat-icon-ink">⚡</div>
          <div class="stat-val">18</div>
          <div class="stat-label">Connects Left</div>
          <div class="stat-delta stable">of 20</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon stat-icon-mint">📈</div>
          <div class="stat-val">98%</div>
          <div class="stat-label">Success Rate</div>
          <div class="stat-delta up">↑ High Match</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon stat-icon-ink">💰</div>
          <div class="stat-val">$124k</div>
          <div class="stat-label">Total Earned</div>
          <div class="stat-delta up">↑ JMD Total</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon stat-icon-mint">⭐</div>
          <div class="stat-val">4.9</div>
          <div class="stat-label">Reviews</div>
          <div class="stat-delta stable">124 ratings</div>
        </div>
      </div>

      <div class="d-grid grid-2col-wide">
        <!-- Active jobs -->
        <div class="card">
          <div class="card-header">
            <div><div class="card-title">Active Working Jobs</div></div>
            <a href="../worker/worker_working.php" class="btn btn-ghost btn-sm">View All</a>
          </div>
          <div class="d-flex flex-col gap-14">
            <div class="job-item">
              <div class="job-item-info">
                <div class="job-item-icon">🏗</div>
                <div><div class="job-item-title">Office Full Rewiring</div><div class="job-item-sub">Client: Jason R.</div></div>
              </div>
              <div class="job-item-status"><div class="job-item-status-main" class="text-mint">80% Complete</div><div class="job-item-status-sub">⏱ In 3 days</div></div>
            </div>
            <div class="job-item">
              <div class="job-item-info">
                <div class="job-item-icon">🔧</div>
                <div><div class="job-item-title">Fix Leaking Garden Pipe</div><div class="job-item-sub">Client: Alicia S.</div></div>
              </div>
              <div class="job-item-status"><div class="job-item-status-main">Just Started</div><div class="job-item-status-sub">⏱ Tomorrow</div></div>
            </div>
          </div>
        </div>

        <!-- Recent activity -->
        <div class="card">
          <div class="card-header"><div class="card-title">Recent Activity</div></div>
          <div class="d-flex flex-col gap-10">
            <div class="alert alert-error" class="text-sm-2">Your bid on "AC Clean" was rejected.</div>
            <div class="alert alert-success" class="text-sm-2">Client marked "Garden Pipe" as PAID.</div>
            <div class="alert alert-info" class="text-sm-2">New message from Alicia S.</div>
          </div>
          <div class="card mt-10 bg-off-white" style="border:1px solid var(--border)">
            <div class="text-muted mb-4 fw-600" class="text-sm-2">Trust Score</div>
            <p class="text-muted mb-10" class="text-sm-2">Complete your verification to appear higher in client searches.</p>
            <a href="../worker/worker-settings.php" class="btn btn-primary btn-sm btn-full">Verify ID Now</a>
          </div>
        </div>
      </div>

      <!-- New job alert banner -->
      <div class="bg-ink rounded-lg p-18 d-flex flex-wrap mt-20" style="align-items:center;justify-content:space-between;gap:16px">
        <div>
          <div class="text-white fw-700">🚨 New Job Alert!</div>
          <div style="font-size:.85rem;color:rgba(255,255,255,.6)">Plumbing repair needed at St. Andrew Park — JMD 15k</div>
        </div>
        <a href="../worker/workerfind_jobs.php" class="btn btn-mint btn-sm">View Job</a>
      </div>
    </div>
  </main>
</div>
<script src="../../js/main.js"></script>
</body>
</html>





