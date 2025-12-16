extends Node2D

@onready var player = $Player
@onready var hud = $HUD

func _ready():
	# Colleghiamo il segnale del player alla funzione dell'HUD
	player.health_changed.connect(hud.update_life)
	
	# Aggiorniamo l'HUD subito per mostrare la vita iniziale
	hud.update_life(player.health)


func _on_player_bombs_changed(new_amount: Variant) -> void:
	$HUD.update_bombs(new_amount)


func _on_player_coins_changed(new_amount: Variant) -> void:
	$HUD.update_coins(new_amount)
