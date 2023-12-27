class_name AsteroidSpawner extends Node

var large_asteroid: PackedScene = preload("res://Entities/large_asteroid.tscn")
var medium_asteroid: PackedScene = preload("res://Entities/medium_asteroid.tscn")
var small_asteroid: PackedScene = preload("res://Entities/small_asteroid.tscn")

var split_count: int = 3

func spawn_large_asteroid(_position: Vector2, _direction: Vector2) -> LargeAsteroid:
	var new_asteroid: LargeAsteroid = large_asteroid.instantiate()
	new_asteroid.position = _position
	new_asteroid.initial_direction = _direction
	return new_asteroid
	
func spawn_medium_asteroid(_position: Vector2, _direction: Vector2) -> MediumAsteroid:
	var new_asteroid: MediumAsteroid = medium_asteroid.instantiate()
	new_asteroid.position = _position
	new_asteroid.initial_direction = _direction
	return new_asteroid

func spawn_small_asteroid(_position: Vector2, _direction: Vector2) -> SmallAsteroid:
	var new_asteroid: SmallAsteroid = small_asteroid.instantiate()
	new_asteroid.position = _position
	new_asteroid.initial_direction = _direction
	return new_asteroid

func asteroid_burst(_position: Vector2, _size: Asteroid.SIZE) -> Array[Asteroid]:
	var arc_length: float = 2 * PI / split_count
	var angle_offset: float = randf_range(0, arc_length / 2)
	var asteroids: Array[Asteroid] = []
	for i: int in split_count:
		match _size:
			Asteroid.SIZE.medium:
				asteroids.push_back(spawn_medium_asteroid(_position, Vector2.from_angle(i * arc_length + angle_offset)))
			Asteroid.SIZE.small:
				asteroids.push_back(spawn_small_asteroid(_position, Vector2.from_angle(i * arc_length + angle_offset)))
	return asteroids
