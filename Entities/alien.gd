class_name Alien extends Area2D

const projectile: PackedScene = preload("res://Entities/projectile.tscn")
const projectile_sound: AudioStream = preload("res://Assets/Sound/laser.wav")
const death_sound: AudioStream = preload("res://Assets/Sound/explosion.wav")

var fsm: LMSM = LMSM.new(self, "approaching")
var target: Vector2
var speed: float = 400
var dir: Vector2
var arrived: bool
var shoot_dir: Vector2
var aim_delay: float = 1.0
var point_value: int = 10000

signal we_need_a_beep(_sound: AudioStream, priority: int)
signal alien_destroyed(_points: int, _pos: Vector2)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dimensions: RectangleShape2D = ($CollisionShape2D as CollisionShape2D).shape

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")
	fsm.add("approaching", {
		"enter" : func() -> void:
			sprite.play("default")
			dir = (target - position).normalized(),
		"step" : func(delta: float) -> void:
			position += dir * speed * delta
			has_arrived(delta)
	})
	fsm.add("attacking", {
		"enter" : func() -> void:
			var player: Player = $"../Player"
			shoot_dir = (player.position - position).normalized()
			get_tree().create_timer(aim_delay).timeout.connect(shoot)
	})
	fsm.add("retreating", {
		"step" : func(delta: float) -> void:
			position += dir * speed * delta
			if Game.is_out_of_play(self):
				queue_free()
	})
	
	fsm.add_transition("t_arrived", ["approaching"], "attacking", func()->bool: return arrived) 
	fsm.add_transition("t_retreat", ["attacking"], "retreating")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fsm.event("step", [delta])
	fsm.trigger("t_arrived")
	
func shoot() -> void:
	we_need_a_beep.emit(projectile_sound, 10)
	var new_projectile: Projectile = projectile.instantiate()
	new_projectile.position = position + shoot_dir * 16
	new_projectile.direction = shoot_dir
	new_projectile.fired_by = self
	new_projectile.lifetime = .667
	$"..".add_child(new_projectile)
	fsm.trigger("t_retreat")

func has_arrived(delta: float) -> void:
	arrived = (target - position).length() < speed * delta

func reset() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		we_need_a_beep.emit(death_sound, 5)
		alien_destroyed.emit(point_value, position)
		queue_free()
