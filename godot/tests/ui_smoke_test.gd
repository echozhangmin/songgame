extends SceneTree

var fails := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = load("res://ui/main.tscn").instantiate()
	main.save_path = "user://test_smoke.json"
	root.add_child(main)
	await process_frame

	ok(main.at_title, "标题页可见")
	main._on_new_game()
	ok(not main.at_title and main.game_view.visible, "开局进入主界面")
	ok(main.E.S["help"] == true, "开局弹凡例")
	main._on_close_help()
	ok(main.E.S["help"] == false, "凡例关闭")

	main._on_act("study")
	ok(main.E.S["pending"] != null and main.E.S["pending"]["kind"] == "study", "温书弹题")
	var q = main.E.S["pending"]["q"]
	main._on_answer("ABCD".find(q["answer"]))
	ok(main.E.S["feedback"] != null, "答题出反馈")
	main._on_cont_answer()
	ok(main.E.S["pending"] == null, "反馈关闭")

	main._on_act("master")
	ok(main.E.S["met"].has("xiansheng"), "家塾初访遇乡先生")
	main._on_act("master")
	ok(main.E.S["event"] != null and main.E.S["event"].get("tag", "") == "talk" and main.E.S["event"]["choice"].size() == 3, "再访开座谈（3 话题）")
	main._on_choose_event(0)
	ok(main.E.S["event"]["done"] == true, "话题选定转完成态")
	main._on_event_ok()
	ok(main.E.S["event"] == null, "座谈关闭")

	main._on_act("sleep")
	ok(main.E.S["day"] == 2, "就寝进入第 2 日")
	main._on_act("rest")
	main._on_act("sleep")
	ok(main.E.S["day"] == 3 and main.E.S["scene"] == 1, "第 3 日长亭")
	var zg = main.E.S["zhi"]
	main._on_act("giftBooks")
	ok(main.E.S["day"] == 4 and main.E.S["zhi"] == zg + 2, "受赠旧书：智力+2 且当日即终")

	ok(main._has_save(), "存档已写入")

	print("== UI 冒烟 %s ==" % ("全部通过" if fails == 0 else "%d 例失败" % fails))
	quit(0 if fails == 0 else 1)


func ok(cond: bool, name: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + name)
	if not cond:
		fails += 1
