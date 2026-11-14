extends Node3D

var kills := 0
var objective: Label
var hp: ProgressBar
var title: Label
var inventory_ui: Control
var state: Node
var interaction_prompt: Label
var interaction_ray: RayCast3D
var focused_chest: Node3D

func _ready() -> void:
	get_tree().quit_on_go_back = false
	# Только одно направление эмуляции: касание -> GUI на телефоне, мышь -> джойстик на ПК.
	if not OS.has_feature("mobile"):
		Input.emulate_mouse_from_touch = false
		Input.emulate_touch_from_mouse = true
	var ui := $HUD/MobileUI
	var player := $Player
	ui.movement_changed.connect(player.set_movement)
	ui.look_dragged.connect(player.look)
	ui.jump_requested.connect(player.jump)
	ui.attack_requested.connect($Player/Combat.attack)
	ui.interact_requested.connect(_interact)
	_make_hud()
	state = get_node("/root/GameState")
	inventory_ui = preload("res://scripts/InventoryUI.gd").new()
	inventory_ui.player = player
	inventory_ui.mobile_ui = ui
	$HUD.add_child(inventory_ui)
	ui.inventory_requested.connect(func(): inventory_ui.open_menu())
	state.changed.connect(_equipment_changed)
	_equipment_changed()
	_make_chests()
	interaction_ray = RayCast3D.new()
	interaction_ray.target_position = Vector3(0, 0, -8)
	interaction_ray.collision_mask = 1
	player.camera.add_child(interaction_ray)
	var timer := Timer.new()
	timer.wait_time = .2
	timer.timeout.connect(_update_interaction)
	add_child(timer)
	timer.start()
	player.health_changed.connect(func(value: int): hp.value = value)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy.defeated.connect(_enemy_defeated)
	# Режим автоматического снимка используется только при визуальной проверке.
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()

func _make_hud() -> void:
	var hud := $HUD
	title = Label.new()
	title.text = "СЕВЕРНЫЙ ПРЕДЕЛ"
	title.position = Vector2(34, 24)
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color("e7d9b6")
	hud.add_child(title)
	objective = Label.new()
	objective.text = "Забытая крепость\nПобедите стражей: 0 / 3"
	objective.position = Vector2(34, 63)
	objective.add_theme_font_size_override("font_size", 17)
	objective.modulate = Color("d0d8cd")
	hud.add_child(objective)
	hp = ProgressBar.new()
	hp.position = Vector2(34, 120)
	hp.size = Vector2(220, 9)
	hp.value = 100
	hp.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ac5147")
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	hp.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.04, 0.05, 0.05, 0.7)
	hp.add_theme_stylebox_override("background", background)
	hp.size.y = 9
	hud.add_child(hp)
	interaction_prompt = Label.new()
	interaction_prompt.position = Vector2(390, 510)
	interaction_prompt.size = Vector2(500, 50)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.add_theme_font_size_override("font_size", 22)
	interaction_prompt.modulate = Color("e7d9b6")
	hud.add_child(interaction_prompt)
	var help := Label.new()
	help.text = "Слева — движение   •   Справа — обзор"
	help.position = Vector2(440, 28)
	help.modulate = Color(0.9, 0.9, 0.8, 0.65)
	hud.add_child(help)

func _enemy_defeated() -> void:
	kills += 1
	objective.text = "Забытая крепость\nПобедите стражей: %d / 3" % kills
	if kills == 3:
		objective.text = "Стражи повержены\nПодойдите к кристаллу в крепости"

func _interact() -> void:
	_update_interaction()
	if is_instance_valid(focused_chest):
		focused_chest.interact($Player)
		return
	if kills >= 3 and $Player.global_position.distance_to(Vector3(0, 0.9, -33)) < 3:
		objective.text = "Северный предел освобождён"

func _capture() -> void:
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/northreach-preview.png")
	get_tree().quit()

func _equipment_changed() -> void:
	$Player/Combat.damage = state.weapon_damage()
	$Player/Visual.set_equipped_weapon(str(state.equipped.get("weapon", "")))

func _make_chests() -> void:
	var definitions := [
		["road_chest", "Дорожный сундук", Vector3(2.4, 0, 1.0), {"healing_potion":3, "dagger":1, "gold":42, "frost_flower":4}],
		["guard_chest", "Сундук стражи", Vector3(-5, 0, -17), {"steel_sword":1, "iron_helmet":1, "gold":75, "iron_ingot":5}],
		["castle_chest", "Старый арсенал", Vector3(5, 0, -33), {"frost_sword":1, "steel_armor":1, "silver_ring":1, "strong_potion":2, "gold":180}]
	]
	for data in definitions:
		var chest := preload("res://scripts/LootChest.gd").new()
		chest.chest_id = data[0]
		chest.chest_title = data[1]
		chest.position = data[2]
		chest.initial_items = data[3]
		chest.requested.connect(func(value: Node): inventory_ui.open_menu(value.chest_id, value.chest_title))
		add_child(chest)
	state.save_game()

func _update_interaction() -> void:
	focused_chest = null
	var player := $Player
	if interaction_ray:
		interaction_ray.force_raycast_update()
		var body = interaction_ray.get_collider()
		if body is Node3D and body.is_in_group("LootChest") and player.global_position.distance_to(body.global_position) <= 3.2:
			focused_chest = body
	if focused_chest == null:
		var nearest := 3.2
		for chest in get_tree().get_nodes_in_group("LootChest"):
			var distance: float = player.global_position.distance_to(chest.global_position)
			if distance >= nearest: continue
			var offset: Vector3 = chest.global_position + Vector3.UP * .5 - player.camera.global_position
			if -player.camera.global_basis.z.dot(offset.normalized()) < .2: continue
			var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * .2, chest.global_position + Vector3.UP * .45, 1)
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.collider != chest: continue
			nearest = distance
			focused_chest = chest
	interaction_prompt.text = "ДЕЙСТВИЕ · " + focused_chest.chest_title if focused_chest else ""

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_I:
		inventory_ui.open_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(inventory_ui) and inventory_ui.visible: inventory_ui.close_menu()
		else: get_tree().quit()
