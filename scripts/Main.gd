extends Node3D

var kills := 0
var objective: Label
var hp: ProgressBar
var title: Label

func _ready() -> void:
	var ui := $HUD/MobileUI
	var player := $Player
	ui.movement_changed.connect(player.set_movement)
	ui.look_dragged.connect(player.look)
	ui.jump_requested.connect(player.jump)
	ui.attack_requested.connect($Player/Combat.attack)
	ui.interact_requested.connect(_interact)
	_make_hud()
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
	if kills >= 3 and $Player.global_position.distance_to(Vector3(0, 0.9, -25)) < 3:
		objective.text = "Северный предел освобождён"

func _capture() -> void:
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/northreach-preview.png")
	get_tree().quit()
