extends CharacterBody2D

# --- VARIABILI CONFIGURABILI ---
@export var speed = 50.0            
@export var patrol_speed = 30.0     
@export var detection_range = 150.0 
@export var max_health = 3
@export var damage = 1
@export var knockback_force = 250.0
@export var attack_cooldown_time = 1.5 
@export var coin_scene: PackedScene
@export var potionH_scene: PackedScene 
@export var projectile_scene: PackedScene 
@export var attack_range = 100.0          
# Probabilità
@export var potion_chance: float = 0.10 
@export var coin_chance: float = 0.60

# --- VARIABILI INTERNE ---
var current_health = 3
var is_hurt = false
var player = null

var is_attacking = false 

# Variabili Pattuglia
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
	# Disegna i due cerchi per debug visivo (Rosso = Vista, Giallo = Sparo)
	draw_circle(Vector2.ZERO, detection_range, Color(1, 0, 0, 0.1))
	draw_circle(Vector2.ZERO, attack_range, Color(1, 1, 0, 0.1))

func _physics_process(delta):
	# 1. GESTIONE KNOCKBACK (Priorità Massima)
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 

	# 2. SE STA ATTACCANDO (SPARANDO O COLPENDO), RESTA FERMO
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide() 
		return

	# 3. CERCA IL GIOCATORE
	# FIX: Cerchiamo dinamicamente il player a ogni frame per evitare crash
	# se il player muore o cambia stanza.
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = null

	# 4. LOGICA DI MOVIMENTO E INSEGUIMENTO
	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		# --- CASO A: GIOCATORE VICINO, SPARA ---
		if distance <= attack_range:
			velocity = Vector2.ZERO
			was_chasing = true
			is_investigating = false
			shoot_projectile()
			
		# --- CASO B: GIOCATORE VISTO, MA TROPPO LONTANO PER SPARARE (INSEGUE) ---
		elif distance <= detection_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			was_chasing = true
			is_investigating = false
			
		# --- CASO C: GIOCATORE PERSO DI VISTA (PATTUGLIA) ---
		else:
			handle_patrol(delta)
	else:
		# Se non c'è il player in scena, pattuglia
		handle_patrol(delta)

	# 5. GESTIONE ANIMAZIONI
	if velocity.length() > 0:
		anim.play("run")
		if velocity.x < 0:
			anim.flip_h = true
		elif velocity.x > 0:
			anim.flip_h = false
	else:
		anim.play("idle")

	# 6. MOVIMENTO FISICO
	move_and_slide()
	
	# 7. GESTIONE COLLISIONI (Spinta Bombe e Melee d'Emergenza)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Spinta Bombe
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			var push_speed = 100.0 
			collider.linear_velocity = push_dir * push_speed
			
		# Melee (se il player gli corre addosso mentre non sta sparando)
		elif collider.is_in_group("player") and not is_attacking:
			if collider.has_method("take_damage"):
				attack_player_melee(collider)

# --- NUOVA FUNZIONE SEPARATA PER LA PATTUGLIA (Più pulita) ---
func handle_patrol(delta):
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

# --- FUNZIONE ATTACCO MELEE (Rinominata) ---
func attack_player_melee(target):
	is_attacking = true
	var recoil_direction = (global_position - target.global_position).normalized()
	velocity = recoil_direction * 60 
	target.take_damage(damage, global_position)
	
	await get_tree().create_timer(0.1).timeout
	velocity = Vector2.ZERO
	anim.play("idle")
	
	var remaining_cooldown = attack_cooldown_time - 0.1
	if remaining_cooldown > 0:
		await get_tree().create_timer(remaining_cooldown).timeout
	is_attacking = false


# --- FUNZIONE SPARO PROIETTILE ---
func shoot_projectile():
	is_attacking = true
	anim.play("idle") 
	
	# Giriamo lo sprite verso il player prima di sparare!
	var shoot_dir = (player.global_position - global_position).normalized()
	if shoot_dir.x < 0:
		anim.flip_h = true
	else:
		anim.flip_h = false
	
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position 
		proj.shooter = self
		proj.direction = shoot_dir
		proj.rotation = shoot_dir.angle()
		# Aggiungiamo il proiettile al mondo, non al nemico
		get_tree().current_scene.add_child(proj)
		
	# Attendi il cooldown
	await get_tree().create_timer(attack_cooldown_time).timeout
	is_attacking = false

# --- RESTO DEL CODICE UGUALE ---
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
	print("Scheletro eliminato!")
	# Rimuoviamolo dal gruppo enemies per far aprire le porte!
	remove_from_group("enemies") 
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	var random_roll = randf()
	if potionH_scene and random_roll < potion_chance:
		spawn_loot(potionH_scene)
	elif coin_scene and random_roll < (potion_chance + coin_chance):
		spawn_loot(coin_scene)
	
	queue_free()

func spawn_loot(scene_to_spawn):
	if scene_to_spawn != null:
		var drop = scene_to_spawn.instantiate()
		drop.global_position = global_position
		get_parent().call_deferred("add_child", drop)
