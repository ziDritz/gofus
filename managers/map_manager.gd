# MapManager.gd
# AutoLoad singleton
# Orchestrates map loading by coordinating Database, Compressor, and Datacenter to build MapResource

extends Node

# =========================
# CONSTANTS
# =========================

const CELL_WIDTH: int = 53
const CELL_HALF_WIDTH: float = 26.5
const CELL_HEIGHT: int = 27  # Half-height for isometric
const CELL_HALF_HEIGHT: float = 13.5  # Half-height for isometric
const LEVEL_HEIGHT: int = 20  # Vertical offset per elevation level

const GROUND_TILES_PATH: String = "res://assets/graphics/gfx/grounds/"
const OBJECT_SPRITES_PATH: String = "res://assets/graphics/gfx/objects/"
const BACKGROUNDS_PATH: String = "res://assets/graphics/gfx/backgrounds/"

# =========================
# ASSET CACHE
# =========================

var _ground_tile_cache: Dictionary = {}
var _object_sprite_cache: Dictionary = {}
var _background_cache: Dictionary = {}

# =========================
# INITIALIZATION
# =========================

func _ready() -> void:
	print("[MapManager] Initializing...")
	print("[MapManager] Ready")

# =========================
# MAP LOADING
# =========================

## Orchestrate map loading process
## Flow: map_id → raw map dict → uncompressed cells → CellResource list → MapResource → Datacenter
func load_map(map_id: int) -> void:
	print("[MapManager] Loading map %d..." % map_id)
	
	# Step 1: Request map data from Database
	var map_data: Dictionary = Database.get_map_data(map_id)
	if map_data.is_empty():
		push_error("[MapManager] Failed to get map data for map %d" % map_id)
		return
	
	print("[MapManager] Map data loaded: width=%d, height=%d" % [map_data.width, map_data.height])
	
	# Step 2: Extract compressed cell_data from map dictionary
	var compressed_cell_data: String = map_data.mapData
	
	# Step 3: Call Compressor.uncompress() to get uncompressed cell data
	var uncompressed_data: String = Compressor.uncompress(compressed_cell_data)
	
	# Step 4: Parse uncompressed data and instantiate CellResource objects
	var cells: Array[CellResource] = _create_cells(uncompressed_data, map_data.width)
	if cells.is_empty():
		push_error("[MapManager] Failed to create cells for map %d" % map_id)
		return
	
	print("[MapManager] Created %d cells" % cells.size())
	
	# Step 5: Create MapResource with all cells and metadata
	var map_resource: MapResource = MapResource.new(
		map_id,
		map_data.width,
		map_data.height,
		cells
	)
	
	# Step 6: Send MapResource to Datacenter
	Datacenter.set_current_map(map_resource)
	
	print("[MapManager] Map %d loaded successfully" % map_id)

## Parse uncompressed cell data string and create CellResource array
## Flow: Uncompressed string → Array of CellResource objects
func _create_cells(uncompressed_data: String, map_width: int) -> Array[CellResource]:
	# Validate map data length
	if uncompressed_data.length() % 10 != 0:
		push_error("[MapManager] MapData length must be divisible by 10, got: %d" % uncompressed_data.length())
		return []
	
	var actual_cell_count: int = uncompressed_data.length() / 10
	print("[MapManager] Cell count: %d" % actual_cell_count)
	
	var cells: Array[CellResource] = []
	
	# Parse each cell
	for i in range(actual_cell_count):
		var start_pos: int = i * 10
		var cell_data: String = uncompressed_data.substr(start_pos, 10)
		
		# Use Compressor to parse cell data
		var cell_dict: Dictionary = Compressor.parse_cell(cell_data, i)
		if cell_dict.is_empty():
			push_error("[MapManager] Failed to parse cell %d" % i)
			return []
		
		# Calculate cell coordinates
		var coords: Vector2i = get_cell_coordinates(i, map_width)
		
		# Create CellResource from parsed data
		var cell_resource: CellResource = CellResource.new(
			i,  # cell_id
			coords.x,  # x
			coords.y,  # y
			cell_dict.walkable,  # walkable
			cell_dict.active,
			cell_dict.line_of_sight,
			cell_dict.ground_level,
			cell_dict.movement,
			cell_dict.ground_slope,
			cell_dict.layer_object2_num,
			cell_dict.layer_object2_interactive,
			cell_dict.object,
			cell_dict.layer_ground_num,
			cell_dict.layer_ground_rot,
			cell_dict.layer_ground_flip,
			cell_dict.layer_object1_num,
			cell_dict.layer_object1_rot,
			cell_dict.layer_object1_flip,
			cell_dict.layer_object2_flip,
			cell_dict.layer_object_external,
			cell_dict.layer_object_external_interactive,
			cell_dict.permanent_level,
			cell_dict.is_targetable,
			cell_dict.raw_data
		)
		
		cells.append(cell_resource)
	
	return cells

# =========================
# COORDINATE UTILITIES
# =========================

## Convert cell number to (x, y) coordinates
func get_cell_coordinates(cell_num: int, map_width: int) -> Vector2i:
	# Simple row-major layout: cells per row = map_width
	var row: int = floori(float(cell_num) / map_width)
	var col: int = cell_num % map_width
	return Vector2i(col, row)

## Convert (x, y) coordinates to cell number
func get_cell_number(x: int, y: int, map_width: int) -> int:
	return x * map_width + y * (map_width - 1)

## Calculate pixel position for a cell
func get_pixel_position(cell_num: int, map_width: int, ground_level: int) -> Vector2:
	var cell_width: int = CELL_WIDTH
	var half_width: float = CELL_HALF_WIDTH
	var half_height: float = CELL_HALF_HEIGHT
	
	var row: int = 0
	var col: int = -1
	var max_col: int = map_width - 1
	var x_offset: float = 0.0
	
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
	var x: float = col * cell_width + x_offset
	var y: float = row * half_height - LEVEL_HEIGHT * (ground_level - 7)
	
	return Vector2(x, y)

# =========================
# ASSET CACHING
# =========================

## Get ground tile texture (cached)
func get_ground_tile(tile_id: int) -> Texture2D:
	if tile_id == 0:
		return null
	if not _ground_tile_cache.has(tile_id):
		var path: String = GROUND_TILES_PATH + "%d.png" % tile_id
		if ResourceLoader.exists(path):
			_ground_tile_cache[tile_id] = load(path)
		else:
			push_warning("[MapManager] Ground tile not found: " + path)
			return null
	return _ground_tile_cache[tile_id]

## Get object sprite texture (cached)
func get_object_sprite(sprite_id: int) -> Texture2D:
	if sprite_id == 0:
		return null
	if not _object_sprite_cache.has(sprite_id):
		var path: String = OBJECT_SPRITES_PATH + "%d.png" % sprite_id
		if ResourceLoader.exists(path):
			_object_sprite_cache[sprite_id] = load(path)
		else:
			push_warning("[MapManager] Object sprite not found: " + path)
			return null
	return _object_sprite_cache[sprite_id]

## Get background texture (cached)
func get_background(bg_id: int) -> Texture2D:
	if bg_id == 0:
		return null
	if not _background_cache.has(bg_id):
		var path: String = BACKGROUNDS_PATH + "%d.png" % bg_id
		if ResourceLoader.exists(path):
			_background_cache[bg_id] = load(path)
		else:
			push_warning("[MapManager] Background not found: " + path)
			return null
	return _background_cache[bg_id]
