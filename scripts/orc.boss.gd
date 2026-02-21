extends CharacterBody2D

# --- STATISTICHE E HP ---
@export_group("Stato")
@export var is_active = false
@export var max_health = 100
@export var contact_damage = 1
@export var explosion_damage = 2
var current_health = 0

# --- MOVIMENTO ---
@export_group("Inseguimento")
@export var speed = 60.0 
@export var chase_duration = 3.0 
@export var post_contact_delay = 1.5 
@export var knockback_force = 600.0

# --- COMBATTIMENTO ---
@export_group("Esplosioni")
@export var explosion_scene: PackedScene
@export var warning_time = 0.8
@export var attack_cooldown = 2.0 
@export var target_explosion_radius = 30.0
@export var aoe_explosion_radius = 90.0

# --- AUDIO ---
@export_group("Audio")
@export var explosion_sound: AudioStream # <--- NUOVO: Trascina qui il tuo file audio (.wav o .ogg)

var player = null
var current_state = "IDLE" 
var last_attack = -1 
var is_stunned = false 

@onready var anim = $AnimatedSprite2D

func _ready():
	current_health = max_health
	if anim: anim.play("idle")

func _physics_process(delta):
	if not is_active: return
	
	# GESTIONE KNOCKBACK (Attrito)
	if is_stunned:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
		move_and_slide()
		return
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	check_contact_damage()

	match current_state:
		"CHASING":
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			if anim: 
				anim.play("run")
				anim.flip_h = velocity.x < 0
		"ATTACKING":
			velocity = Vector2.ZERO
		"IDLE":
			velocity = Vector2.ZERO
			if anim: 
				anim.play("idle")
				anim.flip_h = player.global_position.x < global_position.x

	move_and_slide()

# --- ATTIVAZIONE ---
func activate_boss():
	if is_active: return
	is_active = true
	decide_next_attack()

# --- CICLO IA ---
func decide_next_attack():
	if not is_inside_tree() or current_health <= 0: return

	current_state = "IDLE"
	await get_tree().create_timer(attack_cooldown).timeout 
	
	if not is_active or not is_inside_tree(): return

	var attack_choice = randi() % 3
	while attack_choice == last_attack:
		attack_choice = randi() % 3
	
	last_attack = attack_choice 

	match attack_choice:
		0: await perform_target_explosion()
		1: await perform_aoe_explosion()
		2: await perform_chase()

	decide_next_attack()

# --- AZIONI DI ATTACCO ---
func perform_target_explosion():
	if not is_instance_valid(player): return
	current_state = "ATTACKING"
	if anim: anim.play("attack")
	await spawn_explosion_logic(player.global_position, target_explosion_radius, false)
	current_state = "IDLE"

func perform_aoe_explosion():
	current_state = "ATTACKING"
	if anim: anim.play("attack")
	await spawn_explosion_logic(global_position, aoe_explosion_radius, true)
	current_state = "IDLE"

# --- LOGICA CORE: SPAWN E DANNO ---
func spawn_explosion_logic(target_pos: Vector2, radius: float, is_aoe: bool):
	if explosion_scene == null: return
	
	var warning = Line2D.new()
	var pts = []
	for i in range(33):
		var a = (i * PI * 2.0) / 32
		pts.append(Vector2(cos(a), sin(a)) * radius)
	warning.points = pts
	warning.width = 2.0
	warning.default_color = Color(1, 0, 0, 0.6)
	warning.global_position = target_pos
	get_parent().add_child(warning)
	
	var t = create_tween()
	t.tween_property(self, "modulate", Color(4, 1, 1), warning_time)
	
	await get_tree().create_timer(warning_time).timeout
	
	if is_instance_valid(warning): warning.queue_free()
	modulate = Color(1, 1, 1)

	if is_inside_tree() and current_health > 0:
		# SPAWN EFFETTO VISIVO
		var exp_instance = explosion_scene.instantiate()
		exp_instance.global_position = target_pos
		if is_aoe: exp_instance.scale = Vector2(4, 4)
		get_parent().add_child(exp_instance)
		
		# --- NUOVO: RIPRODUZIONE AUDIO ---
		if explosion_sound:
			var sfx = AudioStreamPlayer2D.new()
			sfx.stream = explosion_sound
			sfx.global_position = target_pos # Il suono viene dalla posizione dell'esplosione
			sfx.autoplay = true
			# Autodistruzione del nodo audio quando il suono finisce
			sfx.finished.connect(sfx.queue_free) 
			get_parent().add_child(sfx)
		
		# CALCOLO DANNO
		if is_instance_valid(player):
			var dist = target_pos.distance_to(player.global_position)
			if dist <= radius + 10:
				if player.has_method("take_damage"):
					player.take_damage(explosion_damage, target_pos)

func perform_chase():
	current_state = "CHASING"
	await get_tree().create_timer(chase_duration).timeout
	current_state = "IDLE"

# --- SISTEMA DI COLLISIONE E KNOCKBACK ---
func check_contact_damage():
	if is_stunned: return 

	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var obj = col.get_collider()
		if obj.is_in_group("player") and obj.has_method("take_damage"):
			obj.take_damage(contact_damage, global_position)
			
			var knock_dir = (global_position - obj.global_position).normalized()
			apply_hit_effects(knock_dir)
			break

func apply_hit_effects(direction: Vector2):
	is_stunned = true
	velocity = direction * knockback_force
	
	if anim: anim.play("idle")
	modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	await get_tree().create_timer(post_contact_delay).timeout
	
	is_stunned = false
	modulate = Color(1, 1, 1, 1)

func take_damage(amount, _source_pos = Vector2.ZERO):
	current_health -= amount
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	flash.tween_property(self, "modulate", Color(1, 1, 1), 0.05)
	
	if current_health <= 0:
		is_active = false
		queue_free()
