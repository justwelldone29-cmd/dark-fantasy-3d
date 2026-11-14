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
	hips_target = _target_bone("root.x")
	hips_source = source.find_bone("DEF-hips")
	base_hips_position = target.get_bone_pose_position(hips_target)
	for name_value in animation_player.get_animation_list():
		if name_value.ends_with("Loop") or name_value in ["Sword_Idle", "Idle_Loop"]:
			animation_player.get_animation(name_value).loop_mode = Animation.LOOP_LINEAR
	_ready_weapon()
	_play("Idle_Loop", 0.0)
	animation_player.advance(0.0)
	_transfer_pose()
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

func _transfer_pose() -> void:
	var target_basis := target.global_basis.orthonormalized()
	var source_basis := source.global_basis.orthonormalized()
	# Порядок Skeleton3D — родитель перед потомком; немаппированные twist-кости наследуют позу.
	for i in range(target.get_bone_count()):
		if not pairs.has(i): continue
		var j: int = pairs[i]
		var source_pose := source_basis * source.get_bone_global_pose(j).basis.orthonormalized()
		var original_source := source_basis * (source_rest[j] as Transform3D).basis.orthonormalized()
		var original_target := target_basis * (target_rest[i] as Transform3D).basis.orthonormalized()
		var world_pose := source_pose * original_source.inverse() * original_target
		var skeleton_pose := target_basis.inverse() * world_pose
		var parent := target.get_bone_parent(i)
		var parent_basis := Basis.IDENTITY if parent < 0 else target.get_bone_global_pose(parent).basis.orthonormalized()
		var local_pose := parent_basis.inverse() * skeleton_pose
		var rotation_value := local_pose
		target.set_bone_pose_rotation(i, rotation_value.orthonormalized().get_rotation_quaternion())
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
	# Сохраняем исходный хват модели: при смене поз меч следует кисти.
	attachment.transform = target.get_bone_global_pose(hand)
	sword.reparent(attachment, true)

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
	if node is MeshInstance3D: box = transform_value * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_box := _bounds(child, transform_value)
			if child_box.size.length_squared() > 0:
				box = child_box if box.size.length_squared() == 0 else box.merge(child_box)
	return box
