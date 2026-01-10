extends Area2D

@export var speed = 200.0
@export var damage = 1
var direction = Vector2.ZERO

func _physics_process(delta):
	# Si muove dritto nella direzione impostata
	position += direction * speed * delta

# Collegato al segnale "body_entered" dell'Area2D
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free() # Scompare quando colpisce il player
	elif not body.is_in_group("mobs"): # Non farti colpire dagli altri mob
		queue_free() # Scompare se colpisce un muro
