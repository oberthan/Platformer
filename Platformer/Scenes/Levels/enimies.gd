extends Node

@export var enemy_amt = 0
@onready var goal: Label = $"../CanvasLayer/Goal"

var goalText = "Kill all enemies: "

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var amt = get_tree().get_nodes_in_group("enemies").size()
	if enemy_amt != amt:
		enemy_amt = amt
		goal.text = str(goalText, enemy_amt, " remaining!")
	if enemy_amt <= 0:
		Network.rpc("switch_to_level", "res://Scenes/Levels/Level_2.tscn")
