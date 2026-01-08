extends CharacterBody2D

# --- CONFIGURAZIONE BASE ---
@export var speed: float = 100.0
@export var max_health: int = 6 
@export var bomb_scene: PackedScene

# --- CONFIGURAZIONE COMBATTIMENTO ---
@export var knockback_force: float = 250.0
@export var invincibility_time: float = 1.0
@export var push_force: float = 5000.0

# Precaricamento scena Game Over
var game_over_screen = preload("res://scenes/GameOverScreen.tscn")

# Riferimenti ai nodi
@onready var anim = $AnimatedSprite2D
@onready var hand = $Hand

# Riferimenti all'HUD
@export var coins: int = 0
@export var bombs: int = 0

# Variabile Armatura
var armor = 0

# --- SEGNALI ---
signal coins_changed(new_amount)
signal bombs_changed(new_amount)
signal health_changed(new_health)
signal armor_changed(new_armor)
signal boost_updated(time_left) # Timer Danno (Blu)
signal speed_updated(time_left) # Timer Velocità (Verde) - NUOVO

# Variabili di stato
var health = 6
var is_hurt = false
var last_direction = Vector2.RIGHT

# Sicurezza danno
var can_take_damage = true
var knockback_vector = Vector2.ZERO

# --- VARIABILI POZIONI ---
# Danno
var current_damage_bonus = 0
var boost_timer : Timer
var boost_tween: Tween

# Velocità
var base_speed : float = 100.0 
var speed_timer : Timer
var speed_tween : Tween

func _ready():
	# 1. SETUP GRUPPI
	if not is_in_group("player"):
		add_to_group("player")

	# 2. SETUP STATISTICHE
	health = max_health
	health_changed.emit(health)
	armor_changed.emit(armor)
	
	# Salvo la velocità base per poterla ripristinare
	base_speed = speed 
	
	# 3. CREAZIONE TIMER DANNO
	boost_timer = Timer.new()
	boost_timer.one_shot = true
	boost_timer.timeout.connect(_on_boost_ended)
	add_child(boost_timer)

	# 4. CREAZIONE TIMER VELOCITÀ
	speed_timer = Timer.new()
	speed_timer.one_shot = true
	speed_timer.timeout.connect(_on_speed_ended)
	add_child(speed_timer)

func _physics_process(delta):
	# --- 1. GESTIONE INPUT ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if is_hurt:
		direction = Vector2.ZERO
	
	# --- 2. CALCOLO VELOCITÀ ---
	velocity = direction * speed
	
	# Sommiamo Knockback
	if knockback_vector != Vector2.ZERO:
		velocity += knockback_vector
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)

	# --- 3. ANIMAZIONI ---
	if not is_hurt:
		if direction:
			anim.play("run")
		else:
			anim.play("idle")
	
	# --- 4. DIREZIONE SPRITE ---
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
		
		# A. GESTIONE SPRITE PERSONAGGIO (L'elfo si gira destra/sinistra)
		if direction.x < 0:
			anim.flip_h = true
		elif direction.x > 0:
			anim.flip_h = false

		# B. GESTIONE MANO (L'arco ruota a 360°)
		# 1. Posiziona la mano nella direzione in cui guardi (a 8 pixel di distanza)
		hand.position = last_direction * 8
		
		# 2. Ruota la mano
		hand.rotation = last_direction.angle()
		
		# 3. RESETTA E CORREGGE LA SCALA
		# Importante: Resettiamo sempre scale.x a 1 per cancellare il vecchio ribaltamento
		hand.scale.x = 0.7 
		
		# Correzione estetica:
		# Se guardiamo a sinistra, l'arco ruotato sarebbe a testa in giù.
		# Lo specchiamo in verticale (Y) per raddrizzarlo, SENZA rovinare la direzione.
		if direction.x < 0:
			hand.scale.y = -0.7
		else:
			hand.scale.y = 0.7

	# --- 5. AZIONI ---
	if Input.is_action_just_pressed("attack") and not is_hurt:
		attempt_attack()

	if Input.is_key_pressed(KEY_M): add_coin(1)
	if Input.is_key_pressed(KEY_B): add_bomb(1)

	if Input.is_action_just_pressed("place_bomb") and not is_hurt:
		place_bomb()

	# --- 6. AGGIORNAMENTO SEGNALI HUD (TIMER) ---
	
	# Timer Danno
	if is_instance_valid(boost_timer) and not boost_timer.is_stopped():
		boost_updated.emit(boost_timer.time_left)

	# Timer Velocità (NUOVO COLLEGAMENTO)
	if is_instance_valid(speed_timer) and not speed_timer.is_stopped():
		speed_updated.emit(speed_timer.time_left)

	move_and_slide()
	
	# Spinta Rigidbodies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			collider.linear_velocity = push_dir * speed * 1.5

# --- FUNZIONI POZIONE DANNO (BLU) ---
func activate_damage_boost(amount, duration):
	current_damage_bonus = amount
	if boost_timer:
		boost_timer.wait_time = duration
		boost_timer.start()
	
	# Effetto Blu
	if boost_tween: boost_tween.kill()
	boost_tween = create_tween().set_loops()
	boost_tween.tween_property(anim, "modulate", Color(0.4, 0.4, 1.5), 0.3)
	boost_tween.tween_property(anim, "modulate", Color.WHITE, 0.3)

func _on_boost_ended():
	current_damage_bonus = 0
	boost_updated.emit(0)
	if boost_tween: boost_tween.kill()
	var reset = create_tween()
	reset.tween_property(anim, "modulate", Color.WHITE, 0.2)


# --- FUNZIONI POZIONE VELOCITÀ (VERDE) ---

func activate_speed_boost(multiplier, duration):
	# 1. Calcola velocità
	speed = base_speed * multiplier
	
	# 2. Avvia Timer
	if speed_timer:
		speed_timer.wait_time = duration
		speed_timer.start()
		print("SPEED UP! Velocità x", multiplier)
	
	# 3. Effetto Visivo (VERDE FLUO)
	if speed_tween: speed_tween.kill()
	if boost_tween: boost_tween.kill()
	
	speed_tween = create_tween().set_loops()
	
	# (R=0.5, G=1.5, B=0.5) -> Verde molto luminoso
	speed_tween.tween_property(anim, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	speed_tween.tween_property(anim, "modulate", Color.WHITE, 0.2)

func _on_speed_ended():
	# 1. Ripristina velocità originale
	speed = base_speed
	
	# 2. Avvisa HUD che è finito
	speed_updated.emit(0) 
	print("Effetto Velocità finito.")
	
	# 3. Ferma l'effetto verde
	if speed_tween: speed_tween.kill()
	
	# 4. Controllo intelligente: Se ho ancora il Danno attivo, riattivo il lampeggio BLU
	if not boost_timer.is_stopped():
		activate_damage_boost(current_damage_bonus, boost_timer.time_left)
	else:
		# Altrimenti torno bianco normale
		anim.modulate = Color.WHITE

# --- ALTRE FUNZIONI ---
func attempt_attack():
	if hand.get_child_count() > 0:
		var weapon = hand.get_child(0)
		if weapon.has_method("attack"):
			weapon.attack()

func take_damage(amount, enemy_pos = Vector2.ZERO):
	if not can_take_damage: return
	
	var damage_to_health = amount
	if armor > 0:
		if armor >= amount:
			armor -= amount
			damage_to_health = 0
		else:
			damage_to_health = amount - armor
			armor = 0
		armor_changed.emit(armor)

	if damage_to_health > 0:
		health -= damage_to_health
		health_changed.emit(health)
		if health <= 0:
			die()
			return

	start_invincibility()
	if enemy_pos != Vector2.ZERO:
		var knockback_dir = (global_position - enemy_pos).normalized()
		knockback_vector = knockback_dir * knockback_force
	
	is_hurt = true
	anim.play("hurt")
	await anim.animation_finished
	is_hurt = false
	anim.play("idle")

func start_invincibility():
	can_take_damage = false
	modulate.a = 0.5
	var timer = get_tree().create_timer(invincibility_time)
	timer.timeout.connect(_on_invincibility_end)

func _on_invincibility_end():
	can_take_damage = true
	modulate.a = 1.0

func heal(amount):
	health += amount
	if health > max_health: health = max_health
	health_changed.emit(health)

func add_armor(amount):
	armor += amount
	armor_changed.emit(armor)

func die():
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var screen_instance = game_over_screen.instantiate()
	get_tree().root.add_child(screen_instance)
	queue_free()

func add_coin(amount):
	coins += amount
	coins_changed.emit(coins)

func add_bomb(amount):
	bombs += amount
	bombs_changed.emit(bombs)

func place_bomb():
	if bombs > 0:
		bombs -= 1
		bombs_changed.emit(bombs)
		if bomb_scene:
			var bomb = bomb_scene.instantiate()
			bomb.global_position = global_position + (last_direction * 40)
			get_parent().add_child(bomb)
