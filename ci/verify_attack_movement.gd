extends SceneTree
var failed := false
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	main.get_node("Player").set_physics_process(false)
	var visual := main.get_node("Player/Visual")
	var reference := Node3D.new()
	reference.set_script(load("res://scripts/HumanoidVisual.gd"))
	main.add_child(reference)
	reference.build()
	for speed in [3.0, 5.5]:
		var clip: String = visual._resolve_clip("Sprint_Loop" if speed > 3.4 else "Walk_Loop")
		for actor in [visual, reference]:
			actor.strike_remaining = 0.0
			actor.strike_weight = 0.0
			actor.animation_player.play(clip, 0.0)
			actor.animation_player.seek(0.0, true)
			actor.animation_player.advance(0.0)
		visual.swing()
		var ankle: int = visual._target_bone("foot.l")
		var start: Transform3D = visual.target.get_bone_global_pose(ankle)
		var leg_moved := false
		var upper_changed := false
		for frame in range(60):
			visual.animate_motion(1.0 / 60, speed)
			reference.animate_motion(1.0 / 60, speed)
			for prefix in ["thigh_stretch", "leg_stretch", "foot", "toes_01"]:
				for side in ["l", "r"]:
					var bone: int = visual._target_bone(prefix + "." + side)
					var pose: Transform3D = visual.target.get_bone_global_pose(bone)
					var expected: Transform3D = reference.target.get_bone_global_pose(bone)
					if not pose.is_equal_approx(expected):
						push_error("Удар изменил анимацию ног при скорости " + str(speed))
						failed = true
			var foot: Transform3D = visual.target.get_bone_global_pose(ankle)
			if foot.origin.distance_to(start.origin) > .05: leg_moved = true
			var arm: int = visual._target_bone("forearm_stretch.r")
			if not visual.target.get_bone_global_pose(arm).basis.is_equal_approx(reference.target.get_bone_global_pose(arm).basis): upper_changed = true
			if visual.animation_player.current_animation != clip:
				push_error("Удар остановил цикл движения")
				failed = true
		if not leg_moved or not upper_changed:
			push_error("Не проигрывается один из слоёв")
			failed = true
		print("ATTACK_WITH_MOVEMENT speed=", speed, " legs_move=", leg_moved, " upper_attacks=", upper_changed)
	reference.queue_free()
	quit(1 if failed else 0)
