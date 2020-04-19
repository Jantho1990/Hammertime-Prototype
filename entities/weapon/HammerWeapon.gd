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
var motion = Vector2(0, 0)

var rotation_force_deg = 30

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
  dir = parent.direction
  print(current_throw_state)
  match current_throw_state:
    throw_state.THROWING:
      handle_throw_state_throwing()
    throw_state.SUSPENDING:
      handle_throw_state_suspending()
    throw_state.RETURNING:
      handle_throw_state_returning()
    throw_state.HOLDING, _:
     handle_throw_state_holding()
  
  if Input.is_action_pressed('weapon_throw'):
    current_throw_state = throw_state.THROWING

func handle_throw_state_holding():
  if rotation != 0:
    rotation = 0
  update_position()

func handle_throw_state_throwing():
  rotation_degrees += rotation_force_deg * dir.x
  update_position()
  if not $ThrowTween.is_active():
    $ThrowTween.interpolate_property(self, 'position', Vector2(position), (position + Vector2(100, 0)), 0.1)
    $ThrowTween.interpolate_property(self, 'position', (position + Vector2(100, 0)), (position + Vector2(100, 0)), 0.2, 0, 2, 0.2)
    $ThrowTween.interpolate_property(self, 'position', (position + Vector2(100, 0)), Vector2(position), 0.1, 0, 2, 0.3)
    $ThrowTween.interpolate_callback(self, 0.4, '_on_Tween_stop')
    $ThrowTween.start()

func handle_throw_state_suspending():
  pass

func handle_throw_state_returning():
  pass

func _on_Tween_stop():
  current_throw_state = throw_state.HOLDING

func update_position():
  position = hold_offset * dir

func set_throw_state(value):
  if throw_state.has(value):
    current_throw_state = throw_state[value]
