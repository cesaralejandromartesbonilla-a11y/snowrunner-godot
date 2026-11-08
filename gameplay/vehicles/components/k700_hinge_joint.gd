extends HingeJoint3D

@export var unidad_frontal: NodePath = "../FrontUnit"
@export var unidad_trasera: NodePath = "../RearUnit"

var frontal: VehicleBody3D
var trasera: VehicleBody3D

func _ready() -> void:
	frontal = get_node(unidad_frontal)
	trasera = get_node(unidad_trasera)
	
	# Configurar joint basico
	node_a = frontal.get_path()
	node_b = trasera.get_path()
	global_position = frontal.get_node("HingePivot").global_position
	
	# Configuracion basica sin parametros complejos
	# El joint funcionara con los valores por defecto de Godot 4
	
	# Excluir colision entre las dos unidades
	frontal.add_collision_exception_with(trasera)
	trasera.add_collision_exception_with(frontal)

func _physics_process(delta: float) -> void:
	# El joint maneja la fisi automticamente
	pass
