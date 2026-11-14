extends SceneTree
## Регрессия реального контакта, препятствий и однократного урона.
class Dummy:
	extends StaticBody3D
	var hits := 0
	func take_damage(_amount: int) -> void: hits += 1
var failed := false
var saw_particles := false
var saw_sound := false
var saw_shake := false
func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error(text)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var player := main.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector3(0, .91, 5)
	player.visual.rotation.y = 0
	for enemy in get_nodes_in_group("Enemy"):
		enemy.set_physics_process(false)
		enemy.position = Vector3(20, 1, -20)
	var combat := player.get_node("Combat")
	combat.hit_confirmed.connect(func(_target: Node, point: Vector3):
		check(point.distance_to(player.global_position) < 2.0, "Точка эффекта находится далеко от меча"))
	var targets: Array[Dummy] = []
	for pos in [Vector3(.4, .91, 4.2), Vector3(.65, .91, 4.25), Vector3(0, .91, 2.5), Vector3(0, .91, 6.2)]:
		var dummy := Dummy.new()
		dummy.collision_layer = 4
		dummy.collision_mask = 0
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = .3
		shape.height = 1.8
		collision.shape = shape
		dummy.add_child(collision)
		main.add_child(dummy)
		dummy.position = pos
		targets.append(dummy)
	await physics_frame
	check(not combat.hit_cast.enabled and not combat.is_physics_processing(), "Cast работает вне атаки")
	combat.attack()
	check(not combat.attack(), "Повторная атака прошла кулдаун")
	await run_swing(player, main)
	check(targets[0].hits == 1 and targets[1].hits == 1, "Несколько целей не получили ровно один удар")
	check(targets[2].hits == 0 and targets[3].hits == 0, "Урон вне траектории лезвия")
	check(saw_particles and saw_sound and saw_shake, "Не запущены эффекты подтверждённого попадания")
	check(not combat.hit_cast.enabled and not combat.is_physics_processing(), "Cast не выключился после атаки")
	await create_timer(.4).timeout
	check(is_zero_approx(player.camera.h_offset) and is_zero_approx(player.camera.v_offset), "Камера не вернулась в исходное положение")
	for child in main.get_children():
		check(not (child is CPUParticles3D or child is AudioStreamPlayer3D), "Эффект не удалился после завершения")
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(3, 3, .15)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	main.add_child(wall)
	wall.position = Vector3(0, 1, 4.55)
	await physics_frame
	combat.next_attack = 0
	combat.attack()
	await run_swing(player, main)
	check(targets[0].hits == 1 and targets[1].hits == 1, "Урон прошёл через стену")
	wall.queue_free()
	await physics_frame
	combat.next_attack = 0
	combat.attack()
	player.visual.animate_motion(.1, 0)
	player.visual.set_equipped_weapon("steel_sword")
	await physics_frame
	await physics_frame
	check(not combat.hit_cast.enabled and not combat.is_physics_processing(), "Смена оружия не выключила Cast")
	check(targets[0].hits == 1, "Отменённый удар нанёс урон")
	if not failed: print("SWORD_SWEEP_MULTI_TARGET_ONCE_OCCLUSION_EFFECTS_CLEANUP_CANCEL_OK")
	quit(1 if failed else 0)
func run_swing(player: Node, main: Node) -> void:
	for frame in range(67):
		player.visual.animate_motion(1.0 / 60, 0)
		await physics_frame
		for child in main.get_children():
			if child is CPUParticles3D: saw_particles = true
			if child is AudioStreamPlayer3D and child.playing: saw_sound = true
		if player.camera._remaining > 0: saw_shake = true
