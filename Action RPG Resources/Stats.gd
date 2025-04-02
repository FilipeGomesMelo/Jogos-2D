extends Node

export var max_health = 1 setget set_max_health
var health = max_health setget set_health

signal no_health
signal health_changed(value)
signal max_health_changed(value)

func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)

func set_health(value):
	if value > 4:
		value = 4
	health = value
	emit_signal("health_changed", health)
	
	if health <= 0:
		emit_signal("no_health")
		
		# Criando um timer temporário para esperar 3 segundos
		var timer = Timer.new()
		add_child(timer)  # Adiciona o timer como filho da cena
		timer.wait_time = 3  # Define o tempo de espera
		timer.one_shot = true  # Faz com que o timer execute uma vez
		timer.start()
		
		# Espera 3 segundos para chamar a cena do menu
		yield(timer, "timeout")
		
		# Atualizando os scores
		if HelpUi.current_score > HelpUi.high_score:
			HelpUi.high_score = HelpUi.current_score
				
		HelpUi.previous_score = HelpUi.current_score
		# Carrega a cena do menu
		get_tree().change_scene("res://main_menu.tscn")

func _ready():
	health = max_health
