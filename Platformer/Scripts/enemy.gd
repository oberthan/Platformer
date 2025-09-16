extends CharacterBody2D

@export var speed: float = 140.0
@export var acceleration: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 1800.0
@export var run_threshold: float = 10.0 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Area2D/hitbox
@onready var area_2d: Area2D = $Area2D

@onready var health_bar: ProgressBar = $ProgressBar
@onready var sb = StyleBoxFlat.new()

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var health: float = 59

var _target: Node2D = null

func _ready() -> void:
	set_multiplayer_authority(1)
	set_physics_process(multiplayer.is_server())

	if multiplayer.is_server():
		_reacquire_target()
		get_tree().connect("node_added", Callable(self, "_on_tree_changed"))
		get_tree().connect("node_removed", Callable(self, "_on_tree_changed"))

		animated_sprite_2d.animation_finished.connect(_attack_animation_finished)
		area_2d.body_entered.connect(_on_attack_area_body_entered)
		animated_sprite_2d.frame_changed.connect(_on_frame_changed)
		
	hitbox.disabled = true
	area_2d.monitoring = false

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

func _reacquire_target() -> void:

	var best: Node2D = null
	var dist = 100000 #Detection range

	for id in Network.players:
		var player = Network.players[id]
		if is_instance_valid(player) and player is Node2D:
			var distance = (player.global_position - global_position).length_squared()
			if distance < dist:
				dist = distance
				best = player

	_target = best

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	_reacquire_target()

	var dir_x = 0.0
	if _target:
		var distance = (_target.global_position - global_position).length_squared()
		if distance < 7500:
			velocity.x = 0
			attacking = true
		
		else:
			var dx = _target.global_position.x - global_position.x
			dir_x = sign(dx)

			velocity.x = move_toward(velocity.x, speed * dir_x, acceleration * delta)


	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	if attacking:
		velocity.x = 0

	move_and_slide()

	_play_anim_from_velocity()

	rpc("_sync_state", global_position, velocity)

@rpc("authority", "call_local", "unreliable")
func _sync_state(pos: Vector2, vel: Vector2) -> void:
	if multiplayer.is_server():
		return
	global_position = pos
	velocity = vel
	_play_anim_from_velocity()

func _play_anim_from_velocity() -> void:
	if anim == null:
		return

	var target_anim = "idle"

	if attacking:
		if anim.animation != "attack" or not anim.is_playing():
			anim.play("attack")
		return

	if abs(velocity.x) >= run_threshold:
		target_anim = "run"

	if abs(velocity.x) >= 1.0:
		if velocity.x > 0:
			anim.flip_h = true
			hitbox.position.x = 25
		else:
			anim.flip_h = false
			hitbox.position.x = -25

	# Only switch if changed
	if anim.animation != target_anim or not anim.is_playing():
		anim.play(target_anim)

var attacking = false

func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		attacking = true
		body.velocity += (body.global_position - global_position) * 20
		body.decrease_health(10)
		hitbox.disabled = true
		area_2d.monitoring = false

func _attack_animation_finished():
	attacking = false
	hitbox.disabled = true
	area_2d.monitoring = false
		
func _on_frame_changed():
	if animated_sprite_2d.animation == "attack":
		if animated_sprite_2d.frame == 5:
			hitbox.disabled = false
			area_2d.monitoring = true
		elif animated_sprite_2d.frame == 8:
			hitbox.disabled = true
			area_2d.monitoring = false
			
