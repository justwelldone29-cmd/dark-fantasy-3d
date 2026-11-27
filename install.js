const standalone = navigator.standalone === true || matchMedia('(display-mode: standalone)').matches;
const help = document.getElementById('installHelp');
const status = document.getElementById(standalone ? 'standaloneStatus' : 'offlineStatus');
const iPhone = /iPhone|iPad|iPod/.test(navigator.userAgent)
  || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

if (iPhone && !standalone) {
  help.classList.remove('hide');
  if (/Telegram/i.test(navigator.userAgent)) help.open = true;
}

if ('serviceWorker' in navigator) {
  if (standalone) {
    status.textContent = 'Загружаем уроки и озвучку для работы без интернета…';
    status.classList.remove('hide');
  }
  function showReady() {
    status.textContent = 'Уроки и озвучка доступны без интернета.';
    if (standalone) status.classList.add('hide');
  }
  navigator.serviceWorker.register('sw.js').then(registration => {
    const worker = registration.installing || registration.waiting;
    if (worker && !registration.active) {
      worker.addEventListener('statechange', () => {
        if (worker.state === 'redundant' && !registration.active) {
          status.textContent = 'Загрузка прервалась. Открой приложение с интернетом ещё раз.';
        }
      });
    }
    navigator.serviceWorker.ready.then(showReady);
  }).catch(() => {
    status.textContent = 'Загрузка для офлайн-режима сейчас недоступна. Попробуй открыть приложение снова.';
  });
} else {
  status.textContent = 'Чтобы загрузить уроки для офлайн-режима, открой ссылку в Safari.';
}
