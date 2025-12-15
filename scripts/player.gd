extends CharacterBody2D

@export var speed = 100.0
@export var health = 3
@export var knockback_force = 200.0 # Quanto forte vieni spinto via

@onready var anim = $AnimatedSprite2D

var is_hurt = false

func _physics_process(delta):
	# --- GESTIONE DEL RIMBALZO ---
	if is_hurt:
		# Invece di fermarci, ci muoviamo scivolando (attrito)
		# move_toward riduce la velocità verso 0 un po' alla volta
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
		move_and_slide()
		return

	# --- MOVIMENTO NORMALE ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * speed
		anim.play("run")
		
		if direction.x < 0:
			anim.flip_h = true
		elif direction.x > 0:
			anim.flip_h = false
	else:
		velocity = Vector2.ZERO
		anim.play("idle")

	move_and_slide()

# --- NUOVA FUNZIONE TAKE DAMAGE ---
# Ora accetta "enemy_pos" per sapere da che parte scappare
func take_damage(amount, enemy_pos = Vector2.ZERO):
	if is_hurt:
		return
	
	is_hurt = true
	health -= amount
	print("Vite rimanenti: ", health)
	
	# CALCOLO DEL RIMBALZO
	if enemy_pos != Vector2.ZERO:
		# Calcola la direzione opposta al nemico: (MiaPosizione - PosizioneNemico)
		var knockback_direction = (global_position - enemy_pos).normalized()
		# Applica la spinta istantanea
		velocity = knockback_direction * knockback_force
	else:
		# Se non sappiamo chi ci ha colpito (es. trappola), fermati e basta
		velocity = Vector2.ZERO

	anim.play("hurt")
	
	if health <= 0:
		die()
	else:
		await anim.animation_finished
		is_hurt = false
		anim.play("idle")

func die():
	print("GAME OVER")
	
	set_physics_process(false)
	is_hurt = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	# --- MODIFICA TELECAMERA ---
	var camera = $Camera2D
	
	# 1. Salviamo dove si trova ESATTAMENTE ora nel mondo
	var old_global_pos = camera.global_position
	
	# 2. Sganciamo la telecamera
	camera.top_level = true
	
	# 3. Le riassegniamo forzatamente la posizione salvata
	# (Così non salta a 0,0)
	camera.global_position = old_global_pos
	
	# IMPORTANTE: Disattiviamo lo smoothing se era attivo,
	# altrimenti cercherà di "scivolare" verso la posizione causando scatti.
	camera.position_smoothing_enabled = false
	
	# --- IL RESTO DEL TWEEN RIMANE UGUALE ---
	var tween = create_tween()
	
	# Saltino
	tween.tween_property(self, "position:y", position.y - 40, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Caduta (aumentiamo un po' la distanza per essere sicuri esca dallo schermo)
	tween.tween_property(self, "position:y", position.y + 1000, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	anim.play("hurt")
	
	await tween.finished
	queue_free()
