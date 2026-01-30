# Compressor.gd


static var ZIPKEY : Array = [
	"_a","_b","_c","_d","_e","_f","_g","_h","_i","_j","_k","_l","_m","_n","_o","_p",
	"_q","_r","_s","_t","_u","_v","_w","_x","_y","_z",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
	"Q","R","S","T","U","V","W","X","Y","Z",
	"0","1","2","3","4","5","6","7","8","9","-","_"
]

static var ZKARRAY : Array = [
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p",
	"q","r","s","t","u","v","w","x","y","z",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
	"Q","R","S","T","U","V","W","X","Y","Z",
	"0","1","2","3","4","5","6","7","8","9","-","_"
]

# static var _self : Compressor = Compressor.new()

var _hash_codes: Dictionary = {}

func _init() -> void:
	initialize()

func initialize() -> void:
	_hash_codes.clear()
	for i in range(ZKARRAY.size()):
		_hash_codes[ZKARRAY[i]] = i

# static func decode64(coded_value: String) -> int:
# 	return _self._hash_codes.get(coded_value, -1)

static func encode64(value: int) -> String:
	return ZKARRAY[value]
