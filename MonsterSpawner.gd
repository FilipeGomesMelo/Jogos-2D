extends Node2D

export (PackedScene) var enemy_scene
export var spawn_time = 10.0  # Tempo base entre cada spawn
export var max_enemies = 2   # Número máximo de inimigos ativos
export var spawn_radius = 8.0 # Raio do Spawn
export var difficulty_increase_rate = 0.98  # Quanto o tempo de spawn diminui a cada spawn
export var max_speed_increase = 5  # Aumento da velocidade dos inimigos por spawn
export var points_for_kill = 10

var enemies = []  # Lista para armazenar inimigos vivos
var timer  # Referência ao Timer
var elapsed_time = 0  # Tempo total passado no jogo

func _ready():
	spawn_enemy()
	timer = Timer.new()
	timer.wait_time = spawn_time
	timer.one_shot = false  # Continua rodando
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.start()
	

func spawn_enemy():
	if enemies.size() >= max_enemies:
		return
	print("enemies: ", enemies.size())
	var enemy = enemy_scene.instance()
	
	if randf() <= 0.25:
		enemy.update_type('RANGED')

	# Aumenta a velocidade máxima do inimigo conforme o tempo passa
	enemy.MAX_SPEED += (elapsed_time / 60.0) * max_speed_increase
	enemy.MAX_SPEED = min(enemy.MAX_SPEED, 90)  # Limita a velocidade a 90
	print(enemy.MAX_SPEED)
	
	enemy.position = generate_random_vector() + self.position
	get_parent().add_child(enemy)
	enemies.append(enemy)
	
	enemy.connect("tree_exited", self, "_on_enemy_died", [enemy])

func _on_Timer_timeout():
	if enemies.size() < max_enemies:
		spawn_enemy()
	
	# Reduz o tempo de spawn para aumentar a frequência de inimigos
	spawn_time *= difficulty_increase_rate
	timer.wait_time = max(1.0, spawn_time)  # Evita que o tempo fique muito baixo
	timer.start()

	# Atualiza o tempo total passado no jogo
	elapsed_time += spawn_time

func _on_enemy_died(enemy):
	if enemy in enemies:
		enemies.erase(enemy)  # Remove o inimigo da lista
		HelpUi.current_score += points_for_kill
		
func generate_random_vector() -> Vector2:
	var random_vector := Vector2(rand_range(-1, 1), rand_range(-1, 1))
	random_vector = random_vector.normalized() * randf() * spawn_radius
	return random_vector
