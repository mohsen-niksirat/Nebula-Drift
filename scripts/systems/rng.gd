extends RefCounted
## RNG — seeded random-number generator wrapper.
##
## Purpose: provide a deterministic RNG whose seed survives across a run
## (so enemy spawn positions / salvage offers are reproducible) and whose
## state is isolated from any other randomness in the game.
##
## Usage:
##     var rng = Rng.new()                 # unseeded (system random)
##     var rng = Rng.new(12345)            # fixed seed -> reproducible
##     var value = rng.randi_range(1, 10)
##     var pick = rng.pick(my_list)
##     rng.seed = new_seed                 # advance/re-seed as needed

var _rng: RandomNumberGenerator

func _init(seed: int = -1) -> void:
	_rng = RandomNumberGenerator.new()
	if seed >= 0:
		_rng.seed = seed
		_rng.randomize()

## Reset to the original constructor seed.
func reset() -> void:
	_rng.seed = seed

## Current seed (read-only view).
func get_seed() -> int:
	return _rng.seed

func randomize() -> void:
	_rng.randomize()

func _randf() -> float:
	return _rng.randf()

func _randi() -> int:
	return _rng.randi()

func randf() -> float:
	"""Uniform float in [0, 1[."""
	return _rng.randf()

func randf_range(a: float, b: float) -> float:
	return _rng.randf_range(a, b)

func randi() -> int:
	return _rng.randi()

func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)

func pick<T>(items: Array[T]) -> T:
	"""Return a uniformly chosen item."""
	assert(items.size() > 0, "Cannot pick from an empty array.")
	return items[randi_range(0, items.size() - 1)]

func shuffle<T>(items: Array[T]) -> Array[T]:
	"""Return a shuffled copy of the array."""
	var copy = Array(items)
	var n = copy.size()
	for i in range(n - 1, 0, -1):
		var j = randi_range(0, i)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy
