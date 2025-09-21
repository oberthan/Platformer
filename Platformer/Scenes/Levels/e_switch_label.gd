extends Label

@onready var sprite = $Sprite2D

func _ready() -> void:
	if len(Network.get_all_player_ids()) == 1 and "--server" not in OS.get_cmdline_args():
		text = "Press      to switch character"
		sprite.visible = true
