extends KinematicBody2D

enum throw_state {
  HOLDING,
  THROWING,
  SUSPENDING,
  RETURNING
}

var current_throw_state = throw_state.HOLDING setget set_throw_state

var hold_offset = Vector2(6, 0)
var dir = Vector2(1, 0)
var motion = Vector2(0, 0)

var rotation_force_deg = 10

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
  dir = parent.direction
  match current_throw_state:
    throw_state.THROWING:
      handle_throw_state_throwing()
    throw_state.SUSPENDING:
      handle_throw_state_suspending()
    throw_state.RETURNING:
      handle_throw_state_returning()
    throw_state.HOLDING, _:
     handle_throw_state_holding()

func handle_throw_state_holding():
  if rotation != 0:
    rotation = 0
  # position = parent.position + (hold_offset * dir)

func handle_throw_state_throwing():
  pass

func handle_throw_state_suspending():
  pass

func handle_throw_state_returning():
  pass

func set_throw_state(value):
  if throw_state.has(value):
    current_throw_state = throw_state[value]
