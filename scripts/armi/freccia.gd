extends Area2D

@export var speed = 200.0
@export var damage = 1
@export var life_time: float = 5.0 

var direction = Vector2.ZERO
var shooter = null

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Timer
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# SICUREZZA: Controlliamo se il corpo esiste
	if not is_instance_valid(body):
		return

	# Ignora chi ha sparato
	if body == shooter:
		return
		
	if body.is_in_group("player"):
		body.slow_down()
		
	# controllo possa prendere danno
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		
		
		# Distruggi la freccia dopo l'impatto
		queue_free()
	
		
	# muro
	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		queue_free()
