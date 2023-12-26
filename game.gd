class_name Game extends Node

static var ARENA_WIDTH: float = 640.0
static var ARENA_HEIGHT: float = 480.0
static var ARENA_CENTER: Vector2 = Vector2(ARENA_WIDTH / 2, ARENA_HEIGHT / 2)

var player: PackedScene = preload("res://Entities/player.tscn")
var life_display: PackedScene = preload("res://UI/life_display.tscn")
var max_lives: int = 3
var current_lives: int = max_lives

@onready var sfx_player: SFXPlayer = $Services/SFXPlayer
@onready var entities: CanvasLayer = $World/Entities
@onready var UI: CanvasLayer = $World/UI

func _ready() -> void:
	var new_player: Player = player.instantiate()
	new_player.we_need_a_beep.connect(_on_priority_sfx_request)
	entities.add_child(new_player)
	new_player.reset()
	
	var new_life_display: LifeDisplay = life_display.instantiate()
	new_life_display.max_lives = self.max_lives
	UI.add_child(new_life_display)

func _on_priority_sfx_request(sound: AudioStream, priority) -> void:
	sfx_player._on_sound_request(sound, priority)

func reset() -> void:
	get_tree().call_group("reset", "reset")
	
static func is_out_of_play(node: Node2D) -> bool:
	var hitbox: RectangleShape2D = node.collision.shape
	var right: bool = node.position.x > Game.ARENA_WIDTH + hitbox.size.x
	var down: bool = node.position.y > Game.ARENA_WIDTH + hitbox.size.y
	var left: bool = node.position.x < 0 - hitbox.size.x
	var up: bool = node.position.y < 0 - hitbox.size.y
	return right || down || left || up
