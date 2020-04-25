extends CanvasLayer

func _unhandled_input(event):
  if Input.is_action_just_pressed('delete_construct'):
    if Selection.has_selection():
      var selected_entity = Selection.selected_entity
      GlobalSignal.dispatch('delete_unit', { 'entity': selected_entity })
    else:
      GlobalSignal.dispatch('delete_all_units')

  if event is InputEventMouseButton and event.pressed:
    if event.button_index == BUTTON_LEFT:
      if Selection.has_selection():
        Selection.clear_selection()
    elif event.button_index == BUTTON_RIGHT:
      if Selection.has_selection():
        GlobalSignal.dispatch('cancel_placement') # Triggers cancel placment logic in Placeable of selected unit.
