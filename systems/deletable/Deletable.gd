extends Node

###
# Dependent on:
# - GlobalSignal
# - a parent
###

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
  GlobalSignal.listen('delete_unit', self, '_on_Delete_unit')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Delete_unit(_data):
  if Selection.selected_entity == parent: # or Selection.previously_selected_entity == parent:
    var selected_entity = Selection.selected_entity
    Selection.clear_selection()
    GlobalSignal.dispatch('remove_' + selected_entity.name, { 'entity': selected_entity })
    parent.queue_free()
