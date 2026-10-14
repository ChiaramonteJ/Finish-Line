// Navigation is present in HTML; JavaScript only enhances interaction.
document.addEventListener('DOMContentLoaded', function () {
  var nav = document.querySelector('.site-nav');
  if (!nav) return;
  var toggle = nav.querySelector('.menu-toggle');
  toggle.hidden = false;
  nav.classList.add('nav-enhanced');
  toggle.addEventListener('click', function () {
    var open = toggle.getAttribute('aria-expanded') !== 'true';
    toggle.setAttribute('aria-expanded', String(open));
    nav.classList.toggle('nav-open', open);
  });
  document.addEventListener('keydown', function (event) {
    if (event.key !== 'Escape') return;
    var dropdown = nav.querySelector('details[open]');
    if (dropdown) {
      dropdown.open = false;
      dropdown.querySelector('summary').focus();
    } else if (nav.classList.contains('nav-open')) {
      nav.classList.remove('nav-open');
      toggle.setAttribute('aria-expanded', 'false');
      toggle.focus();
    }
  });
  document.addEventListener('click', function (event) {
    nav.querySelectorAll('details[open]').forEach(function (item) {
      if (!item.contains(event.target)) item.open = false;
    });
  });
  nav.querySelectorAll('a').forEach(function (link) {
    if (link.pathname === window.location.pathname && !link.hash) link.setAttribute('aria-current', 'page');
  });
  var year = document.getElementById('footer-year');
  if (year) year.textContent = new Date().getFullYear();
});
