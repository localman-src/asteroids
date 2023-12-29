class_name Player extends Area2D

enum state {
	normal,
	hit_invuln,
	respawning
}

const projectile: PackedScene = preload("res://Entities/projectile.tscn")
const projectile_sound: AudioStream = preload("res://Assets/Sound/laser.wav")
const death_sound: AudioStream = preload("res://Assets/Sound/explosion.wav")

const rotation_speed: float = 2 * PI
const acceleration: float = 400.0
const max_speed: float = 600.0

const invulnerable_time: float = 0.67

var fsm: LMSM = LMSM.new(self, "normal")
var rotation_input: float
var acceleration_input: bool
var fire_input: bool

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
	fsm.add("normal", {
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
	fsm.add_child("normal", "accelerating", {
		"enter" : func() -> void:
			sprite.play("Accelerating"),
		"step" : func(delta: float) -> void:
			current_acceleration = current_direction * acceleration * delta
			current_velocity += current_acceleration
			var speed: float = clamp(current_velocity.length(), 0, max_speed)
			current_velocity = current_velocity.normalized() * speed
			fsm.inherit([delta])
	})
	
	fsm.add_child("normal", "normal_hit_invuln", {
		"enter" : func() -> void:
			fsm.inherit(),
		"step" : func(delta: float) -> void:
			fsm.inherit([delta])
			modulate.a = cos(invuln_elapsed * 16 * PI)
			invuln_elapsed += delta
	})
	
	fsm.add_child("accelerating", "accelerating_hit_invuln", {
		"enter" : func() -> void:
			fsm.inherit(),
		"step" : func(delta: float) -> void:
			fsm.inherit([delta])
			modulate.a = cos(invuln_elapsed * 16 * PI)
			invuln_elapsed += delta
	})
	
	fsm.add_transition("accelerate", "normal", "accelerating", func()->bool:return acceleration_input)
	fsm.add_transition("stop_accelerating", "accelerating", "normal", func()->bool:return !acceleration_input)
	fsm.add_transition("t_hit_invuln", "normal", "normal_hit_invuln", func()->bool:return true, func()->void: 
		fsm.inherit()
		invuln_elapsed = 0.0)
	fsm.add_transition("t_hit_invuln", "accelerating", "accelerating_hit_invuln", func()->bool:return true, func()->void: 
		fsm.inherit()
		invuln_elapsed = 0.0)
	fsm.add_transition("accelerate_hit_invuln", "normal_hit_invuln", "accelerating_hit_invuln", func()->bool:return acceleration_input)
	fsm.add_transition("stop_accelerating_hit_invuln", "accelerating_hit_invuln", "normal_hit_invuln", func()->bool:return !acceleration_input)
	fsm.add_transition("t_vulnerable", "normal_hit_invuln", "normal", func()->bool:return true, func()->void: modulate.a = 1.0)
	fsm.add_transition("t_vulnerable", "accelerating_hit_invuln", "accelerating", func()->bool:return true, func()->void: modulate.a = 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	check_input()
	fsm.step([delta])
	fsm.trigger("accelerate")
	fsm.trigger("stop_accelerating")
	
	#var rotation_input: float = Input.get_axis("ui_left", "ui_right")
	#var acceleration_input: bool = Input.is_action_pressed("ui_up")
	#var fire: bool = Input.is_action_just_pressed("fire")
	#self.rotation += rotation_input * rotation_speed * delta
	#self.current_direction = Vector2.from_angle(self.rotation - PI/2)
	#if acceleration_input:
		#self.sprite.play("Accelerating")
		#self.current_acceleration = current_direction * acceleration * delta
		#self.current_velocity += current_acceleration
		#var speed: float = clamp(current_velocity.length(), 0, max_speed)
		#self.current_velocity = current_velocity.normalized() * speed
	#if !acceleration_input:
		#self.sprite.play("Idle")
	#self.position += current_velocity * delta
	#
	#if fire:
		#we_need_a_beep.emit(projectile_sound, 10)
		#shoot()
		#
	#if Game.is_out_of_play(self):
		#Game.wrap_screen(self)
	#
	#if current_state == Player.state.hit_invuln:
		#modulate.a = cos(invuln_elapsed * 16 * PI * delta)
		#invuln_elapsed += 1

func check_input() -> void:
	rotation_input = Input.get_axis("ui_left", "ui_right")
	acceleration_input = Input.is_action_pressed("ui_up")
	fire_input = Input.is_action_just_pressed("fire")
	
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
	
