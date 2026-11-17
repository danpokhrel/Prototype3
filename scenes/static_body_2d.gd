extends StaticBody2D

@export var max_health: float = 100.0
var health: float

func _ready() -> void:
	health = max_health

func take_damage(amount: float) -> void:
	health -= amount
	print("Spear hit: ", snappedf(amount, 0.1), " damage. HP: ", snappedf(health, 0.1))
	if health <= 0.0:
		queue_free()
