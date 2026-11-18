@tool
class_name PlatformBlock
extends StaticBody2D

## Reusable rectangular level block. The node origin is the top-center of the
## block, so an instance's position is the height of the surface it presents.
## Size, color and one-way collision are edited per instance in the Inspector.

@export var size: Vector2 = Vector2(160.0, 16.0):
	set(value):
		size = value
		_apply_geometry()

@export var color: Color = Color("5a7bff"):
	set(value):
		color = value
		_apply_color()

## One-way collision lets bodies pass through the block from below.
@export var one_way: bool = true:
	set(value):
		one_way = value
		_apply_geometry()


## Applies the authored geometry once the child nodes exist.
func _ready() -> void:
	_apply()


## Reapplies geometry and color.
func _apply() -> void:
	_apply_geometry()
	_apply_color()


## Sizes the collision shape and the visual, anchored at the top-center.
func _apply_geometry() -> void:
	var collision := get_node_or_null(^"Collision") as CollisionShape2D
	if collision != null:
		var shape := collision.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			collision.shape = shape
		shape.size = size
		collision.position = Vector2(0.0, size.y * 0.5)
		collision.one_way_collision = one_way

	var visual := get_node_or_null(^"Visual") as ColorRect
	if visual != null:
		visual.size = size
		visual.position = Vector2(-size.x * 0.5, 0.0)


## Paints the visual with the authored color.
func _apply_color() -> void:
	var visual := get_node_or_null(^"Visual") as ColorRect
	if visual != null:
		visual.color = color
