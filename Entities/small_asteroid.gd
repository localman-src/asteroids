class_name SmallAsteroid extends Asteroid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	size = Asteroid.SIZE.small

func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		destroyed.emit(1000, position, Asteroid.SIZE.small)
		we_need_a_beep.emit(explosion, 3)
		area.queue_free()
		queue_free()
