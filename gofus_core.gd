extends Node

var battlefield: Battlefield
var gapi: Gapi

func _ready() -> void:
	battlefield = Battlefield.new()
	battlefield.name = "Battlefield"
	get_tree().root.add_child.call_deferred(battlefield)

	gapi = Gapi.new()
	gapi.name = "Gapi"
	get_tree().root.add_child.call_deferred(gapi)