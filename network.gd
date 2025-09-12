extends Node

var peer = ENetMultiplayerPeer.new()
var is_server = false
var players = {}

var connected_players = 0
var max_players = 2

func _ready():
	if "--server" in OS.get_cmdline_args():
		start_server(4242, 2)

func start_server(port, max_clients):
	is_server = true
	max_players = max_clients
	peer.create_server(port, max_clients)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server started on port %d. Waiting for %d players." % [port, max_players])

func _on_peer_connected(id):
	connected_players += 1
	print("Player connected: %d. Total players: %d/%d" % [id, connected_players, max_players])
	if connected_players >= max_players:
		print("Max players reached. Starting game...")
		rpc("switch_to_level", "res://Level_1.tscn")

func _on_peer_disconnected(id):
	connected_players -= 1
	print("Player disconnected: %d. Total players: %d/%d" % [id, connected_players, max_players])

func start_client(ip, port):
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer

func get_player_id():
	return multiplayer.get_unique_id()

func get_all_player_ids():
	return multiplayer.get_peers() + [get_player_id()]

func register_player(id, player_node):
	players[id] = player_node

func unregister_player(id):
	players.erase(id)

@rpc("any_peer", "call_local")
func switch_to_level(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

@rpc(any_peer, "call_local")
def receive_player_input(id, inputs):
	if is_server:
		if players.has(id):
			players[id].apply_server_input(inputs, get_physics_process_delta_time())
