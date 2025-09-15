extends CharacterBody2D

@export var speed: float = 140.0
@export var acceleration: float = 800.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 1800.0
@export var run_threshold: float = 10.0 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _target: Node2D = null

func _ready() -> void:
	set_multiplayer_authority(1)
	set_physics_process(multiplayer.is_server())

	if multiplayer.is_server():
		_reacquire_target()
		get_tree().connect("node_added", Callable(self, "_on_tree_changed"))
		get_tree().connect("node_removed", Callable(self, "_on_tree_changed"))

	_play_anim_from_velocity()

func _on_tree_changed(_n: Node) -> void:
	if multiplayer.is_server():
		_reacquire_target()

func _reacquire_target() -> void:

	var best: Node2D = null
	var dist = 0

	for id in Network.players:
		var player = Network.players[id]
		if is_instance_valid(player) and player is Node2D:
			var distance = (player.global_position - global_position).length_squared()
			if distance > dist:
				dist = distance
				best = player

	_target = best

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	_reacquire_target()

	var dir_x = 0.0
	if _target:
		var dx = _target.global_position.x - global_position.x
		dir_x = sign(dx)

	velocity.x = move_toward(velocity.x, speed * dir_x, acceleration * delta)

	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

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
	if abs(velocity.x) >= run_threshold:
		target_anim = "run"

	if abs(velocity.x) >= 1.0:
		anim.flip_h = velocity.x > 0.0

	# Only switch if changed
	if anim.animation != target_anim or not anim.is_playing():
		anim.play(target_anim)
