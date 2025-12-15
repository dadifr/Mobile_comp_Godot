extends Node2D

@onready var player = $Player
@onready var hud = $HUD

func _ready():
	# Colleghiamo il segnale del player alla funzione dell'HUD
	player.health_changed.connect(hud.update_life)
	
	# Aggiorniamo l'HUD subito per mostrare la vita iniziale
	hud.update_life(player.health)
