# scripts/entities/entity_data.gd
class_name EntityData
extends Resource

## Pure data layer for entities - easily serializable

#region Signals

signal health_changed(old_value: int, new_value: int)
signal max_health_changed(old_value: int, new_value: int)
signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal position_changed(old_pos: Vector2i, new_pos: Vector2i)
signal status_effect_added(effect_id: String)
signal status_effect_removed(effect_id: String)
signal died()

#endregion

#region Core Identity

@export var entity_id: String = ""
@export var entity_name: String = "Unknown"
@export var entity_type: String = "generic"
@export var level: int = 1

#endregion

#region Position

var grid_position: Vector2i = Vector2i.ZERO
var map_id: String = ""

#endregion

#region Stats

var stats: Dictionary = {
	"max_health": 100,
	"health": 100,
	"max_action_points": 6,
	"action_points": 6,
	"max_movement_points": 3,
	"movement_points": 3,
	"strength": 10,
	"intelligence": 10,
	"chance": 10,
	"agility": 10,
	"vitality": 10,
	"wisdom": 10,
	"armor": 0,
	"resistance_neutral": 0,
	"resistance_earth": 0,
	"resistance_fire": 0,
	"resistance_water": 0,
	"resistance_air": 0,
	"damage_neutral": 0,
	"damage_earth": 0,
	"damage_fire": 0,
	"damage_water": 0,
	"damage_air": 0,
	"initiative": 100,
	"prospecting": 100,
	"dodge": 0,
	"lock": 0,
	"critical_hit_chance": 5,
	"critical_hit_bonus": 0
}

#endregion

#region Status Effects

var status_effects: Array[Dictionary] = []

#endregion

#region Equipment

var equipment: Dictionary = {
	"weapon": "",
	"hat": "",
	"cloak": "",
	"amulet": "",
	"ring_left": "",
	"ring_right": "",
	"belt": "",
	"boots": "",
	"shield": "",
	"pet": "",
	"dofus_1": "",
	"dofus_2": "",
	"dofus_3": "",
	"dofus_4": "",
	"dofus_5": "",
	"dofus_6": ""
}

#endregion

#region Inventory

var inventory_items: Array[Dictionary] = []
var kamas: int = 0

#endregion

#region Spells

var known_spells: Array[String] = []
var spell_levels: Dictionary = {}

#endregion

#region State Flags

var is_alive: bool = true
var is_in_fight: bool = false
var can_act: bool = true
var is_moving: bool = false

#endregion

#region Initialization

func initialize(id: String, name: String, type: String) -> void:
	entity_id = id
	entity_name = name
	entity_type = type

#endregion

#region Health Management

func set_health(value: int) -> void:
	var old_health = stats["health"]
	var new_health = clampi(value, 0, stats["max_health"])
	
	if old_health == new_health:
		return
	
	stats["health"] = new_health
	health_changed.emit(old_health, new_health)
	
	if new_health == 0 and is_alive:
		is_alive = false
		died.emit()
		EventBus.entity_died.emit(entity_id, "")


func modify_health(amount: int) -> void:
	set_health(stats["health"] + amount)


func set_max_health(value: int) -> void:
	var old_max = stats["max_health"]
	stats["max_health"] = max(1, value)
	max_health_changed.emit(old_max, stats["max_health"])
	
	if stats["health"] > stats["max_health"]:
		set_health(stats["max_health"])


func heal_to_full() -> void:
	set_health(stats["max_health"])


func is_dead() -> bool:
	return not is_alive

#endregion

#region Stat Management

func get_stat(stat_name: String) -> float:
	var base_value = stats.get(stat_name, 0.0)
	var equipment_bonus = _calculate_equipment_bonus(stat_name)
	var effect_bonus = _calculate_status_effect_bonus(stat_name)
	
	return base_value + equipment_bonus + effect_bonus


func set_stat(stat_name: String, value: float) -> void:
	if not stats.has(stat_name):
		push_warning("[EntityData] Unknown stat: %s" % stat_name)
		return
	
	var old_value = stats[stat_name]
	stats[stat_name] = value
	
	stat_changed.emit(stat_name, old_value, value)


func modify_stat(stat_name: String, amount: float) -> void:
	if not stats.has(stat_name):
		return
	
	set_stat(stat_name, stats[stat_name] + amount)

#endregion

#region Action Points

func spend_action_points(amount: int) -> bool:
	if stats["action_points"] >= amount:
		modify_stat("action_points", -amount)
		return true
	return false


func restore_action_points() -> void:
	set_stat("action_points", stats["max_action_points"])

#endregion

#region Movement Points

func spend_movement_points(amount: int) -> bool:
	if stats["movement_points"] >= amount:
		modify_stat("movement_points", -amount)
		return true
	return false


func restore_movement_points() -> void:
	set_stat("movement_points", stats["max_movement_points"])

#endregion

#region Position Management

func set_grid_position(new_pos: Vector2i, new_map_id: String = "") -> void:
	var old_pos = grid_position
	grid_position = new_pos
	
	if not new_map_id.is_empty():
		map_id = new_map_id
	
	position_changed.emit(old_pos, new_pos)

#endregion

#region Status Effects

func add_status_effect(effect_id: String, duration: int, stacks: int = 1, data: Dictionary = {}) -> void:
	for effect in status_effects:
		if effect["effect_id"] == effect_id:
			effect["stacks"] += stacks
			effect["duration"] = max(effect["duration"], duration)
			return
	
	status_effects.append({
		"effect_id": effect_id,
		"duration": duration,
		"stacks": stacks,
		"data": data
	})
	
	status_effect_added.emit(effect_id)


func remove_status_effect(effect_id: String) -> bool:
	for i in range(status_effects.size()):
		if status_effects[i]["effect_id"] == effect_id:
			status_effects.remove_at(i)
			status_effect_removed.emit(effect_id)
			return true
	return false


func has_status_effect(effect_id: String) -> bool:
	for effect in status_effects:
		if effect["effect_id"] == effect_id:
			return true
	return false


func tick_status_effects() -> void:
	var to_remove: Array[String] = []
	
	for effect in status_effects:
		effect["duration"] -= 1
		if effect["duration"] <= 0:
			to_remove.append(effect["effect_id"])
	
	for effect_id in to_remove:
		remove_status_effect(effect_id)

#endregion

#region Equipment

func equip_item(item_id: String, slot: String) -> bool:
	if not equipment.has(slot):
		push_warning("[EntityData] Invalid equipment slot: %s" % slot)
		return false
	
	equipment[slot] = item_id
	
	EventBus.item_equipped.emit(entity_id, item_id, slot)
	_recalculate_derived_stats()
	
	return true


func unequip_item(slot: String) -> String:
	if not equipment.has(slot):
		return ""
	
	var item_id = equipment[slot]
	equipment[slot] = ""
	
	if not item_id.is_empty():
		EventBus.item_unequipped.emit(entity_id, item_id, slot)
		_recalculate_derived_stats()
	
	return item_id


func get_equipped_item(slot: String) -> String:
	return equipment.get(slot, "")

#endregion

#region Spells

func learn_spell(spell_id: String) -> bool:
	if spell_id in known_spells:
		return false
	
	known_spells.append(spell_id)
	spell_levels[spell_id] = 1
	return true


func get_spell_level(spell_id: String) -> int:
	return spell_levels.get(spell_id, 0)


func level_up_spell(spell_id: String) -> bool:
	if not spell_id in known_spells:
		return false
	
	spell_levels[spell_id] = spell_levels.get(spell_id, 1) + 1
	return true

#endregion

#region Fight State

func start_turn() -> void:
	restore_action_points()
	restore_movement_points()
	tick_status_effects()
	can_act = true


func end_turn() -> void:
	can_act = false

#endregion

#region Serialization

func to_dict() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_name": entity_name,
		"entity_type": entity_type,
		"level": level,
		"grid_position": {"x": grid_position.x, "y": grid_position.y},
		"map_id": map_id,
		"stats": stats.duplicate(),
		"status_effects": status_effects.duplicate(true),
		"equipment": equipment.duplicate(),
		"inventory_items": inventory_items.duplicate(true),
		"kamas": kamas,
		"known_spells": known_spells.duplicate(),
		"spell_levels": spell_levels.duplicate(),
		"is_alive": is_alive,
		"is_in_fight": is_in_fight
	}


func from_dict(data: Dictionary) -> void:
	entity_id = data.get("entity_id", "")
	entity_name = data.get("entity_name", "Unknown")
	entity_type = data.get("entity_type", "generic")
	level = data.get("level", 1)
	
	var pos = data.get("grid_position", {"x": 0, "y": 0})
	grid_position = Vector2i(pos["x"], pos["y"])
	map_id = data.get("map_id", "")
	
	stats = data.get("stats", {})
	status_effects = data.get("status_effects", [])
	equipment = data.get("equipment", {})
	inventory_items = data.get("inventory_items", [])
	kamas = data.get("kamas", 0)
	known_spells = data.get("known_spells", [])
	spell_levels = data.get("spell_levels", {})
	is_alive = data.get("is_alive", true)
	is_in_fight = data.get("is_in_fight", false)

#endregion

#region Private Helpers

func _calculate_equipment_bonus(stat_name: String) -> float:
	return 0.0


func _calculate_status_effect_bonus(stat_name: String) -> float:
	var total: float = 0.0
	return total


func _recalculate_derived_stats() -> void:
	pass

#endregion
