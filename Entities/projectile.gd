class_name Projectile extends Area2D

var max_speed: float = 1000.0
var direction: Vector2 = Vector2.UP

@onready var collision: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")
	get_tree().create_timer(1.5).timeout.connect(_on_lifetime_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += direction * max_speed * delta
	if Game.is_out_of_play(self):
		if position.x < 0:
			position.x = Game.ARENA_WIDTH
		if position.x > Game.ARENA_WIDTH:
			position.x = 0
		if position.y < 0:
			position.y = Game.ARENA_HEIGHT
		if position.y > Game.ARENA_HEIGHT:
			position.y = 0

func _on_lifetime_timeout() -> void:
	queue_free()

func reset() -> void:
	queue_free()
