extends Node2D

@export var arrow_scene: PackedScene 
@export var fire_rate: float = 0.5
@export var texture_pulled: Texture2D # L'immagine dell'arco teso

@onready var sprite_arco = $Sprite2D
@onready var freccia_visiva = $FrecciaVisiva # Il nuovo nodo che hai appena creato

var can_shoot = true
var is_charging = false
var texture_normal = null

func _ready():
	# Ci salviamo l'aspetto normale dell'arco
	if sprite_arco:
		texture_normal = sprite_arco.texture
	
	# Assicuriamoci che la freccia finta sia nascosta all'inizio
	if freccia_visiva:
		freccia_visiva.visible = false

func _process(_delta):
	# Se stiamo caricando...
	if is_charging:
		# ...e rilasciamo il tasto
		if Input.is_action_just_released("attack"):
			shoot()
			reset_bow()

# Questa viene chiamata dall'Elfo quando PREMI il tasto
func attack():
	if not can_shoot:
		return
	
	is_charging = true
	
	# 1. Cambia l'arco in "Teso"
	if sprite_arco and texture_pulled:
		sprite_arco.texture = texture_pulled
	
	# 2. MOSTRA la freccia ferma sulla corda
	if freccia_visiva:
		freccia_visiva.visible = true

# Funzione per resettare la grafica (usata dopo lo sparo o se veniamo interrotti)
func reset_bow():
	is_charging = false
	
	# Rimetti l'arco normale
	if sprite_arco: 
		sprite_arco.texture = texture_normal
	
	# NASCONDI la freccia visiva
	if freccia_visiva:
		freccia_visiva.visible = false

func shoot():
	if not arrow_scene: return
	
	# Qui creiamo la freccia VERA che vola via
	var direction = Vector2.RIGHT
	if owner and "last_direction" in owner:
		if owner.last_direction != Vector2.ZERO:
			direction = owner.last_direction
	
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = direction
	arrow.rotation = direction.angle()
	if owner:
		arrow.shooter = owner
	get_tree().root.add_child(arrow)
	
	# Cooldown
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
