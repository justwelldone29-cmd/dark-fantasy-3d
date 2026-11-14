extends Camera3D
## Смещение проекции не меняет орбиту камеры и вращение от свайпа.
@export var maximum_strength := .07
@export var frequency := 32.0
var _remaining := 0.0
var _duration := 0.0
var _strength := 0.0
var _elapsed := 0.0
var _base := Vector2.ZERO
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
	set_process(false)

func shake(strength: float, duration := .12) -> void:
	if strength <= 0 or duration <= 0: return
	if _remaining <= 0:
		_base = Vector2(h_offset, v_offset)
		_elapsed = 0.0
	_strength = minf(maxf(_strength, strength), maximum_strength)
	_duration = maxf(_remaining, duration)
	_remaining = _duration
	set_process(true)

func _process(delta: float) -> void:
	_remaining = maxf(0, _remaining - delta)
	if _remaining <= 0:
		h_offset = _base.x
		v_offset = _base.y
		_strength = 0.0
		set_process(false)
		return
	_elapsed += delta * frequency
	var amplitude := _strength * pow(_remaining / _duration, 2)
	h_offset = _base.x + _noise.get_noise_1d(_elapsed) * amplitude
	v_offset = _base.y + _noise.get_noise_1d(_elapsed + 100) * amplitude
