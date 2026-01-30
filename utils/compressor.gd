extends Node
## Compressor utility for encoding/decoding map data and paths
## Merged from ank.utils.Compressor and ank.battlefield.utils.Compressor
## Adapted for Godot 4

# CSV export for debuging
const output_path: String = "cell_csv"

# Static arrays for encoding/decoding
const ZIPKEY: Array[String] = [
	"_a", "_b", "_c", "_d", "_e", "_f", "_g", "_h", "_i", "_j", "_k", "_l", "_m", "_n", "_o", "_p",
	"_q", "_r", "_s", "_t", "_u", "_v", "_w", "_x", "_y", "_z", "A", "B", "C", "D", "E", "F",
	"G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
	"W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "_"
]

const ZKARRAY: Array[String] = [
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
	"q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F",
	"G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
	"W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "_"
]

# Hash codes for quick lookup
var _hash_codes: Dictionary = {}


func _ready() -> void:
	_initialize()


## Initialize hash codes for decoding.
func _initialize() -> void:
	_hash_codes.clear()
	for i in range(ZKARRAY.size()):
		_hash_codes[ZKARRAY[i]] = i


## Decode a base64-like character to its numeric value.
func decode64(coded_value: String) -> int:
	if coded_value in _hash_codes:
		return _hash_codes[coded_value]
	push_error("Invalid coded value: " + coded_value)
	return 0


## Encode a numeric value to a base64-like character.
func encode64(value: int) -> String:
	if value >= 0 and value < ZKARRAY.size():
		return ZKARRAY[value]
	push_error("Value out of range: " + str(value))
	return ""


## Uncompress map data and return an array of CellResource objects.
## Each cell is decoded from a 10-character compressed string.
func uncompress_map_data(compressed_map_data: String, forced: bool = false) -> Array[CellResource]:
	var cell_resources: Array[CellResource] = []
	var data_len: int = compressed_map_data.length()
	var cell_index: int = 0
	var char_index: int = 0
	
	while char_index < data_len:
		var cell_data: String = compressed_map_data.substr(char_index, 10)
		var cell: CellResource = uncompress_cell(cell_data, forced, 0)
		cell.num = cell_index
		cell_resources.append(cell)
		
		cell_index += 1
		char_index += 10

	return cell_resources


## Uncompress a single cell from a 10-character string.
## Returns a CellResource with all cell properties decoded.
func uncompress_cell(cell_data: String, forced: bool = false, permanent_level: int = 0) -> CellResource:
	var cell_resource : CellResource = CellResource.new()

	# Split into characters and convert to codes
	var chars: PackedStringArray = cell_data.split("")
	var codes: Array[int] = []
	codes.resize(chars.size())

	for i in range(chars.size()):
		codes[i] = decode64(chars[i])

	# Decode active flag
	cell_resource.is_active = bool((codes[0] & 0x20) >> 5)

	if cell_resource.is_active or forced:
		cell_resource.nPermanentLevel = permanent_level
		cell_resource.is_lineOfSight = bool(codes[0] & 1)
		cell_resource.layerGroundRot = (codes[1] & 0x30) >> 4
		cell_resource.groundLevel = codes[1] & 0x0F
		cell_resource.movement = (codes[2] & 0x38) >> 3
		cell_resource.layerGroundNum = ((codes[0] & 0x18) << 6) + ((codes[2] & 7) << 6) + codes[3]
		cell_resource.groundSlope = (codes[4] & 0x3C) >> 2
		cell_resource.is_layerGroundFlip = bool((codes[4] & 2) >> 1)
		cell_resource.layerObject1Num = ((codes[0] & 4) << 11) + ((codes[4] & 1) << 12) + (codes[5] << 6) + codes[6]
		cell_resource.layerObject1Rot = (codes[7] & 0x30) >> 4
		cell_resource.is_layerObject1Flip = bool((codes[7] & 8) >> 3)
		cell_resource.is_layerObject2Flip = bool((codes[7] & 4) >> 2)
		cell_resource.is_layerObject2Interactive = bool((codes[7] & 2) >> 1)
		cell_resource.layerObject2Num = ((codes[0] & 2) << 12) + ((codes[7] & 1) << 12) + (codes[8] << 6) + codes[9]
		cell_resource.layerObjectExternal = ""
		cell_resource.is_layerObjectExternalInteractive = false
		cell_resource.is_targetable = cell_resource.is_active and cell_resource.is_lineOfSight

	return cell_resource



## Compress map data to a string.
## map_data should have a 'data' key containing an array of cell dictionaries.
func compress_map(map_data: Dictionary) -> String:
	if not map_data.has("data"):
		push_error("Map data missing 'data' array")
		return ""
	
	var compressed_cells: PackedStringArray = []
	var cells: Array = map_data["data"]
	
	for cell in cells:
		compressed_cells.append(compress_cell(cell))
	
	return "".join(compressed_cells)


## Compress a single cell dictionary to a 10-character string.
func compress_cell(cell: Dictionary) -> String:
	var values: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

	values[0] = (1 if cell["is_active"] else 0) << 5
	values[0] |= 1 if cell["is_lineOfSight"] else 0
	values[0] |= (cell["layerGroundNum"] & 0x0600) >> 6
	values[0] |= (cell["layerObject1Num"] & 0x2000) >> 11
	values[0] |= (cell["layerObject2Num"] & 0x2000) >> 12

	values[1] = (cell["layerGroundRot"] & 3) << 4
	values[1] |= cell["groundLevel"] & 0x0F

	values[2] = (cell["movement"] & 7) << 3
	values[2] |= (cell["layerGroundNum"] >> 6) & 7

	values[3] = cell["layerGroundNum"] & 0x3F

	values[4] = (cell["groundSlope"] & 0x0F) << 2
	values[4] |= (1 if cell["is_layerGroundFlip"] else 0) << 1
	values[4] |= (cell["layerObject1Num"] >> 12) & 1

	values[5] = (cell["layerObject1Num"] >> 6) & 0x3F
	values[6] = cell["layerObject1Num"] & 0x3F

	values[7] = (cell["layerObject1Rot"] & 3) << 4
	values[7] |= (1 if cell["is_layerObject1Flip"] else 0) << 3
	values[7] |= (1 if cell["is_layerObject2Flip"] else 0) << 2
	values[7] |= (1 if cell["is_layerObject2Interactive"] else 0) << 1
	values[7] |= (cell["layerObject2Num"] >> 12) & 1

	values[8] = (cell["layerObject2Num"] >> 6) & 0x3F
	values[9] = cell["layerObject2Num"] & 0x3F

	var encoded: PackedStringArray = []
	for value in values:
		encoded.append(encode64(value))

	return "".join(encoded)



## Path Compression/Decompression

## Compress a full path to a compact string representation.
func compress_path(full_path_data: Array, with_first: bool = false) -> String:
	var compressed: String = ""
	var light_path: Array = make_light_path(full_path_data, with_first)
	
	for step in light_path:
		var dir: int = step.get("dir", 0) & 7
		var num: int = step.get("num", 0)
		var high: int = (num & 0x0FC0) >> 6
		var low: int = num & 0x3F
		
		compressed += encode64(dir)
		compressed += encode64(high)
		compressed += encode64(low)
	
	return compressed


## Convert a full path to a light path (only direction changes).
func make_light_path(full_path: Array, with_first: bool = false) -> Array:
	if full_path.is_empty():
		push_error("Path is empty")
		return []
	
	var light_path: Array = []
	
	if with_first:
		light_path.append(full_path[0])
	
	var prev_dir: int = -1
	
	for i in range(full_path.size() - 1, -1, -1):
		var step_dir: int = full_path[i].get("dir", -1)
		if step_dir != prev_dir:
			light_path.push_front(full_path[i])
			prev_dir = step_dir
	
	return light_path


## Extract full path from compressed data.
func extract_full_path(map_width: int, cell_count: int, compressed_data: String) -> Array:
	var light_path: Array = []
	var chars: PackedStringArray = compressed_data.split("")
	var data_len: int = compressed_data.length()
	
	var index: int = 0
	while index < data_len:
		var dir_code: int = decode64(chars[index])
		var high_code: int = decode64(chars[index + 1])
		var low_code: int = decode64(chars[index + 2])
		
		var cell_num: int = (high_code & 0x0F) << 6 | low_code
		
		if cell_num < 0 or cell_num > cell_count:
			push_error("Cell not on map: " + str(cell_num))
			return []
		
		light_path.append({"num": cell_num, "dir": dir_code})
		index += 3
	
	return make_full_path(map_width, light_path)


## Convert a light path to a full path.
func make_full_path(map_width: int, light_path: Array) -> Array:
	if light_path.is_empty():
		return []
	
	var full_path: Array = []
	var dir_offsets: Array[int] = [
		1,
		map_width,
		map_width * 2 - 1,
		map_width - 1,
		-1,
		-map_width,
		-map_width * 2 + 1,
		-(map_width - 1)
	]
	
	var current_num: int = light_path[0].get("num", 0)
	full_path.append(current_num)
	
	for light_index in range(1, light_path.size()):
		var target_num: int = light_path[light_index].get("num", 0)
		var direction: int = light_path[light_index].get("dir", 0)
		var safety: int = 2 * map_width + 1
		
		while full_path[-1] != target_num:
			current_num += dir_offsets[direction]
			full_path.append(current_num)
			
			safety -= 1
			if safety < 0:
				push_error("Impossible path")
				return []
		
		current_num = target_num
	
	return full_path




# =========================
# VALIDATION & COMPARISON
# =========================

## Export cells to CSV format (matching Java output)
func export_to_csv(cells: Array[CellResource]) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + output_path)
		return

	# Header (Java-compatible)
	file.store_line(
		"cellNum,rawData,walkable,los,level,slope,active,layerObject2,layerObject2Interactive,object"
	)

	for cell in cells:
		# Build dictionary expected by compress_cell()
		var cell_dict := {
			"is_active": cell.is_active,
			"is_lineOfSight": cell.is_lineOfSight,
			"layerGroundRot": cell.layerGroundRot,
			"groundLevel": cell.groundLevel,
			"movement": cell.movement,
			"layerGroundNum": cell.layerGroundNum,
			"groundSlope": cell.groundSlope,
			"is_layerGroundFlip": cell.is_layerGroundFlip,
			"layerObject1Num": cell.layerObject1Num,
			"layerObject1Rot": cell.layerObject1Rot,
			"is_layerObject1Flip": cell.is_layerObject1Flip,
			"is_layerObject2Flip": cell.is_layerObject2Flip,
			"is_layerObject2Interactive": cell.is_layerObject2Interactive,
			"layerObject2Num": cell.layerObject2Num
		}

		var raw_data: String = compress_cell(cell_dict)

		var line := "%d,%s,%s,%s,%d,%d,%s,%d,%s,%d" % [
			cell.num,
			raw_data,
			"TRUE" if cell.movement > 0 else "FALSE", # walkable
			"TRUE" if cell.is_lineOfSight else "FALSE",
			cell.groundLevel,
			cell.groundSlope,
			"TRUE" if cell.is_active else "FALSE",
			cell.layerObject2Num,
			"TRUE" if cell.is_layerObject2Interactive else "FALSE",
			cell.layerObject1Num # object
		]

		file.store_line(line)
	file.close()
	print("Exported %d cells to: %s" % [cells.size(), output_path])
