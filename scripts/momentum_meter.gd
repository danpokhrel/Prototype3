class_name MomentumMeter
extends ProgressBar

## Displays the player's momentum meter (0..1). Attach to a ProgressBar node
## and set the player_path to the Player node.

@export var player_path: NodePath = ^"../Player"

var _player: Player


func _ready() -> void:
	max_value = 1.0
	min_value = 0.0
	_player = get_node_or_null(player_path) as Player
	if _player == null:
		push_warning("MomentumMeter: no Player found at %s" % player_path)
		return
	_player.momentum_changed.connect(_on_player_momentum_changed)
	# Initialize to the player's current value.
	value = _player.momentum


## Syncs the bar to the player's momentum value.
func _on_player_momentum_changed(new_value: float) -> void:
	value = new_value
