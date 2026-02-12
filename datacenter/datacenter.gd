# Datacenter.gd
# AutoLoad singleton
# Singleton API that holds and provides access to the current MapResource

extends Node


## The currently active map resource
var current_map_resource: MapResource = null


## Emitted when the current map changes
signal map_changed(new_map: MapResource)


func _ready() -> void:
	print("[Datacenter] Initializing...")
	print("[Datacenter] Ready")


## Replace current_map_resource with the new MapResource
## Flow: MapResource → stored as current_map_resource
func set_current_map_resource(map: MapResource) -> void:
	current_map_resource = map
	print("[Datacenter] Current map set to: %d" % map.map_id)
	map_changed.emit(map)

## Return current MapResource
## Flow: Returns current MapResource
func get_current_map() -> MapResource:
	return current_map_resource
