extends RefCounted

const C = preload("res://core/content.gd")

const MAX := 10
const TOTAL_DAYS := 30
const LETTERS := ["A", "B", "C", "D"]
const STRIP_PUNCT := "，。；、！？：,.!?;: \t\r\n　"

var S: Dictionary = {}
var QUESTIONS: Array = []
var GLOSSARY: Dictionary = {}
var ACT: Dictionary = {}
var FAMOUS_LINES: Dictionary = {}
var CLASS_OF: Dictionary = {}


func _init() -> void:
	_load_json_data()
	_build_act_table()
	_build_famous_lines()
	_build_class_of()


func _load_json_data() -> void:
	var qf = FileAccess.open("res://data/quiz_150.json", FileAccess.READ)
	QUESTIONS = JSON.parse_string(qf.get_as_text())
	var gf = FileAccess.open("res://data/glossary.json", FileAccess.READ)
	GLOSSARY = JSON.parse_string(gf.get_as_text())


func _build_famous_lines() -> void:
	for t in C.POEM_THEMES:
		for l in t["ex"].split("\n", false):
			var s = strip_punct(l)
			if s.length() > 0 and not FAMOUS_LINES.has(s):
				FAMOUS_LINES[s] = t["name"]


func _build_class_of() -> void:
	for cls in C.CLASS_DATA:
		for ch in C.CLASS_DATA[cls]:
			if not CLASS_OF.has(ch):
				CLASS_OF[ch] = cls


func _build_act_table() -> void:
	ACT = {
		"study": {"name": "温书做题", "hint": "答对智力+1 精力-1", "ap": 1, "primary": true,
			"run": Callable(self, "_run_study")},
		"rest": {"name": "歇息", "hint": "精力+3（驿站+4）", "ap": 1,
			"run": Callable(self, "_run_rest")},
		"social": {"name": "宴饮结交", "hint": "人缘+2 盘缠-2", "ap": 1,
			"run": Callable(self, "_run_social")},
		"master": {"name": "拜访大儒", "hint": "初见或座谈 · 智力+1 人缘+1 盘缠-1", "ap": 1,
			"can": Callable(self, "_can_master"), "deny": "你与这位先生素无往来，门房只说“主人不见客”。",
			"run": Callable(self, "_run_master")},
		"info": {"name": "打听消息", "hint": "人缘+1 探听主司", "ap": 1,
			"run": Callable(self, "_run_info")},
		"poem": {"name": "题诗换宿", "hint": "上品 5 贯 · 下品人缘-1", "ap": 1,
			"can": Callable(self, "_can_poem"), "deny": "此地壁上已有你的诗，主人笑着摆手：“换处再写罢。”",
			"run": Callable(self, "_run_poem")},
		"copy": {"name": "抄书换钱", "hint": "盘缠+3 智力+1", "ap": 1,
			"run": Callable(self, "_run_copy")},
		"sell": {"name": "街头鬻诗", "hint": "上品 4 贯 · 下品人缘-1", "ap": 1,
			"can": Callable(self, "_can_poem"), "deny": "这条街上已有人买过你的诗，再写便不值钱了。",
			"run": Callable(self, "_run_sell")},
		"view": {"name": "凭栏观景", "hint": "精力+1 人缘+1", "ap": 1,
			"run": Callable(self, "_run_view")},
		"giftMoney": {"name": "受赠程仪", "hint": "盘缠 +8", "ap": 1, "primary": true,
			"run": Callable(self, "_run_gift_money")},
		"giftBooks": {"name": "受赠旧书", "hint": "智力 +2", "ap": 1, "primary": true,
			"run": Callable(self, "_run_gift_books")},
		"giftWords": {"name": "受先生赠言", "hint": "人缘 +1 · 智力 +1", "ap": 1, "primary": true,
			"run": Callable(self, "_run_gift_words")},
		"toujuan": {"name": "投行卷", "hint": "谒欧阳修 · 只此一次", "ap": 1, "primary": true,
			"hide_if": Callable(self, "_hide_toujuan"),
			"run": Callable(self, "_run_toujuan")},
		"guard": {"name": "结伴同行", "hint": "盘缠-1 人缘+1 · 遇匪可呼救", "ap": 1,
			"run": Callable(self, "_run_guard")},
		"temple": {"name": "夜宿山寺", "hint": "精力+1 智力+1", "ap": 1,
			"run": Callable(self, "_run_temple")},
		"watch": {"name": "系舟守夜", "hint": "精力-1 · 遇水匪可喝退", "ap": 1,
			"run": Callable(self, "_run_watch")},
		"chat": {"name": "与船家闲谈", "hint": "人缘+1 智力+1", "ap": 1,
			"run": Callable(self, "_run_chat")},
		"toudi": {"name": "投状报名", "hint": "礼部交解状 · 盘缠-1", "ap": 1,
			"hide_if": Callable(self, "_hide_toudi"),
			"run": Callable(self, "_run_toudi")},
		"lodge": {"name": "寻住处", "hint": "客栈／僧舍／投同乡", "ap": 1,
			"hide_if": Callable(self, "_hide_lodge"),
			"run": Callable(self, "_run_lodge")},
		"scout": {"name": "踩点贡院", "hint": "智力+1 人缘+1 · 省试少一错项", "ap": 1,
			"hide_if": Callable(self, "_hide_scout"),
			"run": Callable(self, "_run_scout")},
		"bridge_walk": {"name": "桥头走走", "hint": "人缘+1 精力+1 · 看市声", "ap": 1,
			"run": Callable(self, "_run_bridge_walk")},
		"bridge_supply": {"name": "上岸补给", "hint": "盘缠-1 精力+2", "ap": 1,
			"run": Callable(self, "_run_bridge_supply")},
		"sleep": {"name": "就寝 · 结束今日", "hint": "夜间结算", "ap": 0,
			"run": Callable(self, "_run_sleep")}
	}


func date_label(d: int) -> String:
	if d <= 20:
		return "正月" + C.CN_NUM[d + 9]
	return "二月" + C.CN_NUM[d - 20]


func fresh_state() -> Dictionary:
	return {
		"day": 1, "scene": 0, "ap": 4,
		"zhi": 5, "jing": 5, "yuan": 5, "money": 60,
		"flags": {"gift": null, "master": 0, "rumor": false, "entered": false, "juan": false, "juanReply": false},
		"maintained": {"zhi": false, "jing": false, "yuan": false},
		"log": [], "phase": "play", "pending": null, "feedback": null, "help": false,
		"exam": {"total": 0, "palace": 0, "round": 0, "queue": [], "cur": 0, "correct": 0, "pcur": 0, "palaceQueue": []},
		"used": [], "ending": null, "met": [], "poems": [], "poem": null, "poemUsed": [], "event": null, "seenEvents": [], "talked": {}, "safe": {"shan": false, "shui": false}, "banditDone": {"shan": false, "shui": false}, "gloss": null, "glossIndex": false, "tou": false, "lodged": false, "scouted": false
	}


func add_stat(k: String, v: int) -> void:
	S[k] = clampi(S[k] + v, 0, MAX)


func fatigue(n: int = 1) -> void:
	S["jing"] = maxi(1, S["jing"] - n)


func add_log(text: String) -> void:
	S["log"].push_front({"d": S["day"], "t": text})
	if S["log"].size() > 40:
		S["log"].pop_back()


func money(v: int) -> void:
	S["money"] += v


func cur_scene() -> Dictionary:
	return C.SCENES[S["scene"]]


func scene_for_day(d: int) -> int:
	for i in range(C.SCENES.size()):
		if d >= C.SCENES[i]["from"] and d <= C.SCENES[i]["to"]:
			return i
	return C.SCENES.size() - 1


func strip_punct(x: String) -> String:
	var out = ""
	for ch in x:
		if not (ch in STRIP_PUNCT):
			out += ch
	return out


func start_new() -> void:
	S = fresh_state()
	S["phase"] = "play"
	add_log("你收拾行囊，把《周礼》放在最上层。")
	S["help"] = true


func pick_question(pool: Callable) -> Dictionary:
	var arr: Array = []
	for q in QUESTIONS:
		if pool.call(q) and not S["used"].has(q["id"]):
			arr.append(q)
	if arr.is_empty():
		for q in QUESTIONS:
			if pool.call(q):
				arr.append(q)
	var q = arr[randi() % arr.size()]
	S["used"].append(q["id"])
	if S["used"].size() > 90:
		S["used"].pop_front()
	return q


func start_study() -> void:
	S["pending"] = {"q": pick_question(func(q): return true), "kind": "study"}
	S["feedback"] = null


func _exam_pool(r: int) -> Callable:
	match r:
		1:
			return func(q): return q["era"] == "先秦" or q["era"] == "秦汉"
		2:
			return func(q): return q["era"] == "魏晋南北朝" or q["era"] == "隋唐"
		3:
			return func(q): return q["era"] == "五代与北宋" or q["era"] == "隋唐"
		_:
			return func(q): return true


func start_exam_round() -> void:
	var r = S["day"] - 24
	S["exam"]["round"] = r
	S["exam"]["cur"] = 0
	S["exam"]["correct"] = 0
	var pool = _exam_pool(r)
	var picked: Array = []
	for i in range(5):
		var q = pick_question(pool)
		var guard = 0
		while picked.any(func(p): return p["id"] == q["id"]) and guard < 30:
			guard += 1
			q = pick_question(pool)
		picked.append(q)
	S["exam"]["queue"] = picked
	S["exam"]["cur"] = 0
	next_exam_question()


func next_exam_question() -> void:
	if S["exam"]["cur"] >= S["exam"]["queue"].size():
		finish_exam_round()
		return
	S["pending"] = {"q": S["exam"]["queue"][S["exam"]["cur"]], "kind": "exam"}
	S["feedback"] = null


func finish_exam_round() -> void:
	S["exam"]["total"] += S["exam"]["correct"]
	S["pending"] = null
	S["feedback"] = null
	S["phase"] = "roundEnd"


func start_palace() -> void:
	var picked: Array = []
	for i in range(3):
		var q = pick_question(func(q): return true)
		var guard = 0
		while picked.any(func(p): return p["id"] == q["id"]) and guard < 30:
			guard += 1
			q = pick_question(func(q): return true)
		picked.append(q)
	S["exam"]["palaceQueue"] = picked
	S["exam"]["pcur"] = 0
	next_palace_question()


func next_palace_question() -> void:
	if S["exam"]["pcur"] >= S["exam"]["palaceQueue"].size():
		S["pending"] = null
		S["phase"] = "palaceEnd"
		return
	S["pending"] = {"q": S["exam"]["palaceQueue"][S["exam"]["pcur"]], "kind": "palace"}
	S["feedback"] = null


func meet_npc(tier: String) -> Variant:
	var sc = cur_scene()
	var ids: Array = []
	for k in C.NPCS:
		var npc = C.NPCS[k]
		if npc["tier"] == tier and sc["id"] in npc["where"] and not S["met"].has(k):
			ids.append(k)
	if ids.is_empty():
		return null
	ids.sort_custom(func(a, b): return C.NPCS[a].get("prio", 9) < C.NPCS[b].get("prio", 9))
	var id = ids[0]
	S["met"].append(id)
	var d = C.NPCS[id].duplicate()
	d["id"] = id
	return d


func open_poem(mode: String) -> void:
	var pool: Array = []
	for t in C.POEM_THEMES:
		if S["poem"] == null or t["key"] != S["poem"]["theme"]:
			pool.append(t)
	var th = pool[randi() % pool.size()]
	S["poem"] = {"mode": mode, "theme": th["key"], "text": "", "warn": false, "result": null}


func is_parallel(a: String, b: String) -> bool:
	if a.length() != b.length() or a.length() == 0:
		return false
	if a == b:
		return false
	var known = 0
	for i in range(a.length()):
		var ca = CLASS_OF.get(a[i], null)
		var cb = CLASS_OF.get(b[i], null)
		if ca != null and cb != null:
			known += 1
			if ca != cb:
				return false
	return known >= ceili(a.length() * 0.5)


func grade_poem(text: String, theme_key: String) -> Dictionary:
	var lines: Array = []
	for l in text.split("\n", false):
		var s = strip_punct(l)
		if s.length() > 0:
			lines.append(s)
	var lens: Array = []
	for l in lines:
		lens.append(l.length())
	var n = lines.size()
	var uniform = n >= 2 and lens.all(func(x): return x == lens[0])
	var four = (n == 4)
	var dui = four and uniform and (is_parallel(lines[0], lines[1]) or is_parallel(lines[1], lines[2]) or is_parallel(lines[2], lines[3]))

	var th = {}
	for t in C.POEM_THEMES:
		if t["key"] == theme_key:
			th = t
	var joined = ""
	for l in lines:
		joined += l
	var hits: Array = []
	for ch in C.THEME_WORDS.get(theme_key, ""):
		if not hits.has(ch) and joined.find(ch) >= 0:
			hits.append(ch)
	var on_topic = hits.size() >= 2

	var copy_from = null
	for l in lines:
		if FAMOUS_LINES.has(l):
			copy_from = "《" + FAMOUS_LINES[l] + "》题的示范诗"
			break
		if C.FAMOUS_EXTRA.has(l):
			copy_from = C.FAMOUS_EXTRA[l]
			break

	var vern = null
	for ch in C.BAIHUA_CHARS:
		if joined.find(ch) >= 0:
			vern = ch
			break
	if vern == null:
		for w in C.BAIHUA_WORDS:
			if joined.find(w) >= 0:
				vern = w
				break
	if vern == null:
		for l in lines:
			var c = l.substr(l.length() - 1, 1)
			if c in "了的吗呢吧啊呀":
				vern = "句末「" + c + "」"
				break

	var notes: Array = []
	if four:
		notes.append("四句成篇")
	else:
		notes.append("共 " + str(n) + " 句")
	if uniform:
		notes.append("字数齐整（每句 " + str(lens[0]) + " 字）")
	else:
		notes.append("字数参差")
	if on_topic:
		notes.append("切「" + th.get("name", "") + "」题")
	if copy_from:
		notes.append("有句出自" + copy_from)
	if vern:
		notes.append("白话（" + vern + "）")
	if dui:
		notes.append("中二联相对")

	var pass_ok = four and uniform and on_topic and copy_from == null and vern == null
	var grade = "上品" if pass_ok else ("下品" if (copy_from != null or vern != null) else "中品")
	var note
	if grade == "上品" and dui:
		note = "四句齐整，又切「" + th.get("name", "") + "」之题，中二联对得稳当，越发见功夫。主人读了两遍，连声称善。"
	elif grade == "上品":
		note = "四句齐整，字字相当，又切「" + th.get("name", "") + "」之题，已是一首成样的诗。主人抚掌道：“好，好！”"
	elif copy_from:
		note = "这句子出自" + copy_from + "——当众默写古人成句，满座哄笑。主人把纸推了回来，你的面上有些挂不住。"
	elif vern:
		note = "字句太白，全然不是诗家语。围看的闲人笑出了声，你面上讪讪的。"
	elif four and uniform:
		note = "四句虽齐，却不在「" + th.get("name", "") + "」题内——离题的诗，主人家不好奉上程仪。"
	else:
		note = "肯写就好。下一回写四句、每句字数一样，又切着题，便是上品——主人家也才好奉上程仪。"

	return {"grade": grade, "notes": notes, "lines": lines, "note": note, "dui": dui, "uniform": uniform, "n": n, "onTopic": on_topic, "copyFrom": copy_from, "vern": vern}


func submit_poem(text: String) -> void:
	if S["poem"] == null or S["poem"]["result"] != null:
		return
	var clean = (text if text != null else "").strip_edges()
	S["poem"]["text"] = clean
	if clean.is_empty():
		S["poem"]["warn"] = true
		return
	var th = {}
	for t in C.POEM_THEMES:
		if t["key"] == S["poem"]["theme"]:
			th = t
	var g = grade_poem(clean, S["poem"]["theme"])
	var reward = 5 if (g["grade"] == "上品" and S["poem"]["mode"] == "poem") else (4 if g["grade"] == "上品" else 0)
	money(reward)
	if g["grade"] == "上品":
		add_stat("zhi", 1)
	if g["grade"] == "下品":
		add_stat("yuan", -1)
	S["poems"].append({"day": S["day"], "mode": S["poem"]["mode"], "theme": th["name"], "text": clean, "grade": g["grade"], "reward": reward})
	if not S["poemUsed"].has(cur_scene()["id"]):
		S["poemUsed"].append(cur_scene()["id"])
	if reward > 0:
		add_log("你" + ("于驿壁题" if S["poem"]["mode"] == "poem" else "当街鬻出一首") + th["name"] + "诗，上品，得 " + str(reward) + " 贯。")
	elif g["grade"] == "下品":
		add_log("你" + ("于驿壁题" if S["poem"]["mode"] == "poem" else "当街鬻出") + "一首" + th["name"] + "诗，下品——" + ("满座只当看了一回抄书。" if g["copyFrom"] else "白话连篇，众人只当听个笑话。") + "人缘折了一分。")
	else:
		add_log("你" + ("题了一首" if S["poem"]["mode"] == "poem" else "当街鬻出一首") + th["name"] + "诗，" + ("主人笑着收了，却未提程仪的事。" if S["poem"]["mode"] == "poem" else "围观的人渐渐散了，没做成生意。"))
	var r = {"empty": false, "theme": th["name"], "reward": reward}
	for k in g:
		r[k] = g[k]
	S["poem"]["result"] = r


func answer(i: int) -> void:
	if S["pending"] == null or S["feedback"] != null:
		return
	var q = S["pending"]["q"]
	var my = LETTERS[i]
	var ok = (my == q["answer"])
	if S["pending"]["kind"] == "study":
		if ok:
			add_stat("zhi", 1)
		add_log("此题你答得干脆，心中又亮了一分。" if ok else "此题答错，你把出处又看了一遍。")
	elif S["pending"]["kind"] == "exam":
		if ok:
			S["exam"]["correct"] += 1
		add_log("笔下一气，未曾迟疑。" if ok else "笔尖顿了顿，终究写错了出处。")
	else:
		if ok:
			S["exam"]["palace"] += 1
	S["pending"]["my"] = my
	S["feedback"] = {"ok": ok, "answer": q["answer"], "explain": q["explain"]}


func continue_after_answer() -> void:
	if S["pending"] == null:
		return
	var kind = S["pending"]["kind"]
	S["pending"] = null
	S["feedback"] = null
	if kind == "exam":
		S["exam"]["cur"] += 1
		next_exam_question()
	elif kind == "palace":
		S["exam"]["pcur"] += 1
		next_palace_question()


func enter_day() -> void:
	var sc = cur_scene()
	S["pending"] = null
	S["feedback"] = null
	if sc["kind"] == "gate" and S["day"] == 15 and S["event"] == null:
		open_gate_tax()
	if sc["id"] == "hongqiao" and S["day"] == 12 and S["event"] == null:
		open_bridge_event()
	if sc["kind"] == "exam":
		S["phase"] = "exam"
		if S["day"] == 25 and S["flags"]["juan"] and not S["flags"]["juanReply"]:
			S["flags"]["juanReply"] = true
			var good = S["zhi"] >= 7
			add_stat("yuan", 1)
			if good:
				add_stat("zhi", 1)
			S["letter"] = {"text": "天将明，有人叩门，从门缝里递进一纸小笺，字是瘦硬的欧体：\n\n“文气已足，只宜敛锋。策问若及河渠，可据《禹贡》立论。”\n\n下款只是一个“修”字。",
				"effect": "知贡举记得你的卷子。人缘 +1、智力 +1，省试再得一分考运。"} if good else {"text": "天将明，有人叩门，从门缝里递进一纸小笺：\n\n“笔下太急。入场先定章法，再落字。”\n\n下款是一个“修”字。",
				"effect": "知贡举看过你的行卷。人缘 +1，省试略有考运。"}
			return
		start_exam_round()
		return
	if sc["kind"] == "ending":
		if S["day"] <= 28:
			S["phase"] = "result"
			return
		if S["day"] == 29:
			S["phase"] = "palace"
			start_palace()
			return
		S["phase"] = "banquet"
		return
	S["phase"] = "play"


func end_day() -> void:
	if S["phase"] == "over":
		return
	if S["event"] != null and not S["event"]["done"]:
		add_log("夜里的事，终究没有个结果——你翻身睡下了。")
	S["event"] = null
	var kind_now = cur_scene()["kind"]
	var cost = 2 if S["day"] >= 16 else 1
	if kind_now == "exam" or kind_now == "ending":
		cost = 1
	money(-cost)
	if S["money"] < 0:
		S["money"] = 0
		finish("fail", {"title": "困于逆旅", "text": "盘缠用尽，你连号舍外的客栈也住不起了。放榜那日，你只能站在人群之外，听别人念榜。"})
		return

	var exempt = (kind_now == "exam" or kind_now == "ending" or kind_now == "choice")
	if not exempt:
		var names = {"zhi": "智力", "jing": "精力", "yuan": "人缘"}
		var lost: Array = []
		for k in ["zhi", "jing", "yuan"]:
			if not S["maintained"][k]:
				add_stat(k, -1)
				lost.append(k)
		if lost.size() > 0:
			var parts: Array = []
			for k in lost:
				parts.append(names[k])
			add_log("夜深，" + "、".join(parts) + " 各消减一分。")
		if S["jing"] <= 2 and randf() < 0.45:
			add_stat("jing", -1)
			add_log("你连日奔波，夜里咳了起来，精力又失一分。")
		var low: Array = []
		if S["zhi"] <= 2:
			low.append("智力")
		if S["jing"] <= 2:
			low.append("精力")
		if S["yuan"] <= 2:
			low.append("人缘")
		if low.size() > 0:
			add_log("⚠ " + "、".join(low) + "已近枯竭，明日须先补上。")

	if S["zhi"] <= 0:
		finish("fail", {"title": "胸无点墨", "text": "久不温书，提笔竟不知从何说起。你在号舍里坐了一整日，只写下半行字。"})
		return
	if S["jing"] <= 0:
		finish("fail", {"title": "病卧逆旅", "text": "你在客栈里躺了三天，没能走进贡院的门。这一科，就此作罢。"})
		return
	if S["yuan"] <= 0:
		finish("fail", {"title": "孤身无援", "text": "同行者皆散去，无人为你递一句话。汴京的冬天很冷，你把行囊收了起来。"})
		return

	S["day"] += 1
	if S["day"] > TOTAL_DAYS:
		finish_ending()
		return

	S["scene"] = scene_for_day(S["day"])
	S["ap"] = 4
	S["maintained"] = {"zhi": false, "jing": false, "yuan": false}

	var ns = cur_scene()
	add_log("—— 第 " + str(S["day"]) + " 日 · " + ns["name"] + " ——")

	if ns["kind"] == "travel":
		S["ap"] -= 2
		travel_event()
	enter_day()
	if S["phase"] == "play" and not maybe_bandit():
		maybe_event()


func apply_delta(cost: Dictionary, gain: Dictionary) -> void:
	var c = cost if cost != null else {}
	var g = gain if gain != null else {}
	if c.has("money"):
		money(-c["money"])
	if c.has("jing"):
		fatigue(c["jing"])
	if c.has("zhi"):
		add_stat("zhi", -c["zhi"])
	if c.has("yuan"):
		add_stat("yuan", -c["yuan"])
	if g.has("money"):
		money(g["money"])
	if g.has("jing"):
		add_stat("jing", g["jing"])
	if g.has("zhi"):
		add_stat("zhi", g["zhi"])
	if g.has("yuan"):
		add_stat("yuan", g["yuan"])


func maybe_event() -> void:
	if S["phase"] != "play" or S["day"] < 3 or S["event"] != null:
		return
	var sc = cur_scene()
	if sc["kind"] == "exam" or sc["kind"] == "ending":
		return
	if randf() > 0.5:
		return
	var pool: Array = []
	for e in C.EVENTS:
		if (not e.has("where") or sc["id"] in e["where"]) and not S["seenEvents"].has(e["id"]):
			pool.append(e)
	if pool.is_empty():
		return
	var total = 0
	for e in pool:
		total += e.get("w", 1)
	var r = randf() * total
	var pick = pool[pool.size() - 1]
	for e in pool:
		r -= e.get("w", 1)
		if r <= 0:
			pick = e
			break
	S["seenEvents"].append(pick["id"])
	if pick.has("auto"):
		apply_delta({}, pick["auto"])
		add_log(pick.get("autoMsg", ""))
		S["event"] = {"title": pick["title"], "text": pick["text"], "msg": pick.get("autoMsg", ""), "done": true}
	else:
		S["event"] = {"title": pick["title"], "text": pick["text"], "choice": pick["choice"], "done": false}


func choose_event(i: int) -> void:
	var e = S["event"]
	if e == null or not e.has("choice"):
		return
	var c = e["choice"][i]
	if c.get("needSafe", false) and not S["safe"].get(e.get("safeKey", ""), false):
		return
	if c.has("req") and c["req"].has("yuan") and S["yuan"] < c["req"]["yuan"]:
		return
	apply_delta(c.get("cost", {}), c.get("gain", {}))
	if e.get("tag", "") == "lodge":
		S["lodged"] = true
	if e.get("tag", "") == "talk":
		if not S["talked"].has(c["master"]):
			S["talked"][c["master"]] = []
		S["talked"][c["master"]].append(c["topic"])
		if c.get("rumor", false) and not S["flags"]["rumor"]:
			S["flags"]["rumor"] = true
			add_log("先生的话印证了传闻：今年主司好古文、厌险怪。")
	add_log(c["msg"])
	e["msg"] = c["msg"]
	e["done"] = true


func open_lodge() -> void:
	S["event"] = {"title": "寻 住 处", "tag": "lodge", "done": false, "safeKey": "",
		"text": "州桥一带的客栈家家客满。牙人凑上来：“举子可是要住店？州桥边有间上房，城外的僧舍也清净。”",
		"choice": [
			{"label": "州桥客栈（盘缠 -2，精力 +2）", "cost": {"money": 2}, "gain": {"jing": 2},
				"msg": "房钱不便宜，但离贡院近，夜里也听得见街鼓。"},
			{"label": "城外僧舍（盘缠 -1，精力 +1）", "cost": {"money": 1}, "gain": {"jing": 1},
				"msg": "僧舍清静，只是进城要走半个时辰。"},
			{"label": "投同乡举子（需人缘 ≥5，免费）", "req": {"yuan": 5}, "gain": {"yuan": 1},
				"msg": "同乡挤出一张榻给你，还借了你半刀纸。"}
		]}


func open_bridge_event() -> void:
	S["event"] = {"title": "桥 头", "done": false, "safeKey": "",
		"text": "桥头围着一圈人，说书人正说到“仁宗皇帝夜半批章”，惊堂木一拍，满圈叫好。旁边一个牙人凑过来：“举子要住店么？桥东有间上房，一日只要二百文。”",
		"choice": [
			{"label": "听一段书（盘缠 -1，智力 +1）", "cost": {"money": 1}, "gain": {"zhi": 1},
				"msg": "他说得热闹，你却听出几处与史不合，反倒把《长编》里的记载记牢了。"},
			{"label": "跟牙人去看房（盘缠 -3，精力 +2）", "cost": {"money": 3}, "gain": {"jing": 2},
				"msg": "房钱比别处贵些，好在临河，夜里睡得沉。"},
			{"label": "只在桥头站着（免费，人缘 +1，精力 -1）", "cost": {"jing": 1}, "gain": {"yuan": 1},
				"msg": "你挤在人堆里看了一回热闹，直到闸门开了才回船。"}
		]}


func open_gate_tax() -> void:
	S["event"] = {"title": "门 税", "done": false, "safeKey": "",
		"text": "守门吏拦住你的书箱，眯眼道：“举子行李，照例抽税。”",
		"choice": [
			{"label": "给两贯（盘缠 -2）", "cost": {"money": 2}, "msg": "你递过钱，他挥挥手放行。"},
			{"label": "与他理论（精力 -1，人缘 -1）", "cost": {"jing": 1}, "gain": {"yuan": -1},
				"msg": "你争了半个时辰，钱是省下了，人却得罪了。"}
		]}


func open_dialogue() -> bool:
	var sc = cur_scene()
	var present: Array = []
	for k in C.NPCS:
		if C.NPCS[k]["tier"] == "master" and sc["id"] in C.NPCS[k]["where"] and S["met"].has(k):
			present.append(k)
	var list: Array = []
	for k in present:
		for t in C.DIALOGUES[k]["topics"]:
			if t.get("needJuan", false) and not S["flags"]["juan"]:
				continue
			if S["talked"].get(k, []).has(t["id"]):
				continue
			var msg = t["reply"] + ("\n\n你问：" + t["ask"] + "\n" + t["follow"] if t.has("ask") else "")
			list.append({"master": k, "topic": t["id"],
				"label": (C.DIALOGUES[k]["name"] + " · " if present.size() > 1 else "") + t["label"],
				"gain": t.get("gain", {}), "rumor": t.get("rumor", false),
				"msg": msg})
	if list.is_empty():
		return false
	S["event"] = {"title": "座 谈", "tag": "talk", "done": false, "safeKey": "",
		"text": "落座奉茶。" + ("座上几位先生神色各异，你拣要紧的问。" if present.size() > 1 else "先生放下手中的卷子，等你开口。"),
		"choice": list}
	return true


func show_bandit(key: String) -> void:
	var b = C.BANDITS[key]
	S["event"] = {"title": b["title"], "text": b["text"], "choice": b["choices"], "done": false, "safeKey": b["safeKey"], "bandit": true}


func maybe_bandit() -> bool:
	var sc = cur_scene()
	if sc["id"] == "shandao" and S["day"] == 8 and not S["banditDone"]["shan"]:
		S["banditDone"]["shan"] = true
		show_bandit("shan")
		return true
	if sc["id"] == "bianhe" and S["day"] == 11 and not S["banditDone"]["shui"]:
		S["banditDone"]["shui"] = true
		show_bandit("shui")
		return true
	return false


func travel_event() -> void:
	var r = randf() * 10.0
	if r <= 3.0:
		fatigue()
		add_log("山雨骤至，你的鞋袜尽湿，赶路耗去不少气力。")
	elif r <= 5.0:
		money(-2)
		add_log("渡口船家坐地起价，你多付了两贯。")
	elif r <= 7.0:
		add_stat("zhi", -1)
		add_log("车马颠簸，你翻开书却一个字也读不进去。")
	elif r <= 9.0:
		add_stat("yuan", 1)
		add_log("同行的举子分了半块干粮给你，两人攀谈起来。")
	else:
		add_stat("jing", 1)
		add_log("途中遇到一处茶亭，你歇了半个时辰，精神稍复。")


func finish(kind: String, opt: Dictionary = {}) -> void:
	S["phase"] = "over"
	var ending = {"kind": kind}
	for k in opt:
		ending[k] = opt[k]
	S["ending"] = ending


func fail_exam() -> void:
	S["phase"] = "over"
	S["ending"] = {"kind": "ending", "rank": "落第", "cls": "dim",
		"text": "榜上没有你的名字。你在汴京又住了两月，把行囊里剩下的书读完，才动身回乡。三年后再来，也未必不是好事。"}


func finish_ending() -> void:
	var exam_pct = S["exam"]["total"] / 15.0
	var palace_pct = S["exam"]["palace"] / 3.0
	var jing_coef = 1.0 if S["jing"] >= 6 else (0.88 if S["jing"] >= 3 else 0.75)
	var rumor = 0.03 if S["flags"]["rumor"] else 0.0
	var juan_bonus = 0.04 if S["flags"]["juanReply"] else (0.02 if S["flags"]["juan"] else 0.0)
	var zhi_coef = 0.60 + S["zhi"] / 25.0
	var yuan_norm = S["yuan"] / float(MAX)
	var score = (exam_pct * 0.62 * zhi_coef + palace_pct * 0.26 + yuan_norm * 0.12 + rumor + juan_bonus) * jing_coef
	var e
	if score >= 0.88:
		e = {"rank": "状元", "cls": "red", "text": "唱名之日，你的名字第一个被唤出。琼林宴上，你想起临川老宅的那盏灯，忽然觉得三千里路并不算远。"}
	elif score >= 0.78:
		e = {"rank": "一甲进士", "cls": "red", "text": "你列名一甲，入馆阁读书。同榜的人都说，临川来的这位王举子，文章有锋芒。"}
	elif score >= 0.68:
		e = {"rank": "二甲进士", "cls": "red", "text": "你中了二甲进士，授官外放。离京那日，你在州桥边站了很久，看汴河的水往东去。"}
	elif score >= 0.58:
		e = {"rank": "同进士出身", "cls": "", "text": "你以同进士出身及第，虽非高第，终究脱了白身。回乡时，先生在牌位前多摆了一壶酒。"}
	else:
		e = {"rank": "特奏名", "cls": "dim", "text": "你的卷子被归入特奏名，赐出身，授一县主簿。仕途虽小，终究入了门。（史实中特奏名须积举数与年岁，首举者不与；此为游戏性保底档。）"}
	S["phase"] = "over"
	var ending = {"kind": "ending"}
	for k in e:
		ending[k] = e[k]
	S["ending"] = ending


func save_game() -> Variant:
	if S.is_empty() or S["phase"] == "over":
		return null
	var c = S.duplicate(true)
	c["pending"] = null
	c["feedback"] = null
	c["poem"] = null
	c["letter"] = null
	c["event"] = null
	c["log"] = c["log"].slice(0, 12)
	return c


func apply_save(g: Dictionary) -> Dictionary:
	g = _norm_json(g)
	g["pending"] = null
	g["feedback"] = null
	g["help"] = false
	if typeof(g.get("ap", 4)) != TYPE_INT or g["ap"] < 0 or g["ap"] > 4:
		g["ap"] = 4
	S = g
	return g


func _norm_json(v: Variant) -> Variant:
	if typeof(v) == TYPE_DICTIONARY:
		for k in v:
			v[k] = _norm_json(v[k])
	elif typeof(v) == TYPE_ARRAY:
		for i in range(v.size()):
			v[i] = _norm_json(v[i])
	elif typeof(v) == TYPE_FLOAT and v == floor(v) and abs(v) < 1073741824.0:
		return int(v)
	return v


func do_act(id: String) -> void:
	if S["phase"] == "over":
		return
	if not ACT.has(id):
		return
	var a = ACT[id]
	if a.has("can") and not a["can"].call():
		add_log(a.get("deny", "此举不成。"))
		return
	if S["ap"] < a["ap"]:
		add_log("今日已无余力。")
		return
	S["ap"] -= a["ap"]
	a["run"].call()


func open_question() -> void:
	if S["pending"] == null:
		if S["phase"] == "palace":
			next_palace_question()
		else:
			next_exam_question()


func next_round() -> void:
	S["phase"] = "exam"
	end_day()


func go_on() -> void:
	end_day()


func banquet_act() -> void:
	S["day"] = 30
	S["scene"] = 9
	S["phase"] = "banquet"


func finale() -> void:
	finish_ending()


func close_letter() -> void:
	S["letter"] = null
	if S["phase"] == "exam" and S["pending"] == null:
		start_exam_round()


func event_ok() -> void:
	S["event"] = null


func poem_submit(text: String) -> void:
	submit_poem(text)


func poem_cancel() -> void:
	S["ap"] += 1
	S["poem"] = null
	add_log("你搁笔不题，转身走了。")


func poem_done() -> void:
	S["poem"] = null


func split_by_terms(text: String, terms: Array) -> Array:
	var out: Array = []
	var i = 0
	var buf = ""
	while i < text.length():
		var hit = null
		for t in terms:
			if text.substr(i, t.length()) == t:
				hit = t
				break
		if hit != null:
			if buf != "":
				out.append({"t": "text", "v": buf})
				buf = ""
			out.append({"t": "term", "v": hit})
			i += hit.length()
		else:
			buf += text[i]
			i += 1
	if buf != "":
		out.append({"t": "text", "v": buf})
	return out


func term_badge(text: String) -> String:
	var terms = GLOSSARY.keys()
	terms.sort_custom(func(a, b): return a.length() > b.length())
	for t in terms:
		if text.find(t) >= 0:
			return t
	return ""


func exam_strike_letter(q: Dictionary) -> String:
	if not S["scouted"]:
		return ""
	if S["pending"] == null or S["pending"]["kind"] != "exam":
		return ""
	if S["exam"]["round"] != 1 or S["exam"]["cur"] != 0:
		return ""
	for l in LETTERS:
		if l != q["answer"]:
			return l
	return ""


func _can_master() -> bool:
	return S["yuan"] >= 3


func _can_poem() -> bool:
	return not S["poemUsed"].has(cur_scene()["id"])


func _hide_toujuan() -> bool:
	return S["flags"]["juan"] or S["met"].has("ouyang")


func _hide_toudi() -> bool:
	return S["tou"]


func _hide_lodge() -> bool:
	return S["lodged"]


func _hide_scout() -> bool:
	return S["scouted"]


func _run_study() -> void:
	S["maintained"]["zhi"] = true
	fatigue()
	start_study()


func _run_rest() -> void:
	S["maintained"]["jing"] = true
	var id = cur_scene()["id"]
	var bonus = 1 if id == "yizhan" else (-1 if id == "bianhe" else 0)
	add_stat("jing", 3 + bonus)
	if id == "yizhan":
		add_log("驿舍被褥干爽，你一觉睡到日上三竿。")
	elif id == "bianhe":
		add_log("舱中局促，你枕着书箱睡了半日，醒来腰背酸硬。")
	else:
		add_log("你合眼睡了半日，醒来时天光柔和。")


func _run_social() -> void:
	S["maintained"]["yuan"] = true
	money(-2)
	add_stat("yuan", 2)
	var npc = meet_npc("peer")
	if npc != null:
		add_stat("zhi", 1)
		add_log("〔史料〕" + npc["note"])
		add_log("你结识了" + npc["name"] + "（" + npc["tag"] + "）。" + npc["desc"])
	else:
		add_log("你在席间与几位举子互道乡贯，酒过三巡，已有人称你“王兄”。")


func _run_master() -> void:
	S["maintained"]["zhi"] = true
	S["maintained"]["yuan"] = true
	money(-1)
	add_stat("zhi", 1)
	add_stat("yuan", 1)
	S["flags"]["master"] += 1
	if S["yuan"] >= 8:
		add_stat("zhi", 1)
	var npc = meet_npc("master")
	if npc != null:
		add_log("〔史料〕" + npc["note"])
		add_log(npc["name"] + "（" + npc["tag"] + "）见了你。" + npc["desc"])
	elif open_dialogue():
		pass
	else:
		add_log("你呈上旧作，先生看了半晌，只说了句：" + C.MASTER_LINES[S["flags"]["master"] % C.MASTER_LINES.size()])


func _run_info() -> void:
	S["maintained"]["yuan"] = true
	money(-1)
	add_stat("yuan", 1)
	if not S["flags"]["rumor"]:
		S["flags"]["rumor"] = true
		add_log("酒保凑近低声道：今年知贡举换了人，好古文，厌险怪。")
	else:
		add_log("你又听了一耳朵传闻，多半是重复的旧话。")


func _run_poem() -> void:
	fatigue()
	S["maintained"]["zhi"] = true
	open_poem("poem")


func _run_copy() -> void:
	money(3)
	fatigue()
	S["maintained"]["zhi"] = true
	add_stat("zhi", 1)
	add_log("你替书库抄了两卷《汉书》，腕子发酸，却也把正文默记了一遍。")


func _run_sell() -> void:
	fatigue()
	open_poem("sell")


func _run_view() -> void:
	S["maintained"]["jing"] = true
	S["maintained"]["yuan"] = true
	add_stat("jing", 1)
	add_stat("yuan", 1)
	add_log("你与老者同立船头看落日，他随口讲了半段汴河旧事。")


func _run_gift_money() -> void:
	S["flags"]["gift"] = "money"
	money(8)
	add_log("同窗硬塞来八贯钱：“京城米贵，莫要省这几个铜子。”")
	end_day()


func _run_gift_books() -> void:
	S["flags"]["gift"] = "books"
	add_stat("zhi", 2)
	add_log("先生把一函手抄的《周礼》塞进你的书箱：“路上读它。”")
	end_day()


func _run_gift_words() -> void:
	S["flags"]["gift"] = "words"
	add_stat("yuan", 1)
	add_stat("zhi", 1)
	add_log("先生只说了八个字：“守拙而进，勿趋炎势。”")
	end_day()


func _run_toujuan() -> void:
	money(-2)
	S["met"].append("ouyang")
	S["flags"]["juan"] = true
	add_stat("yuan", 1)
	add_stat("zhi", 1)
	add_log("你携旧作十篇，到礼部衙前投了行卷，门人答应替你转呈。")
	add_log("欧阳修（翰林学士 · 知贡举）展卷细读，半晌才道：“文从字顺，可再简。少年人肯把话说尽，是长处，也是短处。”")
	add_log("〔史料〕嘉祐二年省试由欧阳修主考、梅尧臣点检试卷；苏轼正是此榜见知于欧公。")


func _run_guard() -> void:
	money(-1)
	add_stat("yuan", 1)
	S["maintained"]["yuan"] = true
	S["safe"]["shan"] = true
	add_log("你与一队贩布的商旅搭伴同行，约定前后照应。")


func _run_temple() -> void:
	add_stat("jing", 1)
	add_stat("zhi", 1)
	S["maintained"]["jing"] = true
	add_log("山寺的灯油不多了，你把书凑近些，读到三更。")


func _run_watch() -> void:
	fatigue()
	S["safe"]["shui"] = true
	add_log("你把箱笼挪到舱口，和衣坐着，听了一夜水声。")


func _run_chat() -> void:
	add_stat("yuan", 1)
	add_stat("zhi", 1)
	S["maintained"]["yuan"] = true
	add_log("船家讲了半段汴河旧事：哪段水急，哪段有贼。")


func _run_toudi() -> void:
	money(-1)
	S["tou"] = true
	add_stat("yuan", 1)
	S["maintained"]["yuan"] = true
	add_log("你到礼部衙前投了状，领回一纸号舍凭据。")


func _run_lodge() -> void:
	open_lodge()


func _run_scout() -> void:
	S["scouted"] = true
	add_stat("zhi", 1)
	add_stat("yuan", 1)
	S["maintained"]["zhi"] = true
	S["maintained"]["yuan"] = true
	add_log("你在贡院门前站了半日，看熟了场次与规矩。")


func _run_bridge_walk() -> void:
	add_stat("yuan", 1)
	add_stat("jing", 1)
	S["maintained"]["yuan"] = true
	S["maintained"]["jing"] = true
	add_log("你在虹桥上看了一回船，桥下桅杆如林，卖艺的、算命的、卖药的挤作一处。")


func _run_bridge_supply() -> void:
	money(-1)
	add_stat("jing", 2)
	S["maintained"]["jing"] = true
	add_log("你买了两个胡饼、一包干茶，又灌满了水囊。")


func _run_sleep() -> void:
	end_day()
