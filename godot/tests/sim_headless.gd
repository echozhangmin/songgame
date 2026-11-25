extends SceneTree

var E
var Cc
var MODE := "balanced"
var KNOWN_RANKS := ["状元", "一甲进士", "二甲进士", "同进士出身", "特奏名", "落第"]


func _init() -> void:
	var m = OS.get_environment("MODE")
	if m != "":
		MODE = m
	E = load("res://core/engine.gd").new()
	Cc = load("res://core/content.gd")
	var out = run_all()
	var exit_code = 0
	if out["stuck"] > 0:
		exit_code = 1
	var attr_deaths = 0
	for r in ["胸无点墨", "病卧逆旅", "孤身无援"]:
		attr_deaths += out["deathByRank"].get(r, 0)
	if MODE == "balanced" and (attr_deaths > 0 or out["deaths"] > 5):
		exit_code = 1
	if (MODE == "neglectYuan" or MODE == "neglectJing") and out["deaths"] != out["runs"]:
		exit_code = 1
	print(JSON.stringify(out, "  "))
	print("MODE=%s  runs=%d  stuck=%d  deaths=%d  → %s" % [MODE, out["runs"], out["stuck"], out["deaths"], "GREEN" if exit_code == 0 else "RED"])
	quit(exit_code)


func run_all() -> Dictionary:
	var out = {"runs": 0, "ranks": {}, "stats": {"zhi": 0, "jing": 0, "yuan": 0, "exam": 0, "day": 0}, "stuck": 0, "deaths": 0, "bySkill": {}}
	var skills = [0.55, 0.7, 0.85]
	for sk in skills:
		var bucket = {"ranks": {}, "zhi": 0, "jing": 0, "yuan": 0, "exam": 0, "money": 0, "n": 0}
		for i in range(60):
			var r = play(sk)
			if r["rank"].begins_with("STUCK"):
				out["stuck"] += 1
			if not (r["rank"] in KNOWN_RANKS):
				out["deaths"] = out.get("deaths", 0) + 1
				out["deathByRank"] = out.get("deathByRank", {})
				out["deathByRank"][r["rank"]] = out["deathByRank"].get(r["rank"], 0) + 1
				out["deathHist"] = out.get("deathHist", {})
				out["deathHist"][str(r["day"])] = out["deathHist"].get(str(r["day"]), 0) + 1
			bucket["ranks"][r["rank"]] = bucket["ranks"].get(r["rank"], 0) + 1
			bucket["zhi"] += r["zhi"]
			bucket["jing"] += r["jing"]
			bucket["yuan"] += r["yuan"]
			bucket["exam"] += r["exam"]
			bucket["money"] += r["money"]
			bucket["n"] += 1
			out["ranks"][r["rank"]] = out["ranks"].get(r["rank"], 0) + 1
			out["runs"] += 1
		bucket["avg"] = {"zhi": roundf(bucket["zhi"] * 10.0 / bucket["n"]) / 10.0,
			"jing": roundf(bucket["jing"] * 10.0 / bucket["n"]) / 10.0,
			"yuan": roundf(bucket["yuan"] * 10.0 / bucket["n"]) / 10.0,
			"exam": roundf(bucket["exam"] * 10.0 / bucket["n"]) / 10.0,
			"money": roundf(bucket["money"] * 10.0 / bucket["n"]) / 10.0}
		out["bySkill"][str(sk)] = bucket
	return out


func play(skill: float) -> Dictionary:
	E.S = E.fresh_state()
	var steps = 0
	var actions = 0
	var days_seen = {}
	while steps < 6000:
		steps += 1
		var s = E.S
		if s["phase"] == "over":
			break
		if s["pending"] != null:
			var q = s["pending"]["q"]
			var idx = "ABCD".find(q["answer"])
			var pick = idx if randf() < skill else randi() % 4
			E.answer(pick)
			E.continue_after_answer()
			continue
		if s["event"] != null:
			if s["event"].has("choice") and not s["event"]["done"]:
				E.choose_event(pick_choice(s["event"], s))
			s["event"] = null
			continue
		if s["phase"] == "play":
			days_seen[s["day"]] = true
			var id = choose_action(s)
			if id == "" or E.ACT.get(id) == null:
				E.end_day()
				continue
			var a = E.ACT[id]
			if a.has("can") and not a["can"].call():
				E.end_day()
				continue
			if s["ap"] < a["ap"]:
				E.end_day()
				continue
			E.do_act(id)
			actions += 1
			continue
		if s["phase"] == "exam" or s["phase"] == "palace":
			if s["pending"] == null:
				if s["phase"] == "palace":
					E.next_palace_question()
				else:
					E.next_exam_question()
			continue
		if s["phase"] == "roundEnd":
			E.end_day()
			continue
		if s["phase"] == "result":
			if s["exam"]["total"] >= 8:
				E.end_day()
			else:
				E.fail_exam()
			continue
		if s["phase"] == "palaceEnd":
			E.finish_ending()
			continue
		if s["phase"] == "banquet":
			E.finish_ending()
			continue
		E.end_day()
	var f = E.S
	var rank = "STUCK:" + str(f["phase"])
	if f["ending"] != null:
		rank = f["ending"].get("rank", null)
		if rank == null:
			rank = f["ending"].get("title", "?")
	var log_head: Array = []
	for x in (f["log"] as Array).slice(0, 3):
		log_head.append(str(x["d"]) + ":" + x["t"])
	return {"rank": rank, "day": f["day"], "zhi": f["zhi"], "jing": f["jing"], "yuan": f["yuan"], "money": f["money"],
		"exam": f["exam"]["total"], "palace": f["exam"]["palace"], "actions": actions,
		"log": log_head, "days": days_seen.size(), "steps": steps}


func choose_action(s: Dictionary) -> String:
	var sc = Cc.SCENES[s["scene"]]
	var acts: Array = sc.get("acts", [])
	var ok: Array = []
	for id in acts:
		var a = E.ACT.get(id)
		if a == null:
			continue
		if a["ap"] <= s["ap"] and (not a.has("can") or a["can"].call()) and (not a.has("hide_if") or not a["hide_if"].call()):
			ok.append(id)
	if ok.is_empty():
		return "sleep" if acts.has("sleep") else ""
	var cur = E.S
	if MODE == "neglectYuan":
		if cur["jing"] <= 4 and ok.has("rest"):
			return "rest"
		if ok.has("study"):
			return "study"
		if ok.has("rest"):
			return "rest"
	if MODE == "neglectJing":
		if ok.has("study"):
			return "study"
		if ok.has("social"):
			return "social"
	if MODE == "spend":
		if ok.has("social"):
			return "social"
		if ok.has("rest"):
			return "rest"
		if ok.has("study"):
			return "study"
	if cur["jing"] <= 5 and ok.has("lodge"):
		return "lodge"
	if cur["jing"] <= 4 and ok.has("rest"):
		return "rest"
	if cur["jing"] <= 4 and not ok.has("rest") and not ok.has("lodge"):
		if cur["yuan"] <= 4 and ok.has("social"):
			return "social"
		if ok.has("view"):
			return "view"
		if ok.has("chat"):
			return "chat"
		if ok.has("watch"):
			return "watch"
		return ("sleep" if acts.has("sleep") else ok[0])
	if cur["money"] < 20 and ok.has("sell"):
		return "sell"
	if cur["yuan"] <= 4 and ok.has("social"):
		return "social"
	if cur["yuan"] <= 4 and ok.has("view"):
		return "view"
	if cur["zhi"] <= 5 and ok.has("study"):
		return "study"
	if ok.has("study"):
		return "study"
	if ok.has("rest"):
		return "rest"
	if ok.has("social"):
		return "social"
	if ok.has("poem"):
		return "poem"
	if ok.has("copy"):
		return "copy"
	if ok.has("sell"):
		return "sell"
	return ("sleep" if acts.has("sleep") else ok[0])


func pick_choice(e: Dictionary, s: Dictionary) -> int:
	var best = 0
	var best_score = -1e9
	for i in range(e["choice"].size()):
		var c = e["choice"][i]
		if c.get("needSafe", false) and not s["safe"].get(e.get("safeKey", ""), false):
			continue
		if c.has("req") and c["req"].has("yuan") and s["yuan"] < c["req"]["yuan"]:
			continue
		var cost: Dictionary = c.get("cost", {})
		var gain: Dictionary = c.get("gain", {})
		var sc = 0.0
		if cost.has("jing"):
			sc -= 8 * cost["jing"]
		if cost.has("money"):
			sc -= cost["money"]
		if gain.has("jing"):
			sc += (6 if s["jing"] <= 5 else 3) * gain["jing"]
		if gain.has("zhi"):
			sc += (2 if s["zhi"] <= 8 else 1) * gain["zhi"]
		if gain.has("yuan"):
			sc += (2 if s["yuan"] <= 5 else 1) * gain["yuan"]
		if gain.has("money"):
			sc += 2 * gain["money"]
		if c.get("needSafe", false):
			sc += 5
		if sc > best_score:
			best_score = sc
			best = i
	return best
