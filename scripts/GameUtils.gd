extends Node

# Funzione sicura per spawnare oggetti
# Esempio d'uso: Utils.safe_spawn(coin_scene, self, global_position)
func safe_spawn(scene_to_spawn: PackedScene, parent_node: Node, position: Vector2):
	# 1. Controllo se la scena esiste
	if scene_to_spawn == null:
		printerr("ERRORE: Tentativo di spawnare una scena NULL!")
		return
	
	# 2. Controllo se il genitore esiste
	if not is_instance_valid(parent_node):
		printerr("ERRORE: Il genitore dove spawnare non esiste più.")
		return

	# 3. Procediamo in sicurezza
	var instance = scene_to_spawn.instantiate()
	instance.global_position = position
	
	# 4. Usiamo call_deferred per evitare errori fisici
	parent_node.call_deferred("add_child", instance)

# Funzione sicura per cercare il Player ovunque
func get_player_safe(caller_node: Node) -> Node:
	# Metodo 1: Cerca nel gruppo
	var players = caller_node.get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Nessun player trovato
	printerr("ERRORE CRITICO: Player non trovato nel gruppo!")
	return null
