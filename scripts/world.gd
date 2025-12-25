extends Node2D

# Assicurati che il nome del nodo nella scena sia corretto!
# Se il nodo CanvasLayer si chiama "CanvasLayer", scrivi $CanvasLayer
# Se lo hai rinominato "HUD", scrivi $HUD
@onready var hud = $HUD

func _ready():
	var player_instance = null
	# --- 1. DECIDIAMO CHI SPAWNARE ---
	if GameManager.selected_character_scene != null:
		player_instance = GameManager.selected_character_scene.instantiate()
	else:
		# Fallback per i test se avvii direttamente World senza passare dal menu
		print("Nessun personaggio scelto, carico Knight di default.")
		# Assicurati che il percorso del cavaliere sia giusto
		player_instance = load("res://scenes/cavaliere.tscn").instantiate()
	
	# --- 2. POSIZIONAMENTO ---
	if has_node("SpawnPoint"):
		player_instance.global_position = $SpawnPoint.global_position
	else:
		print("ATTENZIONE: Manca il nodo SpawnPoint nel Mondo! Metto il player a (0,0)")
		player_instance.global_position = Vector2.ZERO
	
	# --- 3. RICOLLEGAMENTO DEI SEGNALI ---
	# Colleghiamo i segnali del player APPENA CREATO alle funzioni dell'HUD
	
	# Vita, Monete, Bombe (Già esistenti)
	player_instance.health_changed.connect(hud.update_life)
	player_instance.coins_changed.connect(hud.update_coins)
	player_instance.bombs_changed.connect(hud.update_bombs)
	
	# ### NUOVO ### Collegamento Armatura
	player_instance.armor_changed.connect(hud.update_armor)
	
	# --- 4. AGGIUNGIAMO IL PLAYER AL MONDO ---
	# Nota: È meglio collegare i segnali PRIMA di add_child, per sicurezza.
	add_child(player_instance)
	
	# --- 5. AGGIORNAMENTO HUD INIZIALE ---
	print("Inizializzo l'HUD...")
	
	# Impostiamo quanti cuori massimi disegnare
	hud.init_max_hearts(player_instance.max_health)
	
	# Riempiamo i valori attuali
	hud.update_life(player_instance.health)
	hud.update_coins(player_instance.coins)
	hud.update_bombs(player_instance.bombs)
	
	# ### NUOVO ### Aggiorniamo gli scudi iniziali (che saranno 0, ma pulisce la barra)
	hud.update_armor(player_instance.armor)
