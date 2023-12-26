class_name HUD extends Control

@onready var life_display: LifeDisplay = $LifeDisplay
@onready var score_display: Label = $ScoreDisplay

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("reset")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_score(score: int) -> void:
	score_display.text = "%06d" % score

func reset() -> void:
	queue_free()
