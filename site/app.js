const THEME_KEY = 'mzt-theme';

async function loadIndex() {
  const response = await fetch('content-index.json');
  if (!response.ok) throw new Error('Не удалось загрузить content-index.json');
  return response.json();
}

function detectRepoContext() {
  const host = window.location.hostname;
  const pathParts = window.location.pathname.split('/').filter(Boolean);
  const owner = host.endsWith('.github.io') ? host.replace('.github.io', '') : '<owner>';
  const repo = pathParts[0] || 'MZT';
  return { owner, repo, branch: 'main' };
}

function githubUrls(ctx, filePath) {
  return {
    blob: `https://github.com/${ctx.owner}/${ctx.repo}/blob/${ctx.branch}/${filePath}`,
    raw: `https://raw.githubusercontent.com/${ctx.owner}/${ctx.repo}/${ctx.branch}/${filePath}`,
  };
}

function sectionId(name) {
  return `section-${name.toLowerCase().replace(/[^a-zа-я0-9]+/gi, '-')}`;
}

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem(THEME_KEY, theme);
  const button = document.getElementById('theme-toggle');
  if (!button) return;
  button.textContent = theme === 'dark' ? '☀️ Светлая' : '🌙 Тёмная';
}

function initTheme() {
  const saved = localStorage.getItem(THEME_KEY);
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  const initial = saved || (prefersDark ? 'dark' : 'light');

  applyTheme(initial);

  const button = document.getElementById('theme-toggle');
  if (!button) return;
  button.addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme') || 'light';
    applyTheme(current === 'dark' ? 'light' : 'dark');
  });
}

function renderMenu(sections) {
  const menu = document.getElementById('menu');
  menu.innerHTML = '';

  sections.forEach((section) => {
    const a = document.createElement('a');
    a.href = `#${sectionId(section.name)}`;
    a.textContent = `${section.name} (${section.files.length})`;
    menu.appendChild(a);
  });
}

function renderCatalog(index, ctx) {
  const catalog = document.getElementById('catalog');
  const stats = document.getElementById('stats');
  const search = document.getElementById('search');

  const allItems = index.sections.flatMap((section) =>
    section.files.map((path) => ({ section: section.name, path }))
  );

  function draw(items) {
    stats.textContent = `Найдено файлов: ${items.length}`;
    const grouped = new Map();
    items.forEach((item) => {
      if (!grouped.has(item.section)) grouped.set(item.section, []);
      grouped.get(item.section).push(item.path);
    });

    catalog.innerHTML = '';
    for (const section of index.sections) {
      const files = grouped.get(section.name);
      if (!files || files.length === 0) continue;

      const article = document.createElement('article');
      article.className = 'section';
      article.id = sectionId(section.name);
      article.innerHTML = `<div class="section-header">${section.name} · ${files.length}</div>`;

      const ul = document.createElement('ul');
      ul.className = 'file-list';

      files.forEach((filePath) => {
        const urls = githubUrls(ctx, filePath);
        const li = document.createElement('li');
        li.className = 'file-item';
        li.innerHTML = `
          <span class="file-name">${filePath}</span>
          <span class="file-links">
            <a href="${urls.blob}" target="_blank" rel="noopener">GitHub</a>
            <a href="${urls.raw}" target="_blank" rel="noopener">Raw</a>
          </span>
        `;
        ul.appendChild(li);
      });

      article.appendChild(ul);
      catalog.appendChild(article);
    }
  }

  draw(allItems);

  search.addEventListener('input', (event) => {
    const term = event.target.value.trim().toLowerCase();
    if (!term) return draw(allItems);

    const filtered = allItems.filter((item) =>
      item.path.toLowerCase().includes(term) || item.section.toLowerCase().includes(term)
    );
    draw(filtered);
  });
}

async function init() {
  initTheme();

  const ctx = detectRepoContext();
  const repoLink = document.getElementById('repo-link');
  const repoMeta = document.getElementById('repo-meta');
  const repoUrl = `https://github.com/${ctx.owner}/${ctx.repo}`;

  repoLink.href = repoUrl;
  repoMeta.textContent = `Репозиторий: ${ctx.owner}/${ctx.repo} · Ветка: ${ctx.branch}`;

  try {
    const index = await loadIndex();
    renderMenu(index.sections);
    renderCatalog(index, ctx);
  } catch (error) {
    repoMeta.textContent = `Ошибка: ${error.message}`;
  }
}

init();
