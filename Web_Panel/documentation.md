# Web_Panel — Documentación Técnica Completa

## Índice

1. [Descripción General](#descripción-general)
2. [Tecnologías y Dependencias](#tecnologías-y-dependencias)
3. [Arquitectura](#arquitectura)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Módulos y Ficheros Clave](#módulos-y-ficheros-clave)
   - [Punto de Entrada](#punto-de-entrada)
   - [Routing (Rutas)](#routing-rutas)
   - [Contextos (Context)](#contextos-context)
   - [Servicios (Services)](#servicios-services)
   - [Hooks Personalizados](#hooks-personalizados)
   - [Páginas (Pages)](#páginas-pages)
   - [Componentes (Components)](#componentes-components)
   - [Tipos TypeScript (Types)](#tipos-typescript-types)
   - [Beacon Renderer](#beacon-renderer)
   - [Firebase](#firebase)
6. [Funcionalidades Principales](#funcionalidades-principales)
7. [Sistema de Comandos](#sistema-de-comandos)
8. [Sistema de Emergencias](#sistema-de-emergencias)
9. [Autenticación y Rutas Protegidas](#autenticación-y-rutas-protegidas)
10. [Despliegue](#despliegue)

---

## Descripción General

El **Panel Web de Control de GeoRacing** es la herramienta de gestión centralizada para el personal de organización del evento. Permite:

- Visualizar el estado de todas las balizas físicas del circuito.
- Controlar remotamente cada baliza (modo, mensaje, flechas, brillo).
- Gestionar emergencias y evacuaciones masivas.
- Configurar el estado global del circuito (banderas).
- Monitorizar incidentes reportados por los usuarios.
- Gestionar pedidos y productos.
- Publicar noticias para los fans.
- Ver estadísticas del evento.

---

## Tecnologías y Dependencias

### Framework Principal

| Tecnología | Versión | Justificación |
|---|---|---|
| **React** | 18.2 | Framework de UI declarativo de Meta. El ecosistema más maduro para SPAs. Actualizaciones granulares con virtual DOM. |
| **TypeScript** | 5.2 | Tipado estático sobre JavaScript. Previene errores en tiempo de compilación, mejora el autocompletado y el refactoring. Esencial en un proyecto con muchos tipos de datos (Beacon, Command, CircuitState, etc.). |
| **Vite** | 5.0 | Bundler de desarrollo extremadamente rápido. HMR (Hot Module Replacement) casi instantáneo. Build optimizado para producción con Rollup. Alternativa moderna a Create React App (CRA). |

### UI y Estilos

| Tecnología | Versión | Justificación |
|---|---|---|
| **Tailwind CSS** | 3.3 | Framework de CSS utilitario. Permite estilizar directamente en el JSX sin escribir CSS separado. Reduce el tamaño del CSS final (purge de clases no usadas). Ideal para dashboards con mucha personalización. |
| **lucide-react** | 0.294 | Librería de iconos SVG como componentes React. Más de 1000 iconos con estilo consistente. Sin dependencias adicionales. |
| **PostCSS** | 8.4 | Procesador de CSS para Tailwind. |
| **autoprefixer** | 10.4 | Plugin PostCSS que añade prefijos de vendor automáticamente para compatibilidad cross-browser. |

### Routing

| Tecnología | Versión | Justificación |
|---|---|---|
| **react-router-dom** | 6.20 | Router estándar de React para SPAs. Gestión declarativa de rutas, rutas anidadas, rutas protegidas. Versión 6 con nueva API basada en hooks. |

### Backend y Datos

| Tecnología | Versión | Justificación |
|---|---|---|
| **Firebase SDK** | 10.14 | Firebase Auth para autenticación del personal. Provee login seguro sin necesitar backend propio. |
| **Custom API REST** | - | La mayoría de los datos van a la API REST personalizada (`alpo.myqnapcloud.com:4010`). Firebase solo se usa para Auth del panel. |

### Herramientas de Desarrollo

| Herramienta | Justificación |
|---|---|
| **ESLint** | Linter estático de JavaScript/TypeScript. Detecta errores y malas prácticas. Configurado con reglas para React Hooks. |
| **tsx** | Ejecutor de TypeScript para scripts Node.js. Usado para los scripts de administración (`create-admin-user.ts`). |

---

## Arquitectura

El panel web es una **Single Page Application (SPA)** con arquitectura por capas:

```
┌──────────────────────────────────────────────────┐
│                    Páginas (Pages)                 │
│   Dashboard, Beacons, Incidents, Emergencies...   │
└────────────────────┬─────────────────────────────┘
                     │ usa
┌────────────────────▼─────────────────────────────┐
│              Hooks Personalizados                  │
│   useBeacons, useCircuitState, useZones...        │
└────────────────────┬─────────────────────────────┘
                     │ llama a
┌────────────────────▼─────────────────────────────┐
│                  Servicios                         │
│   apiClient.ts, beaconService.ts, ...             │
└────────────────────┬─────────────────────────────┘
                     │ HTTP REST
┌────────────────────▼─────────────────────────────┐
│               API REST Backend                     │
│   alpo.myqnapcloud.com:4010/api                   │
│   MySQL Database                                  │
└──────────────────────────────────────────────────┘
```

**¿Por qué no Zustand/Redux para estado global?**  
El panel usa React Context para el estado de autenticación (poco frecuente) y props/hooks locales para el estado de datos. Los datos se "re-fetchen" periódicamente en lugar de mantenerse en un store global, lo que simplifica la arquitectura para este caso de uso de dashboard en tiempo real.

---

## Estructura de Carpetas

```
Web_Panel/
│
├── src/
│   ├── App.tsx                      # Componente raíz + definición de rutas
│   ├── main.tsx                     # Punto de entrada React (ReactDOM.render)
│   ├── index.css                    # Estilos globales (Tailwind + custom)
│   ├── vite-env.d.ts                # Tipos de import.meta para Vite
│   │
│   ├── pages/                       # Páginas de la aplicación
│   │   ├── Dashboard.tsx            # Dashboard principal con KPIs
│   │   ├── Beacons.tsx              # Lista y gestión de balizas
│   │   ├── BeaconDetail.tsx         # Detalle de una baliza
│   │   ├── CircuitState.tsx         # Control del estado global del circuito
│   │   ├── Emergencies.tsx          # Panel de emergencias
│   │   ├── Incidents.tsx            # Lista de incidentes
│   │   ├── Logs.tsx                 # Logs de actividad
│   │   ├── Statistics.tsx           # Estadísticas del evento
│   │   ├── ZonesMap.tsx             # Mapa de zonas del circuito
│   │   ├── Routes.tsx               # Rutas del circuito
│   │   ├── Config.tsx               # Configuración general
│   │   ├── ConfigAdvanced.tsx       # Configuración avanzada
│   │   ├── Login.tsx                # Pantalla de login
│   │   ├── OrdersPage.tsx           # Gestión de pedidos
│   │   ├── ProductsPage.tsx         # Gestión de productos
│   │   ├── FoodStandsPage.tsx       # Gestión de puestos de comida
│   │   ├── NewsPage.tsx             # Gestión de noticias para fans
│   │   └── UsersPage.tsx            # Gestión de usuarios
│   │
│   ├── components/                  # Componentes reutilizables
│   │   ├── Layout.tsx               # Layout principal (sidebar + topbar)
│   │   ├── ProtectedRoute.tsx       # HOC de ruta protegida por auth
│   │   ├── BeaconConfigForm.tsx     # Formulario de configuración de baliza
│   │   ├── BeaconEditModal.tsx      # Modal de edición de baliza
│   │   ├── BeaconMetricsCard.tsx    # Tarjeta de métricas de baliza
│   │   ├── BeaconPreview.tsx        # Previsualización de cómo se verá la baliza
│   │   ├── CommandPanel.tsx         # Panel de envío de comandos
│   │   ├── EvacuationModal.tsx      # Modal de evacuación de emergencia
│   │   ├── NewBeaconModal.tsx       # Modal de creación de nueva baliza
│   │   └── Toast.tsx                # Componente de notificaciones toast
│   │
│   ├── context/                     # Contextos de React
│   │   ├── AuthContext.tsx          # Contexto de autenticación (Firebase)
│   │   └── ToastContext.tsx         # Contexto de notificaciones toast
│   │
│   ├── services/                    # Servicios de datos
│   │   ├── apiClient.ts             # Cliente HTTP genérico para la API
│   │   ├── beaconService.ts         # Operaciones de balizas y emergencias
│   │   └── beaconDetectionService.ts # Servicio de detección de nuevas balizas
│   │
│   ├── hooks/                       # Hooks personalizados de React
│   │   ├── useBeacons.ts            # Hook para datos de balizas
│   │   ├── useCircuitState.ts       # Hook para el estado del circuito
│   │   ├── useNewBeaconDetection.ts # Hook para detectar nuevas balizas
│   │   └── useZones.ts              # Hook para datos de zonas
│   │
│   ├── types/
│   │   └── index.ts                 # Tipos TypeScript de toda la app
│   │
│   ├── firebase/
│   │   ├── config.ts                # Configuración de Firebase (API keys)
│   │   └── firebaseApp.ts           # Inicialización del app Firebase
│   │
│   ├── beacon_renderer/             # Motor de renderizado visual de balizas
│   │   ├── RenderEngine.ts          # Motor de renderizado principal
│   │   ├── LayoutEngine.ts          # Motor de layout
│   │   ├── types.ts                 # Tipos del renderizador
│   │   └── components/
│   │       └── ArrowComponent.ts    # Componente de flecha direccional
│   │
│   ├── utils/                       # Funciones de utilidad
│   └── examples/                    # Ejemplos de uso de componentes
│
├── package.json                     # Dependencias y scripts npm
├── tsconfig.json                    # Configuración TypeScript principal
├── tsconfig.node.json               # Configuración TypeScript para Vite
├── vite.config.ts                   # Configuración de Vite
├── tailwind.config.js               # Configuración de Tailwind CSS
├── postcss.config.js                # Configuración de PostCSS
├── firebase.json                    # Configuración Firebase Hosting
├── firestore.indexes.json           # Índices de Firestore
├── firestore.rules                  # Reglas de seguridad de Firestore
├── index.html                       # HTML raíz (punto de montaje de React)
├── users.json                       # Datos de usuarios de prueba
├── GeoRacingDB.json                 # Esquema/datos de la base de datos
│
└── Guías técnicas:
    ├── API_MIGRATION_GUIDE.md
    ├── AUTH_GUIDE.md
    ├── BEACON_CLIENT_EXAMPLE.js
    ├── BEACON_CONFIG_COMPLETE.md
    ├── BEACON_INTEGRATION_GUIDE.md
    ├── BEACON_METRICS_GUIDE.md
    ├── COMMAND_IMPLEMENTATION_SUMMARY.md
    ├── COMMAND_SYSTEM_GUIDE.md
    ├── COMPLETION_REPORT.md
    ├── CUSTOM_TEXT_INTEGRATION_GUIDE.md
    ├── FIRESTORE_SETUP.md
    ├── FUTURE_IMPROVEMENTS_ROADMAP.md
    ├── IMPLEMENTATION_SUMMARY.md
    ├── INTEGRATION_SUMMARY.md
    ├── QUICK_START.md
    ├── SMART_MESSAGES_GUIDE.md
    ├── VERIFICATION_CHECKLIST.md
    └── WPF_INTEGRATION_CHECKLIST.md
```

---

## Módulos y Ficheros Clave

### Punto de Entrada

#### `main.tsx`
Punto de entrada de React. Monta el componente `App` en el elemento `#root` del `index.html`. Usa `React.StrictMode` para detectar efectos secundarios y componentes obsoletos en desarrollo.

#### `App.tsx`
Componente raíz que define:
1. **Árbol de proveedores de contexto:**
   - `AuthProvider` — Provee el contexto de autenticación.
   - `ToastProvider` — Provee el contexto de notificaciones.
   - `BrowserRouter` — Provee el contexto de routing.
2. **Árbol de rutas** con `react-router-dom`:
   - `/login` — Página de login pública.
   - Todas las demás rutas están envueltas en `ProtectedRoute`.
   - La ruta raíz `/` redirige a `/dashboard`.

---

### Routing (Rutas)

| Ruta | Componente | Descripción |
|---|---|---|
| `/login` | `Login` | Página de autenticación |
| `/dashboard` | `Dashboard` | Dashboard con KPIs generales |
| `/users` | `UsersPage` | Gestión de usuarios del sistema |
| `/beacons` | `Beacons` | Lista de todas las balizas |
| `/beacons/:beaconId` | `BeaconDetail` | Detalle y control de una baliza |
| `/incidents` | `Incidents` | Incidentes reportados |
| `/circuit-state` | `CircuitState` | Control del estado global del circuito |
| `/logs` | `Logs` | Logs de actividad de balizas |
| `/zones` | `ZonesMap` | Mapa de zonas del circuito |
| `/routes` | `Routes` | Rutas del circuito |
| `/statistics` | `Statistics` | Estadísticas del evento |
| `/emergencies` | `Emergencies` | Panel de emergencias |
| `/config` | `Config` | Configuración del sistema |
| `/orders` | `OrdersPage` | Gestión de pedidos |
| `/products` | `ProductsPage` | Catálogo de productos |
| `/food-stands` | `FoodStandsPage` | Puestos de comida |
| `/news` | `NewsPage` | Noticias para fans |

---

### Contextos (Context)

#### `context/AuthContext.tsx`
Gestiona el estado de autenticación de Firebase para toda la aplicación.

**Estado expuesto:**
- `user: User | null` — Usuario de Firebase actualmente autenticado.
- `loading: boolean` — Si la comprobación de autenticación está en curso.
- `signIn(email, password)` — Función de login.
- `signOut()` — Función de logout.

**Implementación:**
```tsx
// Escucha cambios de autenticación en Firebase
useEffect(() => {
  const unsubscribe = onAuthStateChanged(auth, (user) => {
    setUser(user);
    setLoading(false);
  });
  return unsubscribe; // cleanup
}, []);
```

**¿Por qué Firebase Auth?**  
El panel web necesita un sistema de autenticación seguro sin necesidad de implementar un servidor de auth propio. Firebase Auth provee tokens JWT seguros, soporte para múltiples proveedores (email, Google) y gestión de sesiones automática.

#### `context/ToastContext.tsx`
Sistema de notificaciones toast (mensajes temporales de feedback al usuario).

**API:**
- `showToast(message, type)` — Muestra un toast. Tipos: `'success'`, `'error'`, `'warning'`, `'info'`.
- Los toasts desaparecen automáticamente tras unos segundos.

---

### Servicios (Services)

#### `services/apiClient.ts`
**Cliente HTTP genérico** para comunicarse con la API REST del backend.

**Función `request<T>(url, options)`:**
- Convierte automáticamente HTTP a HTTPS.
- Soporte para `timeout` (5 segundos por defecto).
- **Reintentos automáticos** con backoff exponencial (hasta 3 reintentos).
- Usa `AbortController` para cancelar peticiones que superan el timeout.
- Loguea errores con la URL y el status code.

**Objeto `api` exportado:**

```typescript
api.get<T>(table, where?)        // POST /_get
api.upsert(table, data)          // POST /_upsert
api.delete(table, where)         // POST /_delete
api.getBeacons()                 // GET balizas + cálculo de online status
api.getZones()                   // GET zonas
api.getCommands()                // GET comandos
api.getPendingCommands(uid)      // GET comandos pendientes para una baliza
api.getCircuitState()            // GET estado del circuito (id=1)
api.setCircuitState(mode, msg)   // UPSERT estado del circuito
api.getIncidents()               // GET incidentes
api.getBeaconLogs()              // GET logs de balizas
```

**Lógica de `online` en `getBeacons()`:**  
Una baliza se considera **online** si su último heartbeat fue hace menos de **2 minutos** (120.000 ms). Esto refleja que las balizas envían heartbeat cada 10 segundos, por lo que 2 minutos es un margen generoso para problemas de red.

#### `services/beaconService.ts`
Servicio de alto nivel para operaciones de balizas. Usa `apiClient.ts` como base.

**`beaconsService`:**

- **`subscribeToBeacons(callback, intervalMs)`**  
  Polling de balizas cada `intervalMs` ms (por defecto 4 segundos). Solo llama al callback si los datos han cambiado (compara hash JSON). Retorna una función para cancelar el polling (cleanup).

- **`configureBeacon(beaconId, config)`**  
  Configura una baliza enviando un comando `UPDATE_CONFIG` y actualizando la BD. Marca automáticamente `configured = true`.

- **`updateBeacon(beaconId, updates)`**  
  Actualiza parcialmente una baliza. Si los cambios son significativos (modo, flecha, mensaje, zona), envía también el comando `UPDATE_CONFIG` para notificación en tiempo real.

- **`updateMultipleBeacons(beaconIds, updates)`**  
  Actualiza múltiples balizas en paralelo con `Promise.all`.

- **`activateEmergencyAll(message, arrow)`**  
  Activa modo EMERGENCIA en todas las balizas simultáneamente.

- **`restartBeacon(beaconId)`** / **`restartAllBeacons()`**  
  Envía comando `RESTART` a una o todas las balizas. Esto hace que el PC de la baliza se reinicie.

- **`shutdownBeacon(beaconId)`**  
  Envía comando `SHUTDOWN` para apagar el PC de la baliza.

- **`closeAppBeacon(beaconId)`**  
  Envía comando `CLOSE_APP` para cerrar la aplicación de la baliza (el PC sigue encendido).

**`emergencyService`:**

- **`activateGlobalEvacuation(beacons, userId, message, evacuationExit)`**  
  Pone todas las balizas en modo `EVACUATION` con fondo rojo y registra la acción en `emergency_logs`.

- **`deactivateGlobalEvacuation(beacons, userId)`**  
  Restaura todas las balizas a modo `NORMAL` y registra la desactivación.

- **`activateZoneEvacuation(zone, ...)`** / **`deactivateZoneEvacuation(zone, ...)`**  
  Igual que los anteriores pero solo para las balizas de una zona específica.

- **`logEmergencyAction(log)`**  
  Registra una acción de emergencia en la tabla `emergency_logs` para auditoría.

#### `services/beaconDetectionService.ts`
Detecta cuando aparecen **nuevas balizas** en la red (balizas que se registran por primera vez via heartbeat). Notifica al operador para que las configure.

---

### Hooks Personalizados

#### `hooks/useBeacons.ts`
Hook React que gestiona el ciclo de vida de la suscripción a balizas:
```typescript
const { beacons, loading, error, refetch } = useBeacons();
```
- Suscribe al polling de balizas al montar el componente.
- Cancela la suscripción al desmontar (cleanup en `useEffect`).
- Expone `loading` para mostrar un spinner inicial.
- Expone `error` para mostrar mensajes de error.
- Expone `refetch` para forzar una actualización inmediata.

#### `hooks/useCircuitState.ts`
Hook para el estado global del circuito:
```typescript
const { circuitState, setMode, loading } = useCircuitState();
```
- Hace polling del estado del circuito cada pocos segundos.
- Expone `setMode(mode, message)` para cambiar el estado global.

#### `hooks/useZones.ts`
Hook para la lista de zonas del circuito:
```typescript
const { zones, loading } = useZones();
```

#### `hooks/useNewBeaconDetection.ts`
Hook que detecta nuevas balizas no configuradas:
```typescript
const { newBeacons, dismissNewBeacon } = useNewBeaconDetection(beacons);
```
- Compara la lista actual de balizas con la última vista.
- Devuelve las balizas nuevas (`configured === false`).

---

### Páginas (Pages)

#### `pages/Dashboard.tsx`
Pantalla principal del panel. Muestra:
- **KPIs**: Número total de balizas, balizas online/offline, modo del circuito, incidentes activos.
- **Balizas por estado**: Cuántas en modo NORMAL, EMERGENCIA, EVACUACIÓN, MANTENIMIENTO.
- **Actividad reciente**: Últimos cambios de estado de balizas.
- **Accesos rápidos** a las secciones más usadas.

#### `pages/Beacons.tsx`
Lista completa de todas las balizas con:
- Filtros por zona, modo, estado online.
- Búsqueda por nombre o ID.
- Indicador visual de estado (verde=online, gris=offline).
- Acciones rápidas (cambiar modo, enviar comando, abrir detalle).
- Botón para activar evacuación global.
- Detección de nuevas balizas no configuradas.

#### `pages/BeaconDetail.tsx`
Vista detallada de una baliza individual:
- **Información**: ID, nombre, zona, posición GPS, estado.
- **Previsualización** en tiempo real de cómo se ve la baliza física.
- **Formulario de configuración**: Cambiar modo, mensaje, flecha, color, brillo, idioma.
- **Panel de comandos**: Enviar comandos directos (RESTART, SHUTDOWN, PING, etc.).
- **Métricas**: Uptime, último heartbeat, nivel de batería.
- **Logs** de actividad de la baliza.

#### `pages/CircuitState.tsx`
Control del estado global del circuito:
- Botones para cambiar el modo: NORMAL, SAFETY_CAR, RED_FLAG, EVACUATION.
- Campo de mensaje personalizado.
- Temperatura del circuito.
- Historial de cambios de estado.

**Impacto de cambiar el estado global:**  
Cuando se cambia el modo global a EVACUATION, todas las balizas (que hacen polling cada 300ms) detectan este cambio y muestran automáticamente la señal de evacuación. Las apps móviles también lo detectan.

#### `pages/Emergencies.tsx`
Panel de gestión de emergencias:
- **Botón de evacuación global** con confirmación (modal).
- **Evacuación por zona** (activa solo las balizas de una zona específica).
- **Historial** de emergencias pasadas.
- **Estado actual**: Si hay una evacuación activa, muestra cuántas balizas están en modo EVACUATION.

#### `pages/Incidents.tsx`
Lista de incidentes reportados por los usuarios:
- Tipo de incidente (aglomeración, objeto perdido, médico, etc.).
- Zona donde ocurrió.
- Estado (abierto/resuelto).
- Usuario que reportó.
- Acciones: asignar, resolver, escalar.

#### `pages/Logs.tsx`
Logs de actividad de las balizas:
- Heartbeats recibidos.
- Cambios de estado.
- Comandos enviados/ejecutados.
- Errores.
- Filtros por baliza, tipo de evento, rango de fechas.

#### `pages/Statistics.tsx`
Estadísticas del evento:
- Número de visitantes activos.
- Flujo de entrada/salida por zonas.
- Picos de ocupación.
- Temperatura promedio del circuito.
- Resumen de incidentes.

#### `pages/ZonesMap.tsx`
Visualización del mapa de zonas del circuito:
- Cada zona coloreada según su estado (verde=normal, naranja=saturada, rojo=cerrada).
- Número de balizas activas por zona.
- Densidad de ocupación estimada.

#### `pages/Login.tsx`
Página de autenticación:
- Formulario de email y contraseña.
- Autenticación vía Firebase Auth.
- Manejo de errores (credenciales incorrectas, usuario no encontrado).
- Redirección automática al dashboard si ya hay sesión activa.

---

### Componentes (Components)

#### `components/Layout.tsx`
Layout principal de todas las páginas autenticadas. Incluye:
- **Sidebar** izquierdo con el menú de navegación (links a todas las rutas).
- **Topbar** superior con el nombre del usuario y botón de logout.
- **Área de contenido** donde se renderiza el `children`.
- Soporte para colapsar el sidebar en pantallas pequeñas.

#### `components/ProtectedRoute.tsx`
Higher-Order Component (HOC) que protege las rutas autenticadas:
```tsx
function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return <Spinner />;
  if (!user) return <Navigate to="/login" replace />;
  return children;
}
```
Si el usuario no está autenticado, redirige automáticamente a `/login`.

#### `components/BeaconConfigForm.tsx`
Formulario completo para configurar una baliza:
- **Modo**: Selector de NORMAL/CONGESTION/EMERGENCY/EVACUATION/MAINTENANCE.
- **Flecha**: Selector visual de la dirección (NONE, LEFT, RIGHT, UP, DOWN, etc.).
- **Mensaje**: Campo de texto libre (máximo 50 caracteres para balizas sin pantalla extendida).
- **Color**: Color picker hex.
- **Brillo**: Slider 0-100%.
- **Idioma**: Selector ES/EN/FR/DE/IT/PT/CA.
- **Salida de evacuación**: Campo de texto con el nombre de la salida asignada.

#### `components/BeaconPreview.tsx`
Renderiza una **previsualización en tiempo real** de cómo se verá la baliza física en su pantalla. Usa el `beacon_renderer` para generar la imagen. Permite al operador ver el resultado antes de enviar la configuración.

#### `components/CommandPanel.tsx`
Panel de envío de comandos directos a una baliza:
- Lista de comandos disponibles: RESTART, SHUTDOWN, CLOSE_APP, PING, UPDATE_CONFIG.
- Campo para comandos personalizados.
- Historial de comandos enviados y su estado (PENDING/EXECUTED/FAILED).

#### `components/EvacuationModal.tsx`
Modal de confirmación para activar una evacuación:
- Selección del tipo: Global o por zona.
- Campo de mensaje de evacuación.
- Campo de salida/ruta de evacuación asignada.
- Botón de confirmación con texto de advertencia.
- Requiere doble confirmación para evacuaciones globales.

#### `components/BeaconEditModal.tsx`
Modal para edición rápida de una baliza desde la lista. Contiene un `BeaconConfigForm` simplificado.

#### `components/BeaconMetricsCard.tsx`
Tarjeta con métricas de una baliza: batería, uptime, tiempo desde último heartbeat, número de comandos ejecutados en las últimas 24h.

#### `components/Toast.tsx`
Componente de notificaciones temporales (toasts). Se posiciona en la esquina superior derecha. Soporta animaciones de entrada/salida. Colores por tipo: verde (success), rojo (error), amarillo (warning), azul (info).

---

### Tipos TypeScript (Types)

#### `types/index.ts`
Define todos los tipos TypeScript del proyecto. Son la **fuente de verdad** para el modelo de datos.

**Tipos de enumeración:**
```typescript
type BeaconMode = "UNCONFIGURED" | "NORMAL" | "CONGESTION" | "EMERGENCY" | "EVACUATION" | "MAINTENANCE"
type ArrowDirection = "NONE" | "LEFT" | "RIGHT" | "UP" | "DOWN" | "UP_LEFT" | "UP_RIGHT" | ...
type Language = "ES" | "EN" | "FR" | "DE" | "IT" | "PT" | "CA"
type CommandStatus = "PENDING" | "SENT" | "EXECUTED" | "FAILED" | "CANCELLED"
```

**Interfaces principales:**
- `Beacon` — Modelo completo de una baliza (todos los campos de la BD).
- `ZoneDB` — Zona del circuito.
- `Command` — Comando en la cola.
- `BeaconLog` — Entrada de log de una baliza.
- `Emergency` — Emergencia activa.
- `BeaconUpdate` — Objeto de actualización parcial de baliza.
- `Zone` — Zona del circuito con estado y métricas de ocupación.
- `Route` — Ruta del circuito con métricas de flujo.
- `SystemStats` — Estadísticas globales del sistema.

---

### Beacon Renderer

#### `beacon_renderer/RenderEngine.ts`
Motor de renderizado que genera una representación visual de cómo se verá la pantalla de la baliza. Produce SVG o HTML canvas que refleja:
- Color de fondo según el modo.
- Texto del mensaje.
- Icono de la flecha en la dirección configurada.
- Indicadores de modo (iconos de emergencia, safety car, etc.).

#### `beacon_renderer/LayoutEngine.ts`
Motor de layout que calcula la posición y tamaño de cada elemento en la pantalla de la baliza según las dimensiones configuradas.

#### `beacon_renderer/components/ArrowComponent.ts`
Genera el SVG de la flecha direccional según el valor de `ArrowDirection`. Soporta todas las 15 direcciones posibles.

---

### Firebase

#### `firebase/config.ts`
Configuración de Firebase para el panel web. Contiene las API keys públicas del proyecto Firebase.

```typescript
export const firebaseConfig = {
  apiKey: "...",
  authDomain: "panel-de-control-georacing.firebaseapp.com",
  projectId: "panel-de-control-georacing",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
};
```

**Nota:** Las API keys de Firebase son públicas por diseño. La seguridad se gestiona mediante las **Firestore Security Rules** (`firestore.rules`), no ocultando las keys.

#### `firebase/firebaseApp.ts`
Inicializa la app Firebase y exporta las instancias de `auth` y `firestore` para uso en toda la aplicación.

---

## Funcionalidades Principales

### Dashboard en Tiempo Real

El dashboard se actualiza automáticamente gracias al polling periódico de los hooks (`useBeacons`, `useCircuitState`). El intervalo de actualización es de 4 segundos para balizas y pocos segundos para el estado del circuito.

### Previsualización de Balizas

El `BeaconPreview` permite al operador ver exactamente cómo se verá la pantalla de la baliza antes de enviar la configuración. Esto reduce los errores de configuración y mejora la experiencia del operador.

### Gestión de Usuarios

La página `UsersPage` permite al administrador del sistema gestionar los usuarios del panel web:
- Crear nuevos usuarios de staff.
- Asignar roles (admin, operador, viewer).
- Desactivar cuentas.

---

## Sistema de Comandos

Las balizas físicas reciben comandos a través de la tabla `commands` de la BD:

### Ciclo de vida de un comando

```
Operador hace clic en "RESTART" en el panel
    │
    ▼
beaconsService.restartBeacon(beaconId)
    │
    ▼
api.upsert("commands", {
    beacon_uid: beaconId,
    command: "RESTART",
    status: "PENDING",
    created_at: ahora
})
    │
    ▼
Baliza hace polling cada 300ms
    │
    ▼
Baliza ejecuta el comando
    │
    ▼
Baliza elimina el comando de la BD (DELETE)
    │
    ▼
Panel no ve ya el comando en la lista
```

### Comandos disponibles

| Comando | Descripción | Efecto en la baliza |
|---|---|---|
| `UPDATE_CONFIG` | Actualiza la configuración visual | Cambia modo, mensaje, flecha, color, brillo |
| `RESTART` | Reinicia el PC de la baliza | `shutdown.exe /r /t 3` |
| `SHUTDOWN` | Apaga el PC de la baliza | `shutdown.exe /s /t 3` |
| `CLOSE_APP` | Cierra la aplicación | `Application.Current.Shutdown()` |
| `PING` | Comprobación de disponibilidad | La baliza responde con heartbeat |

---

## Sistema de Emergencias

El sistema de emergencias tiene dos niveles:

### 1. Emergencia Global (Todo el circuito)

1. Operador abre `EvacuationModal`.
2. Introduce mensaje y ruta de evacuación.
3. Confirma la acción.
4. `emergencyService.activateGlobalEvacuation()` ejecuta:
   - Actualiza **todas las balizas** en la BD a modo EVACUATION.
   - Registra en `emergency_logs`.
5. Las balizas detectan el cambio en el siguiente poll.
6. Las apps móviles reciben la notificación vía Firestore.

### 2. Evacuación por Zona

Igual que la global pero solo afecta a las balizas de la zona seleccionada. Útil para incidentes localizados sin necesitar evacuar todo el recinto.

---

## Autenticación y Rutas Protegidas

Todas las rutas excepto `/login` están protegidas por `ProtectedRoute`. El flujo es:

1. Usuario accede a cualquier ruta del panel.
2. `AuthContext` comprueba el estado de Firebase Auth.
3. Si no hay usuario autenticado → redirección a `/login`.
4. Usuario introduce credenciales → `signIn()` → Firebase valida.
5. Firebase devuelve token JWT → `onAuthStateChanged` actualiza el estado.
6. `ProtectedRoute` detecta usuario autenticado → renderiza el contenido.

La sesión persiste en localStorage gracias a Firebase (no se pierde al recargar la página).

---

## Despliegue

### Desarrollo
```bash
npm run dev          # Inicia servidor de desarrollo Vite (http://localhost:5173)
```

### Producción
```bash
npm run build        # Compila TypeScript y genera bundle en /dist
npm run preview      # Preview del bundle de producción
npm run deploy       # Build + deploy a Firebase Hosting
```

### Firebase Hosting
El panel se despliega en Firebase Hosting (`firebase.json`). Es una CDN global que sirve los archivos estáticos del bundle de React. Las peticiones a la API REST van directamente al servidor QNAP.

### Scripts de administración
```bash
npm run create-admin    # Crea un usuario administrador en Firebase
npm run create-beacons  # Crea balizas de prueba en la BD
```
