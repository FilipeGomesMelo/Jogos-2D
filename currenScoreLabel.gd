extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var default_text = "CURRENT SCORE: "


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var text = str(default_text, str(HelpUi.current_score))
	self.text = (text)
