// JXA 无头测试：加载游戏逻辑，跑若干次完整流程，检查平衡与崩溃
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
  body:{ insertAdjacentHTML:function(){}, appendChild:function(){} },
  addEventListener:function(){}
};
globalThis.localStorage = { getItem:function(){ return null; }, setItem:function(){}, removeItem:function(){} };

var HTML = '/Users/min/Documents/deepseek-harness/default-workspace/song-exam/北宋赶考记.html';
var html = readFile(HTML);
var m = html.match(/<script>([\s\S]*)<\/script>/);
if (!m) throw new Error('未找到 script 块');
var code = m[1].replace('"use strict";', '');
code += '\n;__G = {QUESTIONS:QUESTIONS,SCENES:SCENES,ACT:ACT,MAX:MAX,startStudy:startStudy,' +
        'answer:answer,continueAfterAnswer:continueAfterAnswer,endDay:endDay,doAct:doAct,' +
        'enterDay:enterDay,finishEnding:finishEnding,failExam:failExam,freshState:freshState,' +
        'setS:function(z){S=z;},getS:function(){return S;}};';
eval(code);
var G = __G;
var MODE = (function(){ try { return ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey('MODE')) || 'balanced'; } catch(e){ return 'balanced'; } })();

function rnd(n){ return Math.floor(Math.random()*n); }
function has(arr, x){ return arr.indexOf(x) >= 0; }

function chooseAction(s){
  var sc = G.SCENES[s.scene];
  var acts = (sc.acts || []).slice();
  var ok = acts.filter(function(id){ var a = G.ACT[id]; return a && a.ap <= s.ap && (!a.can || a.can()); });
  if (!ok.length) return has(acts,'sleep') ? 'sleep' : null;

  function chk(){ return G.getS(); }
  var cur = chk();
  if (has(ok,'enter')) return 'enter';
  if (MODE === 'neglectYuan'){
    if (cur.jing <= 4 && has(ok,'rest')) return 'rest';
    if (has(ok,'study')) return 'study';
    if (has(ok,'rest')) return 'rest';
  }
  if (MODE === 'neglectJing'){
    if (has(ok,'study')) return 'study';
    if (has(ok,'social')) return 'social';
  }
  if (MODE === 'spend'){
    if (has(ok,'social')) return 'social';
    if (has(ok,'rest')) return 'rest';
    if (has(ok,'study')) return 'study';
  }
  if (cur.jing <= 4 && has(ok,'rest')) return 'rest';
  if (cur.money < 20 && has(ok,'sell')) return 'sell';
  if (cur.yuan <= 4 && has(ok,'social')) return 'social';
  if (cur.yuan <= 4 && has(ok,'view')) return 'view';
  if (cur.zhi <= 5 && has(ok,'study')) return 'study';
  if (has(ok,'study')) return 'study';
  if (has(ok,'rest')) return 'rest';
  if (has(ok,'social')) return 'social';
  if (has(ok,'poem')) return 'poem';
  if (has(ok,'copy')) return 'copy';
  if (has(ok,'sell')) return 'sell';
  return has(acts,'sleep') ? 'sleep' : ok[0];
}

function play(skill){
  G.setS(G.freshState());
  var steps = 0, actions = 0, daysSeen = {};
  while (steps++ < 6000){
    var s = G.getS();
    if (s.phase === 'over') break;
    if (s.pending){
      var q = s.pending.q;
      var idx = 'ABCD'.indexOf(q.answer);
      var pick = (Math.random() < skill) ? idx : rnd(4);
      G.answer(pick);
      G.continueAfterAnswer();
      continue;
    }
    if (s.phase === 'play'){
      daysSeen[s.day] = true;
      var id = chooseAction(s);
      if (!id){ G.endDay(); continue; }
      var a = G.ACT[id];
      if (!a) { G.endDay(); continue; }
      if (a.can && !a.can()) { G.endDay(); continue; }
      if (s.ap < a.ap) { G.endDay(); continue; }
      G.doAct(id); actions++;
      continue;
    }
    if (s.phase === 'exam' || s.phase === 'palace'){
      if (!s.pending){
        if (s.phase === 'palace') G.nextPalaceQuestion(); else G.nextExamQuestion();
      }
      continue;
    }
    if (s.phase === 'roundEnd'){ G.endDay(); continue; }
    if (s.phase === 'result'){ if (s.exam.total >= 8) G.endDay(); else G.failExam(); continue; }
    if (s.phase === 'palaceEnd'){ G.finishEnding(); continue; }
    if (s.phase === 'banquet'){ G.finishEnding(); continue; }
    G.endDay();
  }
  var f = G.getS();
  return {
    rank: f.ending ? (f.ending.rank || f.ending.title || '?') : 'STUCK:' + f.phase,
    day: f.day, zhi: f.zhi, jing: f.jing, yuan: f.yuan, money: f.money,
    exam: f.exam.total, palace: f.exam.palace, actions: actions,
    log: (f.log || []).slice(0,3).map(function(x){ return x.d + ':' + x.t; }),
    days: Object.keys(daysSeen).length, steps: steps
  };
}

var out = { runs: 0, ranks: {}, stats: { zhi:0, jing:0, yuan:0, exam:0, day:0 }, stuck: 0, bySkill: {} };
var SKILLS = [0.55, 0.7, 0.85];
for (var si = 0; si < SKILLS.length; si++){
  var sk = SKILLS[si], bucket = { ranks:{}, zhi:0, jing:0, yuan:0, exam:0, n:0 };
  for (var i = 0; i < 60; i++){
    var r = play(sk);
    if (r.rank.indexOf('STUCK') === 0){ out.stuck++; }
    if (r.rank !== '状元' && r.rank !== '一甲进士' && r.rank !== '二甲进士' && r.rank !== '同进士出身' && r.rank !== '特奏名' && r.rank !== '落第'){
      out.deathDays = (out.deathDays || 0) + r.day;
      out.deaths = (out.deaths || 0) + 1;
      out.deathByRank = out.deathByRank || {};
      out.deathByRank[r.rank] = (out.deathByRank[r.rank] || 0) + 1;
      out.deathHist = out.deathHist || {};
      out.deathHist[r.day] = (out.deathHist[r.day] || 0) + 1;
      out.lastLog = out.lastLog || [];
      if (out.lastLog.length < 6) out.lastLog.push({rank:r.rank, day:r.day, zhi:r.zhi, jing:r.jing, yuan:r.yuan, money:r.money, log:r.log});
    }
    bucket.ranks[r.rank] = (bucket.ranks[r.rank] || 0) + 1;
    bucket.zhi += r.zhi; bucket.jing += r.jing; bucket.yuan += r.yuan; bucket.exam += r.exam; bucket.money=(bucket.money||0)+r.money; bucket.n++;
    out.ranks[r.rank] = (out.ranks[r.rank] || 0) + 1;
    out.runs++;
  }
  bucket.avg = { zhi: +(bucket.zhi/bucket.n).toFixed(1), jing: +(bucket.jing/bucket.n).toFixed(1),
                 yuan: +(bucket.yuan/bucket.n).toFixed(1), exam: +(bucket.exam/bucket.n).toFixed(1), money: +((bucket.money||0)/bucket.n).toFixed(1) };
  out.bySkill[sk] = bucket;
}

out.avgDeathDay = out.deaths ? +(out.deathDays/out.deaths).toFixed(1) : null;
JSON.stringify(out, null, 2);
