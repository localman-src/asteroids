class_name LargeAsteroid extends Asteroid

var medium_asteroid: PackedScene = preload("res://Entities/medium_asteroid.tscn")
var split_count: int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	size = Asteroid.SIZE.large

func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		destroyed.emit(100, position, Asteroid.SIZE.large)
		queue_free()
