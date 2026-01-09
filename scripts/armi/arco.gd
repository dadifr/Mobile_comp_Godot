extends Node2D

@export var arrow_scene: PackedScene 
@export var fire_rate: float = 0.5
@export var texture_pulled: Texture2D

@onready var sprite_arco = $Sprite2D
@onready var freccia_visiva = $FrecciaVisiva 

var can_shoot = true
var is_charging = false
var texture_normal = null

func _ready():
	if sprite_arco:
		texture_normal = sprite_arco.texture
	if freccia_visiva:
		freccia_visiva.visible = false
		
	# --- FIX STRETCHING: Top Level ---
	# Rendiamo l'arco indipendente dalle trasformazioni del padre.
	# In questo modo NON eredita lo "scale.x = -1" della mano che causava lo stretch.
	set_as_top_level(true)

func _process(_delta):
	# --- 1. TROVA IL PLAYER ---
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# --- 2. INSEGUI LA MANO (Necessario perché siamo Top Level) ---
		# Cerchiamo il nodo "Hand" dentro il player per sapere dove posizionarci.
		var hand_node = player.get_node_or_null("Hand")
		if hand_node:
			# Copiamo la posizione globale della mano
			global_position = hand_node.global_position
			
		# --- 3. GESTIONE ROTAZIONE VISIVA ---
		if "last_direction" in player and player.last_direction != Vector2.ZERO:
			var dir = player.last_direction
			# Ora possiamo usare l'angolo reale e pulito della direzione.
			# Non serve più il trucco "abs(dir.x)" perché non siamo più influenzati dallo scale negativo.
			rotation = dir.angle()

	# --- 4. GESTIONE CARICAMENTO ---
	if is_charging:
		if Input.is_action_just_released("attack"):
			shoot()
			reset_bow()

func attack():
	if not can_shoot: return
	is_charging = true
	
	if sprite_arco and texture_pulled:
		sprite_arco.texture = texture_pulled
	if freccia_visiva:
		freccia_visiva.visible = true

func reset_bow():
	is_charging = false
	if sprite_arco: 
		sprite_arco.texture = texture_normal
	if freccia_visiva:
		freccia_visiva.visible = false

func shoot():
	if not arrow_scene: return
	
	var player = get_tree().get_first_node_in_group("player")
	
	var direction = Vector2.RIGHT
	var damage_bonus = 0
	
	if player:
		if "last_direction" in player and player.last_direction != Vector2.ZERO:
			direction = player.last_direction
		if "current_damage_bonus" in player:
			damage_bonus = player.current_damage_bonus
	
	# Creazione freccia
	var arrow = arrow_scene.instantiate()
	# La posizione di spawn è la nostra posizione globale attuale
	arrow.global_position = global_position 
	arrow.direction = direction
	arrow.rotation = direction.angle()
	
	if player:
		arrow.shooter = player
	
	# Iniezione danno
	if damage_bonus > 0:
		arrow.damage += damage_bonus
	
	get_tree().root.add_child(arrow)
	
	# Cooldown
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
