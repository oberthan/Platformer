extends CharacterBody2D

@export var speed: float = 140.0
@export var acceleration: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 1800.0
@export var run_threshold: float = 10.0 
@export var damage: float = 20
@onready var enemy: CharacterBody2D = $"."


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D

@onready var health_bar: ProgressBar = $ProgressBar
@onready var sb = StyleBoxFlat.new()

@export var enemy_id = 0

@export var max_health: float = 70
var health: float

var _target: Node2D = null

@export var attacking = 0

enum State { IDLE, CHASING, ATTACKING, HURT, DEAD }
@export var state: State = State.IDLE

var hurting = false
var dead = false

var immunity_timer = 0
 
func _ready() -> void:
	
	set_multiplayer_authority(1)
	set_physics_process(multiplayer.is_server())
	$".".add_to_group("enemies")
	if multiplayer.is_server():
		area_2d.body_entered.connect(_on_attack_area_body_entered)
		area_2d.body_exited.connect(_on_attack_area_body_exited)
		anim.animation_finished.connect(anim_finished)
		

	_play_anim_from_velocity()
	
	health_bar.add_theme_stylebox_override("fill", sb)
	sb.bg_color = Color("00ff00")
	health = max_health

func decrease_health(amount):
	if not multiplayer.is_server():
		return
	if immunity_timer <= 0:
		if health <= 0:
			dead = true
		else:
			hurting = true
		health -= amount
		immunity_timer = 1
		rpc("update_health", enemy_id, health)

func _process(delta):
	if health >= max_health:
		health_bar.hide()
	else:
		health_bar.show()
	health_bar.value = health/max_health*100
	sb.bg_color = Color.from_hsv(max((health-25)/225.0, 0), 1, 1, 1)
	

@export var detection_range = 350
func _reacquire_target() -> void:
	if not multiplayer.is_server():
		return
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
	
	immunity_timer -= delta
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if _target:
		var dx = _target.global_position.x - global_position.x
		var distance = abs(dx)
		
		if attacking > 0:
			state = State.ATTACKING
		elif state != State.ATTACKING:
			if distance < 50: # "close" but not attacking
				state = State.IDLE
			elif distance < detection_range:
				state = State.CHASING
			else:
				state = State.IDLE
		
		if dead:
			state = State.DEAD	
		
		if hurting:
			state = State.HURT
			
		
		
		match state:
			State.CHASING:
				var dir_x = sign(dx)
				velocity.x = move_toward(velocity.x, speed * dir_x, acceleration * delta)
				if dx > 0:
					$Sprite2D.flip_h = true
					area_2d.position.x = 26
				else:
					$Sprite2D.flip_h = false
					area_2d.position.x = -26
					
			State.HURT:
				if dx > 0:
					$Sprite2D.flip_h = true
				else:
					$Sprite2D.flip_h = false
					
			State.DEAD:
				if dx > 0:
					$Sprite2D.flip_h = true
				else:
					$Sprite2D.flip_h = false

			State.IDLE:
				velocity.x = 0
				# Face the player
				if dx > 0:
					$Sprite2D.flip_h = true
					area_2d.position.x = 26
				else:
					area_2d.position.x = -26
					$Sprite2D.flip_h = false

			State.ATTACKING:
				velocity.x = 0
				

				
	else:
		state = State.IDLE
		velocity.x = 0

	move_and_slide()

	_play_anim_from_velocity()

	rpc("_sync_state", enemy_id, global_position, velocity, state, $Sprite2D.flip_h)

@rpc("authority", "call_local", "unreliable")
func _sync_state(id, pos, vel, enemy_state, direction) -> void:
	
	if multiplayer.is_server():
		return
	if id == enemy_id:
		global_position = pos
		velocity = vel
		state = enemy_state
		$Sprite2D.flip_h = direction
		_play_anim_from_velocity()

func _play_anim_from_velocity() -> void:
	if anim == null:
		return
		
	if state == State.DEAD:
		if anim.current_animation != "Die":
			anim.play("Die")
		
	elif state == State.HURT:
		if anim.current_animation != "Hurt":
			anim.play("Hurt")
			
		
	elif state == State.ATTACKING:
		
		if not anim.is_playing() or anim.current_animation != "Attack":

			anim.play("Attack")
	else:
		if velocity != Vector2.ZERO:
			anim.play("Run")
		else:
			anim.play("Idle")


func _on_attack_area_body_entered(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if body.is_in_group("players"):
		attacking += 1

func _on_attack_area_body_exited(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if body.is_in_group("players"):
		attacking -= 1



func _check_attack_landed():
	if not multiplayer.is_server():
		return
	
	var bodies = area_2d.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("players"):
			var dir_left = body.global_position < global_position
			body.velocity += Vector2(-300 if dir_left else 300, -200)
			body.decrease_health(damage)

func bounce_on_head(body: Node2D):
	if not multiplayer.is_server():
		return
	if body.is_in_group("players"):
		if body.prev_vel.y >0:
			body.velocity.y = body.prev_vel.y * -1

func anim_finished(anim_name):
	if not multiplayer.is_server():
		return
	if anim_name == "Hurt":
		hurting = false
	elif anim_name == "Die":
		rpc("despawn_enemy", enemy_id)

@rpc("any_peer", "call_local")
func update_health(id, hp):
	if id == enemy_id:
		health = hp

@rpc("any_peer", "call_local")
func despawn_enemy(id):
	if id == enemy_id:
		enemy.queue_free()
