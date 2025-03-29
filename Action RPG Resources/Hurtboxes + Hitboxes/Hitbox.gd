extends Area2D

export var damage = 1.0

onready var collisionShape = $CollisionShape2D

func enable():
	collisionShape.disabled = false

func disable():
	collisionShape.disabled = true
