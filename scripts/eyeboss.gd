extends CharacterBody2D

# --- LIMITI DELLA STANZA ---
@export_group("Limiti Mappa")
@export var min_x = 100.0   
@export var max_x = 1000.0  
@export var min_y = 100.0   
@export var max_y = 600.0   

@export_group("Movimento")
@export var speed = 45.0
@export var detection_range = 550.0

@export_group("Combattimento")
@export var contact_damage = 1
@export var max_health = 60
@export var laser_scene: PackedScene
@export var shoot_cooldown = 2.5
@export var charge_time = 1.2
@export var lock_ratio = 0.8
@export var nova_cooldown = 8.0
@export var nova_laser_count = 12

@export_group("Teletrasporto")
@export var teleport_cooldown = 5.0
@export var teleport_threshold = 130.0 

# --- STATI INTERNI ---
var current_health = 60
var player = null
var can_shoot = true
var can_nova = true
var can_teleport = true
var is_attacking = false
var current_laser = null 

@onready var anim = $AnimatedSprite2D
@onready var sight_check = $LaserRay 

func _ready():
	current_health = max_health
	if sight_check:
		sight_check.enabled = true
		sight_check.add_exception(self)
		
	# --- NUOVO: Fai partire la OST del Boss! ---
	OST.play_boss_theme()

func _physics_process(delta):
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		check_contact_damage()
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player != null:
		var dist = global_position.distance_to(player.global_position)
		if can_teleport and dist < teleport_threshold:
			teleport_to_random_pos()
			return 

		if dist < detection_range:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * speed
			if can_nova:
				attack_nova()
			elif can_shoot and has_line_of_sight():
				attack_targeted()
		else:
			velocity = Vector2.ZERO
			anim.play("idle")

	update_animations()
	move_and_slide()
	check_contact_damage()

# --- TELETRASPORTO ---
func teleport_to_random_pos():
	can_teleport = false
	is_attacking = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	global_position = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
	var tween_back = create_tween()
	tween_back.tween_property(self, "modulate:a", 1.0, 0.2)
	await tween_back.finished
	is_attacking = false
	await get_tree().create_timer(teleport_cooldown).timeout
	can_teleport = true

# --- ATTACCO MIRATO ---
func attack_targeted():
	if laser_scene == null: return
	is_attacking = true
	can_shoot = false
	anim.play("attack") 
	modulate = Color(2, 0.5, 0.5) 
	
	current_laser = laser_scene.instantiate() 
	current_laser.global_position = global_position
	if "is_charging" in current_laser: current_laser.is_charging = true
	get_parent().add_child(current_laser)
	
	var lock_time = charge_time * lock_ratio
	var timer = 0.0
	
	while timer < charge_time:
		if not is_inside_tree(): return 
		
		if is_instance_valid(current_laser) and is_instance_valid(player):
			var ray = current_laser.get_node_or_null("RayCast2D")
			if ray and timer < lock_time:
				var direction = (player.global_position - global_position).normalized()
				ray.target_position = direction * 2000 
				if timer > lock_time - 0.2:
					var line = current_laser.get_node_or_null("Line2D")
					if line: line.default_color = Color(1, 1, 0, 0.6)
			anim.flip_h = player.global_position.x < global_position.x
			
		await get_tree().process_frame
		timer += get_process_delta_time()
	
	if is_instance_valid(current_laser) and current_laser.has_method("fire_laser"):
		current_laser.fire_laser()
	
	modulate = Color(1, 1, 1, 1)
	anim.play("idle")
	await get_tree().create_timer(0.6).timeout 
	is_attacking = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

# --- ATTACCO NOVA ---
func attack_nova():
	if laser_scene == null: return
	is_attacking = true
	can_nova = false
	anim.play("attack")
	modulate = Color(0.5, 0.5, 3) 
	await get_tree().create_timer(1.2).timeout 
	
	for i in range(nova_laser_count):
		var angle = i * (PI * 2 / nova_laser_count)
		var direction = Vector2.RIGHT.rotated(angle)
		var laser = laser_scene.instantiate()
		laser.global_position = global_position
		get_parent().add_child(laser)
		var ray = laser.get_node_or_null("RayCast2D")
		if ray: ray.target_position = direction * 800
		if laser.has_method("fire_laser"): laser.fire_laser()
	
	modulate = Color(1, 1, 1, 1)
	anim.play("idle")
	await get_tree().create_timer(1.0).timeout
	is_attacking = false
	await get_tree().create_timer(nova_cooldown).timeout
	can_nova = true

# --- SISTEMA DI SICUREZZA ---
func _exit_tree():
	if is_instance_valid(current_laser):
		current_laser.queue_free()

func has_line_of_sight() -> bool:
	if !player or !sight_check: return false
	sight_check.target_position = to_local(player.global_position)
	sight_check.force_raycast_update()
	return sight_check.is_colliding() and sight_check.get_collider().is_in_group("player")

func check_contact_damage():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage, global_position)

func take_damage(amount, _source_pos = Vector2.ZERO):
	current_health -= amount
	var t = create_tween()
	t.tween_property(self, "modulate", Color(10,10,10), 0.05)
	t.tween_property(self, "modulate", Color(1,1,1,1), 0.05)
	if current_health <= 0:
		die() # Invece di queue_free() diretto, chiamiamo la nuova funzione

# --- NUOVA FUNZIONE MORTE ---
func die():
	print("Boss sconfitto!")
	# Rimettiamo la musica del dungeon con dissolvenza
	OST.play_normal_theme()
	queue_free()

func update_animations():
	if is_attacking: return
	if velocity.length() > 0:
		anim.play("run")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")
