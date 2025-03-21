extends Area2D

var player = null
var vector = Vector2.ZERO
export var target_radius = 35
export var attack_radius = 50

func set_target_radius(radius):
	target_radius = radius

func set_attack_radius(radius):
	attack_radius = radius

func can_see_player():
	return player != null

func _on_PlayerDetection_body_entered(body):
	player = body
	vector = (self.global_position - player.global_position).normalized() * target_radius

func recalculate_vector():
	if player != null:
		vector = (self.global_position - player.global_position).normalized() * target_radius

func _on_PlayerDetection_body_exited(_body):
	player = null

func get_target_position():
	if player:
		return player.global_position + vector
	else:
		return Vector2.ZERO

func is_within_attack_range(position):
	if player:
		if player.global_position.distance_to(global_position) < attack_radius:
			return true
	return false
