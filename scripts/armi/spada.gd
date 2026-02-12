extends Area2D

@export var damage = 1

@onready var anim = $AnimationPlayer
@onready var collision = $CollisionShape2D

func _ready():
	# no danno all`inizio
	collision.disabled = true
	# Collega il segnale per colpire
	body_entered.connect(_on_body_entered)

func attack():
	# animazione gia in corso
	if anim.is_playing():
		return
	
	# Fai partire l'animazione
	anim.play("swing")

func _on_body_entered(body):
	if not is_instance_valid(body):
		return

	# giocatore
	var owner_node = get_parent().get_parent()
	
	if body == owner_node:
		return 

	if body.has_method("take_damage"):
		if not body.is_in_group("player"):
			
			#  danno
			var total_damage = damage 
			
			# Controllo bonus del player
			if "current_damage_bonus" in owner_node:
				total_damage += owner_node.current_damage_bonus
			
			# Applichiamo il danno 
			body.take_damage(total_damage, global_position)
			
			# Debug
			print("Colpito! Danno Base: ", damage, " + Bonus: ", (total_damage - damage))

	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		print("Clang! Colpito un muro.")
