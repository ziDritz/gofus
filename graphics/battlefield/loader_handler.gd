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
# ASSET LOADING
# =========================
## Get ground tile texture (cached)
func get_ground_tile_texture(tile_id: int) -> Texture2D:
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
func get_object_sprite_texture(sprite_id: int) -> Texture2D:
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
func get_background_texture(bg_id: int) -> Texture2D:
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