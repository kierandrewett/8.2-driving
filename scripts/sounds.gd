extends Node

var sounds_playing = {}

func play_sound(path, node = get_parent(), volume = Globals.volume, pitch = 1, sink = "master") -> AudioStreamPlayer:
	var resource = ResourceLoader.load(path)
	
	var player = AudioStreamPlayer.new()
	node.add_child(player)
	
	player.set_stream(resource)
	player.volume_db = volume
	player.pitch_scale = pitch

	player.play()

	if !sounds_playing.has(sink):
		sounds_playing[sink] = {}
	sounds_playing[sink][player.get_instance_id()] = player

	player.finished.connect(func ():
		player.queue_free()
		if sounds_playing[sink].has(player.get_instance_id()):
			sounds_playing[sink].erase(player.get_instance_id())
	)
	
	return player

func stop_all_sounds(ignore_sinks = []):
	for key in sounds_playing.keys():
		if ignore_sinks.has(key):
			continue
		
		for sound_key in sounds_playing.get(key).keys():
			sounds_playing[key][sound_key].stop()
			sounds_playing[key][sound_key].queue_free()
			sounds_playing[key].erase(sound_key)
		
func stop_some_sounds(sinks = []):
	for key in sounds_playing.keys():
		if !sinks.has(key):
			continue
		
		for sound_key in sounds_playing.get(key).keys():
			sounds_playing[key][sound_key].stop()
			sounds_playing[key][sound_key].queue_free()
			sounds_playing[key].erase(sound_key)
			
func set_paused_sounds(paused = false, ignore_sinks = ["master"]):
	for key in sounds_playing.keys():
		if ignore_sinks.has(key):
			continue
		
		for sound_key in sounds_playing.get(key).keys():
			sounds_playing[key][sound_key].stream_paused = paused
			
func set_sink_volume(name, volume):
	if !sounds_playing.has(name):
		print("Sink '%s' not found!" % [name])
		return
	
	for key in sounds_playing[name].keys():
		print(volume)
		sounds_playing[name][key].volume_db = volume
			
func get_all_sounds_in_sink(name):
	return sounds_playing[name]
