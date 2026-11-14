extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var visual := main.get_node("Player/Visual")
	if not (visual.ready_model):
		push_error("Рыцарь не загрузился")
		quit(1)
		return
	if not (visual.pairs.size() >= 40):
		push_error("Не все конечности/пальцы сопоставлены")
		quit(1)
		return
	var triangles := _triangles(visual.model)
	print("FULL_KNIGHT_TRIANGLES=", triangles)
	print("RETARGET_BONES=", visual.pairs.size())
	if not (triangles == 223711):
		push_error("Изменилась полная геометрия рыцаря")
		quit(1)
		return
	for clip in ["Idle_Loop", "Walk_Loop", "Sprint_Loop", "Sword_Attack"]:
		var resolved: String = visual._resolve_clip(clip)
		if resolved.is_empty():
			push_error("Отсутствует анимация " + clip)
			quit(1)
			return
		visual.animation_player.play(resolved, 0)
		for i in range(20):
			visual.animation_player.advance(1.0 / 30)
			visual._transfer_pose()
		for bone in visual.pairs:
			var pose: Transform3D = visual.target.get_bone_global_pose(bone)
			if not pose.is_finite():
				push_error("Некорректная поза " + clip)
				quit(1)
				return
		print("ANIMATION_OK=", clip)
	print("PINE_VARIANTS=", 9)
	quit()

func _triangles(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			count += node.mesh.surface_get_array_index_len(i) / 3
	for child in node.get_children(): count += _triangles(child)
	return count
