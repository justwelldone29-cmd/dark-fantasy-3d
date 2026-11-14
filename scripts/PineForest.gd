extends Node3D
## Только одобренные большие и средние сосны LOLIPOP. Каждая сетка инстансируется пачкой.
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 70423
	var variants := ["big_1", "big_2", "big_3", "large_1", "large_2", "large_3", "medium_1", "medium_2", "medium_3"]
	var positions: Array[Array] = []
	for v in variants: positions.append([])
	for i in range(100):
		var position_value := Vector3(random.randf_range(-52, 52), 0, random.randf_range(-52, 30))
		if absf(position_value.x) < 5.5 or position_value.distance_to(Vector3(0, 0, -21)) < 12: continue
		positions[i % variants.size()].append(position_value)
	for i in range(variants.size()):
		_build_variant(variants[i], positions[i])

func _build_variant(variant: String, positions: Array) -> void:
	var scene := load("res://assets/models/pines/trees/Pine_" + variant + ".glb") as PackedScene
	var template := scene.instantiate() as Node3D
	var meshes: Array[Dictionary] = []
	_collect(template, Transform3D.IDENTITY, meshes)
	var bounds := AABB()
	for item in meshes:
		var mesh: Mesh = item.mesh
		var box: AABB = (item.transform as Transform3D) * mesh.get_aabb()
		bounds = box if bounds.size.length_squared() == 0 else bounds.merge(box)
	var height_value := 10.0 if variant.begins_with("medium") else (15.0 if variant.begins_with("big") else 19.0)
	var base_scale := height_value / maxf(bounds.size.y, 0.1)
	var instances: Array[Transform3D] = []
	for pos in positions:
		var factor := base_scale * random.randf_range(0.9, 1.1)
		var basis_value := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3.ONE * factor)
		var offset := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
		instances.append(Transform3D(basis_value, pos - basis_value * offset))
		if pos.length() < 35:
			var body := StaticBody3D.new()
			body.position = pos + Vector3.UP * 2
			var collision := CollisionShape3D.new()
			var shape := CylinderShape3D.new()
			shape.radius = height_value * 0.022
			shape.height = 4.0
			collision.shape = shape
			body.add_child(collision)
			add_child(body)
	for item in meshes:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = item.mesh
		multimesh.instance_count = instances.size()
		for i in range(instances.size()): multimesh.set_instance_transform(i, instances[i] * (item.transform as Transform3D))
		var node := MultiMeshInstance3D.new()
		node.multimesh = multimesh
		node.visibility_range_end = 90
		add_child(node)
	template.free()

func _collect(node: Node3D, parent_transform: Transform3D, meshes: Array[Dictionary]) -> void:
	var transform_value := parent_transform * node.transform
	if node is MeshInstance3D: meshes.append({"mesh":node.mesh,"transform":transform_value})
	for child in node.get_children():
		if child is Node3D: _collect(child, transform_value, meshes)
