extends Area2D

@export var damage = 1

@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# Assicuriamoci che all'inizio non faccia male
	collision.disabled = true
	# Collega il segnale per colpire
	body_entered.connect(_on_body_entered)

func attack():
	collision.disabled = false
	anim.play("default")
	# Aspetta che l'animazione finisca per spegnere la collisione
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	collision.disabled = true

func _on_body_entered(body):
	if not is_instance_valid(body) or body.is_in_group("player"):
		return 

	# Colpisci solo se il corpo ha il metodo take_damage
	if body.has_method("take_damage"):
		var total_damage = damage 
		
		# Recupera il bonus dal player in modo più sicuro
		var owner_node = get_parent().get_parent()
		if "current_damage_bonus" in owner_node:
			total_damage += owner_node.current_damage_bonus
			
		body.take_damage(total_damage, global_position)
		# Debug
		print("Colpito! Danno Base: ", damage, " + Bonus: ", (total_damage - damage))

	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		print("sting! Colpito un muro.")
