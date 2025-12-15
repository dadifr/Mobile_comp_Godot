extends CharacterBody2D

@export var speed = 60.0
@export var damage = 1
@export var attack_range = 15.0
@export var detection_range = 150.0

@onready var anim = $AnimatedSprite2D
var player = null

# STATI
var can_attack = true
var is_searching = false
var was_chasing = false
var is_attacking = false

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if player == null: return
	
	# --- BLOCCO TOTALE SE STA ATTACCANDO ---
	# Se sta attaccando, ignora tutto il resto (movimento, ricerca, ecc.)
	# finché l'animazione non finisce.
	if is_attacking:
		return 

	var distance = global_position.distance_to(player.global_position)
	
	# --- LOGICA DI RICERCA (Se il player è lontano) ---
	if distance > detection_range:
		if was_chasing and not is_searching:
			start_searching()
			return

		if is_searching:
			velocity = Vector2.ZERO
			move_and_slide()
			return
			
		anim.play("idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# --- LOGICA DI INSEGUIMENTO (Se il player è vicino) ---
	is_searching = false
	was_chasing = true
	
	if distance > attack_range:
		# Muoviti verso il giocatore
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		anim.play("run")
		
		if direction.x < 0:
			anim.flip_h = true
		else:
			anim.flip_h = false
			
		move_and_slide()
		
	else:
		# Sei abbastanza vicino per attaccare?
		velocity = Vector2.ZERO
		if can_attack:
			attack_player()

func start_searching():
	is_searching = true
	was_chasing = false
	velocity = Vector2.ZERO
	anim.play("idle")
	
	for i in range(4):
		if not is_searching: return
		anim.flip_h = !anim.flip_h
		await get_tree().create_timer(0.5).timeout
	
	is_searching = false

func attack_player():
	is_attacking = true
	can_attack = false
	
	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		
		# --- MODIFICA 1: IL DANNO ORA È QUI (SUBITO) ---
		# Passiamo anche "global_position" al player, così sa da dove arriva il colpo!
		if player != null:
			player.take_damage(damage, global_position)
		
		# Ora aspettiamo che l'animazione finisca
		await anim.animation_finished
	else:
		# Fallback se non hai l'animazione
		if player != null:
			player.take_damage(damage, global_position)
		await get_tree().create_timer(0.5).timeout
	
	is_attacking = false
	anim.play("idle")
	
	await get_tree().create_timer(1.0).timeout
	can_attack = true

func _draw():
	# Disegna il raggio di visione
	draw_circle(Vector2.ZERO, detection_range, Color(1, 0, 0, 0.1))
	# Disegna il raggio di attacco (per debug)
	draw_circle(Vector2.ZERO, attack_range, Color(1, 1, 0, 0.1))
