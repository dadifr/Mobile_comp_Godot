extends Control

# --- RIFERIMENTI ---
@onready var volume_slider = $VBoxContainer/VolumeSlider
@onready var res_option = $VBoxContainer/ResOptionButton

# Percorsi delle scene
var game_scene_path = "res://scenes/character_selection.tscn"
var credits_scene_path = "res://scenes/credits.tscn" 

func _ready():
	# 1. SETUP AUDIO
	volume_slider.value = db_to_linear(OST.volume_db)
	
	# 2. SETUP RISOLUZIONE
	add_resolutions()
	
	# 3. COLLEGAMENTI SEGNALI
	volume_slider.value_changed.connect(_on_volume_changed)
	res_option.item_selected.connect(_on_resolution_selected)
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	
	# --- NUOVO: Colleghiamo il pulsante dei Titoli di Coda ---
	# Usiamo get_node_or_null così non crasha se dimentichi di creare il pulsante
	var credits_btn = $VBoxContainer.get_node_or_null("CreditsButton")
	if credits_btn:
		credits_btn.pressed.connect(_on_credits_pressed)

func add_resolutions():
	# --- FIX: Svuotiamo il menu per evitare doppioni dall'editor! ---
	res_option.clear()
	
	res_option.add_item("1920 x 1080 (Full HD)") # ID 0
	res_option.add_item("1280 x 720 (HD)")       # ID 1
	res_option.add_item("1152 x 648 (Default)")  # ID 2
	res_option.add_item("FullScreen (Schermo Intero)") # ID 3
	
	res_option.select(2)

func _on_volume_changed(value):
	OST.volume_db = linear_to_db(value)
	if value < 0.05:
		OST.volume_db = -80.0

func _on_resolution_selected(index):
	match index:
		0: # 1920x1080
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1920, 1080))
			center_window()
		1: # 1280x720
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1280, 720))
			center_window()
		2: # 1152x648
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1152, 648))
			center_window()
		3: # FullScreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func center_window():
	# --- FIX: Aspettiamo un millisecondo che il sistema operativo ridimensioni la finestra ---
	await get_tree().process_frame 
	
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_center - window_size / 2)

func _on_play_pressed():
	get_tree().change_scene_to_file(game_scene_path)

# --- NUOVA FUNZIONE: Apre la scena dei crediti ---
func _on_credits_pressed():
	get_tree().change_scene_to_file(credits_scene_path)
