extends Area2D

@export var bonus_amount = 2  # Aggiunge 2 danni extra
@export var duration = 10.0   # Dura 10 secondi

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Controlla se è il Player (o se è nel gruppo player)
	if body.name == "Player" or body.is_in_group("player"):
		
		# Chiama la funzione che abbiamo appena aggiunto al Player
		if body.has_method("activate_damage_boost"):
			body.activate_damage_boost(bonus_amount, duration)
			
			# Effetto sonoro (opzionale)
			# AudioPlayer.play("powerup")
			
			queue_free() # Rimuove la pozione
