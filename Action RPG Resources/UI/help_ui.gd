extends Control

var hearts = 4 setget set_hearts
var max_hearts = 4 setget set_max_hearts
var position = false
var check1 = true
var check2 = true
var check3 = true

onready var heart_ui_full = $HeartUIFull
onready var heart_ui_empty = $HeartUIEmpty
onready var conductor = $Conductor

func set_hearts(value):
	hearts = clamp(value, 0, max_hearts)
	
	if heart_ui_full != null:
		heart_ui_full.rect_size.x = hearts * 15
		
	if heart_ui_empty != null:
		heart_ui_empty.rect_size.x = max_hearts * 15

func set_max_hearts(value):
	max_hearts = max(value, 1)
	self.hearts = min(hearts, max_hearts)
	
func check_conductor(conductor):
	print(conductor.curr_beat)
	
func changePosition():
	heart_ui_full.rect_position = Vector2(0, 0)
	heart_ui_empty.rect_position = Vector2(0, 0)

func _ready():
	self.max_hearts = PlayerStats.max_health
	self.hearts = PlayerStats.health
	PlayerStats.connect("health_changed", self, "set_hearts")
	PlayerStats.connect("max_health_changed", self, "set_max_hearts")
	check_conductor(conductor)


func _on_Conductor_eighth_passed(beat, fract):
	if check3:
		check3 = false

func _on_Conductor_quarter_passed(beat):
	if !position:
		heart_ui_full.rect_scale= Vector2(1.1, 1.1)
		heart_ui_empty.rect_scale= Vector2(1.1, 1.1)
		heart_ui_empty.rect_position = Vector2(2, 10)
	else :
		heart_ui_empty.rect_position = Vector2(2, 8)
		heart_ui_full.rect_scale= Vector2(1, 1)
		heart_ui_empty.rect_scale= Vector2(1, 1)
	position = !position
	check1 = true
	check2 = true
	check3 = true
	
	


func _on_Conductor_sixteenth_passed(beat, fract):
	if check1:
		check1 = false


func _on_Conductor_twelth_passed(beat, fract):
	if check2:
		check2 = false
