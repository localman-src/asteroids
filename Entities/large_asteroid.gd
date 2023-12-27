class_name LargeAsteroid extends Asteroid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	size = Asteroid.SIZE.large

func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		destroyed.emit(100, position, Asteroid.SIZE.large)
		area.queue_free()
		queue_free()
		
