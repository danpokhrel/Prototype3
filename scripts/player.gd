class_name Player
extends CharacterBody2D

## Joust-style movement: unlimited flapping, gravity, and heavy momentum.
## Speed builds slowly, barely bleeds off in the air, and carries into
## wall bounces and the dash.

signal flapped(flap_type: StringName)
signal dashed(dash_type: StringName)
signal landed(impact_speed: float)

@export_group("Horizontal")
@export var max_speed: float = 400.0
@export var ground_acceleration: float = 900.0
## Low air acceleration makes turning around in the air slow and committed.
@export var air_acceleration: float = 350.0
@export var ground_friction: float = 700.0
## Very low: speed carries through the air. Lower this for more momentum.
@export var air_friction: float = 25.0

@export_group("Flight")
@export var gravity: float = 700.0
## Upward speed added by each flap. Tap as fast as you like.
@export var flap_impulse: float = 260.0
@export var max_rise_speed: float = -380.0
@export var max_fall_speed: float = 500.0

@export_group("Bounce")
## Fraction of speed kept when you hit a wall (0 = stop, 1 = perfect bounce).
@export_range(0.0, 1.0) var wall_bounce: float = 0.6
@export_range(0.0, 1.0) var ceiling_bounce: float = 0.3

@export_group("Dash")
## Dash speed. A faster current speed in the same direction is kept.
@export var dash_speed: float = 650.0
## Gravity is off while dashing, so the dash travels straight.
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.8

@export_group("Input")
@export var input_left: StringName = &"move_left"
@export var input_right: StringName = &"move_right"
@export var input_flap: StringName = &"jump"
@export var input_dash: StringName = &"dash"

@export_group("Screen wrap")
@export var wrap_horizontal: bool = true
@export var wrap_vertical: bool = false
## How far past the edge the player must be before wrapping, in pixels.
@export var wrap_margin: float = 8.0
## Leave empty to wrap at the camera view. Set a Rect2 (in world pixels) to wrap
## at fixed arena bounds instead, for example (0, 0, 480, 288).
@export var custom_wrap_bounds: Rect2 = Rect2()

@export var death_tile_layer: TileMapLayer

var facing: float = 1.0
var is_dashing: bool = false
var dash_direction: float = 1.0
var respawn_position: Vector2

var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0


func _ready() -> void:
	respawn_position = global_position
	for action in [input_left, input_right, input_flap, input_dash]:
		if not InputMap.has_action(action):
			push_warning("%s: input action '%s' doesn't exist in the Input Map" % [name, action])


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(input_left, input_right)
	var was_grounded: bool = is_on_floor()
	if direction != 0.0:
		facing = direction

	# Dash timers and start.
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	if is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			is_dashing = false
	if Input.is_action_just_pressed(input_dash) and _dash_cooldown_timer == 0.0 and not is_dashing:
		_start_dash(direction)

	_move_horizontal(direction, was_grounded, delta)

	# Gravity (off during a dash) and flap.
	if not is_dashing:
		velocity.y += gravity * delta
	if Input.is_action_just_pressed(input_flap):
		velocity.y -= flap_impulse
		flapped.emit(&"neutral")
	velocity.y = clampf(velocity.y, max_rise_speed, max_fall_speed)

	var before: Vector2 = velocity
	move_and_slide()

	# Keep momentum when hitting walls and ceilings instead of stopping dead.
	if is_on_wall() and absf(before.x) > 40.0 and before.x * get_wall_normal().x < 0.0:
		velocity.x = signf(get_wall_normal().x) * absf(before.x) * wall_bounce
	if is_on_ceiling() and before.y < 0.0:
		velocity.y = -before.y * ceiling_bounce
	if is_on_floor() and not was_grounded:
		landed.emit(before.y)

	_check_death_tiles()
	_wrap_around_screen()


## Accelerates toward the held direction up to max_speed, but never clips speed
## that is already higher (dash, wall bounce). Speed bleeds off through friction.
func _move_horizontal(direction: float, grounded: bool, delta: float) -> void:
	var accel: float = ground_acceleration if grounded else air_acceleration
	var friction: float = ground_friction if grounded else air_friction

	if direction != 0.0 and (signf(velocity.x) != direction or absf(velocity.x) < max_speed):
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	if direction == 0.0 or absf(velocity.x) > max_speed:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _start_dash(direction: float) -> void:
	dash_direction = direction if direction != 0.0 else facing
	is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	velocity.x = dash_direction * maxf(dash_speed, absf(velocity.x) if signf(velocity.x) == dash_direction else 0.0)
	velocity.y = 0.0
	dashed.emit(&"horizontal")


func _check_death_tiles() -> void:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == death_tile_layer:
			die()
			return


func die() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	is_dashing = false
	_dash_cooldown_timer = 0.0
	
func _wrap_around_screen() -> void:
	var view: Rect2 = custom_wrap_bounds
	if view.size == Vector2.ZERO:
		var viewport: Viewport = get_viewport()
		view = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()

	if wrap_horizontal:
		if global_position.x < view.position.x - wrap_margin:
			global_position.x = view.end.x + wrap_margin
		elif global_position.x > view.end.x + wrap_margin:
			global_position.x = view.position.x - wrap_margin
	if wrap_vertical:
		if global_position.y < view.position.y - wrap_margin:
			global_position.y = view.end.y + wrap_margin
		elif global_position.y > view.end.y + wrap_margin:
			global_position.y = view.position.y - wrap_margin
