# gofus_map.gd (merges Map.as and DofusMap.as)

class_name DofusMap
extends Node




var id: int
var data
var CanChallenge: bool
var CanAttack: bool
var SaveTeleport: bool 
var canUseTeleport: bool
var isOutdoor: bool
var CanAttackHunt: bool
var CanUseItem: bool 
var CanEquipItem: bool
var CanBoostStats: bool
var ambianceID: int
var musicID: int



func _init(nID: int) -> void:
    self.id = nID


func get_coordinates():
    pass


func get_x():
    pass


func get_y():
    pass