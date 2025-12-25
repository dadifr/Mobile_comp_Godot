extends CanvasLayer

# --- TEXTURE CONFIGURATION ---
@export_group("Shield Textures")
@export var shield_full: Texture2D
@export var shield_half: Texture2D

@export_group("Heart Textures")
@export var full_heart_texture: Texture2D
@export var half_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

# --- RIFERIMENTI AI NODI ---
@onready var shield_bar = $MarginContainer/StatsContainer/ShieldBar
@onready var coin_label = $MarginContainer/StatsContainer/CoinRow/CoinLabel
@onready var bomb_label = $MarginContainer/StatsContainer/BombRow/BombLabel

# ### NUOVO ### Riferimento all'etichetta del Boost
# Assicurati di creare una Label chiamata "BoostLabel" dentro StatsContainer (o dove preferisci)
@onready var boost_label = $MarginContainer/StatsContainer/BoostLabel 

@onready var hearts = $MarginContainer/StatsContainer/HBoxContainer.get_children()

# Variabile per ricordare quanti cuori stiamo usando
var active_hearts_count = 0 

# --- INITIALIZZAZIONE (_READY) ---
func _ready():
	# 1. SETUP BOOST LABEL
	if boost_label:
		boost_label.visible = false # Nascondiamo all'avvio
	
	# 2. COLLEGA IL PLAYER (Per il timer pozione)
	# Cerca il nodo Player nel gruppo "player"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Colleghiamo il segnale "boost_updated" che abbiamo creato nel Player
		if player.has_signal("boost_updated"):
			player.boost_updated.connect(_on_boost_updated)
		else:
			print("ATTENZIONE: Il Player non ha il segnale 'boost_updated'. Controlla lo script Player.")
	
	# 3. SETUP DISTANZA SCUDI
	# Questo risolve il problema dello spazio tra gli scudi grandi.
	# -5 li avvicina. Modifica questo numero se li vuoi più vicini/lontani.
	shield_bar.add_theme_constant_override("separation", -5)

# --- FUNZIONI BOOST POZIONE ---
func _on_boost_updated(time_left):
	if boost_label == null: return
	
	if time_left > 0:
		boost_label.visible = true
		# Mostra il testo es: "DMG UP: 4.5s"
		boost_label.text = "DMG UP: " + str("%.1f" % time_left) + "s"
		# Opzionale: Cambia colore se sta per finire
		if time_left < 3.0:
			boost_label.modulate = Color(1, 0, 0) # Rosso
		else:
			boost_label.modulate = Color(1, 1, 1) # Bianco
	else:
		boost_label.visible = false

# --- FUNZIONI AGGIORNAMENTO ARMATURA ---

func update_armor(amount):
	for child in shield_bar.get_children():
		child.queue_free()
	
	var full_count = amount / 2       
	var has_half = (amount % 2) != 0 
	
	for i in range(full_count):
		add_icon(shield_full)
		
	if has_half:
		add_icon(shield_half)

func add_icon(texture):
	var icon = TextureRect.new()
	icon.texture = texture
	
	# Mantiene i pixel nitidi
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
	
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Dimensione aumentata (Scudi grandi)
	icon.custom_minimum_size = Vector2(48, 48) 
	
	# Allineamento Verticale (Centrato)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	
	shield_bar.add_child(icon)

# --- FUNZIONI AGGIORNAMENTO VITA ---

func init_max_hearts(max_hp):
	var hearts_needed = max_hp / 2
	active_hearts_count = hearts_needed
	
	for i in range(hearts.size()):
		if i < hearts_needed:
			hearts[i].show()
		else:
			hearts[i].hide()

func update_life(amount):
	for i in range(active_hearts_count):
		var heart_value = (i + 1) * 2  
		
		if amount >= heart_value:
			hearts[i].texture = full_heart_texture
		elif amount == heart_value - 1:
			hearts[i].texture = half_heart_texture
		else:
			hearts[i].texture = empty_heart_texture
		
		hearts[i].visible = true

	for i in range(active_hearts_count, hearts.size()):
		hearts[i].visible = false

# --- AGGIORNAMENTO ETICHETTE ---
func update_coins(amount):
	coin_label.text = "x " + str(amount)

func update_bombs(amount):
	bomb_label.text = "x " + str(amount)
