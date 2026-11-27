const groups=[["Первое знакомство","👋","пуры кечӹ:Добрый день|тау:Спасибо|яжо:Хороший|у:Новый|мӹнь:Я|тӹнь:Ты|мӓ:Мы|лӹм:Имя"],["Числа","🔢","иктӹ:Один|кокты:Два|кымыт:Три|нӹлӹт:Четыре|вӹзӹт:Пять|кудыт:Шесть|шӹмӹт:Семь|кӓндӓкшӹ:Восемь|ӹндекшӹ:Девять|лу:Десять"],["Семья и люди","👨‍👩‍👧","ӓвӓ:Мама|ӓтя:Папа|папа:Бабушка|ӹдӹр:Дочь|ӹзӓ:Старший брат|эдем:Человек|лӹм:Имя|мӓ:Мы"],["Природа","🌳","вӹд:Вода|тыл:Огонь|кечӹ:Солнце|тӹлзӹ:Луна|шӹдӹр:Звезда|йыд:Ночь|юр:Дождь|лым:Снег|мардеж:Ветер|кырык:Гора"],["Животные","🐈","пи:Собака|коти:Кошка|кол:Рыба|кек:Птица|лӹпӹ:Бабочка|мӧскӓ:Медведь|имни:Лошадь|куку:Кукушка|цӓрӓгек:Летучая мышь|мыны:Яйцо"],["Цвета и качества","🎨","якшаргы:Красный|ошы:Белый|шим:Чёрный|ыжар:Зелёный|симсӹ:Бирюзовый, синий|яжо:Хороший|у:Новый"],["Дом и вещи","🏠","пӧрт:Дом|книгӓ:Книга|арава:Телега|кӹртни:Железо|парсын:Шёлк|компьютер:Компьютер|кӱ:Камень|рок:Земля"],["Еда и напитки","🍯","шӹшер:Молоко|мӱ:Мёд|санзал:Соль|чӓй:Чай|кофе:Кофе|сакыр:Сахар|роколма:Картофель|рис:Рис|шоколад:Шоколад|апельсин:Апельсин"],["Человек и тело","👁️","вуй:Голова|сӹнзӓ:Глаз|пӹлӹш:Ухо|нер:Нос|ышма:Рот|пӱ:Зуб|йӹлмӹ:Язык|кид:Рука|шӱм:Сердце|лу:Кость"],["Действия и время","⏰","качкаш:Есть|йӱӓш:Пить|амалаш:Спать|тенгечӹ:Вчера|иргодым:Завтра|шачмы:Понедельник|шанавӹл:Радуга|хӹдӹртӹш:Гром"]];
const lessons=Array.from({length:100},(_,id)=>({id,group:Math.floor(id/10),round:id%10}));const vocab=groups.map(g=>g[2].split('|').map(pair=>pair.split(':')));
const KEY = 'kyryk_mary_v1';
const defaultState = {name: '', completed: [], xp: 0, streak: 0, lastDay: '', hearts: 5};
function loadState() {
  for (const key of [KEY, 'kyryk_mary_legacy']) {
    try {
      const saved = JSON.parse(localStorage.getItem(key));
      if (saved && typeof saved === 'object' && !Array.isArray(saved)) return saved;
    } catch {}
  }
  return {};
}
const saved = loadState();
const completed = Array.isArray(saved.completed) ? saved.completed : [];
const savedMistakes = Array.isArray(saved.mistakes) ? saved.mistakes : [];
const validMistakes = savedMistakes.filter(key => {
  if (typeof key !== 'string' || !/^\d:\d:(listen|mari|translate)$/.test(key)) return false;
  const [group, index] = key.split(':').map(Number);
  return Boolean(vocab[group] && vocab[group][index]);
});
const state = {
  mistakes: [...new Set(validMistakes)],
  ...defaultState,
  name: typeof saved.name === 'string' ? saved.name.slice(0, 26) : '',
  completed: [...new Set(completed.filter(id => Number.isInteger(id) && id >= 0 && id < lessons.length))],
  xp: typeof saved.xp === 'number' && Number.isFinite(saved.xp) && saved.xp > 0 ? saved.xp : Math.max(0, parseInt(saved.xp, 10) || 0),
  streak: Math.max(0, parseInt(saved.streak, 10) || 0),
  lastDay: typeof saved.lastDay === 'string' ? saved.lastDay : ''
};
const $ = id => document.getElementById(id);
const dateKey = d => [d.getFullYear(), String(d.getMonth() + 1).padStart(2, '0'), String(d.getDate()).padStart(2, '0')].join('-');
const today = () => dateKey(new Date());
let current = 0, qIndex = 0, selected = -1, checked = false, correct = 0, questions = [], hearts = 5;
let activePage = 'home';
let reviewing = false;
let previewGroup = null;
let activeAudio = null;

function persist() {
  try { localStorage.setItem(KEY, JSON.stringify(state)); } catch {}
}
function updateStats(){$('statXp').textContent=state.xp;$('statStreak').textContent=state.streak;$('statHearts').textContent=5;$('welcomeName').textContent=state.name||'друг';}
function go(id){if(id!=='quiz')stopAudio();activePage=id;['home','quiz','finish','themes','profile'].forEach(v=>$(v).classList.toggle('hide',v!==id));$('nav').classList.toggle('hide',id==='quiz'||id==='finish');$('header').classList.toggle('hide',id==='quiz'||id==='finish');document.querySelectorAll('[data-page]').forEach(b=>b.classList.toggle('active',b.dataset.page===id));if(id==='home')renderMap();if(id==='themes')renderThemes();if(id==='profile')renderProfile();window.scrollTo(0,0)}
function renderMap(){updateStats();updateReviewButtons();const done=new Set(state.completed),next=lessons.findIndex(v=>!done.has(v.id));$('mapUnits').innerHTML='';for(let g=0;g<groups.length;g++){const group=groups[g],n=Array.from({length:10},(_,k)=>g*10+k).filter(id=>done.has(id)).length,div=document.createElement('div');div.innerHTML=`<div class="unit"><div style="flex:1"><div class="eyebrow">МОДУЛЬ ${g+1}, РАЗДЕЛ ${g+1}</div><h1>${group[0]}</h1><p>${n} ИЗ 10 УРОКОВ</p><div class="track"><span style="width:${n*10}%"></span></div></div><span class="book">${group[1]}</span></div>`;const trialButton=document.createElement('button');trialButton.type='button';trialButton.className='trialButton';trialButton.textContent='Пробный урок';trialButton.setAttribute('aria-label','Пробный урок: '+group[0]);trialButton.onclick=()=>startTrial(g);div.querySelector('.unit > div').appendChild(trialButton);const path=document.createElement('div');path.className='path';for(let k=0;k<10;k++){const id=g*10+k,doneLesson=done.has(id),unlocked=doneLesson||id===next,wrap=document.createElement('div'),button=document.createElement('button'),shift=Math.round(Math.sin(k*1.3+.4)*75);wrap.className='nodeRow';wrap.style.setProperty('--shift',shift+'px');button.className='node '+(doneLesson?'done':unlocked?'open':k===7?'chest':'');button.style.setProperty('--shift',shift+'px');button.disabled=!unlocked;button.textContent=doneLesson?'★':unlocked?(k%4===0?'★':'📖'):k===7?'🎁':'★';button.setAttribute('aria-label',`Урок ${id+1}${unlocked?'':', заблокирован'}`);button.onclick=()=>start(id);wrap.appendChild(button);if(unlocked&&!doneLesson){const label=document.createElement('span');label.className='bubble';label.textContent='УРОК '+(id+1);wrap.appendChild(label)}if(doneLesson){const label=document.createElement('span');label.className='nodeCaption';label.textContent='ПРОЙДЕНО';wrap.appendChild(label)}path.appendChild(wrap)}div.appendChild(path);$('mapUnits').appendChild(div)}}
function renderThemes(){$('unitsOverview').innerHTML='';groups.forEach((g,i)=>{const b=document.createElement('button');b.className='miniUnit';let count=state.completed.filter(n=>Math.floor(n/10)===i).length;b.innerHTML=`<span>${g[1]}</span>${g[0]}<small>${count}/10 уроков</small>`;b.onclick=()=>{go('home');document.querySelectorAll('.unit')[i].scrollIntoView({block:'start',behavior:'smooth'})};$('unitsOverview').appendChild(b)})}
function renderProfile(){$('profileName').textContent=state.name||'Гость';$('nameInput').value=state.name||'';$('profileXp').textContent=state.xp;$('profileCount').textContent=state.completed.length;$('profileStreak').textContent=state.streak;}
function makeQuestion(group, index, mode, seed) {
  const items = vocab[group];
  const [word, translation] = items[index];
  const reverse = mode === 'mari';
  const listening = mode === 'listen';
  const answer = reverse ? word : translation;
  const distractors = items
    .filter((_, position) => position !== index)
    .map(pair => pair[reverse ? 0 : 1]);
  const offset = seed % distractors.length;
  const answers = [...new Set([
    answer,
    ...[0, 2, 4].map(step => distractors[(offset + step) % distractors.length])
  ])];
  for (let position = answers.length - 1; position > 0; position--) {
    const swap = (seed * 13 + position * 3) % (position + 1);
    [answers[position], answers[swap]] = [answers[swap], answers[position]];
  }
  return {
    key: [group, index, mode].join(':'),
    word, listening, answers,
    correct: answers.indexOf(answer),
    question: listening ? 'Послушай и выбери перевод' : reverse
      ? 'Как по-горномарийски сказать «' + translation + '»?'
      : 'Выбери перевод слова «' + word + '»',
    type: listening ? 'АУДИРОВАНИЕ' : reverse ? 'ВЫБЕРИ ГОРНОМАРИЙСКОЕ СЛОВО' : 'ПЕРЕВЕДИ СЛОВО'
  };
}

function questionsFor(id) {
  const {group, round} = lessons[id];
  return Array.from({length: 5}, (_, step) => {
    const index = (round * 3 + step) % vocab[group].length;
    const mode = step === 2 || step === 4 ? 'listen' : (step + round) % 2 === 1 ? 'mari' : 'translate';
    return makeQuestion(group, index, mode, id * 5 + step);
  });
}

function updateReviewButtons() {
  const count = state.mistakes.length;
  $('mistakeSummary').textContent = count ? 'Заданий для повторения: ' + count : 'Здесь появятся задания, в которых ты ошибся.';
  $('startReview').disabled = count === 0;
  $('reviewFromFinish').classList.toggle('hide', count === 0);
}

function startQuiz(items, isReview, group = null) {
  trial = null;
  reviewing = isReview;
  previewGroup = group;
  $('quizHearts').parentElement.classList.toggle('hide', reviewing || previewGroup !== null);
  questions = items;
  qIndex = 0;
  correct = 0;
  hearts = 5;
  question();
  go('quiz');
}

function start(id) {
  current = id;
  startQuiz(questionsFor(id), false);
}

function startReview() {
  const items = state.mistakes.slice(0, 10).map((key, seed) => {
    const [group, index, mode] = key.split(':');
    return makeQuestion(Number(group), Number(index), mode, seed + 1);
  });
  if (items.length) startQuiz(items, true);
}

function startTrialListening(group) {
  const second = Math.floor(vocab[group].length / 2);
  const items = [0, second].map(index => makeQuestion(group, index, 'listen', group * 11 + index + 2));
  startQuiz(items, false, group);
}

function question() {
  stopAudio();
  selected = -1;
  checked = false;
  const q = questions[qIndex];
  if (q.listening) $('speechStatus').textContent = 'Нажми 🔊, чтобы услышать слово.';
  $('quizBar').style.width = (100 * qIndex / questions.length) + '%';
  $('quizHearts').textContent = hearts;
  const label = reviewing ? 'РАБОТА НАД ОШИБКАМИ'
    : previewGroup !== null ? 'ПРОБНЫЙ УРОК' : '';
  $('quizType').textContent = label ? label + ' · ' + q.type : q.type;
  $('question').textContent = q.question;
  $('feedback').textContent = '';
  $('feedback').style.background = '';
  $('answers').textContent = '';
  q.answers.forEach((answer, index) => {
    const button = document.createElement('button');
    button.className = 'answer';
    button.textContent = answer;
    button.onclick = () => {
      if (checked) return;
      selected = index;
      [...$('answers').children].forEach((node, position) => node.classList.toggle('sel', position === selected));
      $('check').disabled = false;
    };
    $('answers').appendChild(button);
  });
  $('check').disabled = true;
  $('check').textContent = 'ПРОВЕРИТЬ';
}

function advance() {
  if (checked) {
    qIndex++;
    if (qIndex < questions.length && (reviewing || previewGroup !== null || hearts > 0)) question();
    else finish();
    return;
  }
  if (selected < 0) return;
  checked = true;
  const q = questions[qIndex];
  const ok = selected === q.correct;
  if (ok) {
    correct++;
    if (reviewing) state.mistakes = state.mistakes.filter(key => key !== q.key);
  } else {
    if (!reviewing && previewGroup === null) hearts = Math.max(0, hearts - 1);
    // Rotate missed review items to give the remaining queue a turn.
    state.mistakes = state.mistakes.filter(key => key !== q.key);
    state.mistakes.push(q.key);
  }
  persist();
  $('quizHearts').textContent = hearts;
  [...$('answers').children].forEach((button, index) => {
    button.classList.toggle('good', index === q.correct);
    button.classList.toggle('bad', index === selected && !ok);
    button.disabled = true;
  });
  const feedback = ok ? '✅ Правильно!' : '💡 Верный ответ: ' + q.answers[q.correct];
  $('feedback').textContent = q.listening ? feedback + ' · «' + q.word + '»' : feedback;
  $('feedback').style.background = ok ? '#274b29' : '#4a3530';
  $('check').textContent = 'ДАЛЕЕ';
}

function finish() {
  const preview = previewGroup !== null;
  $('lessonArt').classList.toggle('hide', reviewing || preview);
  $('pointsEarned').parentElement.classList.toggle('hide', reviewing || preview);
  $('correctAnswers').textContent = correct + '/' + questions.length;
  if (preview) {
    $('finishTitle').textContent = 'Пробный урок завершён';
    $('finishText').textContent = 'Правильных ответов на слух: ' + correct + ' из ' + questions.length + '.';
  } else if (reviewing) {
    $('finishTitle').textContent = 'Повторение завершено';
    $('finishText').textContent = 'Исправлено: ' + correct + '. Осталось заданий: ' + state.mistakes.length + '.';
  } else {
    $('lessonArt').src = 'lesson-cards/lesson-' + String(current + 1).padStart(3, '0') + '.jpg';
    const win = correct >= 4 && qIndex >= questions.length;
    if (win && !state.completed.includes(current)) state.completed.push(current);
    const points = correct * 10;
    state.xp += points;
    const day = today();
    if (state.lastDay !== day) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      state.streak = state.lastDay === dateKey(yesterday) ? state.streak + 1 : 1;
      state.lastDay = day;
    }
    $('finishTitle').textContent = win ? 'Молодец! 🎉' : 'Попробуй ещё!';
    $('finishText').textContent = win
      ? 'Ты прошёл урок ' + (current + 1) + '. Продолжай в том же духе!'
      : 'Чтобы открыть следующий урок, ответь правильно минимум на 4 из 5 вопросов.';
    $('pointsEarned').textContent = '+' + points;
  }
  persist();
  updateReviewButtons();
  go('finish');
}

$('startReview').onclick = startReview;
$('reviewFromFinish').onclick = startReview;
$('exitQuiz').onclick=()=>go('home');$('check').onclick=advance;$('returnMap').onclick=()=>previewGroup === null ? go('home') : returnToLessons(previewGroup);$('saveName').onclick=()=>{const n=$('nameInput').value.trim().slice(0,26);if(!n){alert('Введи имя ученика');return}state.name=n;persist();renderProfile();updateStats()};
let trial = null;

function updateListen(playing, message) {
  const button = $('listen');
  button.classList.toggle('playing', playing);
  button.textContent = playing ? '⏹ Остановить' : '🔊 Слушать';
  button.setAttribute('aria-label', playing ? 'Остановить озвучку' : 'Прослушать горномарийское слово');
  $('speechStatus').textContent = message;
}

function stopAudio() {
  const playback = activeAudio;
  activeAudio = null;
  if (playback) {
    playback.audio.onended = null;
    playback.audio.onerror = null;
    playback.audio.pause();
    playback.audio.removeAttribute('src');
    URL.revokeObjectURL(playback.url);
  }
  updateListen(false, 'Горномарийская озвучка');
}

$('listen').onclick = () => {
  if (activePage !== 'quiz') return;
  if (activeAudio) {
    stopAudio();
    return;
  }
  const word = trial ? vocab[trial.group][trial.index][0] : questions[qIndex].word;
  const clip = Object.prototype.hasOwnProperty.call(window.KyrykVoiceClips, word) && window.KyrykVoiceClips[word];
  if (!clip) {
    updateListen(false, 'Для этого слова нет озвучки.');
    return;
  }
  const bytes = Uint8Array.from(atob(clip), char => char.charCodeAt(0));
  const url = URL.createObjectURL(new Blob([bytes], {type: 'audio/mpeg'}));
  const player = new Audio(url);
  const playback = {audio: player, url};
  activeAudio = playback;
  player.onended = () => {
    if (activeAudio === playback) stopAudio();
  };
  const failed = () => {
    if (activeAudio !== playback) return;
    stopAudio();
    updateListen(false, 'Не удалось воспроизвести слово. Нажми «Слушать» ещё раз.');
  };
  player.onerror = failed;
  updateListen(true, 'Воспроизводится горномарийское слово');
  // Call play while Safari still has the button's user gesture.
  try {
    const playing = player.play();
    if (playing) playing.catch(failed);
  } catch {
    failed();
  }
};

function startTrial(group) {
  previewGroup = null;
  trial = {group, index: 0};
  go('quiz');
  showTrialWord();
}

function showTrialWord() {
  stopAudio();
  const items = vocab[trial.group];
  const [word, translation] = items[trial.index];
  $('quizBar').style.width = ((trial.index + 1) * 100 / items.length) + '%';
  $('quizHearts').parentElement.classList.add('hide');
  $('quizType').textContent = 'ПРОБНЫЙ УРОК · ' + (trial.index + 1) + ' ИЗ ' + items.length;
  $('question').textContent = word;
  $('answers').textContent = '';
  const meaning = document.createElement('p');
  meaning.className = 'trialTranslation';
  meaning.textContent = translation;
  $('answers').appendChild(meaning);
  $('feedback').textContent = '';
  $('feedback').style.background = '';
  $('check').disabled = false;
  $('check').textContent = trial.index + 1 === items.length ? 'К АУДИРОВАНИЮ' : 'СЛЕДУЮЩЕЕ СЛОВО';
}

function returnToLessons(group) {
  trial = null;
  previewGroup = null;
  go('home');
  document.querySelectorAll('.unit')[group].scrollIntoView({block: 'start'});
}

function advanceOrStudy() {
  if (!trial) {
    advance();
  } else if (trial.index + 1 < vocab[trial.group].length) {
    trial.index++;
    showTrialWord();
  } else {
    startTrialListening(trial.group);
  }
}

$('check').onclick = advanceOrStudy;
$('exitQuiz').onclick = () => {
  const group = trial ? trial.group : previewGroup;
  if (group === null) go('home');
  else returnToLessons(group);
};

document.addEventListener('visibilitychange', () => {
  if (document.hidden) stopAudio();
});
document.querySelectorAll('[data-page]').forEach(button => {
  button.onclick = () => go(button.dataset.page);
});
renderMap();
