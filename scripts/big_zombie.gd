extends CharacterBody2D

# --- VARIABILI CONFIGURABILI ---
@export_group("Movimento")
@export var speed = 50.0            
@export var patrol_speed = 30.0     
@export var detection_range = 150.0 

@export_group("Attacco Corpo a Corpo")
@export var damage = 1
@export var attack_cooldown_time = 1.5 
@export var knockback_force = 250.0

@export_group("Attacco Laser (Distanza)")
@export var laser_scene: PackedScene 
@export var shoot_range = 300.0      
@export var shoot_cooldown = 2.0     
@export var charge_time = 0.7        # Tempo di mira (pre-sparo)
@export var post_shoot_pause = 0.5   # Tempo di recupero (post-sparo)

@export_group("Salute e Loot")
@export var max_health = 3
@export var coin_scene: PackedScene
@export var potionH_scene: PackedScene
@export var potion_chance: float = 0.10 
@export var coin_chance: float = 0.60

# --- VARIABILI INTERNE ---
var current_health = 3
var is_hurt = false
var player = null
var is_attacking = false 
var can_shoot = true

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
@onready var sight_check = $LaserRay 

func _ready():
	current_health = max_health
	if sight_check:
		sight_check.enabled = true
	pick_new_state()

func _physics_process(delta):
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 

	# --- BLOCCO MOVIMENTO SE ATTACCA O SPARO ---
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return 

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		# LOGICA DI SPARO
		if distance <= shoot_range and can_shoot:
			if has_line_of_sight():
				shoot_at_player()

		# LOGICA DI MOVIMENTO
		if distance < detection_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			was_chasing = true
			is_investigating = false 
		else:
			handle_patrol_logic(delta)

	update_animations()
	move_and_slide()
	check_collisions()

func has_line_of_sight() -> bool:
	if player == null or sight_check == null: return false
	sight_check.target_position = to_local(player.global_position)
	sight_check.force_raycast_update()
	if sight_check.is_colliding():
		var collider = sight_check.get_collider()
		return collider.is_in_group("player")
	return false

# --- FUNZIONE SPARO MODIFICATA ---
func shoot_at_player():
	can_shoot = false
	is_attacking = true 
	
	# 1. FASE DI CARICAMENTO
	anim.modulate = Color(2, 2, 0) # Segnale giallo
	
	var laser = laser_scene.instantiate()
	laser.global_position = global_position
	laser.is_charging = true
	
	var ray = laser.get_node("RayCast2D")
	ray.target_position = (player.global_position - global_position)
	get_parent().add_child(laser)
	
	await get_tree().create_timer(charge_time).timeout
	
	# 2. SPARO
	if is_instance_valid(laser):
		laser.fire_laser()
	
	# 3. FASE DI RECUPERO (IDLE POST-RAGGIO)
	anim.modulate = Color(1, 1, 1)
	anim.play("idle") # Forza l'animazione di riposo
	
	# Aspettiamo un po' prima di permettergli di muoversi di nuovo
	await get_tree().create_timer(post_shoot_pause).timeout
	
	# 4. FINE ATTACCO
	is_attacking = false
	
	# Cooldown per il prossimo sparo
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func update_animations():
	# Se sta attaccando/sparando, l'animazione è gestita dalla funzione shoot_at_player
	if is_attacking:
		return
		
	if velocity.length() > 0:
		anim.play("run")
		if not is_investigating:
			anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")
		if player:
			anim.flip_h = player.global_position.x < global_position.x

func handle_patrol_logic(delta):
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

func check_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player") and not is_attacking:
			if collider.has_method("take_damage"):
				attack_player(collider)
		
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			collider.linear_velocity = push_dir * 100.0

func attack_player(target):
	is_attacking = true
	var recoil_direction = (global_position - target.global_position).normalized()
	velocity = recoil_direction * 60 
	target.take_damage(damage, global_position)
	
	await get_tree().create_timer(0.1).timeout
	velocity = Vector2.ZERO
	anim.play("idle")
	
	await get_tree().create_timer(attack_cooldown_time - 0.1).timeout
	is_attacking = false

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
	
	if current_health <= 0:
		die()

func die():
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var random_roll = randf()
	if potionH_scene and random_roll < potion_chance:
		spawn_loot(potionH_scene)
	elif coin_scene and random_roll < (potion_chance + coin_chance):
		spawn_loot(coin_scene)
	queue_free()

func spawn_loot(scene_to_spawn):
	var drop = scene_to_spawn.instantiate()
	drop.global_position = global_position
	get_parent().call_deferred("add_child", drop)
