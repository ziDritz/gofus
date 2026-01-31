# Database.gd
# AutoLoad singleton
# Handles map data persistence and provides quick access to map data

extends Node

# =========================
# CONSTANTS
# =========================

const CSV_PATH := "res://database/maps_data.csv"

# =========================
# CACHE
# =========================

## Stores all loaded map data indexed by map_id for quick lookup
var _map_cache: Dictionary = {}

# =========================
# INITIALIZATION
# =========================

func _ready() -> void:
	print("[Database] Initializing...")
	load_all_maps()
	print("[Database] Ready")

# =========================
# MAP DATA LOADING
# =========================

## Load all map data from CSV file
## Flow: CSV file → Dictionary of map dictionaries
func load_all_maps() -> void:
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
		if row.size() < 7:  # Skip empty/invalid rows
			continue
		
		var map_data: Dictionary = {
			"id": int(row[0]),
			"date": row[1],
			"width": int(row[2]),
			"height": int(row[3]),
			"places": row[4],
			"key": row[5],
			"mapData": row[6],
			"monsters": row[7] if row.size() > 7 else "",
			"capabilities": int(row[8]) if row.size() > 8 else 0,
			"mappos": row[9] if row.size() > 9 else "",
			"numgroup": int(row[10]) if row.size() > 10 else 0,
			"minSize": int(row[11]) if row.size() > 11 else 0,
			"fixSize": int(row[12]) if row.size() > 12 else 0,
			"maxSize": int(row[13]) if row.size() > 13 else 0,
			"forbidden": row[14] if row.size() > 14 else "",
			"sniffed": int(row[15]) if row.size() > 15 else 0,
			"musicID": int(row[16]) if row.size() > 16 else 0,
			"ambianceID": int(row[17]) if row.size() > 17 else 0,
			"bgID": int(row[18]) if row.size() > 18 else 0,
			"outDoor": int(row[19]) if row.size() > 19 else 0,
			"maxMerchant": int(row[20]) if row.size() > 20 else 0
		}
		
		_map_cache[map_data.id] = map_data
		count += 1
	
	file.close()
	print("[Database] Loaded %d maps from CSV" % count)
	if count > 0:
		print("[Database] First map ID: %d" % _map_cache.keys()[0])

## Retrieve map data from cache using map_id as key
## Flow: map_id → raw map data dictionary
func get_map_data(map_id: int) -> Dictionary:
	if not _map_cache.has(map_id):
		push_error("[Database] Map %d not found in cache" % map_id)
		print("[Database] Available map IDs: %s" % _map_cache.keys())
		return {}
	
	return _map_cache[map_id]
