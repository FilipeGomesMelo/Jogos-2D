extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Start_pressed():
	PlayerStats.set_health(4)
	HelpUi.current_score = 0
	get_tree().change_scene("res://World.tscn") # Replace with function body.


func _on_Exit_pressed():
	get_tree().quit() # Replace with function body.
