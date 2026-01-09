extends Area2D

# --- VARIABILI DI CONFIGURAZIONE ---
@export var speed = 400.0
@export var damage = 1
@export var life_time: float = 5.0 

# --- VARIABILI INTERNE ---
var direction = Vector2.RIGHT
var shooter = null # Chi ha sparato (per non colpirlo)

@onready var anim = $AnimatedSprite2D

func _ready():
	# 1. Animazione di Nascita
	anim.play("creazione")
	anim.animation_finished.connect(_on_animation_finished)
	
	# 2. Collegamento Collisioni (come nella freccia)
	body_entered.connect(_on_body_entered)
	
	# 3. Timer di sicurezza (distruzione automatica se non colpisce nulla)
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func setup(new_dir, new_damage, who_shot):
	# Funzione chiamata dal Bastone per impostare i dati
	direction = new_dir
	damage = new_damage
	shooter = who_shot
	rotation = direction.angle() # Ruota la grafica

func _physics_process(delta):
	# Movimento
	position += direction * speed * delta

func _on_animation_finished():
	# Passa al loop di fuoco quando finisce di nascere
	if anim.animation == "creazione":
		anim.play("movimento") # Assicurati che questa si chiami "movimento" (o "default")

func _on_body_entered(body):
	# SICUREZZA: Controlliamo se il corpo esiste
	if not is_instance_valid(body):
		return

	# Ignora chi ha sparato (il Player)
	if body == shooter:
		return

	# SE PUÒ PRENDERE DANNO (Nemico)
	if body.has_method("take_damage"):
		# Qui usiamo la logica della freccia che funziona!
		body.take_damage(damage, global_position)
		print("Palla di fuoco a segno! Danno: ", damage)
		queue_free()
		
	# CASO 2: Colpisce un Muro 
	# (TileMap, StaticBody o TileMapLayer)
	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		queue_free()
