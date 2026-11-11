// 大儒座谈用例（osascript -l JavaScript dialogue_test.js）
// 机制：拜访大儒 → 已相遇者开座谈；每次选一个话题（追问并入回复）；谈尽回落 MASTER_LINES
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
code += '\n;__T = {DIALOGUES:DIALOGUES, NPCS:NPCS, SCENES:SCENES, freshState:freshState,' +
        'doAct:doAct, chooseEvent:chooseEvent,' +
        'setS:function(z){S=z;}, getS:function(){return S;}};';
eval(code);
var T = __T, fail = 0;
function ok(cond, name){ console.log((cond ? 'PASS' : 'FAIL') + '  ' + name); if (!cond) fail++; }

/* 一、结构校验 */
var total = 0, keys = Object.keys(T.DIALOGUES);
keys.forEach(function(k){
  var d = T.DIALOGUES[k];
  ok(T.NPCS[k] && T.NPCS[k].tier === 'master', '人物 '+k+' 是大儒且在场表内');
  d.topics.forEach(function(t){
    total++;
    ok(!!t.id && !!t.label && !!t.reply, k+'.'+t.id+' 字段齐全');
    var g = t.gain || {};
    ok(Object.keys(g).every(function(x){ return ['zhi','yuan'].indexOf(x) >= 0; }), k+'.'+t.id+' 效果键合法');
    if (t.ask) ok(!!t.follow, k+'.'+t.id+' 追问有答');
  });
});
ok(total === 15, '话题总数 15（实为 ' + total + '）');

/* 二、酒楼座谈（三位已遇，未投行卷 → 9 个话题；多人时标签带名） */
var S = T.freshState();
S.day = 17; S.scene = 8; S.met = ['ouyang','meiyaochen','simaguang']; S.ap = 4; S.yuan = 5;
T.setS(S);
T.doAct('master');
S = T.getS();
ok(S.event && S.event.tag === 'talk', '拜访开座谈弹窗');
ok(S.event && S.event.choice.length === 8, '未投行卷 → 8 个话题（问行卷文章被 needJuan 挡掉；实为 ' + (S.event ? S.event.choice.length : 0) + '）');
ok(S.event && S.event.choice[0].label.indexOf('欧阳修 ·') === 0, '多人在场时标签带名');
T.chooseEvent(0);
S = T.getS();
ok(S.event.done === true, '选定话题后弹窗转完成态');
ok((S.talked.ouyang || []).indexOf('wenfeng') >= 0, '话题打勾进 talked');
ok(S.flags.rumor === true, '问今年文风 → 解锁主司传闻');
ok(S.zhi === 7, '基础 +1 与话题 +1 都入账（智力 5→7，实为 ' + S.zhi + '）');

/* 三、投过行卷 → 欧阳修多出「问行卷文章」 */
S = T.freshState();
S.day = 17; S.scene = 8; S.met = ['ouyang','meiyaochen','simaguang']; S.ap = 4; S.yuan = 5;
S.flags.juan = true;
T.setS(S);
T.doAct('master');
S = T.getS();
ok(S.event && S.event.choice.length === 9, '已投行卷 → 9 个话题（含问行卷文章）');

/* 四、谈尽回落寒暄 */
S = T.getS();
S.event = null;
S.talked = { ouyang:['wenfeng','xingjuan','suoyuan'], meiyaochen:['zuoshi','pingdan','yuejuan'], simaguang:['quishi','jianzhi','jiansu'] };
S.ap = 4; S.yuan = 5;
T.setS(S);
T.doAct('master');
S = T.getS();
ok(!S.event, '话题谈尽 → 不再开座谈');
ok(S.log.some(function(l){ return l.t.indexOf('呈上旧作') >= 0; }), '回落 MASTER_LINES 寒暄');

/* 五、家塾乡先生（单人在场，标签不带名） */
S = T.freshState();
S.day = 1; S.scene = 0; S.met = ['xiansheng']; S.ap = 4; S.yuan = 5;
T.setS(S);
T.doAct('master');
S = T.getS();
ok(S.event && S.event.choice.length === 3, '家塾乡先生 → 3 个话题');
ok(S.event && S.event.choice[0].label.indexOf(' · ') < 0, '单人在场标签不带名');

console.log(fail === 0 ? '== 全部通过 ==' : ('== ' + fail + ' 例失败 =='));
