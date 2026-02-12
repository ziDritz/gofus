# MapHandler.gd
# Equivalent of MapHandler.as
# Node representing a complete map with all visual layers
  
extends Node2D
class_name MapHandler
  
  
var loader_handler: LoaderHandler

# Sprite metadata
var ground_metadata: Dictionary[int, Dictionary] = {}
var object_bounds: Dictionary[int, Dictionary] = {}

# Layers
var background: Sprite2D
var ground_layer: Node2D
var object1_layer: Node2D
var object2_layer: Node2D
var interaction_layer: Node2D
var cell_ids_layer: Node2D
# Object pools - arrays of reusable nodes
var _ground_sprite_pool: Array[Sprite2D] = []
var _object1_sprite_pool: Array[Sprite2D] = []
var _object2_sprite_pool: Array[Sprite2D] = []
var _label_pool: Array[Label] = []
# Pool usage indices (how many from each pool are currently in use)
var _ground_pool_index: int = 0
var _object1_pool_index: int = 0
var _object2_pool_index: int = 0
var _label_pool_index: int = 0
  
  
func _ready() -> void:
	# Get node references
	background = get_node_or_null("Background")
	ground_layer = get_node_or_null("GroundLayer")
	object1_layer = get_node_or_null("Object1Layer")
	object2_layer = get_node_or_null("Object2Layer")
	interaction_layer = get_node_or_null("InteractionLayer")
	cell_ids_layer = get_node_or_null("CellIDSLayer")
  
	background.centered = false

	# Loading ground JSON files data
	var ground_metadata_json = FileAccess.open(Battlefield.G_METADATAS_JSON_PATH, FileAccess.READ)
	if ground_metadata_json:
		var json: JSON = JSON.new()
		var error = json.parse(ground_metadata_json.get_as_text())
		if error == OK:
			var data: Dictionary = json.data
			for d in data:
				var ground_id: int = int(d)
				var entry = data[d]
				ground_metadata[ground_id] = {
					"frame_count": int(entry["frame_count"]),
					"horizontal": int(entry["horizontal"]),
					"vertical": int(entry["vertical"])
				}
		else:
			print("Error parsing JSON: ", json.get_error_message())
		ground_metadata_json.close()
	else:
		print("Error opening ground_metadata_json: ", Battlefield.G_METADATAS_JSON_PATH)

	# Loading object bounds JSON file data
	var object_bounds_json = FileAccess.open(Battlefield.O_BOUNDS_JSON_PATH, FileAccess.READ)
	if object_bounds_json:
		var json: JSON = JSON.new()
		var error = json.parse(object_bounds_json.get_as_text()) 
		if error == OK: 
			var data: Dictionary = json.data 
			for d in data: 
				var object_id: int = int(d) 
				var entry = data[d] 
				object_bounds[object_id] = { 
					"horizontal": int(entry["horizontal"]), 
					"vertical": int(entry["vertical"]) 
				} 
		else:
			print("Error parsing JSON: ", json.get_error_message()) 
		object_bounds_json.close() 
	else: print("Error opening object_bounds_json: ", Battlefield.O_BOUNDS_JSON_PATH)
  
  
## Initialize map with MapResource
func initialize(_loader_handler: LoaderHandler) -> void:
	loader_handler = _loader_handler
## Get or create a sprite from the ground pool
func _get_ground_sprite2D() -> Sprite2D:
	if _ground_pool_index < _ground_sprite_pool.size():
		var sprite: Sprite2D = _ground_sprite_pool[_ground_pool_index]
		_ground_pool_index += 1
		sprite.rotation_degrees = 0.0  # Reset rotation
		sprite.scale = Vector2.ONE  # Reset scale
		sprite.frame = 0  # Reset frame
		sprite.visible = true
		return sprite
	else:
		# Pool exhausted, create new sprite
		print("[PERF] Creating new ground sprite - pool size: ", _ground_sprite_pool.size())
		var sprite: Sprite2D = Sprite2D.new()
		sprite.centered = false
		ground_layer.add_child(sprite)
		_ground_sprite_pool.append(sprite)
		_ground_pool_index += 1
		return sprite
## Get or create a sprite from the object1 pool
func _get_object1_sprite2D() -> Sprite2D:
	if _object1_pool_index < _object1_sprite_pool.size():
		var sprite: Sprite2D = _object1_sprite_pool[_object1_pool_index]
		_object1_pool_index += 1
		sprite.rotation_degrees = 0.0  # Reset rotation
		sprite.scale = Vector2.ONE  # Reset scale
		sprite.frame = 0  # Reset frame
		sprite.visible = true
		return sprite
	else:
		print("[PERF] Creating new object1 sprite - pool size: ", _object1_sprite_pool.size())
		var sprite: Sprite2D = Sprite2D.new()
		sprite.centered = false
		object1_layer.add_child(sprite)
		_object1_sprite_pool.append(sprite)
		_object1_pool_index += 1
		return sprite
## Get or create a sprite from the object2 pool
func _get_object2_sprite2D() -> Sprite2D:
	if _object2_pool_index < _object2_sprite_pool.size():
		var sprite: Sprite2D = _object2_sprite_pool[_object2_pool_index]
		_object2_pool_index += 1
		sprite.rotation_degrees = 0.0  # Reset rotation
		sprite.scale = Vector2.ONE  # Reset scale
		sprite.frame = 0  # Reset frame
		sprite.visible = true
		return sprite
	else:
		print("[PERF] Creating new object2 sprite - pool size: ", _object2_sprite_pool.size())
		var sprite: Sprite2D = Sprite2D.new()
		sprite.centered = false
		object2_layer.add_child(sprite)
		_object2_sprite_pool.append(sprite)
		_object2_pool_index += 1
		return sprite
## Get or create a label from the label pool
func _get_cell_id_label() -> Label:
	if _label_pool_index < _label_pool.size():
		var label: Label = _label_pool[_label_pool_index]
		_label_pool_index += 1
		label.visible = true
		return label
	else:
		print("[PERF] Creating new label - pool size: ", _label_pool.size())
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
		cell_ids_layer.add_child(label)
		_label_pool.append(label)
		_label_pool_index += 1
		return label
## Reset all pools for reuse (called before build_map)
func _reset_pools() -> void:
	var start_time := Time.get_ticks_usec()
	
	# Hide all pooled sprites beyond the current usage
	for i in range(_ground_sprite_pool.size()):
		_ground_sprite_pool[i].visible = false
	
	for i in range(_object1_sprite_pool.size()):
		_object1_sprite_pool[i].visible = false
	
	for i in range(_object2_sprite_pool.size()):
		_object2_sprite_pool[i].visible = false
	
	for i in range(_label_pool.size()):
		_label_pool[i].visible = false
	
	# Reset indices to start from beginning
	_ground_pool_index = 0
	_object1_pool_index = 0
	_object2_pool_index = 0
	_label_pool_index = 0
	
	var elapsed := Time.get_ticks_usec() - start_time
	print("[PERF] Pool reset took: ", elapsed, " µs (", elapsed / 1000.0, " ms)")
	print("[PERF] Pool sizes - Ground: ", _ground_sprite_pool.size(), 
		  " | Obj1: ", _object1_sprite_pool.size(), 
		  " | Obj2: ", _object2_sprite_pool.size(), 
		  " | Labels: ", _label_pool.size())
## Build full visual representation of the map
func build_map(map_resource: MapResource) -> void:
	var build_start_time := Time.get_ticks_usec()
	print("[PERF] ===== Starting map build =====")
	print("[PERF] Map size: ", map_resource.width, "x", map_resource.cells.size() / map_resource.width, " (", map_resource.cells.size(), " cells)")
	
	# Reset pools before building
	_reset_pools()
	
	var cell_width: int = Battlefield.CELL_WIDTH
	var cell_half_width: float = Battlefield.CELL_HALF_WIDTH
	var cell_half_height: float = Battlefield.CELL_HALF_HEIGHT
	var level_height: int = Battlefield.LEVEL_HEIGHT
  
	var col: int = -1
	var row: int = 0
	var x_offset: float = 0
  
	var cell_resources: Array[CellResource] = map_resource.cells
	var cell_count: int = cell_resources.size()
	var max_col: int = map_resource.width - 1
	
	# Counters for statistics
	var active_cells: int = 0
	var ground_tiles: int = 0
	var object1_tiles: int = 0
	var object2_tiles: int = 0
	
	# Timing accumulators
	var total_json_time: int = 0
	var total_texture_time: int = 0
	var total_bounds_time: int = 0
	var total_label_time: int = 0
  
	# Background
	var bg_start := Time.get_ticks_usec()
	if background != null and map_resource.background_id != 0:
		background.texture = loader_handler.get_background_texture(map_resource.background_id)
	var bg_elapsed := Time.get_ticks_usec() - bg_start
	print("[PERF] Background setup: ", bg_elapsed, " µs")
  
	# Cell loop
	var loop_start := Time.get_ticks_usec()
	var cell_id: int = -1
	while cell_id + 1 < cell_count:
		cell_id += 1
  
		# Grid positioning (isometric logic)
		if col == max_col:
			col = 0
			row += 1
  
			if x_offset == 0:
				x_offset = cell_half_width
				max_col -= 1
			else:
				x_offset = 0
				max_col += 1
		else:
			col += 1
  
		var cell_resource: CellResource = cell_resources[cell_id]
  
		if not cell_resource.active:
			continue
		
		active_cells += 1
  
		var cell_x: float = col * cell_width + x_offset
		var cell_y: float = row * cell_half_height \
			- level_height * (cell_resource.ground_level - 7)
  
		var cell_position: Vector2 = Vector2(cell_x, cell_y)
  
		# Ground layer
		if cell_resource.layer_ground_num != 0:
			ground_tiles += 1
			var ground_sprite: Sprite2D = _get_ground_sprite2D()
			
			var json_start := Time.get_ticks_usec()
			ground_sprite.hframes = ground_metadata[cell_resource.layer_ground_num]["frame_count"]
			var json_elapsed := Time.get_ticks_usec() - json_start
			total_json_time += json_elapsed
			
			var texture_start := Time.get_ticks_usec()
			ground_sprite.texture = loader_handler.get_ground_tile_texture(cell_resource.layer_ground_num)
			var texture_elapsed := Time.get_ticks_usec() - texture_start
			total_texture_time += texture_elapsed
			
			var bounds_start := Time.get_ticks_usec()
			var bounds: Vector2 = Vector2(
				ground_metadata[cell_resource.layer_ground_num]["horizontal"],
				ground_metadata[cell_resource.layer_ground_num]["vertical"]
			)
			var bounds_elapsed := Time.get_ticks_usec() - bounds_start
			total_bounds_time += bounds_elapsed
			
			ground_sprite.offset = bounds
			ground_sprite.position = cell_position
  
			if cell_resource.ground_slope != 1:
				ground_sprite.frame = cell_resource.ground_slope - 1
			elif cell_resource.layer_ground_rot != 0:
				ground_sprite.rotation_degrees = float(cell_resource.layer_ground_rot * 90)
				if int(ground_sprite.rotation_degrees) % 180 != 0:
					ground_sprite.scale = Vector2(0.5185, 1.9286)
  
			if cell_resource.layer_ground_flip:
				ground_sprite.scale.x *= -1.0
			
			if ground_tiles == 1:  # Only print first tile details
				print("[PERF-DETAIL] First ground tile - JSON frame: ", json_elapsed, "µs | Texture: ", texture_elapsed, "µs | JSON bounds: ", bounds_elapsed, "µs")
  
		# Object layer 1
		if cell_resource.layer_object1_num != 0:
			object1_tiles += 1
			var obj1_sprite_start := Time.get_ticks_usec()
			var object1_sprite: Sprite2D = _get_object1_sprite2D()
			var obj1_sprite_elapsed := Time.get_ticks_usec() - obj1_sprite_start
			
			# Reset sprite properties
			object1_sprite.hframes = 1  # Reset frame count
			
			var obj1_texture_start := Time.get_ticks_usec()
			object1_sprite.texture = loader_handler.get_object_sprite_texture(cell_resource.layer_object1_num)
			var obj1_texture_elapsed := Time.get_ticks_usec() - obj1_texture_start
			total_texture_time += obj1_texture_elapsed
			
			var obj1_bounds_start := Time.get_ticks_usec()
			var bounds: Vector2 = Vector2(
				object_bounds[cell_resource.layer_object1_num]["horizontal"],
				object_bounds[cell_resource.layer_object1_num]["vertical"]
			)
			var obj1_bounds_elapsed := Time.get_ticks_usec() - obj1_bounds_start
			total_bounds_time += obj1_bounds_elapsed
			
			object1_sprite.offset = bounds
			object1_sprite.position = cell_position
  
			if cell_resource.ground_slope == 1 and cell_resource.layer_object1_rot != 0:
				object1_sprite.rotation_degrees = float(cell_resource.layer_object1_rot * 90)
				if int(object1_sprite.rotation_degrees) % 180 != 0:
					object1_sprite.scale = Vector2(0.5185, 1.9286)
  
			if cell_resource.layer_object1_flip:
				object1_sprite.scale.x *= -1.0
			
			if object1_tiles == 1:  # Only print first tile details
				print("[PERF-DETAIL] First obj1 tile - Get sprite: ", obj1_sprite_elapsed, "µs | Texture: ", obj1_texture_elapsed, "µs | JSON bounds: ", obj1_bounds_elapsed, "µs")
  
		# Object layer 2 (top)
		if cell_resource.layer_object2_num != 0:
			object2_tiles += 1
			var obj2_sprite_start := Time.get_ticks_usec()
			var object2_sprite: Sprite2D = _get_object2_sprite2D()
			var obj2_sprite_elapsed := Time.get_ticks_usec() - obj2_sprite_start
			
			# Reset sprite properties
			object2_sprite.hframes = 1  # Reset frame count
			
			var obj2_texture_start := Time.get_ticks_usec()
			object2_sprite.texture = loader_handler.get_object_sprite_texture(cell_resource.layer_object2_num)
			var obj2_texture_elapsed := Time.get_ticks_usec() - obj2_texture_start
			total_texture_time += obj2_texture_elapsed
			
			var obj2_bounds_start := Time.get_ticks_usec()
			var bounds: Vector2 = Vector2(
				object_bounds[cell_resource.layer_object2_num]["horizontal"],
				object_bounds[cell_resource.layer_object2_num]["vertical"]
			)
			var obj2_bounds_elapsed := Time.get_ticks_usec() - obj2_bounds_start
			total_bounds_time += obj2_bounds_elapsed
			
			object2_sprite.offset = bounds
			object2_sprite.position = cell_position
  
			if cell_resource.layer_object2_flip:
				object2_sprite.scale.x = -1.0
			
			if object2_tiles == 1:  # Only print first tile details
				print("[PERF-DETAIL] First obj2 tile - Get sprite: ", obj2_sprite_elapsed, "µs | Texture: ", obj2_texture_elapsed, "µs | JSON bounds: ", obj2_bounds_elapsed, "µs")
  
		# Cell ID label
		var label_start := Time.get_ticks_usec()
		var cell_id_label: Label = _get_cell_id_label()
		var label_get_elapsed := Time.get_ticks_usec() - label_start
		
		var label_setup_start := Time.get_ticks_usec()
		cell_id_label.text = str(cell_id)
		cell_id_label.position = cell_position
		cell_id_label.position.x -= 10  # Approximate centering offset
		cell_id_label.position.y -= 6
		var label_setup_elapsed := Time.get_ticks_usec() - label_setup_start
		total_label_time += label_get_elapsed + label_setup_elapsed
		
		if active_cells == 1:  # Only print first label details
			print("[PERF-DETAIL] First label - Get label: ", label_get_elapsed, "µs | Setup: ", label_setup_elapsed, "µs")
	
	var loop_elapsed := Time.get_ticks_usec() - loop_start
	var build_total := Time.get_ticks_usec() - build_start_time
	
	print("[PERF] Cell loop took: ", loop_elapsed, " µs (", loop_elapsed / 1000.0, " ms)")
	print("[PERF] Active cells: ", active_cells, " | Ground: ", ground_tiles, " | Obj1: ", object1_tiles, " | Obj2: ", object2_tiles, " | Labels: ", active_cells)
	print("[PERF] Pool reuse - Ground: ", _ground_pool_index - ground_tiles, 
		  " | Obj1: ", _object1_pool_index - object1_tiles, 
		  " | Obj2: ", _object2_pool_index - object2_tiles)
	
	# Detailed timing breakdown
	print("[PERF] ===== TIMING BREAKDOWN =====")
	print("[PERF] Total JSON lookups:    ", total_json_time, " µs (", total_json_time / 1000.0, " ms) - ", (total_json_time * 100.0 / loop_elapsed), "%")
	print("[PERF] Total texture loading: ", total_texture_time, " µs (", total_texture_time / 1000.0, " ms) - ", (total_texture_time * 100.0 / loop_elapsed), "%")
	print("[PERF] Total bounds lookups:  ", total_bounds_time, " µs (", total_bounds_time / 1000.0, " ms) - ", (total_bounds_time * 100.0 / loop_elapsed), "%")
	print("[PERF] Total label creation:  ", total_label_time, " µs (", total_label_time / 1000.0, " ms) - ", (total_label_time * 100.0 / loop_elapsed), "%")
	var accounted_time := total_json_time + total_texture_time + total_bounds_time + total_label_time
	var other_time := loop_elapsed - accounted_time
	print("[PERF] Other operations:      ", other_time, " µs (", other_time / 1000.0, " ms) - ", (other_time * 100.0 / loop_elapsed), "%")
	print("[PERF] ===========================")
	
	print("[PERF] TOTAL build_map time: ", build_total, " µs (", build_total / 1000.0, " ms)")
	print("[PERF] ===== Map build complete =====")

# =========================
# DISPLAY METHODS
# =========================

## Toggle visibility of cell ID labels
func display_cell_ids() -> void:
	if cell_ids_layer:
		cell_ids_layer.visible = not cell_ids_layer.visible
	


