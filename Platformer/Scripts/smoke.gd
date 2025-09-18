extends Node2D

@onready var smoke_anim: AnimatedSprite2D = $"."


func _ready() -> void:
	smoke_anim.animation_finished.connect(remove_smoke)

func remove_smoke():
	smoke_anim.queue_free()
