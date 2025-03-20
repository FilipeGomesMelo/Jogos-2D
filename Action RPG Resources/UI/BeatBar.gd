extends Node2D

export var target_position: Vector2
export var travel_time: float = 0.5

var tween: Tween

func _ready():
	tween = Tween.new()  # Cria uma instância do Tween
	add_child(tween)     # Adiciona o Tween à cena
	move_to_target()

func move_to_target():
	tween.interpolate_property(self, "position", position, target_position, travel_time, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	queue_free()  # Remove a barra ao chegar no centro
