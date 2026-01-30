# Battlefield = DofusBattlefier = api.gfx
extends Node


var map_handler: MapHandler


func _ready() -> void:
	map_handler = MapHandler.new()
	add_child(map_handler)


func build_map(map_resource: MapResource):
	pass
