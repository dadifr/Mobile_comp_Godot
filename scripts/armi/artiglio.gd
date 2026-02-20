extends Area2D

@export var damage: int = 2
@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	visible = false 
	collision.disabled = true
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func attack():
	if anim.is_playing():
		return
	self.visible = true
	anim.stop()
	collision.disabled = false
	anim.play("default")
	
	
	if not anim.animation_finished.is_connected(_on_attack_finished):
		anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished():
	collision.disabled = true
	self.visible = false

func _on_body_entered(body):
	
	if not is_instance_valid(body) or body.is_in_group("player"):
		return 

	if body.has_method("take_damage"):
		var total_damage = _calculate_total_damage()
		body.take_damage(total_damage, global_position)
		print("Nemico colpito! Danno: ", total_damage)
	else:
		print("Corpo toccato: ", body.name, " ma non ha il metodo take_damage")

func _calculate_total_damage() -> int:
	var total = damage
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if "current_damage_bonus" in player:
			total += player.current_damage_bonus
	return total
