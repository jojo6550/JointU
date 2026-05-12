/* ═══════════════════════════════════════════════
   JOINTU — MAIN.JS
   Smooth transitions + Nav + Modals + FAQ + Animations
═══════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', () => {

  /* ── SMOOTH PAGE TRANSITIONS ─────────────── */
  document.querySelectorAll('a[href]').forEach(link => {
    const href = link.getAttribute('href');
    // Only transition same-page .php links, skip anchors/modals/external
    if (!href || href.startsWith('#') || href.startsWith('http') || href.startsWith('mailto')) return;
    if (!href.endsWith('.php')) return;

    link.addEventListener('click', function(e) {
      e.preventDefault();
      const target = this.getAttribute('href');
      document.body.classList.add('page-exit');
      setTimeout(() => { window.location.href = target; }, 200);
    });
  });

  /* ── STICKY NAV ──────────────────────────── */
  const nav = document.getElementById('nav');
  if (nav) {
    window.addEventListener('scroll', () => {
      nav.classList.toggle('scrolled', window.scrollY > 20);
    }, { passive: true });
  }

  /* ── BURGER MENU ─────────────────────────── */
  const burger = document.getElementById('burger');
  const navLinks = document.getElementById('navLinks');

  if (burger && navLinks) {
    burger.addEventListener('click', () => {
      const isOpen = navLinks.classList.toggle('open');
      burger.setAttribute('aria-expanded', isOpen);
      const spans = burger.querySelectorAll('span');
      if (isOpen) {
        spans[0].style.cssText = 'transform: translateY(7px) rotate(45deg)';
        spans[1].style.cssText = 'opacity: 0; transform: scaleX(0)';
        spans[2].style.cssText = 'transform: translateY(-7px) rotate(-45deg)';
      } else {
        spans.forEach(s => s.style.cssText = '');
      }
    });
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('open');
        burger.querySelectorAll('span').forEach(s => s.style.cssText = '');
      });
    });
  }

  /* ── MODAL SYSTEM ────────────────────────── */
  const loginModal  = document.getElementById('loginModal');
  const signupModal = document.getElementById('signupModal');

  function openModal(modal) {
    if (!modal) return;
    document.querySelectorAll('.modal-overlay.active').forEach(m => m.classList.remove('active'));
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
  function closeModal(modal) {
    if (!modal) return;
    modal.classList.remove('active');
    document.body.style.overflow = '';
  }
  function closeAllModals() {
    document.querySelectorAll('.modal-overlay').forEach(m => m.classList.remove('active'));
    document.body.style.overflow = '';
  }

  document.querySelectorAll('a[href="#login"]').forEach(el => {
    el.addEventListener('click', e => { e.preventDefault(); openModal(loginModal); });
  });
  document.querySelectorAll('a[href="#signup"]').forEach(el => {
    el.addEventListener('click', e => { e.preventDefault(); openModal(signupModal); });
  });

  const closeLogin  = document.getElementById('closeLogin');
  const closeSignup = document.getElementById('closeSignup');
  const goToSignup  = document.getElementById('goToSignup');
  const goToLogin   = document.getElementById('goToLogin');

  if (closeLogin)  closeLogin.addEventListener('click',  () => closeModal(loginModal));
  if (closeSignup) closeSignup.addEventListener('click', () => closeModal(signupModal));
  if (goToSignup)  goToSignup.addEventListener('click',  e => { e.preventDefault(); openModal(signupModal); });
  if (goToLogin)   goToLogin.addEventListener('click',   e => { e.preventDefault(); openModal(loginModal); });

  [loginModal, signupModal].forEach(modal => {
    if (!modal) return;
    modal.addEventListener('click', e => { if (e.target === modal) closeModal(modal); });
  });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') closeAllModals(); });

  /* ── SIGNUP TABS (modal + pages) ─────────── */
  document.querySelectorAll('[data-tab-panels]').forEach(container => {
    const tabs = container.closest('.auth-card, .modal-card')?.querySelectorAll('.tab') ||
                 document.querySelectorAll('.tab');
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        const targetPanel = tab.getAttribute('data-tab');
        if (targetPanel) {
          document.querySelectorAll('[data-panel]').forEach(p => p.style.display = 'none');
          const panel = document.getElementById(targetPanel);
          if (panel) panel.style.display = '';
        }
      });
    });
  });

  // Simple tab toggle fallback
  document.querySelectorAll('.tab-group .tab, .tabs .tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const group = tab.closest('.tab-group, .tabs');
      if (group) group.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
    });
  });

  /* ── FAQ ACCORDION ───────────────────────── */
  document.querySelectorAll('.faq-q').forEach(btn => {
    btn.addEventListener('click', () => {
      const expanded = btn.getAttribute('aria-expanded') === 'true';
      document.querySelectorAll('.faq-q[aria-expanded="true"]').forEach(other => {
        if (other !== btn) {
          other.setAttribute('aria-expanded', 'false');
          other.nextElementSibling?.classList.remove('open');
        }
      });
      btn.setAttribute('aria-expanded', !expanded);
      btn.nextElementSibling?.classList.toggle('open', !expanded);
    });
  });

  /* ── SCROLL ANIMATIONS ───────────────────── */
  const animEls = document.querySelectorAll('[data-animate], [data-anim], .faq-item, .job-card, .prof-card, .pricing-card, .how-card, .stat-card');
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible', 'in');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });
  animEls.forEach(el => observer.observe(el));

  /* ── SEARCH FILTER ───────────────────────── */
  const searchInput = document.querySelector('.browse-search input');
  if (searchInput) {
    searchInput.addEventListener('input', () => {
      const query = searchInput.value.toLowerCase().trim();
      document.querySelectorAll('.job-card').forEach(card => {
        card.style.display = !query || card.textContent.toLowerCase().includes(query) ? '' : 'none';
      });
    });
  }

  /* ── SMOOTH ANCHOR SCROLL ────────────────── */
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      const href = this.getAttribute('href');
      if (href === '#login' || href === '#signup') return;
      const target = document.querySelector(href);
      if (target) {
        e.preventDefault();
        const top = target.getBoundingClientRect().top + window.scrollY - 80;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

  /* ── POST JOB BUTTON → SIGNUP ────────────── */
  document.querySelectorAll('.btn').forEach(btn => {
    const text = btn.textContent.trim().toLowerCase();
    if (text.includes('post a job') || text.includes('post job')) {
      btn.addEventListener('click', e => { e.preventDefault(); openModal(signupModal); });
    }
  });

  /* ── SIDEBAR MOBILE TOGGLE ───────────────── */
  const sidebarToggle = document.getElementById('sidebarToggle');
  const sidebar = document.querySelector('.sidebar');
  if (sidebarToggle && sidebar) {
    sidebarToggle.addEventListener('click', () => sidebar.classList.toggle('open'));
  }

  /* ── MARK AS COMPLETE BUTTON ─────────────── */
  document.querySelectorAll('.btn-mark-complete').forEach(btn => {
    btn.addEventListener('click', () => {
      btn.textContent = '✓ Marked Complete';
      btn.disabled = true;
      btn.style.opacity = '.6';
    });
  });

});
