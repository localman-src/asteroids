class_name LargeAsteroid extends Asteroid

@onready var particles: CPUParticles2D = $HitParticles
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	size = Asteroid.SIZE.large
	point_value = 100

