extends RigidBody2D

@export var damage = 5
# NUOVO: Danno massiccio contro le strutture (Spawner, Casse, Muri distruttibili)
@export var structure_damage = 30 

# Variabile per assicurarci che esploda una volta sola
var exploded = false

# RIFERIMENTO AL NODO AUDIO (Aggiunto)
@onready var sfx_explosion = $AudioStreamPlayer2D

func _ready():
	# Colleghiamo il timer
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	explode()

func explode():
	# PROTEZIONE 1: Evita doppie esplosioni
	if exploded:
		return
	exploded = true
	
	# 1. VISUAL E AUDIO
	$AnimatedSprite2D.play("explosion")
	$AnimatedSprite2D.scale = Vector2(4, 4) 
	
	# Facciamo partire il suono dell'esplosione! (Aggiunto)
	sfx_explosion.play()
	
	# Blocchiamo la bomba dov'è
	freeze = true 
	
	# 2. LOGICA SICURA: Attiva l'area di danno
	$BlastArea.set_deferred("monitoring", true)
	
	# PROTEZIONE 2: Tempismo Fisico (2 frame di attesa)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 3. DANNO: Cerca chi c'è nell'area
	var bodies = $BlastArea.get_overlapping_bodies()
	
	for body in bodies:
		# PROTEZIONE 3: Il corpo esiste ancora?
		if not is_instance_valid(body):
			continue
		
		# Evitiamo che la bomba colpisca se stessa
		if body == self:
			continue

		# Gestione Danno
		if body.has_method("take_damage"):
			
			# CASO A: È il Player (Danno ridotto)
			if body.is_in_group("player"):
				body.take_damage(2, global_position)
			
			# CASO B: È uno Spawner (Riconosciuto perché ha il metodo spawn_enemy)
			# Questo è il "Danno d'assedio"
			elif body.has_method("spawn_enemy"):
				print("BOOM! Struttura demolita!")
				body.take_damage(structure_damage, global_position)
				
			# CASO C: Nemici normali (Scheletri, Slime, ecc.)
			else:
				body.take_damage(damage, global_position)

	# 4. PULIZIA (Modificata per supportare l'audio)
	
	# Aspettiamo prima che l'animazione del fuoco finisca
	await $AnimatedSprite2D.animation_finished
	
	# Nascondiamo la grafica e disabilitiamo l'area di danno (la bomba visivamente è sparita)
	$AnimatedSprite2D.hide()
	$BlastArea.set_deferred("monitoring", false)
	
	# Se il suono sta ancora suonando, aspettiamo che finisca
	if sfx_explosion.playing:
		await sfx_explosion.finished
		
	# Ora che anche l'audio è finito, possiamo distruggere il nodo
	queue_free()
