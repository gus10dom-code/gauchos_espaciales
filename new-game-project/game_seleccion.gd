extends Node
class_name GameState

signal level_up(new_level: int, unlocked_crop: String)
signal request_load_level(level_index: int)

var current_level := 1
var crop_counts := {"girasol": 0, "papa": 0, "trigo": 0}

# Escenas de cada nivel
var level_scenes := {
	1: "res://scenes/Level1.tscn",
	2: "res://scenes/Level2.tscn",
	3: "res://scenes/Level3.tscn",
}

# Reglas de pase de nivel por conteo de cultivos
var level_rules := {
	1: {"require": {"girasol": 10}, "unlock_crop": "papa"},
	2: {"require": {"papa": 12}, "unlock_crop": "trigo"},
	3: {"require": {"trigo": 15}, "unlock_crop": ""}, # último nivel
}

func add_harvest(crop_name: String, amount: int = 1) -> void:
	crop_counts[crop_name] = crop_counts.get(crop_name, 0) + amount
	print("Cosechaste ", crop_name, ": ", crop_counts[crop_name])
	_check_level_progress()

func _check_level_progress() -> void:
	var rule := level_rules.get(current_level)
	if rule == null: return
	for crop in rule.require.keys():
		if crop_counts.get(crop, 0) < int(rule.require[crop]):
			return
	var new_crop := String(rule.unlock_crop)
	current_level += 1
	print("¡Nivel superado! Pasando al nivel ", current_level)
	emit_signal("level_up", current_level, new_crop)
	emit_signal("request_load_level", current_level)

func get_scene_for_level(i: int) -> String:
	return level_scenes.get(i, "")
