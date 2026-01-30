extends Node

func request_map_data(map_id: String) -> void:
	var data: Dictionary = Database.get_map_by_id(map_id)

	if data.is_empty():
		push_error("[MapManager] Map not found: " + map_id)
		return

	parse_map(data)


func parse_map(data: Dictionary) -> void:
	var map_id = data["id"]
	var map_resource : MapResource = MapResource.new(map_id)

	# --- Basic fields ---
	map_resource.map_width = int(data["width"])
	map_resource.map_height = int(data["height"])
	map_resource.background_id = int(data["backgroundID"])
	map_resource.map_data = String(data["mapData"])
	map_resource.ambiance_id = int(data["ambianceID"])
	map_resource.music_id = int(data["musicID"])
	map_resource.is_outdoor = int(data["outDoor"]) == 1

	# --- Capabilities (bit flags) ---
	var capabilities: int = int(data["capabilities_y"])

	map_resource.can_challenge       = ((capabilities >> 0) & 1) == 0
	map_resource.can_attack          = ((capabilities >> 1) & 1) == 0
	map_resource.can_save_teleport   = ((capabilities >> 2) & 1) == 0
	map_resource.can_use_teleport    = ((capabilities >> 3) & 1) == 0

	# --- Permissions ---
	map_resource.can_attack_hunt = int(data["canAggro"]) == 1
	map_resource.can_use_item    = int(data["canUseObject"]) == 1
	map_resource.can_equip_item  = int(data["canUseInventory"]) == 1
	map_resource.can_boost_stats = int(data["canChangeCharac"]) == 1

	# --- Cells ---
	# var map_data: String = map_resource.map_data
	map_resource.cell_resources = Compressor.uncompress_map_data(map_resource.map_data)

	map_resource.valid_cell_resources.clear()
	for cell in map_resource.cell_resources:
		if cell.is_targetable:
			map_resource.valid_cell_resources.append(cell)

	if map_resource.cell_resources.size() > 0:
		print("[MapManager] First cell: ", map_resource.cell_resources[0].num)

	# Battlefield.build_map(map_resource)
