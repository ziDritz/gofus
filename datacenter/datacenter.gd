# Datacenter.gd
# AutoLoad singleton
# Singleton API that holds and provides access to the current MapResource

extends Node

# =========================
# STATE
# =========================

## The currently active map resource
var current_map: MapResource = null

# =========================
# SIGNALS
# =========================

## Emitted when the current map changes
signal map_changed(new_map: MapResource)

# =========================
# INITIALIZATION
# =========================

func _ready() -> void:
	print("[Datacenter] Initializing...")
	print("[Datacenter] Ready")

# =========================
# MAP MANAGEMENT
# =========================

## Replace current_map with the new MapResource
## Flow: MapResource → stored as current_map
func set_current_map(map: MapResource) -> void:
	current_map = map
	print("[Datacenter] Current map set to: %d" % map.map_id)
	map_changed.emit(map)

## Return current MapResource
## Flow: Returns current MapResource
func get_current_map() -> MapResource:
	return current_map
