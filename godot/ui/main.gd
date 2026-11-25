extends Control

const INK := Color("33291c")
const INK2 := Color("5c503c")
const INK3 := Color("8a7a5f")
const PAPER := Color("e5d8ba")
const PAPER2 := Color("f2ecd8")
const RED := Color("a63a2c")
const GOLD := Color("99813d")
const BLUE := Color("46626b")

const HELP_TEXT := "一 · 每日行动
· 每天 4 点行动：温书、歇息、交游各占 1 点。
· 赶路日先耗 2 点，只剩 2 点——必有一样要放下，这就是取舍。

二 · 入夜结算
· 当日没做的那一类事，对应属性（智力／精力／人缘）各减 1 分。
· 任一项归零，旅程终止：智力尽则胸无点墨，精力尽则病卧逆旅，人缘尽则孤身无援。

三 · 三项属性
· 智力管笔墨成色，精力管临场发挥，人缘管拜访大儒、探听主司。

四 · 行程与考试
· 第 25–27 日省试三场、每场 5 题；第 28 日放榜，第 29 日殿试，第 30 日琼林宴。

五 · 题诗换钱
· 驿站、山道、虹桥、城门可「题诗换宿」，市口可「街头鬻诗」。
· 上品要过四条：一切题（须含所投题材的题眼字）、二四句、每句字数一样、三不得照抄古人成句（示范诗与名句库都在内）、四不得写白话。题诗得 5 贯、鬻诗得 4 贯；白话、默写判下品——分文不给，还当众折一分人缘；离题、不齐判中品，无酬。

六 · 人物与词条
· 酒楼、书库、舟中可结识嘉祐二年的真实人物：苏轼兄弟、曾巩、程颢、张载、吕惠卿、苏洵，以及欧阳修、梅尧臣、司马光。
· 想见知贡举欧阳修：酒楼「投行卷」只此一次；或连访大儒 3 次，依次得见欧阳修、梅尧臣、司马光。
· 见过的大儒可再拜访座谈：每次拣一个话题请教，追问在同席展开、不另计；话题谈尽，便只剩寒暄。"

var E
var save_path := "user://save.json"
var at_title := true

var title_view: VBoxContainer
var game_view: VBoxContainer
var art_rect: TextureRect
var tag_label: Label
var name_label: Label
var desc_label: Label
var acts_grid: GridContainer
var foot_label: Label
var meta_label: Label
var trip_label: Label
var money_label: Label
var ap_label: Label
var log_view: RichTextLabel
var pip_boxes := {}
var ap_dots: HBoxContainer
var overlay: Control
var overlay_panel: PanelContainer
var overlay_box: VBoxContainer
var poem_edit: TextEdit


func _ready() -> void:
	E = load("res://core/engine.gd").new()
	get_tree().auto_accept_quit = false
	_build_theme()
	_build_ui()
	_show_title()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if get_window().has_focus():
			print("[dbg] 用户关闭窗口，正常退出")
			get_tree().quit()
		else:
			print("[dbg] 后台关闭请求已忽略（进程存活）")
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		print("[dbg] 应用被系统暂停（App Nap）")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		print("[dbg] 应用从暂停恢复")


func _build_theme() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Songti SC", "STSong", "SimSun", "Noto Serif CJK SC", "PingFang SC"])
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 17
	theme = th


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_title_view()
	_build_game_view()
	_build_overlay()


func _build_title_view() -> void:
	title_view = VBoxContainer.new()
	title_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_view.add_theme_constant_override("separation", 14)
	title_view.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(title_view)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_CENTER)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := TextureRect.new()
	img.texture = _try_texture("res://assets/scroll.jpg")
	img.custom_minimum_size = Vector2(520, 140)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_view.add_child(margin)
	margin.add_child(img)

	var h1 := Label.new()
	h1.text = "北宋赶考记"
	h1.add_theme_font_size_override("font_size", 44)
	h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_view.add_child(h1)

	var sub := Label.new()
	sub.text = "嘉祐二年 · 丁酉 · 临川举子赴京应省试"
	sub.add_theme_color_override("font_color", INK3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_view.add_child(sub)

	var blurb := Label.new()
	blurb.text = "正月初十启程，二月入贡院。三十天里，你要在赶路、温书、歇息、交游之间取舍：\n智力管笔墨，精力管临场，人缘管引荐。三样任缺其一，这一科便走不到榜下。"
	blurb.add_theme_color_override("font_color", INK2)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_view.add_child(blurb)


func _rebuild_title_buttons() -> void:
	for c in title_view.get_children():
		if c is Button:
			c.queue_free()
	var cont := _has_save()
	var g = _read_save() if cont else null
	if g != null:
		var info := "第 %d 日 · %s" % [g.get("day", 1), E.C.SCENES[g.get("scene", 0)]["name"]]
		title_view.add_child(_mk_btn("继续上次（%s）" % info, _on_continue, true))
	title_view.add_child(_mk_btn("重新开始" if cont else "启程", _on_new_game, not cont))
	title_view.add_child(_mk_btn("凡 例", _on_help_title, false))


func _build_game_view() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	game_view = VBoxContainer.new()
	game_view.add_theme_constant_override("separation", 10)
	margin.add_child(game_view)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	game_view.add_child(header)

	var h1 := Label.new()
	h1.text = "北宋赶考记"
	h1.add_theme_font_size_override("font_size", 26)
	header.add_child(h1)

	var hs := Control.new()
	hs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hs)

	meta_label = Label.new()
	meta_label.add_theme_color_override("font_color", INK2)
	header.add_child(meta_label)

	for pair in [["凡例", _on_help], ["词条", _on_gloss_index], ["重开", _on_restart]]:
		header.add_child(_mk_btn(pair[0], pair[1], false))

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_view.add_child(body)

	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation", 8)
	body.add_child(stage)

	art_rect = TextureRect.new()
	art_rect.custom_minimum_size = Vector2(0, 300)
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(art_rect)

	tag_label = Label.new()
	tag_label.add_theme_color_override("font_color", RED)
	tag_label.add_theme_constant_override("line_spacing", 4)
	stage.add_child(tag_label)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 30)
	stage.add_child(name_label)

	desc_label = Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", INK2)
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_child(desc_label)

	acts_grid = GridContainer.new()
	acts_grid.columns = 3
	acts_grid.add_theme_constant_override("h_separation", 8)
	acts_grid.add_theme_constant_override("v_separation", 8)
	stage.add_child(acts_grid)

	foot_label = Label.new()
	foot_label.add_theme_color_override("font_color", INK3)
	stage.add_child(foot_label)

	var status := VBoxContainer.new()
	status.custom_minimum_size = Vector2(330, 0)
	status.add_theme_constant_override("separation", 8)
	body.add_child(status)

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 7)
	card.add_child(card_box)

	trip_label = Label.new()
	trip_label.add_theme_color_override("font_color", INK2)
	card_box.add_child(trip_label)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 20)
	card_box.add_child(money_label)

	for k in ["zhi", "jing", "yuan"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		card_box.add_child(row)
		var nm := Label.new()
		nm.text = {"zhi": "智力", "jing": "精力", "yuan": "人缘"}[k]
		nm.custom_minimum_size = Vector2(46, 0)
		row.add_child(nm)
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 3)
		pips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(pips)
		pip_boxes[k] = pips
		for i in range(10):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(12, 9)
			pips.add_child(pip)

	var ap_row := HBoxContainer.new()
	ap_row.add_theme_constant_override("separation", 6)
	card_box.add_child(ap_row)
	ap_label = Label.new()
	ap_label.text = "今日行动"
	ap_row.add_child(ap_label)
	ap_dots = HBoxContainer.new()
	ap_dots.add_theme_constant_override("separation", 5)
	ap_row.add_child(ap_dots)
	for i in range(4):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		ap_dots.add_child(dot)

	log_view = RichTextLabel.new()
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_theme_font_size_override("normal_font_size", 15)
	log_view.add_theme_color_override("default_color", INK2)
	log_view.scroll_following = true
	card_box.add_child(log_view)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.12, 0.08, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	overlay_panel = PanelContainer.new()
	overlay_panel.set_anchors_preset(Control.PRESET_CENTER)
	overlay_panel.custom_minimum_size = Vector2(680, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER2
	sb.border_color = Color(53, 42, 28, 0.4)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(26)
	overlay_panel.add_theme_stylebox_override("panel", sb)
	overlay.add_child(overlay_panel)

	overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 12)
	overlay_panel.add_child(overlay_box)


func _show_title() -> void:
	at_title = true
	title_view.visible = true
	game_view.visible = false
	overlay.visible = false
	_rebuild_title_buttons()


func _on_new_game() -> void:
	_clear_save()
	E.start_new()
	at_title = false
	title_view.visible = false
	game_view.visible = true
	persist()
	refresh()


func _on_continue() -> void:
	var g = _read_save()
	if g == null:
		_on_new_game()
		return
	E.apply_save(g)
	E.enter_day()
	at_title = false
	title_view.visible = false
	game_view.visible = true
	refresh()


func _on_restart() -> void:
	_show_title()


func _on_help_title() -> void:
	at_title = true
	title_view.visible = true
	game_view.visible = false
	overlay.visible = true
	E.S = E.fresh_state()
	E.S["help"] = true
	_refresh_overlay()


func _on_help() -> void:
	E.S["help"] = true
	refresh()


func _on_gloss_index() -> void:
	E.S["glossIndex"] = true
	refresh()


func persist() -> void:
	var c = E.save_game()
	if c == null:
		return
	var f = FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(c))
		f.flush()


func _has_save() -> bool:
	return FileAccess.file_exists(save_path)


func _read_save() -> Variant:
	if not _has_save():
		return null
	var f = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return null
	var g = JSON.parse_string(f.get_as_text())
	if g == null or typeof(g) != TYPE_DICTIONARY:
		return null
	return g


func _clear_save() -> void:
	if _has_save():
		DirAccess.open("user://").remove("save.json")


func refresh() -> void:
	if at_title:
		_show_title()
		return
	var S = E.S
	var sc = E.cur_scene()
	game_view.visible = true
	title_view.visible = false
	art_rect.texture = _try_texture("res://assets/scene_%s.jpg" % sc["id"], "res://assets/scene_bg.jpg")
	if S["phase"] == "over":
		tag_label.text = ("途中止步" if S["ending"]["kind"] == "fail" else "嘉祐二年 · 唱名")
		name_label.text = S["ending"].get("rank", S["ending"].get("title", "—"))
		desc_label.text = S["ending"].get("text", "")
		foot_label.text = "省试 %d/15 · 殿试 %d/3 · 第 %d 日 · 诗 %d 首" % [S["exam"]["total"], S["exam"]["palace"], S["day"], S["poems"].size()]
		_clear_acts()
		acts_grid.add_child(_mk_btn("再赴一科", _on_restart, true))
		meta_label.text = ""
		_refresh_status()
		_refresh_overlay()
		return
	meta_label.text = "第 %d / 30 日 · %s" % [S["day"], E.date_label(S["day"])]
	tag_label.text = sc["tag"]
	_refresh_stage(sc)
	_refresh_status()
	_refresh_overlay()


func _refresh_stage(sc) -> void:
	var S = E.S
	match S["phase"]:
		"play":
			name_label.text = sc["name"]
			desc_label.text = sc["desc"]
			foot_label.text = "今日余 %d 点行动 · 食宿约 %d 贯" % [S["ap"], 2 if S["day"] >= 16 else 1]
			_clear_acts()
			for id in sc.get("acts", []):
				if not E.ACT.has(id):
					continue
				var a = E.ACT[id]
				if a.has("hide_if") and a["hide_if"].call():
					continue
				var btn = _mk_act_btn(id, a)
				acts_grid.add_child(btn)
		"exam", "roundEnd":
			var r = E.C.EXAM_ROUNDS[E.S["exam"]["round"] - 1] if E.S["exam"]["round"] >= 1 else "省试 · 入场"
			name_label.text = r
			if S["phase"] == "roundEnd":
				desc_label.text = "你搁下笔，掌心全是汗。这一场答对 %d 题（共 5 题）。" % S["exam"]["correct"]
				_clear_acts()
				acts_grid.add_child(_mk_btn("进入下一场" if S["exam"]["round"] < 3 else "交卷出闱", _on_next_round, true))
			else:
				desc_label.text = "号舍里静得能听见蜡烛燃烧。你展开卷子，深吸一口气。"
				_clear_acts()
				acts_grid.add_child(_mk_btn("展卷作答（第 %d / 5 题）" % (S["exam"]["cur"] + 1), _on_open_question, true))
			foot_label.text = ""
		"result":
			var passed = S["exam"]["total"] >= 8
			name_label.text = "省试放榜"
			desc_label.text = "三场合计答对 %d 题（满分 15）。%s" % [S["exam"]["total"],
				"知贡举取中了你，名字列在榜上。三日后入宫殿试——这一科，你已经脱了白身的一半。" if passed else "榜上没有你的名字。你在人群外站了很久，把带来的书又翻了一遍。"]
			_clear_acts()
			acts_grid.add_child(_mk_btn("入宫应殿试" if passed else "收拾行囊回乡", _on_go_on if passed else _on_fail_exam, true))
			foot_label.text = ""
		"palace", "palaceEnd":
			name_label.text = "殿试"
			if S["phase"] == "palaceEnd":
				desc_label.text = "你答对 %d 题（共 3 题）。皇帝未置一词，只在卷首点了两下。" % S["exam"]["palace"]
				_clear_acts()
				acts_grid.add_child(_mk_btn("谢恩出宫", _on_banquet, true))
			else:
				desc_label.text = "殿上烛火高照，策题落在你面前。两旁的官员都不出声。"
				_clear_acts()
				acts_grid.add_child(_mk_btn("跪读策题（第 %d / 3 题）" % (S["exam"]["pcur"] + 1), _on_open_question, true))
			foot_label.text = ""
		"banquet":
			name_label.text = "琼林宴"
			desc_label.text = "琼林苑里杏花初开，新科进士列坐。有人举杯，有人低语。你忽然想起三十日前，临川老宅的那盏灯。"
			_clear_acts()
			acts_grid.add_child(_mk_btn("入席（看结局）", _on_finale, true))
			foot_label.text = ""
		_:
			name_label.text = sc["name"]
			desc_label.text = sc["desc"]
			_clear_acts()


func _clear_acts() -> void:
	for c in acts_grid.get_children():
		c.queue_free()


func _refresh_status() -> void:
	var S = E.S
	if S["phase"] == "over":
		trip_label.text = ""
		money_label.text = ""
		ap_label.text = ""
		for k in pip_boxes:
			_set_pips(pip_boxes[k], 0, Color(0, 0, 0, 0))
		for d in ap_dots.get_children():
			d.color = Color(0, 0, 0, 0)
	else:
		trip_label.text = "行程 · %s" % E.cur_scene()["tag"]
		money_label.text = "盘缠 %d 贯" % S["money"]
		_set_pips(pip_boxes["zhi"], S["zhi"], BLUE)
		_set_pips(pip_boxes["jing"], S["jing"], GOLD)
		_set_pips(pip_boxes["yuan"], S["yuan"], RED)
		ap_label.text = "今日行动" if S["phase"] == "play" else ""
		var dots = ap_dots.get_children()
		for i in range(dots.size()):
			dots[i].color = INK if (S["phase"] == "play" and i < S["ap"]) else Color(53, 42, 28, 0.12)
	log_view.clear()
	for l in E.S["log"]:
		var prefix = E.date_label(l["d"]) + "　" if l["d"] != null else ""
		log_view.add_text(prefix + l["t"] + "\n")


func _set_pips(pips: HBoxContainer, on: int, color: Color) -> void:
	var ch = pips.get_children()
	for i in range(ch.size()):
		ch[i].color = color if i < on else Color(53, 42, 28, 0.1)


func _refresh_overlay() -> void:
	_clear_overlay()
	var S = E.S
	if S["pending"] != null:
		overlay.visible = true
		_show_question(S["pending"])
	elif S["gloss"] != null:
		overlay.visible = true
		_show_gloss(S["gloss"])
	elif S["glossIndex"]:
		overlay.visible = true
		_show_gloss_index()
	elif S["event"] != null:
		overlay.visible = true
		_show_event(S["event"])
	elif S.get("letter", null) != null:
		overlay.visible = true
		_show_letter(S["letter"])
	elif S["poem"] != null:
		overlay.visible = true
		_show_poem(S["poem"])
	elif S["help"]:
		overlay.visible = true
		_show_help()
	else:
		overlay.visible = false


func _clear_overlay() -> void:
	for c in overlay_box.get_children():
		c.queue_free()


func _show_question(p) -> void:
	var S = E.S
	var q = p["q"]
	var fb = S["feedback"]
	var strike = E.exam_strike_letter(q) if fb == null else ""
	var tag = "温书 · 随手一题"
	if p["kind"] == "exam":
		tag = "%s · 第 %d / 5 题" % [E.C.EXAM_ROUNDS[S["exam"]["round"] - 1], S["exam"]["cur"] + 1]
	elif p["kind"] == "palace":
		tag = "殿试 · 第 %d / 3 题" % [S["exam"]["pcur"] + 1]
	_add_overlay_tag(tag + " · " + q["era"])
	var stem := Label.new()
	stem.text = q["stem"]
	stem.add_theme_font_size_override("font_size", 22)
	stem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(stem)
	for i in range(4):
		var letter = E.LETTERS[i]
		var btn = _mk_btn("%s．%s" % [letter, q["options"][letter]], _on_answer.bind(i), false)
		btn.disabled = fb != null or strike == letter
		if fb != null and letter == q["answer"]:
			btn.add_theme_color_override("font_color", Color("67703f"))
		elif fb != null and letter == fb.get("my", ""):
			btn.add_theme_color_override("font_color", RED)
		elif strike == letter:
			btn.add_theme_color_override("font_color", INK3)
		overlay_box.add_child(btn)
	if fb != null:
		var f := Label.new()
		f.text = "%s。正确答案：%s。%s" % ["答对了" if fb["ok"] else "答错了", fb["answer"], fb["explain"]]
		f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f.add_theme_color_override("font_color", INK2)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(f)
		overlay_box.add_child(_mk_btn("继 续", _on_cont_answer, true))


func _show_event(e) -> void:
	_add_overlay_tag("行程小记")
	var t := Label.new()
	t.text = e["title"]
	t.add_theme_font_size_override("font_size", 22)
	overlay_box.add_child(t)
	var body := Label.new()
	body.text = e["text"]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", INK2)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(body)
	if e["done"]:
		var m := Label.new()
		m.text = e.get("msg", "")
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(m)
		overlay_box.add_child(_mk_btn("继 续", _on_event_ok, true))
	else:
		var S = E.S
		var num := ["一", "二", "三"]
		for i in range(e["choice"].size()):
			var c = e["choice"][i]
			var dis = (c.get("needSafe", false) and not S["safe"].get(e.get("safeKey", ""), false)) or (c.has("req") and c["req"].has("yuan") and S["yuan"] < c["req"]["yuan"])
			var btn = _mk_btn("%s．%s" % [num[i] if i < 3 else str(i + 1), c["label"]], _on_choose_event.bind(i), false)
			btn.disabled = dis
			if dis:
				btn.add_theme_color_override("font_color", INK3)
			overlay_box.add_child(btn)


func _show_letter(letter) -> void:
	_add_overlay_tag("省试前夜 · 贡院门外")
	var t := Label.new()
	t.text = "有人从门缝里递进一纸短笺"
	t.add_theme_font_size_override("font_size", 22)
	overlay_box.add_child(t)
	var body := Label.new()
	body.text = letter["text"]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", INK2)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(body)
	var eff := Label.new()
	eff.text = letter["effect"]
	eff.add_theme_color_override("font_color", GOLD)
	eff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(eff)
	overlay_box.add_child(_mk_btn("收好，入场", _on_close_letter, true))


func _show_poem(po) -> void:
	var th = {}
	for t in E.C.POEM_THEMES:
		if t["key"] == po["theme"]:
			th = t
	if po["result"] == null:
		_add_overlay_tag(("驿壁留题" if po["mode"] == "poem" else "街头鬻诗") + " · " + th["name"])
		var prompt := Label.new()
		prompt.text = th["prompt"]
		prompt.add_theme_font_size_override("font_size", 20)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(prompt)
		var hint := Label.new()
		hint.text = "四样齐了便是上品：一切题，二四句且每句字数一样，三不能照抄古人成句，四不得写白话。抄与白话判下品，当众折一分人缘；离题、不齐判中品，无酬。"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", INK3)
		hint.add_theme_font_size_override("font_size", 14)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(hint)
		poem_edit = TextEdit.new()
		poem_edit.custom_minimum_size = Vector2(0, 150)
		poem_edit.placeholder_text = th["ex"]
		poem_edit.add_theme_font_size_override("font_size", 19)
		overlay_box.add_child(poem_edit)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 10)
		overlay_box.add_child(row)
		row.add_child(_mk_btn("改日再写", _on_poem_cancel, false))
		row.add_child(_mk_btn("落 笔", _on_poem_submit, true))
	else:
		var r = po["result"]
		_add_overlay_tag(str(r["theme"]) + " · " + " · ".join(r["notes"]))
		var lines := Label.new()
		lines.text = "\n".join(r["lines"])
		lines.add_theme_font_size_override("font_size", 21)
		overlay_box.add_child(lines)
		var f := Label.new()
		f.text = "评曰%s%s。%s" % [r["grade"], ("，得 %d 贯" % r["reward"]) if r["reward"] > 0 else "，未得程仪", r["note"]]
		f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f.add_theme_color_override("font_color", INK2)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(f)
		overlay_box.add_child(_mk_btn("收 笔", _on_poem_done, true))


func _show_help() -> void:
	_add_overlay_tag("凡例")
	var t := Label.new()
	t.text = "怎么玩"
	t.add_theme_font_size_override("font_size", 22)
	overlay_box.add_child(t)
	var body := Label.new()
	body.text = HELP_TEXT
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", INK2)
	body.add_theme_font_size_override("font_size", 15)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(body)
	overlay_box.add_child(_mk_btn("知道了" if not at_title and E.S.get("day", 1) != 1 else "知道了，启程", _on_close_help, true))


func _show_gloss(term: String) -> void:
	var g = E.GLOSSARY.get(term, {"def": "", "src": [], "note": ""})
	_add_overlay_tag("词条")
	var t := Label.new()
	t.text = term
	t.add_theme_font_size_override("font_size", 24)
	overlay_box.add_child(t)
	var d := Label.new()
	d.text = g["def"]
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_color_override("font_color", INK2)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(d)
	for x in g.get("src", []):
		var s := Label.new()
		if x.has("quote"):
			s.text = "%s原文：“%s”" % [x["book"], x["quote"]]
		else:
			s.text = "%s所述：%s" % [x["book"], x.get("gist", "")]
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.add_theme_color_override("font_color", INK3)
		s.add_theme_font_size_override("font_size", 15)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(s)
	if g.get("note", "") != "":
		var n := Label.new()
		n.text = g["note"]
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.add_theme_color_override("font_color", GOLD)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_child(n)
	overlay_box.add_child(_mk_btn("知 道", _on_close_gloss, true))


func _show_gloss_index() -> void:
	_add_overlay_tag("词条索引 · 共 %d 条" % E.GLOSSARY.size())
	var t := Label.new()
	t.text = "这一路会遇到的词"
	t.add_theme_font_size_override("font_size", 22)
	overlay_box.add_child(t)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(grid)
	for term in E.GLOSSARY:
		var btn := _mk_btn(term, _on_term.bind(term), false)
		grid.add_child(btn)
	overlay_box.add_child(_mk_btn("合 上", _on_close_index, true))


func _add_overlay_tag(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", RED)
	l.add_theme_font_size_override("font_size", 13)
	overlay_box.add_child(l)


func _mk_act_btn(id: String, a: Dictionary) -> Button:
	var badge = E.term_badge(a["name"] + a["hint"])
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(210, 64)
	btn.disabled = E.S["ap"] < a["ap"]
	btn.pressed.connect(_on_act.bind(id))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(box)
	var nm := Label.new()
	nm.text = a["name"] + ("〔解〕" if badge != "" else "")
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.add_theme_font_size_override("font_size", 18)
	if a.get("primary", false):
		nm.add_theme_color_override("font_color", RED)
	box.add_child(nm)
	var hint := Label.new()
	hint.text = a["hint"]
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_color_override("font_color", INK3)
	hint.add_theme_font_size_override("font_size", 13)
	box.add_child(hint)
	return btn


func _mk_btn(text: String, cb: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	if primary:
		b.add_theme_color_override("font_color", RED)
		b.add_theme_color_override("font_hover_color", RED)
	b.pressed.connect(cb)
	return b


func _try_texture(path: String, fallback: String = "") -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if fallback != "" and ResourceLoader.exists(fallback):
		return load(fallback)
	return null


func _on_act(id: String) -> void:
	E.do_act(id)
	persist()
	refresh()


func _on_answer(i: int) -> void:
	E.answer(i)
	refresh()


func _on_cont_answer() -> void:
	E.continue_after_answer()
	refresh()


func _on_open_question() -> void:
	E.open_question()
	refresh()


func _on_next_round() -> void:
	E.next_round()
	persist()
	refresh()


func _on_go_on() -> void:
	E.go_on()
	persist()
	refresh()


func _on_fail_exam() -> void:
	E.fail_exam()
	_clear_save()
	refresh()


func _on_banquet() -> void:
	E.banquet_act()
	refresh()


func _on_finale() -> void:
	E.finale()
	_clear_save()
	refresh()


func _on_close_letter() -> void:
	E.close_letter()
	refresh()


func _on_event_ok() -> void:
	E.event_ok()
	refresh()


func _on_choose_event(i: int) -> void:
	E.choose_event(i)
	persist()
	refresh()


func _on_poem_submit() -> void:
	E.poem_submit(poem_edit.text)
	persist()
	refresh()


func _on_poem_cancel() -> void:
	E.poem_cancel()
	refresh()


func _on_poem_done() -> void:
	E.poem_done()
	persist()
	refresh()


func _on_close_help() -> void:
	E.S["help"] = false
	refresh()


func _on_close_gloss() -> void:
	E.S["gloss"] = null
	refresh()


func _on_close_index() -> void:
	E.S["glossIndex"] = false
	refresh()


func _on_term(term: String) -> void:
	E.S["gloss"] = term
	E.S["glossIndex"] = false
	refresh()
