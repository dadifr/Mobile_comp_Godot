extends CanvasLayer

func _on_riprova_pressed() -> void:
	# 1. Ricarica il gioco
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	
	# 2. Distruggi questa schermata di Game Over!
	self.queue_free()
# Tasto RIPROVA (Ricarica veloce stesso personaggio)

func _on_menu_pressed() -> void:
	
	get_tree().change_scene_to_file("res://scenes/character_selection.tscn")
	
	self.queue_free()



func _on_esci_pressed() -> void:
	# Chiude l'applicazione immediatamente
	get_tree().quit()
