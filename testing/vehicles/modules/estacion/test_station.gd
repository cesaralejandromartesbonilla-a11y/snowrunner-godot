# Base reutilizable para cualquier estación de trabajo futura (esta de motor,
# y más adelante rueda sola, casco de barco, cabezal de tuneladora...). Maneja
# activación por cercanía + input, cambio de cámara, mostrar/ocultar la
# interfaz, y elevar el cuerpo bajo prueba (si la subclase asigna
# cuerpo_elevado) para que no haya contacto con el suelo mientras se prueba —
# sin eso, cualquier fricción o resto de tracción pelea contra la estación.
extends Area3D
class_name EstacionPrueba

@export var camara_estacion: Camera3D
@export var panel_interfaz: Node3D  # contenedor de los paneles/pantallas 3D de esta estación
@export var accion_activar: String = "press_space"
@export var grupo_jugador: String = "jugador"  # ajustá al grupo/tag real que uses para el jugador
@export var altura_elevacion: float = 0.6  # cuánto se levanta cuerpo_elevado al activar la estación

var jugador_cerca: bool = false
var activa: bool = false
var camara_anterior: Camera3D

# Las subclases asignan esto cuando detectan qué cuerpo va a probarse —
# la base se encarga de levantarlo y congelarlo mientras la estación está activa
var cuerpo_elevado: RigidBody3D
var offset_elevacion_aplicado: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if panel_interfaz:
		panel_interfaz.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(grupo_jugador):
		jugador_cerca = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(grupo_jugador):
		jugador_cerca = false
		if activa:
			_desactivar()

func _physics_process(delta: float) -> void:
	if jugador_cerca and Input.is_action_just_pressed(accion_activar):
		if activa:
			_desactivar()
		else:
			_activar()

func _activar() -> void:
	activa = true
	if camara_estacion:
		camara_anterior = get_viewport().get_camera_3d()
		camara_estacion.current = true
	if panel_interfaz:
		panel_interfaz.visible = true
	#if cuerpo_elevado:
		#cuerpo_elevado.freeze = true
	_al_activar()

func _desactivar() -> void:
	activa = false
	if camara_anterior:
		camara_anterior.current = true
	if panel_interfaz:
		panel_interfaz.visible = false
	if cuerpo_elevado:
		cuerpo_elevado.freeze = false
	_al_desactivar()

# Las estaciones concretas sobreescriben esto para su lógica específica
func _al_activar() -> void:
	pass

func _al_desactivar() -> void:
	pass
