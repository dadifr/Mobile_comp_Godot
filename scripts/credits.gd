extends Control

@export_group("Impostazioni Crediti")
@export var scroll_speed = 60.0 # Velocità di scorrimento del testo
@export var menu_scene_path = "res://scenes/SettingsMenu.tscn"

@onready var testo = $TestoCrediti
@onready var back_button = $BackButton

func _ready():
	# Colleghiamo il pulsante via codice (così non devi farlo tu dall'Editor!)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Trucco: Facciamo partire il testo fuori dallo schermo (in basso)
	# così fa l'effetto "entrata dal basso" tipico del cinema
	if testo:
		var altezza_schermo = get_viewport_rect().size.y
		testo.position.y = altezza_schermo

func _process(delta):
	# Fa scorrere il testo verso l'alto
	if testo:
		testo.position.y -= scroll_speed * delta

# Permette di uscire anche premendo il tasto "UI_CANCEL" (di solito ESC)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		ritorna_al_menu()

func _on_back_button_pressed():
	ritorna_al_menu()

func ritorna_al_menu():
	# Fermiamo tutto e torniamo alla scena principale
	print("Uscita dai crediti. Ritorno al menu...")
	get_tree().change_scene_to_file(menu_scene_path)
