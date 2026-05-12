<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Ad Inventory — JointU Admin</title>
<link rel="stylesheet" href="../../css/style.css">
<style>
.ad-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin-top:20px}
.ad-card{background:var(--white);border:1px solid var(--border);border-radius:var(--r-lg);padding:20px;display:flex;flex-direction:column;gap:14px;transition:box-shadow var(--t)}
.ad-card:hover{box-shadow:var(--sh-md)}
.ad-preview{background:var(--surface);border:1.5px dashed var(--border);border-radius:var(--r);height:100px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;color:var(--light);font-size:.75rem}
.ad-preview svg{color:var(--border)}
.ad-title{font-weight:700;font-size:.9rem}
.ad-target{font-size:.75rem;color:var(--muted)}
.ad-stats{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.ad-stat-item{display:flex;flex-direction:column;gap:2px}
.ad-stat-label{font-size:.65rem;text-transform:uppercase;letter-spacing:.1em;color:var(--muted);font-weight:700}
.ad-stat-val{font-size:1.1rem;font-weight:700}
.ad-footer{display:flex;align-items:center;justify-content:space-between}
.ad-new{border:1.5px dashed var(--border);border-radius:var(--r-lg);height:100%;min-height:200px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;cursor:pointer;transition:border-color var(--t),background var(--t)}
.ad-new:hover{border-color:var(--mint);background:var(--mint-tint)}
.ad-new-plus{width:44px;height:44px;border-radius:50%;border:1.5px dashed var(--border);display:flex;align-items:center;justify-content:center;font-size:1.4rem;color:var(--muted)}
.ad-new:hover .ad-new-plus{border-color:var(--mint);color:var(--mint)}
.ad-new span{font-size:.82rem;color:var(--muted)}
.ad-active-dot{width:8px;height:8px;border-radius:50%;background:var(--mint);display:inline-block;margin-right:4px}
</style>
</head>
<body>
<div class="app">
  <aside class="sidebar" id="sidebar">
    <div class="sidebar-logo"><a href="../../index.php" class="logo">Joint<span>U</span></a></div>
    <div class="sidebar-item">
      <span class="badge badge-ink" class="d-flex btn-center">SYSTEM CONSOLE</span>
    </div>
    <nav class="sidebar-nav" class="p-8-0">
      <a href="../admin/admin-dashboard.php" class="sidebar-link"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>Stats Overview</a>
      <a href="../admin/admin-users.php" class="sidebar-link"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>Manage Users</a>
      <a href="../admin/admin-jobs.php" class="sidebar-link"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>Jobs &amp; Proposals</a>
      <a href="../admin/admin-disputes.php" class="sidebar-link"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/></svg>Dispute Center</a>
      <a href="../admin/admin-ads.php" class="sidebar-link active"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>Ad Inventory</a>
      <a href="../admin/admin-market-rules.php" class="sidebar-link"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/></svg>Market Rules</a>
      <a href="../admin/admin-settings.php" class="sidebar-link"><svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>System Settings</a>
    </nav>
  </aside>

  <main class="app-main">
    <div class="app-content">
      <div style="display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:4px;flex-wrap:wrap;gap:12px">
        <div>
          <h2 class="text-2xl-700">Advertisement Module</h2>
          <p class="muted" class="text-base">Horizontal rotating banners for footer inventory.</p>
        </div>
        <button class="btn btn-primary btn-sm">
          <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>Add New Ad
        </button>
      </div>

      <div class="ad-grid">
        <!-- Ad 1 -->
        <div class="ad-card">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <span class="label-muted">BANNER #1 PREVIEW</span>
            <span style="font-size:.72rem;font-weight:700;color:var(--mint-dim)"><span class="ad-active-dot"></span>ACTIVE</span>
          </div>
          <div class="ad-preview">
            <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/></svg>
            Banner Preview
          </div>
          <div>
            <div class="ad-title">Digicel Home Fibre – Q4 Campaign</div>
            <div class="ad-target">Target: https://digicelgroup.com</div>
          </div>
          <div class="ad-stats">
            <div class="ad-stat-item">
              <span class="ad-stat-label">⊙ Impressions</span>
              <span class="ad-stat-val">12,402</span>
            </div>
            <div class="ad-stat-item">
              <span class="ad-stat-label">↗ Clicks</span>
              <span class="ad-stat-val">842</span>
            </div>
          </div>
          <div class="ad-footer">
            <button class="btn btn-ghost btn-sm">Edit Schedule</button>
            <button class="btn btn-danger btn-sm" style="border:none;padding:6px 10px">
              <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/></svg>
            </button>
          </div>
        </div>

        <!-- Ad 2 -->
        <div class="ad-card">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <span class="label-muted">BANNER #2 PREVIEW</span>
            <span style="font-size:.72rem;font-weight:700;color:var(--mint-dim)"><span class="ad-active-dot"></span>ACTIVE</span>
          </div>
          <div class="ad-preview">
            <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/></svg>
            Banner Preview
          </div>
          <div>
            <div class="ad-title">Digicel Home Fibre – Q4 Campaign</div>
            <div class="ad-target">Target: https://digicelgroup.com</div>
          </div>
          <div class="ad-stats">
            <div class="ad-stat-item">
              <span class="ad-stat-label">⊙ Impressions</span>
              <span class="ad-stat-val">12,402</span>
            </div>
            <div class="ad-stat-item">
              <span class="ad-stat-label">↗ Clicks</span>
              <span class="ad-stat-val">842</span>
            </div>
          </div>
          <div class="ad-footer">
            <button class="btn btn-ghost btn-sm">Edit Schedule</button>
            <button class="btn btn-danger btn-sm" style="border:none;padding:6px 10px">
              <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/></svg>
            </button>
          </div>
        </div>

        <!-- Add New -->
        <div class="ad-new">
          <div class="ad-new-plus">+</div>
          <span>Configure New Advertisement</span>
        </div>
      </div>
    </div>
  </main>
</div>
</body>
</html>






