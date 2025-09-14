extends Node

var peer = WebSocketMultiplayerPeer.new()



	
var players = {}
var player_inputs = {} # Stores the latest inputs for each player

var connected_players = 0
var max_players = 2


func _ready():
	if "--server" in OS.get_cmdline_args():
		start_server(1221, 2)

func start_server(port, max_clients):
	var key = CryptoKey.new()
	var cert = X509Certificate.new()
	
	var key_path = "res://server.key"
	var cert_path = "res://server.crt"
	
	debug_load_key_cert(key_path, cert_path)

	if not key.load(key_path):
		print("Failed to load private key: %s" % key_path)
		return

	if not cert.load(cert_path):
		print("Failed to load certificate: %s" % cert_path)
		return
	
	var tls_opts = TLSOptions.server(key, cert)
	
	max_players = max_clients	
	peer.create_server(port, "*", tls_opts)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server started on port %d. Waiting for %d players." % [port, max_players])

func debug_load_key_cert(key_path: String, cert_path: String) -> bool:
	print("exists key:", key_path, FileAccess.file_exists(key_path))
	print("exists cert:", cert_path, FileAccess.file_exists(cert_path))
	# print header lines
	if FileAccess.file_exists(key_path):
		var f = FileAccess.open(key_path, FileAccess.READ)
		if f:
			print("key header:", f.get_line())
			f.close()
	if FileAccess.file_exists(cert_path):
		var f2 = FileAccess.open(cert_path, FileAccess.READ)
		if f2:
			print("cert header:", f2.get_line())
			f2.close()
	var k = CryptoKey.new()
	var c = X509Certificate.new()
	print("CryptoKey.load():", k.load(key_path))
	print("X509Certificate.load():", c.load(cert_path))
	return k.load(key_path) and c.load(cert_path)


func _on_peer_connected(id):
	connected_players += 1
	player_inputs[id] = {"left": false, "right": false, "jump": false} # Initialize inputs
	print("Player connected: %d. Total players: %d/%d" % [id, connected_players, max_players])
	if connected_players >= max_players:
		print("Max players reached. Starting game...")
		rpc("switch_to_level", "res://Level_1.tscn")

func _on_peer_disconnected(id):
	connected_players -= 1
	player_inputs.erase(id)
	print("Player disconnected: %d. Total players: %d/%d" % [id, connected_players, max_players])
	if multiplayer.is_server() and connected_players == 0:
		print("All players have disconnected. Resetting server.")
		players.clear()
		player_inputs.clear()
		get_tree().change_scene_to_file("res://Main.tscn")

func start_client(ip, port):
	peer.create_client(("wss://{ip}:{port}/".format({"ip":ip, "port":port})))
	multiplayer.multiplayer_peer = peer

func get_player_id():
	return multiplayer.get_unique_id()

func get_all_player_ids():
	return Array(multiplayer.get_peers()) + [get_player_id()]

func register_player(id, player_node):
	players[id] = player_node

func unregister_player(id):
	players.erase(id)

@rpc("any_peer", "call_local")
func switch_to_level(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

# This RPC is called by clients to send their inputs.
# The server just stores them.
@rpc("any_peer", "call_local")
func receive_player_input(id, inputs):
	if multiplayer.is_server():
			# Don't just overwrite the old inputs. Continuous inputs (like left/right)
		# should be overwritten, but single-press actions (like jump) should be merged.
		if inputs.jump:
			player_inputs[id].jump = true
		
		player_inputs[id].left = inputs.left
		player_inputs[id].right = inputs.right
