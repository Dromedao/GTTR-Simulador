extends Area2D

var esta_obstruido = false 

func _on_area_entered(area):
	esta_obstruido = true

func _on_area_exited(area):
	esta_obstruido = false 
