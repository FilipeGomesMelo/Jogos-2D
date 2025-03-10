extends Node2D

const ENEMY_SCENE = preload("res://Action RPG Resources/Enemies/Bat.tscn")

export (PackedScene) var enemy_scene
export var spawn_time = 3.0  # Tempo entre cada spawn
export var max_enemies = 5   # Número máximo de inimigos ativos
export var spawn_positions: Array = []  # Lista de posições possíveis para spawn

var enemies = []  # Lista para armazenar inimigos vivos

var spawn_points = []  # Lista de pontos de spawn
var beat_timer: Timer  # Timer para sincronizar com a música
var beat_interval: float  # Tempo entre batidas
var active_enemies: int = 0  # Contador de inimigos ativos



# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_positions = get_children()  # Assume que os filhos do spawner são os pontos de spawn
	spawn_enemy()  # Opcional: Spawn inicial
	start_spawning()
	
func start_spawning():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_time
	timer.autostart = true
	timer.connect("timeout", self, "_on_spawn_timer_timeout")
	
func _on_spawn_timer_timeout():
	if enemies.size() < max_enemies:
		spawn_enemy()

func spawn_enemy():
	if spawn_positions.empty():
		return
	
	var spawn_point = spawn_positions[randi() % spawn_positions.size()].global_position
	var enemy = enemy_scene.instance()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point
	enemies.append(enemy)
	
	enemy.connect("tree_exited", self, "_on_enemy_died", [enemy])
	
func _on_enemy_died(enemy):
	enemies.erase(enemy)  # Remove da lista quando morrer
