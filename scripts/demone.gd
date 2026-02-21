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
@export_group("Dash Attack Settings")
@export var dash_speed = 100.0        
@export var dash_duration = 1.0       
@export var dash_pause = 0.8          
@export var dash_cooldown = 3.5      
@export var final_stun_time = 2     

var dash_timer = 0.0                  
var is_dashing = false                

@export var bullet_scene: PackedScene 
@export var burst_count = 3          
@export var burst_delay = 0.2         
@export var shoot_cooldown = 4.0     
@export var shoot_range = 200.0

var shoot_timer = 0.0
var is_shooting = false
@export var potion_chance: float = 0.10 
@export var coin_chance: float = 0.60

# --- VARIABILI INTERNE ---
var current_health = 3
var is_hurt = false
var player = null

# --- FIX: VARIABILE DI STATO ATTACCO ---
var is_attacking = false 

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
	# 1. GESTIONE KNOCKBACK 
	if is_hurt and not is_dashing:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 
	# --- GESTIONE DASH ATTACK ---
	if is_dashing:
		return

	if is_attacking:
		move_and_slide() 
		return

	if dash_timer > 0:
		dash_timer -= delta

	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < detection_range and dash_timer <= 0:
			perform_dash_attack()
			return 
	# --- 2. FIX: GESTIONE ATTACCO CON RINCULO ---
	if is_attacking:
		move_and_slide() 
		return 

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
		
		if collider.is_in_group("player") and not is_attacking:
			if collider.has_method("take_damage"):
				attack_player(collider)

	# --- INIZIO CODICE SPINTA BOMBA ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			
			var push_speed = 100.0 
			
			collider.linear_velocity = push_dir * push_speed
	# --- FINE CODICE SPINTA ---

func perform_dash_attack():
	# --- 1. PREAVVISO  ---
	velocity = Vector2.ZERO
	is_dashing = true
	modulate = Color(1.0, 0.5, 0.0) 
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	
	dash_timer = dash_cooldown 

	if player == null: 
		is_dashing = false
		return

	var dash_dir = (player.global_position - global_position).normalized()
	velocity = dash_dir * dash_speed
	
	# --- 2. MOVIMENTO PER UNA DURATA FISSA ---
	var time_passed = 0.0
	
	while time_passed < dash_duration:
		var delta = get_physics_process_delta_time()
		time_passed += delta
		
		var motion = velocity * delta
		
		var collision_info = move_and_collide(motion)
		
		if collision_info:
			var collider = collision_info.get_collider()
			
			if collider.is_in_group("player"):
				dash_hit_logic(collider)
				global_position += collision_info.get_remainder()
			else:
				break 
		
		await get_tree().process_frame 

	# --- 3. STUN FINALE  ---
	velocity = Vector2.ZERO
	anim.play("idle")
	await get_tree().create_timer(final_stun_time).timeout
	is_dashing = false
	
func dash_hit_logic(target):
	if target.has_method("take_damage"):
		var dash_damage = damage * 2 
		target.take_damage(dash_damage, global_position)
		
		

# --- FUNZIONE ATTACCO AGGIORNATA ---
func attack_player(target):
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
	
	if not is_dashing:
		if source_pos != Vector2.ZERO:
			var knockback_dir = (global_position - source_pos).normalized()
			velocity = knockback_dir * knockback_force
			is_hurt = true 
	else:
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
