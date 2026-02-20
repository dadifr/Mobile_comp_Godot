extends StaticBody2D

# --- CONFIGURAZIONE ---
@export_group("Weighted Enemies")
@export var spawn_list: Array[SpawnRate] 

@export_group("Spawner Stats")
@export var max_health: int = 30
@export var spawn_rate: float = 3.0
@export var spawn_radius: float = 50.0

# --- RIFERIMENTI ---
@onready var timer = $SpawnTimer
@onready var sprite = $Sprite2D

var current_health = 0

func _ready():
	add_to_group("enemies")
	current_health = max_health
	timer.wait_time = spawn_rate
	timer.timeout.connect(_on_spawn_timer_timeout)
	
	# CONTROLLO 1: Esiste il nodo?
	if has_node("ActivationArea"):
		print("✅ Nodo ActivationArea TROVATO e collegato!")
		$ActivationArea.body_entered.connect(_on_activation_area_entered)
	else:
		print("❌ ERRORE: Nodo ActivationArea NON TROVATO! Controlla il nome.")

func _on_activation_area_entered(body):
	# CONTROLLO 2: Qualcosa è entrato?
	print("👀 Qualcosa ha toccato l'area: ", body.name)
	
	if body.is_in_group("player") and timer.is_stopped():
		print("🎯 Giocatore riconosciuto! Spawner in azione!")
		spawn_enemy() # Fa nascere il primo nemico subito
		timer.start()

func _on_spawn_timer_timeout():
	spawn_enemy()

func spawn_enemy():
	if spawn_list.is_empty():
		print("ERRORE: Lista nemici vuota!")
		return
	
	var selected_scene = get_weighted_enemy()
	if selected_scene == null: return
	
	var enemy = selected_scene.instantiate()
	var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * spawn_radius
	enemy.global_position = global_position + random_offset
	
	enemy.scale = Vector2(0.1, 0.1)
	get_parent().call_deferred("add_child", enemy)
	
	var tween = create_tween()
	tween.tween_property(enemy, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	var spawner_tween = create_tween()
	spawner_tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.1)
	spawner_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func get_weighted_enemy() -> PackedScene:
	var total_weight = 0.0
	for item in spawn_list:
		if item.enemy_scene:
			total_weight += item.weight
	
	var roll = randf_range(0.0, total_weight)
	var current_weight = 0.0
	
	for item in spawn_list:
		if item.enemy_scene:
			current_weight += item.weight
			if roll <= current_weight:
				return item.enemy_scene
	return null

func take_damage(amount, _pos = Vector2.ZERO):
	current_health -= amount
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if current_health <= 0: die()

func die():
	print("SPAWNER DISTRUTTO!")
	# Togliamolo dal gruppo nemici così le porte possono aprirsi!
	remove_from_group("enemies") 
	queue_free()
