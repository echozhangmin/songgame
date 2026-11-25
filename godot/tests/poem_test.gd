extends SceneTree

var E
var fail := 0


func _init() -> void:
	E = load("res://core/engine.gd").new()
	t("1 抄示范《山居秋暝》投山川题（应下品）", "shan", "空山新雨后\n天气晚来秋\n明月松间照\n清泉石上流", "下品")
	t("2 默写《春晓》投山川题（名句库，应下品）", "shan", "春眠不觉晓\n处处闻啼鸟\n夜来风雨声\n花落知多少", "下品")
	t("3 默写《登鹳雀楼》投山川题（名句库，应下品）", "shan", "白日依山尽\n黄河入海流\n欲穷千里目\n更上一层楼", "下品")
	t("4 自写山川诗（四条全过，应上品）", "shan", "远山如黛水如烟\n一棹春风过江南\n峰影渐随斜日尽\n钟声又送客船还", "上品")
	t("5 同一首投父母题（离题，应中品）", "fu", "远山如黛水如烟\n一棹春风过江南\n峰影渐随斜日尽\n钟声又送客船还", "中品")
	t("6 白话诗投勤学题（白话，应下品）", "xue", "今天真高兴\n我们去喝酒\n明天再读书\n一定考得好", "下品")
	t("7 白话诗投山川题（白话+离题，应下品）", "shan", "今天真高兴\n我们去喝酒\n明天再读书\n一定考得好", "下品")
	t("8 句数不齐（应中品）", "shan", "远山如黛水如烟\n一棹春风过江南", "中品")
	if fail == 0:
		print("== 全部通过 ==")
	else:
		print("== %d 例失败 ==" % fail)
	quit(0 if fail == 0 else 1)


func t(name: String, key: String, text: String, want: String) -> void:
	var g = E.grade_poem(text, key)
	var ok = (g["grade"] == want)
	if not ok:
		fail += 1
	var extra = ""
	if g["copyFrom"] != null:
		extra += "（出自" + str(g["copyFrom"]) + "）"
	if g["vern"] != null:
		extra += "（白话:" + str(g["vern"]) + "）"
	extra += "｜切题" if g["onTopic"] else "｜离题"
	extra += "｜" + "／".join(g["notes"])
	print(("PASS  " if ok else "FAIL  ") + name + " → " + g["grade"] + extra)
