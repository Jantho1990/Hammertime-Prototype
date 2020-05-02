extends KinematicBody2D

const UP = Vector2(0, -1)
const MELEE_RETURN_TIME = 0.05
const THROW_RETURN_TIME = 0.2

enum throw_state {
  HOLDING,
  THROWING,
  SUSPENDING,
  RETURNING,
  MELEE
}

var current_throw_state = throw_state.HOLDING setget set_throw_state
var next_throw_state = -1

var hold_offset = Vector2(-12, -6)
var dir = Vector2(1, 1)
var throwing = false
var returning = false
var rotating = false

var throw_acceleration = 1
var throw_max_speed = 1600
var throw_range = 400
var throw_travel_distance = 0
var return_time = THROW_RETURN_TIME
var thrown_dir = dir
var throw_origin_position = Vector2(0, 0)
var throw_target_position = Vector2(0, 0)
var cursor_position = Vector2(0, 0)

var meleeing = false
var melee_charging = false
var melee_charge_force = 0
var melee_held = false
var melee_range = 100
var melee_max_speed = 3200
var melee_charge_delay = 0.15
var charge_delay_active = false

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
  
  if rotating:
    rotation_degrees += rotation_force_deg * dir.x

  # cursor_position = get_global_mouse_position()
  # GlobalSignal.dispatch('debug_label2', { 'text': dir })
  GlobalSignal.dispatch('debug_label', { 'text': current_throw_state })
  # GlobalSignal.dispatch('debug_label2', { 'text': current_throw_state })
  # GlobalSignal.dispatch('debug_label2', { 'text': $ThrowTween.is_active() })
  calculate_throw_state()
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

# Calculates if the current throw state should be changed.
func calculate_throw_state():
  if Input.is_action_just_pressed('weapon_throw') and \
    current_throw_state == throw_state.HOLDING:
      current_throw_state = throw_state.THROWING
  elif Input.is_action_pressed('weapon_melee') and \
    current_throw_state == throw_state.HOLDING:
      current_throw_state = throw_state.MELEE
  elif (collision_detected() or throw_travel_distance == throw_range) and \
    current_throw_state == throw_state.THROWING:
      current_throw_state = throw_state.SUSPENDING
  elif next_throw_state != -1:
    current_throw_state = next_throw_state
    next_throw_state = -1

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

func handle_throw_state_throwing():
  rotating = true
  # rotation_degrees += rotation_force_deg * dir.x
  
  if not throwing and not meleeing:
    return_time = THROW_RETURN_TIME
    throw_weapon()
  else:
    update_thrown_weapon()

  GlobalSignal.dispatch('debug_label2', { 'text': throw_travel_distance })
  
func handle_throw_state_suspending():
  # rotation_degrees += rotation_force_deg * thrown_dir.x
  tween_suspend()

func handle_throw_state_returning():
  # rotation_degrees += rotation_force_deg * thrown_dir.x
  tween_return()

func handle_throw_state_melee():
  if !meleeing:
    meleeing = true
    return_time = MELEE_RETURN_TIME
    start_melee_charge_delay()
  
  # If this is the first frame in this state, defer to next frame
  # so we can detect if hammer is being charged.
  if Input.is_action_just_pressed('weapon_melee'):
    return
  
  if Input.is_action_pressed('weapon_melee'):
    melee_held = true
  elif Input.is_action_just_released('weapon_melee'):
    melee_held = false

  var charging = melee_held and \
    !charge_delay_active and \
    !throwing

  if collision_detected() or throw_travel_distance >= melee_range:
    next_throw_state = throw_state.RETURNING
  
  if (not charging and not melee_held) or Input.is_action_just_released('weapon_melee'):
    print('NORMAL MELEE')
    melee_normal()
  elif charging:
    print('CHARGING: ', charging)
    print('WEAPON PRESSED: ', Input.is_action_pressed('weapon_melee'))
    print('WEAPON JUST PRESSED: ', Input.is_action_just_pressed('weapon_melee'))
    print('CHARGE DELAY: ', charge_delay_active)
    print('THROWING: ', throwing)
    # breakpoint
    pass
  
  GlobalSignal.dispatch('debug_label2', { 'text': throw_travel_distance })

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
  var max_speed = melee_max_speed if meleeing else throw_max_speed
  # motion = (Vector2(throw_max_speed, 0)).rotated(global_position.angle_to_point(throw_target_position))
  # motion = (position + (throw_target_position * thrown_dir)).clamped(throw_max_speed)
  motion = position.direction_to(throw_target_position) * max_speed
  # GlobalSignal.dispatch('debug_label2', { 'text': motion })
  throw_travel_distance = min(throw_travel_distance + (max_speed * __delta), throw_range)

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
    GlobalSignal.dispatch('hammer_returned', { 'hammer': self })
    # breakpoint
    # var start = position
    # var start = global_position
    var start = offset_position
    var destination = hold_offset * dir
    # var destination = parent.position
    # var destination = parent.global_position
    $ThrowTween.interpolate_property(self, 'position', start, destination, return_time)
    # $ThrowTween.interpolate_property(self, 'global_position', start, destination, return_time)
    $ThrowTween.interpolate_callback(self, return_time, '_on_Tween_returning_stop')
    $ThrowTween.start()

func _on_Tween_throwing_stop():
  next_throw_state = throw_state.SUSPENDING

func _on_Tween_suspending_stop():
  next_throw_state = throw_state.RETURNING

func _on_Tween_returning_stop():
  next_throw_state = throw_state.HOLDING
  throwing = false
  meleeing = false
  returning = false
  rotating = false
  motion = Vector2(0, 0)
  throw_travel_distance = 0
  update_position()
  stop_melee_charge_delay()
  print('STOPPED')

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
    # melee_held = true
    # meleeing = true
    calculate_throw_target('melee')
    release_weapon()
    calculate_motion()
    # start_melee_charge_delay()
  elif throwing:
    update_thrown_weapon()

func melee_charged():
  pass

func start_melee_charge_delay():
  MeleeChargeDelay.start(melee_charge_delay)
  charge_delay_active = true

func stop_melee_charge_delay():
  MeleeChargeDelay.stop()
  charge_delay_active = false

func _on_Melee_charge_delay_timeout():
  charge_delay_active = false
