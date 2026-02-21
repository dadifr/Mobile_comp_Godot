extends Area2D

@onready var sfx_coin = $AudioStreamPlayer

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("add_coin"):
		body.add_coin(1)
		
		hide()
		
		$CollisionShape2D.set_deferred("disabled", true)
		
		sfx_coin.play()
		
		await sfx_coin.finished
		
		queue_free()
