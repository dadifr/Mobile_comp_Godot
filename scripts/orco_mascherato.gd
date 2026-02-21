extends CharacterBody2D

# --- LIMITI DELLA STANZA ---
@export_group("Limiti Mappa")
@export var min_x = 100.0   
@export var max_x = 1000.0  
@export var min_y = 100.0   
@export var max_y = 600.0   

@export_group("Statistiche")
@export var max_health = 10
var current_health = 0

@export_group("Movimento Inseguimento")
@export var speed = 130.0
@export var acceleration = 8.0

@export_group("Teletrasporto Offensivo")
@export var teleport_cooldown = 5.0
@export var min_dist_from_player = 120.0 
@export var max_dist_from_player = 280.0 
@export var teleport_trigger_dist = 650.0 

@export_group("Bilanciamento Colpo")
@export var post_attack_pause = 1.0 # Secondi di pausa del mob dopo aver colpito
@export var knockback_force = 300.0 # Forza della spinta sul player

# --- STATI INTERNI ---
var player = null
var can_teleport = true
var is_teleporting = false
var is_stunned = false # Stato per la pausa post-colpo

@onready var anim = $AnimatedSprite2D

func _ready():
	current_health = max_health

func _physics_process(delta):
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# Se è in teletrasporto o in pausa post-colpo, sta fermo
	if is_teleporting or is_stunned:
		velocity = velocity.lerp(Vector2.ZERO, 10 * delta)
		move_and_slide()
		return

	var dist_to_player = global_position.distance_to(player.global_position)

	if can_teleport and (dist_to_player > teleport_trigger_dist or randf() < 0.002):
		teleport_near_player()

	var direction = (player.global_position - global_position).normalized()
	velocity = velocity.lerp(direction * speed, acceleration * delta)
	
	if velocity.length() > 15:
		anim.play("run")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")

	move_and_slide()
	check_contact_damage()

# --- DISSOLVENZA E TELETRASPORTO ---
func teleport_near_player():
	if not is_instance_valid(player) or not is_inside_tree() or is_stunned: return
	
	can_teleport = false
	is_teleporting = true
	
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween_out.finished
	
	global_position = calculate_safe_teleport_pos()
	
	var tween_in = create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween_in.finished
	
	is_teleporting = false
	await get_tree().create_timer(teleport_cooldown).timeout
	can_teleport = true

func calculate_safe_teleport_pos() -> Vector2:
	if not is_instance_valid(player): return global_position 
	var final_pos = global_position 
	var p_pos = player.global_position
	for i in range(20):
		var offset = Vector2.RIGHT.rotated(randf() * PI * 2) * randf_range(min_dist_from_player, max_dist_from_player)
		var potential_pos = p_pos + offset
		if potential_pos.x > min_x and potential_pos.x < max_x and potential_pos.y > min_y and potential_pos.y < max_y:
			final_pos = potential_pos
			break
	return final_pos

# --- GESTIONE COLLISIONE E PAUSA ---
func check_contact_damage():
	if is_stunned: return # Non colpisce se è in pausa
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if is_instance_valid(collider) and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				# 1. Applica il danno
				collider.take_damage(1, global_position)
				
				# 2. Entra in pausa per dare tempo al player
				apply_post_attack_stun()
				break

func apply_post_attack_stun():
	is_stunned = true
	anim.play("idle")
	# Feedback visivo: diventa un po' più scuro/trasparente per indicare che è fermo
	modulate.a = 0.5 
	
	await get_tree().create_timer(post_attack_pause).timeout
	
	modulate.a = 1.0
	is_stunned = false

func take_damage(amount, _source_pos = Vector2.ZERO):
	current_health -= amount
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	flash.tween_property(self, "modulate", Color(1, 1, 1), 0.05)
	if current_health <= 0: queue_free()
