# Map.gd, equivalent of MalHandler.as
# Node representing a complete map with all visual layers
  
class_name Map
extends Node2D
  
# =========================
# PROPERTIES
# =========================

var loader_handler: LoaderHandler  
var map_resource: MapResource = null
var cells_dict: Dictionary = {}  # Quick lookup: cell_id -> CellResource
  
# =========================
# NODES
# =========================
  
var background: Sprite2D
var ground_layer: Node2D
var object1_layer: Node2D
var object2_layer: Node2D
  
  
# =========================
# INITIALIZATION
# =========================
  
func _ready():
	# Get node references
	background = get_node_or_null("Background")
	ground_layer = get_node_or_null("GroundLayer")
	object1_layer = get_node_or_null("Object1Layer")
	object2_layer = get_node_or_null("Object2Layer")
	
	# Verify nodes exist
	if not background:
		push_error("[Map] Background node not found!")
	if not ground_layer:
		push_error("[Map] GroundLayer node not found!")
	if not object1_layer:
		push_error("[Map] Object1Layer node not found!")
	if not object2_layer:
		push_error("[Map] Object2Layer node not found!")
	
  
  
## Initialize map with MapResource
func initialize(p_map_resource: MapResource, p_loader_handler: LoaderHandler) -> void:

	loader_handler = p_loader_handler
	map_resource = p_map_resource
	
	# Build quick lookup dictionary
	cells_dict.clear()
	for cell in map_resource.cells:
		cells_dict[cell.cell_id] = cell
	
	print("[Map] Map %d initialized with %d cells" % [map_resource.map_id, map_resource.cells.size()])
	
	# Build visual representation
	_build()
  
  
# =========================
# MAP BUILDING
# =========================
  
## Build all visual layers
func _build() -> void:
	print("[Map] Building map %d..." % map_resource.map_id)
	
	# Build background
	var bg_texture : Texture2D = loader_handler.get_background_texture(map_resource.background_id)
	if bg_texture:
		background.texture = bg_texture
		background.centered = false
		print("[Map]   Background: %d" % map_resource.background_id)
	else:
		push_warning("[Map] No background texture for ID: %d" % map_resource.background_id)

	# _build_ground_layer
	_build_ground_layer()

	# _build_object1_layer
	_build_object1_layer()
	
	# build_object2_layer
	_build_object2_layer()
	print("[Map] Map %d built successfully" % map_resource.map_id)
  
  
  
## Build ground layer (all ground tiles)
func _build_ground_layer() -> void:
	var tile_count : int = 0
	for cell in map_resource.cells:
		if cell.layer_ground_num == 0:
			continue
		
		# Get ground tile texture
		var tile_texture : Texture2D = loader_handler.get_ground_tile_texture(cell.layer_ground_num)
		if not tile_texture:
			continue
		
		# Create sprite for this ground tile
		var sprite : Sprite2D = Sprite2D.new()
		sprite.texture = tile_texture
		sprite.name = "Ground_%d" % cell.cell_id
		
		# Position
		sprite.position = MapManager.get_pixel_position(
			cell.cell_id,
			map_resource.width,
			cell.ground_level
		)
		
		# Apply transformations
		if cell.ground_slope == 1 and cell.layer_ground_rot != 0:
			sprite.rotation_degrees = cell.layer_ground_rot * 90.0
			if int(sprite.rotation_degrees) % 180 != 0:
				sprite.scale = Vector2(0.52, 1.93)
		else:
			sprite.rotation = 0
			sprite.scale = Vector2.ONE
		
		sprite.flip_h = cell.layer_ground_flip
		
		# TODO: Handle ground_slope (multi-frame animation)
		ground_layer.add_child(sprite)
		tile_count += 1
	
	print("[Map]   Ground tiles: %d" % tile_count)
	print("Cell 0 pos: ", MapManager.get_pixel_position(0, map_resource.width, 7))
	print("Cell 1 pos: ", MapManager.get_pixel_position(1, map_resource.width, 7))
  
  
## Build object layer 1 (decorations)
func _build_object1_layer() -> void:
	if not object1_layer:
		push_warning("[Map] Object1Layer node missing, skipping")
		return
  
	var object_count: int = 0
  
	for cell in map_resource.cells:
		var node_name := "Cell_%d" % cell.cell_id
  
		# --------------------------------------------------
		# No object → remove existing sprite
		# --------------------------------------------------
		if cell.layer_object1_num == 0:
			var old_obj := object1_layer.get_node_or_null(node_name)
			if old_obj:
				old_obj.queue_free()
			continue
  
		# --------------------------------------------------
		# Get or create sprite
		# --------------------------------------------------
		var sprite := object1_layer.get_node_or_null(node_name) as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = node_name
			object1_layer.add_child(sprite)
  
		# --------------------------------------------------
		# Assign texture
		# --------------------------------------------------
		var obj_texture: Texture2D = loader_handler.get_object_sprite_texture(cell.layer_object1_num)
		if not obj_texture:
			continue
  
		sprite.texture = obj_texture
  
		# --------------------------------------------------
		# Position (same as Flash nCellX / nCellY)
		# --------------------------------------------------
		sprite.position = MapManager.get_pixel_position(
			cell.cell_id,
			map_resource.width,
			cell.ground_level
		)
  
		# --------------------------------------------------
		# Rotation + scale (Flash parity)
		# --------------------------------------------------
		if cell.ground_slope == 1 and cell.layer_object1_rot != 0:
			sprite.rotation_degrees = cell.layer_object1_rot * 90.0
  
			if int(sprite.rotation_degrees) % 180 != 0:
				sprite.scale = Vector2(0.5185, 1.9286)
			else:
				sprite.scale = Vector2.ONE
		else:
			sprite.rotation = 0.0
			sprite.scale = Vector2.ONE
  
		# --------------------------------------------------
		# Horizontal flip
		# --------------------------------------------------
		sprite.flip_h = cell.layer_object1_flip
  
		# --------------------------------------------------
		# Store reference (mcObject1 equivalent)
		# --------------------------------------------------
		object_count += 1
  
	print("[Map]   Object1 sprites: %d" % object_count)
  
  
  
## Build object layer 2 (interactive objects)
func _build_object2_layer() -> void:
	if not object2_layer:
		push_warning("[Map] Object2Layer node missing, skipping")
		return
  
	var object_count: int = 0
  
	for cell in map_resource.cells:
		var node_name := "Cell_%d" % cell.cell_id
  
		# --------------------------------------------------
		# No object → remove existing node
		# --------------------------------------------------
		if cell.layer_object2_num == 0:
			var old_obj := object2_layer.get_node_or_null(node_name)
			if old_obj:
				old_obj.queue_free()
			continue
  
		# --------------------------------------------------
		# Get or create base node
		# --------------------------------------------------
		var sprite := object2_layer.get_node_or_null(node_name) as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = node_name
			sprite.z_index = cell.cell_id * 100
			object2_layer.add_child(sprite)
  
		# --------------------------------------------------
		# Assign texture
		# --------------------------------------------------
		var obj_texture: Texture2D = loader_handler.get_object_sprite_texture(cell.layer_object2_num)
		if not obj_texture:
			# Flash behavior: invalidate object
			cell.layer_object2_num = 0
			sprite.queue_free()
			continue
  
		sprite.texture = obj_texture
  
		# --------------------------------------------------
		# Position (same as Flash nCellX / nCellY)
		# --------------------------------------------------
		# Assuming the texture is loaded and the sprite's size is (width, height)
		var texture_size = obj_texture.get_size()
		# Set the offset to move the origin to the bottom center
		var offset = Vector2(texture_size.x / 2, texture_size.y)
		sprite.position = MapManager.get_pixel_position(
			cell.cell_id,
			map_resource.width,
			cell.ground_level
		)
  
		# --------------------------------------------------
		# Horizontal flip
		# --------------------------------------------------
		sprite.flip_h = cell.layer_object2_flip
  
		object_count += 1
  
	print("[Map]   Object2 sprites: %d" % object_count)
  
  
  
# =========================
# CELL QUERIES
# =========================
  
## Get cell by cell_id
func get_cell(cell_id: int) -> CellResource:
	return cells_dict.get(cell_id, null)
  
  
## Get cell at coordinates
func get_cell_at_coords(x: int, y: int) -> CellResource:
	var cell_num := MapManager.get_cell_number(x, y, map_resource.width)
	return get_cell(cell_num)
  

## Get map ID (convenience accessor)
func get_map_id() -> int:
	return map_resource.map_id if map_resource else 0


## Get map width (convenience accessor)
func get_width() -> int:
	return map_resource.width if map_resource else 0


## Get map height (convenience accessor)
func get_height() -> int:
	return map_resource.height if map_resource else 0