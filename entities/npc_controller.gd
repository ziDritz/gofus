class_name NPCController
extends EntityController

# NPC-specific
@export var dialogue_id: String = ""
@export var shop_id: String = ""
@export var quest_giver: bool = false


func _ready() -> void:
	super._ready()
	entity_data.entity_type = "npc"


## Handle interaction
func interact(interactor_id: String) -> void: 
	
	if not dialogue_id.is_empty():
		EventBus.dialogue_started.emit(entity_id, dialogue_id)
	
	if shop_id and not shop_id.is_empty():
		# Open shop UI
		pass
	
	if quest_giver:
		# Check for quests
		pass
