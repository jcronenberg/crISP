extends Control

func _physics_process(delta: float) -> void:
	%FPSCounter.text = str(Engine.get_frames_per_second())
