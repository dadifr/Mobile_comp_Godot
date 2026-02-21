extends Area2D

@export var amount: int = 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)

func collect(player):
	player.bombs += amount
	
	if player.has_signal("bombs_changed"):
		player.bombs_changed.emit(player.bombs)
	
	print("Hai raccolto ", amount, " bomba/e! Totale: ", player.bombs)
	
	
	queue_free()
