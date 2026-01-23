extends Node2D


func _ready():
	var map = MapManager.load_map(6)
	if map:
		add_child(map)
	else:
		printerr("No map to display !")
