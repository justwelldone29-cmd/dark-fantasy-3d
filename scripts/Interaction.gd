extends RayCast3D

signal prompt_changed(text: String)
var elapsed := 0.0

func _ready() -> void:
	target_position = Vector3(0, 0, -3)
	collision_mask = 1 | 4
	add_exception(get_parent().get_parent())
	# Ручное обновление 10 раз/с вместо автоматического каждый физический кадр.
	enabled = false

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0
		prompt_changed.emit("Нажмите «Действие»" if _target() != null else "")

func _target() -> Node:
	force_raycast_update()
	if not is_colliding():
		return null
	var node := get_collider() as Node
	while node != null:
		if node.is_in_group("Interactable") and node.has_method("interact"):
			return node
		node = node.get_parent()
	return null

func interact() -> void:
	# Повторный луч исключает взаимодействие с уже ушедшим из прицела объектом.
	var target := _target()
	if target != null:
		target.call("interact")
