@tool
class_name AreaBox
extends Area2D

## Rectangular trigger volume with a solid-color visual. Used for hazards and
## the goal. The origin is the top-center unless anchor_bottom is set, in which
## case the origin is the bottom-center (handy for things sitting on a ledge).

## Size of the trigger and its visual.
@export var size: Vector2 = Vector2(120.0, 100.0):
	set(value):
		size = value
		_apply_geometry()

@export var color: Color = Color("ff4d4d"):
	set(value):
		color = value
		_apply_color()

## When true, the origin is the bottom-center instead of the top-center.
@export var anchor_bottom: bool = false:
	set(value):
		anchor_bottom = value
		_apply_geometry()


## Applies the authored geometry once the child nodes exist.
func _ready() -> void:
	_apply()


## Reapplies geometry and color.
func _apply() -> void:
	_apply_geometry()
	_apply_color()


## Sizes the collision shape and the visual around the configured anchor.
func _apply_geometry() -> void:
	var anchor: float = -size.y if anchor_bottom else 0.0
	var collision := get_node_or_null(^"Collision") as CollisionShape2D
	if collision != null:
		var shape := collision.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			collision.shape = shape
		shape.size = size
		collision.position = Vector2(0.0, anchor + size.y * 0.5)

	var visual := get_node_or_null(^"Visual") as ColorRect
	if visual != null:
		visual.size = size
		visual.position = Vector2(-size.x * 0.5, anchor)


## Paints the visual with the authored color.
func _apply_color() -> void:
	var visual := get_node_or_null(^"Visual") as ColorRect
	if visual != null:
		visual.color = color
