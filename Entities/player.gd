class_name Player extends Area2D

const projectile: PackedScene = preload("res://Entities/projectile.tscn")
const projectile_sound: AudioStream = preload("res://Assets/Sound/laser.wav")

const rotation_speed: float = 2 * PI
const acceleration: float = 400.0
const max_speed: float = 600.0

var current_acceleration: Vector2 = Vector2(0, 0)
var current_velocity: Vector2 = Vector2(0, 0)
var current_direction: Vector2 = Vector2(0, 0)

signal we_need_a_beep(sound: AudioStream, priority: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rotation_input = Input.get_axis("ui_left", "ui_right")
	var acceleration_input = Input.is_action_pressed("ui_up")
	var fire = Input.is_action_just_pressed("fire")
	self.rotation += rotation_input * rotation_speed * delta
	self.current_direction = Vector2.from_angle(self.rotation - PI/2)
	if acceleration_input:
		self.sprite.play("Accelerating")
		self.current_acceleration = current_direction * acceleration * delta
		self.current_velocity += current_acceleration
		var speed: float = clamp(current_velocity.length(), 0, max_speed)
		self.current_velocity = current_velocity.normalized() * speed
	if !acceleration_input:
		self.sprite.play("Idle")
	self.position += current_velocity * delta
	
	if fire:
		we_need_a_beep.emit(projectile_sound, 10)
		shoot()
		
	if Game.is_out_of_play(self):
		if position.x < 0:
			position.x = Game.ARENA_WIDTH
		if position.x > Game.ARENA_WIDTH:
			position.x = 0
		if position.y < 0:
			position.y = Game.ARENA_HEIGHT
		if position.y > Game.ARENA_HEIGHT:
			position.y = 0

func shoot() -> void:
	var new_projectile: Projectile = projectile.instantiate()
	new_projectile.position = self.position + self.current_direction * 16
	new_projectile.direction = self.current_direction
	$"..".add_child(new_projectile)

func reset() -> void:
	self.position = Game.ARENA_CENTER
