extends StaticBody2D

# --- 1. CONFIGURAZIONE SCENE (Trascina i .tscn qui) ---

@export_group("Health Items (Cuori)")
@export var potion_h_scene: PackedScene        # Cuore Piccolo
@export var big_potion_h_scene: PackedScene    # Cuore Grande

@export_group("Shield Items (Scudi)")
@export var shield_small_scene: PackedScene    # Mezzo Scudo (Piccolo)
@export var shield_big_scene: PackedScene      # Scudo Intero (Grande)

@export_group("Damage Boost Items (Forza)")
@export var damage_potion_scene: PackedScene     # Boost Piccolo
@export var big_damage_potion_scene: PackedScene # Boost Grande

@export_group("Currency & Traps")
@export var coin_scene: PackedScene
@export var bomb_scene: PackedScene 

# --- 2. PROBABILITÀ DROP (0.1 = 10%, 0.5 = 50%) ---
@export_group("Drop Chances")
@export var mimic_chance: float = 0.1            # 10% Trappola

# Probabilità Cuori
@export var potion_h_chance: float = 0.3         # 30%
@export var big_potion_h_chance: float = 0.1     # 10%

# Probabilità Scudi (Nuove)
@export var shield_small_chance: float = 0.25    # 25% Mezzo Scudo
@export var shield_big_chance: float = 0.10      # 10% Scudo Intero

# Probabilità Danno
@export var damage_potion_chance: float = 0.2    # 20%
@export var big_damage_potion_chance: float = 0.05 # 5% (Molto Raro)

# Probabilità Monete
@export var coin_chance: float = 0.8             # 80%

# Quantità Monete
@export var min_coins: int = 2
@export var max_coins: int = 6

var is_open = false

func _ready():
	if has_node("TriggerArea"):
		$TriggerArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if is_open: return
	if body.is_in_group("player"):
		open_chest()

func open_chest():
	is_open = true
	calculate_loot()

func calculate_loot():
	# --- 1. CONTROLLO TRAPPOLA (MIMIC) ---
	if bomb_scene and randf() <= mimic_chance:
		trigger_mimic()
		return 

	# --- INIZIO LOOT ---
	var has_loot = false
	
	# --- CATEGORIA 1: VITA (Cuori) ---
	if big_potion_h_scene and randf() <= big_potion_h_chance:
		spawn_item(big_potion_h_scene)
		has_loot = true

	if potion_h_scene and randf() <= potion_h_chance:
		spawn_item(potion_h_scene)
		has_loot = true

	# --- CATEGORIA 2: SCUDI (NUOVO!) ---
	# Scudo Grande
	if shield_big_scene and randf() <= shield_big_chance:
		spawn_item(shield_big_scene)
		has_loot = true
		print("Loot: Scudo Grande!")
	
	# Scudo Piccolo
	if shield_small_scene and randf() <= shield_small_chance:
		spawn_item(shield_small_scene)
		has_loot = true
		print("Loot: Scudo Piccolo!")

	# --- CATEGORIA 3: DANNO (Boost) ---
	if big_damage_potion_scene and randf() <= big_damage_potion_chance:
		spawn_item(big_damage_potion_scene)
		has_loot = true
	
	if damage_potion_scene and randf() <= damage_potion_chance:
		spawn_item(damage_potion_scene)
		has_loot = true

	# --- CATEGORIA 4: MONETE ---
	if coin_scene and randf() <= coin_chance:
		var amount = randi_range(min_coins, max_coins)
		for i in range(amount):
			spawn_item(coin_scene)
		has_loot = true
	
	# FEEDBACK ANIMAZIONE
	if has_loot:
		if $AnimatedSprite2D.sprite_frames.has_animation("open"):
			$AnimatedSprite2D.play("open")
	else:
		if $AnimatedSprite2D.sprite_frames.has_animation("empty"):
			$AnimatedSprite2D.play("empty")

func trigger_mimic():
	print("È UNA TRAPPOLA!")
	if $AnimatedSprite2D.sprite_frames.has_animation("mimic"):
		$AnimatedSprite2D.play("mimic")
	
	var bomb_amount = randi_range(2, 4)
	for i in range(bomb_amount):
		spawn_item(bomb_scene)

func spawn_item(scene_to_spawn):
	# VALIDAZIONE
	if scene_to_spawn == null:
		# Non stampiamo errore per gli scudi se non li hai assegnati, 
		# così puoi lasciare i campi vuoti se vuoi casse senza scudi.
		return

	var item = scene_to_spawn.instantiate()
	
	# Sparpagliamento casuale
	var random_offset = Vector2(randf_range(-30, 30), randf_range(20, 50))
	item.global_position = global_position + random_offset
	
	# Spinta fisica
	if item is RigidBody2D:
		item.linear_damp = 5
		var random_force = Vector2(randf_range(-0.5, 0.5), 1).normalized() * 30
		item.apply_impulse(random_force)
	
	if get_parent() == null:
		item.queue_free()
		return

	get_parent().call_deferred("add_child", item)
