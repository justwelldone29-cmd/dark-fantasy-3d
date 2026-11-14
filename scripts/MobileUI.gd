extends Control

signal movement_changed(value: Vector2)
signal look_dragged(delta: Vector2)
signal jump_requested
signal attack_requested
signal interact_requested

var move_finger := -1
var look_finger := -1
var origin := Vector2.ZERO
var stick := Vector2.ZERO
var look_origin := Vector2.ZERO
var look_distance := 0.0
var look_start := 0
var radius := 85.0
var credits_rect := Rect2()
var button_rects: Array[Rect2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	_reset()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	button_rects.clear()
	var screen := get_viewport_rect().size
	radius = minf(screen.x, screen.y) * 0.12
	# TouchScreenButton сам отслеживает пальцы; области исключены из свайпа.
	var names := ["ПРЫЖОК", "УДАР", "ДЕЙСТВИЕ"]
	var actions: Array[Signal] = [jump_requested, attack_requested, interact_requested]
	for i in range(3):
		var center := Vector2(screen.x - 75 - i * 135, screen.y - 85)
		var rect := Rect2(center - Vector2(55, 55), Vector2(110, 110))
		button_rects.append(rect)
		var button := TouchScreenButton.new()
		var shape := CircleShape2D.new()
		shape.radius = 55
		button.shape = shape
		button.position = center
		button.pressed.connect(actions[i].emit)
		add_child(button)
		var label := Label.new()
		label.text = names[i]
		label.add_theme_font_size_override("font_size", 15)
		label.modulate = Color("e7d9b6")
		label.position = rect.position
		label.size = rect.size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	credits_rect = Rect2(Vector2(screen.x - 125, 15), Vector2(110, 38))
	var credits := Button.new()
	credits.text = "Авторы"
	credits.position = credits_rect.position
	credits.size = credits_rect.size
	credits.pressed.connect(_show_credits)
	add_child(credits)
	queue_redraw()

func _show_credits() -> void:
	_reset()
	var dialog := AcceptDialog.new()
	dialog.title = "Авторы и лицензии"
	dialog.dialog_text = FileAccess.get_file_as_string("res://assets/CREDITS.txt")
	dialog.get_ok_button().text = "Закрыть"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		_reset()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if credits_rect.has_point(event.position): return
			for rect in button_rects:
				if rect.has_point(event.position):
					return
			if event.position.x < get_viewport_rect().size.x * 0.5 and move_finger == -1:
				move_finger = event.index
				origin = event.position
			elif event.position.x >= get_viewport_rect().size.x * 0.5 and look_finger == -1:
				look_finger = event.index
				look_origin = event.position
				look_distance = 0
				look_start = Time.get_ticks_msec()
		else:
			if event.index == move_finger:
				move_finger = -1
				stick = Vector2.ZERO
				movement_changed.emit(stick)
			if event.index == look_finger:
				look_finger = -1
				if not event.canceled and look_distance < 15 and Time.get_ticks_msec() - look_start < 250:
					interact_requested.emit()
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == move_finger:
			stick = ((event.position - origin) / radius).limit_length()
			movement_changed.emit(stick if stick.length() > 0.12 else Vector2.ZERO)
			queue_redraw()
		elif event.index == look_finger:
			look_distance += event.relative.length()
			look_dragged.emit(event.relative)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset()

func _reset() -> void:
	move_finger = -1
	look_finger = -1
	stick = Vector2.ZERO
	movement_changed.emit(stick)
	queue_redraw()

func _draw() -> void:
	for rect in button_rects:
		draw_arc(rect.get_center(), 55, 0, TAU, 48, Color(0.8, 0.76, 0.6, 0.7), 1.5, true)
		draw_circle(rect.get_center(), 55, Color(0.08, 0.14, 0.14, 0.55))
	if move_finger == -1:
		var center := Vector2(140, get_viewport_rect().size.y - 140)
		draw_arc(center, radius, 0, TAU, 48, Color(0.8, 0.76, 0.6, 0.35), 1.5, true)
		draw_circle(center, radius * 0.3, Color(0.8, 0.76, 0.6, 0.2))
	if move_finger != -1:
		draw_circle(origin, radius, Color(0.5, 0.6, 0.7, 0.25))
		draw_circle(origin + stick * radius, radius * 0.35, Color(0.8, 0.9, 1, 0.6))
