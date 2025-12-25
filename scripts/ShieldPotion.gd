extends Area2D

# 1 = Pozione Piccola (Mezzo Scudo)
# 2 = Pozione Grande (Scudo Intero)
@export var potion_value: int = 1 

func _ready():
	# Colleghiamo la collisione
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Controllo di sicurezza
	if not is_instance_valid(body):
		return
		
	# Se è il player, gli diamo l'armatura
	if body.is_in_group("player"):
		if body.has_method("add_armor"):
			body.add_armor(potion_value)
			
			# Qui metti il suono della bevuta se vuoi
			# AudioPlayer.play("drink")
			
			queue_free() # La pozione sparisce
