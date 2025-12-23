extends Area2D

# Quante bombe ti regala questo oggetto?
# Di base 1, ma puoi cambiarlo nell'editor (es. 3 per un pacchetto scorta)
@export var amount: int = 1

func _ready():
	# Colleghiamo il segnale di collisione
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Controlliamo se è il giocatore
	if body.is_in_group("player"):
		collect(body)

func collect(player):
	# 1. Aggiungiamo le bombe all'inventario del giocatore
	# (Assumiamo che la variabile "bombs" esista nel player, come fatto prima)
	player.bombs += amount
	
	# 2. Aggiorniamo l'HUD
	# È fondamentale emettere il segnale, altrimenti il numero a schermo non cambia!
	if player.has_signal("bombs_changed"):
		player.bombs_changed.emit(player.bombs)
	
	# 3. Feedback (Stampa di prova)
	print("Hai raccolto ", amount, " bomba/e! Totale: ", player.bombs)
	
	# 4. Audio (Spazio per il futuro)
	# AudioPlayer.play("pickup_key")
	
	# 5. Distruggiamo l'oggetto raccolto
	queue_free()
