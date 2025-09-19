extends Node2D

@export var player_scene: PackedScene
@onready var spawn_point = $SpawnPoint


var role_counter: int = 1

func _ready():
	rpc("level_loaded")
	
var loaded = 0
@rpc("any_peer", "call_local")
func level_loaded():
	loaded += 1
	if loaded >= len(Network.get_all_player_ids()):
		_everyone_ready()
	

func _everyone_ready():
	if multiplayer.is_server():
		# The server does not need a background. Remove it to save resources.
		var background = find_child("Forest", false) # find_child is not recursive by default
		if background:
			background.queue_free()
		
		for id in Network.get_all_player_ids():
			if id == 1 and "--server" not in OS.get_cmdline_args():
				add_player(id)
			elif id != 1:
				add_player(id)

		multiplayer.peer_connected.connect(add_player)
		#multiplayer.peer_disconnected.connect(remove_player)

# This function is only called on the server
func add_player(id: int):
	rpc("spawn_player_on_clients", id, role_counter)
	role_counter+=1
	

# This function is only called on the server
func remove_player(id: int):
	rpc("despawn_player_on_clients", id)

@rpc("any_peer", "call_local")
func spawn_player_on_clients(id: int, role: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = spawn_point.position + Vector2(50*role, 0)
	
	player.player_role = role
	print("Player has role ", role)
	add_child(player)
	player.add_to_group("players")
	player.set_multiplayer_authority(id)
	if multiplayer.is_server():
		Network.register_player(role, player)

@rpc("any_peer", "call_local")
func despawn_player_on_clients(id: int):
	pass
	#if has_node(str(id)):
		#var player = get_node(str(id))
		#if multiplayer.is_server():
			#Network.unregister_player(id)
		#player.queue_free()

func _physics_process(delta):
	if multiplayer.is_server():
		for player_id in Network.players:
			if Network.player_inputs.has(player_id):
				
				var player_node = Network.players[player_id]
				if player_node:
					var inputs = Network.player_inputs[player_id]
					player_node.apply_server_input(inputs, delta)
					
					# Reset the jump input after it has been processed.
					Network.player_inputs[player_id].jump = false
					Network.player_inputs[player_id].attack1 = false
					Network.player_inputs[player_id].switch = false
					if player_node.reset_level:
						print(player_id, " has activated level reset")
						reset_level()
						player_node.reset_level = false



func reset_level():
	Network.reload_level(get_tree().current_scene.scene_file_path)
	
