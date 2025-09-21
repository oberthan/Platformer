extends CharacterBody2D

@export var cam = Camera2D
@export var player_role: int = 0
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_listener: AudioListener2D = $AudioListener2D

@onready var collider_body: CollisionShape2D = $ColliderBody
@onready var health_bar: ProgressBar = $ProgressBar
@onready var sb = StyleBoxFlat.new()
const smoke = preload("res://Scenes/Smoke.tscn")


var SPEED = 300.0
var JUMP_VELOCITY = -425.0
var facing_left = true
@export var health: float = 100
@export var dead = false
@export var reset_level = false
var player_id = 1
@export var abort_anim = false
@export var just_hurt = false

var inputs = {
	"left": false,
	"right": false,
	"jump": false,
	"attack1": false,
	"switch": false
}

var server_position = Vector2.ZERO
var server_velocity = Vector2.ZERO

var last_attack: int

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	cam.enabled = is_multiplayer_authority()


func _ready() -> void:
	# The server needs to simulate collisions for all players.
	# Clients only need to simulate their own player.
	if multiplayer.is_server():
		collider_body.disabled = false
	else:
		collider_body.disabled = !is_multiplayer_authority()
		set_collision_mask_value(1, is_multiplayer_authority())

	cam.enabled = is_multiplayer_authority()

	
	# If this is the client's own player, it needs to tell the background what camera to follow.
	if is_multiplayer_authority():
		audio_listener.clear_current()
		audio_listener.make_current()
		# Find the background node. We assume it's a sibling of the player.
		var background = get_parent().find_child("Background")
		if background:
			background.set_camera_to_follow(cam)

	match player_role:
		1:
			print("Player 1 using Pink")
			sprite_2d.texture = load("res://craftpix-net-622999-free-pixel-art-tiny-hero-sprites/1 Pink_Monster/Pink_Monster_Sheet.png")
			set_collision_mask_value(2, true)
		_:
			print("Player ", name," using Dude")
			sprite_2d.texture = load("res://craftpix-net-622999-free-pixel-art-tiny-hero-sprites/3 Dude_Monster/Dude_Monster_sheet.png")
			set_collision_mask_value(3, true)
			scale = Vector2(1, 1.2)
			JUMP_VELOCITY = -500
			SPEED = 350
	
	health_bar.add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("00ff00")

var prev_vel = Vector2.ZERO
var last_tick_vel = Vector2.ZERO
var prev_facing = false

func _process(delta: float) -> void:
	if health >= 100:
		health_bar.hide()
	else:
		health += delta
		health_bar.show()
	health_bar.value = health
	sb.bg_color = Color.from_hsv(max((health-25)/225.0, 0), 1, 1, 1)

var coyote_timer = 0
var coyote_time = 0.150

func _physics_process(delta: float) -> void:
	# The authoritative client sends its inputs to the server.
	
	
	if is_multiplayer_authority():
		inputs.left = Input.is_action_pressed("left")
		inputs.right = Input.is_action_pressed("right")
		inputs.jump = Input.is_action_just_pressed("jump")
		inputs.attack1 = Input.is_action_just_pressed("attack1")
		inputs.switch = Input.is_action_just_pressed("switch_players")
		Network.rpc_id(1, "receive_player_input", player_role, inputs)

	# On clients, all player nodes (local and remote) are puppets.
	# They just interpolate to the state received from the server.
	if !multiplayer.is_server():
		# If server_position is not zero, start interpolating.
		if server_position != Vector2.ZERO:
			if position.distance_to(server_position) < 0.1:
				position = server_position
			else:
				position = position.lerp(server_position, 0.2)
			move_and_slide()

func change_player(playerid, pos: Vector2):
	if len(Network.get_all_player_ids()) == 1 and "--server" not in OS.get_cmdline_args():
		if playerid == 1:
			print("changed to player 2")
			sprite_2d.texture = load("res://craftpix-net-622999-free-pixel-art-tiny-hero-sprites/3 Dude_Monster/Dude_Monster_sheet.png")
			set_collision_mask_value(3, true)
			scale = Vector2(1, 1.2)
			pos.y -= 3.2
			JUMP_VELOCITY = -500
			SPEED = 350
			player_id = 2
		else:
			print("changed to player 1")
			sprite_2d.texture = load("res://craftpix-net-622999-free-pixel-art-tiny-hero-sprites/1 Pink_Monster/Pink_Monster_Sheet.png")
			set_collision_mask_value(2, true)
			scale = Vector2(1, 1)
			pos.y += 3.2
			JUMP_VELOCITY = -425
			SPEED = 300
			player_id = 1
		rpc("spawn_smoke", pos)
		

@rpc("any_peer", "call_local")
func spawn_smoke(pos: Vector2) -> void:
	var smoke_element = smoke.instantiate()
	var smoke_element_left = smoke.instantiate()
	smoke_element.global_position = pos+Vector2(48, -32)
	smoke_element_left.global_position = pos+Vector2(-48, -32)
	smoke_element_left.flip_h = true
	get_parent().add_child(smoke_element)
	get_parent().add_child(smoke_element_left)
		
# This function is only ever executed on the server.
func apply_server_input(p_inputs, delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		coyote_timer += delta
	else:
		coyote_timer = 0
		
	if p_inputs.switch:
		change_player(player_id, global_position)	
	
	if p_inputs.jump and coyote_timer < coyote_time:
		velocity.y = JUMP_VELOCITY
		coyote_timer += coyote_time

	var direction = 0
	if p_inputs.left:
		direction += -1
	if p_inputs.right:
		direction += 1
		
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED*(delta*10))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*(delta if not is_on_floor() else delta*10))
		
	facing_left = velocity.x < 0 
	facing_left = prev_facing if velocity.x == 0 else facing_left
	
	
	move_and_slide()
	
	# Server-authoritative animation logic
	var did_attack = p_inputs.attack1 or false
	
	
	if did_attack:
		if p_inputs.attack1:
			last_attack = 0
		elif false:
			last_attack = 1
	
	if position.y > 1000:
		print(name, " fell off and died")
		dead = true
	
	last_tick_vel = prev_vel
	
	if velocity != prev_vel or facing_left != prev_facing or did_attack:
		prev_vel = velocity if not did_attack else velocity + Vector2(1,1)
		prev_facing = facing_left
		rpc("update_animation", name, velocity, is_on_floor(), facing_left, did_attack, last_attack, abort_anim, just_hurt, dead)

	


	rpc("update_client_state", position, velocity)



func decrease_health(amount):
	health -= amount
	if health <= 0:
		dead = true
		print(name, " was killed")
	abort_anim = true
	just_hurt = true
	rpc("update_health", name, health)

# This RPC is received by all clients to update the state of their puppets.
@rpc("unreliable", "any_peer", "call_local")
func update_client_state(p_position, p_velocity):
	if !multiplayer.is_server():
		var pos_margin = 0.1
		server_position = p_position
		server_velocity = p_velocity
		velocity = server_velocity

@rpc("any_peer", "call_local")
func update_animation(id, player_velocity, on_floor, flip, is_attack, attack_type,abort, hurt, is_dead):
	if name == id:
		
		animation_tree["parameters/conditions/is_dead"] = is_dead
		
		animation_tree["parameters/Attack/conditions/abort"] = abort
		animation_tree["parameters/conditions/hurt"] = hurt
		
		var walking = player_velocity.x != 0 and on_floor
		animation_tree["parameters/conditions/idle"] = !walking
		animation_tree["parameters/Attack/conditions/idle"] = !walking
		
		animation_tree["parameters/conditions/is_walking"] = walking
		animation_tree["parameters/Attack/conditions/is_walking"] = walking
		
		animation_tree["parameters/Attack/conditions/hit_attack"] = attack_type == 0
		animation_tree["parameters/Attack/conditions/throw_attack"] = attack_type == 1

		animation_tree["parameters/conditions/attack"] = is_attack
		
		animation_tree["parameters/conditions/jump"] = player_velocity.y == JUMP_VELOCITY

		


		
		
		#Movement
		animation_tree["parameters/Idle/blend_position"] = -1 if flip else 1
		animation_tree["parameters/Jump/blend_position"] = -1 if flip else 1
		animation_tree["parameters/Walk/blend_position"] = -1 if flip else 1
		animation_tree["parameters/Hurt/blend_position"] = -1 if flip else 1
		animation_tree["parameters/Death/blend_position"] = -1 if flip else 1
		
		#Attack
		animation_tree["parameters/Attack/Standing/blend_position"] = -1 if flip else 1
		animation_tree["parameters/Attack/Throw/blend_position"] = -1 if flip else 1
		animation_tree["parameters/Attack/Walking/blend_position"] = -1 if flip else 1
		
		
		

@rpc("any_peer", "call_local")
func update_health(id, hp):
	if name == id:
		health = hp
		
		
