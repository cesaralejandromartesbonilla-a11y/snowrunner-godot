# Estación de banco dinamométrico. A diferencia de la primera versión, NO
# asume un vehículo fijo pre-asignado en el inspector — detecta el
# VehiculoTerrestre que entra al área, sea cual sea. Si no armaste un panel
# a mano, se genera uno simple solo (para ver la estructura corriendo y no
# depender de un paso manual en el editor).
extends EstacionPrueba
class_name EstacionMotor

@export_group("Banco")
@export var freno: FrenoDinamometrico

@export_group("Paneles 3D")
@export var etiqueta_rpm: Label3D
@export var etiqueta_torque: Label3D

var chasis_actual: RigidBody3D
var vehiculo_actual: VehiculoTerrestre
var motor_actual: Motor

func _ready() -> void:
	super._ready()
	if not panel_interfaz:
		_crear_panel_simple()

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		var vehiculo = _buscar_vehiculo(body)
		if vehiculo and vehiculo.motor:
			jugador_cerca = true
			chasis_actual = body
			cuerpo_elevado = body  # heredado de EstacionPrueba — así se levanta solo al activar
			vehiculo_actual = vehiculo
			motor_actual = vehiculo.motor

func _on_body_exited(body: Node3D) -> void:
	if body == chasis_actual:
		jugador_cerca = false
		if activa:
			_desactivar()
		chasis_actual = null
		cuerpo_elevado = null
		vehiculo_actual = null
		motor_actual = null

# El chasis es el RigidBody3D que entra al área, y VehiculoTerrestre vive
# como hijo directo suyo — se busca entre los hijos, no en los ancestros.
func _buscar_vehiculo(cuerpo: Node3D) -> VehiculoTerrestre:
	for hijo in cuerpo.get_children():
		if hijo is VehiculoTerrestre:
			return hijo
	return null

func _al_activar() -> void:
	if vehiculo_actual:
		vehiculo_actual.modo_dinamometro = true
	if freno and motor_actual:
		freno.fuente = motor_actual

func _al_desactivar() -> void:
	if vehiculo_actual:
		vehiculo_actual.modo_dinamometro = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)  # maneja la activación/desactivación por press_space

	if activa and freno and motor_actual:
		if Input.is_action_just_pressed("press_i"):
			motor_actual.alternar_encendido()

		freno.input_acelerador = Input.get_action_strength("press_w")
		freno.procesar(delta)

		if etiqueta_rpm:
			etiqueta_rpm.text = "RPM: %.0f" % freno.rpm_actual
		if etiqueta_torque:
			etiqueta_torque.text = "Torque: %.0f N·m" % freno.torque_actual

# Panel mínimo generado por código: un fondo plano + dos etiquetas 3D.
# Es deliberadamente simple — reemplazalo por algo armado a mano en el
# editor cuando quieras pulir el aspecto, esto es solo para ver la
# estructura funcionando y probar el banco ya.
func _crear_panel_simple() -> void:
	panel_interfaz = Node3D.new()
	panel_interfaz.name = "PanelSimple"
	add_child(panel_interfaz)

	var fondo = MeshInstance3D.new()
	fondo.name = "Fondo"
	var malla_fondo = QuadMesh.new()
	malla_fondo.size = Vector2(1.0, 0.6)
	fondo.mesh = malla_fondo
	panel_interfaz.add_child(fondo)

	etiqueta_rpm = Label3D.new()
	etiqueta_rpm.name = "EtiquetaRPM"
	etiqueta_rpm.text = "RPM: 0"
	etiqueta_rpm.font_size = 32
	etiqueta_rpm.position = Vector3(0, 0.15, 0.01)
	panel_interfaz.add_child(etiqueta_rpm)

	etiqueta_torque = Label3D.new()
	etiqueta_torque.name = "EtiquetaTorque"
	etiqueta_torque.text = "Torque: 0 N·m"
	etiqueta_torque.font_size = 32
	etiqueta_torque.position = Vector3(0, -0.05, 0.01)
	panel_interfaz.add_child(etiqueta_torque)

	panel_interfaz.visible = false
