/* Lightbox for screenshot grids.
   Progressive enhancement: every .shot is a plain link to the full image, so
   without this script (or before it loads) clicking one still opens it. */
(() => {
  const shots = Array.from(document.querySelectorAll('a.shot'));
  if (!shots.length) return;

  let box = null;
  let at = 0;
  let lastFocus = null;

  const srcOf = a => a.getAttribute('href');
  const capOf = a => a.dataset.caption || (a.querySelector('img') || {}).alt || '';

  function show(i) {
    at = (i + shots.length) % shots.length;
    const a = shots[at];
    box.querySelector('img').src = srcOf(a);
    box.querySelector('img').alt = capOf(a);
    box.querySelector('figcaption').textContent =
      (at + 1) + ' / ' + shots.length + (capOf(a) ? '  ·  ' + capOf(a) : '');
  }

  function close() {
    if (!box) return;
    box.remove();
    box = null;
    document.body.style.overflow = '';
    document.removeEventListener('keydown', onKey);
    if (lastFocus) lastFocus.focus();
  }

  function onKey(e) {
    if (e.key === 'Escape') close();
    else if (e.key === 'ArrowRight') show(at + 1);
    else if (e.key === 'ArrowLeft') show(at - 1);
  }

  function open(i) {
    lastFocus = document.activeElement;
    box = document.createElement('div');
    box.className = 'lb';
    box.setAttribute('role', 'dialog');
    box.setAttribute('aria-modal', 'true');
    box.setAttribute('aria-label', 'Screenshot viewer');
    box.innerHTML =
      '<button class="lb-close" type="button" aria-label="Close">✕</button>' +
      '<button class="lb-prev" type="button" aria-label="Previous">‹</button>' +
      '<button class="lb-next" type="button" aria-label="Next">›</button>' +
      '<figure><img alt=""><figcaption></figcaption></figure>';

    box.addEventListener('click', e => {
      if (e.target === box) close();                       // click the backdrop
    });
    box.querySelector('.lb-close').addEventListener('click', close);
    box.querySelector('.lb-prev').addEventListener('click', () => show(at - 1));
    box.querySelector('.lb-next').addEventListener('click', () => show(at + 1));

    document.body.appendChild(box);
    document.body.style.overflow = 'hidden';
    document.addEventListener('keydown', onKey);
    show(i);
    box.querySelector('.lb-close').focus();
  }

  shots.forEach((a, i) => {
    a.addEventListener('click', e => {
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return; // let it open normally
      e.preventDefault();
      open(i);
    });
  });
})();
