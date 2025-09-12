extends Node2D

@export var player_scene: PackedScene
@onready var spawn_point = $SpawnPoint

func _ready():
	if Network.is_server:
		for id in Network.get_all_player_ids():
			if id == 1 and "--server" not in OS.get_cmdline_args():
				add_player(id)
			elif id != 1:
				add_player(id)

		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)

# This function is only called on the server
func add_player(id: int):
	rpc("spawn_player_on_clients", id)

# This function is only called on the server
func remove_player(id: int):
	rpc("despawn_player_on_clients", id)

@rpc("any_peer", "call_local")
func spawn_player_on_clients(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = spawn_point.position
	add_child(player)
	player.set_multiplayer_authority(id)
	if Network.is_server:
		Network.register_player(id, player)

@rpc("any_peer", "call_local")
func despawn_player_on_clients(id: int):
	if has_node(str(id)):
		var player = get_node(str(id))
		if Network.is_server:
			Network.unregister_player(id)
		player.queue_free()
