extends KinematicBody2D

const UP = Vector2(0, -1)

enum throw_state {
  HOLDING,
  THROWING,
  SUSPENDING,
  RETURNING
}

var current_throw_state = throw_state.HOLDING setget set_throw_state

var hold_offset = position # Vector2(12, 0)
var dir = Vector2(1, 0)
var throwing = false
var returning = false
var throw_acceleration = 1
var throw_max_speed = 1600
var throw_range = 400
var throw_travel_distance = 0
var thrown_dir = dir
var throw_origin_position = Vector2(0, 0)
var throw_target_position = Vector2(0, 0)
var cursor_position = Vector2(0, 0)
var motion = Vector2(0, 0)

var rotation_force_deg = 60
var __delta

onready var parent = get_parent().get_parent().get_parent()
onready var pivot = get_parent()
onready var throwTween = $ThrowTween

# Called when the node enters the scene tree for the first time.
func _ready():
  GlobalSignal.listen('teleport', self, '_on_Teleport')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
  __delta = delta
  dir = parent.direction
  cursor_position = get_local_mouse_position()
  # GlobalSignal.dispatch('debug_label', { 'text': current_throw_state })
  # GlobalSignal.dispatch('debug_label2', { 'text': current_throw_state })
  # GlobalSignal.dispatch('debug_label2', { 'text': $ThrowTween.is_active() })
  match current_throw_state:
    throw_state.THROWING:
      handle_throw_state_throwing()
    throw_state.SUSPENDING:
      handle_throw_state_suspending()
    throw_state.RETURNING:
      handle_throw_state_returning()
    throw_state.HOLDING, _:
     handle_throw_state_holding()

func _on_Teleport():
  if current_throw_state != throw_state.HOLDING:
    parent.motion = Vector2(0, 0)
    GlobalSignal.dispatch('hammer_returned', { 'hammer': self })
    $ThrowTween.stop_all()
    $ThrowTween.reset_all()
    _on_Tween_returning_stop()

func handle_throw_state_holding():
  if rotation != 0:
    rotation = 0
  update_position()

  if Input.is_action_just_pressed('weapon_throw') and \
    current_throw_state == throw_state.HOLDING:
      current_throw_state = throw_state.THROWING

func handle_throw_state_throwing():
  rotation_degrees += rotation_force_deg * dir.x
  
  if not throwing:
    throw_weapon()
  else:
    update_thrown_weapon()
  
  if collision_detected() or throw_travel_distance == throw_range:
    current_throw_state = throw_state.SUSPENDING
  
func handle_throw_state_suspending():
  rotation_degrees += rotation_force_deg * thrown_dir.x
  tween_suspend()

func handle_throw_state_returning():
  rotation_degrees += rotation_force_deg * thrown_dir.x
  tween_return()

func throw_weapon():
  throwing = true
  throw_origin_position = global_position
  thrown_dir = dir
  throw_target_position.rotated(throw_target_position.angle() - throw_target_position.angle())
  throw_target_position = (global_position + (Vector2(throw_range, 0) * dir)).rotated(position.angle_to(cursor_position))
  GlobalSignal.dispatch('hammer_thrown', { 'hammer': self })
  calculate_motion()
  motion = move_and_slide(motion, UP)
  
func update_thrown_weapon():
  calculate_motion()
  motion = move_and_slide(motion, UP)

func calculate_motion():
  var motion_velocity = throw_max_speed * __delta
  motion = (Vector2(throw_max_speed, 0) * thrown_dir).rotated(global_position.angle_to(throw_target_position))
  throw_travel_distance = min(throw_travel_distance + (throw_max_speed * __delta), throw_range)

func collision_detected():
  return get_slide_count() > 0

func return_weapon():
  calculate_motion()
  motion = move_and_slide(motion, UP)

func calculate_return_motion():
  motion = (Vector2(throw_max_speed, 0) * thrown_dir).rotated(global_position.angle_to(parent.position))
  throw_travel_distance = min(throw_travel_distance + (throw_max_speed * __delta), throw_range)

func tween_throw():
  if not $ThrowTween.is_active():
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
  if not returning:
    returning = true
    # GlobalSignal.dispatch('debug_label2', { 'text': 'fish' })
    # breakpoint
    var offset_position = Vector2(0, 0) + (global_position - parent.global_position)
    var gb = global_position
    var pgb = parent.global_position
    GlobalSignal.dispatch('hammer_returned', { 'hammer': self })
    # breakpoint
    # var start = position
    # var start = global_position
    var start = offset_position
    var destination = hold_offset * dir
    # var destination = parent.position
    # var destination = parent.global_position
    $ThrowTween.interpolate_property(self, 'position', start, destination, 0.2)
    # $ThrowTween.interpolate_property(self, 'global_position', start, destination, 0.2)
    $ThrowTween.interpolate_callback(self, 0.2, '_on_Tween_returning_stop')
    $ThrowTween.start()

func _on_Tween_throwing_stop():
  current_throw_state = throw_state.SUSPENDING

func _on_Tween_suspending_stop():
  current_throw_state = throw_state.RETURNING

func _on_Tween_returning_stop():
  current_throw_state = throw_state.HOLDING
  throwing = false
  returning = false
  motion = Vector2(0, 0)
  throw_travel_distance = 0
  update_position()

func update_position():
  # pass
  position = pivot.position
  # GlobalSignal.dispatch('debug_label2', { 'text': global_position })
  # position = hold_offset * dir

func set_throw_state(value):
  if throw_state.has(value):
    current_throw_state = throw_state[value]
