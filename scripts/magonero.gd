extends CharacterBody2D

# --- LIMITI DELLA STANZA ---
@export_group("Limiti Mappa")
@export var min_x = 100.0   
@export var max_x = 1000.0  
@export var min_y = 100.0   
@export var max_y = 600.0   

@export_group("Movimento a Impulsi")
@export var step_speed = 80.0
@export var pause_duration = 2.0
@export var step_duration = 0.6

@export_group("Combattimento")
@export var contact_damage = 1
@export var laser_scene: PackedScene
@export var shoot_range = 550.0
@export var shoot_cooldown = 3.5
@export var charge_time = 1.3
@export var lock_ratio = 0.75 

# --- STATI INTERNI ---
var player = null
var can_shoot = true
var is_attacking = false
var is_moving = false
var move_direction = Vector2.ZERO
var current_laser = null # <--- Fondamentale per pulire il laser

@onready var anim = $AnimatedSprite2D

func _ready():
	# Avvio sicuro del ciclo di movimento
	call_deferred("start_logic")

func start_logic():
	await get_tree().create_timer(1.0).timeout
	decide_next_action()

func _physics_process(_delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# Gestione Movimento
	if is_attacking:
		velocity = Vector2.ZERO
	elif is_moving:
		velocity = move_direction * step_speed
		anim.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		anim.flip_h = player.global_position.x < global_position.x

	move_and_slide()
	check_contact_damage()
	
	# Logica Sparo
	var dist = global_position.distance_to(player.global_position)
	if dist < shoot_range and can_shoot and not is_attacking:
		attack_targeted()

# --- LOGICA DI MOVIMENTO ---
func decide_next_action():
	if is_attacking or not is_inside_tree(): 
		get_tree().create_timer(1.0).timeout.connect(decide_next_action)
		return

	var angle = deg_to_rad(randi_range(0, 360))
	move_direction = Vector2.RIGHT.rotated(angle)
	
	var future_pos = global_position + (move_direction * step_speed * step_duration)
	if future_pos.x < min_x or future_pos.x > max_x or future_pos.y < min_y or future_pos.y > max_y:
		move_direction *= -1

	is_moving = true
	anim.play("run")
	await get_tree().create_timer(step_duration).timeout
	
	is_moving = false
	anim.play("idle")
	await get_tree().create_timer(pause_duration).timeout
	decide_next_action()

# --- ATTACCO MIRATO (CON PULIZIA SICURA) ---
func attack_targeted():
	if laser_scene == null or not is_inside_tree(): return
	
	is_attacking = true
	can_shoot = false
	anim.play("attack")
	modulate = Color(2, 1, 2) 
	
	# Creiamo il laser e lo salviamo nella variabile di controllo
	current_laser = laser_scene.instantiate()
	current_laser.global_position = global_position
	if "is_charging" in current_laser: current_laser.is_charging = true
	get_parent().add_child(current_laser)
	
	var lock_time = charge_time * lock_ratio
	var timer = 0.0
	
	while timer < charge_time:
		# Se il mago muore durante il caricamento, il ciclo si rompe
		if not is_instance_valid(self) or not is_inside_tree(): return
		
		if is_instance_valid(current_laser) and is_instance_valid(player):
			var ray = current_laser.get_node_or_null("RayCast2D")
			if ray and timer < lock_time:
				var dir = (player.global_position - global_position).normalized()
				ray.target_position = dir * 2000 
				
				if timer > lock_time - 0.2:
					var line = current_laser.get_node_or_null("Line2D")
					if line: line.default_color = Color(1, 1, 0, 0.5)
			
		await get_tree().process_frame
		timer += get_process_delta_time()
	
	# Sparo finale
	if is_instance_valid(current_laser) and current_laser.has_method("fire_laser"):
		current_laser.fire_laser()
	
	modulate = Color(1, 1, 1)
	anim.play("idle")
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

# --- SISTEMA DI SICUREZZA ANTI-FANTASMA ---
func _exit_tree():
	# Se il mago viene rimosso dal gioco, uccide il laser all'istante
	if is_instance_valid(current_laser):
		current_laser.queue_free()

func check_contact_damage():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if is_instance_valid(collider) and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(contact_damage, global_position)

func take_damage(_amount, _pos = Vector2.ZERO):
	# Quando muore, il segnale _exit_tree pulirà il laser
	queue_free()
