extends Area2D

var esta_en_rojo = true  

var carros_detenidos = []

func _on_area_entered(area_del_auto):
	var carro = area_del_auto.get_parent()

	if esta_en_rojo:
		carro.detener()
		carros_detenidos.append(carro)

func cambiar_a_verde():
	esta_en_rojo = false
	
	for carro in carros_detenidos:
		if is_instance_valid(carro):
			carro.reanudar_marcha()
	
	carros_detenidos.clear()

func cambiar_a_rojo():
	esta_en_rojo = true


func _on_area_exited(area: Area2D) -> void:
	pass 

func get_conteo_autos_esperando():
	carros_detenidos = carros_detenidos.filter(func(auto): return is_instance_valid(auto))
	return carros_detenidos.size()
