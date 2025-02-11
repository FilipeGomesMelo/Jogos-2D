extends Timer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const PLAYER_HURT_SOUND = preload("res://Action RPG Resources/Player/MetronomeSound.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.wait_time = 60 / 120 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_WorldTimer_timeout():
	var player_hurt_sound = PLAYER_HURT_SOUND.instance()
	get_tree().current_scene.add_child(player_hurt_sound)
