extends Area2D

# --- MODALITÀ ---
@export var is_random_shop: bool = false 

# --- VARIABILI FISSE ---
@export_group("Manual Settings")
@export var item_to_sell: PackedScene 
@export var price: int = 10           
@export var item_texture: Texture2D   

# --- CONFIGURAZIONE CASUALE ---
@export_group("Random Pool Settings")

# 1. BOMBE
@export var bomb_scene: PackedScene
@export var bomb_texture: Texture2D
@export var bomb_price_range: Vector2i = Vector2i(5, 10)
@export_range(0.0, 1.0) var bomb_chance: float = 0.25

# 2. VITA PICCOLA (Rossa)
@export var potion_scene: PackedScene
@export var potion_texture: Texture2D
@export var potion_price_range: Vector2i = Vector2i(10, 20)
@export_range(0.0, 1.0) var potion_chance: float = 0.20

# 3. VITA GRANDE (Rossa Grande)
@export var big_potion_scene: PackedScene
@export var big_potion_texture: Texture2D
@export var big_potion_price_range: Vector2i = Vector2i(25, 40)
@export_range(0.0, 1.0) var big_potion_chance: float = 0.10

# 4. SCUDO PICCOLO (Gialla/Blu)
@export var shield_small_scene: PackedScene
@export var shield_small_texture: Texture2D
@export var shield_small_price_range: Vector2i = Vector2i(15, 25)
@export_range(0.0, 1.0) var shield_small_chance: float = 0.25

# 5. SCUDO GRANDE (Gialla/Blu Grande)
@export var shield_big_scene: PackedScene
@export var shield_big_texture: Texture2D
@export var shield_big_price_range: Vector2i = Vector2i(30, 50)
@export_range(0.0, 1.0) var shield_big_chance: float = 0.20

# Variabili interne
var player_in_range = null

func _ready():
	print("--- INIZIO DEBUG NEGOZIO ---")
	
	if is_random_shop:
		print("Modalità Random ATTIVA. Calcolo oggetto...")
		randomize_shop_item()
	else:
		print("Modalità Random DISATTIVA. Uso oggetto manuale.")
	
	# --- AGGIORNAMENTO VISIVO ---
	if item_texture:
		$Sprite2D.texture = item_texture
		print("Texture aggiornata con successo.")
	else:
		print("ERRORE: Nessuna texture trovata per l'oggetto scelto!")
	
	if has_node("Label"):
		$Label.text = str(price) + "$"
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("Prezzo finale: ", price)
	print("Oggetto da spawnare: ", item_to_sell)
	print("--- FINE DEBUG NEGOZIO ---")


func randomize_shop_item():
	var roll = randf()
	var current_threshold = 0.0
	
	print("Numero Random (Roll): ", roll)
	
	# 1. Bombe
	current_threshold += bomb_chance
	if roll < current_threshold:
		print("Scelto: BOMBE")
		setup_item(bomb_scene, bomb_texture, bomb_price_range)
		return

	# 2. Vita Piccola
	current_threshold += potion_chance
	if roll < current_threshold:
		print("Scelto: POZIONE VITA PICCOLA")
		setup_item(potion_scene, potion_texture, potion_price_range)
		return

	# 3. Vita Grande
	current_threshold += big_potion_chance
	if roll < current_threshold:
		print("Scelto: POZIONE VITA GRANDE")
		setup_item(big_potion_scene, big_potion_texture, big_potion_price_range)
		return

	# 4. Scudo Piccolo
	current_threshold += shield_small_chance
	if roll < current_threshold:
		print("Scelto: POZIONE SCUDO PICCOLA")
		setup_item(shield_small_scene, shield_small_texture, shield_small_price_range)
		return

	# 5. Scudo Grande
	print("Scelto: POZIONE SCUDO GRANDE (Fallback)")
	setup_item(shield_big_scene, shield_big_texture, shield_big_price_range)


func setup_item(scene, texture, price_range):
	item_to_sell = scene
	item_texture = texture
	price = randi_range(price_range.x, price_range.y)
	
	# CONTROLLO DI SICUREZZA
	if item_to_sell == null:
		print("ATTENZIONE: La scena (tscn) per questo oggetto NON è stata assegnata nell'Inspector!")
	if item_texture == null:
		print("ATTENZIONE: L'immagine (texture) per questo oggetto NON è stata assegnata nell'Inspector!")


func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		try_to_buy()

func try_to_buy():
	if player_in_range.coins >= price:
		buy_success()
	else:
		buy_fail()

func buy_success():
	print("Tento l'acquisto...")
	if item_to_sell == null:
		print("ERRORE CRITICO: Non posso venderti nulla perché 'item_to_sell' è vuoto!")
		return

	player_in_range.coins -= price
	if player_in_range.has_signal("coins_changed"):
		player_in_range.coins_changed.emit(player_in_range.coins)
	
	var item = item_to_sell.instantiate()
	item.global_position = global_position
	get_parent().call_deferred("add_child", item)
	
	print("Oggetto spawnato. Chiudo il negozio.")
	queue_free()

func buy_fail():
	print("Soldi insufficienti!")
	if has_node("Label"):
		var original_color = $Label.modulate
		$Label.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property($Label, "modulate", original_color, 0.5)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
