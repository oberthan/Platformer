extends CharacterBody2D

@export var speed: float = 140.0
@export var acceleration: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 1800.0
@export var run_threshold: float = 10.0 
@export var damage: float = 20

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D

@onready var health_bar: ProgressBar = $ProgressBar
@onready var sb = StyleBoxFlat.new()


var health: float = 59

var _target: Node2D = null

@export var attacking = 0

enum State { IDLE, CHASING, ATTACKING }
var state: State = State.IDLE

func _ready() -> void:
	set_multiplayer_authority(1)
	set_physics_process(multiplayer.is_server())

	if multiplayer.is_server():
		area_2d.body_entered.connect(_on_attack_area_body_entered)
		area_2d.body_exited.connect(_on_attack_area_body_exited)
		

	_play_anim_from_velocity()
	
	health_bar.add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("00ff00")

func decrease_health(amount):
	health -= amount

func _process(delta):
	if health >= 100:
		health_bar.hide()
	else:
		health_bar.show()
	health_bar.value = health
	sb.bg_color = Color.from_hsv(max((health-25)/225.0, 0), 1, 1, 1)

@export var detection_range = 350
func _reacquire_target() -> void:

	var best: Node2D = null
	var dist = detection_range

	for id in Network.players:
		var player = Network.players[id]
		if is_instance_valid(player) and player is Node2D:
			var distance = player.global_position.distance_to(global_position)
			if distance < dist:
				dist = distance
				best = player
				
	_target = best

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	_reacquire_target()
	
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if _target:
		var dx = _target.global_position.x - global_position.x
		var distance = abs(dx)
		
		if attacking > 0:
			state = State.ATTACKING
		elif distance < 50: # "close" but not attacking
			state = State.IDLE
		elif distance < detection_range:
			state = State.CHASING

		else:
			state = State.IDLE
			
			
		
		match state:
			State.CHASING:
				var dir_x = sign(dx)
				velocity.x = move_toward(velocity.x, speed * dir_x, acceleration * delta)

			State.IDLE:
				velocity.x = 0
				# Face the player
				if dx > 0:
					$Sprite2D.flip_h = true
				else:
					$Sprite2D.flip_h = false

			State.ATTACKING:
				velocity.x = 0
	else:
		state = State.IDLE
		velocity.x = 0

	move_and_slide()

	_play_anim_from_velocity()

	rpc("_sync_state", global_position, velocity, state)

@rpc("authority", "call_local", "unreliable")
func _sync_state(pos, vel, enemy_state) -> void:
	if multiplayer.is_server():
		return
	global_position = pos
	velocity = vel
	state = enemy_state
	_play_anim_from_velocity()

func _play_anim_from_velocity() -> void:
	if anim == null:
		return
		

		
	if state == State.ATTACKING:
		
		if not anim.is_playing() or anim.current_animation != "Attack":

			anim.play("Attack")
	else:
		if velocity != Vector2.ZERO:
			anim.play("Run")
		else:
			anim.play("Idle")


func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		attacking += 1

func _on_attack_area_body_exited(body: Node) -> void:
	if body.is_in_group("players"):
		attacking -= 1



func _check_attack_landed():
	var bodies = area_2d.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("players"):
			body.velocity += (body.global_position - global_position) * 20
			body.decrease_health(damage)

func bounce_on_head(body: Node2D):
	if body.is_in_group("players"):
		if body.prev_vel.y >0:
			body.velocity.y = body.prev_vel.y * -1
