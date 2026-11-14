extends CharacterBody3D

signal health_changed(value: int)
@export var walk_speed := 3.0
@export var run_speed := 5.5
@export var jump_speed := 5.0
@export var look_sensitivity := 0.004
var movement := Vector2.ZERO
var jump_pending := false
var health := 100
var hurt_until := 0
@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual: Node3D = $Visual

func _ready() -> void:
	add_to_group("Player")
	camera.make_current()
	$CameraPivot/SpringArm3D.add_excluded_object(get_rid())
	visual.build()

func set_movement(value: Vector2) -> void:
	movement = value.limit_length()

func look(delta: Vector2) -> void:
	# Вращается орбита камеры. Персонаж поворачивается по направлению ходьбы.
	pivot.rotation.y -= delta.x * look_sensitivity
	pivot.rotation.x = clampf(pivot.rotation.x - delta.y * look_sensitivity, -0.65, 0.65)

func jump() -> void:
	jump_pending = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 14.0 * delta
	elif jump_pending:
		velocity.y = jump_speed
	jump_pending = false
	var speed := run_speed if movement.length() > 0.85 else walk_speed
	var input_value := movement
	# Клавиши нужны для проверки в редакторе; сенсорный ввод остаётся основным.
	if Input.is_physical_key_pressed(KEY_W): input_value.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input_value.y += 1
	if Input.is_physical_key_pressed(KEY_A): input_value.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input_value.x += 1
	var direction := Basis(Vector3.UP, pivot.rotation.y) * Vector3(input_value.x, 0, input_value.y).limit_length()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), delta * 12)
	move_and_slide()
	visual.animate_motion(delta, Vector2(velocity.x, velocity.z).length())

func take_damage(amount: int) -> void:
	if Time.get_ticks_msec() < hurt_until:
		return
	hurt_until = Time.get_ticks_msec() + 550
	health = maxi(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		get_tree().call_deferred("reload_current_scene")
