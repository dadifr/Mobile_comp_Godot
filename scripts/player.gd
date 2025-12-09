extends CharacterBody2D

# Velocità di movimento in pixel al secondo
@export var speed = 100.0

func _physics_process(delta):
	# Ottieni la direzione (Vettore normalizzato)
	# ui_left, ui_right, ecc. sono le frecce della tastiera predefinite
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		# Se premi un tasto, imposta la velocità
		velocity = direction * speed
	else:
		# Se non premi nulla, fermati subito
		velocity = Vector2.ZERO

	# Muovi il corpo gestendo le collisioni
	move_and_slide()
