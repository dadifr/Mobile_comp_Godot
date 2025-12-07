extends CharacterBody2D

const SPEED = 130.0
var v = Vector2( )


func _physics_process(delta: float) -> void:
	#movimento 3D sulla mappa di gioco
	
	if Input.is_action_pressed("ui_up"):
		v.y = -1
	elif Input.is_action_pressed("ui_down"):
		v.y = 1
	elif Input.is_action_pressed("ui_left"):
		v.x = -1
	elif Input.is_action_pressed("ui_right"):
		v.x = 1
	
	self.position = self.position + v.normalized() * SPEED * delta
