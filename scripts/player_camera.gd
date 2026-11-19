class_name PlayerCamera
extends Camera2D

## Speed-reactive camera: zooms out slightly with speed, looks ahead in the
## movement direction, kicks opposite the action impulse, and shakes on hard
## landings, bounces, and dashes.

## Zoom range: at rest the zoom is zoom_at_rest; at zoom_speed_ref it is
## zoom_at_top_speed.
@export var zoom_at_rest: float = 2.6
@export var zoom_at_top_speed: float = 0.85
@export var zoom_speed_ref: float = 800.0
@export var zoom_smoothing: float = 4.0

## Lookahead: the camera drifts this many pixels in the movement direction.
@export var lookahead_distance: float = 45.0
@export var lookahead_smoothing: float = 3.0

## Shake on hard landings and dashes.
@export var landing_shake_impact_ref: float = 600.0
@export var max_shake_strength: float = 6.0
@export var shake_decay: float = 8.0

## Directional kick: the camera lurches a short distance opposite the impulse
## of a flap, dash, or bounce (Vlambeer camera kick).
@export var kick_distance: float = 6.0
@export var kick_recovery: float = 10.0

## The player this camera follows. Defaults to the parent node.
@export var player_path: NodePath = ^".."

## Vertical position of the player on screen: 0.5 is the middle, 1.0 is the bottom edge.
@export_range(0.5, 0.95) var player_screen_y: float = 0.8

var _player: Player
var _lookahead: Vector2 = Vector2.ZERO
var _shake: Vector2 = Vector2.ZERO
var _shake_strength: float = 0.0
var _kick: Vector2 = Vector2.ZERO


## Resolves the player and connects to its feel signals.
func _ready() -> void:
	_player = get_node_or_null(player_path) as Player
	if _player == null:
		push_warning("PlayerCamera: no Player found at %s" % player_path)
		set_process(false)
		return
	_player.landed.connect(_on_player_landed)
	_player.bounced.connect(_on_player_bounced)
	_player.dashed.connect(_on_player_dashed)
	_player.flapped.connect(_on_player_flapped)


## Smooths zoom, lookahead, shake and kick into the camera offset.
func _process(delta: float) -> void:
	var velocity: Vector2 = _player.velocity
	var speed: float = velocity.length()
	var speed_frac: float = clampf(speed / zoom_speed_ref, 0.0, 1.0)

	var target_zoom: float = lerpf(zoom_at_rest, zoom_at_top_speed, speed_frac)
	var zoom_current: float = lerpf(zoom.x, target_zoom,
			_smoothing_weight(zoom_smoothing, delta))
	zoom = Vector2(zoom_current, zoom_current)

	var target_lookahead: Vector2 = velocity.normalized() * lookahead_distance * speed_frac
	_lookahead = _lookahead.lerp(target_lookahead,
			_smoothing_weight(lookahead_smoothing, delta))

	_shake_strength = maxf(_shake_strength - shake_decay * _shake_strength * delta, 0.0)
	if _shake_strength > 0.01:
		_shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	else:
		_shake = Vector2.ZERO

	_kick = _kick.lerp(Vector2.ZERO, _smoothing_weight(kick_recovery, delta))
	
	# Shift the view up so the player sits low on screen. Divide by zoom so it
	# stays correct as the zoom changes with speed.
	var framing_y: float = (0.57 - player_screen_y) * get_viewport_rect().size.y / zoom_current

	offset = Vector2(0.0, framing_y) + _lookahead + _shake + _kick

## Adds shake proportional to the impact, never weaker than what is running.
func _add_shake(impact_speed: float, multiplier: float) -> void:
	var reference: float = maxf(landing_shake_impact_ref, 0.001)
	var strength: float = (impact_speed / reference) * max_shake_strength * multiplier
	_shake_strength = maxf(_shake_strength, clampf(strength, 0.0, max_shake_strength))


## Kicks off a shake proportional to the impact speed.
func _on_player_landed(impact_speed: float) -> void:
	_add_shake(impact_speed, 1.0)


## Bounces shake harder than plain landings: they are the skill moments.
func _on_player_bounced(impact_speed: float) -> void:
	_add_shake(impact_speed, 1.5)
	_kick = Vector2.DOWN * kick_distance


## Small fixed shake plus a kick opposite the dash impulse; down dashes kick
## upward instead (the screen lurches against the slam).
func _on_player_dashed(dash_type: StringName) -> void:
	_shake_strength = maxf(_shake_strength, max_shake_strength * 0.4)
	if dash_type == &"down":
		_kick = Vector2.UP * kick_distance
	else:
		_kick = Vector2(-_player.dash_direction, 0.0) * kick_distance


## A small kick opposite the flap impulse; strongest for timed flaps.
func _on_player_flapped(flap_type: StringName) -> void:
	var strength: float = kick_distance * 0.5
	if flap_type == &"timed":
		strength = kick_distance
	elif flap_type == &"dive":
		strength = kick_distance * 0.8
	_kick = Vector2.UP * strength


## Frame-rate independent interpolation weight for a smoothing rate.
func _smoothing_weight(rate: float, delta: float) -> float:
	return 1.0 - exp(-rate * delta)
