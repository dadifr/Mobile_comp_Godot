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

@onready var hearts = $MarginContainer/StatsContainer/HBoxContainer.get_children()

# Variabile per ricordare quanti cuori stiamo usando (es. Cavaliere = 3)
var active_hearts_count = 0 

# --- FUNZIONI AGGIORNAMENTO ---

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
	
	# Dimensione aumentata
	icon.custom_minimum_size = Vector2(48, 48) 
	
	# --- CORREZIONE ALLINEAMENTO ---
	# Questo dice all'icona: "Non stare in alto, mettiti al centro verticale della riga"
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	# -------------------------------
	
	shield_bar.add_child(icon)


# --- QUI È LA CORREZIONE IMPORTANTE ---
func init_max_hearts(max_hp):
	var hearts_needed = max_hp / 2
	
	# Memorizziamo quanti cuori sono attivi
	active_hearts_count = hearts_needed
	
	for i in range(hearts.size()):
		if i < hearts_needed:
			hearts[i].show()
		else:
			hearts[i].hide()

func update_life(amount):
	# Invece di range(hearts.size()), usiamo active_hearts_count!
	# Così aggiorniamo solo i primi 3 cuori e ignoriamo il 4° e il 5°.
	for i in range(active_hearts_count):
		var heart_value = (i + 1) * 2  
		
		if amount >= heart_value:
			hearts[i].texture = full_heart_texture
		elif amount == heart_value - 1:
			hearts[i].texture = half_heart_texture
		else:
			hearts[i].texture = empty_heart_texture
		
		# Assicuriamoci che questi siano visibili (nel caso fossero stati nascosti per errore)
		hearts[i].visible = true

	# SICUREZZA EXTRA:
	# Assicuriamoci che tutti i cuori OLTRE il limite rimangano nascosti
	for i in range(active_hearts_count, hearts.size()):
		hearts[i].visible = false

# --- AGGIORNAMENTO ETICHETTE ---
func update_coins(amount):
	coin_label.text = "x " + str(amount)

func update_bombs(amount):
	bomb_label.text = "x " + str(amount)
