// 题诗四重标准判定用例（osascript -l JavaScript poem_test.js）
// 标准（2026-11-04 两次拍板）：字数对齐 · 非白话 · 非默写古人原句（示范诗+名句库） · 切题
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
code += '\n;__T = {gradePoem:gradePoem};';
eval(code);

var fail = 0;
function t(name, key, text, want){
  var g = __T.gradePoem(text, key);
  var ok = (g.grade === want);
  if (!ok) fail++;
  console.log((ok ? 'PASS' : 'FAIL') + '  ' + name + ' → ' + g.grade
    + (g.copyFrom ? '（出自' + g.copyFrom + '）' : '')
    + (g.vern ? '（白话:' + g.vern + '）' : '')
    + (g.onTopic ? '｜切题' : '｜离题')
    + '｜' + g.notes.join('／'));
}

t('1 抄示范《山居秋暝》投山川题（应中品）', 'shan',
  '空山新雨后\n天气晚来秋\n明月松间照\n清泉石上流', '中品');
t('2 默写《春晓》投山川题（名句库，应中品）', 'shan',
  '春眠不觉晓\n处处闻啼鸟\n夜来风雨声\n花落知多少', '中品');
t('3 默写《登鹳雀楼》投山川题（名句库，应中品）', 'shan',
  '白日依山尽\n黄河入海流\n欲穷千里目\n更上一层楼', '中品');
t('4 自写山川诗（四条全过，应上品）', 'shan',
  '远山如黛水如烟\n一棹春风过江南\n峰影渐随斜日尽\n钟声又送客船还', '上品');
t('5 同一首投父母题（离题，应中品）', 'fu',
  '远山如黛水如烟\n一棹春风过江南\n峰影渐随斜日尽\n钟声又送客船还', '中品');
t('6 白话诗投勤学题（白话，应中品）', 'xue',
  '今天真高兴\n我们去喝酒\n明天再读书\n一定考得好', '中品');
t('7 白话诗投山川题（白话+离题，应中品）', 'shan',
  '今天真高兴\n我们去喝酒\n明天再读书\n一定考得好', '中品');
t('8 句数不齐（应中品）', 'shan',
  '远山如黛水如烟\n一棹春风过江南', '中品');

console.log(fail === 0 ? '== 全部通过 ==' : ('== ' + fail + ' 例失败 =='));
