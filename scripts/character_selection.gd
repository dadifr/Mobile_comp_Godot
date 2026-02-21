extends Control

# Immagini selezione personaggio
@export var knight_scene: PackedScene
@export var elf_scene: PackedScene
@export var dwarf_scene: PackedScene
@export var lizard_scene: PackedScene
@export var mage_scene: PackedScene

# Riferimenti ai bottoni
@onready var btn_knight = $HBoxContainer/BtnCavaliere
@onready var btn_elf = $HBoxContainer/BtnElfo
@onready var btn_dwarf = $HBoxContainer/BtnNano
@onready var btn_lizard = $HBoxContainer/BtnLizard
@onready var btn_mage = $HBoxContainer/BtnMago

func _ready():
	btn_knight.pressed.connect(_on_knight_selected)
	btn_elf.pressed.connect(_on_elf_selected)
	btn_dwarf.pressed.connect(_on_dwarf_selected)
	btn_lizard.pressed.connect(_on_lizard_selected)
	btn_mage.pressed.connect(_on_mage_selected)

func _on_knight_selected():
	GameManager.selected_character_scene = knight_scene
	start_game()

func _on_elf_selected():
	GameManager.selected_character_scene = elf_scene
	start_game()

func _on_dwarf_selected():
	GameManager.selected_character_scene = dwarf_scene
	start_game()

func _on_lizard_selected():
	GameManager.selected_character_scene = lizard_scene
	start_game()

func _on_mage_selected():
	GameManager.selected_character_scene = mage_scene
	start_game()

func start_game():
	get_tree().change_scene_to_file("res://scenes/world.tscn")
