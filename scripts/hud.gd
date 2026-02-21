extends CanvasLayer

# --- TEXTURE CONFIGURATION ---
@export_group("Shield Textures")
@export var shield_full: Texture2D
@export var shield_half: Texture2D
@onready var dash_bar = $DashBar

@export_group("Heart Textures")
@export var full_heart_texture: Texture2D
@export var half_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

# --- RIFERIMENTI AI NODI ---
@onready var shield_bar = $MarginContainer/StatsContainer/ShieldBar
@onready var coin_label = $MarginContainer/StatsContainer/CoinRow/CoinLabel
@onready var bomb_label = $MarginContainer/StatsContainer/BombRow/BombLabel

# Riferimenti alle Label Timer
@onready var boost_label = $MarginContainer/StatsContainer/BoostLabel 
@onready var speed_label = $MarginContainer/StatsContainer/SpeedLabel 
@onready var slow_label = $MarginContainer/StatsContainer/SlowLabel


# --- NUOVO: RIFERIMENTO AL NODO AUDIO DEL BUFF ---
@onready var sfx_buff = $SfxBuff

@onready var hearts = $MarginContainer/StatsContainer/HBoxContainer.get_children()

# Variabile per ricordare quanti cuori stiamo usando
var active_hearts_count = 0

# --- NUOVO: VARIABILI PER MEMORIZZARE LO STATO DEI BUFF ---
var was_boost_active = false
var was_speed_active = false

# --- INITIALIZZAZIONE (_READY) ---
func _ready():
	# 1. SETUP LABELS (Nascondiamo all'avvio)
	if boost_label: boost_label.visible = false
	if speed_label: speed_label.visible = false
	if slow_label: slow_label.visible = false
	# 2. SETUP DISTANZA SCUDI
	shield_bar.add_theme_constant_override("separation", -5)
	
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.slow_updated.connect(_on_slow_updated) 
		player.dash_cooldown_updated.connect(_on_dash_cooldown_updated)
	else:
		print("ERRORE: Player non trovato dall'HUD!")
	
	if not DisplayServer.is_touchscreen_available():
		var joystick = get_node_or_null("VirtualJoystick") 
		if joystick: joystick.visible = false


# --- FUNZIONI BOOST DANNO (BLU) ---
func _on_boost_updated(time_left):
	if boost_label == null: return
	
	if time_left > 0:
		# --- LOGICA DEL SUONO ---
		if not was_boost_active:
			was_boost_active = true
			if sfx_buff: sfx_buff.play() # Suona SOLO all'attivazione
			
		boost_label.visible = true
		boost_label.text = "DMG UP: " + str("%.1f" % time_left) + "s"
		
		# Logica Colore
		if time_left < 3.0:
			boost_label.modulate = Color(1, 0.3, 0.3) 
		else:
			boost_label.modulate = Color(0.5, 0.8, 1.0) 
	else:
		was_boost_active = false # Resettiamo la memoria quando finisce
		boost_label.visible = false

# --- FUNZIONI BOOST VELOCITÀ (VERDE) ---
func _on_speed_updated(time_left):
	if speed_label == null: return
	
	if time_left > 0:
		# --- LOGICA DEL SUONO ---
		if not was_speed_active:
			was_speed_active = true
			if sfx_buff: sfx_buff.play() # Suona SOLO all'attivazione
			
		speed_label.visible = true
		speed_label.text = "SPD UP: " + str("%.1f" % time_left) + "s"
		
		if time_left < 3.0:
			speed_label.modulate = Color(1, 0.3, 0.3) 
		else:
			speed_label.modulate = Color(0.5, 1.0, 0.5) 
	else:
		was_speed_active = false # Resettiamo la memoria quando finisce
		speed_label.visible = false

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
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shield_bar.add_child(icon)

# --- FUNZIONI AGGIORNAMENTO VITA ---
func init_max_hearts(max_hp):
	if max_hp == null:
		max_hp = 6
	
	var hearts_needed = max_hp / 2
	active_hearts_count = hearts_needed
	
	for i in range(hearts.size()):
		if i < hearts_needed:
			hearts[i].show()
		else:
			hearts[i].hide()

func update_life(amount):
	if amount == null: amount = 0
	
	if active_hearts_count == 0 and hearts.size() > 0:
		active_hearts_count = 3
		
	for i in range(active_hearts_count):
		if i >= hearts.size(): break
			
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

# --- AGGIORNAMENTO MONETE E BOMBE ---
func update_coins(amount):
	coin_label.text = "x " + str(amount)

func update_bombs(amount):
	bomb_label.text = "x " + str(amount)
func _on_slow_updated(time_left):
	if slow_label == null: return
	
	if time_left > 0:
		slow_label.visible = true
		# Arrotondiamo a 1 decimale
		slow_label.text = "SLOWED: " + str("%.1f" % time_left) + "s"
		
		# Logica Colore: diventa rosso se sta per finire
		if time_left < 2.0:
			slow_label.modulate = Color(1, 0.3, 0.3) # Rosso
		else:
			slow_label.modulate = Color(0.8, 0.5, 1.0) # Viola/Bluastro
	else:
		slow_label.visible = false
		
func _on_dash_cooldown_updated(percentuale):
	if dash_bar:
		dash_bar.value = percentuale
		if percentuale >= 100:
			dash_bar.modulate = Color(1, 1, 1) # Pronta!
		else:
			dash_bar.modulate = Color(0.5, 0.5, 0.5) # In ricarica...
