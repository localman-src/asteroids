class_name LargeAsteroid extends Asteroid

@onready var particles: CPUParticles2D = $HitParticles
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	size = Asteroid.SIZE.large

func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		destroyed.emit(100, position, Asteroid.SIZE.large)
		we_need_a_beep.emit(explosion, 3)
		area.queue_free()
		queue_free()
		
