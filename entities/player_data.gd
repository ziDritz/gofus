# scripts/data/player_data.gd
class_name PlayerData
extends Resource

## Runtime player data (mutable, saveable)

#region Core

var player_name: String = ""
var class_id: String = ""
var level: int = 1
var experience: int = 0

#endregion

#region Current State

var current_map_id: String = ""
var current_position: Vector2i = Vector2i.ZERO
var kamas: int = 0

#endregion

#region Inventory

var inventory: Array[Dictionary] = []

#endregion

#region Equipment

var equipment: Dictionary = {}

#endregion

#region Spells

var known_spell_ids: Array[String] = []
var spell_levels: Dictionary = {}

#endregion

#region Stats

var base_stats: Dictionary = {}

#endregion

#region Quests

var active_quests: Array[String] = []
var completed_quests: Array[String] = []

#endregion

#region Initialization

func apply_class_data(class_data: ClassData) -> void:
	base_stats = class_data.starting_stats.duplicate()
	known_spell_ids = class_data.starting_spells.duplicate()

#endregion

#region Serialization

func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"class_id": class_id,
		"level": level,
		"experience": experience,
		"current_map_id": current_map_id,
		"current_position": {"x": current_position.x, "y": current_position.y},
		"kamas": kamas,
		"inventory": inventory.duplicate(true),
		"equipment": equipment.duplicate(),
		"known_spell_ids": known_spell_ids.duplicate(),
		"spell_levels": spell_levels.duplicate(),
		"base_stats": base_stats.duplicate(),
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate()
	}


func from_dict(data: Dictionary) -> void:
	player_name = data.get("player_name", "")
	class_id = data.get("class_id", "")
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	
	current_map_id = data.get("current_map_id", "")
	var pos = data.get("current_position", {"x": 0, "y": 0})
	current_position = Vector2i(pos.x, pos.y)
	
	kamas = data.get("kamas", 0)
	
	inventory = data.get("inventory", [])
	equipment = data.get("equipment", {})
	known_spell_ids.assign(data.get("known_spell_ids", []))
	spell_levels = data.get("spell_levels", {})
	base_stats = data.get("base_stats", {})
	active_quests.assign(data.get("active_quests", []))
	completed_quests.assign(data.get("completed_quests", []))

#endregion
