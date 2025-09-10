extends Node2D

@onready var cam := get_viewport().get_camera_2d()

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

func _init_camera() -> void:
	cam = get_viewport().get_camera_2d()
	if cam == null:
		push_warning("No Camera2D found yet. Will keep checking every frame.")
	

func _ready() -> void:
	call_deferred("_init_camera")
	call_deferred("_init_parallax")

func _init_parallax():
	if cam == null:
		push_warning("No Camera2D found. Scaling skipped.")
		return
	
	
	var cam_height = get_viewport_rect().size.y
	
	var i := 0
	for child in get_children():
		if i >= layer_speeds.size():
			break

		var speed = layer_speeds[i]

		# New unified node (Godot 4.3+)
		if child is Parallax2D:
			child.scroll_scale = speed
			#print_debug("Set scroll_scale on Parallax2D ", child.name, " -> ", speed)
			# find the Sprite2D (adjust path if different)
			var s: Sprite2D = child.get_child(0)
			#if s == null or s.texture == null:
				#return

			# ensure sprite is aligned and tileable
			##s.centered = false
			##s.position = Vector2.ZERO

			# enable tile / repeat for the sprite (CanvasItem.texture_repeat)
			# (Sprite2D inherits CanvasItem)
			##s.texture_repeat = child.CanvasItem.TextureRepeat.REPEAT

			var tex_size: Vector2 # compute displayed width (texture size * scale)
			if s.region_enabled:
				
				tex_size= s.region_rect.size
			else:
				tex_size = s.texture.get_size()
				
			if tex_size.y == 0:
				continue
			var scale_factor = cam_height / tex_size.y
			child.scale = Vector2(scale_factor, scale_factor)

			# set repeat_size.x so Parallax2D will snap/loop every tex width
			child.repeat_size.x = tex_size.x#*child.scale.x
			
			position = tex_size*child.scale*0.5

			#child.repeat_times.x = 2


		# Legacy system
		elif child is ParallaxLayer:
			child.motion_scale = speed
			print_debug("Set motion_scale on ParallaxLayer ", child.name, " -> ", speed)

		# if you accidentally have Sprite2D/Node2D layers directly and want to wrap them,
		# you can also set their transform manually by adjusting their position relative to camera movement.
		else:
			print_debug("Skipping ", child.name, " (not a Parallax2D/ParallaxLayer)")

		i += 1

	# Force parallax to recompute offsets (works around initial-offset quirks)
