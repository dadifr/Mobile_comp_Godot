extends Area2D

# --- MODIFICA: Ora è una LISTA (Array) di Area2D ---
# Invece di collegarne una sola, puoi collegarne quante ne vuoi!
@export var target_spikes: Array[Area2D] 

# --- STATO ---
var is_pulled = false
var player_in_range = false

@onready var anim = $AnimatedSprite2D
@onready var label = $Label

func _ready():
	anim.play("off")
	if label: label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_in_range and not is_pulled and Input.is_action_just_pressed("interact"):
		pull_lever()

func pull_lever():
	is_pulled = true
	anim.play("on")
	if label: label.visible = false
	
	# --- MODIFICA: Ciclo For ---
	# Scorriamo tutta la lista e le disattiviamo una per una
	if target_spikes.is_empty():
		print("ATTENZIONE: Nessuna spina collegata a questa leva!")
		return

	for spike in target_spikes:
		# Controlliamo che la spina esista e abbia la funzione giusta
		if spike and spike.has_method("open_gate"):
			spike.open_gate()
	
	print("Tutte le spine collegate sono state abbassate!")

# --- RILEVAMENTO PLAYER ---
func _on_body_entered(body):
	if body.is_in_group("player") and not is_pulled:
		player_in_range = true
		if label: label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if label: label.visible = false
