extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main := load("res://scenes/Main.tscn").instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var player := main.get_node("Player")
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("Enemy"): enemy.set_physics_process(false)
	main.get_node("HUD").hide()
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.position = player.position + Vector3(3.5, 1.3, 1.8)
	camera.look_at(player.position + Vector3.UP * .15)
	camera.fov = 43
	camera.make_current()
	var visual := player.get_node("Visual")
	visual.animate_motion(.2, 0)
	visual.swing()
	DirAccess.make_dir_recursive_absolute("/workspace/qa")
	var previous := 0.0
	var frames := [0.0, .18, .40, .65, .95]
	for i in range(frames.size()):
		visual.animate_motion(frames[i] - previous, 0)
		previous = frames[i]
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/workspace/qa/strike_%d.png" % i)
	main.get_node("HUD").show()
	main.inventory_ui.open_menu()
	main.inventory_ui.selected = "iron_armor"
	main.inventory_ui.refresh()
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/qa/full_armor.png")
	print("STRIKE_AND_FULL_ARMOR_RENDERED")
	quit()
