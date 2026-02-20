extends Area2D

@export var projectile_scene: PackedScene 
@export var fire_rate: float = 0.5

@onready var spawn_point = $Punta

var can_shoot = true

func _ready():
	set_as_top_level(true)

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var hand_node = player.get_node_or_null("Hand")
		if hand_node:
			global_position = hand_node.global_position
		
		# Gestione visiva del bastone (si gira a destra e sinistra)
		if "last_direction" in player:
			var dir = player.last_direction
			rotation = 0 
			if dir.x < 0:
				scale.x = -0.7
			elif dir.x > 0:
				scale.x = 0.7

# --- FUNZIONE CHIAMATA DAL PLAYER QUANDO PREMI IL TASTO ATTACCO ---
func attack():
	if not can_shoot: return
	shoot()

func shoot():
	if not projectile_scene: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return # Sicurezza
	
	# 1. DIREZIONE: Prendiamo la direzione in cui sta guardando il player
	var shoot_dir = Vector2.RIGHT
	if "last_direction" in player:
		# Se il player guarda in alto, sparerà in alto!
		shoot_dir = player.last_direction
	
	# 2. CALCOLO DANNO
	var final_damage = 2
	if "current_damage_bonus" in player:
		final_damage += player.current_damage_bonus

	# 3. CREAZIONE PALLA DI FUOCO
	var fireball = projectile_scene.instantiate()
	
	if spawn_point:
		fireball.global_position = spawn_point.global_position
	else:
		fireball.global_position = global_position
		
	# 4. CHIAMATA AL SETUP DELLA PALLA DI FUOCO
	fireball.setup(shoot_dir, final_damage, player)
	
	# Aggiungiamo il proiettile alla scena del livello
	get_tree().current_scene.add_child(fireball)
	
	# 5. COOLDOWN (Tempo di ricarica tra un colpo e l'altro)
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
