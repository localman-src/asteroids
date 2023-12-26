class_name SFXPlayer extends Node

var max_channels: int = 6
var channels: Array[PriorityAudioStreamPlayer] = []

func _ready() -> void:
	for i: int in max_channels:
		var new_audio_stream_player: PriorityAudioStreamPlayer = PriorityAudioStreamPlayer.new()
		new_audio_stream_player.bus = &"SFX"
		add_child(new_audio_stream_player)
		channels.push_back(new_audio_stream_player)
		
func _on_sound_request(sound: AudioStream, priority: int) -> void:
	var open_stream_player: PriorityAudioStreamPlayer = find_open_stream_player()
	if open_stream_player != null:
		open_stream_player.stream = sound
		open_stream_player.priority = priority
		open_stream_player.play()
	else:
		var low_priority_player: PriorityAudioStreamPlayer = channels[channels.size() - 1]
		if low_priority_player.priority < priority:
			low_priority_player.stream = sound
			low_priority_player.priority = priority
			low_priority_player.play()
	sort_channels()
	
func sort_channels() -> void:
	channels.sort_custom(func(a: PriorityAudioStreamPlayer, b: PriorityAudioStreamPlayer) -> bool: return a.priority > b.priority)

func find_open_stream_player() -> PriorityAudioStreamPlayer:
	for channel: PriorityAudioStreamPlayer in channels:
		if !channel.playing:
			return channel
	return null
