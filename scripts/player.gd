extends CharacterBody2D

@export var speed = 100.0
@export var max_health = 6 # 3 Cuori
@export var knockback_force = 200.0

# Precaricamento scena Game Over
var game_over_screen = preload("res://scenes/GameOverScreen.tscn")

# Riferimenti ai nodi
@onready var anim = $AnimatedSprite2D
@onready var hand = $Hand # Il nodo che tiene l'arma

#Riferimenti all'HUD
@export var coins = 0
@export var bombs = 0

# Definiamo dei segnali per avvisare l'HUD quando cambiano
signal coins_changed(new_amount)
signal bombs_changed(new_amount)

# Variabili di stato
var health = 6
var is_hurt = false

# Segnali
signal health_changed(new_health)

func _ready():
	health = max_health
	health_changed.emit(health)

func _physics_process(delta):
	# --- 1. GESTIONE DANNO E KNOCKBACK ---
	if is_hurt:
		# Se sei colpito, scivoli all'indietro e NON puoi muoverti o attaccare
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
		move_and_slide()
		return # Interrompiamo qui la funzione

	# --- 2. MOVIMENTO STANDARD ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * speed
		anim.play("run")
	else:
		velocity = Vector2.ZERO
		anim.play("idle")

	# --- 3. DIREZIONE DELLO SPRITE E DELL'ARMA ---
	if direction.x < 0:
		anim.flip_h = true   # Player guarda a sinistra
		hand.scale.x = -1    # L'arma si specchia
		
		# NUOVO: Se la mano è a destra (positiva), portala a sinistra (negativa)
		# abs() assicura che prendiamo il numero positivo, e il "-" davanti lo rende negativo
		hand.position.x = -abs(hand.position.x) 
		
	elif direction.x > 0:
		anim.flip_h = false  # Player guarda a destra
		hand.scale.x = 1     # L'arma torna normale
		
		# NUOVO: Riportiamo la mano a destra (positiva)
		hand.position.x = abs(hand.position.x)

	# --- 4. INPUT ATTACCO ---
	if Input.is_action_just_pressed("attack"):
		attempt_attack()

	# --- DEBUG / CHEAT ---
	# Usa "is_key_pressed" per tasti rapidi senza doverli configurare nell'Input Map
	if Input.is_key_pressed(KEY_M):
		add_coin(1) # Aggiunge 1 moneta
		
	if Input.is_key_pressed(KEY_B):
		add_bomb(1) # Aggiunge 1 bomba

	# --- 5. APPLICA IL MOVIMENTO ---
	move_and_slide()

# Funzione per attaccare con l'arma equipaggiata
func attempt_attack():
	# Controlliamo se la mano ha un figlio (l'arma)
	if hand.get_child_count() > 0:
		var weapon = hand.get_child(0)
		if weapon.has_method("attack"):
			weapon.attack()
	else:
		print("Sono disarmato!")

# Funzione per ricevere danno
func take_damage(amount, enemy_pos = Vector2.ZERO):
	if is_hurt: return
	
	is_hurt = true
	health -= amount
	health_changed.emit(health)
	print("Ahia! Vita: ", health)
	
	# Calcolo Knockback
	if enemy_pos != Vector2.ZERO:
		var knockback_dir = (global_position - enemy_pos).normalized()
		velocity = knockback_dir * knockback_force
	
	anim.play("hurt")
	
	if health <= 0:
		die()
	else:
		await anim.animation_finished
		is_hurt = false
		anim.play("idle")

func die():
	print("GAME OVER")
	set_physics_process(false)
	is_hurt = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	var camera = $Camera2D
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
	coins_changed.emit(coins) # Avvisa l'HUD
	print("Monete: ", coins)

func add_bomb(amount):
	bombs += amount
	bombs_changed.emit(bombs) # Avvisa l'HUD
	print("Bombe: ", bombs)
