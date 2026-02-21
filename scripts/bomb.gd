extends RigidBody2D

@export var damage = 5

@export var structure_damage = 30 


var exploded = false


@onready var sfx_explosion = $AudioStreamPlayer2D

func _ready():

	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	explode()

func explode():

	if exploded:
		return
	exploded = true
	

	$AnimatedSprite2D.play("explosion")
	$AnimatedSprite2D.scale = Vector2(4, 4) 
	

	sfx_explosion.play()
	
	
	freeze = true 
	
	
	$BlastArea.set_deferred("monitoring", true)
	

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var bodies = $BlastArea.get_overlapping_bodies()
	
	for body in bodies:
		if not is_instance_valid(body):
			continue
		
		if body == self:
			continue

		if body.has_method("take_damage"):
			
			if body.is_in_group("player"):
				body.take_damage(2, global_position)
			
			elif body.has_method("spawn_enemy"):
				print("BOOM! Struttura demolita!")
				body.take_damage(structure_damage, global_position)
				
			else:
				body.take_damage(damage, global_position)

	
	await $AnimatedSprite2D.animation_finished
	
	$AnimatedSprite2D.hide()
	$BlastArea.set_deferred("monitoring", false)
	
	if sfx_explosion.playing:
		await sfx_explosion.finished
		
	queue_free()
