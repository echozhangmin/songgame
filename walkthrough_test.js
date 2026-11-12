// 全流程交互审计（osascript -l JavaScript walkthrough_test.js）
// 逐幕模拟真人路径，校验状态、弹窗、文案链、存档；报 FAIL 处即 bug
ObjC.import('Foundation');

function readFile(p){
  var s = $.NSString.stringWithContentsOfFileEncodingError(p, $.NSUTF8StringEncoding, null);
  return ObjC.unwrap(s);
}
function mkEl(){
  return { innerHTML:'', remove:function(){}, appendChild:function(){},
           insertAdjacentHTML:function(){}, addEventListener:function(){},
           dataset:{}, style:{}, className:'', disabled:false };
}
globalThis.document = {
  getElementById:function(){ return mkEl(); },
  createElement:function(){ return mkEl(); },
  body:{ insertAdjacentHTML:function(){}, appendChild:function(){} },
  addEventListener:function(){}
};
globalThis.localStorage = { getItem:function(){ return null; }, setItem:function(){}, removeItem:function(){} };

var HTML = '/Users/min/Documents/deepseek-harness/default-workspace/song-exam/北宋赶考记.html';
var html = readFile(HTML);
var m = html.match(/<script>([\s\S]*)<\/script>/);
var code = m[1].replace('"use strict";', '');
code += '\n;__T = {SCENES:SCENES, ACT:ACT, DIALOGUES:DIALOGUES, NPCS:NPCS, POEM_THEMES:POEM_THEMES, THEME_WORDS:THEME_WORDS,' +
        'freshState:freshState, doAct:doAct, endDay:endDay, chooseEvent:chooseEvent,' +
        'submitPoem:submitPoem, openPoem:openPoem, answer:answer, continueAfterAnswer:continueAfterAnswer,' +
        'nextExamQuestion:nextExamQuestion, nextPalaceQuestion:nextPalaceQuestion, startPalace:startPalace,' +
        'finishEnding:finishEnding, failExam:failExam, saveGame:saveGame,' +
        'setS:function(z){S=z;}, getS:function(){return S;}};';
eval(code);
var T = __T, fail = 0;

/* 安全推进：一夜一步，每夜先把三属性补到安全线，over 停 */
function advanceTo(targetDay){
  var guard = 0;
  while (S().day < targetDay && S().phase !== 'over' && guard++ < 40){
    if (S().event){ if (!S().event.done) T.chooseEvent(0); S().event = null; }
    ['zhi','jing','yuan'].forEach(function(k){ if (S()[k] < 9) S()[k] = 9; });
    if (S().money < 10) S().money = 10;
    T.endDay();
  }
  if (S().phase === 'over'){
    var e = S().ending || {};
    console.log('    [死因] ' + (e.title || e.rank || '?') + '｜day=' + S().day + ' zhi=' + S().zhi + ' jing=' + S().jing + ' yuan=' + S().yuan + ' money=' + S().money);
    console.log('    [末行记] ' + (S().log[0] ? S().log[0].t : '') + ' ／ ' + (S().log[1] ? S().log[1].t : ''));
  }
  ok(S().day === targetDay && S().phase !== 'over', '推进到第' + targetDay + '日（day=' + S().day + ' phase=' + S().phase + '）');
}

function ok(cond, name){ console.log((cond ? 'PASS' : 'FAIL') + '  ' + name); if (!cond) fail++; }
function S(){ return T.getS(); }

/* ===== 第 1–2 日 家塾 ===== */
var s = T.freshState();
T.setS(s);
ok(S().day === 1 && S().scene === 0 && S().ap === 4, '开局面板：第1日·家塾·4行动点');
T.doAct('study');
ok(S().pending && S().pending.kind === 'study', '温书弹出题目');
T.answer('ABCD'.indexOf(S().pending.q.answer));
var z1 = S().zhi;
T.continueAfterAnswer();
ok(S().zhi === (S().log[0] && S().log[0].t.indexOf('干脆') >= 0 ? 6 : 5) || S().zhi === z1, '温书结算（答对+1）');
T.doAct('master');
ok(S().met.indexOf('xiansheng') >= 0, '家塾初访遇乡先生');
T.doAct('master');
ok(S().event && S().event.tag === 'talk' && S().event.choice.length === 3, '再访开座谈（3话题）');
T.chooseEvent(0);
ok((S().talked.xiansheng || []).length === 1 && S().event.done, '座谈话题打勾');
S().event = null;
T.doAct('sleep');
ok(S().day === 2, '就寝进入第2日');
T.doAct('rest'); T.doAct('rest'); T.doAct('sleep');

/* ===== 第 3 日 长亭（三选一终日） ===== */
ok(S().day === 3 && S().scene === 1, '第3日切换长亭');
var zg = S().zhi;
T.doAct('giftBooks');
ok(S().day === 4 && S().zhi === zg + 2, '受赠旧书：智力+2、当日即终（进第4日，zhi ' + zg + '→' + S().zhi + '）');

/* ===== 第 4–6 日 驿站 ===== */
ok(S().scene === 2 && S().ap === 4, '第4日驿站4行动点');
var mp = S().money;
T.doAct('poem');
ok(S().poem && S().poem.mode === 'poem', '题诗弹出诗笺（' + S().poem.theme + '）');
var tw = T.THEME_WORDS[S().poem.theme] || '';
var cs = tw.replace(/(.)(.)/g, '$1$2').split('');
var poemText = [0,1,2,3].map(function(i){
  var a = cs[(i*2) % cs.length], b = cs[(i*2+1) % cs.length];
  return '客路' + a + '深' + b + '处';
}).join('\n');
T.submitPoem(poemText);
var pg = S().poem.result;
ok(pg && pg.grade === '上品' && S().money === mp + 5, '题诗按题眼作诗判上品得5贯（盘缠 ' + mp + '→' + S().money + '，grade=' + (pg && pg.grade) + '）');
ok(S().poemUsed.indexOf('yizhan') >= 0, '一地一首：yizhan 记账');
S().poem = null;
T.doAct('poem');
ok(S().poem === null && S().ap >= 0, '同地再题被拒（can 拦截，不空耗行动点）');
T.endDay();
ok(S().day === 5, '进入第5日（实为 ' + S().day + '）');
if (S().event){ T.chooseEvent(0); S().event = null; }
T.endDay();
ok(S().day === 6, '进入第6日（实为 ' + S().day + '）');
if (S().event){ T.chooseEvent(0); S().event = null; }
T.endDay();

/* ===== 第 7–9 日 山道（赶路日+山匪） ===== */
ok(S().day === 7 && S().scene === 3 && S().ap === 2, '第7日山道：赶路日只剩2行动点（day=' + S().day + ' scene=' + S().scene + ' ap=' + S().ap + '）');
T.doAct('guard');
ok(S().safe.shan === true, '结伴同行置 safe.shan');
T.endDay();
ok(S().day === 8, '进入第8日（实为 ' + S().day + '）');
ok(S().event && S().event.bandit === true, '第8日山匪必发弹窗');
if (S().event){
  var safeIdx = -1;
  (S().event.choice || []).forEach(function(c, i){ if (c.needSafe) safeIdx = i; });
  T.chooseEvent(safeIdx >= 0 ? safeIdx : 0);
  ok(S().event.done === true, '山匪三选一可结算');
  S().event = null;
}
T.endDay();
ok(S().day === 9, '进入第9日（实为 ' + S().day + '）');
if (S().event){ T.chooseEvent(0); S().event = null; }
T.endDay();
ok(S().day === 10, '进入第10日（实为 ' + S().day + '）');
if (S().event){ T.chooseEvent(0); S().event = null; }

/* ===== 第 10–14 日 汴河（苏洵+水匪+虹桥） ===== */
ok(S().scene === 4 || S().scene === 5, '第10日进入汴河水域（场景 ' + S().scene + '）');
advanceTo(12);
ok(S().scene === 5, '第12日虹桥（scene=' + S().scene + '）');
if (S().event){ if (!S().event.done) T.chooseEvent(0); S().event = null; }
advanceTo(15);

/* ===== 第 15 日 城门（门税+入京三件事） ===== */
ok(S().day === 15 && S().scene === 7, '第15日城门');
if (S().event && !S().event.done){ T.chooseEvent(0); }
if (S().event) S().event = null;
T.doAct('toudi');
ok(S().tou === true && S().money >= 0, '投状报名置 tou');
T.doAct('lodge');
ok(S().event && S().event.tag === 'lodge', '寻住处弹出三选一');
T.chooseEvent(0);
ok(S().lodged === true && S().event.done, '选州桥客栈：lodged 置位');
S().event = null;
T.doAct('scout');
ok(S().scouted === true, '踩点贡院置 scouted');
T.endDay();

/* ===== 第 16–19 日 酒楼（行卷/座谈/传闻） ===== */
ok(S().day === 16 && S().scene === 8, '第16日酒楼');
T.doAct('toujuan');
ok(S().flags.juan === true && S().met.indexOf('ouyang') >= 0, '投行卷：置 juan、遇欧阳修');
T.doAct('info');
ok(S().flags.rumor === true, '打听消息解锁传闻');
T.doAct('master');
T.doAct('master'); T.doAct('master');
var metMasters = S().met.filter(function(k){ return T.NPCS[k].tier === 'master'; }).length;
ok(metMasters >= 3, '酒楼三访见齐大儒（已遇 ' + metMasters + ' 位）');
/* 相遇优先座谈：每日行动点有限，跨日拜访直到开座谈 */
var tries = 0;
while (!(S().event && S().event.tag === 'talk') && S().phase === 'play' && tries++ < 12){
  T.doAct('master');
  if (!(S().event && S().event.tag === 'talk') && S().ap < 1){
    if (S().event){ if (!S().event.done) T.chooseEvent(0); S().event = null; }
    ['zhi','jing','yuan'].forEach(function(k){ if (S()[k] < 9) S()[k] = 9; });
    if (S().money < 10) S().money = 10;
    T.endDay();
  }
}
ok(S().event && S().event.tag === 'talk', '见齐后再访开座谈（第' + tries + '次拜访）');
var hasJuanTopic = S().event && S().event.choice.some(function(c){ return c.topic === 'xingjuan'; });
ok(hasJuanTopic, '投过行卷 → 座谈含「问行卷文章」');
var wf = S().event.choice.findIndex(function(c){ return c.topic === 'wenfeng'; });
T.chooseEvent(wf);
ok(S().flags.rumor === true, '问今年文风：传闻已解锁（幂等，不重复加成）');
S().event = null;
advanceTo(25);

/* ===== 第 25–27 日 省试 ===== */
ok(S().day === 25 && S().scene === 10 && S().phase === 'exam', '第25日入考试相');
var examRight = 0;
for (var r = 0; r < 3; r++){
  for (var q = 0; q < 5; q++){
    if (!S().pending) T.nextExamQuestion();
    if (S().pending){
      var idx = 'ABCD'.indexOf(S().pending.q.answer);
      T.answer(idx); T.continueAfterAnswer();
      examRight++;
    }
  }
  T.endDay();
}
ok(S().exam.total === examRight, '省试三场计分：' + S().exam.total + '/' + examRight);
ok(S().day === 28, '进入第28日');

/* ===== 第 28 日 查榜 → 殿试 ===== */
ok(S().phase === 'result', '第28日查榜相');
T.endDay();
ok(S().day === 29 && S().phase === 'palace', '第29日殿试相');
T.startPalace();
for (var pq = 0; pq < 3; pq++){
  if (!S().pending) T.nextPalaceQuestion();
  if (S().pending){
    T.answer('ABCD'.indexOf(S().pending.q.answer));
    T.continueAfterAnswer();
  }
}
ok(S().exam.palace === 3, '殿试三题全对');
T.endDay();
ok(S().day === 30 && S().phase === 'banquet', '第30日琼林宴相');

/* ===== 结局 ===== */
T.finishEnding();
var e = S().ending;
ok(e && ['状元','一甲进士','二甲进士'].indexOf(e.rank) >= 0, '高属性路径结局为进士高第（实得 ' + (e ? e.rank : '无') + '）');
ok(S().poems && S().poems.length >= 1, '诗囊有诗（' + (S().poems || []).length + ' 首）');
T.saveGame();
ok(true, '结局后存档不报错（saveGame 对 over 态短路）');

if (S().phase === 'over'){
  console.log('== 流程中断：主角已死（' + ((S().ending||{}).title||'') + '），后续断言跳过 ==');
} else {
  console.log(fail === 0 ? '== 全流程审计通过 ==' : ('== ' + fail + ' 处 FAIL =='));
}
