extends CanvasLayer

func _on_riprova_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	
	self.queue_free()

func _on_menu_pressed() -> void:
	
	get_tree().change_scene_to_file("res://scenes/character_selection.tscn")
	
	self.queue_free()



func _on_esci_pressed() -> void:
	get_tree().quit()
