extends Area2D

@onready var collider: CollisionShape2D = $CollisionShape2D

@export var collider_size: Vector2 = Vector2(20,20)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collider.shape.size = collider_size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
