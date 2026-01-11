extends Area2D

@export var damage: int = 1

# Variabile di stato
var is_active = true

@onready var anim = $AnimatedSprite2D
# Riferimento al muro fisico (collisione solida)
# Assicurati che il percorso sia corretto rispetto alla tua scena!
@onready var wall_collision = $StaticBody2D/CollisionShape2D

func _ready():
	# All'inizio sono alzate, pericolose e SOLIDE
	is_active = true
	anim.play("active")
	
	# Attiviamo il muro (false significa "non disabilitato", quindi attivo)
	if wall_collision:
		wall_collision.set_deferred("disabled", false)
	
	body_entered.connect(_on_body_entered)

# Questa funzione viene chiamata dalla Leva
func open_gate():
	is_active = false
	anim.play("safe")
	
	# DISATTIVIAMO IL MURO: Ora il giocatore può camminarci sopra
	if wall_collision:
		wall_collision.set_deferred("disabled", true)
		
	print("Il passaggio è aperto! Muro rimosso.")

func _on_body_entered(body):
	# Fanno danno SOLO se sono attive
	if is_active:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
