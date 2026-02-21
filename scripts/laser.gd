extends Node2D

@onready var line = $Line2D
@onready var ray = $RayCast2D

var is_charging = true
var creator = null # <--- Verrà assegnato dal Boss direttamente!

func _ready():
	# Se il boss ci ha detto che è lui il creatore, diciamo al raggio di NON colpirlo!
	if is_instance_valid(creator) and creator is CollisionObject2D:
		ray.add_exception(creator)
		
	line.width = 2.0
	line.default_color = Color(1, 0, 0, 0.3)
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)

func _process(_delta):
	if is_charging:
		# Se il creatore non è più valido (ucciso), distruggi il laser
		if not is_instance_valid(creator):
			queue_free()
			return

		ray.force_raycast_update()
		var beam_end = ray.target_position
		if ray.is_colliding():
			beam_end = to_local(ray.get_collision_point())
		
		line.set_point_position(1, beam_end)

func fire_laser():
	is_charging = false
	ray.force_raycast_update()
	
	var final_beam_end = ray.target_position
	if ray.is_colliding():
		final_beam_end = to_local(ray.get_collision_point())
		var target = ray.get_collider()
		if target.is_in_group("player") and target.has_method("take_damage"):
			target.take_damage(1, global_position)

	line.set_point_position(1, final_beam_end)
	line.width = 18.0 
	line.default_color = Color(1, 1, 1, 1) 
	
	var tween = create_tween()
	tween.tween_property(line, "width", 28.0, 0.05)
	tween.tween_property(line, "width", 0, 0.15)
	tween.finished.connect(queue_free)
