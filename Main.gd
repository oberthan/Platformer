extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene



func _on_host_pressed() -> void:
	peer.create_server(4242, 1)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player(multiplayer.get_unique_id())


func _on_join_pressed() -> void:
	peer.create_client("127.0.0.1", 4242)
	multiplayer.multiplayer_peer = peer


func add_player(id = 1):
	print("Player joined with id:", id)

# Host starts game
func _on_start_game_pressed():
	if multiplayer.is_server():
		rpc("switch_to_level", "res://Level_1.tscn")

@rpc("authority", "call_local")
func switch_to_level(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
