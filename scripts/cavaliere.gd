extends CharacterBody2D

@export var speed: float = 100.0
@export var max_health: int = 6 # 3 Cuori
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

# ### NUOVO ### Variabile Armatura (Scudi)
var armor = 0

# Definiamo dei segnali per avvisare l'HUD
signal coins_changed(new_amount)
signal bombs_changed(new_amount)
signal health_changed(new_health)
signal armor_changed(new_armor)
signal boost_updated(time_left) # Segnale Timer Pozione

# Variabili di stato
var health = 6
var is_hurt = false
var last_direction = Vector2.RIGHT

# Variabili per la sicurezza del danno
var can_take_damage = true
var knockback_vector = Vector2.ZERO

# Variabili per il timer delle pozioni
var current_damage_bonus = 0
var boost_timer : Timer
# NUOVO: Variabile per gestire l'animazione lampeggiante blu
var boost_tween: Tween

func _ready():
	# 1. SICUREZZA GRUPPI: Ci assicuriamo via codice che siamo nel gruppo "player"
	if not is_in_group("player"):
		add_to_group("player")
		print("Player aggiunto al gruppo 'player' via codice.")

	# 2. SETUP STATISTICHE
	health = max_health
	health_changed.emit(health)
	armor_changed.emit(armor)
	
	# 3. CREAZIONE TIMER POZIONE
	boost_timer = Timer.new()
	boost_timer.one_shot = true
	boost_timer.timeout.connect(_on_boost_ended)
	add_child(boost_timer)

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

	# --- 8. AGGIORNAMENTO HUD TIMER (POZIONE) ---
	# Aggiorniamo l'HUD ogni frame se il timer corre
	if is_instance_valid(boost_timer) and not boost_timer.is_stopped():
		boost_updated.emit(boost_timer.time_left)

	# --- 9. MOVIMENTO FISICO ---
	move_and_slide()
	
	# --- 10. SPINTA RIGIDBODIES ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_dir = -collision.get_normal()
			collider.linear_velocity = push_dir * speed * 1.5

# --- NUOVE FUNZIONI PER LA POZIONE (AGGIORNATE CON EFFETTO BLU) ---

# 1. Chiamata dalla Pozione
func activate_damage_boost(amount, duration):
	current_damage_bonus = amount
	
	# Avvio Timer
	if boost_timer:
		boost_timer.wait_time = duration
		boost_timer.start()
	else:
		print("ERRORE: Boost Timer non esiste!")
		
	print("POWER UP BLU! Danni +", amount)
	
	# --- EFFETTO VISIVO (Lampeggio Blu) ---
	# Se c'era già un'animazione attiva, la fermiamo per riavviarla pulita
	if boost_tween:
		boost_tween.kill()
	
	# Creiamo un nuovo Tween che si ripete all'infinito
	boost_tween = create_tween().set_loops()
	
	# Passo 1: Diventa Blu Luminoso (in 0.3 secondi)
	# Nota: Usiamo valori > 1 per fare un effetto "Glow" se l'ambiente lo permette, 
	# oppure semplicemente una tinta bluastra mantenendo visibile lo sprite.
	boost_tween.tween_property(anim, "modulate", Color(0.4, 0.4, 1.5), 0.3) 
	
	# Passo 2: Torna Normale (in 0.3 secondi)
	boost_tween.tween_property(anim, "modulate", Color.WHITE, 0.3)

# 2. Quando il tempo scade
func _on_boost_ended():
	current_damage_bonus = 0
	boost_updated.emit(0)
	print("Effetto pozione finito.")
	
	# --- STOP EFFETTO VISIVO ---
	if boost_tween:
		boost_tween.kill() # Ferma il lampeggio
	
	# Assicuriamoci che il personaggio torni del colore normale dolcemente
	var reset_tween = create_tween()
	reset_tween.tween_property(anim, "modulate", Color.WHITE, 0.2)

# Funzione per attaccare
func attempt_attack():
	if hand.get_child_count() > 0:
		var weapon = hand.get_child(0)
		if weapon.has_method("attack"):
			weapon.attack()

# ### TAKE DAMAGE ###
func take_damage(amount, enemy_pos = Vector2.ZERO):
	if not can_take_damage:
		return
	
	# 1. LOGICA ARMATURA
	var damage_to_health = amount
	
	if armor > 0:
		if armor >= amount:
			armor -= amount
			damage_to_health = 0
		else:
			damage_to_health = amount - armor
			armor = 0
		
		armor_changed.emit(armor)
		print("Armatura parzialmente rotta! Rimasta: ", armor)

	# 2. LOGICA VITA ROSSA
	if damage_to_health > 0:
		health -= damage_to_health
		health_changed.emit(health)
		print("Ahi! Vita rossa rimasta: ", health)
		
		if health <= 0:
			die()
			return

	# 3. EFFETTI FISICI
	start_invincibility()
	
	if enemy_pos != Vector2.ZERO:
		var knockback_dir = (global_position - enemy_pos).normalized()
		knockback_vector = knockback_dir * knockback_force
	
	is_hurt = true
	anim.play("hurt")
	
	await anim.animation_finished
	is_hurt = false
	anim.play("idle")

# Gestione Invincibilità
func start_invincibility():
	can_take_damage = false
	# Nota: self.modulate agisce "sopra" anim.modulate.
	# Quindi se sei Blu (anim) + Invincibile (self), diventi Blu Trasparente. Perfetto!
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

# Aggiungi Armatura (Pozioni)
func add_armor(amount):
	armor += amount
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
