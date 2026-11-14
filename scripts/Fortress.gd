extends Node3D
## Оригинальные модули Modular Fort 01 (Rico Cilliers / Poly Haven, CC0).
func _ready() -> void:
	var template := preload("res://assets/models/fort/modular_fort_01.gltf").instantiate()
	for x in [-12.0, 12.0]:
		for z in [-23.0, -41.0]: _part(template, "tower_round", Vector3(x, 0, z), 0, .56)
		_part(template, "wall_thin_straight_01", Vector3(x, 0, -32), 0, 1.02)
	_part(template, "wall_thin_gate_01", Vector3(0, 0, -23), PI / 2, .95)
	for x in [-7.0, 7.0]: _part(template, "wall_thin_straight_03", Vector3(x, 0, -23), PI / 2, .95)
	for x in [-5.0, 5.0]: _part(template, "wall_thin_straight_01", Vector3(x, 0, -41), PI / 2, .95)
	_part(template, "wall_stairs_straight_01", Vector3(-8, 0, -31), 0, .8)
	template.free()

func _part(template: Node, part_name: String, position_value: Vector3, angle: float, factor: float) -> void:
	var original := template.find_child("modular_fort_01_" + part_name, true, false) as MeshInstance3D
	assert(original != null, "Отсутствует модуль крепости " + part_name)
	var node := original.duplicate() as MeshInstance3D
	var box := node.get_aabb()
	var basis_value := Basis(Vector3.UP, angle).scaled(Vector3.ONE * factor)
	node.transform = Transform3D(basis_value, position_value - basis_value * Vector3(box.get_center().x, box.position.y, box.get_center().z))
	for surface in range(node.mesh.get_surface_count()):
		var material := node.mesh.surface_get_material(surface).duplicate() as StandardMaterial3D
		if material:
			material.albedo_color *= Color(.65, .68, .71)
			node.set_surface_override_material(surface, material)
	add_child(node)
	# Точная статичная коллизия сохраняет проходы арки и ступени; расчёта на кадре нет.
	node.create_trimesh_collision()
