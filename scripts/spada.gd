extends Area2D

@export var damage = 1

@onready var anim = $AnimationPlayer
@onready var collision = $CollisionShape2D

func _ready():
	# Assicuriamoci che all'inizio non faccia male
	collision.disabled = true
	# Collega il segnale per colpire
	body_entered.connect(_on_body_entered)

func attack():
	# Se l'animazione sta già andando, non interromperla
	if anim.is_playing():
		return
	
	# Fai partire l'animazione che hai creato (che gestisce rotazione e collisione)
	anim.play("swing")

func _on_body_entered(body):
	if body.has_method("take_damage"):
		if not body.is_in_group("player"):
			# ORA PASSIAMO 2 COSE: IL DANNO E LA NOSTRA POSIZIONE
			body.take_damage(damage, global_position)
