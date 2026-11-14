extends Node3D
## Полная модель рыцаря. Движения — Quaternius UAL (CC0), ретаргетинг по костям.
const HERO = preload("res://assets/models/forgotten_knight/knight.glb")
const MOTIONS = preload("res://assets/animations/AnimationLibrary_Godot_Standard.gltf")
var target: Skeleton3D
var source: Skeleton3D
var animation_player: AnimationPlayer
var model: Node3D
var motion_model: Node3D
var pairs: Dictionary = {}
var source_rest: Dictionary = {}
var target_rest: Dictionary = {}
var pose_corrections: Dictionary = {}
var grip_pose: Dictionary = {}
var strike_remaining := 0.0
var ready_model := false
var hips_target := -1
var hips_source := -1
var base_hips_position := Vector3.ZERO

func build(_enemy := false) -> void:
	model = HERO.instantiate()
	add_child(model)
	target = _find_skeleton(model)
	assert(target != null, "У рыцаря отсутствует Skeleton3D")
	# Розы — отдельные декоративные меши исходного ассета, для игры они не нужны.
	for decoration in ["Object_4", "Object_5"]:
		var flowers := model.find_child(decoration, true, false) as Node3D
		if flowers: flowers.hide()
	var bounds := _bounds(model, Transform3D.IDENTITY)
	var factor := 1.8 / maxf(bounds.size.y, 0.01)
	model.scale = Vector3.ONE * factor
	model.rotation.y = PI
	model.position = Vector3(-bounds.get_center().x * factor, -0.9 - bounds.position.y * factor, bounds.get_center().z * factor)
	motion_model = MOTIONS.instantiate()
	add_child(motion_model)
	motion_model.rotation.y = PI
	source = _find_skeleton(motion_model)
	animation_player = _find_animation(motion_model)
	assert(source != null and animation_player != null, "Не удалось загрузить UAL")
	# Исходный манекен служит только источником поз; в кадре остаётся полный рыцарь.
	_hide_meshes(motion_model)
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_map("DEF-hips", "root.x")
	_map("DEF-spine.002", "spine_01.x")
	_map("DEF-neck", "neck.x")
	_map("DEF-head", "head.x")
	for side in ["L", "R"]:
		var suffix: String = side.to_lower()
		_map("DEF-shoulder." + side, "shoulder." + suffix)
		_map("DEF-upper_arm." + side, "arm_stretch." + suffix)
		_map("DEF-forearm." + side, "forearm_stretch." + suffix)
		_map("DEF-hand." + side, "hand." + suffix)
		_map("DEF-thigh." + side, "thigh_stretch." + suffix)
		_map("DEF-shin." + side, "leg_stretch." + suffix)
		_map("DEF-foot." + side, "foot." + suffix)
		_map("DEF-toe." + side, "toes_01." + suffix)
		for finger in ["index", "middle", "ring", "pinky", "thumb"]:
			for joint in range(1, 4):
				var source_name := "DEF-%s.%02d.%s" % ["thumb" if finger == "thumb" else "f_" + finger, joint, side]
				_map(source_name, "%s%d.%s" % [finger, joint, suffix])
	for i in range(source.get_bone_count()): source_rest[i] = source.get_bone_global_rest(i)
	for i in range(target.get_bone_count()): target_rest[i] = target.get_bone_global_rest(i)
	_prepare_retarget_pose()
	hips_target = _target_bone("root.x")
	hips_source = source.find_bone("DEF-hips")
	base_hips_position = target.get_bone_pose_position(hips_target)
	for name_value in animation_player.get_animation_list():
		if name_value.ends_with("Loop") or name_value in ["Sword_Idle", "Idle_Loop"]:
			animation_player.get_animation(name_value).loop_mode = Animation.LOOP_LINEAR
	# Сохраняем закрытую правую ладонь из готовой анимации владения мечом.
	_play("Sword_Idle", 0.0)
	animation_player.advance(0.0)
	_transfer_pose()
	for finger in ["index", "middle", "ring", "pinky", "thumb"]:
		for joint in range(1, 4):
			var bone := _target_bone("%s%d.r" % [finger, joint])
			if bone >= 0: grip_pose[bone] = target.get_bone_pose_rotation(bone)
	_play("Idle_Loop", 0.0)
	animation_player.advance(0.0)
	_transfer_pose()
	_ready_weapon()
	ready_model = true

func _map(source_name: String, target_prefix: String) -> void:
	var a := source.find_bone(source_name)
	var b := _target_bone(target_prefix)
	if a >= 0 and b >= 0: pairs[b] = a

func _target_bone(prefix: String) -> int:
	for i in range(target.get_bone_count()):
		if target.get_bone_name(i).begins_with(prefix + "_"):
			return i
	return -1

func _prepare_retarget_pose() -> void:
	# UAL создан в T-позе, а рыцарь — с опущенными руками (A-поза).
	# Сначала совмещаем направления костей исходных поз, затем переносим движение.
	var child_names := {
		"shoulder": "arm_stretch", "arm_stretch": "forearm_stretch",
		"forearm_stretch": "hand", "hand": "middle1",
		"thigh_stretch": "leg_stretch", "leg_stretch": "foot", "foot": "toes_01"
	}
	for bone in pairs:
		var source_bone: int = pairs[bone]
		var alignment := Basis.IDENTITY
		for side in ["l", "r"]:
			for prefix in child_names:
				if bone != _target_bone(prefix + "." + side): continue
				var child := _target_bone(child_names[prefix] + "." + side)
				if child < 0 or not pairs.has(child): continue
				var target_direction: Vector3 = (target_rest[child].origin - target_rest[bone].origin).normalized()
				var source_direction: Vector3 = (source_rest[pairs[child]].origin - source_rest[source_bone].origin).normalized()
				alignment = Basis(Quaternion(target_direction, source_direction))
		pose_corrections[bone] = (source_rest[source_bone] as Transform3D).basis.orthonormalized().inverse() * alignment * (target_rest[bone] as Transform3D).basis.orthonormalized()

func _transfer_pose() -> void:
	# Все матрицы в локальном пространстве Skeleton3D; оба рига имеют одинаковый поворот.
	# Коррекция rest-позы рассчитана один раз, лишних мировых матриц на каждом кадре нет.
	for i in range(target.get_bone_count()):
		if not pairs.has(i): continue
		var j: int = pairs[i]
		var desired: Basis = source.get_bone_global_pose(j).basis.orthonormalized() * pose_corrections[i]
		var parent := target.get_bone_parent(i)
		var parent_basis := Basis.IDENTITY if parent < 0 else target.get_bone_global_pose(parent).basis.orthonormalized()
		var local_pose := parent_basis.inverse() * desired
		target.set_bone_pose_rotation(i, local_pose.orthonormalized().get_rotation_quaternion())
	for finger in grip_pose:
		target.set_bone_pose_rotation(finger, grip_pose[finger])
	# Вертикальный ход таза сохраняется; горизонтальное перемещение выполняет CharacterBody3D.
	if hips_source >= 0 and hips_target >= 0:
		var delta_y := source.get_bone_global_pose(hips_source).origin.y - (source_rest[hips_source] as Transform3D).origin.y
		var target_height := absf((target_rest[hips_target] as Transform3D).origin.y)
		var source_height := maxf(absf((source_rest[hips_source] as Transform3D).origin.y), 0.01)
		target.set_bone_pose_position(hips_target, base_hips_position + Vector3.UP * clampf(delta_y * target_height / source_height, -0.15, 0.15))

func _ready_weapon() -> void:
	var sword := model.find_child("Object_103", true, false) as Node3D
	var hand := _target_bone("hand.r")
	if sword == null or hand < 0: return
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = target.get_bone_name(hand)
	target.add_child(attachment)
	# В исходном ассете меч лежит отдельно перед героем: его мировую позицию не сохраняем.
	# Рукоять имеет центр около Y=-0.15; помещаем эту точку в середину ладони.
	var hand_basis := target.get_bone_global_pose(hand).basis.orthonormalized()
	var middle := _target_bone("middle1.r")
	var palm := Vector3(0, 0.08, 0)
	if middle >= 0:
		palm = (target_rest[hand] as Transform3D).affine_inverse() * (target_rest[middle] as Transform3D).origin * 0.55
	var blade_direction := Vector3(0, -0.65, 1).normalized()
	var sword_basis := hand_basis.inverse() * Basis(Quaternion(Vector3.DOWN, blade_direction))
	sword.reparent(attachment, false)
	sword.transform = Transform3D(sword_basis, palm - sword_basis * Vector3(0, -0.15, 0))

func _resolve_clip(requested: String) -> String:
	if animation_player.has_animation(requested): return requested
	# Godot распознаёт суффикс _Loop и удаляет его при импорте glTF.
	var wanted := requested.to_lower().replace("_loop", "")
	for name_value in animation_player.get_animation_list():
		if name_value.get_file().to_lower().replace("_loop", "") == wanted:
			return name_value
	return ""

func _play(clip: String, blend := 0.15) -> void:
	var resolved := _resolve_clip(clip)
	if not resolved.is_empty() and animation_player.current_animation != resolved:
		animation_player.play(resolved, blend)

func animate_motion(delta: float, speed: float) -> void:
	if not ready_model: return
	strike_remaining = maxf(0, strike_remaining - delta)
	if strike_remaining <= 0:
		_play("Sprint_Loop" if speed > 3.4 else ("Walk_Loop" if speed > 0.15 else "Idle_Loop"))
	animation_player.advance(delta)
	_transfer_pose()

func swing() -> void:
	if not ready_model or strike_remaining > 0: return
	_play("Sword_Attack", 0.08)
	strike_remaining = animation_player.get_animation(_resolve_clip("Sword_Attack")).length

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found: return found
	return null

func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found: return found
	return null

func _hide_meshes(node: Node) -> void:
	if node is MeshInstance3D: node.visible = false
	for child in node.get_children(): _hide_meshes(child)

func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform_value := parent_transform * node.transform
	var box := AABB()
	if node is MeshInstance3D and node.visible: box = transform_value * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_box := _bounds(child, transform_value)
			if child_box.size.length_squared() > 0:
				box = child_box if box.size.length_squared() == 0 else box.merge(child_box)
	return box
