extends Area2D

@export var damage: int = 1

# Variabile di stato: True = fanno male, False = puoi passare
var is_active = true

@onready var anim = $AnimatedSprite2D

func _ready():
	# All'inizio sono alzate e pericolose
	is_active = true
	anim.play("active")
	
	body_entered.connect(_on_body_entered)

# Questa funzione verrà chiamata dalla Leva
func open_gate():
	is_active = false
	anim.play("safe") # Animazione spine abbassate
	print("Il passaggio è aperto!")

func _on_body_entered(body):
	# Fanno danno SOLO se sono attive
	if is_active:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
