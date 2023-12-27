class_name Asteroid extends Area2D

enum SIZE {
	large,
	medium,
	small
}

const SPEED: float = 75.0

var size: Asteroid.SIZE
var initial_direction: Vector2 = Vector2.from_angle(randf_range(0, 2 * PI))
var initial_rotation: float = randf_range(-PI / 3, PI / 3)

signal destroyed(points: int, pos: Vector2, _size: Asteroid.SIZE)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation += initial_rotation * delta
	position += initial_direction * SPEED * delta
	
	if Game.is_out_of_play(self):
		Game.wrap_screen(self)

func reset() -> void:
	queue_free()

