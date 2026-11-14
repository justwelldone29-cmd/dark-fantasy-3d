extends SceneTree
var failed := false
func _initialize() -> void:
	_run.call_deferred()
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await physics_frame
	var player := main.get_node("Player")
	var ui := main.get_node("HUD/MobileUI")
	var origin: Vector3 = player.position
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(100, 500)
	touch.pressed = true
	ui._input(touch)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = touch.position - Vector2(0, ui.radius)
	drag.relative = Vector2(0, -ui.radius)
	ui._input(drag)
	await process_frame
	print("TOUCH=",player.movement," RADIUS=",ui.radius)
	for i in range(30): await physics_frame
	print("START=",origin," END=",player.position," MOVEMENT=",player.movement)
	check(player.position.distance_to(origin) > 1.0, "Сенсорный джойстик не перемещает игрока")
	touch.pressed = false
	ui._input(touch)
	await physics_frame
	check(player.movement.is_zero_approx(), "Джойстик не остановился после отпускания")
	if not failed: print("TOUCH_HANDLER_MOVEMENT_OK")
	var enemy := main.get_node("Enemy")
	for other in get_nodes_in_group("Enemy"): other.set_physics_process(false)
	var height: float = enemy.visual._posed_bounds(enemy.visual.model).size.y * enemy.visual.model.scale.y
	check(height > 1.0 and height < 2.5, "Ошибочный масштаб скелета")
	check(enemy.visual.animator.has_animation("death") and enemy.visual.animator.has_animation("attack1"), "Не импортированы боевые анимации")
	player.position = Vector3(0, .91, 5)
	player.visual.rotation.y = 0
	enemy.position = Vector3(.4, .91, 4.2)
	for i in range(5): await physics_frame
	var combat := player.get_node("Combat")
	combat.attack()
	await create_timer(player.visual.strike_length * player.visual.CONTACT_PHASE + .08).timeout
	check(enemy.health == 66, "Первый удар не нанёс ровно 34 урона")
	combat.attack()
	await create_timer(.20).timeout
	check(enemy.health == 66, "Кулдаун не блокирует повторный удар")
	await create_timer(maxf(.02, player.visual.strike_remaining + .06)).timeout
	combat.attack()
	await create_timer(maxf(.02, player.visual.strike_remaining + .06)).timeout
	combat.attack()
	await create_timer(player.visual.strike_length * player.visual.CONTACT_PHASE + .08).timeout
	check(enemy.dead, "Враг не погиб после трёх ударов")
	check(enemy.visual.animator.current_animation == "death", "Смерть не использует анимацию рига")
	check(enemy.get_node("CollisionShape3D").disabled, "Коллизия погибшего врага осталась включена")
	await create_timer(.4).timeout
	if not failed: print("COMBAT_DAMAGE_COOLDOWN_DEATH_OK")
	quit(1 if failed else 0)
