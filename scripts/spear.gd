class_name MomentumSpear
extends Node2D

## Godot 4: attach as a child of the CharacterBody2D player.
## Left mouse = thrust, right mouse = sweep. Actual collision velocity determines damage.
@export var length: float = 68.0
@export var thickness: float = 10.0
@export var thrust_distance: float = 34.0
@export var thrust_duration: float = 0.24
@export var swing_duration: float = 0.34
@export var swing_arc_degrees: float = 135.0
@export var attack_cooldown: float = 0.12
@export var minimum_impact_speed: float = 90.0
@export var stab_damage_per_speed: float = 0.055
@export var swing_damage_per_speed: float = 0.045
## Physics layers the spear can hit: 1 = world props, 2 = hittables.
@export var collision_mask: int = 3

var _player: CharacterBody2D
var _hit_area: Area2D
var _hit_shape: CollisionShape2D
var _mode: String = ""
var _elapsed: float = 0.0
var _duration: float = 0.0
var _cooldown: float = 0.0
var _facing: float = 1.0
var _already_hit: Dictionary = {}
var _previous_tip: Vector2
var _tip_velocity: Vector2 = Vector2.ZERO
var _ready_to_measure: bool = false
var _sprite: Sprite2D
var _sprite_base: Vector2

func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if _player == null:
		push_error("MomentumSpear must be a child of CharacterBody2D")
		set_physics_process(false)
		return
	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = collision_mask
	_hit_area.monitoring = true
	_hit_area.monitorable = false
	add_child(_hit_area)
	_hit_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(length, thickness)
	_hit_shape.shape = rectangle
	_hit_shape.position.x = length * 0.5
	_hit_area.add_child(_hit_shape)
	_hit_area.body_entered.connect(_on_body_entered)
	_hit_area.area_entered.connect(_on_area_entered)
	_hit_shape.disabled = true
	_previous_tip = _tip_world_position()
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite:
		_sprite_base = _sprite.position

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _mode == "" and _cooldown <= 0.0:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_start_attack("stab")
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_start_attack("swing")

	if _mode == "":
		var direction := Input.get_axis(
			_player.input_left,
			_player.input_right
		)
		if direction != 0.0:
			_facing = direction
		elif absf(_player.velocity.x) > 25.0:
			_facing = signf(_player.velocity.x)
			
		rotation = 0.0 if _facing > 0.0 else PI
			
		_hit_area.position = Vector2.ZERO
		_hit_shape.set_deferred("disabled", true)
	else:
		_elapsed += delta
		var progress: float = minf(_elapsed / _duration, 1.0)
		if _mode == "stab":
			rotation = 0.0 if _facing > 0.0 else PI
			_hit_area.position.x = thrust_distance * sin(progress * PI)
		else:
			var start_angle: float = -deg_to_rad(swing_arc_degrees) * 0.5
			var angle: float = lerpf(start_angle, -start_angle, progress)
			rotation = (0.0 if _facing > 0.0 else PI) + angle * _facing
			_hit_area.position = Vector2.ZERO
		if progress >= 1.0:
			_finish_attack()

	var current_tip := _tip_world_position()
	if _ready_to_measure and delta > 0.0:
		_tip_velocity = (current_tip - _previous_tip) / delta
	_previous_tip = current_tip
	_ready_to_measure = true
	_update_sprite()
	
func _start_attack(attack_type: String) -> void:
	_mode = attack_type
	_elapsed = 0.0
	_duration = thrust_duration if attack_type == "stab" else swing_duration
	_already_hit.clear()
	if absf(_player.velocity.x) > 25.0:
		_facing = signf(_player.velocity.x)
	_hit_shape.set_deferred("disabled", false)

func _finish_attack() -> void:
	_mode = ""
	_cooldown = attack_cooldown
	_hit_shape.set_deferred("disabled", true)

func _tip_world_position() -> Vector2:
	return _hit_area.to_global(Vector2(length, 0.0)) if _hit_area != null else global_position

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(target: Node2D) -> void:
	if _mode == "" or target == _player or _player.is_ancestor_of(target):
		return
	var receiver: Node = target
	if not receiver.has_method("take_damage") and target.get_parent() != null and target.get_parent().has_method("take_damage"):
		receiver = target.get_parent()
	if not receiver.has_method("take_damage"):
		return
	var key: int = receiver.get_instance_id()
	if _already_hit.has(key):
		return

	var target_velocity := Vector2.ZERO
	if receiver is CharacterBody2D:
		target_velocity = (receiver as CharacterBody2D).velocity
	elif receiver is RigidBody2D:
		target_velocity = (receiver as RigidBody2D).linear_velocity
	var relative_tip_velocity := _tip_velocity - target_velocity
	var forward := Vector2.RIGHT.rotated(global_rotation)
	var axial_speed := maxf(0.0, relative_tip_velocity.dot(forward))
	var tangential_speed := absf(relative_tip_velocity.cross(forward))
	var impact_speed: float = axial_speed if _mode == "stab" else tangential_speed
	if impact_speed < minimum_impact_speed:
		return
	_already_hit[key] = true
	var damage: float = (impact_speed - minimum_impact_speed) * (stab_damage_per_speed if _mode == "stab" else swing_damage_per_speed)
	receiver.call("take_damage", damage)
	
func _update_sprite() -> void:
	if _sprite == null:
		return
	# Follow the thrust, since the hit area slides forward during a stab.
	# Facing left rotates the node 180 degrees, which would put the art
	# upside down and mirror any vertical offset, so correct both.
	_sprite.position = Vector2(
		_sprite_base.x + _hit_area.position.x,
		_sprite_base.y * _facing
	)
	_sprite.flip_v = _facing < 0.0
