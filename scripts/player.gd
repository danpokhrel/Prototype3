class_name Player
extends CharacterBody2D

## Horizontal movement
@export var ground_acceleration: float = 1200.0
@export var air_acceleration: float = 600.0
@export var ground_friction: float = 1000.0
@export var air_friction: float = 60.0
@export var max_speed: float = 350.0

## Flapping movement
@export var flap_impulse: float = 280.0       # upward velocity added per tap
@export var gravity: float = 900.0
@export var max_fall_speed: float = 500.0
@export var max_rise_speed: float = -450.0

## Dash settings
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 2.0

## Input actions
@export var input_left: StringName = &"move_left"
@export var input_right: StringName = &"move_right"
@export var input_flap: StringName = &"jump"
@export var input_dash: StringName = &"dash"

## Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(input_left, input_right)
	var grounded: bool = is_on_floor()

	# Dash cooldown
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	# Start dash
	if Input.is_action_just_pressed(input_dash) \
	and dash_cooldown_timer == 0.0 \
	and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

		if direction != 0.0:
			dash_direction = direction
		else:
			dash_direction = signf(velocity.x)

		if dash_direction == 0.0:
			dash_direction = 1.0

	# Horizontal movement
	if is_dashing:
		velocity.x = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		var accel: float = ground_acceleration if grounded else air_acceleration
		var fric: float = ground_friction if grounded else air_friction

		if direction != 0.0:
			velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# Gravity
	velocity.y += gravity * delta

	if Input.is_action_just_pressed(input_flap):
		velocity.y = maxf(velocity.y - flap_impulse, max_rise_speed)

	# Clamp vertical velocity
	velocity.y = clampf(velocity.y, max_rise_speed, max_fall_speed)

	move_and_slide()
