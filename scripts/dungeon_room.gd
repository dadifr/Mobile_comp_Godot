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
	# Contiamo SOLO i nodi che sono nel gruppo "enemies"
	var enemy_count = count_enemies()
	
	if enemy_count > 0:
		print("Battaglia Iniziata! Nemici: ", enemy_count)
		room_started = true
		close_all_doors()
		
		# --- NOVITÀ: SVEGLIA GLI SPAWNER ---
		# Cerchiamo dentro il nodo Enemies se c'è qualcuno che deve essere attivato
		for child in $Enemies.get_children():
			if child.has_method("activate_spawner"):
				child.activate_spawner()
		# -----------------------------------
		
	else:
		room_cleared = true

func _process(_delta):
	if room_started and !room_cleared:
		# Se il numero di VERI nemici scende a 0
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
		
		# --- CONTROLLO REALE ---
		# Se è vivo e fa parte del gruppo nemici:
		if child.is_in_group("enemies"):
			count += 1
			
	return count

func win_battle():
	print("Stanza pulita!")
	room_cleared = true
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
