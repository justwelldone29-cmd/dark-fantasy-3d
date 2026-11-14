extends Area3D

signal struck
@export var damage := 34
@export var cooldown := 0.55
var next_attack := 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitorable = false

func attack() -> void:
	var now := Time.get_ticks_msec()
	if now < next_attack:
		return
	var visual := get_parent().get_node("Visual")
	if not visual.swing(): return
	next_attack = now + int(maxf(cooldown, visual.strike_remaining) * 1000)
	struck.emit()
	# Небольшая задержка совпадает с замахом. Список целей читается в момент удара.
	get_tree().create_timer(0.14).timeout.connect(_hit)

func _hit() -> void:
	var player := get_parent() as Node3D
	for body in get_overlapping_bodies():
		if not is_instance_valid(body) or not body.is_in_group("Enemy"):
			continue
		var offset: Vector3 = body.global_position - player.global_position
		var direction: Vector3 = -player.get_node("Visual").global_basis.z
		if offset.normalized().dot(direction) < 0.05:
			continue
		var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.3,
			body.global_position + Vector3.UP * 0.3, 1 | 4)
		ray.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider == body:
			body.take_damage(damage)
