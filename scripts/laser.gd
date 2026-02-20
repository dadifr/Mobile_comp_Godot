extends Node2D

@onready var line = $Line2D
@onready var ray = $RayCast2D
@export var damage = 1

func _ready():
	# All'inizio il laser è invisibile
	line.points[1] = Vector2.ZERO
	# Facciamo sparare il laser appena appare
	fire_laser()

func fire_laser():
	# 1. Il RayCast punta verso la posizione del player (impostata dal mob)
	# ray.target_position è già stata settata dal mob prima di istanziare
	
	ray.force_raycast_update() # Forza il calcolo della collisione istantanea
	
	var end_point = ray.target_position
	
	if ray.is_colliding():
		# Se il laser sbatte contro qualcosa, si ferma lì
		end_point = to_local(ray.get_collision_point())
		
		var collider = ray.get_collider()
		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage, global_position)
	
	# 2. Disegna la linea
	line.points[1] = end_point
	
	# 3. Effetto di dissolvenza (il laser sparisce dopo 0.2 secondi)
	var tween = create_tween()
	tween.tween_property(line, "width", 0, 0.2)
	tween.finished.connect(queue_free)
