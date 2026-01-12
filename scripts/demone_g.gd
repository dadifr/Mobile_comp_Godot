extends CharacterBody2D

# --- VARIABILI CONFIGURABILI ---
@export var speed = 50.0            
@export var patrol_speed = 30.0     
@export var detection_range = 150.0 
@export var max_health = 3
@export var damage = 1
@export var knockback_force = 250.0
@export var attack_cooldown_time = 1.5 # Tempo in cui sta fermo dopo l'attacco
@export var coin_scene: PackedScene
@export var potionH_scene: PackedScene # <--- La nuova pozione
@export_group("Dash Attack Settings")
@export var dash_speed = 170.0        # Velocità dello scatto
@export var dash_duration = 1       # Quanto dura un singolo scatto
@export var dash_pause = 0.8          # Pausa tra uno scatto e l'altro
@export var dash_cooldown = 2.0       # Ogni quanti secondi può rifare questa mossa
@export var final_stun_time = 2     # Tempo in cui resta fermo alla fine dei 3 scatti

var dash_timer = 0.0                  # Timer interno per il cooldown della mossa
var is_dashing = false                # Flag per lo stato di scatto

# Sotto le altre variabili @export
@export var bullet_scene: PackedScene # Trascina qui la scena Bullet
@export var burst_count = 3           # Numero di colpi per ogni raffica
@export var burst_delay = 0.2         # Tempo tra un proiettile e l'altro della stessa raffica
@export var shoot_cooldown = 4.0      # Tempo tra una raffica e l'altra
@export var shoot_range = 200.0

var shoot_timer = 0.0
var is_shooting = false
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
	# Se sta subendo knockback MA NON sta dashando, allora processa il dolore
	if is_hurt and not is_dashing:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 
	# --- NUOVO: GESTIONE DASH ATTACK ---
	if is_dashing:
		return

	if is_attacking:
		move_and_slide() 
		return

	# Gestione Timer Cooldown Dash
	if dash_timer > 0:
		dash_timer -= delta

	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		# Se è nel range, il cooldown è scaduto e non sta già facendo altro: SCATTA!
		if distance < detection_range and dash_timer <= 0:
			perform_dash_attack()
			return # Esci per non sovrascrivere la velocity
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

func perform_dash_attack():
	# --- 1. PREAVVISO ---
	velocity = Vector2.ZERO
	is_dashing = true
	modulate = Color(1.0, 0.5, 0.0) 
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	
	dash_timer = dash_cooldown 

	# RIMOSSO: if is_hurt: return 
	if player == null: 
		is_dashing = false
		return

	var dash_dir = (player.global_position - global_position).normalized()
	velocity = dash_dir * dash_speed

	# --- 2. MOVIMENTO CONTINUO ---
	var hit_wall = false
	while not hit_wall:
		# Spostiamo il mob manualmente calcolando il movimento di questo frame
		var motion = velocity * get_physics_process_delta_time()
		
		# move_and_collide restituisce la collisione se avviene
		var collision_info = move_and_collide(motion)
		
		if collision_info:
			var collider = collision_info.get_collider()
			
			if collider.is_in_group("player"):
				# COLPISCE IL PLAYER: fa danno e...
				dash_hit_logic(collider)
				
				# ...CONTINUA IL MOTO: sommiamo la parte di movimento rimanente 
				# per evitare che il mob si "impunti" sul player
				global_position += collision_info.get_remainder()
			else:
				# COLPISCE UN MURO (o altro): si ferma
				hit_wall = true
		
		await get_tree().process_frame 

	# --- 3. STUN FINALE ---
	velocity = Vector2.ZERO
	anim.play("idle")
	await get_tree().create_timer(final_stun_time).timeout
	is_dashing = false
	
func dash_hit_logic(target):
	# Evitiamo di colpire il player mille volte nello stesso scatto
	# Se il player ha già un timer di invulnerabilità nel suo script, questo è opzionale
	if target.has_method("take_damage"):
		# Esempio: Il dash infligge il DOPPIO del danno normale
		var dash_damage = damage * 2 
		target.take_damage(dash_damage, global_position)
		
		# Opzionale: Se vuoi che lo scatto si fermi appena colpisce il player
		# time_passed = dash_duration
		

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
	
	# Se NON sta dashando, applica il knockback normalmente
	if not is_dashing:
		if source_pos != Vector2.ZERO:
			var knockback_dir = (global_position - source_pos).normalized()
			velocity = knockback_dir * knockback_force
			is_hurt = true 
	else:
		# Se sta dashando, magari facciamo solo un flash rosso più veloce
		# senza cambiare la velocity o impostare is_hurt = true
		pass

	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)
	
	if not is_dashing:
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
