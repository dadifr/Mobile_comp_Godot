extends AudioStreamPlayer

# Qui trascinerai i tuoi file audio nell'Inspector
@export var normal_music: AudioStream
@export var boss_music: AudioStream

# Questa variabile ricorda il volume scelto dal giocatore nelle impostazioni
var current_user_volume = 0.0

func _ready():
	# Salva il volume iniziale e fa partire la musica normale
	current_user_volume = volume_db
	if normal_music:
		stream = normal_music
		play()

# Funzione per passare alla musica del boss con dissolvenza
func play_boss_theme():
	if stream == boss_music: return # Evita di riavviarla se sta già suonando
	_crossfade_to(boss_music)

# Funzione per tornare alla musica normale con dissolvenza
func play_normal_theme():
	if stream == normal_music: return
	_crossfade_to(normal_music)

# La "Magia" della dissolvenza
func _crossfade_to(new_track: AudioStream):
	current_user_volume = volume_db # Ricorda il volume attuale
	
	var tween = create_tween()
	# 1. Abbassa il volume fino a zero (-80 db) in 1 secondo
	tween.tween_property(self, "volume_db", -80.0, 1.0)
	
	# 2. Cambia la traccia e falle fare play
	tween.tween_callback(func():
		stream = new_track
		play()
	)
	
	# 3. Riporta il volume al livello originale in 1 secondo
	tween.tween_property(self, "volume_db", current_user_volume, 1.0)
