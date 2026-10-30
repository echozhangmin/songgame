// 生成静态快照（用 JXA 跑游戏脚本，把渲染结果落成 HTML），便于在无浏览器环境下核对版式
ObjC.import('Foundation');

function readFile(p){
  var s = $.NSString.stringWithContentsOfFileEncodingError(p, $.NSUTF8StringEncoding, null);
  return ObjC.unwrap(s);
}
function writeFile(p, s){
  var str = $(s);
  str.writeToFileAtomicallyEncodingError(p, true, $.NSUTF8StringEncoding, null);
}

var DIR = '/Users/min/Documents/deepseek-harness/default-workspace/song-exam/';
var html = readFile(DIR + '北宋赶考记.html');
var css = html.match(/<style>([\s\S]*?)<\/style>/)[1];
var code = html.match(/<script>([\s\S]*)<\/script>/)[1].replace('"use strict";', '');

var els = {};
function mkEl(id){
  return {
    id:id, innerHTML:'', remove:function(){ els[id]._removed = true; },
    appendChild:function(){}, insertAdjacentHTML:function(p,h){ els[id]._extra = (els[id]._extra||'') + h; },
    addEventListener:function(){}, dataset:{}, style:{}, className:'', disabled:false
  };
}
globalThis.document = {
  getElementById:function(id){ if(!els[id]) els[id] = mkEl(id); return els[id]; },
  body:{ insertAdjacentHTML:function(pos,h){ els.__body = (els.__body||'') + h; }, appendChild:function(){} },
  addEventListener:function(){}
};
globalThis.localStorage = { getItem:function(){return null;}, setItem:function(){}, removeItem:function(){} };

code += '\n;__G = {freshState:freshState, setS:function(z){S=z;}, getS:function(){return S;},' +
        'render:render, startStudy:startStudy, enterDay:enterDay, finishEnding:finishEnding,' +
        'startExamRound:startExamRound, endDay:endDay, answer:answer, doAct:doAct,' +
        'openPoem:openPoem, submitPoem:submitPoem, chooseEvent:chooseEvent};';
eval(code);
var G = __G;

function reset(){
  for (var k in els) delete els[k];
  G.setS(G.freshState());
}
function snapshot(name){
  G.render();
  var app = (els['app'] && els['app'].innerHTML) || '';
  var overlays = (els.__body || '');
  var doc = '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">' +
            '<style>' + css + '</style></head><body><div id="app">' + app + '</div>' + overlays + '</body></html>';
  writeFile(DIR + 'snap-' + name + '.html', doc);
}

// 0 起始页（boot 已把 phase 置为 title）
snapshot('00-title');

// 1 开场
reset(); snapshot('01-open');

// 2 温书答题
reset();
G.doAct('study');
snapshot('02-study');

// 3 省试
reset();
var s = G.getS(); s.day = 25; s.scene = 8; s.ap = 4; s.phase = 'exam';
G.startExamRound();
snapshot('03-exam');

// 4 凡例
reset();
var s4 = G.getS(); s4.help = true;
G.render();
snapshot('05-help');

// 5 酒楼
reset();
var s5 = G.getS(); s5.day = 17; s5.scene = 6; s5.ap = 4; s5.money = 42; s5.zhi = 8; s5.jing = 6; s5.yuan = 5;
G.enterDay();
snapshot('06-jiulou');

// 6 题诗对话框
reset();
var s6 = G.getS(); s6.day = 5; s6.scene = 2; s6.money = 52;
G.doAct('poem');
snapshot('07-poem');

// 7 题诗评语
G.submitPoem('空山新雨后\n天气晚来秋\n明月松间照\n清泉石上流');
G.render();
snapshot('08-poem-result');

// 8 人物相遇
reset();
var s8 = G.getS(); s8.day = 17; s8.scene = 6; s8.ap = 4; s8.money = 40;
G.doAct('social');
G.doAct('social');
G.doAct('master');
snapshot('09-npc');

// 8.5 支线事件（选择）
reset();
var s85 = G.getS(); s85.day = 7; s85.scene = 3; s85.ap = 2; s85.money = 42;
s85.event = { title: '山 寺', text: '山寺老僧留你吃茶。他说：“心不定，文不工。”',
  choice: [
    { label: '听他说法（精力 +1）', cost: {}, gain: { jing: 1 }, msg: '你静坐一炷香，心里果然定了些。' },
    { label: '捐两贯香火（盘缠 -2，人缘 +1）', cost: { money: 2 }, gain: { yuan: 1 }, msg: '老僧合掌，替你写了一纸荐书。' }
  ], done: false };
G.render();
snapshot('11-event');

// 8.6 山匪遭遇
reset();
var s86 = G.getS(); s86.day = 8; s86.scene = 3; s86.ap = 3; s86.money = 40;
s86.event = { title: '山 匪',
  text: '转过山坳，林中忽然闪出四五条汉子，横着扁担拦在路心。为首的斜眼打量你的书箱：“举子？书箱里可有值钱的？”',
  choice: [
    { label: '舍财免灾（盘缠 -2）', cost: { money: 2 }, msg: '你把两贯钱递过去。他们掂了掂，骂了句晦气，让开了路。' },
    { label: '拼命护箱（精力 -2）', cost: { jing: 2 }, msg: '你抱紧书箱撞开一人，跌跌撞撞跑出半里地，膝头全是血。' },
    { label: '与同行者并作一处（需先“结伴同行”）', needSafe: true, gain: { yuan: 1 }, msg: '你一声呼哨，前后赶路的举子、挑夫都围拢来。' }
  ], done: false, safeKey: 'shan' };
G.render();
snapshot('12-bandit');

// 8.7 词条释义
reset();
var s87 = G.getS(); s87.phase = 'play'; s87.day = 3; s87.scene = 1;
s87.gloss = '程仪';
G.render();
snapshot('13-gloss');

// 8.8 词条索引
reset();
var s88 = G.getS(); s88.phase = 'play'; s88.glossIndex = true;
G.render();
snapshot('14-index');

// 9 省试前夜的短笺
reset();
var s9 = G.getS();
s9.day = 24; s9.scene = 8; s9.zhi = 8; s9.yuan = 6; s9.money = 20; s9.ap = 4;
s9.flags.juan = true; s9.maintained = {zhi:true, jing:true, yuan:true};
G.endDay();
snapshot('10-letter');

// 10 结局
reset();
var s2 = G.getS(); s2.exam.total = 13; s2.exam.palace = 3; s2.zhi = 9; s2.yuan = 8; s2.jing = 9;
G.finishEnding();
snapshot('04-ending');

'ok';
