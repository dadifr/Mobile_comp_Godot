extends Node2D

# Trascina qui la scena Freccia.tscn dall'inspector
@export var arrow_scene: PackedScene 
@export var fire_rate: float = 0.5

var can_shoot = true

func attack():
	# Se siamo in cooldown o non abbiamo assegnato la scena della freccia, non fare nulla
	if not can_shoot or not arrow_scene:
		return
	
	# 1. Istanzia la freccia
	var arrow = arrow_scene.instantiate()
	
	# 2. Imposta la posizione iniziale (la posizione dell'arco nel mondo)
	arrow.global_position = global_position
	
	# 3. Calcola la direzione
	# In cavaliere.gd, la "Hand" viene flippata (scale.x = -1) quando guarda a sinistra.
	# Possiamo usare questo per decidere la direzione della freccia.
	var direction = Vector2.RIGHT
	
	# get_parent() è il nodo "Hand". Se la sua scala X è negativa, stiamo guardando a sinistra.
	if get_parent().scale.x < 0:
		direction = Vector2.LEFT
	
	# 4. Assegna i dati alla freccia
	arrow.direction = direction
	arrow.rotation = direction.angle() # Ruota la sprite della freccia (es. 180° se va a sinistra)
	
	# "owner" è solitamente il nodo radice della scena (l'Elfo/Cavaliere).
	# Lo assegniamo come "shooter" così la freccia non ti colpisce da sola.
	if owner:
		arrow.shooter = owner
	
	# 5. Aggiungi la freccia al mondo di gioco (Root)
	# Non aggiungerla come figlio dell'arco, altrimenti si muoverebbe con te!
	get_tree().root.add_child(arrow)
	
	# 6. Gestione Cooldown
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
