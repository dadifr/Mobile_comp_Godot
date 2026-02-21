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

# --- MOVIMENTO CASUALE ---
@export_group("Movimento")
@export var step_speed = 90.0
@export var pause_duration = 1.5
@export var step_duration = 0.5

# --- COMBATTIMENTO ---
@export_group("Attacco")
@export var explosion_scene: PackedScene # Trascina qui EsplosioneNemica.tscn
@export var attack_cooldown = 4.0
@export var warning_time = 0.6 # Tempo di "caricamento" prima dell'esplosione

var player = null
var can_attack = true
var is_moving = false
var move_direction = Vector2.ZERO

@onready var anim = $AnimatedSprite2D

func _ready():
	current_health = max_health
	decide_next_action()

func _physics_process(_delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# Gestione Movimento
	if is_moving:
		velocity = move_direction * step_speed
		anim.play("run")
		anim.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		anim.play("idle")
		anim.flip_h = player.global_position.x < global_position.x

	move_and_slide()
	
	# Se il player è nel range, prova ad attaccare
	if can_attack:
		spawn_explosion_on_player()

# --- LOGICA MOVIMENTO CASUALE ---
func decide_next_action():
	if not is_inside_tree(): return

	# Sceglie direzione casuale
	var angle = deg_to_rad(randi_range(0, 360))
	move_direction = Vector2.RIGHT.rotated(angle)
	
	# Rimbalzo sui bordi
	var future_pos = global_position + (move_direction * step_speed * step_duration)
	if future_pos.x < min_x or future_pos.x > max_x or future_pos.y < min_y or future_pos.y > max_y:
		move_direction *= -1

	is_moving = true
	await get_tree().create_timer(step_duration).timeout
	
	is_moving = false
	await get_tree().create_timer(pause_duration).timeout
	
	decide_next_action()

# --- LOGICA ESPLOSIONE ---
func spawn_explosion_on_player():
	if not is_instance_valid(player) or explosion_scene == null: return
	
	can_attack = false
	var target_pos = player.global_position
	
	# --- CREAZIONE ALERT PRECISO ---
	# Creiamo un nodo Line2D per disegnare un cerchio vuoto (più pulito di uno Sprite)
	var warning_circle = Line2D.new()
	var points = []
	var segments = 32 # Più segmenti = cerchio più liscio
	var radius = 20.0 # <--- MODIFICA QUESTO valore per farlo uguale alla tua esplosione
	
	for i in range(segments + 1):
		var angle = (i * PI * 2.0) / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	warning_circle.points = points
	warning_circle.width = 2.0 # Spessore del cerchio
	warning_circle.default_color = Color(1, 0, 0, 0.6) # Rosso semitrasparente
	warning_circle.global_position = target_pos
	get_parent().add_child(warning_circle)
	
	# Feedback visivo sul Mob
	var t = create_tween()
	t.tween_property(self, "modulate", Color(5, 1, 1), warning_time)
	
	await get_tree().create_timer(warning_time).timeout
	
	# Rimuovi alert e spawna esplosione
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
	
	# Flash feedback
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	flash.tween_property(self, "modulate", Color(1, 1, 1), 0.05)
	
	if current_health <= 0:
		queue_free()
