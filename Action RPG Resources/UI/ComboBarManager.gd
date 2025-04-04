extends Node

signal height_changed(new_height)

var progressBarHeight = 0 setget set_progress_bar_height

func set_progress_bar_height(new_value):
	if new_value > 126:
		new_value = 126
	if new_value < 0:
		new_value = 0
	progressBarHeight = new_value
	emit_signal("height_changed", new_value)
