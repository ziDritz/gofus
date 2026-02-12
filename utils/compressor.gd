# Compressor.gd
# AutoLoad singleton
# Handles compression/decompression of cell data

extends Node

# =========================
# CONSTANTS
# =========================

const HASH: Array = [
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_'
]

var HASH_DICT: Dictionary = {}

# =========================
# INITIALIZATION
# =========================

func _ready() -> void:
	print("[Compressor] Initializing...")
	_build_hash_dict()
	print("[Compressor] Ready")

## Build hash dictionary for fast character lookup
func _build_hash_dict() -> void:
	for i in range(HASH.size()):
		HASH_DICT[HASH[i]] = i

# =========================
# HASH CONVERSION
# =========================

## Convert character to numeric value using HASH table
func get_int_by_hashed_value(c: String) -> int:
	if c.length() != 1:
		push_error("[Compressor] Character must be single char, got: " + c)
		return -1
	if not HASH_DICT.has(c):
		push_error("[Compressor] Invalid character not in HASH table: " + c)
		return -1
	return HASH_DICT[c]

# =========================
# DECOMPRESSION
# =========================

## Apply decompression algorithm to cell data
## Parse single cell data (10 characters) into cell properties dictionary
## Flow: Compressed string → Uncompressed string
func uncompress_cell_data(cell_data: String, cell_num: int) -> Dictionary:
	if cell_data.length() != 10:
		push_error("[Compressor] Cell %d: Expected 10 chars, got %d" % [cell_num, cell_data.length()])
		return {}
	
	# Convert characters to byte array
	var bytes: Array = []
	for i in range(10):
		var byte_val: int = get_int_by_hashed_value(cell_data[i])
		if byte_val == -1:
			push_error("[Compressor] Cell %d: Invalid character '%s' at position %d" % [cell_num, cell_data[i], i])
			return {}
		bytes.append(byte_val)
	
	# Extract cell properties using bit masks (matching Compressor.uncompressCell)
	var cell: Dictionary = {}
	
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
