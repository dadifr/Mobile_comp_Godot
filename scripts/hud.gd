extends CanvasLayer

#riferimenti alle vite
@export var full_heart_texture: Texture2D 
@export var half_heart_texture: Texture2D 
@export var empty_heart_texture: Texture2D 

# Prendo la lista dei cuori
@onready var hearts = $MarginContainer/StatsContainer/HBoxContainer.get_children()

# Riferimenti alle Label
@onready var coin_label = $StatsContainer/CoinRow/CoinLabel
@onready var bomb_label = $StatsContainer/BombRow/BombLabel

# Funzione per aggiornare le monete
func update_coins(amount):
	coin_label.text = "x " + str(amount)


# Funzione per aggiornare le bombe
func update_bombs(amount):
	bomb_label.text = "x " + str(amount)


func update_life(amount):
	# amount è la vita attuale (es. 6, 5, 4...)
	
	# Cicliamo su ogni cuore (indice 0, 1, 2)
	for i in range(hearts.size()):
		var heart_value = (i + 1) * 2  # Valore di questo cuore (2, 4, 6)
		
		if amount >= heart_value:
			# Il giocatore ha abbastanza vita per riempire questo cuore
			hearts[i].texture = full_heart_texture
			hearts[i].visible = true
			
		elif amount == heart_value - 1:
			# Il giocatore ha 1 punto in meno del valore di questo cuore -> MEZZO
			hearts[i].texture = half_heart_texture
			hearts[i].visible = true
			
		else:
			# Il cuore è vuoto
			if empty_heart_texture:
				hearts[i].texture = empty_heart_texture
			else:
				# Se non hai sprite vuoti, nascondiamo il cuore
				hearts[i].visible = false
