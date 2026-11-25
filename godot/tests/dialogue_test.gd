extends SceneTree

var E
var fails := 0
var total_topics := 0


func _init() -> void:
	E = load("res://core/engine.gd").new()
	var c = load("res://core/content.gd")

	var total = 0
	for k in c.DIALOGUES:
		var d = c.DIALOGUES[k]
		ok(c.NPCS.has(k) and c.NPCS[k]["tier"] == "master", "人物 " + k + " 是大儒且在场表内")
		for t in d["topics"]:
			total += 1
			ok(t.get("id", "") != "" and t.get("label", "") != "" and t.get("reply", "") != "", k + "." + t["id"] + " 字段齐全")
			var g = t.get("gain", {})
			var valid = true
			for x in g:
				if not (x == "zhi" or x == "yuan"):
					valid = false
			ok(valid, k + "." + t["id"] + " 效果键合法")
			if t.has("ask"):
				ok(t.get("follow", "") != "", k + "." + t["id"] + " 追问有答")
	ok(total == 15, "话题总数 15（实为 %d）" % total)

	var S = E.fresh_state()
	S["day"] = 17
	S["scene"] = 8
	S["met"] = ["ouyang", "meiyaochen", "simaguang"]
	S["ap"] = 4
	S["yuan"] = 5
	E.S = S
	E.do_act("master")
	S = E.S
	ok(S["event"] != null and S["event"].get("tag", "") == "talk", "拜访开座谈弹窗")
	ok(S["event"] != null and S["event"]["choice"].size() == 8, "未投行卷 → 8 个话题（实为 %d）" % (S["event"]["choice"].size() if S["event"] != null else -1))
	ok(S["event"] != null and S["event"]["choice"][0]["label"].begins_with("欧阳修 ·"), "多人在场时标签带名")
	E.choose_event(0)
	S = E.S
	ok(S["event"]["done"] == true, "选定话题后弹窗转完成态")
	ok(S["talked"].get("ouyang", []).has("wenfeng"), "话题打勾进 talked")
	ok(S["flags"]["rumor"] == true, "问今年文风 → 解锁主司传闻")
	ok(S["zhi"] == 7, "基础 +1 与话题 +1 都入账（智力 5→7，实为 %d）" % S["zhi"])

	S = E.fresh_state()
	S["day"] = 17
	S["scene"] = 8
	S["met"] = ["ouyang", "meiyaochen", "simaguang"]
	S["ap"] = 4
	S["yuan"] = 5
	S["flags"]["juan"] = true
	E.S = S
	E.do_act("master")
	S = E.S
	ok(S["event"] != null and S["event"]["choice"].size() == 9, "已投行卷 → 9 个话题（实为 %d）" % (S["event"]["choice"].size() if S["event"] != null else -1))

	S = E.S
	S["event"] = null
	S["talked"] = {"ouyang": ["wenfeng", "xingjuan", "suoyuan"], "meiyaochen": ["zuoshi", "pingdan", "yuejuan"], "simaguang": ["quishi", "jianzhi", "jiansu"]}
	S["ap"] = 4
	S["yuan"] = 5
	E.S = S
	E.do_act("master")
	S = E.S
	ok(S["event"] == null, "话题谈尽 → 不再开座谈")
	var fallback = false
	for l in S["log"]:
		if l["t"].find("呈上旧作") >= 0:
			fallback = true
	ok(fallback, "回落 MASTER_LINES 寒暄")

	S = E.fresh_state()
	S["day"] = 1
	S["scene"] = 0
	S["met"] = ["xiansheng"]
	S["ap"] = 4
	S["yuan"] = 5
	E.S = S
	E.do_act("master")
	S = E.S
	ok(S["event"] != null and S["event"]["choice"].size() == 3, "家塾乡先生 → 3 个话题")
	ok(S["event"] != null and S["event"]["choice"][0]["label"].find(" · ") < 0, "单人在场标签不带名")

	print("== 座谈 %s ==" % ("全部通过" if fails == 0 else "%d 例失败" % fails))
	quit(0 if fails == 0 else 1)


func ok(cond: bool, name: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + name)
	if not cond:
		fails += 1
