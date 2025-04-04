extends Control

onready var bar_empty = $ComboBarEmpty
onready var bar_progress = $ComboBarProgress
onready var bar_full = $ComboBarFull

var isFull = false
var isBig = false
var barTween = Tween.new()   

func _ready():
	if Conductor:
		Conductor.connect("quarter_passed", self, "_on_Conductor_quarter_passed")
	bar_progress.rect_size.x = 0
	ComboBarManager.connect("height_changed", self, "set_progress_bar_height")
	add_child(barTween)

func set_progress_bar_height(x):
	if(x >= 126):
		bar_full.visible = true
		bar_progress.rect_size.x = 126
		barTween
		isFull = true
	else:
		isFull = false
		bar_full.visible = false
		var finalValue = Vector2(x, bar_progress.rect_size.y)
		barTween.interpolate_property(bar_progress, 'rect_size', bar_progress.rect_size, finalValue, 1)
		barTween.start()
