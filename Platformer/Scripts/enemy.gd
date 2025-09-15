extends CharacterBody2D

@export var speed: float = 120.0
@export var retarget_interval: float = 0.25  # hvor ofte vi leder efter nærmeste spiller

var _target: Node2D
var _retarget_timer := 0.0

func _physics_process(delta: float) -> void:
	_get_nearest_player()
	
func _get_nearest_player() -> Node2D:
	var nearest: Node2D = null
	var best_d2 := INF
	for p in get_tree().get_nodes_in_group("players"):
		# spring ugyldige/ikke synlige nodes over
		if not is_instance_valid(p):
			continue
		var d2 := global_position.distance_squared_to(p.global_position)
		if d2 < best_d2:
			best_d2 = d2
			nearest = p
	print(nearest)
	print_debug("Network players: ", Network.players.size())
	print_debug("Group players: ", get_tree().get_nodes_in_group("players").size())

	return nearest
