extends Control

# --- RIFERIMENTI AI NODI ---
@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var status_label = $VBoxContainer/StatusLabel

# --- PERCORSO DEL FILE DI SALVATAGGIO ---
# "user://" è una cartella sicura creata da Godot sul PC del giocatore
var save_path = "user://user_data.save"

# Un dizionario per tenere in memoria tutti gli utenti registrati
# Formato: { "Mario": "1234", "Luigi": "segreto" }
var user_database = {}


var game_scene_path = "res://scenes/SettingsMenu.tscn" 

func _ready():
	# 1. Carichiamo i dati esistenti appena si apre il gioco
	load_data()
	
	# 2. Colleghiamo i segnali dei pulsanti
	$VBoxContainer/LoginButton.pressed.connect(_on_login_pressed)
	$VBoxContainer/RegisterButton.pressed.connect(_on_register_pressed)

func _on_register_pressed():
	var user = username_input.text
	var passw = password_input.text
	
	# Validazione base
	if user == "" or passw == "":
		status_label.text = "Errore: Campi vuoti!"
		status_label.modulate = Color.RED
		return
	
	# Controlliamo se l'utente esiste già
	if user_database.has(user):
		status_label.text = "Errore: Utente già esistente!"
		status_label.modulate = Color.RED
		return
	
	# REGISTRAZIONE
	user_database[user] = passw # Salviamo nel dizionario
	save_data() # Scriviamo su file
	
	status_label.text = "Registrazione completata! Ora fai Login."
	status_label.modulate = Color.GREEN
	
	# Puliamo i campi
	username_input.text = ""
	password_input.text = ""

func _on_login_pressed():
	var user = username_input.text
	var passw = password_input.text
	
	# Controlliamo se l'utente esiste
	if not user_database.has(user):
		status_label.text = "Errore: Utente non trovato!"
		status_label.modulate = Color.RED
		return
	
	# Controlliamo la password
	if user_database[user] == passw:
		status_label.text = "Login Riuscito! Caricamento..."
		status_label.modulate = Color.GREEN
		
		# --- TRANSIZIONE AL GIOCO ---
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(game_scene_path)
		
	else:
		status_label.text = "Errore: Password Sbagliata!"
		status_label.modulate = Color.RED

# --- GESTIONE SALVATAGGIO SU DISCO ---

func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(user_database)
	file.close()
	print("Database salvato.")

func load_data():
	if not FileAccess.file_exists(save_path):
		print("Nessun salvataggio trovato, database vuoto.")
		return # Nessun file da caricare
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	user_database = file.get_var()
	file.close()
	print("Database caricato: ", user_database)
