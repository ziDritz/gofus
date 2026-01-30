extends Node


const maps_db_path: String = "res://database/maps_db.csv"
var maps_data : Dictionary = {}  # id -> row Dictionary


func _ready() -> void:
	load_csv(maps_db_path)


func load_csv(path: String) -> void:
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CSV not found: " + path)
		return

	var headers : PackedStringArray = file.get_csv_line()
	var id_index : int = headers.find("id")

	while not file.eof_reached():
		var row : PackedStringArray = file.get_csv_line()
		if row.is_empty() or row.size() == 1:
			continue

		var entry : Dictionary = {}

		for i in headers.size():
			entry[headers[i]] = row[i]

		maps_data[row[id_index]] = entry


func get_map_by_id(id: String) -> Dictionary:
	return maps_data.get(id)
