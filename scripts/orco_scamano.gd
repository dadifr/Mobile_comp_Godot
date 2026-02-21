extends CharacterBody2D

# --- STATISTICHE E HP ---
@export_group("Statistiche")
@export var max_health = 15
var current_health = 0

# --- LIMITI MAPPA ---
@export_group("Limiti Mappa")
@export var min_x = 100.0   
@export var max_x = 1000.0  
@export var min_y = 100.0   
@export var max_y = 600.0   

# --- MOVIMENTO CASUALE A SCATTI ---
@export_group("Movimento")
@export var step_speed = 90.0
@export var step_duration = 0.5   # Tempo in cui cammina
@export var pause_duration = 2.0  # <--- AUMENTA QUESTO VALORE per farlo stare fermo più a lungo tra un passo e l'altro

# --- COMBATTIMENTO ---
@export_group("Attacco")
@export var explosion_scene: PackedScene
@export var attack_cooldown = 4.0
@export var warning_time = 0.6
@export var attack_range = 400.0 

# --- DEBUG ---
@export_group("Debug")
@export var show_debug_range = true

var player = null
var can_attack = true
var is_moving = false
var move_direction = Vector2.ZERO

@onready var anim = $AnimatedSprite2D

func _ready():
	current_health = max_health
	# Fa partire subito il ciclo di movimento casuale
	decide_next_action() 

func _physics_process(_delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# --- GESTIONE MOVIMENTO ---
	if is_moving:
		velocity = move_direction * step_speed
		if anim: 
			anim.play("run")
			anim.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		if anim: 
			anim.play("idle")
			# Anche se si muove a caso, quando è fermo guarda verso di te
			anim.flip_h = player.global_position.x < global_position.x

	move_and_slide()
	
	# --- CONTROLLO ATTACCO ---
	if can_attack:
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			spawn_explosion_on_player()

# --- CICLO DI MOVIMENTO CASUALE ---
func decide_next_action():
	if not is_inside_tree(): return

	# 1. PAUSA: sta fermo per il tempo stabilito da pause_duration
	is_moving = false
	await get_tree().create_timer(pause_duration).timeout

	# 2. SCELTA DIREZIONE: sceglie un angolo a caso
	var angle = deg_to_rad(randi_range(0, 360))
	move_direction = Vector2.RIGHT.rotated(angle)
	
	# Controllo rimbalzo: se sta per uscire dalla mappa, inverte la rotta
	var future_pos = global_position + (move_direction * step_speed * step_duration)
	if future_pos.x < min_x or future_pos.x > max_x or future_pos.y < min_y or future_pos.y > max_y:
		move_direction *= -1

	# 3. MOVIMENTO: cammina per il tempo stabilito da step_duration
	is_moving = true
	await get_tree().create_timer(step_duration).timeout
	
	# Ripete il ciclo all'infinito
	decide_next_action() 

# --- LOGICA ESPLOSIONE ---
func spawn_explosion_on_player():
	if not is_instance_valid(player) or explosion_scene == null: return
	
	can_attack = false
	var target_pos = player.global_position
	
	var warning_circle = Line2D.new()
	var points = []
	var segments = 32
	var radius = 20.0 
	
	for i in range(segments + 1):
		var angle = (i * PI * 2.0) / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	warning_circle.points = points
	warning_circle.width = 2.0
	warning_circle.default_color = Color(1, 0, 0, 0.6)
	warning_circle.global_position = target_pos
	get_parent().add_child(warning_circle)
	
	var t = create_tween()
	t.tween_property(self, "modulate", Color(5, 1, 1), warning_time)
	
	await get_tree().create_timer(warning_time).timeout
	
	if is_instance_valid(warning_circle):
		warning_circle.queue_free()
	
	if is_inside_tree():
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = target_pos
		get_parent().add_child(exp_node)
	
	modulate = Color(1, 1, 1)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# --- GESTIONE DANNO RICEVUTO ---
func take_damage(amount, _source_pos = Vector2.ZERO):
	current_health -= amount
	
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	flash.tween_property(self, "modulate", Color(1, 1, 1), 0.05)
	
	if current_health <= 0:
		queue_free()

# --- FUNZIONI DI DEBUG VISIVO ---
func _draw():
	if show_debug_range:
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(1, 0, 0, 0.4), 2.0)    
		
func _process(_delta):
	if show_debug_range:
		queue_redraw()
