extends CharacterBody2D

@export var cam = Camera2D
@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider_body: CollisionShape2D = $ColliderBody
@onready var collider_top: CollisionShape2D = $ColliderTop
@onready var health_bar: ProgressBar = $ProgressBar
@onready var sb = StyleBoxFlat.new()

var SPEED = 300.0
var JUMP_VELOCITY = -400.0
var facing_left = true
var health: float = 100

var inputs = {
	"left": false,
	"right": false,
	"jump": false
}

var server_position = Vector2.ZERO
var server_velocity = Vector2.ZERO

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	cam.enabled = is_multiplayer_authority()

func _ready() -> void:
	# The server needs to simulate collisions for all players.
	# Clients only need to simulate their own player.
	if Network.is_server:
		collider_body.disabled = false
		collider_top.disabled = false
	else:
		collider_body.disabled = !is_multiplayer_authority()
		collider_top.disabled = is_multiplayer_authority()
		set_collision_mask_value(1, is_multiplayer_authority())

	cam.enabled = is_multiplayer_authority()
	
	# If this is the client's own player, it needs to tell the background what camera to follow.
	if is_multiplayer_authority():
		# Find the background node. We assume it's a sibling of the player.
		var background = get_parent().find_child("Background")
		if background:
			background.set_camera_to_follow(cam)

	match name.to_int():
		1:
			print("Player 1 using Pink")
			animation_sprite.sprite_frames = preload("res://Pink_Monster_Frames.tres")
			set_collision_mask_value(2, true)
		_:
			print("Player ", name," using Dude")
			animation_sprite.sprite_frames = preload("res://Dude_Monster_Frames.tres")
			set_collision_mask_value(3, true)
			scale = Vector2(1, 1.2)
			JUMP_VELOCITY = -500
			SPEED = 350
	
	health_bar.add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("00ff00")

var prev_animation = ""
func _process(delta: float) -> void:
	# Animation logic can remain client-side for responsiveness,
	# but the server's state will ultimately be authoritative.
	# This is a cosmetic layer.
	var animationName = ""
	if velocity == Vector2.ZERO:
		animationName = "Idle"
	elif is_on_floor():
		animationName = "Walk"
	else:
		animationName = "Jump"

	animation_sprite.play(animationName)
	animation_sprite.set_flip_h(facing_left)
	
	if is_multiplayer_authority() and animationName != prev_animation:
		prev_animation = animationName
		rpc("update_animation", name, animationName, facing_left)

	if health >= 100:
		health_bar.hide()
	else:
		health += delta
		health_bar.show()
	health_bar.value = health
	sb.bg_color = Color.from_hsv(max((health-25)/225.0, 0), 1, 1, 1)

func _physics_process(delta: float) -> void:
	# The authoritative client sends its inputs to the server.
	if is_multiplayer_authority():
		inputs.left = Input.is_action_pressed("left")
		inputs.right = Input.is_action_pressed("right")
		inputs.jump = Input.is_action_just_pressed("jump")
		Network.rpc_id(1, "receive_player_input", name.to_int(), inputs)

	# On clients, all player nodes (local and remote) are puppets.
	# They just interpolate to the state received from the server.
	if !Network.is_server:
		# If server_position is not zero, start interpolating.
		if server_position != Vector2.ZERO:
			position = server_position
			velocity = server_velocity

# This function is only ever executed on the server.
func apply_server_input(p_inputs, delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if p_inputs.jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = 0
	if p_inputs.left:
		direction = -1
	elif p_inputs.right:
		direction = 1
		
	if direction:
		velocity.x = direction * SPEED
		if facing_left != (direction<0):
			facing_left = direction<0
			rpc("update_animation", name, prev_animation, facing_left)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if position.y > 1000:
		position.y = -100
		velocity.y = 0
		decrease_health(35)

	rpc("update_client_state", position, velocity)

func decrease_health(amount):
	health -= amount
	rpc("update_health", name, health)

# This RPC is received by all clients to update the state of their puppets.
@rpc("unreliable", "any_peer", "call_local")
func update_client_state(p_position, p_velocity):
	if !Network.is_server:
		server_position = p_position
		server_velocity = p_velocity

@rpc("any_peer", "call_local")
func update_animation(id, animationName, flip):
	if !is_multiplayer_authority():
		if name == id:
			animation_sprite.set_flip_h(flip)
			animation_sprite.play(animationName)

@rpc("any_peer", "call_local")
func update_health(id, hp):
	if !is_multiplayer_authority():
		if name == id:
			health = hp
