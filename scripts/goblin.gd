extends CharacterBody2D

# --- VARIABILI CONFIGURABILI ---
@export var speed = 50.0            
@export var patrol_speed = 30.0     
@export var detection_range = 150.0 
@export var max_health = 3
@export var damage = 1
@export var knockback_force = 250.0
@export var attack_cooldown_time = 1.5 # Tempo in cui sta fermo dopo l'attacco

# --- VARIABILI INTERNE ---
var current_health = 3
var is_hurt = false
var player = null

# --- FIX: VARIABILE DI STATO ATTACCO ---
var is_attacking = false # Se è vero, il mob è "congelato" post-attacco

# Variabili Pattuglia e Investigazione
var move_direction = Vector2.ZERO
var roam_timer = 0.0
var time_to_next_move = 0.0
var is_investigating = false      
var investigation_timer = 0.0     
var investigation_duration = 2.0  
var was_chasing = false           
var look_timer = 0.0 

@onready var anim = $AnimatedSprite2D 

func _ready():
	current_health = max_health
	pick_new_state()

func _draw():
	draw_circle(Vector2.ZERO, detection_range, Color(1, 0, 0, 0.1))

func _physics_process(delta):
	# 1. GESTIONE KNOCKBACK (Priorità Massima)
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 

	# --- 2. FIX: GESTIONE ATTACCO CON RINCULO ---
	if is_attacking:
		# NON forziamo velocity a zero qui. 
		# Lasciamo che sia la funzione attack_player a decidere se spingerci indietro o fermarci.
		move_and_slide() 
		return # Usciamo per non fare calcoli di inseguimento

	# 3. CERCA IL GIOCATORE
	if player == null:
		player = get_parent().get_node_or_null("Player")
	
	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		# --- CASO A: INSEGUIMENTO ---
		if distance < detection_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			was_chasing = true
			is_investigating = false 
		
		# --- CASO B: PATTUGLIA/INVESTIGAZIONE ---
		else:
			if was_chasing:
				start_investigation()
				was_chasing = false 
			
			if is_investigating:
				velocity = Vector2.ZERO
				investigation_timer -= delta
				look_timer -= delta
				if look_timer <= 0:
					anim.flip_h = !anim.flip_h
					look_timer = 0.5 
				
				if investigation_timer <= 0:
					is_investigating = false
					pick_new_state()
			else:
				roam_timer += delta
				if roam_timer >= time_to_next_move:
					pick_new_state()
				velocity = move_direction * patrol_speed

	# 4. GESTIONE ANIMAZIONI
	if velocity.length() > 0:
		anim.play("walk")
		if not is_investigating:
			if velocity.x < 0:
				anim.flip_h = true
			elif velocity.x > 0:
				anim.flip_h = false
	else:
		anim.play("idle")

	# 5. MOVIMENTO E COLLISIONI
	move_and_slide()
	
	# Controllo collisioni per attaccare
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Se tocca il player E NON sta già attaccando
		if collider.name == "Player" and not is_attacking:
			if collider.has_method("take_damage"):
				attack_player(collider)

# --- FUNZIONE ATTACCO AGGIORNATA ---
func attack_player(target):
	# 1. Blocchiamo l'AI
	is_attacking = true
	
	# 2. CALCOLO RINCULO (Molto più leggero)
	var recoil_direction = (global_position - target.global_position).normalized()
	
	# PRIMA ERA: 150. ADESSO PROVIAMO: 60 (Un passetto piccolo)
	velocity = recoil_direction * 60 
	
	# 3. Infliggi danno
	target.take_damage(damage, global_position)
	
	# 4. FASE DI RINCULO (Molto più breve)
	# PRIMA ERA: 0.2s. ADESSO PROVIAMO: 0.1s (Appena un istante per staccarsi)
	await get_tree().create_timer(0.1).timeout
	
	# 5. FASE DI STOP
	velocity = Vector2.ZERO
	anim.play("idle")
	
	# Calcoliamo il tempo rimanente del cooldown
	# Sottraiamo il 0.1 che abbiamo appena aspettato
	var remaining_cooldown = attack_cooldown_time - 0.1
	if remaining_cooldown > 0:
		await get_tree().create_timer(remaining_cooldown).timeout
	
	# 6. Sblocca il mob
	is_attacking = false

# --- LE ALTRE FUNZIONI RIMANGONO UGUALI ---
func start_investigation():
	is_investigating = true
	investigation_timer = investigation_duration
	look_timer = 0.5 
	velocity = Vector2.ZERO 

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
	was_chasing = true 
	
	if current_health <= 0:
		die()

func die():
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()
