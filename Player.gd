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


	

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	cam.enabled = is_multiplayer_authority()

func _ready() -> void:
	if is_multiplayer_authority():
		rpc("updatePos", name, position, velocity)
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
			rpc("updateAnimation", name,animationName, facing_left)
	

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
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
			if facing_left != (direction<0):
				facing_left = direction<0
				rpc("updateAnimation", name, prev_animation, facing_left)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		
		if position.y > 1000:
			position.y = -100
			velocity.y = 0
			decrease_health(35)
			rpc("updatePos", name, position, velocity)		
		else:
			rpc("updatePos", name, position, velocity)		
			

	else:
		
		move_and_slide()
		#position = lerp(position, updated_position, delta*15)

func decrease_health(amount):
	health -= amount
	rpc("updateHealth", name, health)
	
@rpc("unreliable", "any_peer", "call_local") func updatePos(id, pos, vel):
	if !is_multiplayer_authority():
		if name == id:
			velocity = vel
			position = pos


@rpc("any_peer", "call_local") func updateAnimation(id, animationName, flip):
	if !is_multiplayer_authority():
		if name == id:
			animation_sprite.set_flip_h(flip)
			animation_sprite.play(animationName)
			
@rpc("any_peer", "call_local") func updateHealth(id, hp):
	if !is_multiplayer_authority():
		if name == id:
			health = hp
