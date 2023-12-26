class_name LifeDisplay extends PanelContainer

const life_icon: PackedScene = preload("res://UI/life_icon.tscn")
var max_lives: int = 3

@onready var life_container: GridContainer = $GridContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")
	for lives: int in max_lives:
		self.add_life()

func get_current_lives() -> int:
	return life_container.get_children().size()

func remove_life() -> void:
	var lives: Array[Node] = life_container.get_children()
	if lives.size() > 0:
		var lost_life: Node = lives.pop_back()
		lost_life.queue_free()

func add_life() -> void:
	var lives: Array[Node] = life_container.get_children()
	if lives.size() < max_lives:
		var new_life_icon: TextureRect = life_icon.instantiate()
		life_container.add_child(new_life_icon)

func reset() -> void:
	var current_lives: int = life_container.get_children().size()
	while current_lives < max_lives:
		add_life()
		current_lives = life_container.get_children().size()
