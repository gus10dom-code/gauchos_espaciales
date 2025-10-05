extends Node

signal twenty_reached

var counter: int = 0
const TARGET: int = 20

func reset_counter() -> void:
	counter = 0

func register_progress() -> void:
	counter += 1
	print("Progreso: %d / %d" % [counter, TARGET])
	if counter >= TARGET:
		counter = 0
		emit_signal("twenty_reached")
