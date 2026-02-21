extends CharacterBody2D

# --- STATISTICHE BASE ---
@export_group("Base")
@export var speed: float = 100.0
@export var max_health: int = 6 
@export var bomb_scene: PackedScene

# --- CONFIGURAZIONE COMBATTIMENTO ---
@export_group("Combact")
@export var knockback_force: float = 250.0
@export var invincibility_time: float = 1.0
@export var push_force: float = 5000.0
@export var speed_reduction: float = 0.7

# --- CONFIGURAZIONE DASH ---
@export_group("Dash Settings")
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 3.0

# Precaricamento scena Game Over
var game_over_screen = preload("res://scenes/GameOverScreen.tscn")

# Riferimenti ai nodi
@onready var anim = $AnimatedSprite2D
@onready var hand = $Hand
@onready var sfx_hurt = $SfxHurt

# Riferimenti all'HUD
@export_group("Utility")
@export var coins: int = 0
@export var bombs: int = 0

# Variabile Armatura (Scudi)
var armor = 0

#effetti rallentamento
var rallentato=0
@onready var bolle = $Bolle/bolle
var slow_effect_timer : Timer

# --- SEGNALI ---
signal coins_changed(new_amount)
signal bombs_changed(new_amount)
signal health_changed(new_health)
signal armor_changed(new_armor)

# SEGNALI SEPARATI PER I TIMER
signal boost_updated(time_left) # Per la Forza (Label Blu)
signal speed_updated(time_left) # Per la Velocità (Label Verde) - NUOVO!
signal slow_updated(time_left)
signal dash_cooldown_updated(percentuale: float)
# Variabili di stato
var health = 6
var is_hurt = false
var last_direction = Vector2.RIGHT

# Variabili per la sicurezza del danno
var can_take_damage = true
var knockback_vector = Vector2.ZERO

# --- VARIABILI POZIONI ---
var current_damage_bonus = 0
var boost_timer : Timer
var boost_tween: Tween

# Variabili Velocità
var default_speed = 100.0  
var speed_timer : Timer    
var speed_tween: Tween # Variabile per il lampeggio verde

# --- VARIABILI DASH ---
var is_dashing = false
var can_dash = true
var dash_timer : Timer



func _ready():
	if not is_in_group("player"):
		add_to_group("player")

	health = max_health
	default_speed = speed 
	
	health_changed.emit(health)
	armor_changed.emit(armor)
	
	# Timer Vari
	boost_timer = Timer.new()
	boost_timer.one_shot = true
	boost_timer.timeout.connect(_on_boost_ended)
	add_child(boost_timer)
	
	dash_timer = Timer.new()
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_cooldown
	dash_timer.timeout.connect(_on_dash_cooldown_ended)
	add_child(dash_timer)
	
	speed_timer = Timer.new()
	speed_timer.one_shot = true
	speed_timer.timeout.connect(_on_speed_boost_ended)
	add_child(speed_timer)
	
	slow_effect_timer = Timer.new()
	slow_effect_timer.one_shot = true
	slow_effect_timer.timeout.connect(_on_slow_ended)
	add_child(slow_effect_timer)
	
func _physics_process(delta):
	if is_dashing:
		_process_dash(delta)
		return 

	# --- 1. GESTIONE INPUT ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if is_hurt:
		direction = Vector2.ZERO
	
	# --- 2. CALCOLO VELOCITÀ ---
	velocity = direction * speed
	
	if knockback_vector != Vector2.ZERO:
		velocity += knockback_vector
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)

	# --- 3. ANIMAZIONI ---
	if not is_hurt:
		if direction:
			anim.play("run")
		else:
			anim.play("idle")
	
	# --- 4. DIREZIONE DELLO SPRITE ---
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
		
		if direction.x < 0:
			anim.flip_h = true
			hand.scale.x = -1
			hand.position.x = -abs(hand.position.x)
		elif direction.x > 0:
			anim.flip_h = false
			hand.scale.x = 1
			hand.position.x = abs(hand.position.x)

	# --- 5. AZIONI ---
	if Input.is_action_just_pressed("attack") and not is_hurt:
		attempt_attack()

	if Input.is_action_just_pressed("dash") and can_dash and not is_hurt and direction != Vector2.ZERO:
		start_dash()

	if Input.is_key_pressed(KEY_M): add_coin(1)
	if Input.is_key_pressed(KEY_B): add_bomb(1)
	if Input.is_action_just_pressed("place_bomb") and not is_hurt: place_bomb()

	# --- 9. AGGIORNAMENTO HUD TIMER (CORRETTO) ---
	# Ora gestiamo i due timer separatamente!
	
	# Timer Danno (Blu)
	if is_instance_valid(boost_timer) and not boost_timer.is_stopped():
		boost_updated.emit(boost_timer.time_left)
	
	# Timer Velocità (Verde)
	if is_instance_valid(speed_timer) and not speed_timer.is_stopped():
		speed_updated.emit(speed_timer.time_left)
		
	#Timer rallentamento (viola)
	if is_instance_valid(slow_effect_timer) and not slow_effect_timer.is_stopped():
		slow_updated.emit(slow_effect_timer.time_left)
	# Timer Dash
	if is_instance_valid(dash_timer) and not dash_timer.is_stopped():
		var p = (1.0 - (dash_timer.time_left / dash_timer.wait_time)) * 100
		dash_cooldown_updated.emit(p)
	else:
		dash_cooldown_updated.emit(100.0)
	# MOVIMENTO
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			collider.linear_velocity = push_dir * speed * 1.5

# DASH
func start_dash():
	is_dashing = true
	can_dash = false
	anim.modulate = Color(0.8, 0.6, 1.0) # Viola
	var duration_timer = get_tree().create_timer(dash_duration)
	duration_timer.timeout.connect(end_dash)
	print("DASH!")

func _process_dash(_delta):
	velocity = last_direction * dash_speed
	move_and_slide()

func end_dash():
	is_dashing = false
	anim.modulate = Color.WHITE
	dash_timer.start()

func _on_dash_cooldown_ended():
	can_dash = true
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(2, 2, 2), 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)

# --- FUNZIONI POZIONE DANNO (BLUE) ---
func activate_damage_boost(amount, duration):
	current_damage_bonus = amount
	if boost_timer:
		boost_timer.wait_time = duration
		boost_timer.start()
	print("POWER UP BLU!")
	
	if boost_tween: boost_tween.kill()
	boost_tween = create_tween().set_loops()
	boost_tween.tween_property(anim, "modulate", Color(0.4, 0.4, 1.5), 0.3)
	boost_tween.tween_property(anim, "modulate", Color.WHITE, 0.3)

func _on_boost_ended():
	current_damage_bonus = 0
	boost_updated.emit(0) # Spegne la label BLU
	print("Fine Boost Danno")
	if boost_tween: boost_tween.kill()
	var reset_tween = create_tween()
	reset_tween.tween_property(anim, "modulate", Color.WHITE, 0.2)

# --- FUNZIONI POZIONE VELOCITÀ (VERDE) ---
func activate_speed_boost(multiplier, duration):
	speed = default_speed * multiplier 
	
	if speed_timer:
		speed_timer.wait_time = duration
		speed_timer.start()
	print("SPEED UP!")
	
	# Effetto Lampeggio Verde
	if speed_tween: speed_tween.kill()
	speed_tween = create_tween().set_loops()
	speed_tween.tween_property(anim, "modulate", Color(0.5, 1.0, 0.5), 0.3)
	speed_tween.tween_property(anim, "modulate", Color.WHITE, 0.3)

func _on_speed_boost_ended():
	speed = default_speed
	speed_updated.emit(0) # Spegne la label VERDE (Nuovo segnale)
	print("Fine Speed Boost")
	
	if speed_tween: speed_tween.kill()
	var reset_tween = create_tween()
	reset_tween.tween_property(anim, "modulate", Color.WHITE, 0.2)

# --- ALTRE FUNZIONI ---
func attempt_attack():
	if hand.get_child_count() > 0:
		var weapon = hand.get_child(0)
		if weapon.has_method("attack"): weapon.attack()

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

	# --- FAI PARTIRE IL SUONO DEL DANNO QUI ---
	if sfx_hurt:
		sfx_hurt.play()
	
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
	print("GAME OVER")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 40, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + 1000, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	anim.play("hurt")
	await tween.finished
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
			var distance = 40
			bomb.global_position = global_position + (last_direction * distance)
			get_parent().add_child(bomb)
func slow_down():
	if not rallentato:
		rallentato = 1
		speed *= speed_reduction
		bolle.emitting = true

	slow_effect_timer.start(5.0)
	
func _on_slow_ended():
	rallentato = 0
	speed = default_speed
	bolle.emitting = false
	slow_updated.emit(0)
