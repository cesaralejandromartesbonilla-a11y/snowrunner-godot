extends VehicleBody3D

# Unidad trasera del K-700 - pasiva, solo es arrastrada por el joint
# La tracción viene del HingeJoint3D que conecta con la unidad frontal

@export var unidad_frontal: NodePath = "../FrontUnit"
var frontal: VehicleBody3D

func _ready() -> void:
	frontal = get_node(unidad_frontal)
	
	# Sin input propio
	process_mode = Node.PROCESS_MODE_INHERIT

func _physics_process(delta: float) -> void:
	if not frontal or not is_instance_valid(frontal):
		return
	
	# Unidad trasera PASIVA - sin fuerza de motor propia
	# El HingeJoint3D transmite la fuerza de la unidad frontal
	engine_force = 0.0
	brake = frontal.brake
	steering = 0.0