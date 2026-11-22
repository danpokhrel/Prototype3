extends Area2D

@export var outer_radius: float = 14.0
@export var inner_radius: float = 10.0
@export var points: int = 1

# Makes the ring slightly easier to hit
@export var hitbox_multiplier: float = 1.2

var scored: bool = false


func _ready():
	# Create the ring's collision hitbox
	var collision = get_node_or_null("CollisionShape2D")

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)

	var shape = CircleShape2D.new()
	shape.radius = inner_radius * hitbox_multiplier
	collision.shape = shape

	# Detect the spear on collision layer 2
	collision_mask = 2
	monitoring = true

	area_entered.connect(_on_area_entered)

	queue_redraw()

func _physics_process(_delta):
	if scored:
		return

	# Check overlaps while left-click is held
	# This also handles a spear already inside the ring
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for area in get_overlapping_areas():
			try_collect(area)


func _on_area_entered(area: Area2D):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		try_collect(area)


func try_collect(area: Area2D):
	if scored:
		return

	if not area.is_in_group("spear"):
		return

	scored = true

	print("Collected ring! +", points)

	queue_free()
