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
		
	set_as_top_level(true)

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var hand_node = player.get_node_or_null("Hand")
		if hand_node:
			global_position = hand_node.global_position
#rotazione
		if "last_direction" in player:
			var dir = player.last_direction
			if dir.x > 0:
				rotation = 0
			elif dir.x < 0:
				rotation = PI 
# caricamento
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
	
	var shoot_direction = Vector2.RIGHT.rotated(rotation)
	
	var arrow = arrow_scene.instantiate()
	
	arrow.global_position = global_position 
	arrow.direction = shoot_direction
	arrow.rotation = rotation
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		arrow.shooter = player
		if "current_damage_bonus" in player:
			arrow.damage += player.current_damage_bonus
	
	get_tree().root.add_child(arrow)
	
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
