extends CharacterBody2D

@export var speed = 100.0
@export var max_health = 6 # 3 Cuori
@export var bomb_scene: PackedScene

# --- CONFIGURAZIONE COMBATTIMENTO ---
@export var knockback_force = 250.0 
@export var invincibility_time = 1.0 
@export var push_force = 5000.0

# Precaricamento scena Game Over
var game_over_screen = preload("res://scenes/GameOverScreen.tscn")

# Riferimenti ai nodi
@onready var anim = $AnimatedSprite2D
@onready var hand = $Hand 

# Riferimenti all'HUD
@export var coins = 0
@export var bombs = 0

# ### NUOVO ### Variabile Armatura (Scudi)
# 1 punto = Mezzo Scudo, 2 punti = Scudo Intero
var armor = 0

# Definiamo dei segnali per avvisare l'HUD
signal coins_changed(new_amount)
signal bombs_changed(new_amount)
signal health_changed(new_health)
signal armor_changed(new_armor) # ### NUOVO SEGNALE ###

# Variabili di stato
var health = 6
var is_hurt = false 
var last_direction = Vector2.RIGHT

# Variabili per la sicurezza del danno
var can_take_damage = true 
var knockback_vector = Vector2.ZERO 

func _ready():
	health = max_health
	health_changed.emit(health)
	# Emettiamo anche l'armatura iniziale (0)
	armor_changed.emit(armor)

func _physics_process(delta):
	# --- 1. GESTIONE INPUT ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if is_hurt:
		direction = Vector2.ZERO
	
	# --- 2. CALCOLO VELOCITÀ ---
	velocity = direction * speed
	
	# Sommiamo la spinta esterna (Knockback)
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

	# --- 5. INPUT ATTACCO ---
	if Input.is_action_just_pressed("attack") and not is_hurt:
		attempt_attack()

	# --- 6. DEBUG / CHEAT ---
	if Input.is_key_pressed(KEY_M): add_coin(1)
	if Input.is_key_pressed(KEY_B): add_bomb(1)

	# --- 7. PIAZZAMENTO BOMBE ---
	if Input.is_action_just_pressed("place_bomb") and not is_hurt:
		place_bomb()

	# --- 8. MOVIMENTO FISICO ---
	move_and_slide()
	
	# --- 9. SPINTA RIGIDBODIES ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			collider.linear_velocity = push_dir * speed * 1.5

# Funzione per attaccare
func attempt_attack():
	if hand.get_child_count() > 0:
		var weapon = hand.get_child(0)
		if weapon.has_method("attack"):
			weapon.attack()

# ### AGGIORNATO: TAKE DAMAGE CON ARMATURA ###
func take_damage(amount, enemy_pos = Vector2.ZERO):
	if not can_take_damage:
		return
	
	# 1. LOGICA ARMATURA
	# Calcoliamo quanto danno va alla vita rossa
	var damage_to_health = amount
	
	if armor > 0:
		if armor >= amount:
			# L'armatura assorbe tutto il colpo
			armor -= amount
			damage_to_health = 0
		else:
			# L'armatura si rompe, il resto passa alla vita
			damage_to_health = amount - armor
			armor = 0
		
		# Aggiorniamo l'HUD degli scudi
		armor_changed.emit(armor)
		print("Armatura parzialmente rotta! Rimasta: ", armor)

	# 2. LOGICA VITA ROSSA
	# Se è rimasto del danno da fare (perché l'armatura è finita o non c'era)
	if damage_to_health > 0:
		health -= damage_to_health
		health_changed.emit(health)
		print("Ahi! Vita rossa rimasta: ", health)
		
		if health <= 0:
			die()
			return # Stop, sei morto

	# 3. EFFETTI FISICI (Knockback e Invincibilità)
	# Questi avvengono SEMPRE se vieni colpito, anche se l'armatura ha parato tutto
	start_invincibility()
	
	if enemy_pos != Vector2.ZERO:
		var knockback_dir = (global_position - enemy_pos).normalized()
		knockback_vector = knockback_dir * knockback_force
	
	# Animazione danno
	is_hurt = true
	anim.play("hurt")
	
	await anim.animation_finished
	is_hurt = false
	anim.play("idle")

# Gestione Invincibilità
func start_invincibility():
	can_take_damage = false
	modulate.a = 0.5 
	var timer = get_tree().create_timer(invincibility_time)
	timer.timeout.connect(_on_invincibility_end)

func _on_invincibility_end():
	can_take_damage = true
	modulate.a = 1.0 

# Cura Vita Rossa
func heal(amount):
	health += amount
	if health > max_health:
		health = max_health
	health_changed.emit(health)
	print("Curato! Vita: ", health)

# ### NUOVO: Aggiungi Armatura (Pozioni) ###
func add_armor(amount):
	armor += amount
	# Non metto limiti massimi, ma se vuoi puoi mettere: if armor > 6: armor = 6
	armor_changed.emit(armor)
	print("Scudo Aggiunto! Totale Armatura: ", armor)

func die():
	print("GAME OVER")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	var camera = $Camera2D
	if is_instance_valid(camera):
		var old_pos = camera.global_position
		camera.top_level = true
		camera.global_position = old_pos
		camera.position_smoothing_enabled = false
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 40, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + 1000, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	anim.play("hurt")
	
	await tween.finished
	
	if is_instance_valid(camera):
		camera.reparent(get_parent())
		
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
		else:
			print("ERRORE: Manca la scena della Bomba nel Player!")
