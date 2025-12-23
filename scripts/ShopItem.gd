extends Area2D

# --- MODALITÀ ---
@export var is_random_shop: bool = false # Se VERO, il negozio sceglie a caso cosa vendere

# --- VARIABILI FISSE (Usate se is_random_shop è FALSE) ---
@export_group("Manual Settings")
@export var item_to_sell: PackedScene # La scena da spawnare
@export var price: int = 10           # Il prezzo
@export var item_texture: Texture2D   # L'immagine da mostrare

# --- CONFIGURAZIONE CASUALE (Usate se is_random_shop è TRUE) ---
@export_group("Random Pool Settings")

# 1. BOMBE (Munizioni)
@export var bomb_scene: PackedScene
@export var bomb_texture: Texture2D
@export var bomb_price_range: Vector2i = Vector2i(5, 10)
@export_range(0.0, 1.0) var bomb_chance: float = 0.5 # 50% Probabilità

# 2. POZIONI (Cura Piccola)
@export var potion_scene: PackedScene
@export var potion_texture: Texture2D
@export var potion_price_range: Vector2i = Vector2i(10, 20)
@export_range(0.0, 1.0) var potion_chance: float = 0.3 # 30% Probabilità

# 3. BIG POZIONI (Cura Grande - Rara)
# Nota: Questa prende automaticamente la probabilità rimanente (es. 20%)
@export var big_potion_scene: PackedScene
@export var big_potion_texture: Texture2D
@export var big_potion_price_range: Vector2i = Vector2i(25, 40)
@export_range(0.0, 1.0) var big_potion_chance: float = 0.2

# Variabili interne
var player_in_range = null


func _ready():
	# Se è un negozio random, calcoliamo ora cosa vendere
	if is_random_shop:
		randomize_shop_item()
	
	# --- AGGIORNAMENTO VISIVO ---
	# Impostiamo l'immagine dell'oggetto
	if item_texture:
		$Sprite2D.texture = item_texture
	
	# Impostiamo il prezzo sulla Label
	if has_node("Label"):
		$Label.text = str(price) + "$"
	
	# Colleghiamo i segnali di collisione
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func randomize_shop_item():
	var roll = randf() # Genera un numero tra 0.0 e 1.0
	
	# LOGICA DI PROBABILITÀ CUMULATIVA
	
	# 1. Tentativo Bomba (0.0 -> bomb_chance)
	if roll < bomb_chance:
		setup_item(bomb_scene, bomb_texture, bomb_price_range)
		
	# 2. Tentativo Pozione (bomb_chance -> bomb_chance + potion_chance)
	elif roll < (bomb_chance + potion_chance):
		setup_item(potion_scene, potion_texture, potion_price_range)
		
	# 3. Altrimenti... Pozione Grande (il resto della torta)
	else:
		setup_item(big_potion_scene, big_potion_texture, big_potion_price_range)


# Funzione "Helper" per evitare di riscrivere il codice 3 volte
func setup_item(scene, texture, price_range):
	item_to_sell = scene
	item_texture = texture
	# Sceglie un prezzo a caso tra il minimo (x) e il massimo (y)
	price = randi_range(price_range.x, price_range.y)


func _process(delta):
	# Controlliamo se il giocatore è vicino e preme il tasto F (o quello che hai scelto)
	if player_in_range and Input.is_action_just_pressed("interact"):
		try_to_buy()


func try_to_buy():
	# Controlliamo se il giocatore ha i soldi (assumiamo la variabile 'coins')
	if player_in_range.coins >= price:
		buy_success()
	else:
		buy_fail()


func buy_success():
	print("Oggetto acquistato per ", price, " monete!")
	
	# 1. Togli i soldi
	player_in_range.coins -= price
	
	# 2. Aggiorna l'HUD del giocatore (segnale)
	if player_in_range.has_signal("coins_changed"):
		player_in_range.coins_changed.emit(player_in_range.coins)
	
	# 3. Spawna l'oggetto vero e proprio nel mondo
	if item_to_sell:
		var item = item_to_sell.instantiate()
		item.global_position = global_position
		get_parent().call_deferred("add_child", item)
	
	# 4. Elimina l'espositore (venduto!)
	queue_free()


func buy_fail():
	print("Soldi insufficienti!")
	
	# Feedback Visivo: La scritta diventa ROSSA
	if has_node("Label"):
		var original_color = $Label.modulate
		$Label.modulate = Color.RED
		
		# Torna normale dopo 0.5 secondi
		var tween = create_tween()
		tween.tween_property($Label, "modulate", original_color, 0.5)


# --- GESTIONE RILEVAMENTO GIOCATORE ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		# Effetto visivo "Pop" (Ingrandisce leggermente)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		# Torna alla dimensione normale
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
