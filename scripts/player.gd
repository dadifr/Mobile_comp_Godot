extends AnimatedSprite2D

const SPEED = 130.0
var v = Vector2( )

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
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
