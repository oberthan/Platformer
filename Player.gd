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

var eDelta = 0

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
	cam.enabled = is_multiplayer_authority()
	
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
			
	collider_body.disabled = !is_multiplayer_authority()
	collider_top.disabled = is_multiplayer_authority()
	set_collision_mask_value(1, is_multiplayer_authority())
	
	
	health_bar.add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("00ff00")
	

var prev_animation = ""
func _process(delta: float) -> void:
	if is_multiplayer_authority():
		var animationName = ""
		if velocity == Vector2.ZERO:
			animationName = "Idle"
		elif is_on_floor():
			animationName = "Walk"  # for example
		else:
			animationName = "Jump"  # for example
		
		animation_sprite.play(animationName)
		animation_sprite.set_flip_h(facing_left)
		if animationName != prev_animation:
			prev_animation = animationName
			rpc("update_animation", name,animationName, facing_left)
	

	if health >= 100:
		
		health_bar.hide()
	else:
		health += delta

		health_bar.show()
	health_bar.value = health
	sb.bg_color = Color.from_hsv(max((health-25)/225.0, 0), 1, 1, 1)
	#sb.bg_color = Color.from_hsv(0.3, 1, 1, 1)

	
var updated_position = Vector2.ZERO

func _physics_process(delta: float) -> void:
	eDelta = delta
	if is_multiplayer_authority():
		inputs.left = Input.is_action_pressed("left")
		inputs.right = Input.is_action_pressed("right")
		inputs.jump = Input.is_action_just_pressed("jump")

		Network.rpc_id(1, "receive_player_input", name.to_int(), inputs)
	else:
		# Interpolate the position of the remote player
		position = position.linear_interpolate(server_position, 0.2)

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
	
@rpc("unreliable", "any_peer", "call_local")
func update_client_state(p_position, p_velocity):
	if !is_multiplayer_authority():
		server_position = p_position
		server_velocity = p_velocity


@rpc("any_peer", "call_local") func update_animation(id, animationName, flip):
	if !is_multiplayer_authority():
		if name == id:
			animation_sprite.set_flip_h(flip)
			animation_sprite.play(animationName)
			
@rpc("any_peer", "call_local") func update_health(id, hp):
	if !is_multiplayer_authority():
		if name == id:
			health = hp
