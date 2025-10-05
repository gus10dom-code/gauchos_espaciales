# res://Main.gd
extends Node

var current_level: Node = null
var level_index: int = 1

# Ajustá estas rutas a tus escenas reales
const LEVEL_PATHS: Dictionary = {
	1: "res://scenes/campo.tscn",
	2: "res://scenes/level_2.tscn",
	3: "res://scenes/level_3.tscn"
}

func _ready() -> void:
	load_level(level_index)

func load_level(index: int) -> void:
	if not LEVEL_PATHS.has(index):
		push_error("No existe LEVEL_PATHS[%s]" % index)
		return

	var path := String(LEVEL_PATHS[index])
	if path.is_empty():
		push_error("LEVEL_PATHS[%s] está vacío" % index)
		return

	# Verifica que el archivo exista
	if not FileAccess.file_exists(path):
		push_error("No se encontró el archivo: %s" % path)
		return

	# Libera el nivel anterior si existe
	if is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null

	# Carga y verifica que sea una PackedScene
	var packed := load(path)
	if not (packed is PackedScene):
		push_error("El recurso no es PackedScene: %s" % path)
		return

	current_level = (packed as PackedScene).instantiate()
	add_child(current_level)
	print("Nivel %d cargado: %s" % [index, path])

func level_up() -> void:
	if level_index < LEVEL_PATHS.size():
		level_index += 1
		load_level(level_index)
	else:
		print("Juego completado")
