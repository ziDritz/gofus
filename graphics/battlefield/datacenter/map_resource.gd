# (merges Map.as and DofusMap.as). Data model

class_name MapResource
extends Resource


var id: int
var map_id: int
var map_width: int
var map_height: int
var background_id: int
var map_data: String
var ambiance_id: int
var music_id: int
var is_outdoor: bool
var can_challenge: bool
var can_attack: bool
var can_save_teleport: bool
var can_use_teleport: bool
var can_attack_hunt: bool
var can_use_item: bool
var can_equip_item: bool
var can_boost_stats: bool
var cell_resources: Array[CellResource]
var valid_cell_resources: Array[CellResource]


func _init(s_id: String) -> void:
    id = int(s_id)


func get_coordinates():
    pass


func get_x():
    pass


func get_y():
    pass