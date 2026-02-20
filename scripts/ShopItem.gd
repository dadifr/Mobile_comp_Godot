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

# 2. VITA (Rossa)
@export var potion_scene: PackedScene
@export var potion_texture: Texture2D
@export var potion_price_range: Vector2i = Vector2i(10, 20)
@export_range(0.0, 1.0) var potion_chance: float = 0.15

@export var big_potion_scene: PackedScene
@export var big_potion_texture: Texture2D
@export var big_potion_price_range: Vector2i = Vector2i(25, 40)
@export_range(0.0, 1.0) var big_potion_chance: float = 0.08

# 3. SCUDI (Blu)
@export var shield_small_scene: PackedScene
@export var shield_small_texture: Texture2D
@export var shield_small_price_range: Vector2i = Vector2i(15, 25)
@export_range(0.0, 1.0) var shield_small_chance: float = 0.15

@export var shield_big_scene: PackedScene
@export var shield_big_texture: Texture2D
@export var shield_big_price_range: Vector2i = Vector2i(30, 50)
@export_range(0.0, 1.0) var shield_big_chance: float = 0.08

# 4. DANNO (Blu Scuro/Viola)
@export var damage_potion_scene: PackedScene
@export var damage_potion_texture: Texture2D
@export var damage_potion_price_range: Vector2i = Vector2i(40, 60)
@export_range(0.0, 1.0) var damage_potion_chance: float = 0.15

@export var big_damage_potion_scene: PackedScene
@export var big_damage_potion_texture: Texture2D
@export var big_damage_potion_price_range: Vector2i = Vector2i(80, 120)
@export_range(0.0, 1.0) var big_damage_potion_chance: float = 0.05

# 5. VELOCITÀ (Verde - NUOVO)
@export var speed_potion_scene: PackedScene
@export var speed_potion_texture: Texture2D
@export var speed_potion_price_range: Vector2i = Vector2i(30, 50)
@export_range(0.0, 1.0) var speed_potion_chance: float = 0.15

@export var big_speed_potion_scene: PackedScene
@export var big_speed_potion_texture: Texture2D
@export var big_speed_potion_price_range: Vector2i = Vector2i(60, 90)
@export_range(0.0, 1.0) var big_speed_potion_chance: float = 0.05

# Variabili interne
var player_in_range = null
var is_bought = false # Aggiunto per evitare doppi acquisti accidentali

# --- NUOVO: RIFERIMENTI AUDIO ---
@onready var sfx_buy = $SfxBuy
@onready var sfx_error = $SfxError

func _ready():
	if is_random_shop:
		randomize_shop_item()
	
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
	
	# Ordine di controllo (Accumuliamo le probabilità)
	
	# Bombe
	current_threshold += bomb_chance
	if roll < current_threshold: setup_item(bomb_scene, bomb_texture, bomb_price_range); return

	# Vita
	current_threshold += potion_chance
	if roll < current_threshold: setup_item(potion_scene, potion_texture, potion_price_range); return
	current_threshold += big_potion_chance
	if roll < current_threshold: setup_item(big_potion_scene, big_potion_texture, big_potion_price_range); return

	# Scudi
	current_threshold += shield_small_chance
	if roll < current_threshold: setup_item(shield_small_scene, shield_small_texture, shield_small_price_range); return
	current_threshold += shield_big_chance
	if roll < current_threshold: setup_item(shield_big_scene, shield_big_texture, shield_big_price_range); return

	# Danno
	current_threshold += damage_potion_chance
	if roll < current_threshold: setup_item(damage_potion_scene, damage_potion_texture, damage_potion_price_range); return
	current_threshold += big_damage_potion_chance
	if roll < current_threshold: setup_item(big_damage_potion_scene, big_damage_potion_texture, big_damage_potion_price_range); return

	# Velocità
	current_threshold += speed_potion_chance
	if roll < current_threshold: setup_item(speed_potion_scene, speed_potion_texture, speed_potion_price_range); return
	current_threshold += big_speed_potion_chance
	if roll < current_threshold: setup_item(big_speed_potion_scene, big_speed_potion_texture, big_speed_potion_price_range); return

	# FALLBACK (Se qualcosa va storto, vendiamo bombe)
	setup_item(bomb_scene, bomb_texture, bomb_price_range)


func setup_item(scene, texture, price_range):
	item_to_sell = scene
	item_texture = texture
	price = randi_range(price_range.x, price_range.y)

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not is_bought:
		try_to_buy()

func try_to_buy():
	if player_in_range.coins >= price:
		buy_success()
	else:
		buy_fail()

func buy_success():
	if item_to_sell == null: return
	
	is_bought = true

	player_in_range.coins -= price
	
	if player_in_range.has_signal("coins_changed"):
		player_in_range.coins_changed.emit(player_in_range.coins)
	elif player_in_range.has_method("update_coins"):
		player_in_range.update_coins(player_in_range.coins)
	
	var item = item_to_sell.instantiate()
	item.global_position = global_position
	get_parent().call_deferred("add_child", item)
	
	# --- GESTIONE AUDIO E DISTRUZIONE ---
	# Nascondiamo l'oggetto e disabilitiamo le collisioni
	hide()
	set_deferred("monitoring", false)
	
	if sfx_buy:
		sfx_buy.play()
		await sfx_buy.finished
		
	queue_free()

func buy_fail():
	if sfx_error:
		sfx_error.play()
		
	if has_node("Label"):
		var original_color = Color.WHITE
		$Label.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property($Label, "modulate", original_color, 0.5)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_bought:
		player_in_range = body
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
