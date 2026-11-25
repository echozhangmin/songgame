// 数据与规则守卫（osascript -l JavaScript data_test.js）
// 不测玩法体验，只测"数据不能坏、史实不能穿越、旧档不能读崩"这三类事。
ObjC.import('Foundation');

function readFile(p){
  var s = $.NSString.stringWithContentsOfFileEncodingError(p, $.NSUTF8StringEncoding, null);
  if (!s) throw new Error('读不到文件：' + p);
  return ObjC.unwrap(s);
}
function mkEl(){
  return { innerHTML:'', remove:function(){}, appendChild:function(){},
           insertAdjacentHTML:function(){}, addEventListener:function(){},
           setAttribute:function(){}, querySelector:function(){ return null; },
           focus:function(){}, dataset:{}, style:{}, className:'', disabled:false };
}
var STORE = {};
globalThis.document = {
  getElementById:function(){ return mkEl(); },
  createElement:function(){ return mkEl(); },
  body:{ insertAdjacentHTML:function(){}, appendChild:function(){} },
  addEventListener:function(){}
};
globalThis.localStorage = {
  getItem:function(k){ return Object.prototype.hasOwnProperty.call(STORE, k) ? STORE[k] : null; },
  setItem:function(k, v){ STORE[k] = String(v); },
  removeItem:function(k){ delete STORE[k]; }
};

var PWD = ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey('PWD')) || '.';
var html = readFile(PWD + '/北宋赶考记.html');

var checks = 0, fail = 0;
function ok(cond, name){
  checks++;
  console.log((cond ? 'PASS' : 'FAIL') + '  ' + name);
  if (!cond) fail++;
}

/* ---------- 1. 构建产物 ---------- */
['__QUESTIONS__', '__GLOSSARY__', '__SCENE_BG__', '__SCENE_ART__', '__SCROLL_IMG__'].forEach(function(token){
  ok(html.indexOf(token) < 0, '构建产物没有残留占位符 ' + token);
});
ok(html.indexOf('data:image/jpeg;base64,') > 0, '单文件版仍内嵌图片（可离线双击）');
ok(html.indexOf('rel="icon"') > 0, '有 favicon（避免 E2E 吃 404）');

/* ---------- 2. 题库 ---------- */
var Q = JSON.parse(readFile(PWD + '/data/quiz_150.json'));
var ERAS = {'先秦':1, '秦汉':1, '魏晋南北朝':1, '隋唐':1, '五代与北宋':1};
ok(Q.length === 150, '题库 150 条（实为 ' + Q.length + '）');
var ids = {}, stems = {}, badAnswer = [], badEra = [], badOpts = [], dupId = [], dupStem = [];
Q.forEach(function(q){
  if (ids[q.id]) dupId.push(q.id); ids[q.id] = 1;
  if (stems[q.stem]) dupStem.push(q.id); stems[q.stem] = 1;
  if (!q.options || !q.options[q.answer]) badAnswer.push(q.id);
  if (!ERAS[q.era]) badEra.push(q.id);
  if (Object.keys(q.options || {}).length !== 4) badOpts.push(q.id);
});
ok(dupId.length === 0, '题号不重复' + (dupId.length ? '：' + dupId.join(',') : ''));
ok(dupStem.length === 0, '题干不重复' + (dupStem.length ? '：' + dupStem.join(',') : ''));
ok(badAnswer.length === 0, '答案都在选项内' + (badAnswer.length ? '：' + badAnswer.join(',') : ''));
ok(badEra.length === 0, '朝代标签合法' + (badEra.length ? '：' + badEra.join(',') : ''));
ok(badOpts.length === 0, '每题四个选项' + (badOpts.length ? '：' + badOpts.join(',') : ''));

var late = Q.filter(function(q){ return q.afterCutoff; });
ok(late.length === 6, '已标注 6 道"晚于 1057"的题（实为 ' + late.length + '）');
ok(late.every(function(q){ return q.afterCutoff > 1057; }),
   'afterCutoff 必须晚于嘉祐二年：' + late.map(function(q){ return q.id + '=' + q.afterCutoff; }).join(' '));

/* ---------- 3. 抽题池排除穿越题 ---------- */
var m = html.match(/<script>([\s\S]*)<\/script>/);
var code = m[1].replace('"use strict";', '');
code += '\n;__T = {QUESTIONS:QUESTIONS, GLOSSARY:GLOSSARY, EXAM_POOLS:EXAM_POOLS, usable:usable,' +
        ' CUTOFF_YEAR:CUTOFF_YEAR, SCENES:SCENES, POEM_THEMES:POEM_THEMES, THEME_WORDS:THEME_WORDS,' +
        ' DIALOGUES:DIALOGUES, NPCS:NPCS, SAVE_KEY:SAVE_KEY, SAVE_VERSION:SAVE_VERSION,' +
        ' freshState:freshState, loadGame:loadGame, saveGame:saveGame,' +
        ' startStudy:startStudy, answer:answer, continueAfterAnswer:continueAfterAnswer,' +
        ' setS:function(z){S=z;}, getS:function(){return S;}};';
eval(code);
var T = __T;

ok(T.CUTOFF_YEAR === 1057, '游戏内截断年为 1057');
T.EXAM_POOLS.forEach(function(pool, i){
  var leaked = Q.filter(function(q){ return q.afterCutoff && pool(q); }).map(function(q){ return q.id; });
  ok(leaked.length === 0, '第 ' + (i + 1) + ' 场抽题池不含穿越题' + (leaked.length ? '：' + leaked.join(',') : ''));
});
ok(late.every(function(q){ return !T.usable(q); }), 'usable() 拒绝所有 afterCutoff 题');
var legal = T.QUESTIONS.filter(function(q){ return T.usable(q); });
ok(legal.length === T.QUESTIONS.length - 6, '可用题数 = 150 - 6（实为 ' + legal.length + '）');

/* ---------- 4. 词条：出处与据/推断/设 ---------- */
var G = JSON.parse(readFile(PWD + '/data/glossary.json'));
var names = Object.keys(G);
var NO_SRC = [], BAD_TAG = [], TAG_MISMATCH = [], NO_DEF = [];
names.forEach(function(k){
  var g = G[k];
  if (!g.def) NO_DEF.push(k);
  if (!g.src || !g.src.length) NO_SRC.push(k);
  if (['据', '推断', '设'].indexOf(g.tag) < 0) BAD_TAG.push(k);
  var hasQuote = (g.src || []).some(function(s){ return s.quote; });
  if (hasQuote && g.tag !== '据') TAG_MISMATCH.push(k);
  if (!hasQuote && g.tag === '据') TAG_MISMATCH.push(k);
});
ok(names.length === 57, '词条 57 条（实为 ' + names.length + '）');
ok(NO_DEF.length === 0, '每条都有释义' + (NO_DEF.length ? '：' + NO_DEF.join(',') : ''));
ok(NO_SRC.length === 0, '每条都有出处' + (NO_SRC.length ? '：' + NO_SRC.join(',') : ''));
ok(BAD_TAG.length === 0, '每条都标了据/推断/设' + (BAD_TAG.length ? '：' + BAD_TAG.join(',') : ''));
ok(TAG_MISMATCH.length === 0, '有原文者标"据"、无原文者不标"据"' + (TAG_MISMATCH.length ? '：' + TAG_MISMATCH.join(',') : ''));
var tiers = {据:0, 推断:0, 设:0};
names.forEach(function(k){ tiers[G[k].tag]++; });
ok(tiers['据'] === 5 && tiers['设'] === 3, '三档齐全：据 ' + tiers['据'] + ' · 推断 ' + tiers['推断'] + ' · 设 ' + tiers['设']);
ok(T.GLOSSARY && Object.keys(T.GLOSSARY).length === names.length, '构建产物里的词条数与源文件一致');

/* ---------- 5. 场景、题诗、人物 ---------- */
var sceneIds = T.SCENES.map(function(s){ return s.id; });
ok(sceneIds.length === 12, '十二幕（实为 ' + sceneIds.length + '）');
ok(T.POEM_THEMES.length === 18, '十八个题诗题材（实为 ' + T.POEM_THEMES.length + '）');
var themeKeys = T.POEM_THEMES.map(function(t){ return t.key; });
ok(themeKeys.every(function(k){ return T.THEME_WORDS[k]; }), '每个题材都有题眼字表');
ok(T.POEM_THEMES.every(function(t){ return t.ex && t.ex.length > 0; }), '每个题材都有示范诗');
var masters = Object.keys(T.NPCS).filter(function(k){ return T.NPCS[k].tier === 'master'; });
ok(masters.length === 5, '五位大儒（实为 ' + masters.length + '）');
ok(masters.every(function(k){ return T.DIALOGUES[k] && T.DIALOGUES[k].topics && T.DIALOGUES[k].topics.length > 0; }), '每位大儒都有座谈话题');

/* ---------- 6. 错题本：温书优先重练答错的题 ---------- */
T.setS(T.freshState());
T.startStudy();
var wq = T.getS().pending.q;
var rightIdx = 'ABCD'.indexOf(wq.answer);
var wrongIdx = [0, 1, 2, 3].filter(function(i){ return i !== rightIdx; })[0];
T.answer(wrongIdx);
T.continueAfterAnswer();
ok(T.getS().wrong.indexOf(wq.id) >= 0, '答错的温书题记入错题本');
T.startStudy();
ok(T.getS().pending.q.id === wq.id, '下次温书优先抽这道错题');
T.answer('ABCD'.indexOf(T.getS().pending.q.answer));
T.continueAfterAnswer();
ok(T.getS().wrong.length === 0, '答对后移出错题本');

/* ---------- 7. 旧档迁移 ---------- */
var oldSave = {day:12, scene:5, ap:4, zhi:7, jing:6, yuan:5, money:20, phase:'play',
               flags:{gift:null, master:0, rumor:false, entered:false},
               maintained:{zhi:false, jing:false, yuan:false}, log:[], met:[], poems:[]};
STORE[T.SAVE_KEY] = JSON.stringify(oldSave);
var loaded = T.loadGame();
ok(loaded && loaded.day === 12, '旧档（无 v、缺 talked/safe）能读入');
ok(loaded && loaded.talked && typeof loaded.talked === 'object', '旧档补齐 talked，拜访大儒不再抛错');
ok(loaded && loaded.safe && loaded.safe.shan === false, '旧档补齐 safe');
ok(loaded && Array.isArray(loaded.poemUsed), '旧档补齐 poemUsed');
ok(loaded && Array.isArray(loaded.wrong), '旧档补齐 wrong（错题本）');

STORE[T.SAVE_KEY] = JSON.stringify({v: T.SAVE_VERSION + 9, day: 3, scene: 0, phase: 'play'});
ok(T.loadGame() === null, '未来版本存档读入为 null（宁可不读，不读坏）');

T.setS(T.freshState());
T.getS().day = 9; T.getS().money = 33;
T.saveGame();
var parsed = JSON.parse(STORE[T.SAVE_KEY]);
ok(parsed.v === T.SAVE_VERSION && parsed.day === 9, '存档写入版本号与当前进度（v' + parsed.v + '）');
var back = T.loadGame();
ok(back && back.day === 9 && back.money === 33, '存档读回进度不丢');

console.log(fail === 0
  ? '== 数据与规则守卫通过：' + checks + ' 条断言 =='
  : ('== ' + fail + ' / ' + checks + ' 处 FAIL =='));
if (fail) throw new Error(fail + ' 处断言失败');
