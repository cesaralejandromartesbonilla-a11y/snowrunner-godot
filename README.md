# SnowRunner Godot 4.6 — Ecosistema 1 (Gameplay)

Recreación de la jugabilidad y mecánicas de SnowRunner en **Godot 4.6** utilizando la física nativa de `VehicleBody3D`.

---

## Estado Actual: Pre-MVP (Fase 3 Completa / Fases 4 y 5 Prototipadas)

El Ecosistema 1 cuenta con el bucle jugable base completamente conectado:
`Garaje 3D → Selección de Mapa → Conducción con Terrenos y Marchas → Tablón de Contratos → Carga / Entrega de Mercancía → Recompensa Económica → Compra / Almacén de Vehículos y Remolques`.

Sin embargo, múltiples sistemas están en estado **bruto / sin pulir**, con decadencias físicas, desajustes de geometría y fallos predecibles documentados a continuación.

---

## 1. Lo Implementado y Avanzado (Ecosistema 1)

### 1.1 Controlador del Vehículo (`camioneta.gd`)
- **VehicleBody3D nativo** con simulación de masa y centro de gravedad.
- **Caja de cambios secuencial/realista**: `R (-3)`, `N (-2)`, `L (-1)`, `1 (0)`, `2 (1)`, `3 (2)`, `4 (3)`.
- **Modos de transmisión**: Automático (shifting por velocidad/gas) y Manual (Shift/Ctrl).
- **Curva de potencia y torque**: cálculo de RPM dependiente del ratio de marcha y velocidad lineal.
- **Tracción AWD y Bloqueo de Diferencial**:
  - Restricciones según `VehicleStats` (`ALWAYS_ON`, `SWITCHABLE`, `UPGRADE_NEEDED`, `NONE`).
  - Penalización de consumo diferencial: AWD (+15%), Diff Lock (+5%), Marcha Low (+20%).
- **Consumo y nivel de combustible**: apagado del motor al vaciarse el tanque.
- **Detección de terreno por rueda**: integración con `WheelTerrainDetector` para fricción y resistencia dinámica.
- **Sistema de acople de remolques**:
  - Detección de proximidad mediante `PuntoAcopleRemolque` / `QuintaRueda`.
  - Creación y liberación dinámica de `ConeTwistJoint3D`.
  - Exclusión de colisiones mutuas entre camión y remolque acoplado.

### 1.2 Catálogo de 6 Vehículos (`VehicleStats` Resources)
| Vehículo | Archivo Escena | Clase | Masa | Combustible | AWD | Diff Lock | Precio |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Chevrolet CK1500** | `ck1500.tscn` | Scout | 2,000 kg | 80 L | Switchable | Upgrade | Gratis (Inicial) |
| **Fleetstar F2070A** | `fleetstar.tscn` | Heavy Duty | 6,300 kg | 240 L | Upgrade | Switchable | $800 |
| **Azov 67096 Atom** | `atom.tscn` | Heavy | 15,528 kg | 350 L | Switchable | Always On | $2,500 |
| **Kirovets K-700** | `k700.tscn` | Special | 12,008 kg | 340 L | Always On | Switchable | $2,000 |
| **Pacific P16** | `p16.tscn` | Super Heavy | 25,000 kg | 300 L | NONE (RWD) | Always On | $3,500 |
| **KOLOB 74941** | `kolob.tscn` | Super Heavy | 26,500 kg | 340 L | Switchable | Switchable | $4,000 |

### 1.3 Sistema de Terrenos (`TerrainManager` & `WheelTerrainDetector`)
- **14 tipos de terreno soportados**: Asfalto, Tierra, Barro (Ligero/Estándar/Profundo/Extremo), Nieve (Estándar/Profunda), Hielo, Agua (Poco/Media/Profunda), Roca.
- **Fricción y Resistencia aplicada por fuerza central**: reduce la velocidad del vehículo según la profundidad del barro/nieve.
- **Daño por inmersión en líquidos**: pérdida de combustible o detención en agua profunda.
- **`TerrainZone` (Area3D)**: zonas perimetrales en los mapas que inyectan el tipo de terreno a las ruedas.

### 1.4 Sistema de Remolques (Trailers)
- **`TrailerData` Resource**: definición de masa, precio, slots de carga y tipo.
- **3 Variantes de Remolque creadas**:
  - `trailer_basico.tscn` (1,500 kg): remolque de arrastre ligero sin slots.
  - `trailer_carga.tscn` (2,000 kg): plataforma con 4 slots de carga.
  - `trailer_carga_largue.tscn` (3,500 kg): plataforma extendida de 6 slots.
- **`TrailerManager` (Autoload)**: compra, posesión, inventario de patio y equipamiento.
- **Trailer Spawner HUD (Tecla Y)**: menú emergente en partida para desplegar remolques en el punto de spawn del mapa.
- **Patio de remolques visual en Garaje**: visualización 3D de los remolques poseídos.

### 1.5 Sistema de Carga y Contratos
- **`ContratoManager` (Autoload)**: 8 contratos distribuidos entre los 3 mapas.
- **Recursos de carga**: `suministros.tres`, `troncos.tres`, `combustible.tres`, `repuestos.tres`.
- **`ContractBoard`**: panel de aceptación con tecla `F`.
- **`ContractMarker` / `CargoLoadingZone`**: zonas de carga y descarga de slots en camión o remolque.
- **`ContractHUD`**: interfaz con brújula orientada al objetivo activo y distancia en tiempo real.

### 1.6 Mapas
- **Río Negro (Michigan)**: `rio_negro.tscn` — 200x200m, zonas de barro, carretera, garaje, gasolinera, 4 contratos, 3 watchtowers, gateway a Alaska, spawn point y remolques pre-posicionados.
- **Alaska**: `alaska.tscn` — Nieve, hielo, garaje, gasolinera, 2 contratos, 2 watchtowers, gateways a Río Negro y Taymyr.
- **Taymyr (Siberia)**: `taymyr.tscn` — Pantano, barro extremo, garaje, gasolinera, 2 contratos, 2 watchtowers, gateway a Alaska.

### 1.7 UI y Garaje
- **Garaje 3D con 5 bahías**: navegación de slots, animaciones de cámara.
- **Paneles**: Tienda de camiones, Almacén infinito, Selección de mapas, Patio de remolques, Reparación ($50) y Repostaje ($20).
- **HUD de Instrumentos**: Velocímetro, Tacómetro RPM, Nivel de Combustible, Marcha actual y Estado AWD/Diff.

---

## 2. Decadencias, Sin Pulir y Fallos Conocidos / Predecibles

A pesar de que el código compila y las escenas cargan, existen deficiencias críticas a tener en cuenta:

### ⚠️ Física de Ruedas y Geometría de Chasis
1. **Offsets de ruedas desalineados**: Solo el **CK1500** tiene las ruedas alineadas a su malla. Los otros 5 vehículos (`fleetstar`, `atom`, `k700`, `p16`, `kolob`) fueron clonados con posiciones de `VehicleWheel3D` genéricas, lo que provoca:
   - Ruedas que flotan o traspasan el chasis visual.
   - Centro de masa incorrecto que facilita volcaduras inmediatas al girar a alta velocidad.
2. **Radio de ruedas hardcodeado**: `VehicleWheel3D.wheel_radius` no se lee dinámicamente desde `VehicleStats`, debiendo ajustarse manualmente por vehículo.
3. **K-700 Articulado no funcional en gameplay**: En `gameplay/vehicles/k700.tscn` se comporta como un vehículo rígido de 4 ruedas convencional. El sistema de dos cuerpos unidos por `HingeJoint3D` (`k700_articulado.tscn`) está aislado y carece de sincronización de dirección y tracción en partida normal.
4. **Resistencia de terreno por `apply_central_force`**: La resistencia al barro se aplica al centro de masa del chasis en lugar de resistencia individual rueda por rueda, provocando desaceleraciones poco naturales en pendientes.

### ⚠️ Sistema de Remolques y Acople
1. **Inestabilidad del `ConeTwistJoint3D`**: Al desacoplar o remolcar a alta velocidad o sobre terreno rocoso, el Joint físico puede sufrir tirones bruscos (*jittering*) o voltear el camión tractor.
2. **Colisión de remolques con el suelo**: Algunos remolques spawnearán ligeramente enterrados si el `TrailerSpawnPoint` del mapa no tiene suficiente elevación en el eje Y.
3. **Auto-acople sin add-on Saddle verificado en mapas**: Los remolques estáticos en los mapas permiten acople cercano aunque el camión no tenga instalada la pieza visual de 5ª rueda en su chasis.

### ⚠️ Add-Ons (Fase 4 Parcial)
1. **Add-ons sin representación visual / modular 3D**: `AddOnComponent` y `camioneta.gd` generan nodos lógicos (`Marker3D`, `FlatbedSlots`, `QuintaRueda`) por código, pero no instancian modelos 3D detallados de grúa, cisterna o camas de carga.
2. **Falta de Grúa funcional interactiva**: Aunque existe la lógica de detección, el brazo articulado de la grúa no se puede controlar con ratón/joystick para cargar física independiente.

### ⚠️ Transmisión y Shifting Automático
1. **Transición a Reversa brusca**: El modo automático cambia a `R` (-3) si se mantiene presionado el freno (`S`), pero puede provocar oscilaciones entre marcha 1 y reversa en pendientes empinadas.
2. **Sin freno de mano independiente**: La barra espaciadora aplica freno a las ruedas, pero no existe bloqueo de estacionamiento persistente al bajar del vehículo.

### ⚠️ Winch (Cabrestante) / Rescate
1. **Winch sin física de cable**: No existe un cable dinámico visible con tensión elástica; solo existe la comprobación lógica en `RecoveryManager`.
2. **Sin Quick Winch**: No hay atajo rápido de teclado para lanzar un cable de rescate al árbol/poste más cercano durante un vuelco.

### ⚠️ Daño, Audio y Efectos Visuales
1. **Sistema de daño inexistente**: Los choques a alta velocidad, la inmersión de motor en agua y el uso de bloqueo de diferencial en asfalto no degradan componentes ni reducen potencia.
2. **Sin audio de motor dinámico**: No hay `AudioStreamPlayer3D` modulando el *pitch* o volumen según las RPM calculadas.
3. **Sin partículas de terreno**: No hay emisores de partículas de barro salpicando ni huellas deformadas en el suelo (deformación de malla no implementada en Ecosistema 1).

### ⚠️ Guardado y Carga (`GlobalData`)
1. **Sin versionado de savegame**: El archivo `user://partida_guardada.save` usa `ConfigFile` plano. Si se renombran rutas de escenas o variables de inventario, la partida guardada anterior puede quedar corrupta o generar `null references`.

---

## 3. Mapeo de Controles (Input Map)

| Acción | Tecla / Control | Función |
| :--- | :--- | :--- |
| **Acelerar** | `W` | Aplica torque motor |
| **Frenar / Reversa** | `S` | Freno de servicio / Retroceso |
| **Dirección** | `A` / `D` | Giro ruedas delanteras |
| **Freno de Mano** | `Espacio` | Frena ruedas traseras |
| **Encender / Apagar Motor** | `E` | Toggle encendido motor |
| **Subir Marcha (Manual)** | `Shift` | 1 → 2 → 3 → 4 |
| **Bajar Marcha (Manual)** | `Ctrl` | 4 → 3 → 2 → 1 → L → N → R |
| **Toggle Auto / Manual** | `T` | Cambia lógica de transmisión |
| **Toggle AWD (4x4)** | `Z` | Alterna tracción total (si disponible) |
| **Toggle Diff Lock** | `X` | Alterna bloqueo diferencial (si disponible) |
| **Interactuar / Aceptar** | `F` | Tableros, Gasolineras, Carga, Acople remolque |
| **Trailer Spawner HUD** | `Y` | Abrir menú para desplegar remolques |
| **Menú / Pausa** | `Esc` | Volver o pausar |

---

## 4. Estructura de Directorios

```
snowrunner-godot/
├── autoloads/
│   ├── global_data.gd          # Dinero, slots de garaje, inventario, save/load
│   ├── terrain_manager.gd      # 14 tipos de terreno, fricción y daño
│   ├── contrato_manager.gd     # Estados de contratos y recompensas
│   ├── trailer_manager.gd      # Compra, posesión y despacho de remolques
│   └── recovery_manager.gd     # Lógica de rescate y autorrescate
├── gameplay/
│   ├── main.gd                 # Controlador del nivel en curso y HUD
│   ├── vehicles/
│   │   ├── camioneta.gd        # Controlador unificado VehicleBody3D
│   │   ├── vehicle_body.gd     # Script base auxiliar para instancias de mapa
│   │   ├── resources/          # VehicleStats, TrailerData, AddOnData
│   │   ├── components/         # WheelTerrainDetector, ArticulatedJoint, AddOnComponent
│   │   ├── trailers/           # Escenas y datos de los 3 remolques
│   │   └── *.tscn              # ck1500, fleetstar, atom, k700, p16, kolob
│   ├── maps/
│   │   ├── rio_negro.tscn      # Mapa Michigan
│   │   ├── alaska.tscn         # Mapa Nieve
│   │   └── taymyr.tscn         # Mapa Pantano
│   ├── cargo/                  # CargoData, ContractBoard, ContractMarker, Zonas
│   ├── world/                  # Gasolineras, Gateways, Watchtowers, Zonas de terreno
│   └── ui/                     # Garaje, Tienda, Almacén, Selector de Mapas, HUDs
├── data/
│   ├── vehicles/*_stats.tres   # Recursos de estadísticas por vehículo
│   └── surfaces/               # Materiales de terreno
├── testing/                    # Ecosistema 2: módulos de física avanzada (NO MEZCLAR)
└── legacy/                     # Archivos antiguos preservados para referencia
```

---

## 5. Regla Fundamental de Arquitectura

- **Ecosistema 1 (`gameplay/`)**: Está diseñado sobre `VehicleBody3D` nativo de Godot 4.6 para garantizar estabilidad, compatibilidad con la jerarquía del motor y ejecución directa del juego.
- **Ecosistema 2 (`testing/`)**: Contiene experimentos de cinemática modular, cajas de torsión y simulaciones térmicas independientes. **Bajo ninguna circunstancia deben mezclarse ni transferirse scripts de `testing/` a `gameplay/`** sin refactorización previa.
