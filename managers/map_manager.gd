# MapManager.gd
# AutoLoad singleton
# Orchestrates map loading by coordinating Database, Compressor, and Datacenter to build MapResource
extends Node


func _ready() -> void:
	print("[MapManager] Ready")


## Orchestrate map loading process
## Flow: map_id → raw map dict → uncompressed cells → CellResource list → MapResource → Datacenter
func load_map(map_id: int) -> void:
	print("[MapManager] Loading map %d..." % map_id)


	# Step 1: Request map data from Database
	var map_data: Dictionary = Database.get_map_data(map_id)
	if map_data.is_empty():
		push_error("[MapManager] Failed to get map data for map %d" % map_id)
		return


	# Step 2: Parse uncompressed data and instantiate CellResource objects
	var compressed_cell_data: String = map_data.mapData

	# Validate map data length
	if compressed_cell_data.length() % 10 != 0:
		push_error("[MapManager] MapData length must be divisible by 10, got: %d" % compressed_cell_data.length())
		return
	
	var actual_cell_count: int = compressed_cell_data.length() / 10
	var cell_resources: Array[CellResource] = []
	cell_resources.resize(actual_cell_count)

	# Parse each cell
	for i in range(actual_cell_count):
		var start_pos: int = i * 10
		var cell_data: String = compressed_cell_data.substr(start_pos, 10)
		
		# Use Compressor to parse cell data
		var cell_dict: Dictionary = Compressor.uncompress_cell_data(cell_data, i)
		if cell_dict.is_empty():
			push_error("[MapManager] Failed to parse cell %d" % i)
			return
		
		# Calculate cell coordinates
		var coords: Vector2i = get_cell_grid_coordinates(i, map_data.width)
		
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
		
		cell_resources[i] = cell_resource
	
	
	# Step 3: Create MapResource with all cells and metadata
	var map_resource: MapResource = MapResource.new(
		map_id,
		map_data.width,
		map_data.height,
		cell_resources,
		map_data.bgID
	)
	
	print("[MapManager] MapHandler resource initialized: width=%d, height=%d, bgID=%d, cell count=%d" % [map_data.width, map_data.height, map_data.bgID, actual_cell_count])

	# Step 4: Send MapResource to Datacenter
	Datacenter.set_current_map(map_resource)

	# Step 5: Call map building
	Battlefield.build_map(map_resource)





# =========================
# COORDINATE UTILITIES
# =========================
## Convert cell number to (x, y) grid coordinates
func get_cell_grid_coordinates(cell_id: int, map_width: int) -> Vector2i:
	# Simple row-major layout: cells per row = map_width
	var row: int = floori(float(cell_id) / map_width)
	var col: int = cell_id % map_width
	return Vector2i(col, row)

## Convert (x, y) coordinates to cell number
func get_cell_number(x: int, y: int, map_width: int) -> int:
	return x * map_width + y * (map_width - 1)

## Calculate pixel position for a cell
func get_pixel_position(cell_num: int, map_width: int, ground_level: int) -> Vector2:
	var cell_width: int = Battlefield.CELL_WIDTH
	var half_width: float = Battlefield.CELL_HALF_WIDTH
	var half_height: float = Battlefield.CELL_HALF_HEIGHT
	
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
	var y: float = row * half_height - Battlefield.LEVEL_HEIGHT * (ground_level - 7)
	
	return Vector2(x, y)