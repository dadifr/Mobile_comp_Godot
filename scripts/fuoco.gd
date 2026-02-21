extends Area2D

@export var speed = 200.0
@export var damage = 1
var direction = Vector2.ZERO

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	elif not body.is_in_group("mobs"): 
		queue_free() 
