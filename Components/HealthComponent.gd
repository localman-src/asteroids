class_name HealthComponent extends Node

@export var MAX_HP: int = 1
@onready var CURRENT_HP: int = MAX_HP

signal health_depleted
signal health_increased
signal health_decreased

func _ready() -> void:
	add_to_group("reset")
	
func decrease_health(amount: int) -> void:
	health_decreased.emit()
	self.CURRENT_HP = clamp(self.CURRENT_HP - amount, 0, self.MAX_HP)
	if self.CURRENT_HP == 0:
		health_depleted.emit()

func increase_health(amount: int) -> void:
	health_increased.emit()
	self.CURRENT_HP = clamp(self.CURRENT_HP + amount, 0, self.MAX_HP)

func set_current_health(amount: int) -> void:
	self.CURRENT_HP = clamp(amount, 0, self.MAX_HP)

func reset() -> void:
	CURRENT_HP = MAX_HP
