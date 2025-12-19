extends StaticBody2D

# --- VARIABILI SCENE ---
@export var coin_scene: PackedScene
@export var potion_scene: PackedScene
@export var bomb_scene: PackedScene 

# --- PROBABILITÀ ---
@export var mimic_chance: float = 0.1 # 10% di probabilità che sia una trappola
@export var potion_chance: float = 0.4
@export var coin_chance: float = 0.8

# Quantità
@export var min_coins: int = 2
@export var max_coins: int = 5

var is_open = false

func _ready():
	$TriggerArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if is_open: return
	if body.is_in_group("player"):
		open_chest()

func open_chest():
	is_open = true
	# Non lanciamo animazioni qui, lasciamo decidere alla logica
	calculate_loot()

func calculate_loot():
	# --- 1. CONTROLLO TRAPPOLA (MIMIC) ---
	# Controlliamo questo PER PRIMO. Se è un mimic, il resto non succede.
	if bomb_scene and randf() <= mimic_chance:
		trigger_mimic()
		return # <--- IMPORTANTE: Esce dalla funzione. Niente loot per te!

	# --- 2. LOGICA STANDARD (LOOT) ---
	var has_loot = false
	
	# Controllo Pozione
	if potion_scene and randf() <= potion_chance:
		spawn_item(potion_scene)
		has_loot = true
		
	# Controllo Monete
	if coin_scene and randf() <= coin_chance:
		var amount = randi_range(min_coins, max_coins)
		for i in range(amount):
			spawn_item(coin_scene)
		has_loot = true
	
	# Feedback Visivo (Aperta o Vuota)
	if has_loot:
		$AnimatedSprite2D.play("open")
	else:
		$AnimatedSprite2D.play("empty")

func trigger_mimic():
	print("È UNA TRAPPOLA!")
	
	# 1. Mostra il mostro
	$AnimatedSprite2D.play("mimic")
	
	# 2. Sputa fuori bombe ATTIVE!
	# Ne facciamo uscire da 2 a 3
	var bomb_amount = randi_range(2, 3)
	
	for i in range(bomb_amount):
		spawn_item(bomb_scene)

func spawn_item(scene_to_spawn):
	var item = scene_to_spawn.instantiate()
	
	# Sparpagliamento casuale
	var random_offset = Vector2(randf_range(-30, 30), randf_range(20, 50))
	item.global_position = global_position + random_offset
	
	if item is RigidBody2D:
		item.linear_damp = 5 
		# Diamo una spinta casuale verso il basso/giocatore
		var random_force = Vector2(randf_range(-0.5, 0.5), 1).normalized() * 30
		item.apply_impulse(random_force)
	
	get_parent().call_deferred("add_child", item)
