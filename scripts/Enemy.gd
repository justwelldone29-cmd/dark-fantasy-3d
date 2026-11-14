extends CharacterBody3D

signal defeated
@export var speed := 1.8
@export var sight_range := 9.0
@export var attack_range := 1.5
@export var health := 100
var player: Node3D
var home := Vector3.ZERO
var patrol_target := Vector3.ZERO
var next_attack := 0
var next_sense := 0
var sees_player := false
var dead := false
@onready var visual: Node3D = $Visual

func _ready() -> void:
	add_to_group("Enemy")
	visual.build(true)
	player = get_tree().get_first_node_in_group("Player")
	home = global_position
	patrol_target = home + Vector3(2, 0, 0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or dead:
		return
	var now := Time.get_ticks_msec()
	var offset := player.global_position - global_position
	if now >= next_sense:
		next_sense = now + 250
		sees_player = false
		if offset.length_squared() <= sight_range * sight_range:
			var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5,
				player.global_position + Vector3.UP * 0.5, 1 | 2)
			query.exclude = [get_rid()]
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			sees_player = not hit.is_empty() and hit.collider == player
	var target := player.global_position if sees_player else patrol_target
	var direction := target - global_position
	direction.y = 0
	if sees_player and offset.length() <= attack_range:
		direction = Vector3.ZERO
		visual.rotation.y = atan2(-offset.x, -offset.z)
		if now >= next_attack:
			next_attack = now + 1400
			visual.swing()
			get_tree().create_timer(0.3, false).timeout.connect(_attack_hit)
	elif not sees_player and direction.length_squared() < 0.25:
		patrol_target = home + (Vector3(-2, 0, 0) if patrol_target.x > home.x else Vector3(2, 0, 0))
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), delta * 8)
	if not is_on_floor(): velocity.y -= 14.0 * delta
	move_and_slide()
	visual.animate_motion(delta, Vector2(velocity.x, velocity.z).length())

func _attack_hit() -> void:
	if dead or not is_instance_valid(player): return
	if global_position.distance_to(player.global_position) <= attack_range + 0.25:
		player.take_damage(12)

func take_damage(amount: int) -> void:
	if dead: return
	health -= maxi(0, amount)
	if health <= 0:
		dead = true
		set_physics_process(false)
		defeated.emit()
		$CollisionShape3D.set_deferred("disabled", true)
		var tween := create_tween()
		tween.tween_interval(visual.die())
		tween.tween_interval(2)
		tween.tween_callback(queue_free)
