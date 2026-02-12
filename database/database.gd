# Database.gd
# AutoLoad singleton
# Handles data persistence and provides quick access to data

extends Node


const CSV_PATH : String = "res://database/maps_data.csv"

## Stores all loaded map data indexed by map_id for quick lookup
var _map_cache: Dictionary = {} # I tried to use an array instead, but very little gains in the end


func _ready() -> void:
	print("[Database] Initializing...")
	_load_all_maps()
	print("[Database] Ready")


## Load all map data from CSV file
## Flow: CSV file → Dictionary of map dictionaries
func _load_all_maps() -> void:
	print("[Database] Loading maps from CSV: %s" % CSV_PATH)
	
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		push_error("[Database] Failed to open maps CSV: " + CSV_PATH)
		return
	
	# Read header
	var header: PackedStringArray = file.get_csv_line()
	print("[Database] CSV header: %s" % str(header))
	
	# Parse rows
	var count: int = 0
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 7:  # Skip empty/invalid rows, used toskip the last row get (empty)
			continue
		
		var map_data: Dictionary = {
			"id": int(row[0]),
			"date": row[1],
			"width": int(row[2]),
			"height": int(row[3]),
			"places": row[4],
			"key": row[5],
			"mapData": row[6],
			"monsters": row[7],
			"capabilities": int(row[8]),
			"mappos": row[9],
			"numgroup": int(row[10]),
			"minSize": int(row[11]),
			"fixSize": int(row[12]),
			"maxSize": int(row[13]),
			"forbidden": row[14],
			"sniffed": int(row[15]),
			"musicID": int(row[16]),
			"ambianceID": int(row[17]),
			"bgID": int(row[18]),
			"outDoor": int(row[19]),
			"maxMerchant": int(row[20])
		}
		
		_map_cache[map_data.id] = map_data
		count += 1
	
	file.close()
	print("[Database] Loaded %d maps from CSV" % count)


## Retrieve map data from cache using map_id as key
## Flow: map_id → raw map data dictionary
func get_map_data(map_id: int) -> Dictionary:
	if not _map_cache.has(map_id):
		push_error("[Database] MapHandler %d not found in cache" % map_id)
		print("[Database] Available map IDs: %s" % _map_cache.keys())
		return {}
	
	return _map_cache[map_id]
