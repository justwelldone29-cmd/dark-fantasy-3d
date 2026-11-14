extends SubViewportContainer
## Предпросмотр отрисовывается только при выборе предмета или повороте пальцем.
const DB = preload("res://scripts/ItemDB.gd")
const HERO = preload("res://assets/models/forgotten_knight/knight.glb")
var viewport_3d: SubViewport
var pivot: Node3D
var object: Node3D

func _ready() -> void:
	stretch = true
	custom_minimum_size = Vector2(300, 160)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(400, 300)
	viewport_3d.own_world_3d = true
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport_3d)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(.75, .82, .95)
	environment.ambient_light_energy = .8
	world.environment = environment
	viewport_3d.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -35, 0)
	light.light_energy = 1.6
	viewport_3d.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(1.8, .6, 3.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.6
	viewport_3d.add_child(camera)
	camera.look_at(Vector3.ZERO)
	pivot = Node3D.new()
	viewport_3d.add_child(pivot)

func show_item(id: String) -> void:
	if object:
		pivot.remove_child(object)
		object.queue_free()
	object = Node3D.new()
	pivot.add_child(object)
	pivot.rotation.y = -.3
	var view: String = DB.item(id).get("view", "coin")
	if view in ["sword", "dagger", "armor", "helmet"]:
		var template := HERO.instantiate()
		var parts := ["Object_103"] if view in ["sword", "dagger"] else (["Object_27", "Object_18", "Object_20"] if view == "armor" else ["Object_29", "Object_16"])
		for part in parts:
			var original := template.find_child(part, true, false) as MeshInstance3D
			if original:
				var mesh := _helmet(original.mesh) if view == "helmet" and part == "Object_29" else original.mesh
				_piece(mesh, Vector3.ZERO, null)
		template.free()
	else:
		var silver := _material(Color("9ca9b3"), .85)
		var gold := _material(Color("c49b42"), .8)
		match view:
			"ring":
				var ring := TorusMesh.new()
				ring.inner_radius = .28
				ring.outer_radius = .40
				_piece(ring, Vector3.ZERO, silver).rotation_degrees.x = 70
			"potion":
				var glass := _material(Color(.22, .04, .06, .8), .1)
				glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				var ball := SphereMesh.new()
				ball.radius = .3
				ball.height = .7
				_piece(ball, Vector3.ZERO, glass)
				_cylinder(.12, .3, Vector3(0, .42, 0), silver)
				_cylinder(.1, .12, Vector3(0, .60, 0), _material(Color("694932"), 0))
			"flower":
				_cylinder(.035, .8, Vector3(0, -.2, 0), _material(Color("435c39"), 0))
				var petal := SphereMesh.new()
				petal.radius = .16
				petal.height = .15
				for i in range(6):
					var a := i * TAU / 6
					_piece(petal, Vector3(cos(a) * .18, .25, sin(a) * .18), _material(Color("aec9e0"), 0))
			"ingot":
				var ingot := BoxMesh.new()
				ingot.size = Vector3(1, .3, .55)
				_piece(ingot, Vector3.ZERO, silver)
			_:
				for i in range(5): _cylinder(.32, .045, Vector3(.06 * sin(i), i * .05, .04 * cos(i)), gold)
	var box := AABB()
	for child in object.get_children():
		if child is MeshInstance3D:
			var bounds: AABB = child.transform * child.get_aabb()
			box = bounds if box.size.is_zero_approx() else box.merge(bounds)
	var factor := 1.9 / maxf(box.size.y, maxf(box.size.x, .1))
	object.scale = Vector3.ONE * factor
	object.position = -box.get_center() * factor
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _gui_input(event: InputEvent) -> void:
	var distance := 0.0
	if event is InputEventScreenDrag: distance = event.relative.x
	elif event is InputEventMouseMotion and event.device >= 0 and event.button_mask & MOUSE_BUTTON_MASK_LEFT: distance = event.relative.x
	if distance != 0:
		pivot.rotation.y += distance * .012
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
		accept_event()

func _piece(mesh: Mesh, position_value: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position_value
	if material: node.material_override = material
	object.add_child(node)
	return node

func _material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = .38
	return material

func _cylinder(radius: float, height_value: float, position_value: Vector3, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_value
	mesh.radial_segments = 24
	_piece(mesh, position_value, material)

func _helmet(mesh: Mesh) -> ArrayMesh:
	# Выделяем шлем из исходной общей сетки для предпросмотра; игровая модель не меняется.
	var output := ArrayMesh.new()
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var points := PackedVector3Array()
		var directions := PackedVector3Array()
		var coordinates := PackedVector2Array()
		for i in range(0, indices.size(), 3):
			if vertices[indices[i]].y < 2.26 or vertices[indices[i+1]].y < 2.26 or vertices[indices[i+2]].y < 2.26: continue
			for k in range(3):
				points.append(vertices[indices[i+k]])
				directions.append(normals[indices[i+k]])
				coordinates.append(uvs[indices[i+k]])
		if points.is_empty(): continue
		var result := []
		result.resize(Mesh.ARRAY_MAX)
		result[Mesh.ARRAY_VERTEX] = points
		result[Mesh.ARRAY_NORMAL] = directions
		result[Mesh.ARRAY_TEX_UV] = coordinates
		output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, result)
		output.surface_set_material(output.get_surface_count()-1, mesh.surface_get_material(surface))
	return output
