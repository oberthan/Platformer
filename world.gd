extends Node2D

func _ready() -> void:
	# Connect after the world is loaded
	Network.peer_ready.connect(_on_peer_ready)

	# Spawn local player immediately once world is ready
	var my_id = multiplayer.get_unique_id()
	Network._spawn_player_for_peer(my_id)

func _on_peer_ready(id: int) -> void:
	# Server tells us another peer joined
	if multiplayer.is_server():
		Network._spawn_player_for_peer(id)

func _physics_process(delta: float) -> void:
	var my_id := multiplayer.get_unique_id()
	var players_node := $Players
	if players_node.has_node(str(my_id)):
		var local_player = players_node.get_node(str(my_id))
		if not local_player.is_multiplayer_authority():
			local_player.send_local_input()
