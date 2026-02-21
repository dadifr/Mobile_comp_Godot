extends CharacterBody2D

# --- IMPOSTAZIONI ---
@export_group("Movimento")
@export var flee_speed = 130.0 # Corre abbastanza veloce per rendere la caccia divertente!
@export var patrol_speed = 30.0
@export var detection_range = 250.0 # Inizia a scappare da molto lontano

@export_group("Loot")
@export var potion_scene: PackedScene # Trascina qui la tua scena della Pozione di Cura!

var player = null

# Variabili Pattuglia
var move_direction = Vector2.ZERO
var roam_timer = 0.0
var time_to_next_move = 0.0

@onready var anim = $AnimatedSprite2D

func _ready():
	# Lo mettiamo nel gruppo enemies così la stanza si chiude e parte la sfida!
	add_to_group("enemies")
	pick_new_state()

func _physics_process(delta):
	# 1. CERCA IL GIOCATORE
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = null

	# 2. LOGICA DI FUGA O PATTUGLIA
	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < detection_range:
			# --- MODALITÀ FUGA! ---
			# La formula è invertita (global_position - player) per farlo allontanare
			var flee_direction = (global_position - player.global_position).normalized()
			velocity = flee_direction * flee_speed
		else:
			# --- MODALITÀ PATTUGLIA (Tranquillo) ---
			handle_patrol(delta)
	else:
		handle_patrol(delta)

	# 3. ANIMAZIONI
	if velocity.length() > 0:
		# Se hai un'animazione di volo chiamala qui, es: anim.play("fly")
		anim.play("run") 
		if velocity.x < 0:
			anim.flip_h = true
		elif velocity.x > 0:
			anim.flip_h = false
	else:
		anim.play("idle")

	# 4. MOVIMENTO FISICO
	move_and_slide()

# --- FUNZIONI DI PATTUGLIA ---
func handle_patrol(delta):
	roam_timer += delta
	if roam_timer >= time_to_next_move:
		pick_new_state()
	velocity = move_direction * patrol_speed

func pick_new_state():
	roam_timer = 0.0
	time_to_next_move = randf_range(1.0, 3.0)
	if randf() > 0.5:
		move_direction = Vector2.ZERO
	else:
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

# --- RICEZIONE DANNO E "MORTE" ---
func take_damage(amount, source_pos = Vector2.ZERO):
	# L'angelo è fragile e pacifico: basta 1 solo colpo per farlo svanire!
	die()

func die():
	print("Angelo colpito! Lascia un dono e svanisce.")
	
	# Lo rimuoviamo dal gruppo per far aprire le porte della stanza
	remove_from_group("enemies")
	
	# --- DROPPING DELLA POZIONE ---
	if potion_scene != null:
		var potion = potion_scene.instantiate()
		potion.global_position = global_position
		# Usiamo call_deferred per sicurezza quando generiamo oggetti durante un colpo
		get_parent().call_deferred("add_child", potion)
	
	# L'angelo sparisce
	queue_free()
