extends RigidBody2D

@export var damage = 5

func _ready():
	# Colleghiamo il timer
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	explode()

func explode():
	# 1. VISUAL
	$AnimatedSprite2D.play("explosion")
	$AnimatedSprite2D.scale = Vector2(2, 2) # Diventa grande (effetto boom economico)
	
	# 2. LOGICA: Attiva l'area di danno
	# Dobbiamo aspettare un micro-secondo che la fisica si aggiorni
	$BlastArea.monitoring = true
	
	await get_tree().create_timer(0.1).timeout # Aspetta un attimo per rilevare i nemici
	
	# 3. DANNO: Cerca chi c'è nell'area
	var bodies = $BlastArea.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			
		
		elif body.is_in_group("player"):
			body.take_damage(1) 
			pass

	# 4. PULIZIA: Rimuovi la bomba
	queue_free()
