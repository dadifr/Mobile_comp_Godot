extends Control

# Immagini selezione personaggio
@export var knight_scene: PackedScene
@export var elf_scene: PackedScene
@export var dwarf_scene: PackedScene

# Riferimenti ai bottoni (se li hai chiamati diversamente, cambia i nomi qui!)
@onready var btn_knight = $HBoxContainer/BtnCavaliere
@onready var btn_elf = $HBoxContainer/BtnElfo
@onready var btn_dwarf = $HBoxContainer/BtnNano

func _ready():
	# Colleghiamo i click dei bottoni
	btn_knight.pressed.connect(_on_knight_selected)
	btn_elf.pressed.connect(_on_elf_selected)
	btn_dwarf.pressed.connect(_on_dwarf_selected)

func _on_knight_selected():
	# 1. Diciamo al GameManager: "Ho scelto il Cavaliere!"
	GameManager.selected_character_scene = knight_scene
	# 2. Carichiamo il livello di gioco
	start_game()

func _on_elf_selected():
	# 1. Diciamo al GameManager: "Ho scelto il Mago!"
	GameManager.selected_character_scene = elf_scene
	# 2. Carichiamo il livello di gioco
	start_game()

func _on_dwarf_selected():
	# 1. Diciamo al GameManager: "Ho scelto il Cavaliere!"
	GameManager.selected_character_scene = dwarf_scene
	# 2. Carichiamo il livello di gioco
	start_game()

func start_game():
	# Cambia scena verso il tuo mondo principale (assicurati del percorso!)
	get_tree().change_scene_to_file("res://scenes/world.tscn")
