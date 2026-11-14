extends StaticBody3D
## Сундук с настоящим шарниром крышки и постоянным содержимым.
signal requested(chest: Node)
var chest_id := ""
var chest_title := "Сундук"
var initial_items: Dictionary = {}
var hinge: Node3D
var is_open := false

func _ready() -> void:
	add_to_group("LootChest")
	add_to_group("Interactable")
	collision_layer = 1
	collision_mask = 0
	var state := get_node("/root/GameState")
	state.ensure_chest(chest_id, initial_items)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("493322")
	wood.albedo_texture = load("res://assets/textures/pbr/bark_brown_02_diffuse_1k.jpg")
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3(2, .5, 2)
	wood.roughness = .88
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("464b50")
	metal.metallic = .85
	metal.roughness = .38
	var inside := StandardMaterial3D.new()
	inside.albedo_color = Color("18120d")
	_box(Vector3(1.4, .12, .94), Vector3(0, .06, 0), wood, self)
	_box(Vector3(1.22, .03, .75), Vector3(0, .14, 0), inside, self)
	for x in [-.65, .65]: _box(Vector3(.10, .6, .94), Vector3(x, .36, 0), wood, self)
	for z in [-.43, .43]:
		for plank in range(4): _box(Vector3(1.3, .13, .09), Vector3(0, .19 + plank * .14, z), wood, self)
	for x in [-.48, .48]:
		for z in [-.49, .49]: _box(Vector3(.09, .64, .035), Vector3(x, .34, z), metal, self)
	_box(Vector3(.18, .19, .05), Vector3(0, .53, .50), metal, self)
	hinge = Node3D.new()
	hinge.position = Vector3(0, .65, -.44)
	add_child(hinge)
	# Поперечные доски образуют выпуклую крышку, металлические полосы повторяют её изгиб.
	for part in range(10):
		var a := float(part) / 10 * PI
		var b := float(part + 1) / 10 * PI
		var middle := (a + b) * .5
		var point := Vector3(0, sin(middle) * .25, .44 - cos(middle) * .44)
		var plank := _box(Vector3(1.4, .055, .16), point, wood, hinge)
		plank.rotation.x = -atan2(cos(middle) * .25, sin(middle) * .44)
		for x in [-.48, .48]:
			var band := _box(Vector3(.095, .065, .17), point + Vector3(x, .012, 0), metal, hinge)
			band.rotation.x = plank.rotation.x
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, .95, .98)
	collision.shape = shape
	collision.position.y = .45
	add_child(collision)
	is_open = bool(state.opened_chests.get(chest_id, false))
	if is_open: hinge.rotation.x = deg_to_rad(-105)

func interact(_player: Node = null) -> void:
	if not is_open:
		is_open = true
		get_node("/root/GameState").open_chest(chest_id)
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(hinge, "rotation:x", deg_to_rad(-105), .35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	requested.emit(self)

func _box(size_value: Vector3, position_value: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.material_override = material
	node.position = position_value
	parent.add_child(node)
	return node
