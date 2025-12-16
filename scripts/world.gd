extends Node2D

@onready var hud = $HUD # Assicurati che il nodo nella scena si chiami "HUD"

func _ready():
	var player_instance = null
	
	# 1. Decidiamo chi spawnare
	if GameManager.selected_character_scene != null:
		player_instance = GameManager.selected_character_scene.instantiate()
	else:
		# Fallback per i test se avvii direttamente World
		print("Nessun personaggio scelto, carico Knight di default.")
		player_instance = load("res://scenes/cavaliere.tscn").instantiate()
	
	# 2. Posizionamento
	player_instance.global_position = $SpawnPoint.global_position
	
	# --- 3. RICOLLEGAMENTO DEI SEGNALI (LA PARTE FONDAMENTALE) ---
	# Qui colleghiamo i "fili" via codice tra il NUOVO player e il VECCHIO HUD
	
	# Segnale VITA -> Funzione update_hearts (o come l'hai chiamata tu nell'HUD)
	# Nota: Controlla in HUD.gd come si chiama la funzione per i cuori. 
	# Se si chiama "_on_player_health_changed", scrivi quella.
	# Se si chiama "update_hearts", scrivi quella.
	player_instance.health_changed.connect(hud.update_life) 
	
	# Segnale MONETE -> Funzione update_coins
	player_instance.coins_changed.connect(hud.update_coins)
	
	# Segnale BOMBE -> Funzione update_bombs
	player_instance.bombs_changed.connect(hud.update_bombs)
	
	# 4. Aggiungi finalmente il player al mondo
	add_child(player_instance)
	
	# --- AGGIORNAMENTO INIZIALE FORZATO ---
	print("Aggiorno HUD iniziale...")
	
	# 1. NUOVO: Impostiamo il numero di cuori VISIBILI in base alla vita massima
	hud.init_max_hearts(player_instance.max_health)
	
	# 2. Riempiamo i cuori in base alla vita attuale
	hud.update_life(player_instance.health)
	
	# 3. Aggiorniamo il resto
	hud.update_coins(player_instance.coins)
	hud.update_bombs(player_instance.bombs)
