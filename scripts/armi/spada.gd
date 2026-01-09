extends Area2D

@export var damage = 1

@onready var anim = $AnimationPlayer
@onready var collision = $CollisionShape2D

func _ready():
	# Assicuriamoci che all'inizio non faccia male
	collision.disabled = true
	# Collega il segnale per colpire
	body_entered.connect(_on_body_entered)

func attack():
	# Se l'animazione sta già andando, non interromperla
	if anim.is_playing():
		return
	
	# Fai partire l'animazione (che deve attivare/disattivare la collisione)
	anim.play("swing")

func _on_body_entered(body):
	if not is_instance_valid(body):
		return

	# Troviamo il Player (il "nonno" dell'arma)
	var owner_node = get_parent().get_parent()
	
	if body == owner_node:
		return 

	if body.has_method("take_damage"):
		if not body.is_in_group("player"):
			
			# --- CALCOLO DEL DANNO TOTALE ---
			var total_damage = damage 
			
			# Controlliamo se il "proprietario" (Player) ha la variabile del bonus
			if "current_damage_bonus" in owner_node:
				total_damage += owner_node.current_damage_bonus
			
			# Applichiamo il danno calcolato
			body.take_damage(total_damage, global_position)
			
			# Debug per vedere se funziona
			print("Colpito! Danno Base: ", damage, " + Bonus: ", (total_damage - damage))

	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		print("Clang! Colpito un muro.")
