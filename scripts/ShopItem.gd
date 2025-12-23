extends Area2D

# --- CONFIGURAZIONE NEGOZIO ---
@export var item_to_sell: PackedScene # La scena vera (es. Potion.tscn)
@export var price: int = 10           # Costo
@export var item_texture: Texture2D   # L'immagine da mostrare nello shop

var player_in_range = null # Memorizza il giocatore se è vicino

func _ready():
	# Impostiamo la grafica
	if item_texture:
		$Sprite2D.texture = item_texture
	
	# Scriviamo il prezzo
	$Label.text = str(price) + "$"
	
	# Colleghiamo i segnali di ingresso/uscita
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		# Opzionale: Ingrandisci un po' l'oggetto per evidenziarlo
		scale = Vector2(1.2, 1.2)

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		scale = Vector2(1.0, 1.0)

func _process(delta):
	# Se il giocatore è vicino e preme "Interazione" (o E)
	if player_in_range and Input.is_action_just_pressed("interact"):
		try_to_buy()

func try_to_buy():
	# Controlliamo se il giocatore ha abbastanza soldi
	# Assumiamo che il player abbia una variabile "coins"
	if player_in_range.coins >= price:
		buy_success()
	else:
		buy_fail()

func buy_success():
	print("Acquisto effettuato!")
	
	# 1. Togli i soldi al giocatore
	player_in_range.coins -= price
	# Aggiorna l'HUD (se hai un segnale nel player, emettilo)
	if player_in_range.has_signal("coins_changed"):
		player_in_range.coins_changed.emit(player_in_range.coins)
	
	# 2. Crea l'oggetto vero e proprio
	if item_to_sell:
		var item = item_to_sell.instantiate()
		item.global_position = global_position
		get_parent().add_child(item)
	
	# 3. Effetto sonoro "Cashing!" (Opzionale)
	# AudioPlayer.play("buy")
	
	# 4. Elimina l'espositore (o sostituiscilo con un cartello "Sold Out")
	queue_free()

func buy_fail():
	print("Non hai abbastanza soldi!")
	# Fai lampeggiare il prezzo in rosso per feedback
	var original_color = $Label.modulate
	$Label.modulate = Color.RED
	
	# Crea un tween per rimetterlo normale dopo 0.5 secondi
	var tween = create_tween()
	tween.tween_property($Label, "modulate", original_color, 0.5)
