extends CharacterBody2D

var direction = 1
var steps = 0

func _physics_process(delta: float) -> void:

	steps += delta
	
	if steps > 5:
		direction *= -1
		steps = 0
	velocity.x = 100 * direction
	


	move_and_slide()
