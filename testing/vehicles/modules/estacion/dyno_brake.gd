# Freno dinamométrico: un PowerConsumer más, no un caso especial. En vez de
# mandar torque a una caja de cambios, aplica una resistencia configurable
# y expone los datos en vivo (RPM, torque) para que la interfaz de la
# estación los muestre.
extends PowerConsumer
class_name FrenoDinamometrico

@export var torque_resistencia: float = 500.0  # ajustable en vivo desde la interfaz de la estación

var input_acelerador: float = 0.0  # lo escribe EstacionMotor mientras la estación está activa

# Datos en vivo para la interfaz
var rpm_actual: float = 0.0
var torque_actual: float = 0.0

func procesar(delta: float) -> void:
	if not fuente:
		return
	torque_actual = fuente.procesar(input_acelerador, torque_resistencia, delta)
	rpm_actual = fuente.velocidad_angular
