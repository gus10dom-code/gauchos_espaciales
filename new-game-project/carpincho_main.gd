extends CharacterBody2D

@export var speed: float = 100.0

func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO

	# --- Movimiento básico con WASD o flechas ---
	if Input.is_action_pressed("derecha"):
		$AnimatedSprite2D.play("derecha")
		$AnimatedSprite2D.flip_h = false
		dir.x += 1
	if Input.is_action_pressed("izquierda"):
		$AnimatedSprite2D.play("izquierda")
		$AnimatedSprite2D.flip_h = false
		dir.x -= 1
	if Input.is_action_pressed("abajo"):
		$AnimatedSprite2D.play("frente")
		dir.y += 1
	if Input.is_action_pressed("arriba"):
		$AnimatedSprite2D.play("arriba")
		dir.y -= 1

	# --- Quieto ---
	if dir == Vector2.ZERO:
		$AnimatedSprite2D.play("quieto")

	# --- Movimiento real ---
	velocity = dir.normalized() * speed
	move_and_slide()
