extends Area2D

@onready var collider: CollisionShape2D = $CollisionShape2D

@export var collider_size: Vector2 = Vector2(20,20)
@export var deal_damage_to: String = "players"
@export var damage: float = 20
@export var active: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collider.shape.size = collider_size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func deal_damage(body: Node2D):
	if not active:
		return
	if not multiplayer.is_server():
		return
	
	if body.is_in_group(deal_damage_to):
		body.decrease_health(damage)
