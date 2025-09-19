extends Node

@export var enemy_amt = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	enemy_amt = get_tree().get_nodes_in_group("enemies").size()
	if enemy_amt <= 0:
		Network.rpc("switch_to_level", "res://Scenes/Levels/Level_1.tscn")
