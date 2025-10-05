extends StaticBody2D

@onready var plant_sprite: AnimatedSprite2D = $pl_girasol
@onready var timer_girasol: Timer = $Timer_girasol
@onready var timer_papa: Timer = $Timer_papa
@onready var timer_trigo: Timer = $Timer_trigo  # NUEVO: timer para trigo

var plant: int = 1
var plantgrowing: bool = false
var plant_grown: bool = false

func _physics_process(_delta: float) -> void:
	if not plantgrowing:
		plant = NewScript.plant_selected

func _on_area_2d_area_entered(area: Area2D) -> void:
	if plantgrowing:
		print("Ya hay una planta creciendo aquí.")
		return

	match plant:
		1:
			plantgrowing = true
			plant_sprite.play("girasol")
			plant_sprite.frame = 0
			timer_girasol.start()
			
		2:
			plantgrowing = true
			plant_sprite.play("papa")
			plant_sprite.frame = 0
			timer_papa.start()
			
		3:  # NUEVO: trigo
			plantgrowing = true
			plant_sprite.play("trigo")
			plant_sprite.frame = 0
			timer_trigo.start()
			
		_:
			return

func _on_timer_girasol_timeout() -> void:
	if plant_sprite.animation != "girasol":
		return
	if plant_sprite.frame == 0:
		plant_sprite.frame = 1
		timer_girasol.start()
	elif plant_sprite.frame == 1:
		plant_sprite.frame = 2
		plant_grown = true
		plantgrowing = false

func _on_timer_papa_timeout() -> void:
	if plant_sprite.animation != "papa":
		return
	if plant_sprite.frame == 0:
		plant_sprite.frame = 1
		timer_papa.start()
	elif plant_sprite.frame == 1:
		plant_sprite.frame = 2
		plant_grown = true
		plantgrowing = false

# NUEVO: crecimiento de trigo
func _on_timer_trigo_timeout() -> void:
	if plant_sprite.animation != "trigo":
		return
	if plant_sprite.frame == 0:
		plant_sprite.frame = 1
		timer_trigo.start()
	elif plant_sprite.frame == 1:
		plant_sprite.frame = 2
		plant_grown = true
		plantgrowing = false

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and Input.is_action_just_pressed("click"):
		if plant_grown:
			match plant:
				1:
					NewScript.numofgirasol += 1
				2:
					NewScript.numofpapa += 1
				3:  # NUEVO: cosecha de trigo
					NewScript.numoftrigo += 1

			plantgrowing = false
			plant_grown = false
			plant_sprite.play("none")  # asegurate de tener la animación "none" vacía

			print("Número de girasoles: " + str(NewScript.numofgirasol))
			print("Número de papas: " + str(NewScript.numofpapa))
			print("Número de trigos: " + str(NewScript.numoftrigo))  # NUEVO
