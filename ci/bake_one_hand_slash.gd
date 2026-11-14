extends SceneTree
## Однократная подготовка CC0 KayKit-клипа под риг UAL, используемый контроллером.
func _initialize() -> void: _run.call_deferred()
func _find(node: Node, kind: String) -> Node:
	if node.is_class(kind): return node
	for child in node.get_children():
		var result := _find(child, kind)
		if result: return result
	return null
func _run() -> void:
	var a: Node3D = load("res://assets/animations/kaykit/combat.glb").instantiate()
	var b: Node3D = load("res://assets/animations/AnimationLibrary_Godot_Standard.gltf").instantiate()
	root.add_child(a)
	root.add_child(b)
	var source := _find(a, "Skeleton3D") as Skeleton3D
	var target := _find(b, "Skeleton3D") as Skeleton3D
	var source_player := _find(a, "AnimationPlayer") as AnimationPlayer
	var target_player := _find(b, "AnimationPlayer") as AnimationPlayer
	for player in [source_player, target_player]: player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	target_player.play("Sword_Idle", 0)
	target_player.advance(0)
	var baseline: Array[Transform3D] = []
	for i in range(target.get_bone_count()): baseline.append(target.get_bone_pose(i))
	var names := {"DEF-hips":"hips", "DEF-spine.001":"spine", "DEF-spine.002":"chest", "DEF-spine.003":"chest", "DEF-neck":"head", "DEF-head":"head"}
	for side in ["L", "R"]:
		for pair in [["upper_arm", "upperarm"], ["forearm", "lowerarm"], ["hand", "wrist"], ["thigh", "upperleg"], ["shin", "lowerleg"], ["foot", "foot"], ["toe", "toes"]]:
			names["DEF-" + pair[0] + "." + side] = pair[1] + "." + side.to_lower()
	var pairs := {}
	var corrections := {}
	for name_value in names:
		var i := target.find_bone(name_value)
		var j := source.find_bone(names[name_value])
		if i < 0 or j < 0: continue
		pairs[i] = j
		var alignment := Basis.IDENTITY
		var end_target := ""
		var end_source := ""
		for side in ["L", "R"]:
			for chain in [["upper_arm", "forearm", "lowerarm"], ["forearm", "hand", "wrist"], ["hand", "f_middle.01", "hand"], ["thigh", "shin", "lowerleg"], ["shin", "foot", "foot"], ["foot", "toe", "toes"]]:
				if name_value == "DEF-" + chain[0] + "." + side:
					end_target = "DEF-" + chain[1] + "." + side
					end_source = chain[2] + "." + side.to_lower()
		if not end_target.is_empty():
			var target_direction := (target.get_bone_global_rest(target.find_bone(end_target)).origin - target.get_bone_global_rest(i).origin).normalized()
			var source_direction := (source.get_bone_global_rest(source.find_bone(end_source)).origin - source.get_bone_global_rest(j).origin).normalized()
			alignment = Basis(Quaternion(target_direction, source_direction))
		corrections[i] = source.get_bone_global_rest(j).basis.orthonormalized().inverse() * alignment * target.get_bone_global_rest(i).basis.orthonormalized()
	var animation := Animation.new()
	animation.resource_name = "Knight_OneHand_Diagonal"
	animation.length = source_player.get_animation("Melee_1H_Attack_Slice_Diagonal").length
	var skeleton_path := target_player.get_node(target_player.root_node).get_path_to(target)
	var tracks := {}
	for i in range(target.get_bone_count()):
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath(str(skeleton_path) + ":" + target.get_bone_name(i)))
		tracks[i] = track
	var hips := target.find_bone("DEF-hips")
	var source_hips := source.find_bone("hips")
	var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(position_track, NodePath(str(skeleton_path) + ":DEF-hips"))
	source_player.play("Melee_1H_Attack_Slice_Diagonal", 0)
	for frame in range(61):
		var time := animation.length * frame / 60.0
		source_player.seek(time, true)
		source_player.advance(0)
		for i in range(target.get_bone_count()):
			target.set_bone_pose_position(i, baseline[i].origin)
			target.set_bone_pose_rotation(i, baseline[i].basis.get_rotation_quaternion())
		for i in range(target.get_bone_count()):
			if not pairs.has(i): continue
			var desired: Basis = source.get_bone_global_pose(pairs[i]).basis.orthonormalized() * corrections[i]
			var parent := target.get_bone_parent(i)
			var parent_basis := target.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
			target.set_bone_pose_rotation(i, (parent_basis.inverse() * desired).orthonormalized().get_rotation_quaternion())
		var ratio := target.get_bone_global_rest(hips).origin.y / source.get_bone_global_rest(source_hips).origin.y
		var delta := (source.get_bone_global_pose(source_hips).origin - source.get_bone_global_rest(source_hips).origin) * ratio
		target.set_bone_pose_position(hips, baseline[hips].origin + delta)
		for i in tracks: animation.rotation_track_insert_key(tracks[i], time, target.get_bone_pose_rotation(i))
		animation.position_track_insert_key(position_track, time, target.get_bone_pose_position(hips))
	var error := ResourceSaver.save(animation, "res://assets/animations/kaykit/one_hand_slash.tres")
	print("KAYKIT_SLASH_BAKED bones=", pairs.size(), " duration=", animation.length, " error=", error)
	quit(0 if error == OK else 1)
