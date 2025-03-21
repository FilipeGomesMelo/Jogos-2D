extends Node2D

export (PackedScene) var enemy_scene
export var spawn_time = 3.0  # Tempo entre cada spawn
export var max_enemies = 5   # Número máximo de inimigos ativos
export var spawn_radius = 5.0 # Raio do Spawn

var enemies = []  # Lista para armazenar inimigos vivos

var active_enemies: int = 0  # Contador de inimigos ativos

# Called when the node enters the scene tree for the first time.
func spawn_enemy():
	
	var enemy = enemy_scene.instance()
	enemy.position = generate_random_vector() + self.position
	get_parent().add_child(enemy)
	enemies.append(enemy)
	
	enemy.connect("tree_exited", self, "_on_enemy_died", [enemy])

func _on_Timer_timeout():
	if enemies.size() < max_enemies:
		spawn_enemy()
		
func _on_enemy_died(enemy):
	if enemy in enemies:
		enemies.erase(enemy)  # Remove o inimigo da lista
		
func generate_random_vector() -> Vector2:
	var random_vector := Vector2(rand_range(-1, 1), rand_range(-1, 1))
	random_vector = random_vector.normalized() * randf() * spawn_radius
	return random_vector
