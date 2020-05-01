extends Position2D

onready var parent = $".."

# Called when the node enters the scene tree for the first time.
# func _ready():
  # update_pivot_angle()

func _physics_process(delta):
  update_pivot_angle()

func update_pivot_angle():
  GlobalSignal.dispatch('debug_label', { 'text': String(get_local_mouse_position()) + String(position) })
  GlobalSignal.dispatch('debug_label2', { 'text': rad2deg(Vector2(0, 0).angle_to_point(get_local_mouse_position())) })
  rotation_degrees = rad2deg(Vector2(0, 0).angle_to_point(get_local_mouse_position()))
