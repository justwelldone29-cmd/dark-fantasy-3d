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
	var state := root.get_node("GameState")
	state.reset_defaults()
	for chest in get_nodes_in_group("LootChest"): state.ensure_chest(chest.chest_id, chest.initial_items)
	var player := main.get_node("Player")
	player.position = Vector3(2.4, .91, 3)
	for i in range(6): await physics_frame
	main._interact()
	check(main.inventory_ui.visible and paused, "Взаимодействие не открыло сундук с паузой")
	check(main.inventory_ui.chest_id == "road_chest", "Открылся другой сундук")
	await create_timer(.45).timeout
	var chest := get_nodes_in_group("LootChest")[0]
	check(chest.hinge.rotation.x < -1.0, "Крышка не открылась")
	state.take_all("road_chest")
	check(state.containers.road_chest.is_empty(), "После взятия всего осталась добыча")
	var gold_before: int = state.items.gold
	check(state.take_all("road_chest") == 0 and state.items.gold == gold_before, "Сундук дублирует добычу")
	main.inventory_ui.close_menu()
	await create_timer(.16).timeout
	check(not paused and main.get_node("HUD/MobileUI").visible, "После меню не восстановилось управление")
	state.transfer("guard_chest", "steel_sword", 1, true)
	state.toggle_equipment("steel_sword")
	check(state.weapon_damage() == 46 and player.get_node("Combat").damage == 46, "Экипировка не изменила урон")
	state.transfer("guard_chest", "steel_sword", 1, false)
	check(state.equipped.weapon == "" and state.weapon_damage() == 8, "Переданный меч остался экипирован")
	state.toggle_equipment("iron_sword")
	player.health = 17
	var potion_before: int = state.items.healing_potion
	check(state.consume("healing_potion", player) and player.health == 57, "Зелье не восстановило 40 здоровья")
	check(state.items.healing_potion == potion_before - 1, "Зелье не израсходовалось")
	player.health = 100
	potion_before = state.items.healing_potion
	check(not state.consume("healing_potion", player) and state.items.healing_potion == potion_before, "Зелье тратится при полном здоровье")
	state.ensure_chest("capacity_test", {"iron_ingot":500})
	state.take_all("capacity_test")
	check(state.total_weight() <= 120.001 and state.containers.capacity_test.iron_ingot > 0, "Нарушен предел веса")
	var count_before: int = state.items.iron_ingot
	state.save_game()
	state.reset_defaults()
	check(state.load_game() and state.items.iron_ingot == count_before and state.containers.road_chest.is_empty(), "Сохранение не восстановило предметы и пустой сундук")
	main.inventory_ui.open_menu()
	for id in preload("res://scripts/ItemDB.gd").ITEMS:
		main.inventory_ui.preview.show_item(id)
		await process_frame
	main.inventory_ui.close_menu()
	# Чистое начальное состояние для последующих тестов и сборки.
	state.reset_defaults()
	state.save_game()
	print("CHEST_TRANSFER_EQUIPMENT_POTIONS_CAPACITY_SAVE_PREVIEWS_OK=", not failed)
	quit(1 if failed else 0)
