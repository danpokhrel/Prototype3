class_name StaminaBar
extends Node2D

## One pip per stamina point. A pip fills as stamina regenerates, and the bar
## turns red when you can't afford a flap.

@export var player: Player
@export var pip_size: Vector2 = Vector2(18.0, 8.0)
@export var pip_gap: float = 4.0
@export var color_full := Color("35e0ff")
@export var color_low := Color("ff4d4d")
@export var color_empty := Color("1b2a33")
@export var hide_when_full: bool = false

var _value: float = 0.0
var _max: float = 1.0
var _cost: float = 1.0


func _ready() -> void:
	if player == null:
		player = get_parent() as Player
	if player == null:
		push_error("StaminaBar: assign the Player in the Inspector.")
		return
	player.stamina_changed.connect(_on_stamina_changed)
	_sync.call_deferred()   # wait for the player's own _ready to fill stamina


func _sync() -> void:
	_max = player.max_stamina
	_cost = player.flap_stamina_cost
	_on_stamina_changed(player.stamina)


func _on_stamina_changed(value: float) -> void:
	_value = value
	visible = not (hide_when_full and _value >= _max)
	queue_redraw()


func _draw() -> void:
	var fill_color: Color = color_low if _value < _cost else color_full
	for i in int(ceil(_max)):
		var rect := Rect2(Vector2(i * (pip_size.x + pip_gap), 0.0), pip_size)
		draw_rect(rect, color_empty)
		var fill: float = clampf(_value - i, 0.0, 1.0)
		if fill > 0.0:
			draw_rect(Rect2(rect.position, Vector2(pip_size.x * fill, pip_size.y)), fill_color)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.35), false, 1.0)
