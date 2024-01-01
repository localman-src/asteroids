class_name Game extends Node

static var ARENA_WIDTH: float = 640.0
static var ARENA_HEIGHT: float = 480.0
static var ARENA_CENTER: Vector2 = Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT / 2)

var fsm: LMSM = LMSM.new(self, "title")

var player: PackedScene = preload("res://Entities/player.tscn")
var hud: PackedScene = preload("res://UI/hud.tscn")
var ufo: PackedScene = preload("res://Entities/alien.tscn")
var split_count: int = 3

var max_lives: int = 3
var current_lives: int = max_lives
var current_player: Player
var current_score: int = 0
var current_level: int = 1

var ufo_spawn_point: Vector2
var ufo_spawn_time: float = 15.0

@onready var sfx_player: SFXPlayer = $Services/SFXPlayer
@onready var asteroid_spawner: AsteroidSpawner = $Services/AsteroidSpawner
@onready var particle_manager: ParticleManager = $Services/ParticleManager
@onready var entities: CanvasLayer = $World/Entities
@onready var UI: CanvasLayer = $World/UI

func _ready() -> void:
	fsm.add("title", {
		"enter" : enter_title_state
	})
	fsm.add("active", {
		"enter" : enter_active_state,
		"leave" : reset
	})
	
	fsm.add_transition("t_game_triggers", ["title"], "active", func()->bool: return Input.is_action_just_pressed("ui_accept"))
	fsm.add_transition("t_game_triggers", ["active"], "title", func()->bool: return Input.is_action_just_pressed("ui_cancel"))
	fsm.add_transition("t_lost_the_game", ["active"], "title", func() ->bool: return current_lives <= 0)
	fsm.add_reflexive_transition("t_game_triggers", ["title"], func()->bool: return Input.is_action_just_pressed("ui_cancel"), fsm.leave, get_tree().quit)

func _process(_delta: float) -> void:
	fsm.event("step", [_delta])
	fsm.trigger("t_game_triggers")

func enter_title_state() -> void:
	for i: int in 3:
		var _pos: Vector2 = Vector2(randf_range(0, ARENA_WIDTH), randf_range(0, ARENA_HEIGHT))
		var _dir: Vector2 = Vector2.from_angle(randf_range(0, 2 * PI))
		var new_asteroid: Asteroid = asteroid_spawner.spawn_large_asteroid(_pos, _dir)
		new_asteroid.add_to_group("title_screen")
		entities.call_deferred("add_child", new_asteroid)
	var titletext: PackedScene = load("res://UI/title_text.tscn")
	var titletextnode: Label = titletext.instantiate()
	titletextnode.add_to_group("title_screen")
	UI.add_child(titletextnode)
	
func enter_active_state() -> void:
	get_tree().call_group("title_screen", "queue_free")
	var new_player: Player = player.instantiate()
	new_player.we_need_a_beep.connect(_on_priority_sfx_request)
	new_player.im_freaking_dead.connect(_on_player_death)
	new_player.position = ARENA_CENTER
	entities.add_child(new_player)
	current_player = new_player
	
	var new_hud: HUD = hud.instantiate()
	UI.add_child(new_hud)
	new_hud.life_display.max_lives = max_lives
	
	for i: int in current_level + 1:
		spawn_large_asteroid()
	get_tree().create_timer(ufo_spawn_time).timeout.connect(spawn_ufo)

func spawn_large_asteroid() -> void:
	var _pos: Vector2 = Vector2(randf_range(0, ARENA_WIDTH / 3), randf_range(0, ARENA_HEIGHT) / 3)
	var _origin: Vector2 = Vector2(randi() % 3, randi() % 3)
	if _origin == Vector2(1,1):
		_origin.x += 1
	var _dir: Vector2 = Vector2.from_angle(randf_range(0, 2 * PI))
	var new_asteroid: Asteroid = asteroid_spawner.spawn_large_asteroid(_pos + _origin*Vector2(ARENA_WIDTH / 3, ARENA_HEIGHT / 3), _dir)
	new_asteroid.destroyed.connect(_on_asteroid_destroyed)
	new_asteroid.we_need_a_beep.connect(_on_priority_sfx_request)
	entities.call_deferred("add_child", new_asteroid)
	
func spawn_ufo() -> void:
	if fsm.__get_current_state().__name == "title":
		return
	var new_ufo: Alien = ufo.instantiate()
	new_ufo.position = Vector2(-300, randf_range(0, Game.ARENA_HEIGHT))
	new_ufo.target = Game.ARENA_CENTER + Vector2(randf_range(0, Game.ARENA_WIDTH / 2), randf_range(-Game.ARENA_HEIGHT / 2, Game.ARENA_HEIGHT / 2))
	new_ufo.we_need_a_beep.connect(_on_priority_sfx_request)
	new_ufo.alien_destroyed.connect(_on_alien_destroyed)
	entities.add_child(new_ufo)
	get_tree().create_timer(ufo_spawn_time).timeout.connect(spawn_ufo)
	
	
func _on_priority_sfx_request(sound: AudioStream, priority: int) -> void:
	sfx_player._on_sound_request(sound, priority)

func _on_player_death() -> void:
	current_lives -= 1
	var hit_particles: CPUParticles2D = particle_manager.hit_particles_emitter(current_player.position)
	hit_particles.finished.connect(hit_particles.queue_free)
	hit_particles.emitting = true
	UI.add_child(hit_particles)
	remove_life_from_ui()
	current_player.position = ARENA_CENTER
	current_player.current_velocity = Vector2.ZERO
	fsm.trigger("t_lost_the_game")

func _on_asteroid_destroyed(points: int, pos: Vector2, _size: Asteroid.SIZE) -> void:
	current_score += points
	update_score_ui()
	var burst: Array[Asteroid]
	match _size:
		Asteroid.SIZE.large:
			burst = asteroid_spawner.asteroid_burst(pos, Asteroid.SIZE.medium)
		Asteroid.SIZE.medium:
			burst = asteroid_spawner.asteroid_burst(pos, Asteroid.SIZE.small)
		_:
			pass
			
	for asteroid: Asteroid in burst:
		asteroid.destroyed.connect(_on_asteroid_destroyed)
		asteroid.we_need_a_beep.connect(_on_priority_sfx_request)
		entities.call_deferred("add_child", asteroid)
	
	var hit_particles: CPUParticles2D = particle_manager.hit_particles_emitter(pos)
	hit_particles.finished.connect(hit_particles.queue_free)
	hit_particles.emitting = true
	UI.add_child(hit_particles)
	
	if _size == Asteroid.SIZE.small:
		var asteroids_left: Array[Node] = get_tree().get_nodes_in_group("asteroids")
		if asteroids_left.size() == 1:
			current_level += 1
			for i: int in current_level + 1:
				spawn_large_asteroid()

func _on_alien_destroyed(points: int, pos: Vector2) -> void:
	current_score += points
	update_score_ui()
	
	var hit_particles: CPUParticles2D = particle_manager.hit_particles_emitter(pos)
	hit_particles.finished.connect(hit_particles.queue_free)
	hit_particles.emitting = true
	UI.add_child(hit_particles)
	
func update_score_ui() -> void:
	var current_hud: HUD = UI.get_node("HUD")
	current_hud.update_score(current_score)

func remove_life_from_ui() -> void:
	var current_hud: HUD = UI.get_node("HUD")
	current_hud.life_display.remove_life()

func reset() -> void:
	current_lives = max_lives
	current_score = 0
	current_level = 1
	get_tree().call_group("reset", "reset")
	
static func is_out_of_play(node: Node2D) -> bool:
	var collision: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	if collision != null:
		var hitbox: RectangleShape2D = collision.shape
		var right: bool = node.position.x > Game.ARENA_WIDTH + hitbox.size.x
		var down: bool = node.position.y > Game.ARENA_WIDTH + hitbox.size.y
		var left: bool = node.position.x < 0 - hitbox.size.x
		var up: bool = node.position.y < 0 - hitbox.size.y
		return right || down || left || up
	return false

static func wrap_screen(node: Node2D) -> void:
		if node.position.x < 0:
			node.position.x = Game.ARENA_WIDTH
		if node.position.x > Game.ARENA_WIDTH:
			node.position.x = 0
		if node.position.y < 0:
			node.position.y = Game.ARENA_HEIGHT
		if node.position.y > Game.ARENA_HEIGHT:
			node.position.y = 0
