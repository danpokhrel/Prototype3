extends Area2D

func _ready():
	add_to_group("spear")
	collision_layer = 2
	collision_mask = 1
	monitoring = true


func _physics_process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for area in get_overlapping_areas():
			if area.is_in_group("rings"):
				area.queue_free()
