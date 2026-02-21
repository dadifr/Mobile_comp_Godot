extends CharacterBody2D

# --- IMPOSTAZIONI ---
@export_group("Movimento")
@export var flee_speed = 130.0 
@export var patrol_speed = 30.0
@export var detection_range = 250.0 

@export_group("Loot")
@export var potion_scene: PackedScene

var player = null


var move_direction = Vector2.ZERO
var roam_timer = 0.0
var time_to_next_move = 0.0

@onready var anim = $AnimatedSprite2D

func _ready():
	
	add_to_group("enemies")
	pick_new_state()

func _physics_process(delta):
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = null


	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < detection_range:

			var flee_direction = (global_position - player.global_position).normalized()
			velocity = flee_direction * flee_speed
		else:

			handle_patrol(delta)
	else:
		handle_patrol(delta)


	if velocity.length() > 0:
		anim.play("run") 
		if velocity.x < 0:
			anim.flip_h = true
		elif velocity.x > 0:
			anim.flip_h = false
	else:
		anim.play("idle")


	move_and_slide()


func handle_patrol(delta):
	roam_timer += delta
	if roam_timer >= time_to_next_move:
		pick_new_state()
	velocity = move_direction * patrol_speed

func pick_new_state():
	roam_timer = 0.0
	time_to_next_move = randf_range(1.0, 3.0)
	if randf() > 0.5:
		move_direction = Vector2.ZERO
	else:
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()


func take_damage(amount, source_pos = Vector2.ZERO):
	die()

func die():
	print("Angelo sconfitto!")
	remove_from_group("enemies")
	
	if potion_scene == null:
		print("❌ ERRORE GRAVE: L'Angelo non ha la scena della pozione nell'Inspector!")
	else:
		var potion = potion_scene.instantiate()
		potion.global_position = global_position
		
		get_tree().current_scene.call_deferred("add_child", potion)
	
	queue_free()
