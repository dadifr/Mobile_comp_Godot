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

@export_group("Area Attack Settings")
@export var aoe_damage = 1
@export var aoe_cooldown = 3.0  
@export var aoe_enabled = true

var aoe_timer = 0.0
@onready var aura_area = $AuraDanno 



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

	var color = Color(1, 0, 0, (aoe_timer / aoe_cooldown) * 0.4)

	draw_circle(Vector2.ZERO, 50, color)
func _physics_process(delta):

	queue_redraw()
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return 


	if is_attacking:

		move_and_slide() 
		return


	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
	
		if distance < detection_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			was_chasing = true
			is_investigating = false 

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


	move_and_slide()
	

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		

		if collider.is_in_group("player") and not is_attacking:
			if collider.has_method("take_damage"):
				attack_player(collider)

	if aoe_enabled:
		aoe_timer += delta
		if aoe_timer >= aoe_cooldown:
			perform_aoe_attack()
			aoe_timer = 0.0 # Reset del timer
			


	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		

		if collider is RigidBody2D:

			var push_dir = -collision.get_normal()
			

			var push_speed = 100.0 
			

			collider.linear_velocity = push_dir * push_speed

func perform_aoe_attack():

	var tween = create_tween()
	tween.tween_property(aura_area, "modulate", Color(1, 0, 0, 0.5), 0.1)
	tween.tween_property(aura_area, "modulate", Color(1, 1, 1, 0), 0.2)


	var overlapping_bodies = aura_area.get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(aoe_damage, global_position)
			print("Il giocatore è stato colpito dall'aura!")

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
