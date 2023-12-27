class_name Player extends Area2D

enum state {
	normal,
	hit_invuln
}
const projectile: PackedScene = preload("res://Entities/projectile.tscn")
const projectile_sound: AudioStream = preload("res://Assets/Sound/laser.wav")
const death_sound: AudioStream = preload("res://Assets/Sound/explosion.wav")

const rotation_speed: float = 2 * PI
const acceleration: float = 400.0
const max_speed: float = 600.0

const invulnerable_time: float = 0.67

var current_acceleration: Vector2 = Vector2(0, 0)
var current_velocity: Vector2 = Vector2(0, 0)
var current_direction: Vector2 = Vector2(0, 0)
var current_state: Player.state = Player.state.normal
var invuln_elapsed: float = 0.0

signal we_need_a_beep(sound: AudioStream, priority: int)
signal im_freaking_dead

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rotation_input: float = Input.get_axis("ui_left", "ui_right")
	var acceleration_input: bool = Input.is_action_pressed("ui_up")
	var fire: bool = Input.is_action_just_pressed("fire")
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
		Game.wrap_screen(self)
	
	if current_state == Player.state.hit_invuln:
		modulate.a = cos(invuln_elapsed * 16 * PI * delta)
		invuln_elapsed += 1

func shoot() -> void:
	var new_projectile: Projectile = projectile.instantiate()
	new_projectile.position = self.position + self.current_direction * 16
	new_projectile.direction = self.current_direction
	$"..".add_child(new_projectile)

func reset() -> void:
	queue_free()

func enter_hit_invuln_state() -> void:
	current_state = Player.state.hit_invuln
	invuln_elapsed = 0.0
	get_tree().create_timer(invulnerable_time).timeout.connect(enter_normal_state)

func enter_normal_state() -> void:
	current_state = Player.state.normal
	modulate.a = 1.0
	
func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid && current_state != Player.state.hit_invuln:
		health_component.decrease_health(1)
		we_need_a_beep.emit(death_sound, 10)
		enter_hit_invuln_state()

func _on_health_component_health_depleted() -> void:
	im_freaking_dead.emit()
	health_component.reset()
	
