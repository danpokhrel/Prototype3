class_name Player
extends CharacterBody2D
## Sidescroller player with tunable game-feel movement.
##
## Implements acceleration, variable jump height, coyote time, and jump
## buffering. All parameters are exported so prototypes can tune them in the
## Inspector without touching code.

## Horizontal acceleration in pixels per second squared.
@export var acceleration: float = 2200.0
## Horizontal deceleration when no input is held, in pixels per second squared.
@export var friction: float = 2600.0
## Maximum horizontal speed in pixels per second.
@export var max_speed: float = 240.0
## Initial upward velocity when jumping, in pixels per second.
@export var jump_velocity: float = -420.0
## Gravity while the jump button is held, in pixels per second squared.
@export var gravity: float = 980.0
## Gravity multiplier when the jump button is released mid-jump.
@export var gravity_multiplier: float = 2.0
## Downward velocity cap, in pixels per second.
@export var max_fall_speed: float = 700.0
## Time after leaving a ledge that jumping is still allowed, in seconds.
@export var coyote_time: float = 0.12
## Time before landing that a jump press is still remembered, in seconds.
@export var jump_buffer_time: float = 0.12

## Input action name for moving left, as configured in the Input Map.
@export var input_left: StringName = &"move_left"
## Input action name for moving right, as configured in the Input Map.
@export var input_right: StringName = &"move_right"
## Input action name for jumping, as configured in the Input Map.
@export var input_jump: StringName = &"jump"

## Seconds remaining on the coyote timer. Zero when the timer is expired.
var _coyote_timer: float = 0.0
## Seconds remaining on the jump buffer timer. Zero when the timer is expired.
var _jump_buffer_timer: float = 0.0


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(input_left, input_right)

	# Horizontal movement: accelerate toward the target speed, or apply friction.
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Variable jump height: heavier gravity while the jump button is not held.
	var gravity_now: float = gravity if Input.is_action_pressed(input_jump) else gravity * gravity_multiplier
	velocity.y = minf(velocity.y + gravity_now * delta, max_fall_speed)

	# Coyote time: jump is still allowed shortly after walking off a ledge.
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	if is_on_floor():
		_coyote_timer = coyote_time

	# Jump buffer: a jump press shortly before landing is remembered.
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	if Input.is_action_just_pressed(input_jump):
		_jump_buffer_timer = jump_buffer_time

	if _jump_buffer_timer > 0.0 and (_coyote_timer > 0.0 or is_on_floor()):
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		velocity.y = jump_velocity

	move_and_slide()
