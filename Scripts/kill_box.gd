extends Area2D

@onready var timer : Timer = $KBTimer

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Engine.time_scale = 0.2
		timer.start()

func _on_kb_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
