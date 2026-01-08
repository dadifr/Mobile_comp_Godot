extends Node2D

# Trascina qui la scena Freccia.tscn dall'inspector
@export var arrow_scene: PackedScene 
@export var fire_rate: float = 0.5

var can_shoot = true

func attack():
	if not can_shoot or not arrow_scene:
		return
	
	# 1. Recupera la direzione dal Giocatore (owner)
	# Impostiamo una direzione di default (destra) per sicurezza
	var direction = Vector2.RIGHT
	
	# Controlliamo se l'arco ha un proprietario (l'Elfo) e se questo ha la variabile 'last_direction'
	if owner and "last_direction" in owner:
		# Se last_direction non è zero (cioè se l'elfo si è mosso almeno una volta)
		if owner.last_direction != Vector2.ZERO:
			direction = owner.last_direction
	
	# 2. Istanzia la freccia
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	
	# 3. Assegna direzione e rotazione
	arrow.direction = direction
	arrow.rotation = direction.angle()
	
	# 4. Assegna lo shooter
	if owner:
		arrow.shooter = owner
	
	# 5. Aggiungi al mondo
	get_tree().root.add_child(arrow)
	
	# 6. Gestione Cooldown
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
