extends CharacterBody2D

# --- LIMITI DELLA STANZA (Modifica questi valori in base alla tua mappa!) ---
@export_group("Limiti Mappa")
@export var min_x = 100.0   # Limite sinistro
@export var max_x = 1000.0  # Limite destro
@export var min_y = 100.0   # Limite superiore
@export var max_y = 600.0   # Limite inferiore

@export_group("Movimento")
@export var speed = 45.0
@export var detection_range = 550.0

@export_group("Combattimento")
@export var contact_damage = 1
@export var max_health = 40
@export var laser_scene: PackedScene
@export var shoot_cooldown = 2.5
@export var charge_time = 1.0
@export var nova_cooldown = 7.0
@export var nova_laser_count = 10

@export_group("Teletrasporto")
@export var teleport_cooldown = 5.0
@export var teleport_threshold = 120.0 # Se il player è più vicino di così, scappa

# --- STATI INTERNI ---
var current_health = 40
var player = null
var can_shoot = true
var can_nova = true
var can_teleport = true
var is_attacking = false

@onready var anim = $AnimatedSprite2D
@onready var sight_check = $LaserRay 

func _ready():
	current_health = max_health
	if sight_check:
		sight_check.enabled = true
		sight_check.add_exception(self)

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
		
		# 1. TELETRASPORTO CASUALE ENTRO COORDINATE
		if can_teleport and dist < teleport_threshold:
			teleport_to_random_pos()
			return 

		# 2. LOGICA MOVIMENTO
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

# --- NUOVA FUNZIONE TELETRASPORTO SICURO ---
func teleport_to_random_pos():
	can_teleport = false
	is_attacking = true
	
	# Effetto Scomparsa (Solo visivo)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	# Calcola una posizione casuale entro i limiti impostati
	var rand_x = randf_range(min_x, max_x)
	var rand_y = randf_range(min_y, max_y)
	var new_pos = Vector2(rand_x, rand_y)
	
	# Spostamento istantaneo
	global_position = new_pos
	
	# Effetto Riapparsa
	var tween_back = create_tween()
	tween_back.tween_property(self, "modulate:a", 1.0, 0.2)
	await tween_back.finished
	
	is_attacking = false
	
	# Cooldown
	await get_tree().create_timer(teleport_cooldown).timeout
	can_teleport = true

# --- ATTACCHI (Gestione Laser) ---
func attack_targeted():
	if laser_scene == null: return
	is_attacking = true
	can_shoot = false
	
	anim.play("attacco_carica")
	modulate = Color(2, 0.5, 0.5) 
	
	var laser = laser_scene.instantiate()
	laser.global_position = global_position
	if "is_charging" in laser: laser.is_charging = true
	get_parent().add_child(laser)
	
	var timer = 0.0
	while timer < charge_time:
		if is_instance_valid(laser) and is_instance_valid(player):
			var ray = laser.get_node_or_null("RayCast2D")
			if ray: ray.target_position = player.global_position - global_position
			anim.flip_h = player.global_position.x < global_position.x
		await get_tree().process_frame
		timer += get_process_delta_time()
	
	if is_instance_valid(laser) and laser.has_method("fire_laser"):
		laser.fire_laser()
	
	modulate = Color(1, 1, 1, 1)
	anim.play("idle")
	await get_tree().create_timer(0.6).timeout 
	is_attacking = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func attack_nova():
	if laser_scene == null: return
	is_attacking = true
	can_nova = false
	
	anim.play("attacco_carica")
	modulate = Color(0.5, 0.5, 3) 
	await get_tree().create_timer(1.2).timeout 
	
	for i in range(nova_laser_count):
		var angle = i * (PI * 2 / nova_laser_count)
		var direction = Vector2.RIGHT.rotated(angle)
		var laser = laser_scene.instantiate()
		laser.global_position = global_position
		get_parent().add_child(laser)
		var ray = laser.get_node_or_null("RayCast2D")
		if ray: ray.target_position = direction * 500
		if laser.has_method("fire_laser"): laser.fire_laser()
	
	modulate = Color(1, 1, 1, 1)
	anim.play("idle")
	await get_tree().create_timer(1.0).timeout
	is_attacking = false
	await get_tree().create_timer(nova_cooldown).timeout
	can_nova = true

# --- FUNZIONI DI SERVIZIO ---
func has_line_of_sight() -> bool:
	if !player or !sight_check: return false
	sight_check.target_position = to_local(player.global_position)
	sight_check.force_raycast_update()
	if sight_check.is_colliding():
		return sight_check.get_collider().is_in_group("player")
	return false

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
		queue_free()

func update_animations():
	if is_attacking: return
	if velocity.length() > 0:
		anim.play("run")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")
