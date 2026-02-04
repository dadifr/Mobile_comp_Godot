extends Node2D

@export var projectile_scene: PackedScene 
@export var fire_rate: float = 0.5

@onready var spawn_point = $Punta

var can_shoot = true

func _ready():
	set_as_top_level(true)

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var hand_node = player.get_node_or_null("Hand")
		if hand_node:
			global_position = hand_node.global_position
		
		if "last_direction" in player:
			var dir = player.last_direction
			
			if dir.x < 0:
				scale.x = -0.7
				rotation = -0.3
			elif dir.x > 0:
				scale.x = 0.7
				rotation = 0.3

func attack():
	if not can_shoot: return
	shoot()

func shoot():
	if not projectile_scene: return
	
	var player = get_tree().get_first_node_in_group("player")
	
	var shoot_dir = Vector2.RIGHT
	if scale.x < 0:
		shoot_dir = Vector2.LEFT
	
	var final_damage = 2 # Danno base
	
	if player:
		if "current_damage_bonus" in player:
			final_damage += player.current_damage_bonus

	var fireball = projectile_scene.instantiate()
	
	if spawn_point:
		fireball.global_position = spawn_point.global_position
	else:
		fireball.global_position = global_position
		
	fireball.setup(shoot_dir, final_damage, player)
	
	get_tree().root.add_child(fireball)
	
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
