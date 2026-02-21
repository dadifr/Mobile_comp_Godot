extends Node2D

var room_started = false
var room_cleared = false

func _ready():
	$Detector.body_entered.connect(_on_player_entered)
	open_all_doors()

func _on_player_entered(body):
	if room_cleared or room_started:
		return
	
	if body.is_in_group("player"):
		start_battle()

func start_battle():
	var enemy_count = count_enemies()

	if enemy_count > 0:
		print("Battaglia Iniziata! Nemici: ", enemy_count)
		room_started = true
		close_all_doors()

		var is_boss_room = false 

		for child in $Enemies.get_children():
			if is_instance_valid(child):
				
				if child.is_in_group("boss"):
					is_boss_room = true 
					if child.has_method("activate_boss"):
						child.activate_boss()
						
				elif child.has_method("activate"):
					child.activate()

		if is_boss_room:
			print("Suona la musica del Boss!")
			OST.play_boss_theme()
		else:
			print("Suona la musica da combattimento normale.")
			
	else:
		room_cleared = true

func _process(_delta):
	if room_started and !room_cleared:
		if count_enemies() == 0:
			win_battle()

func count_enemies():
	var count = 0
	for child in $Enemies.get_children():
		if not is_instance_valid(child):
			continue
		if child.is_queued_for_deletion():
			continue
		
		if child.is_in_group("enemies") or child.is_in_group("boss"):
			count += 1
			
	return count

func win_battle():
	print("Stanza pulita! Cambio musica.")
	room_cleared = true
	room_started = false 
	open_all_doors()
	
	if OST.has_method("play_normal_theme"):
		OST.play_normal_theme()

func close_all_doors():
	for door in $Doors.get_children():
		if door.has_method("close"):
			door.close()

func open_all_doors():
	for door in $Doors.get_children():
		if door.has_method("open"):
			door.open()
