extends Node2D

@export var player_scene: PackedScene
@onready var spawn_point = $SpawnPoint

func _ready():
	# Host spawns all players (works also if you connect late)

	for id in multiplayer.get_peers():
		add_player(id)
	add_player(multiplayer.get_unique_id()) # host itself

func add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = spawn_point.position
	add_child(player)
	player.set_multiplayer_authority(id)
