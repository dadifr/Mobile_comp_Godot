extends Area2D

# Configurazione nell'Inspector
@export var speed_multiplier: float = 1.5 # 1.5 = +50% Velocità
@export var duration: float = 60.0 # Dura 60 secondi

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Controlla se il player ha la funzione che abbiamo appena scritto
		if body.has_method("activate_speed_boost"):
			body.activate_speed_boost(speed_multiplier, duration)
			
			# Suono (opzionale)
			# AudioPlayer.play_sfx("powerup")
			
			queue_free()
