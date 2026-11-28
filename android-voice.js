window.KyrykVoice = (function () {
const vowels = {'а':'a','ӓ':'&','е':'e','э':'e','и':'i','о':'o','ӧ':'Y','у':'u','ӱ':'y','ӹ':'@','ы':'8'};
const consonants = {'б':'b','в':'B','г':'g','д':'d','ж':'Z','з':'z','й':'j','к':'k','л':'l','м':'m','н':'n','п':'p','р':'R','с':'s','т':'t','ф':'f','х':'x','ц':'ts','ч':'tS','ш':'S','щ':'s^s^'};
const palatal = {'t':'t^','n':'n^','l':'l^','s':'s^'};
const iotated = {'я':'а','ю':'у','ё':'о'};
const loanStress = {'компьютер':1,'кофе':0,'шоколад':2,'апельсин':2};

// Hill Mari sound inventory and stress rules from Riese et al. (pp. 43–50).
function wordPhonemes(word) {
  const phones = [];
  const syllables = [];
  const letters = Array.from(word);
  for (let i = 0; i < letters.length; i++) {
    let letter = letters[i];
    if (letter === 'ь' || letter === 'ъ') {
      const last = phones.length - 1;
      if (letter === 'ь' && palatal[phones[last]]) phones[last] = palatal[phones[last]];
      continue;
    }
    if (iotated[letter]) {
      if (letter === 'я' && letters[i - 1] === 'т' && word.includes('ӓ')) {
        phones[phones.length - 1] = 'c';
        letter = 'ӓ';
      } else {
        phones.push('j');
        letter = iotated[letter];
      }
    }
    if (vowels[letter]) {
      syllables.push({position: phones.length, reduced: letter === 'ы' || letter === 'ӹ'});
      phones.push(vowels[letter]);
    } else if (letter === 'н' && letters[i + 1] === 'г') {
      phones.push('N');
    } else if (consonants[letter]) {
      phones.push(consonants[letter]);
    }
  }
  if (!syllables.length) return '';
  let stress = Math.max(0, syllables.length - 2);
  if (stress > 0 && syllables[stress].reduced && !syllables[stress - 1].reduced) stress--;
  stress = Object.prototype.hasOwnProperty.call(loanStress, word) ? loanStress[word] : stress;
  const position = syllables[stress].position;
  phones[position] = "'" + phones[position];
  return phones.join('');
}

function transcribe(text) {
  return '[[' + text.normalize('NFC').toLowerCase().split(/[^а-яёӓӧӱӹ]+/u).map(wordPhonemes).filter(Boolean).join(' ') + ']]';
}


  let engine;
  let calls = 0;
  function resetEngine() {
    engine = window.createKyrykSynthesizer();
    calls = 0;
  }

  return {transcribe, synthesize: function (text) {
    const phrase = transcribe(text);
    if (phrase === '[[]]') throw new Error('No letters to read');
    const words = phrase.slice(2, -2).split(' ');
    const connectedSpeech = words.length > 1;
    const syllables = (text.toLowerCase().match(/[аӓеёиоуӧӱыӹэюя]/g) || []).length;
    const speed = connectedSpeech ? 146 : Math.min(158, 137 + 6 * syllables);
    const boundary = /[?!]$/.test(text.trim()) ? text.trim().slice(-1) : '.';
    const options = {
      voice: 'fi',
      variant: 'm3',
      pitch: connectedSpeech ? 54 : 48,
      speed,
      wordgap: connectedSpeech ? 2 : 0,
      rawdata: 'base64'
    };
    if (!engine || calls >= 16) resetEngine();
    calls++;
    let wav;
    try {
      wav = engine.speak(phrase + boundary, options);
    } catch {
      // Retry with a fresh instance below.
    }
    if (!wav || wav.length < 160 || !wav.startsWith('UklGR')) {
      resetEngine();
      calls++;
      wav = engine.speak(phrase + boundary, options);
    }
    if (!wav || wav.length < 160 || !wav.startsWith('UklGR')) throw new Error('No audio synthesized');
    return wav;
  }};
})();
