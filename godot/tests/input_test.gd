extends SceneTree

var fails := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = load("res://ui/main.tscn").instantiate()
	main.save_path = "user://test_input.json"
	root.add_child(main)
	await process_frame

	var names := ["bg", "title_view", "margin", "overlay"]
	for i in range(4):
		var c = main.get_child(i)
		print("layer %s: filter=%d visible=%s rect=%s" % [names[i], c.mouse_filter, c.visible, c.get_global_rect()])

	var target: Button = null
	for c in main.title_view.get_children():
		if c is Button and (c.text.begins_with("启程") or c.text.begins_with("重新开始")):
			target = c
			break
	ok(target != null, "找到「启程」按钮")
	if target != null:
		var blocker = _blocker_at(main, target)
		ok(blocker == null, "点击命中的最顶层拦截控件就是按钮（实际拦截：%s）" % (blocker.name if blocker != null else "无"))
		target.pressed.emit()
		await process_frame
		ok(not main.at_title, "按钮信号 → 进入主界面")
		if not main.at_title:
			ok(main.E.S["help"] == true, "开局凡例弹出")
			main._on_close_help()
			ok(main.E.S["phase"] == "play", "关闭凡例进入游玩态")

	var saved = main._has_save()
	print("（隔离存档存在：%s）" % str(saved))

	main.E.S = main.E.fresh_state()
	main.E.S["day"] = 5
	main.E.add_log("测试行记")
	var c = main.E.save_game()
	var f = FileAccess.open("user://test_input.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(c))
	f.flush()
	main._on_restart()
	var cont_btn: Button = null
	for b in main.title_view.get_children():
		if b is Button and b.text.begins_with("继续上次"):
			cont_btn = b
			break
	ok(cont_btn != null, "标题页出现「继续上次」")
	if cont_btn != null:
		cont_btn.pressed.emit()
		ok(not main.at_title and main.E.S["day"] == 5, "继续上次：恢复第 5 日并进入游戏")
		ok(main.E.S["phase"] == "play", "读档后为游玩态")

	print("== 输入路由 %s ==" % ("全部通过" if fails == 0 else "%d 例失败" % fails))
	quit(0 if fails == 0 else 1)


func _blocker_at(root: Control, target: Button) -> Control:
	var pos = target.get_global_rect().get_center()
	var chain: Array = []
	_collect(root, chain)
	for i in range(chain.size() - 1, -1, -1):
		var c = chain[i]
		if not _effective_visible(c):
			continue
		if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if not c.get_global_rect().has_point(pos):
			continue
		if c == target:
			return null
		if c.mouse_filter == Control.MOUSE_FILTER_STOP:
			return c
	return null


func _effective_visible(c: Control) -> bool:
	var p: Node = c
	while p is Control:
		if not (p as Control).visible:
			return false
		p = p.get_parent()
	return true


func _collect(c: Control, out: Array) -> void:
	for ch in c.get_children():
		if ch is Control:
			out.append(ch)
			_collect(ch, out)


func ok(cond: bool, name: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + name)
	if not cond:
		fails += 1
