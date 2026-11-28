'use strict';

const $ = selector => document.querySelector(selector);
const $$ = selector => [...document.querySelectorAll(selector)];
const shapes = {
  bolt:'<path d="m13 2-9 12h7l-1 8 10-12h-7l1-8Z"/>',
  game:'<path d="M7 8h10c2 0 3 2 4 6l1 4c0 2-2 2-3 1l-3-3H8l-3 3c-1 1-3 1-3-1l1-4c1-4 2-6 4-6Z"/><path d="M7 10v5m-2.5-2.5h5M16 12h.01M19 14h.01"/>',
  face:'<rect x="4" y="5" width="16" height="15" rx="5"/><path d="M12 2v3M8 11h.01M16 11h.01m-7 4 3 2 3-2"/>',
  trophy:'<path d="M8 21h8m-4-5v5M7 3h10v8a5 5 0 0 1-10 0ZM7 5H3v2a4 4 0 0 0 4 4m10-6h4v2a4 4 0 0 1-4 4"/>',
  coin:'<circle cx="12" cy="12" r="9"/><path d="m12 7 3 5-3 5-3-5Z"/>',
  volume:'<path d="M3 9v6h4l5 4V5L7 9H3Zm13 0a4 4 0 0 1 0 6m2-9a8 8 0 0 1 0 12"/>',
  mute:'<path d="M3 9v6h4l5 4V5L7 9H3Zm13 0 5 6m0-6-5 6"/>',
  full:'<path d="M9 4H4v5m11-5h5v5M4 15v5h5m11-5v5h-5"/>',
  play:'<path d="m8 4 13 8-13 8Z"/>',
  target:'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
  arrow:'<path d="M4 12h15m-6-6 6 6-6 6"/>',
  close:'<path d="m6 6 12 12M18 6 6 18"/>',
  pause:'<path d="M9 5v14m6-14v14"/>'
};
function icon(name) {
  return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round" aria-hidden="true">' + shapes[name] + '</svg>';
}
$$('[data-icon]').forEach(el => { el.innerHTML = icon(el.dataset.icon); });

const words = {
  brand:['Брейнрот Раш','Brainrot Rush'], brand1:['БРЕЙНРОТ','BRAINROT'], brand2:['РАШ','RUSH'],
  race:['Забег','Run'], garage:['Коллекция','Collection'], records:['Рекорды','Records'],
  arcade:['ПОБЕГ ИЗ ЛАБОРАТОРИИ','LAB BREAKOUT'],
  pitch:['Уворачивайся от ловушек, хватай чипы и открывай безумных брейнротов. Как далеко ты убежишь?','Dodge traps, grab chips and unlock bizarre brainrots. How far can you escape?'],
  start:['Играть','Play'], help:['Как играть','How to play'], best:['Личный рекорд','Personal best'], points:['очков','points'],
  goal:['Задание дня','Daily mission'], controls:['Управление','Controls'], steer:['Движение','Move'], nitro:['Рывок','Dash'],
  touch:['Кнопки на экране','On-screen buttons'], garageTip:['Собирай чипы и открывай новых брейнротов.','Collect chips to unlock new brainrots.'],
  recordsTip:['Твои лучшие забеги.','Your best runs.'], score:['СЧЁТ','SCORE'], speed:['МЕТРЫ','METRES'], coins:['ЧИПЫ','CHIPS'],
  sound:['Выключить звук','Mute sound'], mute:['Включить звук','Unmute sound'], full:['Полный экран','Fullscreen'],
  pause:['Пауза','Paused'], left:['Влево','Left'], right:['Вправо','Right'], close:['Закрыть','Close'],
  dailyChips:['Собери чипы','Collect chips'], dailyDistance:['Пробеги метров','Run metres'], dailyDash:['Разбей ловушки','Smash traps'],
  goalDone:['Задание выполнено','Mission complete'], empty:['Сыграй первый забег, и здесь появится результат.','Play your first run to set a record.'],
  selected:['Выбран','Selected'], choose:['Выбрать','Select'], unlock:['Открыть','Unlock'], need:['Нужно чипов','Chips needed'],
  go:['БЕГИ!','RUN!'], resume:['Продолжить','Resume'], home:['В меню','Menu'], again:['Ещё забег','Run again'],
  escape:['Забег окончен','Run over'], record:['Новый рекорд!','New record!'], m:['м','m'],
  ad:['Удвоить чипы • реклама','Double chips • ad'], adWait:['Загрузка рекламы…','Loading ad…'], adFail:['Реклама сейчас недоступна.','Ad is unavailable right now.'],
  adWon:['Чипы удвоены!','Chips doubled!'], labels:['Стрелки или A / D — меняй дорожку. На телефоне нажимай стрелки или свайпай.','Use arrows or A / D to change lanes. On a phone, tap arrows or swipe.'],
  helpDash:['Пробел или кнопка с молнией — рывок. Пока он активен, можно разбивать ловушки.','Space or the lightning button triggers a dash. Dash through traps to smash them.'],
  helpGoal:['Собирай чипы, чтобы открыть героев. Бежишь дольше — коридор ускоряется.','Collect chips to unlock heroes. The corridor speeds up as you run.'],
  smash:['Ловушка разбита!','Trap smashed!'], combo:['Серия','Streak'], sectors:['Следующий сектор','Next sector']
};
let language = 0;
const t = key => words[key][language];
const format = number => Math.floor(number).toLocaleString(language ? 'en' : 'ru');
const heroes = [
  {name:['Тостер Турбо','Turbo Toaster'], text:['Завтрак сбежал первым.','Breakfast broke out first.'], color:'#ff953c', rim:'#fecc70', shoe:'#c3fb5f', price:0},
  {name:['Квак Сокович','Juice Croaker'], text:['Внутри сок. В голове ква.','Juice inside. Ribbits upstairs.'], color:'#50e4a7', rim:'#adfcbf', shoe:'#ff92a8', price:25},
  {name:['Медузумный','Jelly Glitch'], text:['Завис, но продолжил бежать.','Froze up. Kept running anyway.'], color:'#ad82fd', rim:'#e0b8ff', shoe:'#6de7fa', price:65},
  {name:['Тостер Вулкан','Volcano Toaster'], text:['Тосты с хрустящей лавой.','Now with extra crunchy lava.'], color:'#fa5270', rim:'#ffc968', shoe:'#f4e461', price:115},
  {name:['Квак Полярный','Polar Croaker'], text:['Внутри один большой кубик льда.','One big ice cube inside.'], color:'#5ed9ff', rim:'#b4faff', shoe:'#c6a8ff', price:180},
  {name:['Медуза 404','Jelly 404'], text:['Ошибка: не найден выход.','Error: exit not found.'], color:'#f474cd', rim:'#fbc5f2', shoe:'#f6ff86', price:270}
];
const missions = [
  {key:'dailyChips', metric:'coins', target:15}, {key:'dailyDistance', metric:'meters', target:750}, {key:'dailyDash', metric:'broken', target:5}
];
const storageKey = 'brainrot-rush-v1';
let profile = {coins:0, owned:[0], hero:0, scores:[], sound:true, day:{}, updated:0};
try {
  const saved = JSON.parse(localStorage.getItem(storageKey));
  if (saved) profile = {...profile, ...saved};
} catch {}
let sdk, cloud, saveQueue = Promise.resolve(), platformPaused = false, gameApiActive = false;
let page = 'home', dialogType = '', adPending = false, result = null, run;
let audio;
const modal = $('#modal');
const canvas = $('#road');
const ctx = canvas.getContext('2d');
const rnd = Math.random;
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

function save() {
  profile.updated = Date.now();
  try { localStorage.setItem(storageKey, JSON.stringify(profile)); } catch {}
  if (cloud) {
    const snapshot = JSON.parse(JSON.stringify(profile));
    saveQueue = saveQueue.catch(() => {}).then(() => cloud.setData({brainrotRush:snapshot}, true)).catch(() => {});
  }
}
function daily() {
  const day = Math.floor(Date.now() / 86400000);
  if (profile.day.id !== day) profile.day = {id:day, value:0, done:false};
  return missions[day % missions.length];
}
function langUI() {
  document.documentElement.lang = language ? 'en' : 'ru';
  document.title = t('brand');
  $$('[data-i]').forEach(el => { el.textContent = t(el.dataset.i); });
  $$('[data-label]').forEach(el => {
    el.setAttribute('aria-label', t(el.dataset.label));
    el.title = t(el.dataset.label);
  });
  if (dialogType) renderDialog();
  refresh();
}
function refresh() {
  $$('[data-coins]').forEach(el => { el.textContent = format(profile.coins); });
  $$('[data-best]').forEach(el => { el.textContent = format(profile.scores[0]?.score || 0); });
  const mission = daily();
  $('#goal-title').textContent = profile.day.done ? t('goalDone') : t(mission.key) + ' · ' + format(profile.day.value) + '/' + format(mission.target);
  $('#goal-progress').style.width = (100 * profile.day.value / mission.target) + '%';
  $('#goal-reward').style.opacity = profile.day.done ? '.55' : '1';
  $('#sound i').innerHTML = icon(profile.sound ? 'volume' : 'mute');
  $('#sound').setAttribute('aria-label', t(profile.sound ? 'sound' : 'mute'));
  $('#sound').title = t(profile.sound ? 'sound' : 'mute');
  if (page === 'garage') showHeroes();
  if (page === 'records') showRecords();
}
function navigate(next) {
  page = next;
  $$('.page').forEach(el => { el.hidden = el.id !== page; });
  $$('.tab').forEach(el => {
    const selected = el.dataset.page === (page === 'track' ? 'home' : page);
    el.classList.toggle('active', selected);
    if (selected) el.setAttribute('aria-current','page');
    else el.removeAttribute('aria-current');
  });
  document.body.classList.toggle('driving', page === 'track');
  refresh();
}
function showHeroes() {
  $('#car-list').innerHTML = heroes.map((hero, id) => {
    const owned = profile.owned.includes(id);
    const selected = profile.hero === id;
    const action = selected ? t('selected') : owned ? t('choose') : t('unlock') + ' · ' + hero.price;
    const short = !owned && profile.coins < hero.price;
    return '<article class="car-card"><div class="car-preview"><canvas width="400" height="210" aria-hidden="true"></canvas></div><div class="car-content"><h2>' + hero.name[language] + '</h2><p>' + hero.text[language] + '</p><button class="secondary" data-hero="' + id + '"' + (selected || short ? ' disabled' : '') + '>' + (owned ? '' : icon('coin')) + action + '</button></div></article>';
  }).join('');
  $$('.car-preview canvas').forEach((preview, id) => drawHero(preview.getContext('2d'), 200, 192, 140, id, .7, false));
}
function showRecords() {
  $('#record-list').innerHTML = profile.scores.length ? profile.scores.map((entry, i) =>
    '<div class="record"><strong>#' + (i + 1) + '</strong><b>' + format(entry.score) + ' ' + t('points') + '</b><small>' + format(entry.meters) + ' ' + t('m') + '</small></div>'
  ).join('') : '<p class="empty">' + t('empty') + '</p>';
}
function setDialog(kind) {
  dialogType = kind;
  if (kind) {
    renderDialog();
    if (!modal.open) modal.showModal();
  } else if (modal.open) modal.close();
}
function dialogButton(label, action, primary = false, iconName = '') {
  return '<button class="' + (primary ? 'primary' : 'secondary') + '" data-action="' + action + '">' + (iconName ? icon(iconName) : '') + t(label) + '</button>';
}
function renderDialog() {
  $('#close-dialog').disabled = adPending;
  const body = $('#modal-body');
  if (dialogType === 'help') {
    body.innerHTML = '<h2>' + t('help') + '</h2><ul><li>' + t('labels') + '</li><li>' + t('helpDash') + '</li><li>' + t('helpGoal') + '</li></ul><div class="actions">' + dialogButton('start','start',true,'play') + '</div>';
  }
  if (dialogType === 'pause') {
    body.innerHTML = '<h2>' + t('pause') + '</h2><div class="actions">' + dialogButton('resume','resume',true,'play') + dialogButton('home','menu') + '</div>';
  }
  if (dialogType === 'result') {
    const ad = sdk?.adv?.showRewardedVideo && result.coins > 0 && !result.rewarded;
    body.innerHTML = '<h2>' + t(result.record ? 'record' : 'escape') + '</h2><div class="dialog-score">' + format(result.score) + '</div><p>' + format(result.meters) + ' ' + t('m') + ' · +' + format(result.coins * (result.rewarded ? 2 : 1)) + ' ' + t('coins').toLowerCase() + '</p><div class="actions">' + dialogButton('again','start',true,'play') + dialogButton('home','menu') + (ad ? dialogButton(adPending ? 'adWait' : 'ad','ad',false,'bolt') : '') + '</div>' + (result.notice ? '<p role="status">' + t(result.notice) + '</p>' : '');
    if (adPending) body.querySelectorAll('button').forEach(button => { button.disabled = true; });
  }
}

function tone(freq, end, length, volume = .09, type = 'sine') {
  if (!profile.sound || platformPaused || !audio || audio.state !== 'running') return;
  const osc = audio.createOscillator();
  const gain = audio.createGain();
  const now = audio.currentTime;
  osc.type = type;
  osc.frequency.setValueAtTime(freq, now);
  osc.frequency.exponentialRampToValueAtTime(end, now + length);
  gain.gain.setValueAtTime(volume, now);
  gain.gain.exponentialRampToValueAtTime(.001, now + length);
  osc.connect(gain).connect(audio.destination);
  osc.start();
  osc.stop(now + length);
}
function wakeAudio() {
  if (!profile.sound) return;
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio) return;
  audio ||= new Audio();
  audio.resume().catch(() => {});
}
function markPlaying() {
  const shouldPlay = !!run && run.state === 'active' && !platformPaused && !document.hidden;
  if (shouldPlay === gameApiActive || !sdk) return;
  gameApiActive = shouldPlay;
  if (shouldPlay) sdk.features?.GameplayAPI?.start();
  else sdk.features?.GameplayAPI?.stop();
}

function startRun() {
  if (adPending || platformPaused) return;
  wakeAudio();
  setDialog('');
  result = null;
  run = {state:'countdown', countdown:2.35, go:0, time:0, meters:0, x:0, lane:0, energy:100, dash:0, score:0, coins:0, broken:0, streak:0, spawnAt:0, objects:[], flash:0, message:0, particles:[]};
  makeRow(30, true);
  $('#toast').textContent = '';
  $('#countdown').hidden = true;
  navigate('track');
  resize();
  lastTime = performance.now();
  if (!frame) frame = requestAnimationFrame(tick);
}
function pauseRun() {
  if (!run || !['active','countdown'].includes(run.state)) return;
  run.beforePause = run.state;
  run.state = 'paused';
  markPlaying();
  setDialog('pause');
}
function resumeRun() {
  if (!run || run.state !== 'paused' || platformPaused || document.hidden) return;
  run.state = run.beforePause;
  wakeAudio();
  setDialog('');
  markPlaying();
}
function settle(show) {
  if (!run || run.state === 'over') return;
  const data = {score:Math.floor(run.score), meters:Math.floor(run.meters), coins:run.coins, record:Math.floor(run.score) > (profile.scores[0]?.score || 0), rewarded:false};
  run.state = 'over';
  markPlaying();
  $('#countdown').hidden = true;
  profile.coins += data.coins;
  if (data.score > 0) {
    profile.scores = [...profile.scores, {score:data.score, meters:data.meters}].sort((a,b) => b.score - a.score || b.meters - a.meters).slice(0, 10);
  }
  const mission = daily();
  if (!profile.day.done) {
    profile.day.value = Math.min(mission.target, profile.day.value + Math.floor(run[mission.metric]));
    if (profile.day.value === mission.target) {
      profile.day.done = true;
      profile.coins += 50;
    }
  }
  save();
  refresh();
  if (show) {
    result = data;
    tone(125, 38, .29, .12, 'triangle');
    setDialog('result');
  }
}
function leaveRun(next = 'home') {
  if (adPending) return;
  settle(false);
  run = null;
  setDialog('');
  navigate(next);
}
function rewarded() {
  const api = sdk?.adv;
  if (!api?.showRewardedVideo || !result?.coins || result.rewarded || adPending) return;
  const offer = result;
  adPending = true;
  offer.notice = '';
  renderDialog();
  let finished = false;
  const finish = () => {
    if (finished) return;
    finished = true;
    adPending = false;
    offer.notice = offer.rewarded ? 'adWon' : 'adFail';
    if (dialogType === 'result' && result === offer) renderDialog();
  };
  try {
    api.showRewardedVideo({callbacks:{
      onRewarded:() => {
        if (offer.rewarded || finished) return;
        offer.rewarded = true;
        profile.coins += offer.coins;
        save();
        refresh();
      },
      onClose:finish,
      onError:finish
    }});
  } catch { finish(); }
}

let width = 0, height = 0, frame = 0, lastTime = 0;
const horizon = .26, depth = 115;
const sectors = [
  {sky:'#110a24', glow:'#873aff', rail:'#bd71ff', floor:'#241639', wall:'#1f122f', light:'#78f9da'},
  {sky:'#081d21', glow:'#16c3a9', rail:'#4ff9cf', floor:'#143238', wall:'#102730', light:'#d5ff65'},
  {sky:'#20091e', glow:'#bf3279', rail:'#ff77b4', floor:'#35172c', wall:'#2b1428', light:'#ffcf75'}
];
function project(distance, lane = 0) {
  const p = Math.pow(Math.max(0, 1 - distance / depth), 2.1);
  const wide = Math.min(width * .47, height * .89);
  const half = wide * (.08 + .92 * p);
  return {x: width / 2 + lane * half * .62, y:height * (horizon + p * .60), half, p};
}
function poly(c, fill, ...xy) {
  c.fillStyle = fill;
  c.beginPath();
  c.moveTo(xy[0],xy[1]);
  for (let i = 2; i < xy.length; i += 2) c.lineTo(xy[i],xy[i+1]);
  c.closePath();
  c.fill();
}
function ellipse(c, color, x, y, rx, ry) {
  c.fillStyle = color;
  c.beginPath();
  c.ellipse(x, y, rx, ry, 0, 0, Math.PI * 2);
  c.fill();
}
function rect(c, color, x, y, w, h, radius = 0) {
  c.fillStyle = color;
  c.beginPath();
  c.roundRect(x, y, w, h, radius);
  c.fill();
}
function segment(c, color, size, ...xy) {
  c.strokeStyle = color;
  c.lineWidth = size;
  c.lineJoin = 'round';
  c.lineCap = 'round';
  c.beginPath();
  c.moveTo(xy[0], xy[1]);
  for (let i = 2; i < xy.length; i += 2) c.lineTo(xy[i], xy[i+1]);
  c.stroke();
}
function drawHero(c,x,y,size,id,time,boost) {
  const hero = heroes[id];
  const step = Math.sin(time * (boost ? 25 : 15));
  const bob = Math.abs(step) * 5;
  c.save();
  c.translate(x,y);
  c.scale(size/100,size/100);
  ellipse(c,'#0907118c',0,0,38,9);
  if (boost) ellipse(c,'#beff6666',0,-38,44,49);
  segment(c,'#251634',7,-16,-37,-24-step*8,-16,-21+step*12,-6);
  segment(c,'#251634',7,16,-37,22+step*8,-17,21-step*12,-6);
  rect(c,'#191121',-31+step*12,-10,25,12,5);
  rect(c,'#191121',9-step*12,-10,25,12,5);
  rect(c,hero.shoe,-31+step*12,-13,25,11,5);
  rect(c,hero.shoe,9-step*12,-13,25,11,5);
  c.translate(0,-bob);
  segment(c,'#543281',6,-25,-63,-37,-52,-43-step*5,-58);
  segment(c,'#543281',6,25,-62,37,-51,43+step*5,-58);
  ellipse(c,hero.rim,-43-step*5,-59,6,7);
  ellipse(c,hero.rim,43+step*5,-59,6,7);
  switch(id % 3) {
    case 0:
      rect(c,'#98502e',-18,-96,35,41,9);
      rect(c,'#f9ce94',-14,-91,27,33,7);
      rect(c,hero.rim,-33,-76,69,47,13);
      rect(c,hero.color,-34,-71,66,47,12);
      rect(c,'#fff4c68a',-28,-68,15,4,2);
      rect(c,'#a6442c',28,-64,7,18,2);
      break;
    case 1:
      poly(c,hero.rim,-27,-77,-17,-91,18,-91,30,-77,19,-69);
      rect(c,hero.color,-26,-77,55,53,6);
      rect(c,hero.rim,-22,-74,10,43,3);
      segment(c,'#ffe0ab',5,17,-84,17,-104,25,-109);
      ellipse(c,hero.color,-17,-78,15,14);
      ellipse(c,hero.color,16,-78,15,14);
      break;
    default:
      segment(c,hero.rim,4,-4,-81,-14,-99,3,-94,12,-102);
      rect(c,hero.color,-35,-82,70,52,15);
      rect(c,'#30224a',-28,-76,55,39,11);
      segment(c,hero.color,5,-25,-32,-31,-22,-26,-15);
      segment(c,hero.color,5,25,-32,32,-22,26,-15);
  }
  const eyeHeight = time % 3.4 > 3.28 ? 2 : 10;
  ellipse(c,'#fffcf8',-12,-61,10,eyeHeight);
  ellipse(c,'#fffcf8',12,-61,11,eyeHeight);
  if (eyeHeight > 2) {
    ellipse(c,'#1a1426',-10,-59,4,5);
    ellipse(c,'#1a1426',14,-59,4,5);
  }
  ellipse(c,'#32182f',1,-45,10,6);
  rect(c,'#fff4eb',-4,-49,11,3,1.5);
  c.restore();
}
function drawHall(theme) {
  const offset = run.meters;
  const far = project(depth), near = project(0);
  const lineY = far.y;
  const light = ctx.createRadialGradient(width/2,lineY,0,width/2,lineY,width*.68);
  light.addColorStop(0,theme.glow);
  light.addColorStop(.39,theme.sky);
  light.addColorStop(1,'#090615');
  ctx.fillStyle = light;
  ctx.fillRect(0,0,width,height);
  poly(ctx,theme.wall,0,0,far.x-far.half,lineY,near.x-near.half,near.y,0,height);
  poly(ctx,theme.wall,width,0,far.x+far.half,lineY,near.x+near.half,near.y,width,height);
  const floor = ctx.createLinearGradient(0,lineY,0,height);
  floor.addColorStop(0,theme.sky);
  floor.addColorStop(.35,theme.floor);
  floor.addColorStop(1,'#0d0a18');
  poly(ctx,floor,far.x-far.half,lineY,far.x+far.half,lineY,width*.5+near.half*1.2,height,width*.5-near.half*1.2,height);
  for (const side of [-1,1]) {
    segment(ctx,theme.rail+'94',2,far.x + far.half*side,lineY,width/2 + near.half*1.2*side,height);
    segment(ctx,theme.rail+'55',1,far.x + far.half*side,lineY,width/2 + near.half*1.8*side,0);
  }
  for (let d = depth - offset % 13; d > -4; d -= 13) {
    const spot = project(d);
    const size = spot.p;
    ctx.globalAlpha = Math.min(1,size * 1.6 + .08);
    segment(ctx,theme.rail+'48',Math.max(1,size*2),spot.x-spot.half,spot.y,spot.x+spot.half,spot.y);
    if (d > 4) {
      const ahead = project(d - 4);
      for (const lane of [-.5,.5]) {
        segment(ctx,theme.rail+'77',Math.max(1,size*3),spot.x+spot.half*.62*lane,spot.y,ahead.x+ahead.half*.62*lane,ahead.y);
      }
    }
    for (const side of [-1,1]) {
      const x = spot.x + side*spot.half;
      const top = lineY - size*height*.47;
      const postWidth = 2 + size*20;
      const glassHeight = Math.max(1,(spot.y-top)*.42);
      const tankX = side < 0 ? x-postWidth*3.45 : x+postWidth*.9;
      rect(ctx,theme.rail+'24',tankX,top+glassHeight*.41,postWidth*2.45,glassHeight,Math.min(8,postWidth*.28));
      rect(ctx,theme.light+'55',tankX+postWidth*.2,top+glassHeight*.56,postWidth*2.02,glassHeight*.82,2);
      rect(ctx,theme.light,side < 0 ? x-postWidth : x,top,postWidth*.22,Math.max(1,(spot.y-top)*.62),1);
      rect(ctx,theme.rail+'7c',side < 0 ? x-postWidth : x,top,postWidth,Math.max(1,spot.y-top),2);
      ellipse(ctx,theme.light+'88',tankX+postWidth*1.25,top+glassHeight*.75,postWidth*.21,postWidth*.21);
    }
    ctx.globalAlpha = 1;
  }
}
function drawObject(object, theme) {
  const distance = object.z - run.meters;
  if (distance > depth || distance < -3) return;
  const {x,y,p} = project(distance,object.lane);
  const size = Math.max(2,(.05 + p*.95) * Math.min(width*.16,height*.15));
  ctx.save();
  ctx.translate(x,y);
  if (object.type === 'coin') {
    const sway = Math.abs(Math.cos(run.time*7 + object.z*.1))*.62 + .38;
    const r = size*.27;
    ctx.translate(0,-size*.55 + Math.sin(run.time*5+object.z)*size*.07);
    ellipse(ctx,'#ffaf4655',0,0,r*1.38,r*1.45);
    ellipse(ctx,'#f38624',0,0,r*sway,r);
    ellipse(ctx,'#ffd765',0,-r*.1,r*sway*.78,r*.81);
    poly(ctx,'#df7629',0,-r*.58,r*.3*sway,0,0,r*.47,-r*.3*sway,0);
  } else {
    const alt = object.style;
    ellipse(ctx,'#090714aa',0,0,size*.63,size*.12);
    rect(ctx,alt ? '#494369' : '#5b294f',-size*.55,-size*.68,size*1.1,size*.67,size*.08);
    rect(ctx,alt ? '#a5f1ff' : '#ff8bc6',-size*.54,-size*.72,size*1.08,size*.11,size*.05);
    rect(ctx,'#141221',-size*.49,-size*.55,size*.98,size*.31,size*.03);
    for (let i = 0; i < 3; i++) {
      const start = size*(-.43 + i*.29);
      poly(ctx,alt ? theme.light : '#ffbf54',start,-size*.29,start+size*.16,-size*.52,start+size*.28,-size*.52,start+size*.12,-size*.29);
    }
  }
  ctx.restore();
}
function draw() {
  if (!run || !width || !height) return;
  const theme = sectors[Math.floor(run.meters/450) % sectors.length];
  drawHall(theme);
  for (let i = run.objects.length - 1; i >= 0; i--) drawObject(run.objects[i],theme);
  const player = project(0,run.x);
  const size = Math.min(width*.24,height*.23);
  drawHero(ctx,player.x,player.y,size,profile.hero,run.time,run.dash > 0);
  for (const p of run.particles) {
    ctx.globalAlpha = p.life * 2;
    rect(ctx,p.color,p.x,p.y,p.size,p.size,2);
  }
  ctx.globalAlpha = 1;
  if (run.flash > 0) {
    ctx.fillStyle = run.dash > 0 ? 'rgba(190,255,90,' + run.flash*.36 + ')' : 'rgba(255,85,115,' + run.flash*.55 + ')';
    ctx.fillRect(0,0,width,height);
  }
}
function burst(lane, color) {
  const {x,y} = project(4,lane);
  for (let i=0; i<9; i++) {
    run.particles.push({x,y:y-24,vx:(rnd()-.5)*270,vy:-rnd()*220,size:3+rnd()*5,life:.3+rnd()*.2,color});
  }
}
function makeRow(z, intro = false) {
  const safe = intro ? 0 : Math.floor(rnd()*3)-1;
  const traps = [-1,0,1].filter(lane => lane !== safe);
  if (!intro) {
    const count = run.meters > 180 && rnd() < .35 ? 2 : 1;
    if (rnd() < .5) traps.reverse();
    for (const lane of traps.slice(0,count)) run.objects.push({z,lane,type:'trap',style:rnd()<.35});
  }
  for (let i=0;i<3;i++) run.objects.push({z:z+3+i*4,lane:safe,type:'coin'});
  run.objects.sort((a,b) => a.z-b.z);
}
function toast(message) {
  $('#toast').textContent = message;
  run.message = 1.15;
}
function update(dt) {
  if (run.state === 'countdown') {
    run.countdown -= dt;
    const countdown = $('#countdown');
    countdown.hidden = false;
    if (run.countdown > 0) countdown.textContent = Math.ceil(run.countdown);
    else {
      run.state = 'active';
      run.go = .5;
      markPlaying();
      countdown.textContent = t('go');
      tone(380,680,.18);
    }
    return;
  }
  if (run.state !== 'active') return;
  run.time += dt;
  run.go -= dt;
  if (run.go <= 0) $('#countdown').hidden = true;
  run.x += (run.lane - run.x) * Math.min(1, dt*16);
  run.dash = Math.max(0,run.dash-dt);
  if (!run.dash) run.energy = Math.min(100,run.energy + 16*dt);
  run.flash = Math.max(0,run.flash-dt);
  if (run.message > 0) {
    run.message -= dt;
    if (run.message <= 0) $('#toast').textContent = '';
  }
  const previous = run.meters;
  const speed = 24 + Math.min(34,run.time*.72) + (run.dash ? 17 : 0);
  run.meters += dt * speed;
  run.score += dt * speed * (run.dash ? 2 : 1);
  if (Math.floor(previous/450) !== Math.floor(run.meters/450)) toast(t('sectors'));
  if (run.meters >= run.spawnAt) {
    makeRow(run.meters + 91);
    run.spawnAt = run.meters + Math.max(31,46-run.time*.29);
  }
  run.objects = run.objects.filter(object => {
    if (run.state === 'over') return true;
    const d = object.z - run.meters;
    if (d > 2.2) return true;
    if (object.z - previous < -2.4 || d < -2.4) {
      if (object.type === 'coin') run.streak = 0;
      return false;
    }
    if (Math.abs(object.lane-run.x) > (object.type === 'trap' ? .48 : .49)) return true;
    if (object.type === 'coin') {
      run.coins++;
      run.streak++;
      run.score += 14 + Math.min(15,run.streak);
      burst(object.lane,'#ffcf65');
      tone(590+run.streak%8*48,880+run.streak%8*36,.12,.047);
      if (run.streak % 6 === 0) toast(t('combo') + ' ×' + run.streak);
    } else if (run.dash) {
      run.broken++;
      run.score += 70;
      run.flash = .18;
      burst(object.lane,'#c1ff61');
      tone(120,255,.16,.11,'triangle');
      toast(t('smash'));
    } else {
      run.flash = .4;
      settle(true);
    }
    return false;
  });
  if (run.state === 'over') return;
  run.particles = run.particles.filter(p => {
    p.life -= dt;
    p.x += p.vx*dt;
    p.y += p.vy*dt;
    p.vy += 430*dt;
    return p.life > 0;
  });
}
function tick(time) {
  frame = 0;
  if (!run || page !== 'track') return;
  const dt = Math.min(.05,(time-lastTime)/1000);
  lastTime = time;
  if (run.state !== 'paused' && run.state !== 'over' && !platformPaused) update(Math.max(0,dt));
  draw();
  $('#hud-score').textContent = format(run.score);
  $('#hud-speed').textContent = format(run.meters);
  $('#hud-coins').textContent = format(run.coins);
  $('#boost-fill').style.width = run.energy + '%';
  if (run.state !== 'over') frame = requestAnimationFrame(tick);
}
function resize() {
  if (page !== 'track') return;
  const viewport = canvas.getBoundingClientRect();
  width = viewport.width;
  height = viewport.height;
  const ratio = Math.min(devicePixelRatio || 1,2);
  canvas.width = Math.round(width*ratio);
  canvas.height = Math.round(height*ratio);
  ctx.setTransform(ratio,0,0,ratio,0,0);
  draw();
}
function drive(action) {
  if (!run || !['active','countdown'].includes(run.state) || platformPaused) return;
  if (action === 'left' || action === 'right') {
    run.lane = clamp(run.lane + (action === 'left' ? -1 : 1),-1,1);
  } else if (run.state === 'active' && run.energy >= 60 && run.dash <= 0) {
    run.energy -= 60;
    run.dash = 1.08;
    tone(140,680,.23,.09,'triangle');
  }
}

document.addEventListener('click', event => {
  const button = event.target.closest('button');
  if (!button || adPending) return;
  if (button.dataset.page) {
    if (page === 'track') leaveRun(button.dataset.page);
    else navigate(button.dataset.page);
  }
  if (button.dataset.hero !== undefined) {
    const id = Number(button.dataset.hero);
    if (!profile.owned.includes(id)) {
      if (profile.coins < heroes[id].price) return;
      profile.coins -= heroes[id].price;
      profile.owned.push(id);
    }
    profile.hero = id;
    save();
    refresh();
  }
  const action = button.dataset.action || button.id;
  if (action === 'start') startRun();
  if (action === 'help') setDialog('help');
  if (action === 'pause') pauseRun();
  if (action === 'resume') resumeRun();
  if (action === 'menu') leaveRun();
  if (action === 'ad') rewarded();
  if (action === 'close-dialog') closeDialog();
  if (action === 'sound') {
    profile.sound = !profile.sound;
    save();
    if (profile.sound) { wakeAudio(); tone(420,610,.14); }
    else audio?.suspend().catch(() => {});
    refresh();
  }
  if (action === 'fullscreen') {
    if (document.fullscreenElement) document.exitFullscreen?.().catch(() => {});
    else document.documentElement.requestFullscreen?.().catch(() => {});
  }
});
function closeDialog() {
  if (adPending) return;
  if (dialogType === 'pause') resumeRun();
  else if (dialogType === 'result') leaveRun();
  else setDialog('');
}
modal.addEventListener('cancel', event => { event.preventDefault(); closeDialog(); });
document.addEventListener('keydown', event => {
  const controls = {ArrowLeft:'left',KeyA:'left',ArrowRight:'right',KeyD:'right',Space:'boost'};
  if (modal.open || page !== 'track') return;
  if (controls[event.code]) {
    event.preventDefault();
    if (!event.repeat) drive(controls[event.code]);
  } else if (event.code === 'Escape' || event.code === 'KeyP') {
    event.preventDefault();
    if (!event.repeat) pauseRun();
  }
});
$$('[data-drive]').forEach(button => button.addEventListener('pointerdown', event => {
  event.preventDefault();
  drive(button.dataset.drive);
}));
$$('[data-drive]').forEach(button => button.addEventListener('click', event => {
  if (event.detail === 0) drive(button.dataset.drive);
}));
let drag;
canvas.addEventListener('pointerdown', event => {
  if (event.pointerType === 'mouse') return;
  drag = {id:event.pointerId,x:event.clientX,y:event.clientY};
  canvas.setPointerCapture(event.pointerId);
});
canvas.addEventListener('pointermove', event => {
  if (drag?.id !== event.pointerId) return;
  const dx = event.clientX-drag.x, dy = event.clientY-drag.y;
  if (Math.abs(dx) >= 28 && Math.abs(dx) > Math.abs(dy)) {
    drive(dx < 0 ? 'left' : 'right');
    drag.x = event.clientX;
    drag.y = event.clientY;
  }
});
for (const end of ['pointerup','pointercancel']) {
  canvas.addEventListener(end, event => { if (drag?.id === event.pointerId) drag = undefined; });
}
window.addEventListener('resize',resize);
window.addEventListener('blur',pauseRun);
document.addEventListener('visibilitychange',() => {
  if (document.hidden) {
    audio?.suspend().catch(() => {});
    pauseRun();
  }
});
document.addEventListener('contextmenu',event => event.preventDefault());
if (!document.fullscreenEnabled) $('#fullscreen').hidden = true;

async function connectPlatform() {
  try {
    sdk = await window.YaGames.init();
    if (!sdk) return;
    const lang = sdk.environment?.i18n?.lang;
    if (lang) language = lang === 'ru' ? 0 : 1;
    langUI();
    sdk.on?.('game_api_pause',() => {
      platformPaused = true;
      audio?.suspend().catch(() => {});
      pauseRun();
    });
    sdk.on?.('game_api_resume',() => {
      platformPaused = false;
    });
    sdk.features?.LoadingAPI?.ready();
    markPlaying();
    const player = await sdk.getPlayer?.();
    if (!player || player.isAuthorized?.() === false) return;
    const versionAtRequest = profile.updated;
    const saved = (await player.getData(['brainrotRush'])).brainrotRush;
    cloud = player;
    if (saved?.updated > profile.updated && versionAtRequest === profile.updated && page !== 'track') {
      profile = {...profile,...saved};
      try { localStorage.setItem(storageKey,JSON.stringify(profile)); } catch {}
      refresh();
    } else if (profile.updated > (saved?.updated || 0)) {
      save();
    }
  } catch {}
}
langUI();
navigate('home');
if (window.YaGames) {
  connectPlatform();
} else if (location.protocol !== 'file:' && (window.self !== window.top || /(^|\.)(yandex\.(ru|com|kz|uz|by|net)|yandexgames\.com)$/.test(location.hostname))) {
  const script = document.createElement('script');
  script.src = '/sdk.js';
  script.async = true;
  script.onload = connectPlatform;
  document.head.append(script);
}
