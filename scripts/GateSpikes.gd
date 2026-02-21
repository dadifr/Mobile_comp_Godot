extends Area2D

@export var damage: int = 1

var is_active = true

@onready var anim = $AnimatedSprite2D
@onready var wall_collision = $StaticBody2D/CollisionShape2D

func _ready():
	is_active = true
	anim.play("active")
	
	if wall_collision:
		wall_collision.set_deferred("disabled", false)
	
	body_entered.connect(_on_body_entered)

func open_gate():
	is_active = false
	anim.play("safe")
	
	if wall_collision:
		wall_collision.set_deferred("disabled", true)
		
	print("Il passaggio è aperto! Muro rimosso.")

func _on_body_entered(body):
	if is_active:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
