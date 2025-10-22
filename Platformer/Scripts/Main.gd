extends Node2D

#var ip_address_input = LineEdit.new()

#func _ready():
	#ip_address_input.text = "dis-responded-scoring-evaluated.trycloudflare.com"
	#var container = $VBoxContainer
	#container.add_child(ip_address_input)

func _on_single_player_pressed() -> void:
	Network.start_server(1221, 1)
	Network.max_players = 1
	Network._on_peer_connected(multiplayer.multiplayer_peer.get_unique_id())

func _on_host_pressed() -> void:
	Network.start_server(1221, 2)
	Network._on_peer_connected(multiplayer.multiplayer_peer.get_unique_id())
	# The server will automatically switch to the level when it's ready.

func _on_join_pressed() -> void:
	var ip = "dis-responded-scoring-evaluated.trycloudflare.com"
	#var ip = ip_address_input.text
	$"VBoxContainer/Single Player".disabled = true
	$VBoxContainer/Join.disabled = true
	Network.start_client(ip)
	


func _on_start_game_pressed():
	if Network.is_server:
		Network.rpc("switch_to_level", "res://Scenes/Levels/Level_1.tscn")
