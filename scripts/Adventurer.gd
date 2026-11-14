extends Node3D
## Низкополигональный человек: отдельные суставы, броня, плащ и оружие.
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var cloak: MeshInstance3D
var phase := 0.0
var striking := false
var metal: StandardMaterial3D
var cloth: StandardMaterial3D
var leather: StandardMaterial3D

func material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = 0.75
	return result

func part(parent: Node3D, mesh: Mesh, position_value: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = position_value
	parent.add_child(node)
	return node

func capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 2
	return mesh

func cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	return mesh

func joint(pos: Vector3) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	return node

func build(enemy := false) -> void:
	metal = material(Color("727e86"), 0.65)
	cloth = material(Color("752f32") if enemy else Color("234c47"))
	leather = material(Color("362c27"))
	var skin := material(Color("ae8968"))
	# Торс с наплечниками, пояс и сегментированный шлем.
	part(self, cylinder(0.24, 0.19, 0.54), Vector3(0, 0.25, 0), metal)
	part(self, cylinder(0.205, 0.21, 0.09), Vector3(0, -0.02, 0), leather)
	part(self, capsule(0.14, 0.34), Vector3(0, 0.69, 0), skin)
	part(self, capsule(0.163, 0.28), Vector3(0, 0.77, 0.025), metal)
	var visor := part(self, cylinder(0.13, 0.14, 0.08), Vector3(0, 0.72, -0.045), leather)
	visor.scale.z = 0.9
	for side in [-1, 1]:
		part(self, capsule(0.17, 0.22), Vector3(side * 0.29, 0.47, 0), metal)
	left_leg = joint(Vector3(-0.13, -0.08, 0))
	right_leg = joint(Vector3(0.13, -0.08, 0))
	for leg in [left_leg, right_leg]:
		part(leg, capsule(0.105, 0.62), Vector3(0, -0.28, 0), leather)
		part(leg, capsule(0.11, 0.29), Vector3(0, -0.53, -0.03), metal)
		var boot := part(leg, capsule(0.105, 0.28), Vector3(0, -0.68, -0.06), leather)
		boot.rotation.x = PI / 2
	left_arm = joint(Vector3(-0.29, 0.44, 0))
	right_arm = joint(Vector3(0.29, 0.44, 0))
	for arm in [left_arm, right_arm]:
		part(arm, capsule(0.09, 0.43), Vector3(0, -0.2, 0), cloth)
		part(arm, capsule(0.095, 0.22), Vector3(0, -0.39, -0.02), metal)
		part(arm, capsule(0.075, 0.16), Vector3(0, -0.48, -0.03), leather)
	# Плоский ромбовидный стальной клинок вместо прямоугольника.
	var sword := Node3D.new()
	right_arm.add_child(sword)
	sword.position = Vector3(0, -0.48, -0.06)
	sword.rotation.x = -1.05
	part(sword, cylinder(0.025, 0.025, 0.18), Vector3(0, 0.04, 0), leather)
	var guard := part(sword, capsule(0.025, 0.3), Vector3(0, 0.15, 0), metal)
	guard.rotation.z = PI / 2
	var blade := part(sword, cylinder(0, 0.055, 0.82), Vector3(0, 0.58, 0), metal)
	blade.scale.z = 0.24
	# Щит на левой руке.
	var shield := part(left_arm, cylinder(0.29, 0.29, 0.065), Vector3(-0.08, -0.3, -0.07), metal)
	shield.rotation.z = PI / 2
	part(left_arm, capsule(0.085, 0.14), Vector3(-0.13, -0.3, -0.07), cloth)
	# Плащ расширяется к подолу и находится сзади тела (+Z).
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := [Vector3(-0.25, 0.5, 0.16), Vector3(0.25, 0.5, 0.16),
		Vector3(-0.34, -0.55, 0.30), Vector3(0.34, -0.55, 0.30)]
	for index in [0, 2, 1, 1, 2, 3]:
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var cape_material := material(cloth.albedo_color.darkened(0.15))
	cape_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloak = part(self, surface.commit(), Vector3.ZERO, cape_material)

func animate_motion(delta: float, speed: float) -> void:
	phase += delta * (9.0 if speed > 3 else 6.0)
	var stride := minf(speed / 4, 1.0) * 0.65
	left_leg.rotation.x = sin(phase) * stride
	right_leg.rotation.x = -sin(phase) * stride
	left_arm.rotation.x = -sin(phase) * stride * 0.5
	if not striking:
		right_arm.rotation.x = sin(phase) * stride * 0.5
	cloak.rotation.x = sin(phase * 0.5) * stride * 0.08

func swing() -> void:
	if striking:
		return
	striking = true
	var tween := create_tween()
	tween.tween_property(right_arm, "rotation:x", -2.0, 0.11)
	tween.tween_property(right_arm, "rotation:x", 0.65, 0.16)
	tween.tween_property(right_arm, "rotation:x", 0.0, 0.17)
	tween.tween_callback(func(): striking = false)
