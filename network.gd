extends Node

var peer = ENetMultiplayerPeer.new()
var is_server = false
var players = {}

func _ready():
	if "--server" in OS.get_cmdline_args():
		start_server(4242, 2)

func start_server(port, max_clients):
	is_server = true
	peer.create_server(port, max_clients)
	multiplayer.multiplayer_peer = peer
	print("Server started on port %d" % port)

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
			players[id].apply_server_input(inputs, get_process_delta_time())
