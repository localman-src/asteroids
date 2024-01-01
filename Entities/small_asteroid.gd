class_name SmallAsteroid extends Asteroid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	size = Asteroid.SIZE.small
	point_value = 1000
