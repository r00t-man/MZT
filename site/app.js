const DATA_PATH = 'data/content.json';

async function loadContentMap() {
  const response = await fetch(DATA_PATH);
  if (!response.ok) throw new Error('Не удалось загрузить карту контента');
  return response.json();
}

function getQueryParam(name) {
  const params = new URLSearchParams(window.location.search);
  return params.get(name);
}

function buildTopNav(data) {
  const nav = document.getElementById('top-nav');
  const page = document.body.dataset.page;

  const links = [
    `<a class="nav-link ${page === 'home' ? 'active' : ''}" href="index.html">Главная</a>`,
    ...data.sections.map((section) =>
      `<a class="nav-link ${page === 'section' && getQueryParam('section') === section.id ? 'active' : ''}" href="section.html?section=${encodeURIComponent(section.id)}">${section.title}</a>`
    )
  ].join('');

  nav.innerHTML = `
    <div class="nav-wrap container">
      <div class="brand">MZT Docs</div>
      <nav class="nav-strip">${links}</nav>
    </div>
  `;
}

async function loadMarkdown(path) {
  const response = await fetch(`content/${path}`);
  if (!response.ok) throw new Error(`Не удалось загрузить: ${path}`);
  return response.text();
}

function renderMarkdown(targetId, markdown) {
  const target = document.getElementById(targetId);
  target.innerHTML = marked.parse(markdown);
}

function findSection(data, sectionId) {
  return data.sections.find((section) => section.id === sectionId);
}

async function renderHome(data) {
  const md = await loadMarkdown('README.md');
  renderMarkdown('doc-content', md);
}

function renderSectionPage(data) {
  const sectionId = getQueryParam('section');
  const section = findSection(data, sectionId);
  if (!section) throw new Error('Раздел не найден');

  document.getElementById('section-title').textContent = section.title;
  const list = document.getElementById('article-list');
  list.innerHTML = section.files
    .map((file) => `<li><a href="article.html?section=${encodeURIComponent(section.id)}&file=${encodeURIComponent(file.path)}">${file.title}</a></li>`)
    .join('');
}

async function renderArticlePage(data) {
  const sectionId = getQueryParam('section');
  const filePath = getQueryParam('file');

  const section = findSection(data, sectionId);
  if (!section) throw new Error('Раздел не найден');

  const file = section.files.find((item) => item.path === filePath);
  if (!file) throw new Error('Статья не найдена');

  document.getElementById('article-title').textContent = file.title;
  document.getElementById('back-link').href = `section.html?section=${encodeURIComponent(section.id)}`;

  const md = await loadMarkdown(file.path);
  renderMarkdown('doc-content', md);
}

async function init() {
  try {
    const data = await loadContentMap();
    buildTopNav(data);

    const page = document.body.dataset.page;
    if (page === 'home') await renderHome(data);
    if (page === 'section') renderSectionPage(data);
    if (page === 'article') await renderArticlePage(data);
  } catch (error) {
    document.querySelector('main').innerHTML = `<p class="error">Ошибка: ${error.message}</p>`;
  }
}

init();
