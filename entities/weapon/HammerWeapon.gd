extends KinematicBody2D

const UP = Vector2(0, -1)

enum throw_state {
  HOLDING,
  THROWING,
  SUSPENDING,
  RETURNING,
  MELEE
}

var current_throw_state = throw_state.HOLDING setget set_throw_state

var hold_offset = Vector2(-12, -6)
var dir = Vector2(1, 1)
var throwing = false
var returning = false
var throw_acceleration = 1
var throw_max_speed = 1600
var melee_range = 50
var melee_charge_delay = 1
var charge_delay_active = false
var throw_range = 400
var throw_travel_distance = 0
var thrown_dir = dir
var throw_origin_position = Vector2(0, 0)
var throw_target_position = Vector2(0, 0)
var cursor_position = Vector2(0, 0)
var motion = Vector2(0, 0)

var rotation_force_deg = 60
var __delta

onready var parent = get_parent()
onready var throwTween = $ThrowTween
onready var MeleeChargeDelay = $MeleeChargeDelay

# Called when the node enters the scene tree for the first time.
func _ready():
  GlobalSignal.listen('teleport', self, '_on_Teleport')
  MeleeChargeDelay.connect('timeout', self, '_on_Melee_charge_delay_timeout')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
  __delta = delta
  dir = parent.direction
  if dir.y <= 0:
    dir.y = 1
  cursor_position = get_local_mouse_position()
  # cursor_position = get_global_mouse_position()
  # GlobalSignal.dispatch('debug_label2', { 'text': dir })
  GlobalSignal.dispatch('debug_label', { 'text': current_throw_state })
  # GlobalSignal.dispatch('debug_label2', { 'text': current_throw_state })
  # GlobalSignal.dispatch('debug_label2', { 'text': $ThrowTween.is_active() })
  match current_throw_state:
    throw_state.THROWING:
      handle_throw_state_throwing()
    throw_state.SUSPENDING:
      handle_throw_state_suspending()
    throw_state.RETURNING:
      handle_throw_state_returning()
    throw_state.MELEE:
      handle_throw_state_melee()
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
  
  if Input.is_action_just_pressed('weapon_melee') or \
    Input.is_action_pressed('weapon_melee'):
      current_throw_state = throw_state.MELEE

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

func handle_throw_state_melee():
  var charging = !Input.is_action_just_pressed('weapon_melee') and \
    !charge_delay_active

  if not charging:
    melee_normal()
  else:
    breakpoint
    pass

func throw_weapon():
  throwing = true
  throw_origin_position = global_position
  thrown_dir = dir# * Vector2(-1, 1) # correct the x direction since dir is inverted
  throw_target_position.rotated(throw_target_position.angle() - throw_target_position.angle())
  $Sprite.rotation = 0
  # throw_target_position = (global_position + (Vector2(throw_range, 0) * thrown_dir)).rotated(global_position.angle_to_point(cursor_position))
  # var tvec = (position + cursor_position).normalized() * throw_range # * thrown_dir
  # throw_target_position = global_position + tvec
  # GlobalSignal.dispatch('debug_label', { 'text': String(tvec) + ' ' + String(cursor_position) + ' ' + String(thrown_dir) })
  calculate_throw_target('throw')
  release_weapon()
  calculate_motion()
  motion = move_and_slide(motion, UP)
  
func update_thrown_weapon():
  calculate_motion()
  motion = move_and_slide(motion, UP)

func release_weapon():
  GlobalSignal.dispatch('hammer_thrown', { 'hammer': self })

func calculate_throw_target(throw_type = 'throw'):
  var distance
  match throw_type:
    'throw': distance = throw_range
    'melee':   distance = melee_range
  
  var tvec = (position + cursor_position).normalized() * distance
  throw_target_position = global_position + tvec

func calculate_motion():
  var motion_velocity = throw_max_speed * __delta
  # motion = (Vector2(throw_max_speed, 0)).rotated(global_position.angle_to_point(throw_target_position))
  # motion = (position + (throw_target_position * thrown_dir)).clamped(throw_max_speed)
  motion = position.direction_to(throw_target_position) * throw_max_speed
  GlobalSignal.dispatch('debug_label2', { 'text': motion })
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
  position = hold_offset * dir
  position.y += sin(global.run_time / 0.15) * 4
  $Sprite.rotation = position.angle_to_point(cursor_position) - deg2rad(90)

func set_throw_state(value):
  if throw_state.has(value):
    current_throw_state = throw_state[value]

func melee_normal():
  if not throwing:
    throwing = true
    calculate_throw_target('melee')
    release_weapon()
    calculate_motion()
  else:
    update_thrown_weapon()
  
  if collision_detected() or throw_travel_distance == melee_range:
    current_throw_state = throw_state.RETURNING

func start_melee_charge_delay():
  MeleeChargeDelay.start(melee_charge_delay)
  charge_delay_active = true

func _on_Melee_charge_delay_timeout():
  charge_delay_active = false
