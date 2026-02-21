extends CharacterBody2D

@export_group("Limiti Mappa")
@export var min_x = 100.0   
@export var max_x = 1000.0  
@export var min_y = 100.0   
@export var max_y = 600.0   

@export_group("Movimento")
@export var step_speed = 80.0
@export var pause_duration = 2.0
@export var step_duration = 0.6

@export_group("Combattimento")
@export var contact_damage = 1
@export var fireball_scene: PackedScene
@export var shoot_range = 550.0
@export var shoot_cooldown = 3.0
@export var charge_time = 0.8

var player = null
var can_shoot = true
var is_attacking = false
var is_moving = false
var move_direction = Vector2.ZERO

@onready var anim = $AnimatedSprite2D

func _ready():
	decide_next_action()

func _physics_process(_delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	if is_attacking:
		velocity = Vector2.ZERO
	elif is_moving:
		velocity = move_direction * step_speed
		anim.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		anim.flip_h = player.global_position.x < global_position.x

	move_and_slide()
	check_contact_damage()
	
	var dist = global_position.distance_to(player.global_position)
	if dist < shoot_range and can_shoot and not is_attacking:
		attack_fireball()

func decide_next_action():
	if not is_inside_tree(): return
	if is_attacking:
		await get_tree().create_timer(0.5).timeout
		decide_next_action()
		return

	move_direction = Vector2.RIGHT.rotated(deg_to_rad(randi_range(0, 360)))
	var future_pos = global_position + (move_direction * step_speed * step_duration)
	if future_pos.x < min_x or future_pos.x > max_x or future_pos.y < min_y or future_pos.y > max_y:
		move_direction *= -1

	is_moving = true
	anim.play("run")
	await get_tree().create_timer(step_duration).timeout
	
	is_moving = false
	anim.play("idle")
	await get_tree().create_timer(pause_duration).timeout
	decide_next_action()

func attack_fireball():
	if fireball_scene == null or not is_inside_tree(): return
	
	is_attacking = true
	can_shoot = false
	anim.play("attack")
	modulate = Color(2.5, 1.5, 1.0)
	
	await get_tree().create_timer(charge_time).timeout
	
	if not is_inside_tree() or not is_instance_valid(player): 
		is_attacking = false
		modulate = Color(1,1,1)
		return

	var fireball = fireball_scene.instantiate()
	
	# CALCOLO DIREZIONE E SPAWN OFFSET
	var target_dir = (player.global_position - global_position).normalized()
	# Facciamo apparire la palla 40 pixel davanti al mago per non colpirlo
	fireball.global_position = global_position + (target_dir * 40.0)
	
	if fireball.has_method("setup"):
		fireball.setup(target_dir, 1, self)
	
	get_parent().add_child(fireball)
	
	modulate = Color(1, 1, 1)
	anim.play("idle")
	await get_tree().create_timer(0.4).timeout
	is_attacking = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func check_contact_damage():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if is_instance_valid(collider) and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(contact_damage, global_position)

func take_damage(_amount, _pos = Vector2.ZERO):
	queue_free()
