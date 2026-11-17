class_name Level
extends Node2D

signal summit_reached

@export var player: CharacterBody2D
@export var level_width: float = 1280.0
## Scales every height in the layout. Raise it if the climb feels too easy,
## lower it if your flap tuning is floatier or weaker.
@export_range(0.5, 1.5, 0.05) var vertical_scale: float = 1.0
@export var start_position: Vector2 = Vector2(640.0, -48.0)

const THICKNESS: float = 16.0

const COLOR_SOLID := Color("2b2f4a")
const COLOR_PLATFORM := Color("5a7bff")
const COLOR_SHELF := Color("35d6a0")
const COLOR_HAZARD := Color("ff4d4d")
const COLOR_CHECKPOINT := Color("5a6075")
const COLOR_CHECKPOINT_ON := Color("ffd84d")
const COLOR_GOAL := Color("ff7bf0")

var checkpoint_position: Vector2


func _ready() -> void:
	checkpoint_position = start_position
	_build_level()
	if player:
		player.global_position = to_global(start_position)


# ---------------------------------------------------------------------------
# Layout. All heights are "pixels above the ground", positive going up.
# x is the horizontal center of the platform.
# ---------------------------------------------------------------------------
func _build_level() -> void:
	_build_bounds()

	# ZONE 1: Warm-up. Wide ledges, short steps, learn the flap rhythm.
	_platform(640, 120, 400)
	_platform(260, 240, 260)
	_platform(1020, 240, 260)
	_platform(640, 360, 260)
	_platform(260, 480, 220)
	_platform(1020, 480, 220)
	_shelf(640, 600)

	# ZONE 2: Zigzag. Narrow ledges, long horizontal carries between flaps.
	_platform(200, 750, 160)
	_platform(600, 900, 160)
	_platform(1000, 1050, 160)
	_platform(600, 1200, 160)
	_platform(200, 1350, 160)
	_shelf(640, 1500)

	# ZONE 3: Thorns. Spike pads sit on the direct line between ledges,
	# so you have to arc around them instead of mashing straight up.
	_platform(300, 1650, 120)
	_spikes(530, 1735, 140)
	_platform(760, 1800, 120)
	_spikes(600, 1885, 120)
	_platform(440, 1950, 120)
	_spikes(540, 2035, 120)
	_shelf(640, 2100)

	# ZONE 4: Dash gaps. Wide gaps with spikes below, so use the dash.
	_platform(160, 2230, 180)
	_spikes(360, 2190, 200)
	_platform(560, 2300, 180)
	_spikes(760, 2250, 220)
	_platform(960, 2370, 180)
	_platform(560, 2440, 180)
	_shelf(640, 2560)

	# ZONE 5: Summit tower. Small ledges, alternating sides, no wide shelves.
	_platform(440, 2700, 110)
	_platform(840, 2830, 110)
	_platform(440, 2960, 110)
	_platform(840, 3090, 110)
	_shelf(640, 3230, false)
	_goal(640, 3230)


# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------
func _build_bounds() -> void:
	var total_height: float = 3500.0 * vertical_scale
	# Ground (solid, not one-way)
	_body(Vector2(level_width / 2.0, 32.0), Vector2(level_width, 64.0), COLOR_SOLID, false)
	# Side walls
	var wall_center_y: float = -(total_height - 100.0) / 2.0
	_body(Vector2(-32.0, wall_center_y), Vector2(64.0, total_height + 100.0), COLOR_SOLID, false)
	_body(Vector2(level_width + 32.0, wall_center_y), Vector2(64.0, total_height + 100.0), COLOR_SOLID, false)


func _platform(x: float, height: float, width: float) -> void:
	var y: float = -height * vertical_scale
	_body(Vector2(x, y + THICKNESS / 2.0), Vector2(width, THICKNESS), COLOR_PLATFORM, true)


## Wide rest ledge. Optionally adds a checkpoint.
func _shelf(x: float, height: float, with_checkpoint: bool = true) -> void:
	var y: float = -height * vertical_scale
	_body(Vector2(x, y + THICKNESS / 2.0), Vector2(360.0, THICKNESS), COLOR_SHELF, true)
	if with_checkpoint:
		_checkpoint(x, y)


func _spikes(x: float, height: float, width: float) -> void:
	var y: float = -height * vertical_scale
	var area := _area(Vector2(x, y + 10.0), Vector2(width, 20.0), COLOR_HAZARD)
	area.body_entered.connect(_on_hazard_entered)


func _checkpoint(x: float, shelf_top_y: float) -> void:
	var area := _area(Vector2(x, shelf_top_y - 45.0), Vector2(40.0, 90.0), COLOR_CHECKPOINT)
	var marker: ColorRect = area.get_child(1)
	var spawn := Vector2(x, shelf_top_y - 40.0)
	area.body_entered.connect(_on_checkpoint_entered.bind(spawn, marker))


func _goal(x: float, height: float) -> void:
	var y: float = -height * vertical_scale
	var area := _area(Vector2(x, y - 50.0), Vector2(120.0, 100.0), COLOR_GOAL)
	area.body_entered.connect(_on_goal_entered)


func _body(center: Vector2, size: Vector2, color: Color, one_way: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = one_way
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)

	add_child(body)
	return body


func _area(center: Vector2, size: Vector2, color: Color) -> Area2D:
	var area := Area2D.new()
	area.position = center

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(visual)

	add_child(area)
	return area


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_hazard_entered(body: Node2D) -> void:
	if body == player:
		_respawn.call_deferred()


func _on_checkpoint_entered(body: Node2D, spawn: Vector2, marker: ColorRect) -> void:
	if body == player:
		checkpoint_position = spawn
		marker.color = COLOR_CHECKPOINT_ON


func _on_goal_entered(body: Node2D) -> void:
	if body == player:
		summit_reached.emit()


func _respawn() -> void:
	player.global_position = to_global(checkpoint_position)
	player.velocity = Vector2.ZERO
