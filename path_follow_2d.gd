extends PathFollow2D

@export var velocidad = 150.0 

func _process(delta):
	progress += velocidad * delta

	if progress_ratio >= 1.0:
		queue_free()
