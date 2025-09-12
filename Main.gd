extends Node2D

var ip_address_input = LineEdit.new()

func _ready():
	ip_address_input.text = "127.0.0.1"
	ip_address_input.position = Vector2(100, 150)
	add_child(ip_address_input)

func _on_host_pressed() -> void:
	Network.start_server(4242, 2)
	# The server will automatically switch to the level when it's ready.

func _on_join_pressed() -> void:
	var ip = ip_address_input.text
	Network.start_client(ip, 4242)


func _on_start_game_pressed():
	if Network.is_server:
		Network.rpc("switch_to_level", "res://Level_1.tscn")
