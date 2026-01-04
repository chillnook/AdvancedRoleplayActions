const root = document.getElementById('root');

/** @type {Map<number, HTMLElement>} */
const nodes = new Map();

function ensureNode(id) {
  let node = nodes.get(id);
  if (node) return node;

  node = document.createElement('div');
  node.className = 'bubble';

  const bg = document.createElement('div');
  bg.className = 'bubble__bg';
  node._bg = bg;

  const badge = document.createElement('img');
  badge.className = 'bubble__badge';
  badge.style.display = 'none';
  node._badge = badge;

  const label = document.createElement('div');
  label.className = 'bubble__label';
  label.style.display = 'none';
  node._label = label;

  const text = document.createElement('div');
  text.className = 'bubble__text';
  const name = document.createElement('div');
  name.className = 'bubble__name';

  node.appendChild(bg);
  node.appendChild(badge);
  node.appendChild(label);
  node.appendChild(name);
  node.appendChild(text);
  root.appendChild(node);

  nodes.set(id, node);
  return node;
}

function setNode(node, item) {
  const cx = (typeof item.x === 'number') ? Math.min(Math.max(item.x, 0.0), 1.0) : 0.5;
  const cy = (typeof item.y === 'number') ? Math.min(Math.max(item.y, 0.0), 1.0) : 0.5;

  if (typeof item.scale === 'number') {
    node.style.setProperty('--bubble-scale', String(item.scale));
  }
  if (typeof item.sizePx === 'number') {
    node.style.setProperty('--bubble-width', `${item.sizePx}px`);
    const h = Math.max(40, Math.round(item.sizePx * 0.18));
    node.style.setProperty('--bubble-height', `${h}px`);
    const fontSize = Math.max(16, Math.round(item.sizePx * 0.05));
    node.style.setProperty('--bubble-font-size', `${fontSize}px`);
  }

  const textNode = node.querySelector('.bubble__text');
  const nameNode = node.querySelector('.bubble__name');
  if (textNode) {
    textNode.textContent = item.text ?? '';
    if (Array.isArray(item.color) && item.color.length >= 3) {
      textNode.style.color = `rgb(${item.color[0]}, ${item.color[1]}, ${item.color[2]})`;
    }
  }
  if (nameNode) {
    nameNode.textContent = item.playerName ?? '';
  }

  node.classList.remove('bubble--me', 'bubble--do');
  if (item.actionType === 'me') node.classList.add('bubble--me');
  else if (item.actionType === 'do') node.classList.add('bubble--do');

  try {
    const bg = node._bg;
    if (bg && item.bg) {
      bg.style.setProperty('--bubble-bg', item.bg);
      bg.style.background = item.bg;
    }
  } catch (e) { /* ignore */ }

  node._offsetX = (typeof item.headOffsetX === 'number') ? item.headOffsetX : 0;
  node._verticalOffset = (typeof item.verticalOffsetPx === 'number') ? item.verticalOffsetPx : 10;
  try {
    const badge = node._badge;
    if (badge) {
      if (item.avatar) {
        badge.src = item.avatar;
        const bs = (typeof item.badgeSizePx === 'number') ? item.badgeSizePx : 40;
        badge.style.width = `${bs}px`;
        badge.style.height = `${bs}px`;
        badge.style.display = 'block';
      } else {
        badge.style.display = 'none';
      }
    }
  } catch (e) { }

  try {
    const label = node._label;
    if (label) {
      if (item.actionType === 'me' || item.actionType === 'do') {
        label.textContent = (item.actionType === 'me') ? 'ME' : 'DO';
        label.style.display = 'flex';
        const bs = (typeof item.badgeSizePx === 'number') ? item.badgeSizePx : 48;
        const ls = Math.max(24, Math.round(bs * 0.72));
        label.style.width = `${ls}px`;
        label.style.height = `${ls}px`;
        label.style.lineHeight = `${ls}px`;
        label.style.borderRadius = '50%';
        label.style.fontSize = `${Math.max(12, Math.round(ls * 0.42))}px`;
      } else {
        label.style.display = 'none';
      }
    }
  } catch (e) { }

  requestAnimationFrame(() => {
    const w = node.offsetWidth || parseInt(getComputedStyle(node).getPropertyValue('--bubble-width')) || 200;
    const h = node.offsetHeight || parseInt(getComputedStyle(node).getPropertyValue('--bubble-height')) || 48;

    const px = Math.round((cx * window.innerWidth) - (w / 2) + (node._offsetX || 0));
    const py = Math.round((cy * window.innerHeight) - h - (node._verticalOffset || 10));

    const lastX = (typeof node._lastX === 'number') ? node._lastX : px;
    const lastY = (typeof node._lastY === 'number') ? node._lastY : py;
    const lerp = 0.28;
    const nextX = Math.round(lastX + (px - lastX) * lerp);
    const nextY = Math.round(lastY + (py - lastY) * lerp);

    node.style.left = `${nextX}px`;
    node.style.top = `${nextY}px`;

    node._lastX = nextX;
    node._lastY = nextY;
  });
}

function prune(seen) {
  for (const [id, node] of nodes.entries()) {
    if (!seen.has(id)) {
      node.remove();
      nodes.delete(id);
    }
  }
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'actiontext:update') return;
  const items = Array.isArray(data.items) ? data.items : [];
  const opts = (data.options) ? data.options : null;

  if (opts && opts.indicatorEnabled) {
    document.documentElement.classList.toggle('indicator-glow', opts.indicatorStyle === 'glow');
    if (opts.indicatorMeColor && Array.isArray(opts.indicatorMeColor)) {
      document.documentElement.style.setProperty('--indicator-me-rgb', `${opts.indicatorMeColor[0]}, ${opts.indicatorMeColor[1]}, ${opts.indicatorMeColor[2]}`);
    }
    if (opts.indicatorDoColor && Array.isArray(opts.indicatorDoColor)) {
      document.documentElement.style.setProperty('--indicator-do-rgb', `${opts.indicatorDoColor[0]}, ${opts.indicatorDoColor[1]}, ${opts.indicatorDoColor[2]}`);
    }
    if (typeof opts.indicatorIntensity === 'number') {
      document.documentElement.style.setProperty('--indicator-intensity', String(opts.indicatorIntensity));
    }
  } else {
    document.documentElement.classList.remove('indicator-glow');
  }
  const seen = new Set();

  for (const item of items) {
    if (!item || typeof item.id !== 'number') continue;
    if (typeof item.x !== 'number' || typeof item.y !== 'number') continue;

    seen.add(item.id);
    const node = ensureNode(item.id);
    setNode(node, item);
  }

  prune(seen);
});