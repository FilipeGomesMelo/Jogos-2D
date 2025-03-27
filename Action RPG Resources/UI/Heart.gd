extends Area2D

var blink_interval = 0.5
var is_blinking = true

func _on_Heart_body_entered(body):
	if body.is_in_group("player"):
		PlayerStats.set_health(PlayerStats.health + 1)
		queue_free()

func _ready():
	start_blinking()
	yield(get_tree().create_timer(5), "timeout")
	is_blinking = false
	queue_free()

func start_blinking(): 
	var tweenBlink = Tween.new()   
	add_child(tweenBlink)
	while is_blinking:
		tweenBlink.interpolate_property(self, "modulate:a", 1, 0, blink_interval / 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tweenBlink.start()
		yield(get_tree().create_timer(blink_interval / 2), "timeout") 

		tweenBlink.interpolate_property(self, "modulate:a", 0, 1, blink_interval / 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tweenBlink.start()
		yield(get_tree().create_timer(blink_interval / 2), "timeout")

		blink_interval *= 0.9
