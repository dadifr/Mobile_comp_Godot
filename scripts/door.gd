extends StaticBody2D

# Variabile per sapere lo stato attuale
var is_open = false

func _ready():
	# Partiamo con la porta chiusa
	close()

func open():
	if is_open:
		return # È già aperta, non fare nulla
	
	is_open = true
	
	# 1. Cambia grafica
	$AnimatedSprite2D.play("open")
	
	# 2. Disattiva il muro fisico
	# IMPORTANTE: Usiamo "set_deferred" perché non possiamo cambiare la fisica
	# mentre il gioco sta calcolando le collisioni, altrimenti crasha.
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Suono (opzionale)
	# AudioPlayer.play("door_open")

func close():
	if !is_open:
		return # È già chiusa
		
	is_open = false
	
	# 1. Cambia grafica
	$AnimatedSprite2D.play("closed")
	
	# 2. Attiva il muro fisico
	$CollisionShape2D.set_deferred("disabled", false)
