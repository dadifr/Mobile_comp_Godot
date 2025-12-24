extends CharacterBody2D

# --- VARIABILI CONFIGURABILI ---
@export var explosion_damage = 3
@export var explosion_radius = 80.0
@export var fuse_time = 0.5 # Tempo tra il contatto e il botto
@export var speed = 50.0            
@export var patrol_speed = 30.0     
@export var detection_range = 150.0 
@export var max_health = 3
@export var damage = 1
@export var knockback_force = 250.0
@export var attack_cooldown_time = 1.5 # Tempo in cui sta fermo dopo l'attacco
@export var coin_scene: PackedScene
@export var potionH_scene: PackedScene # <--- La nuova pozione

# Probabilità (0.15 = 15%, 0.5 = 50%)
@export var potion_chance: float = 0.10 
@export var coin_chance: float = 0.60

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
		player = get_tree().get_first_node_in_group("player")

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
		anim.play("run")
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
		if collider.is_in_group("player") and not is_attacking:
			if collider.has_method("take_damage"):
				attack_player(collider)

	# --- INIZIO CODICE SPINTA BOMBA ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Se il nemico sbatte contro un oggetto rigido (Bomba)
		if collider is RigidBody2D:
			# 1. Calcoliamo la direzione della spinta
			# Usiamo "-normal" che è la direzione opposta all'urto
			var push_dir = -collision.get_normal()
			
			# 2. Velocità di spinta
			# Facciamo che il nemico spinge un po' più piano del giocatore
			# (o uguale, dipende da quanto è forte lo scheletro)
			var push_speed = 100.0 
			
			# 3. Sovrascriviamo la velocità della bomba
			# Usiamo la stessa tecnica "Anti-Railgun" per evitare che voli via
			collider.linear_velocity = push_dir * push_speed
	# --- FINE CODICE SPINTA ---

# --- FUNZIONE ATTACCO AGGIORNATA ---
func attack_player(target):
	if is_attacking: return
	is_attacking = true
	
	# 1. Fase di avvertimento (il mob si ferma e lampeggia)
	velocity = Vector2.ZERO
	modulate = Color(2, 2, 2) # Diventa molto luminoso (effetto White)
	anim.play("idle") # O un'animazione di "caricamento"
	
	await get_tree().create_timer(fuse_time).timeout
	
	# 2. Esecuzione dell'esplosione
	explode()

func explode():
	print("BOOM!")
	# Mostra un'animazione o particelle (se ne hai)
	# Esempio: $ExplosionParticles.emitting = true
	
	# 3. Controlla chi è nell'area dell'esplosione
	# Attiviamo l'area per un istante
	$ExplosionArea/CollisionShape2D.disabled = false
	
	# Aspettiamo un frame per permettere a Godot di calcolare le collisioni
	await get_tree().process_frame
	
	var targets = $ExplosionArea.get_overlapping_bodies()
	for target in targets:
		if target.is_in_group("player") and target.has_method("take_damage"):
			target.take_damage(explosion_damage, global_position)
		# Opzionale: danneggia anche altri nemici!
	
	# 4. Il mob muore nell'esplosione
	die_instantly()

func die_instantly():
	# Una morte rapida senza loot o con loot specifico
	queue_free()
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
	print("Goblin eliminato!")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# --- SISTEMA DI LOOT LOGICO ---
	var random_roll = randf() # Genera un numero da 0.0 a 1.0
	
	# CONTROLLO 1: Pozione (È la più rara, controlliamo per prima)
	# Esempio: Se random_roll è 0.10 (che è < 0.15), vinci la pozione.
	if potionH_scene and random_roll < potion_chance:
		spawn_loot(potionH_scene)
		
	# CONTROLLO 2: Moneta
	# Usiamo "elif": quindi se hai già vinto la pozione, NON entri qui.
	# Sommiamo le chance: da 0.15 a 0.65 (0.15 + 0.5) vince la moneta.
	elif coin_scene and random_roll < (potion_chance + coin_chance):
		spawn_loot(coin_scene)
	
	# Se il numero è molto alto (es. 0.8), non entra in nessuno dei due if
	# e il mostro non droppa nulla (sfortuna!).
	
	queue_free()

func spawn_loot(scene_to_spawn):
	if scene_to_spawn != null:
		var drop = scene_to_spawn.instantiate()
		drop.global_position = global_position
		get_parent().call_deferred("add_child", drop)
