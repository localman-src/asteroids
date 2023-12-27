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
var large_asteroid: PackedScene = preload("res://Entities/large_asteroid.tscn")
var medium_asteroid: PackedScene = preload("res://Entities/medium_asteroid.tscn")
var small_asteroid: PackedScene = preload("res://Entities/small_asteroid.tscn")
var split_count: int = 3

var max_lives: int = 3
var current_lives: int = max_lives
var current_player: Player
var current_score: int = 0
var gamestate: Game.GAME_STATE

@onready var sfx_player: SFXPlayer = $Services/SFXPlayer
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
		var new_asteroid: Asteroid = large_asteroid.instantiate()
		new_asteroid.position = Vector2(randf_range(0, ARENA_WIDTH), randf_range(0, ARENA_HEIGHT))
		new_asteroid.add_to_group("title_screen")
		entities.add_child(new_asteroid)
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
	
	var new_asteroid: Asteroid = spawn_large_asteroid(Vector2(randf_range(0, ARENA_WIDTH), randf_range(0, ARENA_HEIGHT)), Vector2.from_angle(randf_range(0, 2 * PI)))
	entities.add_child(new_asteroid)

func enter_game_over_state() -> void:
	gamestate = GAME_STATE.game_over
	
func spawn_large_asteroid(_position: Vector2, _direction: Vector2) -> LargeAsteroid:
	var new_asteroid: LargeAsteroid = large_asteroid.instantiate()
	new_asteroid.position = _position
	new_asteroid.initial_direction = _direction
	new_asteroid.destroyed.connect(_on_asteroid_destroyed)
	return new_asteroid
	
func spawn_medium_asteroid(_position: Vector2, _direction: Vector2) -> MediumAsteroid:
	var new_asteroid: MediumAsteroid = medium_asteroid.instantiate()
	new_asteroid.position = _position
	new_asteroid.initial_direction = _direction
	new_asteroid.destroyed.connect(_on_asteroid_destroyed)
	return new_asteroid

func spawn_small_asteroid(_position: Vector2, _direction: Vector2) -> SmallAsteroid:
	var new_asteroid: SmallAsteroid = small_asteroid.instantiate()
	new_asteroid.position = _position
	new_asteroid.initial_direction = _direction
	new_asteroid.destroyed.connect(_on_asteroid_destroyed)
	return new_asteroid

func asteroid_burst(_position: Vector2, _size: Asteroid.SIZE) -> void:
	var arc_length: float = 2 * PI / split_count
	var angle_offset: float = randf_range(0, arc_length / 2)
	
	for i: int in split_count:
		match _size:
			Asteroid.SIZE.medium:
				var new_asteroid: Asteroid = spawn_medium_asteroid(_position, Vector2.from_angle(i * arc_length + angle_offset))
				entities.call_deferred("add_child", new_asteroid)
			Asteroid.SIZE.small:
				var new_asteroid: Asteroid = spawn_small_asteroid(_position, Vector2.from_angle(i * arc_length + angle_offset))
				entities.call_deferred("add_child", new_asteroid)
	
func _on_priority_sfx_request(sound: AudioStream, priority: int) -> void:
	sfx_player._on_sound_request(sound, priority)

func _on_player_death() -> void:
	current_lives -= 1
	if current_lives > 0:
		remove_life_from_ui()
		current_player.position = ARENA_CENTER
	else:
		reset()

func _on_asteroid_destroyed(points: int, pos: Vector2, _size: Asteroid.SIZE) -> void:
	current_score += points
	update_score_ui()
	
	match _size:
		Asteroid.SIZE.large:
			asteroid_burst(pos, Asteroid.SIZE.medium)
		Asteroid.SIZE.medium:
			asteroid_burst(pos, Asteroid.SIZE.small)
			
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
