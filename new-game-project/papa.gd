extends StaticBody2D

var selected := false
var seed_type = 2

func _ready() -> void:
	$AnimatedSprite2D.play("bolsa_papa")

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Input.is_action_just_pressed("click"):
		NewScript.plant_selected = seed_type
		selected = true
#	elif Input.is_action_just_released("click"):
#		selected = false

func _physics_process(delta: float) -> void:
	if selected:
		global_position = global_position.lerp(get_global_mouse_position(), 25 * delta)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			selected = false
			
