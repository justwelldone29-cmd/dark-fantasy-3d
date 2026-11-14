extends Node3D
## Геометрия создаётся один раз. Деревья/камни объединяются через MultiMesh.
var rng := RandomNumberGenerator.new()
var stone: StandardMaterial3D
var wood: StandardMaterial3D
var leaves: StandardMaterial3D
var ground: StandardMaterial3D
var rock_material: StandardMaterial3D

func mat(color: String) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = 0.95
	return result

func mesh_node(mesh: Mesh, pos: Vector3, material: Material, parent: Node3D = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = pos
	return node

func cone(top: float, bottom: float, height: float, segments := 10) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return mesh

func collider(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)

func batch(mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	var node := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size(): multi.set_instance_transform(i, transforms[i])
	node.multimesh = multi
	if material == leaves:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = material
	add_child(node)

func _ready() -> void:
	rng.seed = 42017
	stone = pbr("castle_wall_varriation_diff_2k.jpg", "castle_wall_varriation_nor_2k.jpg", "castle_wall_varriation_rough_2k.jpg", Color(0.56, 0.57, 0.55), 0.55)
	rock_material = pbr("Rock058_1K-JPG_Color.jpg", "Rock058_1K-JPG_NormalGL.jpg", "Rock058_1K-JPG_Roughness.jpg", Color(0.63, 0.65, 0.63), 0.65)
	wood = pbr("bark_brown_02_diffuse_1k.jpg", "bark_brown_02_nor_gl_1k.jpg", "bark_brown_02_rough_1k.jpg", Color(0.63, 0.61, 0.56), 0.8)
	leaves = mat("9fac89")
	leaves.albedo_texture = load("res://assets/textures/pine_needles.png")
	leaves.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaves.alpha_scissor_threshold = 0.35
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.backlight_enabled = true
	leaves.backlight = Color(0.08, 0.1, 0.04)
	ground = pbr("forrest_ground_01_diffuse_1k.jpg", "forrest_ground_01_nor_gl_1k.jpg", "forrest_ground_01_rough_1k.jpg", Color(0.6, 0.58, 0.50), 0.5)
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	mesh_node(plane, Vector3(0, -0.03, 0), ground)
	# Извилистая тропа: единая полоса с неравномерными краями.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(65):
		var z := 16.0 - i * 0.7
		var center := sin(z * 0.11) * 1.5
		var next_center := sin((z - 0.7) * 0.11) * 1.5
		var width := 1.5 + sin(i * 1.7) * 0.18
		var points := [Vector3(center-width, 0.005, z), Vector3(center+width, 0.005, z),
			Vector3(next_center-width, 0.005, z-0.7), Vector3(next_center+width, 0.005, z-0.7)]
		for index in [0, 1, 2, 1, 3, 2]:
			surface.set_uv(Vector2(points[index].x, points[index].z) * 0.5)
			surface.add_vertex(points[index])
	surface.generate_normals()
	var path_mat := ground.duplicate() as StandardMaterial3D
	path_mat.albedo_color = Color(0.47, 0.43, 0.35)
	mesh_node(surface.commit(), Vector3.ZERO, path_mat)
	var trunks: Array[Transform3D] = []
	var crowns: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	var grass: Array[Transform3D] = []
	for i in range(125):
		var pos := Vector3(rng.randf_range(-65, 65), 0, rng.randf_range(-65, 45))
		if absf(pos.x) < 5.0 or pos.distance_to(Vector3(0, 0, -20)) < 12: continue
		var height := rng.randf_range(4.5, 10.0)
		trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.36, height, 0.36)), pos + Vector3.UP * height * 0.5))
		for level in range(9):
			var t := float(level) / 9.0
			var branch_length := height * (0.28 * (1.0 - t) + 0.045)
			for branch in range(5):
				var angle := branch * TAU / 5.0 + level * 0.76 + rng.randf_range(-0.2, 0.2)
				var scale_value := Vector3(branch_length * 1.05, 1, branch_length)
				var basis_value := Basis(Vector3.UP, angle).rotated(Vector3.RIGHT, rng.randf_range(-0.4, 0.1)).scaled(scale_value)
				crowns.append(Transform3D(basis_value, pos + Vector3.UP * height * (0.32 + t * 0.63)))
		
	
	
	var rock_mesh := SphereMesh.new()
	rock_mesh.radial_segments = 7
	rock_mesh.rings = 3
	rock_mesh.radius = 1
	rock_mesh.height = 2
	for i in range(150):
		var pos := Vector3(rng.randf_range(-38, 38), 0, rng.randf_range(-40, 25))
		if absf(pos.x) < 2.3: continue
		var size_value := rng.randf_range(0.2, 1.0)
		rocks.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size_value, size_value * 0.65, size_value)), pos))
	batch(rock_mesh, rock_material, rocks)
	# Травяные пучки с общей геометрией, без обработки на каждом кадре.
	for i in range(1100):
		var pos := Vector3(rng.randf_range(-35, 35), 0.14, rng.randf_range(-38, 20))
		if absf(pos.x - sin(pos.z * 0.11) * 1.5) < 1.8: continue
		grass.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(0.16, rng.randf_range(0.2, 0.6), 0.16)), pos))
	# Трава состоит из узких перекрещенных лезвий, без пирамид.
	batch(_grass_blades(), mat("626b47"), grass)
	# Силуэты гор на горизонте.
	for i in range(15):
		var pos := Vector3(-90 + i * 13, 5, -80 - rng.randf_range(0, 20))
		var mountain := mesh_node(_mountain_mesh(), pos, rock_material)
		mountain.rotation.y = rng.randf() * TAU
	_imported_props()
	_fortress()
	for pos in [Vector3(-2.6, 0, -12), Vector3(2.6, 0, -12)]: _torch(pos)

func _fortress() -> void:
	for x in [-7.0, 7.0]:
		var pos := Vector3(x, 0, -21)
		mesh_node(cone(2.35, 2.7, 7, 16), pos + Vector3.UP * 3.5, stone)
		collider(pos + Vector3.UP * 3.5, 2.7, 7)
		mesh_node(cone(2.65, 2.65, 0.35, 16), pos + Vector3.UP * 6.5, stone)
		for i in range(10):
			var angle := i * TAU / 10
			var battlement := mesh_node(cone(0.4, 0.43, 1.1, 5), pos + Vector3(sin(angle) * 2.2, 7.2, cos(angle) * 2.2), stone)
			battlement.rotation.y = angle
		# Тёмные узкие оконные ниши.
		for y in [2.8, 5.0]:
			var window := mesh_node(cone(0.11, 0.11, 0.9, 6), pos + Vector3(0, y, 2.36), mat("1e3030"))
			window.scale.z = 0.3
	# Входная арка собрана из клиновидных камней, проход свободен.
	for side in [-1, 1]:
		for level in range(4):
			mesh_node(cone(0.65, 0.7, 0.72, 6), Vector3(side * 2.7, 0.36 + level * 0.72, -19), stone)
		collider(Vector3(side * 2.7, 1.4, -19), 0.65, 2.8)
	for i in range(13):
		var angle := i * PI / 12
		var brick := mesh_node(cone(0.38, 0.4, 0.95, 5), Vector3(cos(angle) * 2.7, 2.8 + sin(angle) * 2.7, -19), stone)
		brick.rotation.z = angle
	# Камни двора и центральный алтарь.
	for i in range(18):
		var angle := i * TAU / 18
		mesh_node(cone(0.7, 0.8, 0.16, 6), Vector3(sin(angle) * 4, 0.08, -25 + cos(angle) * 4), stone)
	mesh_node(cone(0.85, 1.1, 0.5, 8), Vector3(0, 0.25, -25), stone)
	var crystal_mat := mat("84dccc")
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color("4b998f")
	mesh_node(cone(0, 0.32, 1.4, 5), Vector3(0, 1.4, -25), crystal_mat)
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(0, 2, -25)
	beacon.light_color = Color("77d8be")
	beacon.omni_range = 6
	add_child(beacon)

func _torch(pos: Vector3) -> void:
	mesh_node(cone(0.08, 0.12, 1.6, 6), pos + Vector3.UP * 0.8, wood)
	var flame := mat("ffc176")
	flame.emission_enabled = true
	flame.emission = Color("ffa043")
	mesh_node(cone(0, 0.16, 0.6, 6), pos + Vector3.UP * 1.85, flame)
	var light := OmniLight3D.new()
	light.position = pos + Vector3.UP * 2
	light.light_color = Color("ffc18c")
	light.light_energy = 1.7
	light.omni_range = 6
	add_child(light)

func _imported_props() -> void:
	# GLB инстанцируется как PackedScene: сетки и материалы сохраняются при импорте.
	for x in [-3.7, 3.7]:
		for z in [-3.0, -8.0, -13.0, -24.0]:
			_prop("gravestone-cross-large", Vector3(x + rng.randf_range(-0.3, 0.3), 0, z), 1.5, rng.randf_range(-0.25, 0.25))
	for pos in [Vector3(-4.7, 0, 2), Vector3(5.3, 0, -5), Vector3(-5.5, 0, -10), Vector3(6, 0, -16)]:
		_prop("rocks", pos, 1.6, rng.randf() * TAU)
	for x in [-3.0, 3.0]:
		_prop("column-large", Vector3(x, 0, -17), 3.8, 0)

func _prop(file_name: String, pos: Vector3, target_height: float, angle: float) -> void:
	var scene := load("res://assets/models/kenney/" + file_name + ".glb") as PackedScene
	var model := scene.instantiate() as Node3D
	add_child(model)
	var bounds := _model_bounds(model, Transform3D.IDENTITY)
	var factor := target_height / maxf(bounds.size.y, 0.01)
	model.scale = Vector3.ONE * factor
	model.rotation.y = angle
	model.position = pos - Vector3.UP * bounds.position.y * factor
	_material_override(model, rock_material if file_name == "rocks" else stone)
	_static_collision(model)

func _model_bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform_value := parent_transform * node.transform
	var box := AABB()
	if node is MeshInstance3D: box = transform_value * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_box := _model_bounds(child, transform_value)
			if child_box.size.length_squared() > 0:
				box = child_box if box.size.length_squared() == 0 else box.merge(child_box)
	return box

func _static_collision(node: Node) -> void:
	if node is MeshInstance3D:
		# Только неподвижное окружение использует точную треугольную коллизию.
		node.create_trimesh_collision()
	for child in node.get_children():
		if not child is StaticBody3D: _static_collision(child)

func pbr(color_file: String, normal_file: String, rough_file: String, tint: Color, density: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load("res://assets/textures/pbr/" + color_file)
	material.normal_enabled = true
	material.normal_texture = load("res://assets/textures/pbr/" + normal_file)
	material.normal_scale = 0.7
	material.roughness_texture = load("res://assets/textures/pbr/" + rough_file)
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness = 0.95
	# Мировая трипланарная проекция даёт правильный масштаб даже импортированным сеткам без UV.
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * density
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material

func _material_override(node: Node, material: Material) -> void:
	if node is MeshInstance3D: node.material_override = material
	for child in node.get_children(): _material_override(child, material)

func _pine_frond() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.5, 0.1, -1), Vector3(0.5, 0.1, -1)]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(0, 0), Vector2(1, 0)]
	# Три пересекающиеся плоскости сохраняют объём кроны при обзоре сбоку.
	for angle in [0.0, 0.9, -0.9]:
		var rotation_value := Basis(Vector3.FORWARD, angle)
		for index in [0, 1, 2, 1, 3, 2]:
			surface.set_uv(uvs[index])
			surface.add_vertex(rotation_value * points[index])
	surface.generate_normals()
	return surface.commit()

func _grass_blades() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0, 1.0, 2.0]:
		var basis_value := Basis(Vector3.UP, angle)
		for vertex in [Vector3(-0.12, -0.2, 0), Vector3(0.12, -0.2, 0), Vector3(0.15, 1, 0), Vector3(0.12, -0.2, 0), Vector3(-0.12, -0.2, 0), Vector3(0.15, 1, 0)]:
			surface.add_vertex(basis_value * vertex)
	surface.generate_normals()
	return surface.commit()

func _mountain_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seed_value := rng.randf() * 10
	for z in range(10):
		for x in range(10):
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var vx: float = (x + corner.x - 5) * 5.0
				var vz: float = (z + corner.y - 5) * 5.0
				var h := maxf(0, 1.0 - Vector2(vx, vz).length() / 32)
				var height_value := pow(h, 0.7) * (22 + sin(vx * 0.15 + seed_value) * 5 + cos(vz * 0.2) * 4) - 7
				surface.add_vertex(Vector3(vx, height_value, vz))
	surface.generate_normals()
	return surface.commit()
