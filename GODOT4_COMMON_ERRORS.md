# Referencia Rápida: Errores Comunes y Soluciones (Godot 4.6)

## 1. Dictionary.get() - Solo 1 argumento
```gdscript
# ❌ ERROR: get() solo acepta 1 argumento (la key)
value = dict.get("key", default_value)

# ✅ CORRECTO: usar operador nullish coalescing ??
value = dict.get("key") ?? default_value

# O verificar existencia
if dict.has("key"):
    value = dict["key"]
```

## 2. Transform3D Constructor
```gdscript
# ❌ ERROR: 12 parámetros no funcionan como en Godot 3
Transform3D(1,0,0, 0,1,0, 0,0,1, x, y, z)

# ✅ CORRECTO: Basis + Vector3
Transform3D(Basis.IDENTITY, Vector3(x, y, z))

# Con rotación
Transform3D(Basis().rotated(Vector3.UP, angle), Vector3(x, y, z))

# O usar global_transform/position directamente en Markers/Node3D
marker.position = Vector3(x, y, z)
```

## 3. class_name obligatorio para clases reutilizables
```gdscript
# ✅ Al inicio del archivo
extends Node3D
class_name MiClase
```

## 4. HingeJoint3D Parámetros (Godot 4)
```gdscript
# ❌ ERROR: set_param/get_param con constantes antiguas
set_param(HingeJoint3D.PARAM_SWING_SPAN, deg_to_rad(45))

# ✅ CORRECTO: Propiedades directas
limit_angular_lower = deg_to_rad(-45)
limit_angular_upper = deg_to_rad(45)
limit_twist_lower = deg_to_rad(-15)
limit_twist_upper = deg_to_rad(15)
bias = 0.3
damping = 0.5
```

## 5. Signal Connection con lambda
```gdscript
# ❌ ERROR: is_connected() no funciona con lambdas inline
if not signal.is_connected(func(): ...)

# ✅ CORRECTO: Guardar referencia o usar callable
var callable = Callable(self, "_callback")
if not signal.is_connected(callable):
    signal.connect(callable)
```

## 6. RigidBody3D Reparenting
```gdscript
# ✅ Patrón correcto (de box.gd reference)
func acoplar_a_vehiculo(nuevo_padre, marcador):
    freeze = true
    collision_layer = 0
    collision_mask = 0
    reparent(nuevo_padre)
    global_transform = marcador.global_transform
    PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)
    if is_inside_tree(): force_update_transform()
```

## 7. VehicleBody3D Wheel Properties
```gdscript
# ✅ Propiedades requeridas en VehicleWheel3D
wheel_radius = 0.45           # Radio real de la rueda
wheel_roll_influence = 0.4    # Inclinación al girar
wheel_friction_slip = 1.0     # Deslizamiento lateral
suspension_stiffness = 50.0   # Rigidez suspensión
damping_compression = 0.88    # Amortiguación compresión
use_as_traction = true/false  # Tracción
use_as_steering = true/false  # Dirección
```

## 8. VehicleBody3D Properties
```gdscript
mass = 2000.0
center_of_mass_mode = VehicleBody3D.CENTER_OF_MASS_MODE_CUSTOM
center_of_mass = Vector3(0, -0.3, 0)  # Bajado para estabilidad
```

## 9. Area3D para Detection (Terrain Zones)
```gdscript
# terrain_zone.gd pattern
collision_layer = 0
collision_mask = 0
body_entered.connect(_on_body_entered)
body_exited.connect(_on_body_exited)
area_entered.connect(_on_area_entered)
area_exited.connect(_on_area_exited)
```

## 10. Save/Load con FileAccess
```gdscript
# Godot 4
var file = FileAccess.open(path, FileAccess.WRITE)
file.store_var(data)
file.close()

var file = FileAccess.open(path, FileAccess.READ)
var data = file.get_var()
file.close()
```

## 11. Common Pitfalls Checklist
- [ ] `dict.get(key) ?? default` no `dict.get(key, default)`
- [ ] `Transform3D(Basis.IDENTITY, Vector3)` no 12 params
- [ ] `class_name` en archivos reutilizables
- [ ] HingeJoint3D: `limit_angular_lower/upper`, `limit_twist_lower/upper`, `bias`, `damping`
- [ ] `get("key") ?? default` pattern
- [ ] `class_name` antes de funciones
- [ ] `PhysicsServer3D.body_set_state()` tras reparent RigidBody3D
- [ ] VehicleWheel3D: radius, roll_influence, friction_slip, stiffness, damping
- [ ] `collision_layer = 0` y `collision_mask = 0` para zones de detección

## 12. Signals en Godot 4
```gdscript
# Definir
signal mi_senal(param: int)

# Emitir
mi_senal.emit(42)

# Conectar
mi_senal.connect(Callable(self, "_callback"))
# O en _ready:
otro_nodo.senal.connect(_callback.bind(args))
```

## 12. Preload vs Load
```gdscript
# Recursos constantes - preload (compile-time)
const MI_ESCENA = preload("res://path.tscn")

# Recursos dinámicos - load (runtime)
var escena = load("res://path.tscn")
```

## 13. Node3D Position vs Transform
```gdscript
# Para posiciones simples - usar position
marker.position = Vector3(0, 1.5, -1.0)

# Para transform completas con rotación
marker.transform = Transform3D(Basis().rotated(Vector3.UP, PI/2), Vector3(0, 1.5, -1.0))

# global_transform para coordenadas mundiales
global_position = Vector3(10, 5, 10)
global_transform = Transform3D(Basis.IDENTITY, Vector3(10, 5, 10))
```

---

**Nota**: Este documento cubre los errores encontrados durante el desarrollo. Actualizar según se encuentren nuevos patrones.