extends Node2D

# Assicurati che il nome del nodo nella scena sia corretto!
@onready var hud = $HUD

func _ready():
	var player_instance = null
	
	# --- 1. DECIDIAMO CHI SPAWNARE ---
	if GameManager.selected_character_scene != null:
		player_instance = GameManager.selected_character_scene.instantiate()
	else:
		print("Nessun personaggio scelto, carico Knight di default.")
		player_instance = load("res://scenes/pg/cavaliere.tscn").instantiate()
	
	# --- 2. POSIZIONAMENTO ---
	if has_node("SpawnPoint"):
		player_instance.global_position = $SpawnPoint.global_position
	else:
		print("ATTENZIONE: Manca il nodo SpawnPoint! Metto il player a (0,0)")
		player_instance.global_position = Vector2.ZERO
	
	# --- 3. RICOLLEGAMENTO DEI SEGNALI ---
	# Qui colleghiamo tutto ciò che il player "grida" all'HUD che deve "ascoltare"
	
	# Vita, Monete, Bombe (Standard)
	player_instance.health_changed.connect(hud.update_life)
	player_instance.coins_changed.connect(hud.update_coins)
	player_instance.bombs_changed.connect(hud.update_bombs)
	
	# Armatura (Scudi)
	player_instance.armor_changed.connect(hud.update_armor)
	
	# Collegamento Timer Pozione
	if player_instance.has_signal("boost_updated"):
		player_instance.boost_updated.connect(hud._on_boost_updated)
	
	if player_instance.has_signal("speed_updated"):
		player_instance.speed_updated.connect(hud._on_speed_updated)
	
	# --- 4. AGGIUNGIAMO IL PLAYER AL MONDO ---
	add_child(player_instance)
	
	# --- 5. AGGIORNAMENTO HUD INIZIALE ---
	print("Inizializzo l'HUD...")
	
	# PROTEZIONE ANTI-CRASH: Controlliamo che max_health esista
	var max_hp = 6
	if "max_health" in player_instance:
		max_hp = player_instance.max_health
	
	# Impostiamo i cuori massimi
	if hud.has_method("init_max_hearts"):
		hud.init_max_hearts(max_hp)
	
	# Riempiamo i valori attuali
	hud.update_life(player_instance.health)
	hud.update_coins(player_instance.coins)
	hud.update_bombs(player_instance.bombs)
	hud.update_armor(player_instance.armor)
	
	# Nascondiamo la label del boost all'inizio
	if hud.has_method("_on_boost_updated"):
		hud._on_boost_updated(0)
