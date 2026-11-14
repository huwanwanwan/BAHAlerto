// The user requested visible motion. Offer an explicit pause control as well.
document.body.dataset.motion = 'on';
const reducedMotion = { get matches() { return document.body.dataset.motion === 'off'; } };
const motionButton = document.createElement('button');
motionButton.className = 'motion-toggle';
motionButton.type = 'button';
motionButton.textContent = 'Pause animations';
motionButton.setAttribute('aria-pressed', 'false');
document.body.append(motionButton);
motionButton.addEventListener('click', () => {
  const paused = document.body.dataset.motion !== 'off';
  document.body.dataset.motion = paused ? 'off' : 'on';
  motionButton.textContent = paused ? 'Play animations' : 'Pause animations';
  motionButton.setAttribute('aria-pressed', String(paused));
  requestUpdate();
});

if ('IntersectionObserver' in window) {
  document.body.classList.add('js');
  document.querySelectorAll('.benefits article, .resource').forEach((element, index) => {
    element.style.setProperty('--delay', `${index % 3 * 110}ms`);
  });
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      } else entry.target.classList.remove('visible');
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -25px 0px' });
  document.querySelectorAll('.reveal').forEach(element => observer.observe(element));
}

// Scroll drives the phone tilt and scene depth; floating elements move independently.
const scenes = [...document.querySelectorAll('[data-parallax]')];
let scheduled = false;
function updateScenes() {
  scenes.forEach(scene => {
    const rect = scene.getBoundingClientRect();
    if (rect.bottom < -100 || rect.top > window.innerHeight + 100) return;
    const position = Math.max(-1, Math.min(1, (window.innerHeight / 2 - rect.top - rect.height / 2) / window.innerHeight));
    scene.style.setProperty('--parallax', `${reducedMotion.matches ? 0 : position * 30}px`);
  });
  scheduled = false;
}
function requestUpdate() {
  if (!scheduled) { scheduled = true; requestAnimationFrame(updateScenes); }
}
window.addEventListener('scroll', requestUpdate, { passive: true });
window.addEventListener('resize', requestUpdate);
updateScenes();

const resources = document.querySelector('.resource-grid');
document.querySelectorAll('[data-slide]').forEach(button => {
  button.addEventListener('click', () => {
    const direction = Number(button.dataset.slide);
    if (resources.scrollWidth > resources.clientWidth + 1) {
      resources.scrollBy({ left: direction * (resources.firstElementChild.getBoundingClientRect().width + 25), behavior: reducedMotion.matches ? 'instant' : 'smooth' });
    } else if (direction > 0) resources.append(resources.firstElementChild);
    else resources.prepend(resources.lastElementChild);
  });
});
