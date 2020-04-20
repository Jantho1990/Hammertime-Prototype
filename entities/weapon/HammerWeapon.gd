extends KinematicBody2D

enum throw_state {
  HOLDING,
  THROWING,
  SUSPENDING,
  RETURNING
}

var current_throw_state = throw_state.HOLDING setget set_throw_state

var hold_offset = Vector2(12, 0)
var dir = Vector2(1, 0)
var throwing = false
var throw_acceleration = 20
var throw_max_speed = 100
var throw_range = 200
var thrown_dir = dir
var throw_destination = Vector2(0, 0)
var cursor_position = Vector2(0, 0)
var motion = Vector2(0, 0)

var rotation_force_deg = 60

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
  dir = parent.direction
  cursor_position = get_local_mouse_position()
  match current_throw_state:
    throw_state.THROWING:
      handle_throw_state_throwing()
    throw_state.SUSPENDING:
      handle_throw_state_suspending()
    throw_state.RETURNING:
      handle_throw_state_returning()
    throw_state.HOLDING, _:
     handle_throw_state_holding()
  
  if Input.is_action_just_pressed('weapon_throw') and \
    current_throw_state == throw_state.HOLDING:
    current_throw_state = throw_state.THROWING

func handle_throw_state_holding():
  if rotation != 0:
    rotation = 0
  update_position()

func handle_throw_state_throwing():
  rotation_degrees += rotation_force_deg * dir.x
  update_position()
  
  tween_throw()
  if not throwing:
    # Launch the weapon
    pass
  elif test_move(transform, global_position):
    print('COLLISION', global_position)
    pass

func handle_throw_state_suspending():
  rotation_degrees += rotation_force_deg * thrown_dir.x
  tween_suspend()

func handle_throw_state_returning():
  rotation_degrees += rotation_force_deg * thrown_dir.x
  tween_return()

func tween_throw():
  if not $ThrowTween.is_active():
    throwing = true
    thrown_dir = dir
    var start = position
    var destination = (position + (Vector2(200, 1) * thrown_dir)).rotated(position.angle_to(cursor_position))
    var collision = move_and_collide(destination, true, true, true)
    if collision:
      destination = collision.travel
    $ThrowTween.interpolate_property(self, 'position', start, destination, 0.2)
    $ThrowTween.interpolate_callback(self, 0.2, '_on_Tween_throwing_stop')
    $ThrowTween.start()

func tween_suspend():
  if not $ThrowTween.is_active():
    $ThrowTween.interpolate_callback(self, 0.2, '_on_Tween_suspending_stop')
    $ThrowTween.start()

func tween_return():
  if not $ThrowTween.is_active():
    var start = position
    var destination = Vector2(0, 0)
    $ThrowTween.interpolate_property(self, 'position', start, destination, 0.2)
    $ThrowTween.interpolate_callback(self, 0.2, '_on_Tween_returning_stop')
    $ThrowTween.start()

func _on_Tween_throwing_stop():
  current_throw_state = throw_state.SUSPENDING

func _on_Tween_suspending_stop():
  current_throw_state = throw_state.RETURNING

func _on_Tween_returning_stop():
  current_throw_state = throw_state.HOLDING

func update_position():
  position = hold_offset * dir

func set_throw_state(value):
  if throw_state.has(value):
    current_throw_state = throw_state[value]
