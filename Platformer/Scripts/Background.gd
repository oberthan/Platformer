extends Node2D

var cam: Camera2D

# Speeds for each of the 7 layers (lower = farther away)
var layer_speeds := [
	Vector2(0.05, 0.0),
	Vector2(0.01, 0.0),
	Vector2(0.15, 0.0),
	Vector2(0.2, 0.0),
	Vector2(0.5, 0.0),
	Vector2(0.9, 0.0)
	#Vector2(1.0, 0.0)
]

func set_camera_to_follow(camera_node: Camera2D):
	self.cam = camera_node
	if is_inside_tree():
		call_deferred("_init_parallax")

func _ready() -> void:
	set_camera_to_follow(get_viewport().get_camera_2d())

#func _process(delta: float) -> void:
	#if cam == null:
		#print("Trying to set cam again: ")
		#set_camera_to_follow(get_viewport().get_camera_2d())

func _init_parallax():
	if cam == null:
		push_warning("Parallax background has no camera to follow.")
		return
	
	var cam_height = get_viewport_rect().size.y / cam.zoom.y
	
	var i := 0
	for child in get_children():
		if i >= layer_speeds.size():
			break

		var speed = layer_speeds[i]

		# New unified node (Godot 4.3+)
		if child is Parallax2D:
			child.scroll_scale = speed
			var s: Sprite2D = child.get_child(0)

			var tex_size: Vector2
			if s.region_enabled:
				tex_size= s.region_rect.size
			else:
				tex_size = s.texture.get_size()
				
			if tex_size.y == 0:
				continue
			var scale_factor = cam_height / 1200
			#child.scale = Vector2(scale_factor, scale_factor)


			child.repeat_size.x = 1900
			child.scale = Vector2(scale_factor,scale_factor)
			child.scroll_offset = cam.global_position * child.scroll_scale
		
		# Legacy system
		elif child is ParallaxLayer:
			child.motion_scale = speed

		else:
			print_debug("Skipping ", child.name, " (not a Parallax2D/ParallaxLayer)")

		i += 1
