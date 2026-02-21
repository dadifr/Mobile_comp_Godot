extends Area2D

@export var damage = 1

func _ready():
	# 1. Avvia l'animazione (Assicurati che Loop sia OFF nell'editor!)
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("default")
		$AnimatedSprite2D.animation_finished.connect(queue_free)
	
	# 2. Eseguiamo il danno IMMEDIATO
	# Aspettiamo un tempo brevissimo per far sì che la fisica si svegli
	await get_tree().create_timer(0.05).timeout
	check_damage()

func check_damage():
	# Recupera TUTTI i corpi che toccano l'esplosione in questo istante
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
				# Stampiamo in console per essere sicuri che funzioni
				print("Player colpito dall'esplosione!")

# Per sicurezza, teniamo anche il segnale se il player entra un istante dopo
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
