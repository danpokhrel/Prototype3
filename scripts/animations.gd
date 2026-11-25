extends AnimatedSprite2D

@export var walk_anim: StringName = &"Walk"
@export var jetpack_anim: StringName = &"Jetpack"
@export var idle_anim: StringName = &"idle"
@export var fall_anim: StringName = &"fall"
## Set to false if your art is drawn facing left.
@export var sprite_faces_right: bool = true
@export var walk_speed_threshold: float = 20.0
## Upward speed (negative y) needed to count as rising.
@export var rise_threshold: float = -10.0
## Walk animation plays faster at higher speed.
@export var scale_walk_with_speed: bool = true

var player: Player
var facing: float = 1.0


func _ready() -> void:
	player = get_parent() as Player
	if player == null:
		push_error("This sprite must be a direct child of the Player.")
		set_process(false)


func _process(_delta: float) -> void:
	_update_facing()
	_update_animation()


func _update_facing() -> void:
	if player.is_dashing:
		facing = player.dash_direction
	else:
		var dir: float = Input.get_axis(player.input_left, player.input_right)
		if dir != 0.0:
			facing = signf(dir)
	# Art faces right by default, so flip when facing left.
	flip_h = (facing < 0.0) == sprite_faces_right


func _update_animation() -> void:
	var on_floor: bool = player.is_on_floor()
	speed_scale = 1.0

	if not on_floor and player.velocity.y < rise_threshold:
		_play(jetpack_anim)          # going up only
	elif on_floor and absf(player.velocity.x) > walk_speed_threshold:
		_play(walk_anim)
		if scale_walk_with_speed:
			speed_scale = clampf(absf(player.velocity.x) / player.max_speed, 0.6, 1.5)
	elif on_floor:
		if sprite_frames.has_animation(idle_anim):
			_play(idle_anim)
		else:
			# No idle animation: hold the first walk frame.
			animation = walk_anim
			frame = 0
			pause()
	else:
		# Airborne and not rising: falling or hovering at the apex.
		if sprite_frames.has_animation(fall_anim):
			_play(fall_anim)
		else:
			animation = walk_anim
			frame = 0
			pause()


func _play(anim: StringName) -> void:
	if not sprite_frames.has_animation(anim):
		return
	if animation != anim:
		play(anim)
	elif not is_playing():
		play()
