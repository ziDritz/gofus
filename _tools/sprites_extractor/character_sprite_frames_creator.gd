@tool
extends Node

# =========================
# CONFIG
# =========================
const PATH_TO_SPRITES := "res://assets/graphics/characters"
const FPS := 48.0
const LOOP := true
const OVERWRITE_EXISTING_ANIMATIONS := false



@export var import_frames := false:
	set(value):
		if value:
			import_frames = false
			import_all_characters(PATH_TO_SPRITES)



## Import logic (all folders → animations)
func import_character(character_path: String):
	var character_id := character_path.rstrip("/").get_file()
	var sprite_frames := load_or_create_sprite_frames(character_path, character_id)

	var frames_root := character_path + "/frames"
	var dir := DirAccess.open(frames_root)
	if dir == null:
		push_error("Cannot open: " + frames_root)
		return

	dir.list_dir_begin()
	var anim_name := dir.get_next()

	while anim_name != "":
		if dir.current_is_dir() and not anim_name.begins_with("."):
			import_animation_folder(
				sprite_frames,
				frames_root + "/" + anim_name,
				anim_name
			)
		anim_name = dir.get_next()
	dir.list_dir_end()

	ResourceSaver.save(sprite_frames, character_path + "/" + character_id + ".tres")



func import_all_characters(characters_root: String):
	var dir := DirAccess.open(characters_root)
	if dir == null:
		push_error("Cannot open: " + characters_root)
		return

	dir.list_dir_begin()
	var character_id := dir.get_next()

	while character_id != "":
		if dir.current_is_dir() and not character_id.begins_with("."):
			import_character(characters_root + "/" + character_id)
		character_id = dir.get_next()

	dir.list_dir_end()



## Import one animation folder safely
func import_animation_folder(
		sprite_frames: SpriteFrames,
		folder_path: String,
		animation_name: String
	):

	if sprite_frames.has_animation(animation_name):
		if not OVERWRITE_EXISTING_ANIMATIONS:
			print("Skipping existing animation:", animation_name)
			return
		sprite_frames.remove_animation(animation_name)

	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, FPS)
	sprite_frames.set_animation_loop(animation_name, LOOP)

	var dir := DirAccess.open(folder_path)
	var files := []

	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.to_lower().ends_with(".png"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()

	files.sort_custom(_numeric_sort) # VERY important

	for file in files:
		var tex := load(folder_path + "/" + file)
		if tex:
			sprite_frames.add_frame(animation_name, tex)


## Import one animation folder safely
func load_or_create_sprite_frames(npc_path: String, npc_id: String) -> SpriteFrames:
	var save_path := npc_path + "/" + npc_id + ".tres"

	if ResourceLoader.exists(save_path):
		return load(save_path) as SpriteFrames
	var sprite_frames = SpriteFrames.new()
	
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
		
	return sprite_frames



func _numeric_sort(a: String, b: String) -> int:
	# Remove extension, convert to int
	var num_a := int(a.get_basename())
	var num_b := int(b.get_basename())
	if num_a < num_b:
		return true
	return false
