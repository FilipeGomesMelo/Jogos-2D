extends Node2D

export (PackedScene) var enemy_scene
export var spawn_time = 20.0  # Tempo entre cada spawn
export var max_enemies = 5   # Número máximo de inimigos ativos
export var spawn_radius = 2.0 # Raio do Spawn

var enemies = []  # Lista para armazenar inimigos vivos

var timer  # Referência ao Timer

func _ready():
	# Criar e configurar o Timer
	timer = Timer.new()
	timer.wait_time = spawn_time
	timer.one_shot = false  # Continua rodando
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.start()

func spawn_enemy():
	if enemies.size() >= max_enemies:
		return

	var enemy = enemy_scene.instance()
	enemy.position = generate_random_vector() + self.position
	get_parent().add_child(enemy)
	enemies.append(enemy)
	
	enemy.connect("tree_exited", self, "_on_enemy_died", [enemy])

func _on_Timer_timeout():
	print("Timeout! Enemies count:", enemies.size())
	if enemies.size() < max_enemies:
		spawn_enemy()

func _on_enemy_died(enemy):
	if enemy in enemies:
		enemies.erase(enemy)
		print("Inimigo removido da lista. Total restante:", enemies.size())

func generate_random_vector() -> Vector2:
	var random_vector := Vector2(rand_range(-1, 1), rand_range(-1, 1))
	random_vector = random_vector.normalized() * randf() * spawn_radius
	return random_vector
