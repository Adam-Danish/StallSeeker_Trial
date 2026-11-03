const toggle = document.querySelector('.nav-toggle');
const navigation = document.querySelector('#site-nav');
function closeNavigation() {
  toggle.setAttribute('aria-expanded', 'false');
  toggle.setAttribute('aria-label', 'Open navigation');
  navigation.classList.remove('is-open');
}
toggle.addEventListener('click', () => {
  const open = toggle.getAttribute('aria-expanded') !== 'true';
  toggle.setAttribute('aria-expanded', String(open));
  toggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
  navigation.classList.toggle('is-open', open);
});
navigation.querySelectorAll('a').forEach(link => link.addEventListener('click', closeNavigation));
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
    closeNavigation(); toggle.focus();
  }
});
const previews = {
  discover: { image: 'assets/nearby-map.png', alt: "Map view showing nearby stalls and a stall's opening status", caption: 'Discover what’s around you.' },
  check: { image: 'assets/stall-details.png', alt: 'Stall details showing opening hours, menu, and last known location', caption: 'Check the details before heading out.' },
  collect: { image: 'assets/stall-details.png', alt: 'Stall details with the Self-collect booking entry point', caption: 'Choose Self-collect to start a booking request.' }
};
const tabs = [...document.querySelectorAll('[role="tab"]')];
function activateTab(tab) {
  for (const item of tabs) {
    const selected = item === tab;
    item.setAttribute('aria-selected', String(selected));
    item.tabIndex = selected ? 0 : -1;
    item.classList.toggle('active', selected);
  }
  const data = previews[tab.dataset.preview];
  const image = document.querySelector('#preview-image');
  image.src = data.image;
  image.alt = data.alt;
  document.querySelector('#preview-caption').textContent = data.caption;
  document.querySelector('#preview-panel').setAttribute('aria-labelledby', tab.id);
}
tabs.forEach((tab, index) => {
  tab.addEventListener('click', () => activateTab(tab));
  tab.addEventListener('keydown', event => {
    let next;
    if (event.key === 'ArrowDown') next = (index + 1) % tabs.length;
    if (event.key === 'ArrowUp') next = (index - 1 + tabs.length) % tabs.length;
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = tabs.length - 1;
    if (next !== undefined) { event.preventDefault(); activateTab(tabs[next]); tabs[next].focus(); }
  });
});
document.querySelector('#year').textContent = new Date().getFullYear();
