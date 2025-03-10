extends Control

const CIRCLE_SPEED = 1  # Velocidade do círculo se movendo para o coração
const START_RADIUS = 150  # Distância inicial dos círculos
export var circle_texture: Texture  # Defina a textura do círculo no editor

onready var beats_container = $BeatsContainer
onready var endzone = $Endzone
onready var conductor = $Conductor
var bigEndzone = false

func _ready():
	pass
	
func _on_Conductor_quarter_passed(beat):
	
	endzone.rect_scale =  Vector2(1, 1) if bigEndzone else Vector2(1.1, 1.1)
	bigEndzone = !bigEndzone
	
	# Criar um círculo
	var circle = TextureRect.new()
	circle.texture = circle_texture
	circle.rect_size = Vector2(10,10)  # Tamanho do círculo
	circle.rect_scale = Vector2(0.2, 0.2)

	# Define a posição inicial do círculo ao redor da endzone
	circle.rect_position = Vector2(endzone.rect_position.x - START_RADIUS, 0) 
	beats_container.add_child(circle)

	# Criar um Tween para animar o círculo até o coração
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(circle, "rect_position", circle.rect_position, endzone.rect_position, 1.5, Tween.TRANS_SINE, Tween.EASE_IN)
	
	# Conectar diretamente o sinal de finalização da animação
	tween.connect("tween_completed", self, "_on_tween_complete", [circle, tween])

	tween.start()

func _on_tween_complete(tween, object_id):
	# Remover o círculo e o Tween da árvore
	if object_id:
		object_id.queue_free()
	tween.queue_free()  # Também libera o tween
