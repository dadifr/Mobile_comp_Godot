extends Area2D

@export var speed = 400.0
@export var damage = 1
@export var life_time: float = 5.0 

var direction = Vector2.RIGHT
var shooter = null 

@onready var anim = $AnimatedSprite2D

func _ready():
	# nascita
	anim.play("creazione")
	anim.animation_finished.connect(_on_animation_finished)
	
	#collisioni
	body_entered.connect(_on_body_entered)
	
	#timer
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func setup(new_dir, new_damage, who_shot):
	direction = new_dir
	damage = new_damage
	shooter = who_shot
	rotation = direction.angle()

func _physics_process(delta):
	# Movimento
	position += direction * speed * delta

func _on_animation_finished():
	# loop
	if anim.animation == "creazione":
		anim.play("movimento") # Assicurati che questa si chiami "movimento" (o "default")

func _on_body_entered(body):
	if not is_instance_valid(body):
		return
	if body == shooter:
		return
	#danno
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		print("Palla di fuoco a segno! Danno: ", damage)
		queue_free()
	# muro
	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		queue_free()
