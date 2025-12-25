extends RigidBody2D

@export var damage = 5

# Variabile per assicurarci che esploda una volta sola
var exploded = false

func _ready():
	# Colleghiamo il timer
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	explode()

func explode():
	# PROTEZIONE 1: Evita doppie esplosioni (se timer e collisione accadono insieme)
	if exploded:
		return
	exploded = true
	
	# 1. VISUAL
	$AnimatedSprite2D.play("explosion")
	$AnimatedSprite2D.scale = Vector2(4, 4) 
	
	# Blocchiamo la bomba dov'è, così non rotola via mentre esplode
	freeze = true 
	
	# 2. LOGICA SICURA: Attiva l'area di danno
	# IMPORTANTE: Usiamo set_deferred invece di cambiare "monitoring" direttamente.
	# Questo evita crash se il motore fisico sta lavorando in quel momento.
	$BlastArea.set_deferred("monitoring", true)
	
	# PROTEZIONE 2: Tempismo Fisico
	# Invece di un timer a caso (0.1), aspettiamo esattamente 2 frame fisici.
	# Questo garantisce che Godot abbia aggiornato la lista dei corpi sovrapposti.
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 3. DANNO: Cerca chi c'è nell'area
	var bodies = $BlastArea.get_overlapping_bodies()
	
	for body in bodies:
		# PROTEZIONE 3: Il corpo esiste ancora?
		# Se un nemico muore nello stesso istante, questa riga evita il crash.
		if not is_instance_valid(body):
			continue
		
		# Evitiamo che la bomba colpisca se stessa
		if body == self:
			continue

		# Gestione Danno
		if body.has_method("take_damage"):
			# Logica originale: Se è il player, fa solo 1 danno
			if body.is_in_group("player"):
				body.take_damage(2, global_position)
			else:
				# Altrimenti fa danno pieno (es. ai nemici)
				body.take_damage(damage, global_position)

	# 4. PULIZIA
	# Aspettiamo che l'animazione finisca prima di sparire, altrimenti non si vede il BOOM!
	await $AnimatedSprite2D.animation_finished
	queue_free()
