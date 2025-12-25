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
@export_range(0.0, 1.0) var bomb_chance: float = 0.15

# 2. VITA PICCOLA
@export var potion_scene: PackedScene
@export var potion_texture: Texture2D
@export var potion_price_range: Vector2i = Vector2i(10, 20)
@export_range(0.0, 1.0) var potion_chance: float = 0.15

# 3. VITA GRANDE
@export var big_potion_scene: PackedScene
@export var big_potion_texture: Texture2D
@export var big_potion_price_range: Vector2i = Vector2i(25, 40)
@export_range(0.0, 1.0) var big_potion_chance: float = 0.10

# 4. SCUDO PICCOLO
@export var shield_small_scene: PackedScene
@export var shield_small_texture: Texture2D
@export var shield_small_price_range: Vector2i = Vector2i(15, 25)
@export_range(0.0, 1.0) var shield_small_chance: float = 0.15

# 5. SCUDO GRANDE
@export var shield_big_scene: PackedScene
@export var shield_big_texture: Texture2D
@export var shield_big_price_range: Vector2i = Vector2i(30, 50)
@export_range(0.0, 1.0) var shield_big_chance: float = 0.15

# 6. POZIONE DANNO (PICCOLA)
@export var damage_potion_scene: PackedScene
@export var damage_potion_texture: Texture2D
@export var damage_potion_price_range: Vector2i = Vector2i(40, 60)
@export_range(0.0, 1.0) var damage_potion_chance: float = 0.20

# 7. POZIONE DANNO GRANDE (NUOVA!)
@export var big_damage_potion_scene: PackedScene
@export var big_damage_potion_texture: Texture2D
@export var big_damage_potion_price_range: Vector2i = Vector2i(80, 120) # Molto costosa!
@export_range(0.0, 1.0) var big_damage_potion_chance: float = 0.10 # Molto rara

# Variabili interne
var player_in_range = null

func _ready():
	if is_random_shop:
		randomize_shop_item()
	
	# --- AGGIORNAMENTO VISIVO ---
	if item_texture:
		$Sprite2D.texture = item_texture
		$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if has_node("Label"):
		$Label.text = str(price) + "$"
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func randomize_shop_item():
	var roll = randf()
	var current_threshold = 0.0
	
	# 1. Bombe
	current_threshold += bomb_chance
	if roll < current_threshold:
		setup_item(bomb_scene, bomb_texture, bomb_price_range)
		return

	# 2. Vita Piccola
	current_threshold += potion_chance
	if roll < current_threshold:
		setup_item(potion_scene, potion_texture, potion_price_range)
		return

	# 3. Vita Grande
	current_threshold += big_potion_chance
	if roll < current_threshold:
		setup_item(big_potion_scene, big_potion_texture, big_potion_price_range)
		return

	# 4. Scudo Piccolo
	current_threshold += shield_small_chance
	if roll < current_threshold:
		setup_item(shield_small_scene, shield_small_texture, shield_small_price_range)
		return

	# 5. Scudo Grande
	current_threshold += shield_big_chance
	if roll < current_threshold:
		setup_item(shield_big_scene, shield_big_texture, shield_big_price_range)
		return

	# 6. Pozione Danno Piccola
	current_threshold += damage_potion_chance
	if roll < current_threshold:
		setup_item(damage_potion_scene, damage_potion_texture, damage_potion_price_range)
		return

	# 7. Pozione Danno Grande (NUOVA)
	current_threshold += big_damage_potion_chance
	if roll < current_threshold:
		setup_item(big_damage_potion_scene, big_damage_potion_texture, big_damage_potion_price_range)
		return

	# FALLBACK
	setup_item(bomb_scene, bomb_texture, bomb_price_range)


func setup_item(scene, texture, price_range):
	item_to_sell = scene
	item_texture = texture
	price = randi_range(price_range.x, price_range.y)

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		try_to_buy()

func try_to_buy():
	if player_in_range.coins >= price:
		buy_success()
	else:
		buy_fail()

func buy_success():
	if item_to_sell == null: return

	player_in_range.coins -= price
	
	# Aggiorna monete (usa i segnali o metodi del player)
	if player_in_range.has_signal("coins_changed"):
		player_in_range.coins_changed.emit(player_in_range.coins)
	elif player_in_range.has_method("update_coins"):
		player_in_range.update_coins(player_in_range.coins)
	
	var item = item_to_sell.instantiate()
	item.global_position = global_position
	get_parent().call_deferred("add_child", item)
	
	queue_free()

func buy_fail():
	if has_node("Label"):
		var original_color = Color.WHITE
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
