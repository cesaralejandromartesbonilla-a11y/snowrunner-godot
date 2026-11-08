extends CanvasLayer

# --- CONFIGURACIÓN ---
@export var nodo_camioneta: NodePath # Arrastra tu Vehiculo aquí en el inspector
var vehiculo: Node = null

# --- REFERENCIAS VISUALES (Ajusta las rutas a tus nodos reales del HUD) ---
# Si te da error "null instance", verifica que estas rutas sean correctas en tu escena
@onready var label_velocidad = $PanelInstrumentos/Velocimetro
@onready var label_marcha = $PanelInstrumentos/MarchaLabel
@onready var barra_rpm = $PanelInstrumentos/RPMProgress
@onready var barra_combustible = $PanelInstrumentos/CombustibleBar
@onready var icono_4x4 = $PanelInstrumentos/Indicador4x4
@onready var icono_diff = $PanelInstrumentos/IconoDiff

# Colores para estados (Verde encendido, Rojo/Gris apagado)
var color_activo = Color(0, 1, 0, 1) # Verde
var color_inactivo = Color(0.5, 0.5, 0.5, 0.5) # Gris oscuro

func _ready() -> void:
	if nodo_camioneta:
		vehiculo = get_node(nodo_camioneta)
	else:
		vehiculo = get_parent()
	
	if vehiculo and vehiculo.has_signal("datos_actualizados"):
		vehiculo.datos_actualizados.connect(_actualizar_relojes)
		if vehiculo.has_signal("traccion_cambiada"):
			vehiculo.traccion_cambiada.connect(_actualizar_icono_4x4)
		if vehiculo.has_signal("dif_cambiado"):
			vehiculo.dif_cambiado.connect(_actualizar_icono_diff)
		if vehiculo.has_signal("motor_estado_cambiado"):
			vehiculo.motor_estado_cambiado.connect(_actualizar_motor)
		_actualizar_icono_4x4(vehiculo.es_4x4)
		_actualizar_icono_diff(vehiculo.dif_bloqueado)

# --- ACTUALIZACIÓN CONTINUA ---
func _actualizar_relojes(combustible: float, velocidad: float, rpm: float, marcha: String = "A") -> void:
	if label_velocidad:
		label_velocidad.text = str(int(velocidad)) + " km/h"
	
	if barra_rpm:
		barra_rpm.value = rpm
		
	if barra_combustible:
		barra_combustible.value = combustible
		if combustible < 20:
			barra_combustible.modulate = Color(1, 0, 0)
		else:
			barra_combustible.modulate = Color(1, 1, 1)

	if label_marcha:
		if vehiculo.motor_encendido:
			label_marcha.text = marcha
		else:
			label_marcha.text = "OFF"

# --- ICONOS DE ESTADO ---
func _actualizar_icono_4x4(activo: bool) -> void:
	if icono_4x4:
		if activo:
			icono_4x4.modulate = color_activo
			# Si es un Label, podrías poner texto
			if icono_4x4 is Label: icono_4x4.text = "AWD: ON"
		else:
			icono_4x4.modulate = color_inactivo
			if icono_4x4 is Label: icono_4x4.text = "AWD: OFF"

func _actualizar_icono_diff(activo: bool) -> void:
	if icono_diff:
		if activo:
			icono_diff.modulate = color_activo
			if icono_diff is Label: icono_diff.text = "DIFF: LOCK"
		else:
			icono_diff.modulate = color_inactivo
			if icono_diff is Label: icono_diff.text = "DIFF: OPEN"

func _actualizar_motor(encendido: bool) -> void:
	if label_marcha:
		if not encendido:
			label_marcha.text = "OFF"
