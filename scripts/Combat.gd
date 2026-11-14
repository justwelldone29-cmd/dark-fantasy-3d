extends Node3D
## Форма следует лезвию. Проверки работают только во время замаха.
signal struck
signal hit_confirmed(target: Node, point: Vector3)
@export var damage := 34
@export var cooldown := 0.55
@export_range(0.0, 1.0) var contact_start := 0.22
@export_range(0.0, 1.0) var contact_end := 0.56
@export var blade_radius := 0.065
@export var shake_strength := 0.035
@export var shake_duration := 0.12
@export var impact_color := Color("efb66b")
@export var impact_stream: AudioStream = preload("res://assets/audio/sword_impact.wav")
var next_attack := 0
var hit_cast: ShapeCast3D
var hit_sound: AudioStreamPlayer3D
var _shape := CapsuleShape3D.new()
var _particle_mesh: SphereMesh
var _damaged: Dictionary = {}
var _previous_blade := PackedVector3Array()
var _previous_elapsed := 0.0
var _weapon := ""
@onready var player := get_parent() as CharacterBody3D
@onready var visual := get_parent().get_node("Visual")

func _ready() -> void:
	# Игрок сначала переносит позу AnimationPlayer, затем читаем кости меча.
	process_physics_priority = 10
	hit_cast = ShapeCast3D.new()
	hit_cast.name = "SwordShapeCast"
	hit_cast.enabled = false
	hit_cast.shape = _shape
	hit_cast.collision_mask = 4
	hit_cast.collide_with_areas = false
	hit_cast.max_results = 16
	hit_cast.add_exception(player)
	add_child(hit_cast)
	hit_sound = AudioStreamPlayer3D.new()
	hit_sound.name = "HitSound"
	hit_sound.stream = impact_stream
	hit_sound.max_distance = 22.0
	hit_sound.volume_db = -5.0
	add_child(hit_sound)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	_particle_mesh = SphereMesh.new()
	_particle_mesh.radius = .018
	_particle_mesh.height = .036
	_particle_mesh.radial_segments = 6
	_particle_mesh.rings = 3
	_particle_mesh.material = material
	set_physics_process(false)

func attack() -> bool:
	var now := Time.get_ticks_msec()
	if now < next_attack or not visual.swing(): return false
	next_attack = now + int(maxf(cooldown, visual.strike_remaining) * 1000)
	_damaged.clear()
	_weapon = visual.equipped_weapon_id
	_previous_blade = visual.get_blade_segment()
	_previous_elapsed = 0.0
	set_physics_process(true)
	struck.emit()
	return true

func _physics_process(_delta: float) -> void:
	if visual.equipped_weapon_id != _weapon:
		_stop_cast()
		return
	var elapsed: float = visual.strike_length - visual.strike_remaining
	var blade: PackedVector3Array = visual.get_blade_segment()
	var start: float = visual.strike_length * contact_start
	var end: float = visual.strike_length * maxf(contact_start, contact_end)
	if elapsed >= start and _previous_elapsed < end and blade.size() == 2 and _previous_blade.size() == 2:
		# Обрезаем путь по активной фазе, в том числе при низком FPS.
		var span := maxf(elapsed - _previous_elapsed, .000001)
		var a := clampf((start - _previous_elapsed) / span, 0, 1)
		var b := clampf((end - _previous_elapsed) / span, 0, 1)
		var first := PackedVector3Array([_previous_blade[0].lerp(blade[0], a), _previous_blade[1].lerp(blade[1], a)])
		var last := PackedVector3Array([_previous_blade[0].lerp(blade[0], b), _previous_blade[1].lerp(blade[1], b)])
		_sweep_blade(first, last)
	else:
		hit_cast.enabled = false
	_previous_blade = blade
	_previous_elapsed = elapsed
	if elapsed >= end: hit_cast.enabled = false
	if visual.strike_remaining <= 0.0: _stop_cast()

func _sweep_blade(first: PackedVector3Array, last: PackedVector3Array) -> void:
	hit_cast.enabled = true
	# Несколько ориентаций капсулы учитывают вращение между кадрами.
	var travel := maxf(first[0].distance_to(last[0]), first[1].distance_to(last[1]))
	var steps := clampi(int(ceil(travel / .10)), 1, 12)
	var previous_center := (first[0] + first[1]) * .5
	for step in range(steps + 1):
		var t := float(step) / steps
		var base := first[0].lerp(last[0], t)
		var tip := first[1].lerp(last[1], t)
		var axis := (tip - base).normalized()
		if axis.is_zero_approx(): axis = Vector3.UP
		_shape.radius = blade_radius if not _weapon.is_empty() else .14
		_shape.height = maxf(base.distance_to(tip) + _shape.radius * 2, _shape.radius * 2)
		var center := (base + tip) * .5
		hit_cast.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, axis)), center)
		hit_cast.target_position = hit_cast.to_local(previous_center)
		hit_cast.force_shapecast_update()
		deal_damage()
		previous_center = center

func deal_damage() -> void:
	for index in range(hit_cast.get_collision_count()):
		var target := hit_cast.get_collider(index) as Node
		if not is_instance_valid(target) or target == player or not target.has_method("take_damage"): continue
		if _damaged.has(target.get_instance_id()) or target.get("dead") == true: continue
		var point := hit_cast.get_collision_point(index)
		# Не наносим урон сквозь стены, даже если меч оказался за препятствием.
		var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * .3, point, 1)
		query.exclude = [player.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		_damaged[target.get_instance_id()] = true
		_spawn_impact(point, hit_cast.get_collision_normal(index))
		_play_hit(point)
		player.camera.shake(shake_strength, shake_duration)
		hit_confirmed.emit(target, point)
		if is_instance_valid(target): target.take_damage(damage)

func _spawn_impact(point: Vector3, normal: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 14
	particles.lifetime = .28
	particles.preprocess = .04
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.spread = 65
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.8
	particles.gravity = Vector3(0, -5, 0)
	particles.color = impact_color
	particles.mesh = _particle_mesh
	player.get_parent().add_child(particles)
	particles.global_position = point
	if normal.length_squared() > .0001: particles.quaternion = Quaternion(Vector3.UP, normal.normalized())
	particles.finished.connect(particles.queue_free)
	particles.restart()

func _play_hit(point: Vector3) -> void:
	var sound := AudioStreamPlayer3D.new()
	sound.stream = hit_sound.stream
	sound.volume_db = hit_sound.volume_db
	sound.max_distance = hit_sound.max_distance
	sound.pitch_scale = randf_range(.94, 1.06)
	player.get_parent().add_child(sound)
	sound.global_position = point
	sound.finished.connect(sound.queue_free)
	sound.play()

func _stop_cast() -> void:
	hit_cast.enabled = false
	hit_cast.target_position = Vector3.ZERO
	set_physics_process(false)
