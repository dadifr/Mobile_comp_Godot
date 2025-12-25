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
	
	# Fai partire l'animazione (che deve attivare/disattivare la collisione)
	anim.play("swing")

func _on_body_entered(body):
	# --- SICUREZZA 1: Validità dell'istanza ---
	# Se il nemico è stato ucciso da un'altra cosa 1 millisecondo fa,
	# questa riga impedisce al gioco di crashare.
	if not is_instance_valid(body):
		return

	# --- SICUREZZA 2: Protezione Proprietario ---
	# Dobbiamo evitare che la spada colpisca chi la tiene in mano!
	# Struttura ipotizzata: Player -> Hand -> Sword (Tu sei qui)
	# Quindi il proprietario è il "nonno" (get_parent().get_parent())
	var owner_node = get_parent().get_parent()
	if body == owner_node:
		return # Ignora la collisione con noi stessi

	# --- LOGICA DANNO ---
	if body.has_method("take_damage"):
		# Qui manteniamo la tua logica: questa spada non ferisce i Player
		# (Utile se aggiungi co-op o NPC alleati, o semplicemente come sicurezza extra)
		if not body.is_in_group("player"):
			
			# Applichiamo il danno e passiamo la posizione per il Knockback
			body.take_damage(damage, global_position)
			
			# Opzionale: Aggiungi un suono di impatto "Carne"
			# AudioPlayer.play("hit_flesh")

	# --- SICUREZZA 3: Gestione Muri/Oggetti solidi ---
	# Se colpiamo un muro, non deve succedere nulla (o fai un suono "Clang")
	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		print("Clang! Colpito un muro.")
		# Opzionale: Aggiungi un suono metallico e scintille
		# AudioPlayer.play("hit_wall")
		# spawn_sparks(global_position)
