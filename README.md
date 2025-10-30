# 🚦 Simulador de Semáforo Inteligente

Simulador de tráfico vehicular desarrollado en **Godot Engine** que compara dos estrategias de control de semáforos: un sistema de tiempo fijo tradicional y un sistema inteligente basado en sensores.

## Descripción

Este proyecto simula una intersección de dos calles (Norte-Sur y Este-Oeste) con flujos vehiculares diferentes. El sistema permite observar y comparar la eficiencia de dos modos de control:

1. **Modo Semáforo Fijo (Tradicional)**: Cambios de luz basados en tiempos predeterminados
2. **Modo Sensores Inteligentes**: Cambios dinámicos basados en detección de vehículos en tiempo real

## Funcionamiento

### Inicio de la Simulación

Al ejecutar el proyecto, el simulador inicia automáticamente en **Modo Semáforo Fijo**:

- La luz Este (horizontal) comienza en VERDE
- La luz Norte (vertical) comienza en ROJO
- Los vehículos empiezan a generarse en ambas direcciones

### Modo 1: Semáforo Fijo (TONTO)

**Características:**

- Utiliza tiempos predeterminados para cada dirección
- **Tiempo verde Este**: 15 segundos
- **Tiempo verde Norte**: 5 segundos
- Los cambios ocurren automáticamente sin considerar el tráfico real
- Puede generar ineficiencias cuando una dirección está vacía

**Comportamiento:**

```
Este VERDE (15s) → Norte VERDE (5s) → Este VERDE (15s) → ...
```

### Modo 2: Sensores Inteligentes (EFICIENTE)

**Características:**

- Activa después de un tiempo determinado (configurable con `TimerCambioDeModo`)
- Monitorea constantemente el número de vehículos esperando en cada dirección
- Toma decisiones inteligentes basadas en tres criterios:

#### Criterios de Cambio:

1. **Calle vacía**: Si la dirección actual está vacía y hay vehículos esperando en la otra, cambia inmediatamente

```
   Ejemplo: Este está VERDE pero no hay autos → Cambia a Norte si hay autos esperando
```

2. **Tiempo mínimo**: Respeta un tiempo mínimo de 3 segundos en verde para evitar cambios bruscos

3. **Desbalance de tráfico**: Si una dirección tiene 3 o más vehículos adicionales esperando, prioriza esa dirección

```
   Ejemplo: Norte tiene 8 autos esperando, Este tiene 2 → Cambia a Norte
```

#### Proceso de Cambio Seguro:

Para evitar colisiones, el sistema implementa un cambio en dos fases:

```
FASE 1: Semáforo actual → ROJO (Despeje de intersección - 2 segundos)
FASE 2: Semáforo contrario → VERDE
```

Este tiempo de despeje permite que los vehículos que ya están cruzando terminen de pasar antes de dar luz verde a la otra dirección.

## Sistema de Vehículos

### Generación de Vehículos

Los vehículos se generan automáticamente con diferentes frecuencias:

- **Dirección Norte** (vertical):

  - Frecuencia alta: cada 0.3 a 0.6 segundos
  - Simula una calle principal con tráfico denso

- **Dirección Este** (horizontal):
  - Frecuencia baja: cada 15 a 20 segundos
  - Simula una calle secundaria con tráfico ligero

### Comportamiento de los Vehículos

- **Velocidad**: 150 unidades/segundo
- **Detección frontal**: Cada vehículo tiene un sensor que detecta al auto de adelante
- **Respeto al semáforo**: Se detienen automáticamente en luz roja
- **Reinicio de marcha**: Continúan cuando el semáforo cambia a verde
- **Eliminación**: Se destruyen al completar su recorrido

### Sensores de Spawn

Cada dirección tiene un sensor que evita generar vehículos cuando:

- Ya hay un vehículo en el punto de generación
- Previene colisiones en el spawn point

## Componentes del Sistema

### 1. Control Principal (`Main.gd`)

- Gestiona el cambio entre modos
- Implementa la lógica inteligente
- Controla los temporizadores de spawn y semáforos

### 2. Semáforos (`Semaforo.gd`)

- Detectan vehículos en su área
- Mantienen lista de vehículos detenidos
- Cambian entre estado ROJO y VERDE
- Reportan cantidad de vehículos esperando

### 3. Sensores de Spawn (`SpawnSensor.gd`)

- Detectan si el punto de generación está obstruido
- Previenen spawn de vehículos sobre otros vehículos

### 4. Vehículos (`Auto.gd`)

- Siguen un camino predefinido (Path2D)
- Responden a señales del semáforo
- Detectan vehículos adelante con RayCast2D
- Se auto-destruyen al completar el recorrido

## Métricas de Eficiencia

El sistema permite observar:

- **Tiempo de espera**: Cuánto esperan los vehículos en cada modo
- **Flujo vehicular**: Cantidad de vehículos que pasan por unidad de tiempo
- **Congestión**: Acumulación de vehículos en luz roja
- **Adaptabilidad**: Respuesta del sistema a cambios en el flujo

### Comparación Esperada:

| Aspecto                         | Modo Fijo                     | Modo Inteligente |
| ------------------------------- | ----------------------------- | ---------------- |
| Eficiencia con tráfico variable | ❌ Baja                       | ✅ Alta          |
| Tiempo de espera promedio       | ⚠️ Alto                       | ✅ Bajo          |
| Adaptabilidad                   | ❌ Nula                       | ✅ Excelente     |
| Desperdiciodeficiencia          | ⚠️ Alto (luces verdes vacías) | ✅ Mínimo        |

## Configuración

Puedes ajustar los siguientes parámetros desde el Inspector de Godot:

```gdscript
# Frecuencia de spawn
min_spawn_time_norte = 0.3      # Mínimo tiempo entre autos (Norte)
max_spawn_time_norte = 0.6      # Máximo tiempo entre autos (Norte)
min_spawn_time_este = 15.0      # Mínimo tiempo entre autos (Este)
max_spawn_time_este = 20.0      # Máximo tiempo entre autos (Este)

# Tiempos de semáforo (Modo Fijo)
tiempo_verde_semaforo_norte = 5.0   # Verde en dirección Norte
tiempo_verde_semaforo_este = 15.0   # Verde en dirección Este

# Tiempos de seguridad (Modo Inteligente)
tiempo_despeje = 2.0                # Tiempo de despeje entre cambios
tiempo_minimo_verde = 3.0           # Tiempo mínimo antes de cambiar
```

## Debugging

El sistema incluye mensajes de consola para seguimiento:

```
--- INICIANDO SIMULACIÓN EN MODO: Semáforo Fijo (TONTO) ---
CAMBIANDO A: NORTE (ROJO), ESTE (VERDE)
DEBUG - Norte esperando: 5 | Este esperando: 0 | Norte en rojo: true | Tiempo en verde: 4.2
SMART: Este vacío, Norte tiene 5 autos. Cambiando a Norte.
FASE 1: Poniendo Este en ROJO (despejando intersección)
FASE 2: Poniendo Norte en VERDE
```

## Requisitos

- **Godot Engine**: 4.0 o superior
- **Escenas necesarias**:
  - `auto.tscn`: Escena del vehículo
  - Nodos Path2D configurados para rutas
  - Áreas 2D para semáforos y sensores

---

**Nota**: Este simulador es una representación simplificada. Los sistemas de tráfico reales involucran muchos más factores como peatones, clima, accidentes, eventos especiales, etc.
