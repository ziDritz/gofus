extends Node


var map_handler: MapHandler


func _ready() -> void:
	map_handler = MapHandler.new()
	add_child(map_handler)
