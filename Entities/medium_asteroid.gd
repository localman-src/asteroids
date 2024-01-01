class_name MediumAsteroid extends Asteroid

func _ready() -> void:
	super()
	size = Asteroid.SIZE.medium
	point_value = 500
