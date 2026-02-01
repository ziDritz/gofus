# LoaderHandler.gd
# Referenced via Battlefield
# Handles loading and caching of map assets (ground tiles, object sprites, backgrounds)
class_name LoaderHandler
extends Node

# =========================
# CONSTANTS
# =========================
const GROUND_TILES_PATH: String = "res://assets/graphics/gfx/grounds/"
const OBJECT_SPRITES_PATH: String = "res://assets/graphics/gfx/objects/"
const BACKGROUNDS_PATH: String = "res://assets/graphics/gfx/backgrounds/"

# =========================
# ASSET CACHE
# =========================
var _ground_tile_cache: Dictionary = {}
var _object_sprite_cache: Dictionary = {}
var _background_cache: Dictionary = {}

# =========================
# INITIALIZATION
# =========================
func _ready() -> void:
	print("[LoaderHandler] Initializing...")
	print("[LoaderHandler] Ready")

# =========================
# ASSET LOADING
# =========================
## Get ground tile texture (cached)
func get_ground_tile(tile_id: int) -> Texture2D:
	if tile_id == 0:
		return null
	
	if not _ground_tile_cache.has(tile_id):
		var path: String = GROUND_TILES_PATH + "%d.png" % tile_id
		if ResourceLoader.exists(path):
			_ground_tile_cache[tile_id] = load(path)
		else:
			push_warning("[LoaderHandler] Ground tile not found: " + path)
			return null
	
	return _ground_tile_cache[tile_id]

## Get object sprite texture (cached)
func get_object_sprite(sprite_id: int) -> Texture2D:
	if sprite_id == 0:
		return null
	
	if not _object_sprite_cache.has(sprite_id):
		var path: String = OBJECT_SPRITES_PATH + "%d.png" % sprite_id
		if ResourceLoader.exists(path):
			_object_sprite_cache[sprite_id] = load(path)
		else:
			push_warning("[LoaderHandler] Object sprite not found: " + path)
			return null
	
	return _object_sprite_cache[sprite_id]

## Get background texture (cached)
func get_background(bg_id: int) -> Texture2D:
	if bg_id == 0:
		return null
	
	if not _background_cache.has(bg_id):
		var path: String = BACKGROUNDS_PATH + "%d.png" % bg_id
		if ResourceLoader.exists(path):
			_background_cache[bg_id] = load(path)
		else:
			push_warning("[LoaderHandler] Background not found: " + path)
			return null
	
	return _background_cache[bg_id]

# =========================
# CACHE MANAGEMENT
# =========================
## Clear all cached assets (useful for memory management)
func clear_cache() -> void:
	_ground_tile_cache.clear()
	_object_sprite_cache.clear()
	_background_cache.clear()
	print("[LoaderHandler] All caches cleared")

## Clear specific cache type
func clear_ground_cache() -> void:
	_ground_tile_cache.clear()
	print("[LoaderHandler] Ground tile cache cleared")

func clear_object_cache() -> void:
	_object_sprite_cache.clear()
	print("[LoaderHandler] Object sprite cache cleared")

func clear_background_cache() -> void:
	_background_cache.clear()
	print("[LoaderHandler] Background cache cleared")

## Get cache statistics
func get_cache_stats() -> Dictionary:
	return {
		"ground_tiles": _ground_tile_cache.size(),
		"object_sprites": _object_sprite_cache.size(),
		"backgrounds": _background_cache.size(),
		"total": _ground_tile_cache.size() + _object_sprite_cache.size() + _background_cache.size()
	}

## Preload assets for a specific range of IDs (optional optimization)
func preload_ground_tiles(tile_ids: Array[int]) -> void:
	for tile_id in tile_ids:
		get_ground_tile(tile_id)

func preload_object_sprites(sprite_ids: Array[int]) -> void:
	for sprite_id in sprite_ids:
		get_object_sprite(sprite_id)

func preload_backgrounds(bg_ids: Array[int]) -> void:
	for bg_id in bg_ids:
		get_background(bg_id)
