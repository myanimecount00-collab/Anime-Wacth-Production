const COLORS = ['c1','c2','c3','c4','c5','c6'];

function buildCard(anime, idx = 0) {
  const colorClass = COLORS[idx % COLORS.length];
  const imgHtml = anime.thumb
    ? `<img src="${anime.thumb}" alt="${escHtml(anime.title)}" loading="lazy"
          onerror="this.replaceWith(Object.assign(document.createElement('div'), {className:'card-thumb-fallback ${colorClass}', innerHTML:'🎬'}))" />`
    : `<div class="card-thumb-fallback ${colorClass}">🎬</div>`;

  return `
    <a href="anime.html?url=${encodeURIComponent(anime.link)}" class="anime-card">
      <div class="card-thumb">
        ${imgHtml}
        <div class="card-badges">
          <span class="card-ep-badge">${escHtml(anime.ep || '???')}</span>
          ${anime.isNew ? '<span class="card-status-new">Baru</span>' : ''}
        </div>
      </div>
      <div class="card-body">
        <div class="card-title">${escHtml(anime.title)}</div>
        <div class="card-footer">
          <span class="card-genre">${escHtml(anime.genre || '')}</span>
          ${anime.score ? `<span class="card-score">★ ${anime.score}</span>` : ''}
        </div>
      </div>
    </a>`;
}

function escHtml(str) {
  if (!str) return '';
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}