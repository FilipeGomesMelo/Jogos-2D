extends Node2D

export var bpm: int = 125  # Define o BPM da música
export var beat_point_scene: PackedScene  # Cena dos pontos/barras
export var num_bars: int = 2  # Barras aparecem apenas à esquerda e à direita
export var radius: float = 100  # Distância inicial das barras (próximo ao centro)
export var travel_time: float = 0.48  # Tempo que as barras demoram para chegar ao centro

onready var center = $CenterPoint  # Nó que representa o centro do indicador

var beat_time: float

func _ready():
	beat_time = 60.0 / bpm  # Calcula o tempo entre batidas
	start_beat_cycle()

func start_beat_cycle():
	while true:
		yield(get_tree().create_timer(beat_time), "timeout")
		spawn_beat_bars()

func spawn_beat_bars():
	if not beat_point_scene:
		print("Erro: beat_point_scene não foi atribuído no Inspetor!")
		return
	
	for i in range(num_bars):
		# Define a posição inicial das barras (esquerda e direita)
		var spawn_pos = center.position + Vector2((-1 if i == 0 else 1) * radius, 0)
		
		var beat_bar = beat_point_scene.instance()
		beat_bar.position = spawn_pos
		beat_bar.target_position = center.position
		beat_bar.travel_time = travel_time
		
		add_child(beat_bar)
