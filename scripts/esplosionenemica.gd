extends Area2D

@export var damage = 1

func _ready():
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("default")
		$AnimatedSprite2D.animation_finished.connect(queue_free)
	
	await get_tree().create_timer(0.05).timeout
	check_damage()

func check_damage():
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
				print("Player colpito dall'esplosione!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
