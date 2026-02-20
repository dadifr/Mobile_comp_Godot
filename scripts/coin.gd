extends Area2D

# Creiamo un riferimento al nodo del suono
@onready var sfx_coin = $AudioStreamPlayer

func _ready():
	# Colleghiamo il segnale di quando qualcosa entra nell'area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Controlliamo se è il Player (cercando se ha il metodo "add_coin")
	if body.has_method("add_coin"):
		# Aggiungi la moneta al contatore del Player
		body.add_coin(1)
		
		# 1. Nascondiamo la moneta visivamente (sparisce dallo schermo)
		hide()
		
		# 2. Disabilitiamo la collisione (evita che il player la raccolga 2 volte di fila)
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 3. Facciamo partire il suono
		sfx_coin.play()
		
		# 4. Aspettiamo che l'audio finisca completamente di suonare
		await sfx_coin.finished
		
		# 5. Ora possiamo distruggere il nodo in totale sicurezza!
		queue_free()
