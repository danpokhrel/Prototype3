class_name Level
extends Node2D

## Level controller. The geometry lives in level_layout.tscn as prefab
## instances; this script owns the player reference, checkpoints, hazards and
## the goal, and is the only place that knows about respawning.

signal summit_reached

const GROUP_HAZARDS: StringName = &"hazards"
const GROUP_CHECKPOINTS: StringName = &"checkpoints"
const GROUP_GOAL: StringName = &"goal"
const GROUP_PLAYER: StringName = &"player"

## Player override; defaults to the first node in the "player" group.
@export var player: Player
## Spawn position in the level's local space; also the first checkpoint.
@export var start_position: Vector2 = Vector2(640.0, -48.0)

var checkpoint_position: Vector2


## Places the player at the start and connects the layout's trigger areas.
func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group(GROUP_PLAYER) as Player
	if player == null:
		push_error("Level: no player assigned or in the player group")
		return
	checkpoint_position = start_position
	player.global_position = to_global(start_position)
	_connect_hazards()
	_connect_checkpoints()
	_connect_goal()


## Connects every hazard area in the layout to the respawn handler.
func _connect_hazards() -> void:
	for node in get_tree().get_nodes_in_group(GROUP_HAZARDS):
		var hazard: Area2D = node as Area2D
		if hazard != null:
			hazard.body_entered.connect(_on_hazard_entered)


## Connects every checkpoint area in the layout.
func _connect_checkpoints() -> void:
	for node in get_tree().get_nodes_in_group(GROUP_CHECKPOINTS):
		var checkpoint: Checkpoint = node as Checkpoint
		if checkpoint != null:
			checkpoint.body_entered.connect(_on_checkpoint_entered.bind(checkpoint))


## Connects the goal area in the layout.
func _connect_goal() -> void:
	for node in get_tree().get_nodes_in_group(GROUP_GOAL):
		var goal: Area2D = node as Area2D
		if goal != null:
			goal.body_entered.connect(_on_goal_entered)


## Sends the player back to the last checkpoint when it touches a hazard.
func _on_hazard_entered(body: Node2D) -> void:
	if body == player:
		_respawn.call_deferred()


## Stores a new respawn point and lights the checkpoint up.
func _on_checkpoint_entered(body: Node2D, checkpoint: Checkpoint) -> void:
	if body != player:
		return
	checkpoint_position = to_local(checkpoint.get_spawn_position())
	checkpoint.activate()


## Announces that the player reached the top of the climb.
func _on_goal_entered(body: Node2D) -> void:
	if body == player:
		summit_reached.emit()


## Puts the player back at the last checkpoint without leftover velocity.
func _respawn() -> void:
	player.global_position = to_global(checkpoint_position)
	player.velocity = Vector2.ZERO
