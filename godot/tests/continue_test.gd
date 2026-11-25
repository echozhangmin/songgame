extends SceneTree
var fails := 0
func _init(): _run.call_deferred()
func _run() -> void:
	var main = load("res://ui/main.tscn").instantiate()
	main.save_path = "user://test_continue.json"
	root.add_child(main)
	await process_frame
	var rf = FileAccess.open("/tmp/real_save.json", FileAccess.READ)
	var wf = FileAccess.open("user://test_continue.json", FileAccess.WRITE)
	wf.store_string(rf.get_as_text())
	wf.flush()
	main._on_restart()
	var btn: Button = null
	for b in main.title_view.get_children():
		if b is Button and b.text.begins_with("继续上次"):
			btn = b
			break
	ok(btn != null, "标题页有「继续上次」")
	if btn != null:
		btn.pressed.emit()
		await process_frame
		ok(not main.at_title, "点击后离开标题页")
		ok(main.E.S["day"] == 4, "恢复第 4 日（实为 %d）" % main.E.S["day"])
		ok(main.E.S["scene"] == 2, "驿站场景")
		ok(main.game_view.visible, "主界面可见")
	print("== 继续上次 %s ==" % ("全部通过" if fails == 0 else "%d 例失败" % fails))
	quit(0 if fails == 0 else 1)
func ok(c: bool, n: String) -> void:
	print(("PASS  " if c else "FAIL  ") + n)
	if not c: fails += 1
