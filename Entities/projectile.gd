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
		Game.wrap_screen(self)

func _on_lifetime_timeout() -> void:
	queue_free()

func reset() -> void:
	queue_free()
