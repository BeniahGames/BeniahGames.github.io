/* Prompt + router for the static terminal pages (games, devlogs, privacy, 404).
   The home page has its own in-page engine; this one navigates between URLs. */
(() => {
  const input = document.getElementById('cmdline');
  const out = document.getElementById('nav-out');
  const screen = document.querySelector('.screen');
  const root = document.body.dataset.root || './';

  const say = (text, cls = 'l') => {
    if (!out) return;
    const p = document.createElement('p');
    p.className = cls;
    p.textContent = text;
    out.appendChild(p);
    out.scrollTop = out.scrollHeight;
  };

  const go = url => { say('> opening ' + url + ' ...', 'l ok'); location.href = url; };
  const ROUTES = {
    HOME: () => go(root),
    ABOUT: () => go(root + '#about'),
    CONTACT: () => go(root + '#contact'),
    FAQ: () => go(root + '#faq'),
    PROJECTS: () => go(root + 'games/'),
    GAMES: () => go(root + 'games/'),
    'ALL GAMES': () => go(root + 'games/'),
    DEVLOG: () => go(root + 'devlogs/'),
    DEVLOGS: () => go(root + 'devlogs/'),
    PRIVACY: () => go(root + 'privacy/'),
    DISCORD: () => { say('> opening discord ...', 'l ok'); window.open('https://discord.gg/PW6UZWtZ7C', '_blank', 'noopener'); },
    BACK: () => history.back(),
    HELP: () => say('HOME  ABOUT  PROJECTS  DEVLOG  FAQ  CONTACT  PRIVACY  DISCORD  BACK', 'l dim'),
  };

  function run(raw) {
    const cmd = String(raw || '').trim().toUpperCase();
    if (!cmd) return;
    const fn = ROUTES[cmd];
    if (fn) return fn();
    say('command not found: ' + cmd + ' — type HELP', 'l err');
  }

  document.querySelectorAll('[data-cmd]').forEach(b =>
    b.addEventListener('click', () => run(b.dataset.cmd)));

  if (input) {
    input.addEventListener('keydown', e => {
      if (e.key !== 'Enter') return;
      const v = input.value;
      input.value = '';
      run(v);
    });
    if (screen) screen.addEventListener('click', e => {
      if (e.target.closest('button, a, input, textarea, summary, details')) return;
      input.focus();
    });
  }

  // hamburger-free: the bar links are plain anchors, nothing else to wire
})();
