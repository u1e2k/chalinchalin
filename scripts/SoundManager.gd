class_name SoundManager
extends RefCounted

## High-performance Procedural Arcade Sound Manager for Godot 4.x
## Caches synthesized audio streams and plays them on-demand directly via SceneTree.

enum SfxType {
	COIN_DROP,
	COIN_WIN,
	COIN_LOSE,
	COIN_CLINK,
	TILT_SHAKE,
	FEVER_START,
	GAME_OVER,
	UI_FOCUS,
	UI_SELECT,
	BUTTON_CLICK,
	SLOT_CHECKER,
	SLOT_STOP,
	SLOT_WIN,
	COIN_SHOWER
}

static var _cached_wavs: Dictionary = {}

static func play(type: SfxType) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return
		
	if not _cached_wavs.has(type):
		_cached_wavs[type] = _generate_stream(type)
		
	var stream: AudioStreamWAV = _cached_wavs[type]
	if not stream:
		return
		
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(player)
	player.play()
	player.finished.connect(func(): player.queue_free())

static func _generate_stream(type: SfxType) -> AudioStreamWAV:
	var sample_rate := 22050
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var buffer := PackedByteArray()
	var duration := 0.2
	
	match type:
		SfxType.COIN_DROP:
			# Metallic high-pitch ping descending
			duration = 0.18
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 1800.0 - 600.0 * (float(i) / samples)
				var env := exp(-t * 18.0)
				var wave := sin(TAU * freq * t) + 0.4 * sin(TAU * freq * 2.3 * t)
				var sample_val := int(clampf(wave * env * 0.7, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)
				
		SfxType.COIN_WIN:
			# Joyful two-tone chime
			duration = 0.35
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 1046.5 if t < 0.12 else 1318.5
				if t > 0.22:
					freq = 2093.0
				var env := exp(-fmod(t, 0.12) * 12.0)
				var wave := sin(TAU * freq * t) + 0.3 * sin(TAU * (freq * 2.0) * t)
				var sample_val := int(clampf(wave * env * 0.7, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)
				
		SfxType.COIN_LOSE:
			# Low descending thud / lost coin
			duration = 0.25
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := maxf(300.0 - 200.0 * (float(i) / samples), 60.0)
				var env := exp(-t * 10.0)
				var wave := sin(TAU * freq * t)
				var sample_val := int(clampf(wave * env * 0.6, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)
				
		SfxType.COIN_CLINK:
			# Short metallic clink
			duration = 0.08
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 2400.0 + randf_range(-100.0, 100.0)
				var env := exp(-t * 40.0)
				var wave := sin(TAU * freq * t) + 0.5 * sin(TAU * freq * 1.7 * t)
				var sample_val := int(clampf(wave * env * 0.5, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)
				
		SfxType.TILT_SHAKE:
			# Heavy mechanical shaker rumbling
			duration = 0.45
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var noise := randf_range(-1.0, 1.0) * 0.5
				var freq := 80.0 + sin(t * 30.0) * 30.0
				var env := sin(t / duration * PI)
				var wave := sin(TAU * freq * t) + noise
				var sample_val := int(clampf(wave * env * 0.8, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.FEVER_START:
			# Arpeggio fanfare
			duration = 0.6
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			var notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
			for i in range(samples):
				var t := float(i) / sample_rate
				var note_idx := clampi(int(t / 0.09), 0, notes.size() - 1)
				var freq: float = notes[note_idx]
				var env := exp(-fmod(t, 0.09) * 14.0)
				var wave := sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)
				var sample_val := int(clampf(wave * env * 0.7, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)
				
		SfxType.GAME_OVER:
			# Dramatic falling melody
			duration = 0.8
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			var notes := [587.33, 554.37, 523.25, 466.16]
			for i in range(samples):
				var t := float(i) / sample_rate
				var note_idx := clampi(int(t / 0.18), 0, notes.size() - 1)
				var freq: float = notes[note_idx]
				var env := exp(-fmod(t, 0.18) * 6.0)
				var wave := sin(TAU * freq * t)
				var sample_val := int(clampf(wave * env * 0.7, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.UI_FOCUS:
			# Crisp tick
			duration = 0.05
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 880.0
				var env := exp(-t * 70.0)
				var wave := sin(TAU * freq * t)
				var sample_val := int(clampf(wave * env * 0.4, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.UI_SELECT:
			# Ascending blip
			duration = 0.12
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 600.0 + 800.0 * (float(i) / samples)
				var env := exp(-t * 20.0)
				var wave := sin(TAU * freq * t)
				var sample_val := int(clampf(wave * env * 0.6, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.BUTTON_CLICK:
			duration = 0.06
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 1200.0
				var env := exp(-t * 50.0)
				var wave := sin(TAU * freq * t)
				var sample_val := int(clampf(wave * env * 0.5, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.SLOT_CHECKER:
			# Bright arcade chime for passing checker (D6 -> A6)
			duration = 0.22
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 1174.66 if t < 0.10 else 1760.0
				var env := exp(-fmod(t, 0.10) * 16.0)
				var wave := sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)
				var sample_val := int(clampf(wave * env * 0.65, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.SLOT_STOP:
			# Mechanical reel click / clunk
			duration = 0.08
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 900.0 - 400.0 * (float(i) / samples)
				var env := exp(-t * 45.0)
				var wave := sin(TAU * freq * t) + 0.4 * (randf() * 2.0 - 1.0)
				var sample_val := int(clampf(wave * env * 0.6, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.SLOT_WIN:
			# Grand fanfare for jackpot/match
			duration = 0.75
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			var notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 2093.00]
			for i in range(samples):
				var t := float(i) / sample_rate
				var note_idx := clampi(int(t / 0.11), 0, notes.size() - 1)
				var freq: float = notes[note_idx]
				var env := exp(-fmod(t, 0.11) * 10.0)
				var wave := sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 2.0 * t)
				var sample_val := int(clampf(wave * env * 0.75, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

		SfxType.COIN_SHOWER:
			# Rapid arcade coins rattling / direct payout rain
			duration = 0.12
			var samples := int(sample_rate * duration)
			buffer.resize(samples * 2)
			for i in range(samples):
				var t := float(i) / sample_rate
				var freq := 2000.0 + sin(t * 120.0) * 800.0
				var env := exp(-t * 25.0)
				var wave := sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.5 * t)
				var sample_val := int(clampf(wave * env * 0.5, -1.0, 1.0) * 32767.0)
				buffer.encode_s16(i * 2, sample_val)

	wav.data = buffer
	return wav
