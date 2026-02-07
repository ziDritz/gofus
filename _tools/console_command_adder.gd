extends Node
# Linked to Console addon from Jistpoe : https://www.youtube.com/watch?v=M_ymfQtZad4


func _ready() -> void:
	Console.add_command("load_map", console_load_map, 1)
	Console.add_command("display_cell_ids", console_display_cell_ids)


func console_load_map(param: String):
	MapManager.load_map(int(param))

func console_display_cell_ids():
	Battlefield.display_cell_ids()