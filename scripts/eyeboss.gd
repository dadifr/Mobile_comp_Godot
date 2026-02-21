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
@export var contact_cooldown = 1.0 # <--- NUOVO: Tempo di ricarica tra un danno fisico e l'altro
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

# --- AUDIO ---
@export_group("Audio")
@export var laser_shoot_sound: AudioStream 
@export var nova_sound: AudioStream        

# --- STATI INTERNI ---
var is_active = false
var current_health = 60
var player = null
var can_shoot = true
var can_nova = true
var can_teleport = true
var is_attacking = false
var current_laser = null 
var can_contact_damage = true # <--- NUOVO: Lucchetto per i danni fisici

@onready var anim = $AnimatedSprite2D
@onready var sight_check = $LaserRay 

func _ready():
	add_to_group("enemies") 
	add_to_group("boss")    
	
	current_health = max_health
	if sight_check:
		sight_check.enabled = true
		sight_check.add_exception(self)

func _physics_process(delta):
	if not is_active: return 
	
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
	
	if "creator" in current_laser:
		current_laser.creator = self
		
	get_tree().current_scene.add_child(current_laser)
	
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
	
	if laser_shoot_sound:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = laser_shoot_sound
		sfx.global_position = global_position
		sfx.autoplay = true
		sfx.finished.connect(sfx.queue_free)
		get_tree().current_scene.add_child(sfx)
		
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
	
	if nova_sound:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = nova_sound
		sfx.global_position = global_position
		sfx.autoplay = true
		sfx.finished.connect(sfx.queue_free)
		get_tree().current_scene.add_child(sfx)
	
	for i in range(nova_laser_count):
		var angle = i * (PI * 2 / nova_laser_count)
		var direction = Vector2.RIGHT.rotated(angle)
		var laser = laser_scene.instantiate()
		laser.global_position = global_position
		
		if "creator" in laser:
			laser.creator = self
			
		get_tree().current_scene.add_child(laser)
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

# --- DANNO DA CONTATTO CON COOLDOWN ---
func check_contact_damage():
	# Se il cooldown è attivo, non fare nulla!
	if not can_contact_damage: 
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage, global_position)
			
			# Appena facciamo danno, chiudiamo il lucchetto e facciamo partire il timer!
			can_contact_damage = false
			await get_tree().create_timer(contact_cooldown).timeout
			can_contact_damage = true
			
			# Interrompiamo il ciclo per non fargli prendere danno doppio nello stesso impatto
			break 

func take_damage(amount, _source_pos = Vector2.ZERO):
	current_health -= amount
	var t = create_tween()
	t.tween_property(self, "modulate", Color(10,10,10), 0.05)
	t.tween_property(self, "modulate", Color(1,1,1,1), 0.05)
	if current_health <= 0:
		die() 


# --- MORTE ---
func die():
	print("Boss sconfitto! GG!")
	remove_from_group("enemies") 
	remove_from_group("boss")
	
	# --- SCHERMATA DI FINE GIOCO (GG) ---
	# 1. Creiamo un "livello tela" per far apparire la scritta sopra a tutto il gioco
	var gg_layer = CanvasLayer.new()
	gg_layer.layer = 100 # Livello altissimo così copre sia la mappa che i player
	
	# 2. Creiamo l'etichetta di testo
	var gg_label = Label.new()
	gg_label.text = "GG\nHAI VINTO!"
	
	# 3. La centriamo perfettamente su tutto lo schermo
	gg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gg_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 4. Le diamo uno stile epico (Enorme, Dorata, con ombra nera)
	gg_label.add_theme_font_size_override("font_size", 120)
	gg_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Oro
	gg_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0)) # Ombra nera
	gg_label.add_theme_constant_override("shadow_outline_size", 15)
	
	# 5. Aggiungiamo il testo al livello, e il livello alla scena principale
	gg_layer.add_child(gg_label)
	get_tree().current_scene.call_deferred("add_child", gg_layer)
	
	# 6. Animazione epica: la facciamo apparire dal nulla (dissolvenza incrociata di 2 secondi)
	gg_label.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(gg_label, "modulate:a", 1.0, 2.0)
	
	# 7. Addio Boss
	queue_free()

func update_animations():
	if is_attacking: return
	if velocity.length() > 0:
		anim.play("run")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")

# --- SVEGLIATO DALLA STANZA ---
func activate_boss():
	print("Il Boss si è svegliato!")
	is_active = true
