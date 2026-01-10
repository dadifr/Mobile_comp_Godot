extends Control

# --- RIFERIMENTI ---
@onready var volume_slider = $VBoxContainer/VolumeSlider
@onready var res_option = $VBoxContainer/ResOptionButton

# Percorso del gioco vero e proprio
var game_scene_path = "res://scenes/character_selection.tscn"

# Indice del Bus Audio "Master" (il volume principale)
var master_bus_index

func _ready():
	# 1. SETUP AUDIO
	master_bus_index = AudioServer.get_bus_index("Master")
	# Impostiamo lo slider al volume attuale
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	
	# 2. SETUP RISOLUZIONE
	add_resolutions()
	
	# 3. COLLEGAMENTI SEGNALI
	volume_slider.value_changed.connect(_on_volume_changed)
	res_option.item_selected.connect(_on_resolution_selected)
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)

func add_resolutions():
	# Aggiungiamo le opzioni al menu a tendina
	res_option.add_item("1920 x 1080 (Full HD)") # ID 0
	res_option.add_item("1280 x 720 (HD)")       # ID 1
	res_option.add_item("1152 x 648 (Default)")  # ID 2
	res_option.add_item("FullScreen (Schermo Intero)") # ID 3
	
	# Selezioniamo di default la 1152x648 (o quella che preferisci)
	res_option.select(2)

func _on_volume_changed(value):
	# Convertiamo il valore lineare (0 a 1) in Decibel per Godot
	# Se lo slider è a 0, mettiamo "Mute"
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus_index, value < 0.05)

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
	# Centra la finestra nello schermo del monitor
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_center - window_size / 2)

func _on_play_pressed():
	# Avvia il gioco!
	get_tree().change_scene_to_file(game_scene_path)
