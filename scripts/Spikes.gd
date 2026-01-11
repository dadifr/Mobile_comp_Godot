extends Area2D

# --- CONFIGURAZIONE ---
@export var damage: int = 1
@export_group("Timers")
@export var safe_time: float = 2.0   # Tempo in cui sono giù
@export var warn_time: float = 1.0   # Tempo di avvertimento (tremolio)
@export var active_time: float = 1.5 # Tempo in cui sono su (pericolose)

# --- STATI ---
# Definiamo i 3 stati possibili della trappola
enum State { SAFE, WARN, ACTIVE }
var current_state = State.SAFE

# --- RIFERIMENTI ---
@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer

func _ready():
	body_entered.connect(_on_body_entered)
	timer.timeout.connect(_on_timer_timeout)
	
	# Si comincia sempre dallo stato sicuro
	change_state(State.SAFE)

# --- GESTIONE DEL CICLO (STATE MACHINE) ---

# Questa funzione gestisce cosa succede quando il timer scade
func _on_timer_timeout():
	match current_state:
		State.SAFE:
			# Finito il tempo sicuro, si passa all'avvertimento
			change_state(State.WARN)
		State.WARN:
			# Finito l'avvertimento, le spine scattano su!
			change_state(State.ACTIVE)
		State.ACTIVE:
			# Finito il tempo attivo, tornano giù
			change_state(State.SAFE)

# Questa funzione centrale gestisce il cambio di stato
func change_state(new_state):
	current_state = new_state
	timer.stop() # Fermiamo il timer vecchio prima di riavviarlo
	
	match current_state:
		State.SAFE:
			anim.play("safe")
			timer.wait_time = safe_time
			timer.start()
			
		State.WARN:
			anim.play("warn") # Assicurati di aver creato questa animazione!
			timer.wait_time = warn_time
			timer.start()
			
		State.ACTIVE:
			anim.play("active")
			timer.wait_time = active_time
			timer.start()
			# CONTROLLO CRUCIALE: Appena diventano attive, controlla chi c'è sopra
			check_overlapping_bodies()

# --- GESTIONE DANNO ---

# Controlla chi è già sopra le spine nel momento in cui scattano
func check_overlapping_bodies():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		deal_damage(body)

# Controlla chi entra sulle spine mentre sono già su
func _on_body_entered(body):
	# Il danno si applica SOLO se lo stato attuale è ACTIVE
	if current_state == State.ACTIVE:
		deal_damage(body)

# Funzione helper per applicare il danno
func deal_damage(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
