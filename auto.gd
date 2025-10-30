extends PathFollow2D

@export var velocidad = 150.0
var puede_moverse_por_semaforo = true 

@onready var sensor_delantero = $SensorDelantero

func _process(delta):

	if puede_moverse_por_semaforo and not sensor_delantero.is_colliding():
		progress += velocidad * delta
	
	if progress_ratio >= 1.0:
		queue_free()

func detener():
	puede_moverse_por_semaforo = false

func reanudar_marcha():
	puede_moverse_por_semaforo = true
