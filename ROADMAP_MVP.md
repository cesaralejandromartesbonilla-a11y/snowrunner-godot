# SnowRunner Godot - Hoja de Ruta MVP

## Estado Actual del Proyecto

### Lo que YA funciona (map_demo_2)
| Sistema | Estado | Detalle |
|---------|--------|---------|
| VehicleBody3D controller | Funcional | `camioneta.gd`: torque, RPM, 4x4, diff lock, freno |
| Mud básico | Funcional | 4 tipos por grupo (ligero→extremo), detección por contact body, drag cuadrático |
| Combustible | Funcional | Consumo base, AWD/diff lo incrementan, repostar en gasolinera (infinita) |
| Carga | Mínimo | Bool binario (`tiene_carga`), sin peso ni tipo |
| Remolque | Funcional | Acople por Marker3D + ConeTwistJoint3D, distancia 2.5m |
| Gasolinera | Funcional | Area3D, repostaje cuando motor apagado |
| Garaje 3D | Funcional | 5 slots, cámara tween, customización de motor/ruedas/caja |
| Save/Load | Funcional | `GlobalData`, `store_var()`, sin versioning |
| Mapas | Mínimo | 1 mapa, transición instantánea, sin gateways |
| HUD | Mínimo | `canvas_layer.gd` muestra velocidad/RPM/combustible |

### Lo que está roto o incompleto
| Bug | Severidad |
|-----|-----------|
| `ui_garaje.gd` referencia `GestionGaraje` (autoload inexistente) | CRASH |
| `borrar_partida()` no resetea `garaje_slots` | BUG |
| `mud_area.gd` llama métodos que ningún vehículo implementa | DEAD CODE |
| `menu_customizacion.gd` tiene rutas `.tres` hardcodeadas | FRAGILE |
| Sin transición de escena entre mapas | MISSING |
| Sin sistema de daño | MISSING |
| Sin winch/grúa | MISSING |
| Sin objetivos/misiones | MISSING |
| Sin progresión | MISSING |

### Lo que existe en testing/legacy pero NO está conectado
- Sistema térmico completo (motor, radiador, transmisión, tanque)
- Physics customizadas por módulos (HingeJoint)
- Gestión de peso dinámica (`GestorPeso`)
- Cámara con modos toggle/hold
- Estaciones de prueba (dinamómetro)

---

## Objetivo MVP: SnowRunner Fiel

Recrear la experiencia core de SnowRunner con los 3 mapas, 6 vehículos, y las mecánicas fundamentales que hacen que el juego "se sienta" como SnowRunner.

### Los 6 Vehículos (stats del juego original)

| Vehículo | Clase | AWD | Diff Lock | Masa | Fuel | Tires | Rol |
|----------|-------|-----|-----------|------|------|-------|-----|
| **Chevrolet CK1500** | Scout | Switchable | Upgrade needed | 2,000kg | 80L | 35" | Vehículo inicial, exploración |
| **Fleetstar F2070A** | Heavy Duty | Upgrade needed | Switchable | 6,300kg | 240L | 42" | Workhorse temprano |
| **Azov 67096 "Atom"** | Heavy | Switchable | Always On | 15,528kg | 350L | 50" | Hauling pesado |
| **K-700 Kirivets** | Special | Always On | Switchable | 12,008kg | 340L | 50" | Articulado, tractor |
| **Pacific P16** | Super Heavy | **NONE** | Always On | 25,000kg | 300L | 57" | Mega-carga, sin AWD |
| **KOLOB 74941** | Super Heavy | Switchable | Switchable | 26,500kg | 340L | 50" | Torque extremo |

### Los 3 Mapas

| Mapa | Dificultad | Terreno Key | Vehículos recommended |
|------|-----------|-------------|----------------------|
| **Río Negro (Black River)** | Easy-Medium | Barro, asfalto, some nieve | CK1500, Fleetstar |
| **Alaska** | Medium | Nieve, hielo, carreteras montaña | Atom, CK1500 con cadenas |
| **Taymyr** | Hard | Swamp denso, raíces, bosque | K-700, P16, KOLOB, Atom |

---

## Sistemas MVP - Qué construir

### SISTEMA 1: Terreno Multi-Tipo (PRIORIDAD ALTA)
El terreno es LA mecánica de SnowRunner. Actualmente solo tenemos 4 grupos de barro.

**Construir:**
- [ ] `TerrainManager` autoload: mapa de terreno con tipos (asfalto, tierra, barro, nieve, hielo, agua)
- [ ] WheelContactSensor: detección de tipo de terreno bajo cada rueda (ShapeCast3D o RayCast3D)
- [ ] Fricción por tipo de terreno (curvas de fricción: asfalto=1.0, tierra=0.7, barro=0.2-0.05, nieve=0.3, hielo=0.05)
- [ ] Sistema de hundimiento: profundidad por tipo (extrudable vs no-extrudable)
- [ ] Visual feedback: splashes de barro, nieve volando, rocas bajo ruedas
- [ ] Water: empuje de corriente, profundidad crítica para motor

### SISTEMA 2: Física de Vehículo Reescrita (PRIORIDAD ALTA)
`camioneta.gd` funciona pero no es SnowRunner. Necesita:
- [ ] **AWD/Diff por vehiculo**: definidos en recurso (no toggle libre)
  - CK1500: AWD=switchable, Diff=no (hasta upgrade)
  - Fleetstar: AWD=no (hasta upgrade), Diff=switchable
  - Atom: AWD=switchable, Diff=always_on
  - K-700: AWD=always_on, Diff=switchable
  - P16: AWD=NONE, Diff=always_on
  - KOLOB: AWD=switchable, Diff=switchable
- [ ] **Low gears**: L- (crawler), L, 1, 2, 3, 4, Auto. Low gear = menos velocidad pero más torque y control
- [ ] **Consumo diferencial**: AWD +10-15%, Low gear +20%, Diff lock +5%
- [ ] **Weight transfer**: peso del motor en eje delantero, peso de carga en trasero
- [ ] **RPM real**: curva de torque por RPM, no lineal
- [ ] **Freno**: differente por tipo de terreno (hielo = casi nada, asfalto = fuerte)
- [ ] **Centro de gravedad**: influye en volcadura

### SISTEMA 3: Winch/Grúa (PRIORIDAD ALTA)
Sin winch no hay SnowRunner.
- [ ] Puntos de winch en vehículos (front, sides, rear)
- [ ] Puntos de anclaje en mapa (árboles, postes, rocas)
- [ ] Cable visible con física (Line2D o Mesh)
- [ ] Fuerza de tracción configurable por tipo de winch
- [ ] Quick winch (auto-attach al más cercano)
- [ ] Winch autónomo (funciona con motor apagado, solo scouts)
- [ ] Vehículo a vehículo towing

### SISTEMA 4: Combustible Real (PRIORIDAD MEDIA)
- [ ] Tanque por vehiculo (80L-350L, definido en recurso)
- [ ] Gasolineras en mapa (puntos fijos, recarga lenta)
- [ ] Remolques de combustible (transportable,Finite)
- [ ] Bidones/jerry cans (add-on para scouts, 40-80L extra)
- [ ] Transferencia vehículo→vehiculo
- [ ] Fuel cost en Hard Mode

### SISTEMA 5: Sistema de Carga (PRIORIDAD MEDIA)
- [ ] Carga por slots (1-4 slots por vehículo)
- [ ] Tipos de carga: estándar, madera (logs), líquido
- [ ] Almacenes de carga en mapa (puntos de pickup)
- [ ] Peso de carga afecta: fondo de rueda, consumo, volcadura
- [ ] Carga visible en el vehículo (auto-load visual)
- [ ] Requiere tipo de add-on correcto (flatbed, log carrier, saddle)
- [ ] Delivery zones: llevar carga de A a B

### SISTEMA 6: Mapas y Progresión (PRIORIDAD MEDIA)
- [ ] **3 mapas separados**: cada uno con su propio .tscn
- [ ] **Garajes**: repair, refuel, customize, store (1 por mapa)
- [ ] **Watchtowers**: revelan áreas del mapa
- [ ] **Bridges/Roadblocks**: reparar con carga específica para abrir rutas
- [ ] **Gateways**: conexión entre mapas de la misma región
- [ ] **Inter-region travel**: menú global para mover trucks retenidos
- [ ] **Objetivos**: contratos (delivery), contests, tasks
- [ ] **XP/Rank**: ganar XP de tareas, desbloquear tipos de llantas
- [ ] **Truck store**: comprar vehículos con dinero ganado

### SISTEMA 7: Daño (PRIORIDAD BAJA para MVP)
- [ ] Daño por colisión (suspensión, tanque, motor)
- [ ] Daño por agua (motor sumergido)
- [ ] Daño por diff lock en superficie dura (transmisión)
- [ ] Flat tires individuales
- [ ] Repair: garaje (gratis), service trailers (Finite), van addons
- [ ] Visual: deformación, suciedad, humo

---

## Fases de Desarrollo

### FASE 0: Fix Críticos ✅ COMPLETADO
- [x] Fix `ui_garaje.gd` → eliminar referencia a `GestionGaraje`
- [x] Fix `borrar_partida()` → resetear `garaje_slots`
- [x] Decidir: mantener testing/ separado de gameplay/

### FASE 1: Foundation ✅ COMPLETADO
**Objetivo**: Terreno funcional + 1 vehículo que se sienta bien en nieve/barro

1. [x] **TerrainManager** con tipos de terreno (asfalto, tierra, barro, nieve, hielo, agua)
2. [x] **Reescribir vehicle controller**: AWD real, low gears, torque curve, consumo por componentes
3. [x] **Wheel contact system**: detección de terreno bajo cada rueda (WheelTerrainDetector)
4. [x] **Recurso vehiculo**: VehicleStats definido por vehiculo (masa, fuel, awd, diff, tires)
5. [x] **6 vehículos**: CK1500, Fleetstar, Atom, K-700, P16, Kolob — todos con escenas y stats
6. [x] **TerrainZone**: Area3D component para marcar zonas de terreno en mapas
7. [x] **map_demo_2**: zonas de barro convertidas a terrain_zone.gd

### FASE 2: Core Loop ✅ COMPLETADO
**Objetivo**: Conducir → encontrar gasolinera → entregar carga → repetir

1. [x] **Fuel system**: tanque real por VehicleStats, gasolinera v1 con repostaje continuo
2. [x] **Cargo system**: CargoData resource, PickupPoint, DeliveryZone, pickup/deliver en camioneta.gd
3. [x] **Garage**: repair ($50), refuel ($20) con botones, guardar partida al salir
4. [x] **HUD funcional**: speedo, fuel, AWD/diff indicators, dinero, contrato activo
5. [x] **6 vehículos**: todos disponibles con escenas y stats propios
6. [x] **Garage → Map → Garage loop**: funciona con save/load
7. [x] **Tienda**: comprar vehículos con dinero
8. [x] **Almacén**: gestionar vehículos entre slots del garaje

### FASE 3: World Building 🔄 EN PROGRESO
**Objetivo**: Los 3 mapas con contenido

1. [x] **ContratoManager**: sistema de contratos (aceptar → recoger → entregar → cobrar)
2. [x] **Contract Board**: tablero interactivo en el mapa para aceptar contratos
3. [x] **Contract Marker**: puntos de pickup/delivery con interacción F
4. [x] **Contract HUD**: muestra contrato activo, objetivo, dinero
5. [x] **Río Negro**: mapa base con carretera, garage, gasolinera, 4 contratos, terreno mixto
6. [x] **Alaska**: nieve/hielo, garage, gasolinera, 2 contratos
7. [x] **Taymyr**: barro profundo/extremo, garage, gasolinera, 2 contratos
8. [x] **MapSelectionUI**: elegir mapa desde el garaje (3 mapas con progresión por dinero)
9. [x] **Gateways**: transición entre mapas en el mundo (sin pasar por garaje)
   - Río Negro ↔ Alaska ($100)
   - Alaska ↔ Taymyr ($200)
10. [x] **Watchtowers**: 3 torres por mapa, escalables (F en cima), recompensan dinero
    - Río Negro: 3 torres ($50-75)
    - Alaska: 2 torres ($75-100)
    - Taymyr: 2 torres ($100-150)

### FASE 4: All Vehicles (1-2 semanas) ✅ COMPLETADO
**Objetivo**: Los 6 vehículos con personalidad única

1. [x] **Stats por vehiculo**: masa, torque, fuel, tires, addons
2. [x] **Vehicle-specific quirks**: P16 sin AWD, K-700 articulado, Atom always-on diff
3. [x] **Add-ons**: saddle, flatbed, log carrier, crane, fuel tank, winch, snorkel
4. [x] **Add-on slots en garage UI** (equipar/desmontar)
5. [x] **K-700 articulado**: escena con 2 VehicleBody3D + HingeJoint3D
6. [x] **Recovery Manager**: autoload para recuperación a garaje

### FASE 5: Polish (1 semana) 🔄 SIGUIENTE
**Objetivo**: Se siente como SnowRunner
**Objetivo**: Se siente como SnowRunner

1. **Winch system**
2. **Visual polish**: mud splashes, snow particles, dust
3. **Audio**: motor por RPM, mud squelch, water splash
4. **Damage system básico**: collision + water
5. **Save system v2**: versioned, robust
6. **Progression**: XP, ranks, unlock tires

---

## Decisión Arquitectónica Clave

**¿VehicleBody3D (actual) vs reescribir con módulos?**

Recomendación: **Mantener VehicleBody3D** y mejorarlo.
- Ya funciona, ya tiene terreno, ya tiene remolque
- VehicleBody3D de Godot tiene suspensión, steering, engine built-in
- Solo necesitamos AGREGAR: terreno multi-tipo, low gears, weight transfer, AWD real
- Reescribir desde cero = 2+ meses额外的 solo de física
- El sistema de módulos en testing/ es más ambicioso pero no aporta al MVP

**¿Conectar testing/ o reescribir?**

Recomendación: **No conectar**. El thermal/power chain es impresionante pero NO es SnowRunner. SnowRunner no tiene temperatura de motor ni daño por clutch. Concentrarse en lo que SÍ está en el juego original.

---

## MVP Minimum Viable = "Se siente como SnowRunner"

Los 3 pilares que definen la experiencia:

1. **El barro/hielo te frena y tienes que buscar la ruta correcta** → TerrainManager
2. **Tienes que elegir el vehículo correcto para la carga correcta** → Vehicle stats reales + cargo system
3. **Te quedas sin gasolina en medio del barro y tienes que resolverlo** → Fuel management

Todo lo demás (daño, XP, watchtowers, etc.) es Nice-to-Have.
