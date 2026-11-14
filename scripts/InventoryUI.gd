extends Control
## Интерфейс без постоянного _process(): перестраивается по изменению состояния.
const DB = preload("res://scripts/ItemDB.gd")
var player: Node
var mobile_ui: Control
var state: Node
var chest_id := ""
var chest_title := ""
var from_chest := false
var category := "Все"
var selected := ""
var rows: VBoxContainer
var title: Label
var description: Label
var stats: Label
var summary: Label
var message: Label
var heading: Label
var use_button: Button
var transfer_button: Button
var take_button: Button
var bag_tab: Button
var chest_tab: Button
var preview: SubViewportContainer
var categories: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	state = get_node("/root/GameState")
	state.changed.connect(refresh)
	state.notice.connect(func(text: String): message.text = text)
	var theme_value := Theme.new()
	theme_value.default_font_size = 19
	for kind in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(.19, .20, .21, .95) if kind in ["hover", "pressed"] else Color(.075, .085, .10, .95)
		style.border_color = Color("94846a") if kind in ["hover", "pressed", "focus"] else Color("383c40")
		style.set_border_width_all(1)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		theme_value.set_stylebox(kind, "Button", style)
		theme_value.set_color("font_color", "Button", Color("dfdace"))
	theme = theme_value
	var background := ColorRect.new()
	background.color = Color(.025, .035, .05, .97)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	heading = _label("ПРЕДМЕТЫ", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := _button("ЗАКРЫТЬ", close_menu)
	close.custom_minimum_size.x = 150
	header.add_child(close)
	var source_tabs := HBoxContainer.new()
	layout.add_child(source_tabs)
	bag_tab = _button("РЮКЗАК", func(): from_chest = false; selected = ""; refresh())
	chest_tab = _button("СУНДУК", func(): from_chest = true; selected = ""; refresh())
	source_tabs.add_child(bag_tab)
	source_tabs.add_child(chest_tab)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	layout.add_child(columns)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 170
	columns.add_child(sidebar)
	for name_value in DB.CATEGORIES:
		var button := _button(name_value.to_upper(), _select_category.bind(name_value))
		sidebar.add_child(button)
		categories[name_value] = button
	var list_panel := VBoxContainer.new()
	list_panel.custom_minimum_size.x = 390
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(list_panel)
	list_panel.add_child(_label("НАЗВАНИЕ                         ВЕС · ЦЕНА", 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 340
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(details)
	preview = preload("res://scripts/ItemPreview.gd").new()
	details.add_child(preview)
	title = _label("", 25)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	details.add_child(title)
	stats = _label("", 18)
	details.add_child(stats)
	description = _label("", 17)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 3
	details.add_child(description)
	use_button = _button("НАДЕТЬ", _use_selected)
	transfer_button = _button("ВЗЯТЬ", _transfer_selected)
	take_button = _button("ЗАБРАТЬ ВСЁ", _take_all)
	for button in [use_button, transfer_button, take_button]: details.add_child(button)
	message = _label("", 17)
	message.modulate = Color("d6b270")
	layout.add_child(message)
	summary = _label("", 18)
	layout.add_child(summary)
	hide()

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = Color("e6dfcf")
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	return button

func open_menu(container_id := "", container_title := "") -> void:
	chest_id = container_id
	chest_title = container_title
	from_chest = not chest_id.is_empty()
	category = "Все"
	selected = ""
	message.text = ""
	mobile_ui._reset()
	mobile_ui.hide()
	show()
	get_tree().paused = true
	refresh()

func close_menu() -> void:
	if not visible: return
	hide()
	preview.viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	get_tree().paused = false
	mobile_ui._reset()
	# Дожидаемся отпускания касания, чтобы оно не нажало кнопку под закрытым меню.
	get_tree().create_timer(.12).timeout.connect(func():
		if not visible: mobile_ui.show())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close_menu()
		get_viewport().set_input_as_handled()

func _select_category(value: String) -> void:
	category = value
	selected = ""
	refresh()

func refresh() -> void:
	if not visible: return
	bag_tab.text = "◆ РЮКЗАК" if not from_chest else "РЮКЗАК"
	chest_tab.visible = not chest_id.is_empty()
	chest_tab.text = "◆ СУНДУК" if from_chest else "СУНДУК"
	heading.text = chest_title.to_upper() if from_chest else "ПРЕДМЕТЫ"
	for key in categories: categories[key].modulate = Color("e5c282") if key == category else Color.WHITE
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var source: Dictionary = state.containers.get(chest_id, {}) if from_chest else state.items
	var ids: Array = source.keys().filter(func(id): return category == "Все" or DB.item(id).get("category", "") == category)
	ids.sort_custom(func(a, b): return DB.item(a).name < DB.item(b).name)
	if not ids.has(selected): selected = str(ids[0]) if not ids.is_empty() else ""
	for id in ids:
		var data := DB.item(id)
		var mark := "◆ " if state.equipped.values().has(id) and not from_chest else ""
		var text := "%s%s ×%d\n%.1f вес   ·   %d монет" % [mark, data.name, source[id], data.weight, data.value]
		var row := _button(text, _select_item.bind(str(id)))
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", 17)
		row.modulate = Color("e5c282") if id == selected else Color.WHITE
		rows.add_child(row)
	if ids.is_empty(): rows.add_child(_label("Сундук пуст" if from_chest else "Здесь пока ничего нет", 19))
	summary.text = "Здоровье %d/100    |    Урон %d    Броня %d    |    Вес %.1f / %.0f    |    Золото %d" % [player.health, state.weapon_damage(), state.armor_rating(), state.total_weight(), state.MAX_WEIGHT, state.items.get("gold", 0)]
	_show_details(source)

func _select_item(id: String) -> void:
	selected = id
	message.text = ""
	refresh()

func _show_details(source: Dictionary) -> void:
	var data := DB.item(selected)
	var present := not data.is_empty() and source.has(selected)
	preview.visible = present
	use_button.visible = present and not from_chest and (data.has("slot") or data.has("heal"))
	transfer_button.visible = present and not chest_id.is_empty()
	take_button.visible = from_chest and not source.is_empty()
	if not present:
		title.text = "Нет предметов"
		stats.text = ""
		description.text = "Выберите другую категорию."
		return
	preview.show_item(selected)
	title.text = data.name
	stats.text = "Вес %.1f     Стоимость %d" % [data.weight, data.value]
	if data.has("damage"): stats.text += "\nУрон %d" % data.damage
	if data.has("armor"): stats.text += "\nБроня +%d" % data.armor
	if data.has("heal"): stats.text += "\nЛечение +%d" % data.heal
	description.text = data.description
	use_button.text = "СНЯТЬ" if state.equipped.values().has(selected) else ("ВЫПИТЬ" if data.has("heal") else "ЭКИПИРОВАТЬ")
	transfer_button.text = ("ВЗЯТЬ" if from_chest else "ПОЛОЖИТЬ") + " ×" + str(source[selected])

func _use_selected() -> void:
	if DB.item(selected).has("heal"): state.consume(selected, player)
	else: state.toggle_equipment(selected)

func _transfer_selected() -> void:
	var source: Dictionary = state.containers[chest_id] if from_chest else state.items
	if source.has(selected): state.transfer(chest_id, selected, int(source[selected]), from_chest)

func _take_all() -> void:
	state.take_all(chest_id)
