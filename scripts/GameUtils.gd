extends Node

func safe_spawn(scene_to_spawn: PackedScene, parent_node: Node, position: Vector2):
	if scene_to_spawn == null:
		printerr("ERRORE: Tentativo di spawnare una scena NULL!")
		return
	
	if not is_instance_valid(parent_node):
		printerr("ERRORE: Il genitore dove spawnare non esiste più.")
		return

	var instance = scene_to_spawn.instantiate()
	instance.global_position = position
	
	parent_node.call_deferred("add_child", instance)

func get_player_safe(caller_node: Node) -> Node:
	var players = caller_node.get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	printerr("ERRORE CRITICO: Player non trovato nel gruppo!")
	return null
