class_name Game extends Node
enum GAME_STATE {
	title,
	active,
	game_over
}
static var ARENA_WIDTH: float = 640.0
static var ARENA_HEIGHT: float = 480.0
static var ARENA_CENTER: Vector2 = Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT / 2)

var player: PackedScene = preload("res://Entities/player.tscn")
var hud: PackedScene = preload("res://UI/hud.tscn")
var split_count: int = 3

var max_lives: int = 3
var current_lives: int = max_lives
var current_player: Player
var current_score: int = 0
var gamestate: Game.GAME_STATE

@onready var sfx_player: SFXPlayer = $Services/SFXPlayer
@onready var asteroid_spawner: AsteroidSpawner = $Services/AsteroidSpawner
@onready var particle_manager: ParticleManager = $Services/ParticleManager
@onready var entities: CanvasLayer = $World/Entities
@onready var UI: CanvasLayer = $World/UI

func _ready() -> void:
	enter_title_state()

func _process(_delta: float) -> void:
	match gamestate:
		GAME_STATE.title:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().call_group("title_screen", "queue_free")
				enter_active_state()
			if Input.is_action_just_pressed("ui_cancel"):
				get_tree().quit()
		GAME_STATE.active:
			if Input.is_action_just_pressed("ui_cancel"):
				enter_game_over_state()
		GAME_STATE.game_over:
			reset()

func enter_title_state() -> void:
	gamestate = GAME_STATE.title
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
	gamestate = GAME_STATE.active
	var new_player: Player = player.instantiate()
	new_player.we_need_a_beep.connect(_on_priority_sfx_request)
	new_player.im_freaking_dead.connect(_on_player_death)
	new_player.position = Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT / 2)
	entities.add_child(new_player)
	current_player = new_player
	
	var new_hud: HUD = hud.instantiate()
	UI.add_child(new_hud)
	new_hud.life_display.max_lives = max_lives
	
	var _pos: Vector2 = Vector2(randf_range(0, ARENA_WIDTH / 3), randf_range(0, ARENA_HEIGHT) / 3)
	var _origin: Vector2 = Vector2(randi() % 3, randi() % 3)
	if _origin == Vector2(1,1):
		_origin.x += 1
	var _dir: Vector2 = Vector2.from_angle(randf_range(0, 2 * PI))
	var new_asteroid: Asteroid = asteroid_spawner.spawn_large_asteroid(_pos*_origin, _dir)
	new_asteroid.destroyed.connect(_on_asteroid_destroyed)
	new_asteroid.we_need_a_beep.connect(_on_priority_sfx_request)
	entities.add_child(new_asteroid)

func enter_game_over_state() -> void:
	gamestate = GAME_STATE.game_over
	
func _on_priority_sfx_request(sound: AudioStream, priority: int) -> void:
	sfx_player._on_sound_request(sound, priority)

func _on_player_death() -> void:
	current_lives -= 1
	if current_lives > 0:
		remove_life_from_ui()
		current_player.position = ARENA_CENTER
		current_player.current_velocity = Vector2.ZERO
	else:
		reset()

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

func update_score_ui() -> void:
	var current_hud: HUD = UI.get_node("HUD")
	current_hud.update_score(current_score)

func remove_life_from_ui() -> void:
	var current_hud: HUD = UI.get_node("HUD")
	current_hud.life_display.remove_life()

func reset() -> void:
	gamestate = GAME_STATE.title
	current_lives = max_lives
	current_score = 0
	get_tree().call_group("reset", "reset")
	enter_title_state()
	
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
