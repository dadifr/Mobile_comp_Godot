extends Area2D

@export var speed = 200.0
@export var damage = 1
@export var life_time: float = 5.0 # SICUREZZA 1: Tempo massimo di vita

var direction = Vector2.ZERO
var shooter = null

func _ready():
	# Colleghiamo il segnale di collisione
	body_entered.connect(_on_body_entered)
	
	# SICUREZZA 1 (Memoria): "Timer di autodistruzione"
	# Se la freccia vaga nel vuoto per 5 secondi, si distrugge da sola.
	# Questo impedisce al gioco di rallentare se spari fuori mappa.
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# SICUREZZA GENERALE: Controlliamo sempre se il corpo esiste ancora
	if not is_instance_valid(body):
		return

	# Se il corpo che ho colpito è lo stesso che mi ha sparato, IGNORALO.
	if body == shooter:
		return
	#se la freccia può colpire qualsiasi cosa tranne chi la lancia
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free() # Distruggi la freccia
		
	# CASO 1: Colpisce il Player
	#if body.is_in_group("player"):
		## SICUREZZA 2 (Metodo): Verifica se la funzione esiste prima di chiamarla
		#if body.has_method("take_damage"):
			#body.take_damage(damage, global_position)
		#else:
			## Debug utile per noi sviluppatori
			#printerr("ATTENZIONE: Il nodo ", body.name, " è nel gruppo 'player' ma non ha 'take_damage'!")
		#
		#queue_free() # La freccia si distrugge dopo aver colpito

	
	# CASO 2: Colpisce un Muro o Ostacolo
	# Invece di chiedere "Sei un Muro? O sei un TileMap?", usiamo una logica più ampia.
	# Se il corpo NON è un'Area2D (quindi è un corpo fisico solido), ci schiantiamo.
	elif not body is Area2D:
		# Questo copre: StaticBody2D, TileMap, TileMapLayer (nuovo Godot 4), RigidBody2D
		queue_free()

# SICUREZZA 3 (Schermo): Manteniamo questo come backup
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
