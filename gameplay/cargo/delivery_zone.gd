extends Area3D

@export var money_reward: int = 200
@export var mensaje: String = "Carga entregada!"

func _ready() -> void:
	add_to_group("delivery_zones")

func cobrar() -> void:
	GlobalData.dinero += money_reward
	print(mensaje, " +$", money_reward)
