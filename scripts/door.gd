extends StaticBody2D

var is_open = false

func _ready():
	close()

func open():
	if is_open:
		return 
	
	is_open = true
	
	$AnimatedSprite2D.play("open")
	
	$CollisionShape2D.set_deferred("disabled", true)
	

func close():
	if !is_open:
		return 
		
	is_open = false
	
	$AnimatedSprite2D.play("closed")
	
	$CollisionShape2D.set_deferred("disabled", false)
