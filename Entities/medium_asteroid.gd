class_name MediumAsteroid extends Asteroid

func _ready() -> void:
	super()
	size = Asteroid.SIZE.medium


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		destroyed.emit(500, position, Asteroid.SIZE.medium)
		we_need_a_beep.emit(explosion, 3)
		area.queue_free()
		queue_free()
