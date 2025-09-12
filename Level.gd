extends Node2D

@export var player_scene: PackedScene
@onready var spawn_point = $SpawnPoint

func _ready():
	if Network.is_server:
		for id in Network.get_all_player_ids():
			# If we are the server, and not in dedicated server mode, spawn a player for us.
			if id == 1 and "--server" not in OS.get_cmdline_args():
				add_player(id)
			# Spawn players for all clients
			elif id != 1:
				add_player(id)

		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)

func add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = spawn_point.position
	add_child(player)
	player.set_multiplayer_authority(id)
	Network.register_player(id, player)

func remove_player(id: int):
	var player = get_node(str(id))
	if player:
		player.queue_free()
		Network.unregister_player(id)
