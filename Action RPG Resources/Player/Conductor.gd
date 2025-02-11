extends Node

# Signals for when beats pass (4th, 8th, etc.)
signal quarter_passed(beat)
signal eighth_passed(beat, fract)
signal twelth_passed(beat, fract)
signal sixteenth_passed(beat, fract)

# Same as above signals but AudioServer.get_output_latency() seconds earlier
# (for audio scheduling)
signal quarter_will_pass(beat)
signal eighth_will_pass(beat, fract)
signal twelth_will_pass(beat, fract)
signal sixteenth_will_pass(beat, fract)

export var curr_beat: float = 0
export var curr_beat_without_latency: float = 0
export var bpm: float = 60
export var is_playing: bool = false
export var audio_offset_ms: int = 0
export var visual_offset_ms: int = 0

onready var player: AudioStreamPlayer = $Player

# Approximate latency for Godot 3.4 since get_output_latency() doesn't exist
var _cached_latency = AudioServer.get_time_to_next_mix()
var _num_beats_in_song: int = 0
var _prev_time_seconds: float = 0
var _loops: int = 0

var _quarter_passed_incrementor = BeatIncrementor.new(self, "quarter_passed")
var _eighth_passed_incrementor = BeatIncrementor.new(self, "eighth_passed", 2)
var _twelth_passed_incrementor = BeatIncrementor.new(self, "twelth_passed", 3)
var _sixteenth_passed_incrementor = BeatIncrementor.new(self, "sixteenth_passed", 4)
var _quarter_will_pass_incrementor = BeatIncrementor.new(self, "quarter_will_pass")
var _eighth_will_pass_incrementor = BeatIncrementor.new(self, "eighth_will_pass", 2)
var _twelth_will_pass_incrementor = BeatIncrementor.new(self, "twelth_will_pass", 3)
var _sixteenth_will_pass_incrementor = BeatIncrementor.new(self, "sixteenth_will_pass", 4)

class BeatIncrementor:
	var _fract_mod: int
	var _signal: String
	var _last_beat: int = -1
	var _last_fract: int
	var _conductor: Node  # Reference to Conductor

	func _init(conductor: Node, sig: String, fract_mod: int = 1):
		_fract_mod = fract_mod
		_signal = sig
		_last_fract = fract_mod - 1
		_conductor = conductor

	func increment_to(beat: int, fract: int = 0):
		while beat > _last_beat or fract > _last_fract:
			_last_fract += 1
			if _last_fract == _fract_mod:
				_last_beat += 1
				_last_fract = 0

			if _fract_mod == 1:
				_conductor.emit_signal(_signal, _last_beat)
			else:
				_conductor.emit_signal(_signal, _last_beat, _last_fract)

func _ready() -> void:
	self.play()

func play() -> void:
	_prev_time_seconds = -_cached_latency - 0.001
	curr_beat = _prev_time_seconds / 60 * bpm
	_loops = 0
	_num_beats_in_song = round(player.stream.get_length() / 60 * bpm)
	player.play()
	is_playing = true

func stop() -> void:
	player.stop()
	is_playing = false

func get_beat_time() -> float:
	return 60 / bpm

func _process(delta: float) -> void:
	if not is_playing:
		return

	var time_seconds = (
		player.get_playback_position()
		+ AudioServer.get_time_since_last_mix()
		- _cached_latency
		- audio_offset_ms / 1000.0)

	if not _is_valid_update(time_seconds):
		return

	if time_seconds - _prev_time_seconds < -5:
		_loops += 1
		_prev_time_seconds -= _num_beats_in_song / bpm * 60

	var beat = time_seconds / 60 * bpm
	var prev_beat = _prev_time_seconds / 60 * bpm

	beat += _loops * _num_beats_in_song
	prev_beat += _loops * _num_beats_in_song

	beat -= visual_offset_ms / 60000.0 * bpm
	prev_beat -= visual_offset_ms / 60000.0 * bpm

	curr_beat = beat
	if floor(beat) > floor(prev_beat):
		_quarter_passed_incrementor.increment_to(floor(beat))
	if floor(beat*2) > floor(prev_beat*2):
		_eighth_passed_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 2))
	if floor(beat*3) > floor(prev_beat*3):
		_twelth_passed_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 3))
	if floor(beat*4) > floor(prev_beat*4):
		_sixteenth_passed_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 4))

	beat += visual_offset_ms / 60000.0 * bpm
	prev_beat += visual_offset_ms / 60000.0 * bpm

	var latency_in_beats = _cached_latency / 60 * bpm
	beat += latency_in_beats
	prev_beat += latency_in_beats

	curr_beat_without_latency = beat
	if floor(beat) > floor(prev_beat):
		_quarter_will_pass_incrementor.increment_to(floor(beat))
	if floor(beat*2) > floor(prev_beat*2):
		_eighth_will_pass_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 2))
	if floor(beat*3) > floor(prev_beat*3):
		_twelth_will_pass_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 3))
	if floor(beat*4) > floor(prev_beat*4):
		_sixteenth_will_pass_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 4))

	_prev_time_seconds = time_seconds

func _is_valid_update(time_seconds: float) -> bool:
	return time_seconds < 1000 and (time_seconds > _prev_time_seconds or time_seconds - _prev_time_seconds < -5)
