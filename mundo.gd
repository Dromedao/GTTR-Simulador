extends Node2D

const EscenaAuto = preload("res://auto.tscn")

@export var min_spawn_time_norte = 0.3
@export var max_spawn_time_norte = 0.6
@export var min_spawn_time_este = 15.0
@export var max_spawn_time_este = 20.0
@export var tiempo_verde_semaforo_norte = 5.0
@export var tiempo_verde_semaforo_este = 15.0
@export var tiempo_despeje = 2.0
@export var tiempo_minimo_verde = 3.0  # Tiempo mínimo antes de cambiar

@onready var spawn_timer_norte = $TimerSpawnAutoNorte
@onready var spawn_sensor_norte = $SpawnSensor_Norte
@onready var ruta_norte_sur = $Ruta_Norte_a_Sur
@onready var spawn_timer_este = $TimerSpawnAutoEste
@onready var spawn_sensor_este = $SpawnSensor_Este
@onready var ruta_este_oeste = $Ruta_Este_a_Oeste
@onready var semaforo_norte = $Semaforo_Norte
@onready var semaforo_este = $Semaforo_Este
@onready var control_semaforo_timer = $TimerSemaforo

var modo_inteligente_activo = false
var esperando_despeje = false
var timer_despeje = 0.0
var tiempo_actual_en_verde = 0.0  # Contador de tiempo en verde

func _ready():
	print("--- INICIANDO SIMULACIÓN EN MODO: Semáforo Fijo (TONTO) ---")
	set_luz_este_verde() 
	control_semaforo_timer.wait_time = tiempo_verde_semaforo_este
	control_semaforo_timer.start()

func _process(delta):
	if not modo_inteligente_activo:
		return
	
	# Manejar tiempo de despeje
	if esperando_despeje:
		timer_despeje -= delta
		if timer_despeje <= 0:
			esperando_despeje = false
		return
	
	# Incrementar contador de tiempo en verde
	tiempo_actual_en_verde += delta
	
	logica_inteligente()

func logica_inteligente():
	var carros_norte = semaforo_norte.get_conteo_autos_esperando()
	var carros_este = semaforo_este.get_conteo_autos_esperando()
	
	# Debug
	if Engine.get_frames_drawn() % 60 == 0:  # Cada ~1 segundo
		print("DEBUG - Norte esperando: %d | Este esperando: %d | Norte en rojo: %s | Tiempo en verde: %.1f" % 
			[carros_norte, carros_este, semaforo_norte.esta_en_rojo, tiempo_actual_en_verde])
	
	# Verificar tiempo mínimo en verde antes de permitir cambios
	if tiempo_actual_en_verde < tiempo_minimo_verde:
		return
	
	# Si Este está en verde pero hay autos esperando en Norte y Este está vacío
	if not semaforo_este.esta_en_rojo and carros_norte > 0 and carros_este == 0:
		print("SMART: Este vacío, Norte tiene %d autos. Cambiando a Norte." % carros_norte)
		iniciar_cambio_a_norte()
		return
	
	# Si Norte está en verde pero hay autos esperando en Este y Norte está vacío
	if not semaforo_norte.esta_en_rojo and carros_este > 0 and carros_norte == 0:
		print("SMART: Norte vacío, Este tiene %d autos. Cambiando a Este." % carros_este)
		iniciar_cambio_a_este()
		return
	
	# Si una dirección tiene muchos más autos esperando (desbalance)
	if not semaforo_este.esta_en_rojo and carros_norte >= carros_este + 3:
		print("SMART: Norte sobrecargado (%d vs %d). Cambiando a Norte." % [carros_norte, carros_este])
		iniciar_cambio_a_norte()
		return
	
	if not semaforo_norte.esta_en_rojo and carros_este >= carros_norte + 3:
		print("SMART: Este sobrecargado (%d vs %d). Cambiando a Este." % [carros_este, carros_norte])
		iniciar_cambio_a_este()
		return

func iniciar_cambio_a_norte():
	if esperando_despeje:
		return
	
	print("FASE 1: Poniendo Este en ROJO (despejando intersección)")
	semaforo_este.cambiar_a_rojo()
	esperando_despeje = true
	timer_despeje = tiempo_despeje
	tiempo_actual_en_verde = 0.0 
	
	await get_tree().create_timer(tiempo_despeje).timeout
	
	if modo_inteligente_activo:
		print("FASE 2: Poniendo Norte en VERDE")
		semaforo_norte.cambiar_a_verde()

func iniciar_cambio_a_este():
	if esperando_despeje:
		return
	
	print("FASE 1: Poniendo Norte en ROJO (despejando intersección)")
	semaforo_norte.cambiar_a_rojo()
	esperando_despeje = true
	timer_despeje = tiempo_despeje
	tiempo_actual_en_verde = 0.0  # Resetear contador
	
	await get_tree().create_timer(tiempo_despeje).timeout
	
	if modo_inteligente_activo:
		print("FASE 2: Poniendo Este en VERDE")
		semaforo_este.cambiar_a_verde()

func set_luz_norte_verde():
	if semaforo_norte.esta_en_rojo: 
		print("CAMBIANDO A: NORTE (VERDE), ESTE (ROJO)")
		semaforo_norte.cambiar_a_verde()
		semaforo_este.cambiar_a_rojo()

func set_luz_este_verde():
	if semaforo_este.esta_en_rojo: 
		print("CAMBIANDO A: NORTE (ROJO), ESTE (VERDE)")
		semaforo_este.cambiar_a_verde()
		semaforo_norte.cambiar_a_rojo()

func _on_timer_cambio_de_modo_timeout():
	print("==========================================================")
	print("¡¡¡ CAMBIANDO A MODO: Sensores Inteligentes !!!")
	print("==========================================================")
	modo_inteligente_activo = true
	tiempo_actual_en_verde = 0.0  # Inicializar contador
	control_semaforo_timer.stop()

func _on_timer_semaforo_timeout():
	if modo_inteligente_activo:
		return 
	if semaforo_norte.esta_en_rojo:
		set_luz_norte_verde()
		control_semaforo_timer.wait_time = tiempo_verde_semaforo_norte
		control_semaforo_timer.start()
	else:
		set_luz_este_verde()
		control_semaforo_timer.wait_time = tiempo_verde_semaforo_este
		control_semaforo_timer.start()

func _on_timer_spawn_auto_norte_timeout():
	if not spawn_sensor_norte.esta_obstruido: 
		var nuevo_auto = EscenaAuto.instantiate()
		ruta_norte_sur.add_child(nuevo_auto)
	spawn_timer_norte.wait_time = randf_range(min_spawn_time_norte, max_spawn_time_norte)

func _on_timer_spawn_auto_este_timeout():
	if not spawn_sensor_este.esta_obstruido: 
		var nuevo_auto = EscenaAuto.instantiate()
		ruta_este_oeste.add_child(nuevo_auto)
	spawn_timer_este.wait_time = randf_range(min_spawn_time_este, max_spawn_time_este)
