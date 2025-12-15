extends CharacterBody2D

# --- VARIABILI CONFIGURABILI ---
@export var speed = 50.0            
@export var patrol_speed = 30.0     
@export var detection_range = 150.0 
@export var max_health = 3
@export var damage = 1
@export var knockback_force = 250.0

# --- VARIABILI INTERNE ---
var current_health = 3
var is_hurt = false
var player = null

# Variabili per la pattuglia
var move_direction = Vector2.ZERO
var roam_timer = 0.0
var time_to_next_move = 0.0

# --- VARIABILI PER L'INVESTIGAZIONE ---
var is_investigating = false      
var investigation_timer = 0.0     
var investigation_duration = 2.0  
var was_chasing = false           

# --- NUOVA VARIABILE PER GUARDARE A DESTRA/SINISTRA ---
var look_timer = 0.0 # Timer per scattare la testa

@onready var anim = $AnimatedSprite2D 

func _ready():
	current_health = max_health
	pick_new_state()

func _draw():
	# Debug Visivo
	draw_circle(Vector2.ZERO, detection_range, Color(1, 0, 0, 0.1))
	draw_arc(Vector2.ZERO, detection_range, 0, TAU, 32, Color(1, 0, 0, 0.5), 1.0)

func _physics_process(delta):
	# 1. GESTIONE KNOCKBACK
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 

	# 2. CERCA IL GIOCATORE
	if player == null:
		player = get_parent().get_node_or_null("Player")
	
	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		# --- CASO A: TI VEDE (INSEGUIMENTO) ---
		if distance < detection_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			
			was_chasing = true
			is_investigating = false 
		
		# --- CASO B: SEI LONTANO ---
		else:
			if was_chasing:
				start_investigation()
				was_chasing = false 
			
			if is_investigating:
				# --- LOGICA "CONFUSO" (NUOVA) ---
				velocity = Vector2.ZERO # Sta fermo
				
				# Conto alla rovescia generale (2 secondi totali)
				investigation_timer -= delta
				
				# Conto alla rovescia per girare la testa (0.5 secondi)
				look_timer -= delta
				if look_timer <= 0:
					# Inverti la direzione attuale (se era destra diventa sinistra, e viceversa)
					anim.flip_h = !anim.flip_h
					# Resetta il timer per il prossimo scatto
					look_timer = 0.5 
				
				# Se il tempo totale è scaduto, torna a pattugliare
				if investigation_timer <= 0:
					is_investigating = false
					pick_new_state()
					
			else:
				# Logica Pattuglia Classica
				roam_timer += delta
				if roam_timer >= time_to_next_move:
					pick_new_state()
				velocity = move_direction * patrol_speed

	# 3. GESTIONE ANIMAZIONI
	if velocity.length() > 0:
		anim.play("walk")
		# Gira lo sprite in base al movimento (solo se NON sta investigando)
		if not is_investigating:
			if velocity.x < 0:
				anim.flip_h = true
			elif velocity.x > 0:
				anim.flip_h = false
	else:
		anim.play("idle")

	# 4. MOVIMENTO E COLLISIONI
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.name == "Player" and collider.has_method("take_damage"):
			collider.take_damage(damage, global_position)

# --- FUNZIONI DI SUPPORTO ---

func start_investigation():
	is_investigating = true
	investigation_timer = investigation_duration
	look_timer = 0.5 # Aspetta mezzo secondo prima di girarsi la prima volta
	velocity = Vector2.ZERO 
	print("Dove è andato??")

func pick_new_state():
	roam_timer = 0.0
	time_to_next_move = randf_range(1.0, 3.0)
	if randf() > 0.5:
		move_direction = Vector2.ZERO
	else:
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func take_damage(amount, source_pos = Vector2.ZERO):
	current_health -= amount
	if source_pos != Vector2.ZERO:
		var knockback_dir = (global_position - source_pos).normalized()
		velocity = knockback_dir * knockback_force
		is_hurt = true 
	
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)
	is_hurt = false
	
	was_chasing = true # Se colpito, si allerta
	
	if current_health <= 0:
		die()

func die():
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()
