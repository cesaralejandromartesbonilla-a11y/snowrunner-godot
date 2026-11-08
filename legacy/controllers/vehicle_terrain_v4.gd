extends Node3D
class_name VehiculoTerrestre

@export_group("Configuración de Dirección")
@export var grados_maximos: float = 30.0
@export var velocidad_volante: float = 5.0

@export_group("Retorno Automático")
@export var auto_centrar: bool = true
@export var velocidad_retorno: float = 8.0 

@export_group("Modos de Dirección Permitidos")
@export var permitir_modo_normal: bool = true
@export var permitir_modo_opuesta: bool = true
@export var permitir_modo_cangrejo: bool = true
@export var permitir_modo_eje: bool = true
enum ModoDireccion { NORMAL, OPUESTA, CANGREJO, EJE }
var modo_direccion_actual: ModoDireccion = ModoDireccion.NORMAL

@export_group("modulos")
@export var radiador: Radiador
@export var caja_cambios: CajaCambios
@export var motor: Motor
# volante_inercia ya no existe: Motor trackea su propia velocidad_angular (ver PowerSource)

@export_group("Configuración ruedas direccionales")
@export var fuerza_direccion: float = 1500.0 
@export var direccion_principal: Array[HingeJoint3D] = []
@export var direccion_secundaria: Array[HingeJoint3D] = []

@export_group("Configuración ruedas motrices")
@export var fuerza_frenado: float = 3000.0
@export var multiplicador_diferencial: float = 3.0
@export var traccion_principal: Array[HingeJoint3D] = []
@export var traccion_secundaria: Array[HingeJoint3D] = []

var traccion_total_activada: bool = false 
var diferencial_bloqueado: bool = false
var posicion_anterior: Vector3 = Vector3.ZERO
var velocidad_real_camion: float = 0.0

# Lo activa EstacionMotor mientras el vehículo está en el banco dinamométrico.
# A propósito NO se pausa el _physics_process entero — eso dejaba los joints
# de dirección congelados en su último valor, no en cero, y el joint los
# seguía persiguiendo indefinidamente (giros raros + desincronización al salir).
var modo_dinamometro: bool = false

func _set_motor_active(joint: HingeJoint3D, active: bool) -> void:
	joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, active)
	if not active:
		joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 0.0)

# Dirección siempre en cero durante el modo dinamómetro — el joint no
# persigue un objetivo viejo, y girar el volante con el vehículo elevado
# no tiene sentido. Tracción NO se apaga: refleja motor.velocidad_angular
# directamente, para ver las ruedas girar y frenar con el acelerador aunque
# estén en el aire sin mover nada.
func _neutralizar_joints() -> void:
	var todas_direccion = direccion_principal + direccion_secundaria
	for joint in todas_direccion:
		if is_instance_valid(joint):
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)

	var todas_traccion = traccion_principal + traccion_secundaria
	for joint in todas_traccion:
		if is_instance_valid(joint):
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			if is_instance_valid(motor):
				# motor.velocidad_angular es la velocidad CRUDA del cigüeñal,
				# sin pasar por ninguna caja de cambios que la reduzca (como sí
				# pasa en el manejo real). Pedirle a la rueda que gire a esa
				# velocidad directa la estresaba de más. Reducción aproximada
				# solo para que el giro se vea razonable — no es una relación
				# de marcha real, esto es puramente efecto visual.
				joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, motor.velocidad_angular / 4.0)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 500.0)  # modesto a propósito — esto es efecto visual, no tracción real

func _ready() -> void:
	var limite_radianes = deg_to_rad(grados_maximos)
	var todas_direccion = direccion_principal + direccion_secundaria
	for joint in todas_direccion:
		if is_instance_valid(joint):
			joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -limite_radianes)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, limite_radianes)
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)

	var todas_traccion = traccion_principal + traccion_secundaria
	for joint in todas_traccion:
		if is_instance_valid(joint):
			_set_motor_active(joint, false)

	# Conectamos la caja a su fuente de potencia una sola vez
	if is_instance_valid(caja_cambios) and is_instance_valid(motor):
		caja_cambios.fuente = motor

func _physics_process(delta: float) -> void:
	if modo_dinamometro:
		_neutralizar_joints()
		return

	if Input.is_action_just_pressed("press_i"):
		if is_instance_valid(motor):
			motor.alternar_encendido()
	
	var volante = Input.get_axis("press_a", "press_d") 
	var acelerador = Input.get_action_strength("press_w")
	var freno = Input.is_action_pressed("press_space") or Input.is_action_pressed("press_s")
	
	if Input.is_action_just_pressed("press_tab"):
		traccion_total_activada = !traccion_total_activada
		print("Tracción Total: ", "ACTIVADA" if traccion_total_activada else "DESACTIVADA")
	
	if Input.is_action_just_pressed("press_q"):
		diferencial_bloqueado = !diferencial_bloqueado
		print("Diferencial: ", "BLOQUEADO" if diferencial_bloqueado else "ABIERTO")
	
	if Input.is_action_just_pressed("press_esc"):
		for i in range(4):
			modo_direccion_actual = (modo_direccion_actual + 1) % 4 as ModoDireccion
			if modo_direccion_actual == ModoDireccion.NORMAL and permitir_modo_normal:
				print("Dirección: NORMAL (Solo delantera)")
				break
			elif modo_direccion_actual == ModoDireccion.OPUESTA and permitir_modo_opuesta:
				print("Dirección: OPUESTA (Curvas cerradas)")
				break
			elif modo_direccion_actual == ModoDireccion.CANGREJO and permitir_modo_cangrejo:
				print("Dirección: CANGREJO (Marcha diagonal)")
				break
			elif modo_direccion_actual == ModoDireccion.EJE and permitir_modo_eje:
				print("Dirección: EJE (Giro sobre sí mismo)")
				break

	if caja_cambios:
		if Input.is_action_just_pressed("press_e"):
			caja_cambios.subir_marcha()
		if Input.is_action_just_pressed("press_r"):
			caja_cambios.bajar_marcha()

	# --- CÁLCULO DE VELOCIDAD Y FLUJO DE AIRE ---
	# Una sola vez ahora. Antes se recalculaba 3 veces por frame en este método
	# y las últimas dos siempre daban 0 (posicion_anterior ya se había
	# reasignado) — ver auditoría de la Etapa 0.1. Aprovechado para corregirlo.
	velocidad_real_camion = (global_position - posicion_anterior).length() / delta
	posicion_anterior = global_position
	var flujo_aire = velocidad_real_camion

	if is_instance_valid(motor): motor.flujo_aire = flujo_aire
	if is_instance_valid(caja_cambios): caja_cambios.flujo_aire = flujo_aire
	if is_instance_valid(radiador): radiador.flujo_aire = flujo_aire

	# --- LÓGICA DE DIRECCIÓN --- (sin cambios)
	var todas_direccion = direccion_principal + direccion_secundaria
	for joint in todas_direccion:
		if not is_instance_valid(joint): continue
		var velocidad_actual = 0.0
		var es_secundaria = direccion_secundaria.has(joint)
		if es_secundaria and modo_direccion_actual == ModoDireccion.NORMAL:
			if auto_centrar:
				var mangueta = joint.get_node_or_null(joint.node_b) as Node3D
				var brazo = joint.get_node_or_null(joint.node_a) as Node3D
				if mangueta and brazo:
					var transform_local = brazo.global_transform.affine_inverse() * mangueta.global_transform
					var angulo_actual = transform_local.basis.get_euler().y 
					if abs(angulo_actual) > 0.01:
						velocidad_actual = angulo_actual * velocidad_retorno 
		else:
			var multiplicador_giro = 1.0
			if modo_direccion_actual == ModoDireccion.EJE:
				var pos_local = to_local(joint.global_position)
				var lado = sign(pos_local.x) 
				if es_secundaria:
					multiplicador_giro = lado * -1.0
				else:
					multiplicador_giro = lado * 1.0
			elif es_secundaria:
				if modo_direccion_actual == ModoDireccion.OPUESTA:
					multiplicador_giro = -1.0
				elif modo_direccion_actual == ModoDireccion.CANGREJO:
					multiplicador_giro = 1.0
			if abs(volante) > 0.05:
				velocidad_actual = velocidad_volante * (volante * multiplicador_giro)
			else:
				if auto_centrar:
					var mangueta = joint.get_node_or_null(joint.node_b) as Node3D
					var brazo = joint.get_node_or_null(joint.node_a) as Node3D
					if mangueta and brazo:
						var transform_local = brazo.global_transform.affine_inverse() * mangueta.global_transform
						var angulo_actual = transform_local.basis.get_euler().y 
						if abs(angulo_actual) > 0.01:
							velocidad_actual = angulo_actual * velocidad_retorno 
		joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, velocidad_actual)
		joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_direccion)

	if is_instance_valid(radiador):
		radiador.procesar_flujo_aire(velocidad_real_camion, delta)

	# --- CADENA DE POTENCIA ---
	var inclinacion = global_transform.basis.y.dot(Vector3.UP)
	var motor_ahogado = inclinacion < 0.2 
	var acelerador_efectivo = 0.0 if motor_ahogado else acelerador

	# 1. Rotación real de las ruedas motrices — ahora tiene que ir ANTES de
	# llamar a la caja, porque la caja necesita vel_ruedas para procesar()
	var vel_giro_ruedas: float = 0.0
	var ruedas_contadas: int = 0
	var todas_traccion = traccion_principal + traccion_secundaria
	for joint in todas_traccion:
		if is_instance_valid(joint):
			var cuerpo_rueda = get_node_or_null(joint.node_b) as RigidBody3D
			if cuerpo_rueda:
				vel_giro_ruedas += cuerpo_rueda.angular_velocity.length()
				ruedas_contadas += 1
	if ruedas_contadas > 0:
		vel_giro_ruedas /= ruedas_contadas

	# 2. Motor + caja: antes eran dos llamadas separadas (motor.procesar_motor(),
	# después caja_cambios.procesar_transmision() con el resultado). Ahora la
	# caja es quien maneja al motor internamente — solo le damos sus inputs
	# y la llamamos una vez.
	var vel_salida := 0.0
	var fuerza_salida := 0.0
	var en_parking := false

	if is_instance_valid(caja_cambios):
		caja_cambios.input_acelerador = acelerador_efectivo
		caja_cambios.vel_ruedas = vel_giro_ruedas
		caja_cambios.procesar(delta)
		vel_salida = caja_cambios.velocidad_salida
		fuerza_salida = caja_cambios.fuerza_salida
		en_parking = caja_cambios.freno_parking

	# --- APLICACIÓN DE FUERZAS A LAS RUEDAS ---
	for joint in todas_traccion:
		if not is_instance_valid(joint): continue
		var tiene_potencia = true
		if not traccion_total_activada and traccion_secundaria.has(joint):
			tiene_potencia = false

		if en_parking:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_frenado * 5.0) 
		elif freno:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_frenado)
		elif tiene_potencia and fuerza_salida > 0.0:
			var fuerza_final = fuerza_salida
			if diferencial_bloqueado:
				fuerza_final *= multiplicador_diferencial
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_salida)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_final)
		else:
			_set_motor_active(joint, false)
