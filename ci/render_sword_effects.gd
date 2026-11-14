extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var player := main.get_node("Player")
	player.set_physics_process(false)
	player.visual.rotation.y = 0
	for enemy in get_nodes_in_group("Enemy"): enemy.set_physics_process(false)
	var enemy := main.get_node("Enemy")
	enemy.position = player.position + Vector3(.4, 0, -.8)
	main.get_node("HUD").hide()
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.position = player.position + Vector3(2.7, 1.25, 2.1)
	camera.look_at(player.position + Vector3(.2, .4, -.3))
	camera.fov = 43
	camera.make_current()
	for i in range(3): await physics_frame
	var combat := player.get_node("Combat")
	combat.attack()
	for frame in range(65):
		player.visual.animate_motion(1.0 / 60, 0)
		await physics_frame
		if enemy.health < 100:
			combat.set_physics_process(false)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/workspace/qa/sword_impact.png")
			print("SWORD_IMPACT_RENDERED health=", enemy.health)
			await create_timer(.5).timeout
			quit()
			return
	push_error("Нет попадания для проверки эффекта")
	quit(1)
