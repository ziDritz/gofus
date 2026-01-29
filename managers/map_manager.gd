# MapManager.gd (equivalent of ServerMapManager.as)
# AutoLoad singleton managing map loading, caching, and instantiation
# Orchestrates map building, layer rendering, cell updates, and tactic mode

extends Node

# =========================
# CONSTANTS
# =========================

const CELL_WIDTH : int = 53
const CELL_HALF_WIDTH : float = 26.5
const CELL_HEIGHT : int = 27  # Half-height for isometric
const CELL_HALF_HEIGHT : float = 13.5  # Half-height for isometric
const LEVEL_HEIGHT : int = 20  # Vertical offset per elevation level

const CSV_PATH : String = "res://database/maps_data.csv"
const GROUND_TILES_PATH : String = "res://assets/graphics/gfx/grounds/"
const OBJECT_SPRITES_PATH : String = "res://assets/graphics/gfx/objects/"
const BACKGROUNDS_PATH : String = "res://assets/graphics/gfx/backgrounds/"


# =========================
# CACHE
# =========================

var _ground_tile_cache: Dictionary = {}
var _object_sprite_cache: Dictionary = {}
var _background_cache: Dictionary = {}
var _map_data_cache: Dictionary = {}


# =========================
# STATE
# =========================

var current_map: Node2D = null
var map_parser: Node = null


# =========================
# INITIALIZATION
# =========================

func _ready():
	print("[MapManager] Initializing...")
	
	# Get reference to map parser
	map_parser = get_node_or_null("/root/MapParser")
	if not map_parser:
		push_error("[MapManager] MapParser not found in AutoLoad!")
		return
	
	print("[MapManager] MapParser found")
	
	# Load all map data from CSV
	_load_maps_csv()
	
	print("[MapManager] Ready")


# =========================
# CSV LOADING
# =========================

## Load maps data from CSV file
func _load_maps_csv() -> void:
	print("[MapManager] Loading CSV from: %s" % CSV_PATH)
	
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		push_error("[MapManager] Failed to open maps CSV: " + CSV_PATH)
		return
	
	# Read header
	var header := file.get_csv_line()
	print("[MapManager] CSV header: %s" % str(header))
	
	# Parse rows
	var count := 0
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 7:  # Skip empty/invalid rows
			continue
		
		var map_data := {
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
		
		_map_data_cache[map_data.id] = map_data
		count += 1
	
	file.close()
	print("[MapManager] Loaded %d maps from CSV" % count)
	if count > 0:
		print("[MapManager] First map ID: %d" % _map_data_cache.keys()[0])


# =========================
# MAP LOADING
# =========================

## Load and instantiate a map
func load_map(map_id: int) -> Node2D:
	print("[MapManager] Loading map %d..." % map_id)
	
	if not _map_data_cache.has(map_id):
		push_error("[MapManager] Map %d not found in CSV data" % map_id)
		print("[MapManager] Available map IDs: %s" % _map_data_cache.keys())
		return null
	
	var map_data : Dictionary = _map_data_cache[map_id]
	print("[MapManager] Map data loaded: width=%d, height=%d" % [map_data.width, map_data.height])
	
	# Parse cell data
	var cells : Array = map_parser.parse_map(
		map_data.id,
		map_data.width,
		map_data.height,
		map_data.mapData
	)
	
	if cells.is_empty():
		push_error("[MapManager] Failed to parse map %d" % map_id)
		return null
	
	print("[MapManager] Parsed %d cells" % cells.size())
	
	# Create Map scene
	var map_scene : PackedScene = preload("res://graphics/battlefield/Map.tscn")
	var map : Node2D = map_scene.instantiate()
	
	print("[MapManager] Map scene instantiated")
	
	# Initialize map
	map.initialize(map_data, cells)
	
	# Set as current map
	if current_map:
		current_map.queue_free()
	current_map = map
	
	print("[MapManager] Map %d loaded successfully" % map_id)
	return map


# =========================
# ASSET CACHING
# =========================

## Get ground tile texture (cached)
func get_ground_tile(tile_id: int) -> Texture2D:
	if tile_id == 0:
		return null
	
	if not _ground_tile_cache.has(tile_id):
		var path := GROUND_TILES_PATH + "%d.png" % tile_id
		if ResourceLoader.exists(path):
			_ground_tile_cache[tile_id] = load(path)
		else:
			push_warning("Ground tile not found: " + path)
			return null
	
	return _ground_tile_cache[tile_id]


## Get object sprite texture (cached)
func get_object_sprite(sprite_id: int) -> Texture2D:
	if sprite_id == 0:
		return null
	
	if not _object_sprite_cache.has(sprite_id):
		var path := OBJECT_SPRITES_PATH + "%d.png" % sprite_id
		if ResourceLoader.exists(path):
			_object_sprite_cache[sprite_id] = load(path)
		else:
			push_warning("Object sprite not found: " + path)
			return null
	
	return _object_sprite_cache[sprite_id]


## Get background texture (cached)
func get_background(bg_id: int) -> Texture2D:
	if bg_id == 0:
		return null
	
	if not _background_cache.has(bg_id):
		var path := BACKGROUNDS_PATH + "%d.png" % bg_id
		if ResourceLoader.exists(path):
			_background_cache[bg_id] = load(path)
		else:
			push_warning("Background not found: " + path)
			return null
	
	return _background_cache[bg_id]


# =========================
# COORDINATE UTILITIES
# =========================

## Convert cell number to (x, y) coordinates
func get_cell_coordinates(cell_num: int, map_width: int) -> Vector2i:
	# Simple row-major layout: cells per row = map_width
	var row : int = floori(float(cell_num) / map_width)
	var col : int = cell_num % map_width
	return Vector2i(col, row)


## Convert (x, y) coordinates to cell number
func get_cell_number(x: int, y: int, map_width: int) -> int:
	return x * map_width + y * (map_width - 1)


func get_pixel_position(cell_num: int, map_width: int, ground_level: int) -> Vector2:
	var cell_width := CELL_WIDTH
	var half_width := CELL_HALF_WIDTH
	var half_height := CELL_HALF_HEIGHT

	var row := 0
	var col := -1
	var max_col := map_width - 1
	var x_offset := 0.0

	# Reproduce Flash iteration logic to reach cell_num
	for i in range(cell_num):
		if col == max_col:
			col = 0
			row += 1

			if x_offset == 0.0:
				x_offset = half_width
				max_col -= 1
			else:
				x_offset = 0.0
				max_col += 1
		else:
			col += 1

	# Compute final pixel position
	var x := col * cell_width + x_offset
	var y := row * half_height - LEVEL_HEIGHT * (ground_level - 7)

	return Vector2(x, y)
