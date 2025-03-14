extends Control

const CIRCLE_SPEED = 1  # Velocidade do círculo se movendo para o coração
const START_RADIUS = 100  # Distância inicial dos círculos
export var circle_texture: Texture  # Defina a textura do círculo no editor

onready var beats_container = $BeatsContainer
onready var endzone = $Endzone

var bigEndzone = false

func _ready():
	if Conductor:
		Conductor.connect("quarter_passed", self, "_on_Conductor_quarter_passed")
	
func _on_Conductor_quarter_passed(beat):

	endzone.rect_scale =  Vector2(1, 1) if bigEndzone else Vector2(1.1, 1.1)
	bigEndzone = !bigEndzone
	
	# Criar um círculo
	var circle = TextureRect.new()
	circle.texture = circle_texture
	circle.rect_size = Vector2(10,10)  # Tamanho do círculo
	circle.rect_scale = Vector2(0.2, 0.2)
	
	var circle2 = TextureRect.new()
	circle2.texture = circle_texture
	circle2.rect_size = Vector2(10,10)  # Tamanho do círculo
	circle2.rect_scale = Vector2(0.2, 0.2)

	# Define a posição inicial do círculo ao redor da endzone
	circle.rect_position = Vector2(endzone.rect_position.x - START_RADIUS, endzone.rect_position.y) 
	beats_container.add_child(circle)
	
	circle2.rect_position = Vector2(endzone.rect_position.x + START_RADIUS, endzone.rect_position.y) 
	beats_container.add_child(circle2)

	# Criar um Tween para animar o círculo até o coração
	var tween = Tween.new()
	var tween2 = Tween.new()	
	add_child(tween)
	add_child(tween2)
	
	tween.interpolate_property(circle, "rect_position", circle.rect_position, endzone.rect_position, CIRCLE_SPEED, Tween.TRANS_SINE, Tween.TRANS_LINEAR)
	tween2.interpolate_property(circle2, "rect_position", circle2.rect_position, endzone.rect_position, CIRCLE_SPEED, Tween.TRANS_SINE, Tween.TRANS_LINEAR)	
	# Conectar diretamente o sinal de finalização da animação
	tween.connect("tween_all_completed", self, "_on_tween_complete", [circle, tween])
	tween2.connect("tween_all_completed", self, "_on_tween_complete", [circle2, tween2])
	
	tween.start()
	tween2.start()
	

func _on_tween_complete(object, tween):
	# Remover o círculo e o Tween da árvore
	if object:
		object.queue_free()
	if tween:
		tween.queue_free()
