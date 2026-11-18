@tool
class_name Checkpoint
extends AreaBox

## Checkpoint trigger. Starts in the inactive color and switches to the active
## color when the level activates it. The spawn point is offset from the
## node origin, which sits on the ledge it belongs to.

## Color used once the checkpoint has been reached.
@export var active_color: Color = Color("35d6a0")

## Offset from the node origin to the respawn position.
@export var spawn_offset: Vector2 = Vector2(0.0, -40.0)

var is_active: bool = false


## Returns the global respawn position this checkpoint grants.
func get_spawn_position() -> Vector2:
	return global_position + spawn_offset


## Marks the checkpoint active and switches its color. Safe to call twice.
func activate() -> void:
	if is_active:
		return
	is_active = true
	color = active_color
