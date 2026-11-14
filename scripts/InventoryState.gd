extends Node
## Единое состояние переживает перезагрузку сцены и сохраняется между запусками.
signal changed
signal notice(text: String)
const DB = preload("res://scripts/ItemDB.gd")
const SAVE_FILE := "user://northreach_inventory_v1.json"
const MAX_WEIGHT := 120.0
var items: Dictionary = {}
var equipped: Dictionary = {}
var containers: Dictionary = {}
var opened_chests: Dictionary = {}

func _ready() -> void:
	reset_defaults()
	load_game()

func reset_defaults() -> void:
	items = {"iron_sword":1, "iron_armor":1, "healing_potion":2, "gold":18}
	equipped = {"weapon":"iron_sword", "armor":"iron_armor", "head":"", "ring":""}
	containers = {}
	opened_chests = {}

func total_weight() -> float:
	var result := 0.0
	for id in items: result += float(DB.item(id).get("weight", 0)) * int(items[id])
	return result

func armor_rating() -> int:
	var result := 0
	for id in equipped.values(): result += int(DB.item(str(id)).get("armor", 0))
	return result

func weapon_damage() -> int:
	return int(DB.item(str(equipped.get("weapon", ""))).get("damage", 8))

func ensure_chest(id: String, initial: Dictionary) -> void:
	if not containers.has(id): containers[id] = _clean_items(initial)

func open_chest(id: String) -> void:
	opened_chests[id] = true
	_commit()

func transfer(chest_id: String, id: String, amount: int, to_player: bool) -> int:
	if not containers.has(chest_id) or DB.item(id).is_empty() or amount <= 0: return 0
	var chest: Dictionary = containers[chest_id]
	var source: Dictionary = chest if to_player else items
	var destination: Dictionary = items if to_player else chest
	var count := mini(int(source.get(id, 0)), amount)
	if to_player:
		var unit_weight := float(DB.item(id).get("weight", 0))
		if unit_weight > 0:
			count = mini(count, maxi(0, int(floor((MAX_WEIGHT - total_weight() + 0.0001) / unit_weight))))
	if count <= 0:
		notice.emit("Рюкзак заполнен")
		return 0
	source[id] = int(source[id]) - count
	if int(source[id]) <= 0: source.erase(id)
	destination[id] = int(destination.get(id, 0)) + count
	# Обе стороны изменяются до записи: один предмет не может оказаться в двух местах.
	for slot in equipped:
		if not items.has(equipped[slot]): equipped[slot] = ""
	_commit()
	return count

func take_all(chest_id: String) -> int:
	var count := 0
	if not containers.has(chest_id): return count
	var chest: Dictionary = containers[chest_id]
	for id in chest.keys(): count += transfer(chest_id, str(id), int(chest[id]), true)
	return count

func toggle_equipment(id: String) -> void:
	var data := DB.item(id)
	if not items.has(id) or not data.has("slot"): return
	var slot: String = data.slot
	equipped[slot] = "" if equipped.get(slot, "") == id else id
	_commit()

func consume(id: String, player: Node) -> bool:
	var data := DB.item(id)
	if not items.has(id) or not data.has("heal"): return false
	if player.health >= 100:
		notice.emit("Здоровье уже полное")
		return false
	player.health = mini(100, player.health + int(data.heal))
	player.health_changed.emit(player.health)
	items[id] = int(items[id]) - 1
	if int(items[id]) <= 0: items.erase(id)
	_commit()
	return true

func _commit() -> void:
	save_game()
	changed.emit()

func save_game() -> void:
	var file := FileAccess.open(SAVE_FILE + ".tmp", FileAccess.WRITE)
	if file == null:
		push_warning("Не удалось записать инвентарь")
		return
	file.store_string(JSON.stringify({"version":1, "items":items, "equipped":equipped, "containers":containers, "opened":opened_chests}))
	file.flush()
	file.close()
	DirAccess.rename_absolute(SAVE_FILE + ".tmp", SAVE_FILE)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
	if not data is Dictionary or data.get("version", 0) != 1: return false
	if not data.get("equipped", {}) is Dictionary: return false
	items = _clean_items(data.get("items", {}))
	for slot in equipped:
		var id := str(data.equipped.get(slot, ""))
		equipped[slot] = id if items.has(id) and DB.item(id).get("slot", "") == slot else ""
	containers = {}
	if data.get("containers", {}) is Dictionary:
		for id in data.containers: containers[str(id)] = _clean_items(data.containers[id])
	opened_chests = data.get("opened", {}) if data.get("opened", {}) is Dictionary else {}
	return true

func _clean_items(raw: Variant) -> Dictionary:
	var result := {}
	if raw is Dictionary:
		for id in raw:
			if DB.ITEMS.has(str(id)) and (raw[id] is float or raw[id] is int) and int(raw[id]) > 0:
				result[str(id)] = mini(999999, int(raw[id]))
	return result
