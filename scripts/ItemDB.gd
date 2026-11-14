extends RefCounted
## Собственные предметы: название, категория, вес, цена и игровые характеристики.
const CATEGORIES := ["Все", "Оружие", "Броня", "Зелья", "Ингредиенты", "Разное"]
const ITEMS := {
	"iron_sword": {"name":"Железный меч", "category":"Оружие", "weight":9.0, "value":45, "damage":34, "slot":"weapon", "description":"Простой одноручный клинок. Надёжное оружие стражей Северного предела.", "view":"sword"},
	"steel_sword": {"name":"Стальной меч", "category":"Оружие", "weight":10.0, "value":140, "damage":46, "slot":"weapon", "description":"Закалённая сталь держит заточку лучше железа. Увеличивает урон в ближнем бою.", "view":"sword"},
	"dagger": {"name":"Кинжал разведчика", "category":"Оружие", "weight":2.0, "value":65, "damage":25, "slot":"weapon", "description":"Лёгкий короткий клинок для путешествий налегке.", "view":"dagger"},
	"frost_sword": {"name":"Клинок северного инея", "category":"Оружие", "weight":11.0, "value":480, "damage":60, "slot":"weapon", "description":"Редкий стальной клинок из старого арсенала крепости. Его лезвие светится холодным светом.", "view":"sword"},
	"iron_armor": {"name":"Железный доспех", "category":"Броня", "weight":24.0, "value":120, "armor":18, "slot":"armor", "description":"Тяжёлые пластины защищают корпус от ударов стражей.", "view":"armor"},
	"steel_armor": {"name":"Стальной доспех", "category":"Броня", "weight":22.0, "value":300, "armor":30, "slot":"armor", "description":"Усиленный панцирь. Даёт больше защиты при меньшем весе.", "view":"armor"},
	"iron_helmet": {"name":"Шлем дозорного", "category":"Броня", "weight":4.0, "value":70, "armor":7, "slot":"head", "description":"Кованый шлем северного гарнизона. Занимает отдельную ячейку экипировки.", "view":"helmet"},
	"silver_ring": {"name":"Серебряное кольцо защиты", "category":"Броня", "weight":0.1, "value":180, "armor":4, "slot":"ring", "description":"Небольшое кольцо с защитной руной. Можно носить вместе с доспехом.", "view":"ring"},
	"healing_potion": {"name":"Зелье лечения", "category":"Зелья", "weight":0.5, "value":35, "heal":40, "description":"Восстанавливает 40 здоровья. При полном здоровье не расходуется.", "view":"potion"},
	"strong_potion": {"name":"Большое зелье лечения", "category":"Зелья", "weight":0.7, "value":85, "heal":80, "description":"Восстанавливает 80 здоровья.", "view":"potion"},
	"frost_flower": {"name":"Морозный цветок", "category":"Ингредиенты", "weight":0.1, "value":8, "description":"Светлый цветок с холодных склонов. Ценится у торговцев и травников.", "view":"flower"},
	"iron_ingot": {"name":"Железный слиток", "category":"Разное", "weight":1.0, "value":20, "description":"Очищенный металл. Можно хранить в сундуке или носить с собой.", "view":"ingot"},
	"gold": {"name":"Золотые монеты", "category":"Разное", "weight":0.0, "value":1, "description":"Монеты прежних владельцев крепости. Не занимают вес в рюкзаке.", "view":"coin"}
}
static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})
