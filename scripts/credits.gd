extends Control

@export_group("Impostazioni Crediti")
@export var scroll_speed = 60.0 
@export var menu_scene_path = "res://scenes/SettingsMenu.tscn"

@onready var testo = $TestoCrediti
@onready var back_button = $BackButton

func _ready():
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	if testo:
		var altezza_schermo = get_viewport_rect().size.y
		testo.position.y = altezza_schermo

func _process(delta):
	
	if testo:
		testo.position.y -= scroll_speed * delta


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		ritorna_al_menu()

func _on_back_button_pressed():
	ritorna_al_menu()

func ritorna_al_menu():
	
	print("Uscita dai crediti. Ritorno al menu...")
	get_tree().change_scene_to_file(menu_scene_path)
