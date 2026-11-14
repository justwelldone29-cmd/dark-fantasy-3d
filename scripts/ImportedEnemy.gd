extends Node3D
## Импортированная сцена GLB содержит MeshInstance3D и AnimationPlayer.
var model: Node3D
var animator: AnimationPlayer
var attack_until := 0

func build(_enemy := true) -> void:
	model = preload("res://assets/models/undead/skeleton.glb").instantiate()
	add_child(model)
	animator = _find_animation(model)
	if animator:
		for name_value in animator.get_animation_list():
			if name_value in ["idle", "idle2", "walk", "run"]:
				animator.get_animation(name_value).loop_mode = Animation.LOOP_LINEAR
		_play("idle")
		animator.advance(0.0)
	var bounds := _posed_bounds(model)
	var factor := 1.8 / maxf(bounds.size.y, 0.01)
	model.scale *= factor
	model.rotation.y += PI
	model.position += Vector3(bounds.get_center().x * factor, -0.9 - bounds.position.y * factor, bounds.get_center().z * factor)


func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform_value := parent_transform * node.transform
	var box := AABB()
	if node is MeshInstance3D:
		box = transform_value * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_box := _bounds(child, transform_value)
			if child_box.size.length_squared() > 0:
				box = child_box if box.size.length_squared() == 0 else box.merge(child_box)
	return box

func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found: return found
	return null

func _play(name_value: String) -> void:
	if animator and animator.has_animation(name_value) and animator.current_animation != name_value:
		animator.play(name_value, 0.15)

func animate_motion(_delta: float, speed: float) -> void:
	if Time.get_ticks_msec() >= attack_until:
		_play("walk" if speed > 0.2 else "idle")

func swing() -> void:
	attack_until = Time.get_ticks_msec() + 650
	_play("attack1")

func die() -> float:
	# Смерть проигрывает исходный риг, без искусственного поворота всей модели.
	attack_until = 2147483647
	_play("death")
	return animator.get_animation("death").length if animator and animator.has_animation("death") else 1.0

func _posed_bounds(node: Node3D) -> AABB:
	# У skinned-меша get_aabb() не учитывает inverse-bind и масштаб импортированного рига.
	# Один раз при создании вычисляем границы реальных вершин текущей позы.
	var box := AABB()
	var initialized := false
	if node is MeshInstance3D and node.skin != null:
		var skeleton := node.get_node(node.skeleton) as Skeleton3D
		var to_model := model.global_transform.affine_inverse() * skeleton.global_transform
		var transforms: Array[Transform3D] = []
		for bind in range(node.skin.get_bind_count()):
			var bone := skeleton.find_bone(node.skin.get_bind_name(bind))
			if bone < 0: bone = node.skin.get_bind_bone(bind)
			transforms.append(to_model * skeleton.get_bone_global_pose(bone) * node.skin.get_bind_pose(bind))
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = bones.size() / vertices.size()
			for vertex in range(vertices.size()):
				var point := Vector3.ZERO
				for influence in range(influences):
					var index := vertex * influences + influence
					point += (transforms[bones[index]] * vertices[vertex]) * weights[index]
				if not initialized:
					box = AABB(point, Vector3.ZERO)
					initialized = true
				else: box = box.expand(point)
	for child in node.get_children():
		if child is Node3D:
			var child_box := _posed_bounds(child)
			if child_box.size.length_squared() > 0:
				box = child_box if not initialized else box.merge(child_box)
				initialized = true
	return box
