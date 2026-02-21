extends Node2D

var room_started = false
var room_cleared = false

func _ready():
	# Colleghiamo il rilevatore di ingresso
	$Detector.body_entered.connect(_on_player_entered)
	
	# Assicuriamoci che le porte siano aperte all'inizio
	open_all_doors()

func _on_player_entered(body):
	# Se la stanza è già stata pulita o la battaglia è già iniziata, ignoriamo
	if room_cleared or room_started:
		return
	
	if body.is_in_group("player"):
		start_battle()

func start_battle():
	var enemy_count = count_enemies()

	if enemy_count > 0:
		print("Battaglia Iniziata! Nemici: ", enemy_count)
		room_started = true
		close_all_doors()

		var is_boss_room = false # Variabile per capire se c'è un boss

		# Esploriamo i nemici per svegliarli e capire se c'è un boss
		for child in $Enemies.get_children():
			if is_instance_valid(child):
				# Se è nel gruppo "boss" o ha la funzione specifica
				if child.is_in_group("boss") or child.has_method("activate_boss"):
					if child.has_method("activate_boss"):
						child.activate_boss()
					is_boss_room = true # Abbiamo trovato un boss!
				elif child.has_method("activate"):
					child.activate()

		# --- GESTIONE MUSICA ---
		if is_boss_room:
			print("Suona la musica del Boss!")
			# Visto che hai l'Autoload OST, puoi usare:
			# OST.play_boss_theme()
		else:
			print("Suona la musica da combattimento normale.")
			# OST.play_normal_theme() o la tua musica da battaglia
			
	else:
		room_cleared = true

func _process(_delta):
	if room_started and !room_cleared:
		if count_enemies() == 0:
			win_battle()

# Funzione personalizzata per contare solo i nemici
func count_enemies():
	var count = 0
	
	# Esploriamo tutti i figli del nodo Enemies
	for child in $Enemies.get_children():
		
		# --- SICUREZZA 1: Esiste ancora in memoria? ---
		if not is_instance_valid(child):
			continue
			
		# --- SICUREZZA 2: Sta morendo? ---
		if child.is_queued_for_deletion():
			continue
		
		# --- CONTROLLO REALE MODIFICATO ---
		# Ora conta sia i nodi nel gruppo "enemies" che in un eventuale gruppo "boss"
		if child.is_in_group("enemies") or child.is_in_group("boss"):
			count += 1
			
	return count

func win_battle():
	print("Stanza pulita!")
	room_cleared = true
	room_started = false # Ottimizzazione: blocca l'esecuzione inutile in _process
	open_all_doors()
	# Qui potresti far apparire una Chest premio al centro della stanza!

# --- Funzioni Helper per le porte ---
func close_all_doors():
	# Cerca tutte le porte dentro il nodo "Doors" e le chiude
	for door in $Doors.get_children():
		if door.has_method("close"):
			door.close()

func open_all_doors():
	for door in $Doors.get_children():
		if door.has_method("open"):
			door.open()
