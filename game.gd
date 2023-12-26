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
var life_display: PackedScene = preload("res://UI/life_display.tscn")
var large_asteroid: PackedScene = preload("res://Entities/large_asteroid.tscn")

var max_lives: int = 3
var current_lives: int = max_lives
var current_player: Player
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
				start_game()
		GAME_STATE.active:
			if Input.is_action_just_pressed("ui_cancel"):
				gamestate = GAME_STATE.game_over
			pass
		GAME_STATE.game_over:
			reset()

func start_game() -> void:
	gamestate = GAME_STATE.active
	var new_player: Player = player.instantiate()
	new_player.we_need_a_beep.connect(_on_priority_sfx_request)
	new_player.im_freaking_dead.connect(_on_player_death)
	new_player.position = Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT / 2)
	entities.add_child(new_player)
	current_player = new_player
	
	var new_life_display: LifeDisplay = life_display.instantiate()
	new_life_display.max_lives = self.max_lives
	UI.add_child(new_life_display)

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
	
func _on_priority_sfx_request(sound: AudioStream, priority: int) -> void:
	sfx_player._on_sound_request(sound, priority)

func reset() -> void:
	gamestate = GAME_STATE.title
	enter_title_state()
	UI.get_node("LifeDisplay").queue_free()
	get_tree().call_group("reset", "reset")

func _on_player_death() -> void:
	current_lives -= 1
	if current_lives > 0:
		var life_ui_panel: LifeDisplay = UI.get_node("LifeDisplay")
		life_ui_panel.remove_life()
		current_player.reset()
	else:
		current_lives = max_lives
		reset()

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
