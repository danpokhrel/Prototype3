
class_name Player
extends CharacterBody2D

## Horizontal movement
@export var acceleration: float = 1200.0
@export var friction: float = 300.0
@export var max_speed: float = 370.0

## Flapping movement
@export var flap_force: float = 3000.0
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

	# Dash cooldown
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	# Start dash
	if Input.is_action_just_pressed(input_dash) \
	and dash_cooldown_timer == 0.0 \
	and not is_dashing:

		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

		# Dash in the player direction
		if direction != 0.0:
			dash_direction = direction
		else:
			dash_direction = signf(velocity.x)

		# Dash right if stationary
		if dash_direction == 0.0:
			dash_direction = 1.0

	# Horizontal movement
	if is_dashing:
		velocity.x = dash_direction * dash_speed
	else:
		if direction != 0.0:
			velocity.x = move_toward(
				velocity.x,
				direction * max_speed,
				acceleration * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				friction * delta
			)

	# Dash duration
	if is_dashing:
		dash_timer -= delta

		if dash_timer <= 0.0:
			is_dashing = false

	# Vertical movement
	velocity.y += gravity * delta

	if Input.is_action_pressed(input_flap):
		velocity.y -= flap_force * delta

	# Clamp vertical velocity
	velocity.y = clampf(
		velocity.y,
		max_rise_speed,
		max_fall_speed
	)

	move_and_slide()
