# map_parser.gd
# Dofus Map Data Parser
# Decodes the compressed mapData string from database into cell properties

@tool
extends Node

# =========================
# EDITOR TESTING
# =========================

@export var test_map_7_function := false:
	set(value):
		if value:
			test_map_7_function = false
			_ready()
			test_map_7()


# =========================
# CONSTANTS
# =========================

const HASH := [
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_'
]

# Create dict for O(1) lookup
var HASH_DICT := {}


# =========================
# INITIALIZATION
# =========================

func _ready():
	_build_hash_dict()


func _build_hash_dict():
	for i in range(HASH.size()):
		HASH_DICT[HASH[i]] = i


# =========================
# HASH CONVERSION
# =========================

## Convert character to numeric value using HASH table
func get_int_by_hashed_value(c: String) -> int:
	if c.length() != 1:
		push_error("Character must be single char, got: " + c)
		return -1
	
	if not HASH_DICT.has(c):
		push_error("Invalid character not in HASH table: " + c)
		return -1
	
	return HASH_DICT[c]


# =========================
# CELL PARSING
# =========================

## Parse single cell data (10 characters) into cell properties
func parse_cell(cell_data: String, cell_num: int) -> Dictionary:
	if cell_data.length() != 10:
		push_error("Cell %d: Expected 10 chars, got %d" % [cell_num, cell_data.length()])
		return {}
	
	# Convert characters to byte array
	var bytes := []
	for i in range(10):
		var byte_val := get_int_by_hashed_value(cell_data[i])
		if byte_val == -1:
			push_error("Cell %d: Invalid character '%s' at position %d" % [cell_num, cell_data[i], i])
			return {}
		bytes.append(byte_val)
	
	# Extract cell properties using bit masks (matching Compressor.uncompressCell)
	var cell := {}
	
	# Basic properties
	cell.num = cell_num
	cell.raw_data = cell_data
	
	# === SERVER-SIDE PROPERTIES (from Java CryptManager) ===
	
	# Active status
	cell.active = ((bytes[0] & 0x20) >> 5) != 0
	
	# Line of sight
	cell.line_of_sight = (bytes[0] & 1) != 0
	
	# Ground level (elevation)
	cell.ground_level = bytes[1] & 0x0F
	
	# Movement/walkable (with special case checks)
	cell.movement = (bytes[2] & 0x38) >> 3
	cell.walkable = (cell.movement != 0 
		and cell_data != "bhGaeaaaaa" 
		and cell_data != "Hhaaeaaaaa")
	
	# Ground slope
	cell.ground_slope = (bytes[4] & 0x3C) >> 2
	
	# Object layer 2
	cell.layer_object2_num = ((bytes[0] & 2) << 12) + ((bytes[7] & 1) << 12) + (bytes[8] << 6) + bytes[9]
	cell.layer_object2_interactive = ((bytes[7] & 2) >> 1) != 0
	
	# Server-side object logic
	cell.object = cell.layer_object2_num if cell.layer_object2_interactive else -1
	
	# === CLIENT-SIDE RENDERING PROPERTIES (from ActionScript Compressor) ===
	
	# Ground layer rendering
	cell.layer_ground_num = ((bytes[0] & 0x18) << 6) + ((bytes[2] & 7) << 6) + bytes[3]
	cell.layer_ground_rot = (bytes[1] & 0x30) >> 4
	cell.layer_ground_flip = ((bytes[4] & 2) >> 1) != 0
	
	# Object layer 1 (static decorations)
	cell.layer_object1_num = ((bytes[0] & 4) << 11) + ((bytes[4] & 1) << 12) + (bytes[5] << 6) + bytes[6]
	cell.layer_object1_rot = (bytes[7] & 0x30) >> 4
	cell.layer_object1_flip = ((bytes[7] & 8) >> 3) != 0
	
	# Object layer 2 rendering (interactive objects)
	cell.layer_object2_flip = ((bytes[7] & 4) >> 2) != 0
	
	# External object layer (initially empty)
	cell.layer_object_external = ""
	cell.layer_object_external_interactive = false
	
	# Permanent level offset (used in rendering calculations)
	cell.permanent_level = 0
	
	# Derived property: Is cell targetable for combat?
	cell.is_targetable = cell.active and cell.walkable
	
	return cell


# =========================
# MAP PARSING
# =========================

## Parse complete map data string into array of cells
func parse_map(map_id: int, width: int, height: int, map_data: String) -> Array:
	print("=== Parsing Map %d ===" % map_id)
	print("Dimensions: %dx%d" % [width, height])
	print("MapData length: %d chars" % map_data.length())
	
	# Validate map data length
	if map_data.length() % 10 != 0:
		push_error("MapData length must be divisible by 10, got: %d" % map_data.length())
		return []
	
	var actual_cell_count := map_data.length() / 10
	print("Cell count: %d" % actual_cell_count)
	
	# Parse each cell
	var cells := []
	for i in range(actual_cell_count):
		var start_pos := i * 10
		var cell_data := map_data.substr(start_pos, 10)
		var cell := parse_cell(cell_data, i)
		
		if cell.is_empty():
			push_error("Failed to parse cell %d" % i)
			return []
		
		cells.append(cell)
	
	print("Successfully parsed %d cells" % cells.size())
	return cells


# =========================
# VALIDATION & COMPARISON
# =========================

## Export cells to CSV format (matching Java output)
func export_to_csv(cells: Array, output_path: String) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: " + output_path)
		return
	
	# Write header
	file.store_line("cellNum,rawData,walkable,los,level,slope,active,layerObject2,layerObject2Interactive,object")
	
	# Write data rows
	for cell in cells:
		var line := "%d,%s,%s,%s,%d,%d,%s,%d,%s,%d" % [
			cell.num,
			cell.raw_data,
			"TRUE" if cell.walkable else "FALSE",
			"TRUE" if cell.line_of_sight else "FALSE",
			cell.ground_level,
			cell.ground_slope,
			"TRUE" if cell.active else "FALSE",
			cell.layer_object2_num,
			"TRUE" if cell.layer_object2_interactive else "FALSE",
			cell.object
		]
		file.store_line(line)
	
	file.close()
	print("Exported %d cells to: %s" % [cells.size(), output_path])


## Compare GDScript output with Java reference CSV
func compare_with_java_output(cells: Array, java_csv_path: String) -> bool:
	var file := FileAccess.open(java_csv_path, FileAccess.READ)
	if not file:
		push_error("Failed to open Java CSV: " + java_csv_path)
		return false
	
	# Skip header
	file.get_line()
	
	var mismatches := 0
	var line_num := 1
	
	for cell in cells:
		var java_line := file.get_line()
		if java_line == "":
			break
		
		var java_values := java_line.split(",")
		var gd_values := [
			str(cell.num),
			cell.raw_data,
			"TRUE" if cell.walkable else "FALSE",
			"TRUE" if cell.line_of_sight else "FALSE",
			str(cell.ground_level),
			str(cell.ground_slope),
			"TRUE" if cell.active else "FALSE",
			str(cell.layer_object2_num),
			"TRUE" if cell.layer_object2_interactive else "FALSE",
			str(cell.object)
		]
		
		# Compare each field
		for i in range(min(java_values.size(), gd_values.size())):
			if java_values[i] != gd_values[i]:
				print("Mismatch at cell %d, field %d:" % [cell.num, i])
				print("  Java:     %s" % java_values[i])
				print("  GDScript: %s" % gd_values[i])
				mismatches += 1
				break
		
		line_num += 1
	
	file.close()
	
	if mismatches == 0:
		print("✓ Perfect match! All %d cells identical to Java output" % cells.size())
		return true
	else:
		print("✗ Found %d mismatches" % mismatches)
		return false


# =========================
# TEST FUNCTION
# =========================

## Test with map 7 (manual data for now)
func test_map_7():
	var map_id := 7
	var width := 15
	var height := 17
	
	# TODO: Replace with actual mapData from database
	var map_data := "HxbfeaaaaaH3bfeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhafeaaaaaHhafeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaH3aBeaaaaaHNaDeaaaaaHxaCeaaaaaHxaCeaaaaaHhrfeaaaiHHhrfeaaaiHHhqaeaaaaaHhqaeaaaiHHhsJeaaaaaHhGaeb4WaaHhqfeqgaaaHhGaeb5qaaHhaaeaaaaaahaaeaaaaaHhGaemKaaaHhaBeaaaaaHNaDeaaaaaH3aCeaaaaaHNbfeaaaiHH3rfeaaaiHHhsJeaaaeBHhqaeaaaaaHhqaeaaaaaHhqaeaaaiHHhG7eb5GaaHhGaeb4GaaHhaaeaaaaaahaaeaaaaabhGaeaaaaabhGaemKaaaHNaBeaaaaaHNaDeaaaaaHxaCeaaaaaHhrfeaaaiHHhsJeaaaiHH3rfeaaaiHHhsJeaaaaaHhqaeaaaaaHhq5eaaaaaHxG7eaaaaaHhGaeaaaaaHhaaeaaaaabhGaeaaaaabhGaeaaaaabhGaemKaaaHNaBeaaaaaHNaDeaaaaaHxbfeaaaiHHhsJeaaaiHHNrfeaaaiHHxq7eaaaiHHhIJeaaaaaH3q7eaaaaaHNG5eaaaaaHhGaeaaaaaHha7eaaaaaHha7eaaaaaHhaaeaaaaabhGaeaaaaabhGaemKaaaHNaBeaaaaaHNaDeaaaaaHhsJeaaaiHHhsJeaaaiHHhsJeaaaaaHhGaeaaaaaG3bfeaaaaaHNq7em0aaaHhGaem0aaaH3G7eaaaaaHxa6eaaaaaHxa7eaaaaabhGaeaaaaabhGaeaaaaaHhaBemLaaaHhaBeaaadHH3a5eaaaaaHhsJeaaaiHHhq6eaaaiHHhsJeaaaiHHhIJeaaeilGNbfeaaaaaHhGaem0aaaHhGaeaaaaaG3a5eaaadzGNa5eaaadzHhaaeaaaaabhGaeaaaaabhGaeaaaaaH3aBeaaaaaHNaBeaaaaaH3q5eaaaiHH3q6eaaaiHHNq5eaaaeBHhsJeaaaaaHhIJeaaaaaHNG5eaaaaaHhGaeaaaaaHhGaeaaaaaHNa7eaaadzHhaaeaaaaabhGaeaaaaabhGaeaaaaaHhGaemKaaaHNaBeaaadIHhaaeaaaaaHNq7eaaaiHHNq7eaaaaaHhsJem0aaaHhsJeaaaaaHNG7eaaaaaHhGaeaaaaaHhGaeaaaiFHhaaeaaeiOHhaaeaaaaaHhGXeaaaaabhGaeaaaaabhGaeaaaaaHhGaemKaaaHhaBeaaaaaHhqaeaaaiHHhsJeaaaaaHhqaeaaaaaHhqaem0aaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhaaeaaeiObhGaeaaaaaHhGXeaaaaabhGXeaaaaabhGaeaaaaabhGaeaaaaaHhGaemKaaaHhcJeaaaeBHhqaeaaaiHHhsJem0aaaHhsJeaaaaaHhGaeaaaaaHhqaeaaaaaHhGaeaaaaaHhaaeaaeiObhGaeaaaaaHhGXeaaaaabhGaeaaaaabhGXeaaaaabhGaeaaaaabhGaeaaaaaHhaaemKaaaHhqaeaaaaaHhqaeaaaaaHhqaeaaaaaGhaaeaaaaaHhq7eaaaaaHhqaeaaaaaHhaaeaaaiObhGaeaaadyHhGXeaaaaabhGaeaaaaabhGaeaaaaabhGXeaaaaabhGaeaaaaabhGaeaaaaaHhaaeaaaaaHhqaeaaaaaHhqaem0aaaGhaaeaaadLH3q7eaaaaaHxq7eaaaiHHhWaeaaaaaHhaaeaaaiOHhGXeaaaaabhIMeaaaaabhIKeaaaaabhGaeaaaaabhGXeaaaaabhGaeaaaaabhGaeaaaaaHhGaeaaaaaHhq7eaaaaaHha7eaaadyHhq9eaaaaaHNq7eaaaiHHhGaeaaaaaHhGaeaaaaaHhaXeaaaaabhIMeaaaaabhGaeaaaaabhaaeaaaaabhGaeaaaaabhGXeaaaaabhGaeaaaaaHhaaemHaaaH3G7eaaaiHHxq6eaaaiHHxq7eaaaiHHha9em0adQHhGaem0aaaHhWaeaaaaaHhGXeaaaaaHhcKeaaaiObhILeaaadyGhaaeaaaaabhaaeaaaaabhGaeaaaaaHhGXeaaaaabhGaeaaaaaHhGaemHaaaH3q5eaaaiHHNq5eaaaiHHhG9eaaaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhIMeaaaaaHhcLeaaaiOGhcMeaaaaaahaaeaaaaabhaaeaaaaabhGaeaaaaaHhGXeaaaaaHhafeaaaaaHhGaemHaaaHNq7eaaaiHHhqaeaaaiHHhGaeaaaiFHhGaeaaaaaHhWaeaaaaaHhGaeaaaaaHhILeaaaaaHhcJeaaaaaGhaaeaaaaaGhaaeaaae_bhaaeaaaaaHxbfeaaaaaHhaXeaaaaaHhqfeqgGaaHhqaemHaiHHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhWaeaaaaaHhGXeaaaaaHhIMeaaaaaGhbfeaaaaaahaaeaaaaaahaaeaaaaabhaaeaaaaaHNbfeaaaaaHhaaemHGaaHhWfeaaaaaHhGaemHaaaHhGaem0aaaHhGaeaaaeBHhGaeaaaaaHhGaeaaaaaHhWXeaaaaaHhGaeaaaaaH3a5ecsaaaGhaaeaaaaaahaaeaaaaaahaaeaaaaaHhbfeoIaaaHxbfeaaaaaHhGaeb5WaaHhWfeaaaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhWaeaaaaaHhGaemHWaaGhafeaaaaaGhaaeaaaaaGhaaeaaaaaGNbfeaaaaaHhbfeaaaaaHhaaeaaaaaHhWfeaaaaaHhGaeb4qaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhWaemHWaaHhWfeqgaaaGhafeaaaaaGhbfecraaaGxbfeaaaaaH3a6eaaaaaH3a6eaaaaaHhGaemHGaaHhWfeaaaaaHhGaemHaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHNGXemHWaaHhWfeaaaaaHhGaemHqaaH3a7ecsa4QHxbfecraaaHhcMeoIaiOHNa7eaaaaaHhaaeaaaiFHhGaemHGaaHhWfeaaaaaHhGaemHaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXemHWaaHhWfeaaaaaHhWaemHqaaHhGaecsaaaHNG7ecra4QHhIMeaaaaaHhcMeaaaiOHhaaeaaaaaHhGaeaaaaaHhGaemHGaaHhWfeaaaaaHhGaemHaaaHhGaeaaaaaHhGaeaaaaaHhGaemHWaaHxWfeaaaaaHhGXemHqaaHhWaeaaaaaHhGaeaaaaaHhG7eaaaaaHhGaeaaa4QHhaaeaaaiOHhaaeaaaaaHhGaeaaaaaHhGaemHGaaHhWfeaaaaaHhGaemHaiFHhGaeaaaaaHhGaemHWaaHNWfeaaaaaHhGaemHqaaHhGXeaaaaaHhWaeaaaaaH3G7eaaaaaHxG7eaaaaaHhGaeaaa4QHhaaeaaaiOHhGaeaaaaaHhGaeaaaaaHhGaeb5WaaHhWfeaaaaaHhGaeaaaaaHhGaemHWaaHhWfeaaaaaHhGaemHqaaHhaaeaaadpHhGXeaaaaaHhWaeaaaaaGNa7eaaadxHhGaeaaaaaHhGXeaaa4QHhaaeaaaaaHhGaeaaaaaHhG7eaaaaaHhWfeaaaaaHhGaeb4qaaGhaaemHWiQHNWfeaaaaaHhGaemHqaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhWaeaaaaaHhG9eaaaaaHhGXeaaaaaHhaXeaaaaaHhGaeaaaaaH3G7eaaaaaHxG7emHGaaHhWfeaaaaaHhGaeb5aaaHNWfeaaaaaHhGaemHqaaHhGaeaaaaaHhaaeaaadpHhGXeaaaaaHhGaeaaaaaHhWaeaaaaaHhGXeaaaaaHhGaeqgaaaHhaaeaaaaaHhGaeaaaaaGNa7eaaadzHhGaemHGaaHhWfeaaaaaHhWfeaaaaaHhGaemHqaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhaaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGaeb5WaaHhWfeaaaaaHhGaemHqaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhGXeaaaaaHhaaeaaa4QHhGaeaaaaaHhGaeaaaaaHhGaemHWaaH3WfeaaaaaHhGaeb5qaaHhGaeaaaaaHhGaeaaaaaHhaaeaaadpHhGaeaaaaaHhGXeaaaeBHhGXeaaaaaHhGaeaaaaaHhGXeaaaaaHhaXeaaaaaHhGaeaaaeBHhGaeaaaaaHhGaeaaaaaHxWfeaaaaaHhqfeqgGaaHhGaeaaaaaHhGaeaaaaaHhGaeaaaeBHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhGaeaaaaaHhGaeaaaaaHhGXeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhafeaEWaaHxafeaaaaaHhafeaEaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaaaHhaaeaaaiFHhaaeaaaaaHhaaeaaaaa"
	# ... (full 4790 characters)
	
	var cells := parse_map(map_id, width, height, map_data)
	
	if cells.is_empty():
		print("Failed to parse map!")
		return


	for cell in cells:
		print("\n=== Cell %d ===" % cell.num)
		#for key in cell.keys():
			#print("  %s: %s" % [key, cell[key]])
		print("  %s: %s" % ["layer_ground_num", cell["layer_ground_num"]])
	
	# Export for comparison
	export_to_csv(cells, "user://map_7_gdscript.csv")
	
	# Compare with Java output (if available)
	var java_csv := "user://map_7_java.csv"
	if FileAccess.file_exists(java_csv):
		compare_with_java_output(cells, java_csv)
