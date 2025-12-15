extends CanvasLayer

func _on_riprova_pressed() -> void:
	# 1. Ricarica il gioco
	get_tree().reload_current_scene()
	
	# 2. Distruggi questa schermata di Game Over!
	self.queue_free()
	



func _on_esci_pressed() -> void:
	# Chiude l'applicazione immediatamente
	get_tree().quit()
