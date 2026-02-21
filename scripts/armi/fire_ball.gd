extends Area2D

@export var speed = 400.0
@export var damage = 4
@export var life_time: float = 5.0 

var direction = Vector2.RIGHT
var shooter = null 

@onready var anim = $AnimatedSprite2D

func _ready():
	# nascita
	anim.play("creazione")
	anim.animation_finished.connect(_on_animation_finished)
	
	# collisioni
	body_entered.connect(_on_body_entered)
	
	# timer di autodistruzione
	get_tree().create_timer(life_time).timeout.connect(queue_free)

# --- FUNZIONE CHIAMATA DA CHI SPARA ---
func setup(new_dir, new_damage, who_shot):
	direction = new_dir.normalized() 
	damage = new_damage
	shooter = who_shot
	rotation = direction.angle() 
	
	# Capovolge lo sprite se spariamo verso sinistra
	if direction.x < 0:
		$AnimatedSprite2D.flip_v = true
	else:
		$AnimatedSprite2D.flip_v = false

func _physics_process(delta):
	# Movimento
	position += direction * speed * delta

func _on_animation_finished():
	# Passa al movimento solo se ha appena finito la creazione
	if anim.animation == "creazione":
		anim.play("movimento")

func _on_body_entered(body):
	if not is_instance_valid(body):
		return
	
	# Ignora chi ha sparato (per non farsi male da soli)
	if body == shooter:
		return
		
	# --- SISTEMA ANTI-FUOCO AMICO ---
	if shooter != null:
		# Se l'ha sparata il Player, ignora altri player
		if shooter.is_in_group("player") and body.is_in_group("player"):
			return
		# Se l'ha sparata un Mago/Mostro, ignora altri nemici
		if shooter.is_in_group("enemies") and body.is_in_group("enemies"):
			return

	# --- DANNO ---
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		print("Palla di fuoco a segno! Danno: ", damage)
		queue_free()
		
	# --- MURO ---
	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		queue_free()
