# Map.gd
# Equivalent of MapHandler.as
# Node representing a complete map with all visual layers

extends Node2D
class_name Map

# =========================
# PROPERTIES
# =========================

var loader_handler: LoaderHandler
var map_resource: MapResource

# =========================
# NODES
# =========================

var background: Sprite2D
var ground_layer: Node2D
var object1_layer: Node2D
var object2_layer: Node2D
var interaction_layer: Node2D
var cell_ids_layer: Node2D

# =========================
# INITIALIZATION
# =========================

func _ready() -> void:
	# Get node references
	background = get_node_or_null("Background")
	ground_layer = get_node_or_null("GroundLayer")
	object1_layer = get_node_or_null("Object1Layer")
	object2_layer = get_node_or_null("Object2Layer")
	interaction_layer = get_node_or_null("InteractionLayer")
	cell_ids_layer = get_node_or_null("CellIDSLayer")

	background.centered = false


## Initialize map with MapResource
func initialize(p_map_resource: MapResource, p_loader_handler: LoaderHandler) -> void:
	loader_handler = p_loader_handler
	map_resource = p_map_resource
	_build()


# =========================
# MAP BUILDING
# =========================

## Build full visual representation of the map
func _build() -> void:
	var cell_width: int = Battlefield.CELL_WIDTH
	var cell_half_width: float = Battlefield.CELL_HALF_WIDTH
	var cell_half_height: float = Battlefield.CELL_HALF_HEIGHT
	var level_height: int = Battlefield.LEVEL_HEIGHT

	var col: int = -1
	var row: int = 0
	var x_offset: float = 0

	var cells: Array[CellResource] = map_resource.cells
	var cell_count: int = cells.size()
	var max_col: int = map_resource.width - 1

	# --------------------------------------------------
	# Background
	# --------------------------------------------------
	if background != null and map_resource.background_id != 0:
		background.texture = loader_handler.get_background_texture(map_resource.background_id)

	# --------------------------------------------------
	# Cell loop
	# --------------------------------------------------
	var cell_index: int = -1
	while cell_index + 1 < cell_count:
		cell_index += 1

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

		var cell: CellResource = cells[cell_index]

		if not cell.active:
			continue

		var cell_x: float = col * cell_width + x_offset
		var cell_y: float = row * cell_half_height \
			- level_height * (cell.ground_level - 7)

		var cell_position: Vector2 = Vector2(cell_x, cell_y)


		# ----------------------------------------------
		# Ground layer
		# ----------------------------------------------
		if cell.layer_ground_num != 0:
			var ground_sprite: Sprite2D = Sprite2D.new()
			ground_sprite.centered = false
			ground_sprite.hframes = get_frame_count_from_json(cell.layer_ground_num, Battlefield.G_METADATAS_JSON_PATH)
			ground_sprite.texture = loader_handler.get_ground_tile_texture(cell.layer_ground_num)
			var bounds: Vector2 = get_bounds_from_json(cell.layer_ground_num, Battlefield.G_METADATAS_JSON_PATH)
			ground_sprite.offset = bounds
			ground_sprite.position = cell_position

			if cell.ground_slope != 1:
				ground_sprite.frame = cell.ground_slope - 1
			elif cell.layer_ground_rot != 0:
				ground_sprite.rotation_degrees = float(cell.layer_ground_rot * 90)
				if int(ground_sprite.rotation_degrees) % 180 != 0:
					ground_sprite.scale = Vector2(0.5185, 1.9286)

			if cell.layer_ground_flip:
				ground_sprite.scale.x *= -1.0

			ground_layer.add_child(ground_sprite)

		# ----------------------------------------------
		# Object layer 1
		# ----------------------------------------------
		if cell.layer_object1_num != 0:
			var object1_sprite: Sprite2D = Sprite2D.new()
			object1_sprite.centered = false
			object1_sprite.texture = loader_handler.get_object_sprite_texture(cell.layer_object1_num)
			var bounds: Vector2 = get_bounds_from_json(cell.layer_object1_num, Battlefield.O_BOUNDS_JSON_PATH)
			object1_sprite.offset = bounds
			object1_sprite.position = cell_position
			

			if cell.ground_slope == 1 and cell.layer_object1_rot != 0:
				object1_sprite.rotation_degrees = float(cell.layer_object1_rot * 90)
				if int(object1_sprite.rotation_degrees) % 180 != 0:
					object1_sprite.scale = Vector2(0.5185, 1.9286)

			if cell.layer_object1_flip:
				object1_sprite.scale.x *= -1.0

			object1_layer.add_child(object1_sprite)

		# ----------------------------------------------
		# Object layer 2 (top)
		# ----------------------------------------------
		if cell.layer_object2_num != 0:
			var object2_sprite: Sprite2D = Sprite2D.new()
			object2_sprite.centered = false
			object2_sprite.texture = loader_handler.get_object_sprite_texture(cell.layer_object2_num)
			var bounds: Vector2 = get_bounds_from_json(cell.layer_object2_num, Battlefield.O_BOUNDS_JSON_PATH)
			object2_sprite.offset = bounds
			object2_sprite.position = cell_position
			

			if cell.layer_object2_flip:
				object2_sprite.scale.x = -1.0

			object2_layer.add_child(object2_sprite)

		# ----------------------------------------------
		# Cell ID label
		# ----------------------------------------------
		var cell_id_label: Label = Label.new()
		cell_id_label.text = str(cell_index)
		cell_id_label.add_theme_font_size_override("font_size", 12)
		cell_id_label.add_theme_color_override("font_color", Color.WHITE)
		cell_id_label.add_theme_color_override("font_outline_color", Color.BLACK)
		cell_id_label.add_theme_constant_override("outline_size", 2)
		
		# Center the label on the cell position
		cell_id_label.position = cell_position
		cell_id_label.position.x -= 10  # Approximate centering offset
		cell_id_label.position.y -= 6
		
		cell_ids_layer.add_child(cell_id_label)


# =========================
# DISPLAY METHODS
# =========================

## Toggle visibility of cell ID labels
func display_cell_ids() -> void:
	if cell_ids_layer:
		cell_ids_layer.visible = not cell_ids_layer.visible


func get_bounds_from_json(gfx_id: int, file_path: String) -> Vector2:
	var bounds: Vector2 = Vector2.ZERO

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			if data.has(str(gfx_id)):
				var entry = data[str(gfx_id)]
				bounds = Vector2(entry["horizontal"], entry["vertical"])
				# print("ID: %s, Vector: %s" % [gfx_id, bounds])
			else:
				print("No entry found for gfx_id: ", gfx_id)
		else:
			print("Error parsing JSON: ", json.get_error_message())
		file.close()
	else:
		print("Error opening file: ", file_path)

	return bounds
	

func get_frame_count_from_json(gfx_id: int, file_path: String) -> int:
	var frame_count: int = -1

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			if data.has(str(gfx_id)):
				var entry = data[str(gfx_id)]
				frame_count = int(entry["frame_count"])
				# print("ID: %s, Frame count: %s" % [gfx_id, frame_count])
			else:
				print("No entry found for gfx_id: ", gfx_id)
		else:
			print("Error parsing JSON: ", json.get_error_message())
		file.close()
	else:
		print("Error opening file: ", file_path)

	return frame_count