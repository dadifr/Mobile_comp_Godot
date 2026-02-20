extends Node2D

@onready var line = $Line2D
@onready var ray = $RayCast2D

var is_charging = true

func _ready():
	# Inizialmente la linea è un "mirino" quasi trasparente e sottile
	line.width = 0.5
	line.default_color = Color(1, 0, 0, 0.3) # Rosso trasparente

func _process(_delta):
	# Se sta caricando, continua a seguire il player (opzionale)
	# Se vuoi che il laser "si blocchi" prima di sparare, rimuovi questo blocco
	if is_charging and get_tree().get_first_node_in_group("player"):
		var p = get_tree().get_first_node_in_group("player")
		ray.target_position = to_local(p.global_position)
		line.set_point_position(1, ray.target_position)

func fire_laser():
	is_charging = false
	
	# Forza l'aggiornamento per vedere cosa colpisce
	ray.force_raycast_update()
	
	var end_point = ray.target_position
	
	if ray.is_colliding():
		end_point = to_local(ray.get_collision_point())
		var target = ray.get_collider()
		if target.is_in_group("player") and target.has_method("take_damage"):
			target.take_damage(1, global_position)

	# --- EFFETTO VISIVO DELLO SPARO ---
	line.set_point_position(1, end_point)
	line.width = 4.0               # Si ingrossa improvvisamente
	line.default_color = Color(1, 1, 1, 1) # Diventa bianco/rosso brillante
	
	# Dissolvenza rapida
	var tween = create_tween()
	tween.tween_property(line, "width", 0, 0.15)
	tween.finished.connect(queue_free)
