class_name Player extends Area2D

const projectile: PackedScene = preload("res://Entities/projectile.tscn")
const projectile_sound: AudioStream = preload("res://Assets/Sound/laser.wav")
const death_sound: AudioStream = preload("res://Assets/Sound/explosion.wav")

const rotation_speed: float = 2 * PI
const acceleration: float = 400.0
const max_speed: float = 600.0

const max_invulnerable_time: float = 0.67
var invulnerable_time: float = 0.0

var fsm: LMSM = LMSM.new(self, "coasting")
var hit_fsm: LMSM = LMSM.new(self, "vulnerable")

var rotation_input: float
var acceleration_input: bool
var fire_input: bool

var current_acceleration: Vector2 = Vector2(0, 0)
var current_velocity: Vector2 = Vector2(0, 0)
var current_direction: Vector2 = Vector2(0, 0)

signal we_need_a_beep(sound: AudioStream, priority: int)
signal im_freaking_dead

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")
	fsm.add("coasting", {
		"enter" : func() -> void:
			sprite.play("Idle"),
		"step" : func(delta: float) -> void:
			rotation += rotation_input * rotation_speed * delta
			current_direction = Vector2.from_angle(self.rotation - PI/2)
			position += current_velocity * delta
			if fire_input:
				we_need_a_beep.emit(projectile_sound, 10)
				shoot()
			if Game.is_out_of_play(self):
				Game.wrap_screen(self)
	})
	fsm.add_child("coasting", "accelerating", {
		"enter" : func() -> void:
			sprite.play("Accelerating"),
		"step" : func(delta: float) -> void:
			current_acceleration = current_direction * acceleration * delta
			current_velocity += current_acceleration
			var speed: float = clamp(current_velocity.length(), 0, max_speed)
			current_velocity = current_velocity.normalized() * speed
			fsm.inherit([delta])
	})
	fsm.add_transition("t_movement", ["coasting"], "accelerating", func()->bool:return acceleration_input)
	fsm.add_transition("t_movement", ["accelerating"], "coasting", func()->bool:return !acceleration_input)

	hit_fsm.add("vulnerable", {})
	hit_fsm.add("invulnerable", {
		"step" : func(delta: float) -> void:
			invulnerable_time -= delta
			if invulnerable_time >= 0:
				modulate.a = sin(invulnerable_time*16*PI)
			else:
				modulate.a = 1.0
	})
	hit_fsm.add_transition("t_vulnerability", ["vulnerable"], "invulnerable", func()->bool: return invulnerable_time > 0)
	hit_fsm.add_transition("t_vulnerability", ["invulnerable"], "vulnerable", func()->bool: return invulnerable_time <= 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	check_input()
	fsm.event("step", [delta])
	hit_fsm.event("step", [delta])
	fsm.trigger("t_movement")
	hit_fsm.trigger("t_vulnerability")

func check_input() -> void:
	rotation_input = Input.get_axis("ui_left", "ui_right")
	acceleration_input = Input.is_action_pressed("ui_up")
	fire_input = Input.is_action_just_pressed("fire")
	
func shoot() -> void:
	var new_projectile: Projectile = projectile.instantiate()
	new_projectile.position = self.position + self.current_direction * 16
	new_projectile.direction = self.current_direction
	new_projectile.fired_by = self
	$"..".add_child(new_projectile)

func reset() -> void:
	queue_free()
	
func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid && invulnerable_time <= 0:
		health_component.decrease_health(1)
		we_need_a_beep.emit(death_sound, 10)
		invulnerable_time = max_invulnerable_time
	
	if area is Projectile && invulnerable_time <= 0:
		if (area as Projectile).fired_by != self:
			health_component.decrease_health(1)
			we_need_a_beep.emit(death_sound, 10)
			invulnerable_time = max_invulnerable_time
			area.queue_free()

func _on_health_component_health_depleted() -> void:
	im_freaking_dead.emit()
	health_component.reset()
