async function loadIndex() {
  const response = await fetch('content-index.json');
  if (!response.ok) throw new Error('Не удалось загрузить content-index.json');
  return response.json();
}

function detectRepoContext() {
  const host = window.location.hostname;
  const pathParts = window.location.pathname.split('/').filter(Boolean);

  const owner = host.endsWith('.github.io') ? host.replace('.github.io', '') : '<owner>';
  const repo = pathParts.length > 0 ? pathParts[0] : 'MZT';
  const branch = 'main';

  return { owner, repo, branch };
}

function githubUrls(ctx, filePath) {
  return {
    blob: `https://github.com/${ctx.owner}/${ctx.repo}/blob/${ctx.branch}/${filePath}`,
    raw: `https://raw.githubusercontent.com/${ctx.owner}/${ctx.repo}/${ctx.branch}/${filePath}`,
    repo: `https://github.com/${ctx.owner}/${ctx.repo}`,
  };
}

function renderCatalog(index, ctx) {
  const catalog = document.getElementById('catalog');
  const stats = document.getElementById('stats');
  const search = document.getElementById('search');

  const allItems = index.sections.flatMap((section) =>
    section.files.map((file) => ({ section: section.name, path: file }))
  );

  function render(filteredItems) {
    stats.textContent = `Показано файлов: ${filteredItems.length}`;

    const bySection = new Map();
    for (const item of filteredItems) {
      if (!bySection.has(item.section)) bySection.set(item.section, []);
      bySection.get(item.section).push(item.path);
    }

    catalog.innerHTML = '';
    for (const [sectionName, files] of bySection.entries()) {
      const section = document.createElement('article');
      section.className = 'section';
      section.innerHTML = `<div class="section-header">${sectionName} · ${files.length}</div>`;

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

      section.appendChild(ul);
      catalog.appendChild(section);
    }
  }

  render(allItems);

  search.addEventListener('input', (event) => {
    const term = event.target.value.trim().toLowerCase();
    if (!term) return render(allItems);

    const filtered = allItems.filter((item) =>
      item.path.toLowerCase().includes(term) || item.section.toLowerCase().includes(term)
    );
    render(filtered);
  });
}

async function init() {
  const ctx = detectRepoContext();
  const repoLink = document.getElementById('repo-link');
  const repoMeta = document.getElementById('repo-meta');

  const repoUrl = `https://github.com/${ctx.owner}/${ctx.repo}`;
  repoLink.href = repoUrl;
  repoMeta.textContent = `Репозиторий: ${ctx.owner}/${ctx.repo} · ветка: ${ctx.branch}`;

  try {
    const index = await loadIndex();
    renderCatalog(index, ctx);
  } catch (error) {
    repoMeta.textContent = `Ошибка: ${error.message}`;
  }
}

init();
