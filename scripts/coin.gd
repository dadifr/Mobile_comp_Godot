extends Area2D

func _ready():
	# Colleghiamo il segnale di quando qualcosa entra nell'area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Controlliamo se è il Player (cercando se ha il metodo "add_coin")
	if body.has_method("add_coin"):
		# Aggiungi la moneta
		body.add_coin(1)
		
		# (Opzionale) Qui potresti mettere un suono: $AudioStreamPlayer.play()
		
		# Distruggi la moneta dalla scena
		queue_free()
