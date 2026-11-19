extends Node2D

@export var ring_scene: PackedScene
@export var ring_count: int = 15
@export var minimum_spacing: float = 100.0

# Temporary spawn boundaries
@export var spawn_min: Vector2 = Vector2(0, -500)
@export var spawn_max: Vector2 = Vector2(2000, -75)

var ring_positions: Array[Vector2] = []


func _ready():
	if ring_scene == null:
		push_error("RingSpawner: Assign Ring.tscn in the Inspector!")
		return

	spawn_rings()


func spawn_rings():
	ring_positions.clear()

	if spawn_min.x >= spawn_max.x or spawn_min.y >= spawn_max.y:
		push_error("Invalid spawn boundaries! Check Spawn Min and Spawn Max in the Inspector.")
		return

	for i in range(ring_count):
		for attempt in range(50):
			var random_position = Vector2(
				randf_range(spawn_min.x, spawn_max.x),
				randf_range(spawn_min.y, spawn_max.y)
			)

			if is_valid_position(random_position):
				create_ring(random_position)
				ring_positions.append(random_position)
				break


func is_valid_position(new_position: Vector2) -> bool:
	for existing_position in ring_positions:
		if new_position.distance_to(existing_position) < minimum_spacing:
			return false

	return true


func create_ring(spawn_position: Vector2):
	var ring = ring_scene.instantiate()

	if ring == null:
		push_error("Failed to create ring!")
		return

	add_child(ring)
	ring.global_position = spawn_position

	print("Spawned ring at: ", spawn_position)
