extends Area2D

@export var speed = 200.0
@export var damage = 1
@export var life_time: float = 5.0 

var direction = Vector2.ZERO
var shooter = null

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Timer di sicurezza: distruzione automatica dopo 5 secondi
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# SICUREZZA: Controlliamo se il corpo esiste
	if not is_instance_valid(body):
		return

	# Ignora chi ha scoccato la freccia (lo scheletro)
	if body == shooter:
		return

	# SE PUÒ PRENDERE DANNO (Giocatore o altro)
	if body.has_method("take_damage"):
		# --- MODIFICA FONDAMENTALE QUI SOTTO ---
		# Passiamo 'global_position' come secondo argomento.
		# Questo dice al Player: "Ti ho colpito da QUI, spingiti via!"
		body.take_damage(damage, global_position)
		
		# Distruggi la freccia dopo l'impatto
		queue_free()
		
	# CASO 2: Colpisce un Muro (TileMap o StaticBody)
	# Se non è un'Area2D (quindi è solido) e non aveva "take_damage", ci schiantiamo.
	elif not body is Area2D:
		queue_free()

# Sicurezza extra per quando esce dallo schermo (se hai il nodo VisibleOnScreenNotifier2D)
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
