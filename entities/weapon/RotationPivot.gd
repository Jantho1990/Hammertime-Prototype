extends Position2D

onready var parent = $".."

func _physics_process(delta):
  update_pivot_angle()

func update_pivot_angle():
  rotation = parent.parent.position.angle_to(parent.cursor_position)
