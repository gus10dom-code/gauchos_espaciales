extends Node2D


func _on_boton_nivel_pressed() -> void:
	get_tree().change_scene_to_file("res://campo.tscn")


func _on_boton_nivel_2_pressed() -> void:
	get_tree().change_scene_to_file("res://level_2.tscn")
	
	

func _on_boton_nivel_3_pressed() -> void:
	get_tree().change_scene_to_file("res://level_3.tscn")


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://tutorial.tscn")

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	
	


func _on_exit_pressed() -> void:
	get_tree().quit()
