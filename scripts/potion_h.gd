extends Area2D

# Quantità di cura (2 punti = 1 Cuore pieno)
@export var heal_amount = 1 

func _ready():
	# Colleghiamo il segnale di "ingresso" nell'area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Controlliamo se chi è entrato è il Giocatore
	if body.is_in_group("player"):
		# Controlliamo se il giocatore ha bisogno di cure
		# (Assumiamo che il player abbia le variabili health e max_health)
		if body.health < body.max_health:
			# Chiamiamo la funzione di cura sul player
			if body.has_method("heal"):
				body.heal(heal_amount)
				
				# Effetto sonoro (opzionale, mettilo qui se ce l'hai)
				# AudioPlayer.play("potion_pickup")
				
				# Distruggiamo la pozione
				queue_free()
