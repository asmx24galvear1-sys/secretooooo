# Baliza_Noah — Documentación Técnica Completa

## Índice

1. [Descripción General](#descripción-general)
2. [Tecnologías y Dependencias](#tecnologías-y-dependencias)
3. [Arquitectura](#arquitectura)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Módulos y Ficheros Clave](#módulos-y-ficheros-clave)
   - [Config (Configuración)](#config-configuración)
   - [Models (Modelos)](#models-modelos)
   - [Services (Servicios)](#services-servicios)
   - [ViewModels](#viewmodels)
   - [MainWindow (Ventana Principal)](#mainwindow-ventana-principal)
6. [Ciclo de Vida de la Aplicación](#ciclo-de-vida-de-la-aplicación)
7. [Protocolo BLE](#protocolo-ble)
8. [Sistema de Comandos](#sistema-de-comandos)
9. [Modos de la Baliza](#modos-de-la-baliza)
10. [Sistema de Logging](#sistema-de-logging)
11. [Configuración del Sistema](#configuración-del-sistema)

---

## Descripción General

**Baliza Noah** es la aplicación de señalización física para Windows. Se ejecuta a pantalla completa en PCs/tablets con Windows ubicados estratégicamente en el circuito (entradas, salidas, encrucijadas, sectores).

Su función es:
1. **Mostrar información visual** al público del circuito: estado de la carrera, dirección de flujo, mensajes de evacuación.
2. **Emitir señales BLE** para que las apps móviles detecten la zona del usuario.
3. **Recibir comandos** del Panel Web para cambiar su configuración en tiempo real.
4. **Reportar su estado** al servidor mediante heartbeats periódicos.

Esta es la versión **completa y productiva** de la baliza, con interfaz gráfica WPF, sistema de configuración persistente, logging completo, y sistema de resolución de conflictos de estado.

---

## Tecnologías y Dependencias

### Lenguaje y Framework

| Tecnología | Versión | Justificación |
|---|---|---|
| **C#** | 10+ | Lenguaje oficial de .NET. Tipado, moderno, con soporte completo para async/await. |
| **.NET Framework / .NET 7+** | 7+ | Runtime de ejecución. Multiplataforma, aunque aquí se usa específicamente en Windows. |
| **WPF (Windows Presentation Foundation)** | - | Framework de UI de Windows con soporte para XAML, data binding bidireccional y animaciones. Permite crear pantallas a pantalla completa con efectos visuales avanzados. |

### ¿Por qué WPF y no WinForms o UWP?

- **WPF** ofrece el sistema de data binding más potente de .NET para Windows, ideal para el patrón MVVM.
- **WPF** soporta transformaciones visuales, efectos de opacidad, animaciones y fondos de color que son necesarios para la señalización visual de la baliza.
- **WinForms** no tiene data binding automático y es más limitado visualmente.
- **UWP/WinUI** requiere distribución vía Microsoft Store y tiene restricciones de permisos más complejas.

### Bluetooth

| API | Justificación |
|---|---|
| **Windows.Devices.Bluetooth (WinRT)** | API nativa de Windows para BLE. `BluetoothLEAdvertisementPublisher` para emitir señales BLE sin hardware adicional. Disponible desde Windows 10. |

### HTTP y Serialización

| Librería | Justificación |
|---|---|
| **System.Net.Http.HttpClient** | Cliente HTTP nativo de .NET. No requiere dependencias externas. Soporte para async/await. |
| **System.Text.Json** | Serializador JSON nativo de .NET (desde .NET 5). Más rápido que Newtonsoft.Json, sin dependencias externas. |

### Otras dependencias

| Librería | Justificación |
|---|---|
| **System.Windows.Forms.SystemInformation** | Para obtener el nivel de batería del sistema. Usado en el heartbeat para reportar batería. |

### Proyecto

El proyecto usa la solución Visual Studio `METROPOLIS BALIZA 2.sln` con el proyecto `BeaconApp.csproj`.

---

## Arquitectura

La aplicación sigue el patrón **MVVM (Model-View-ViewModel)**:

```
┌─────────────────────────────────────────┐
│         View (XAML + Code-behind)        │
│   MainWindow.xaml / MainWindow.xaml.cs  │
│   Data binding bidireccional            │
└──────────────────┬──────────────────────┘
                   │ INotifyPropertyChanged
┌──────────────────▼──────────────────────┐
│            ViewModel                     │
│         MainViewModel.cs                │
│   Lógica de negocio + estado UI         │
│   Polling + Heartbeat + Commands        │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│            Services                      │
│   ApiClient + BleBeaconService          │
│   BeaconConfigService + FileLogger      │
└──────────────────┬──────────────────────┘
                   │ HTTP / BLE / Disco
┌──────────────────▼──────────────────────┐
│            External Systems              │
│   API REST (QNAP) + BD MySQL            │
│   Windows BLE Stack                     │
└─────────────────────────────────────────┘
```

**Ventajas del MVVM en WPF:**
- La `View` (XAML) declara bindings a propiedades del ViewModel.
- Cuando el ViewModel cambia una propiedad, `INotifyPropertyChanged` notifica automáticamente al XAML y la UI se actualiza.
- No se necesita código para actualizar la UI manualmente.

---

## Estructura de Carpetas

```
Baliza_Noah/
│
├── METROPOLIS BALIZA 2.sln      # Solución Visual Studio
│
└── BeaconApp/                   # Proyecto principal
    │
    ├── App.xaml                 # Definición de la aplicación WPF (recursos globales, estilos)
    ├── App.xaml.cs              # Code-behind del App (startup, excepciones globales)
    ├── BeaconApp.csproj         # Proyecto C# (referencias, targets, dependencias)
    │
    ├── MainWindow.xaml          # UI principal (pantalla completa de la baliza)
    ├── MainWindow.xaml.cs       # Code-behind de la ventana principal
    │
    ├── Config/
    │   └── BeaconConfigService.cs   # Lectura/creación de config (beacon_config.json)
    │
    ├── Models/
    │   └── BeaconModels.cs          # DTOs y modelos de datos
    │
    ├── Services/
    │   ├── ApiClient.cs             # Cliente HTTP para la API REST
    │   ├── ApiLogger.cs             # Logger que envía logs a la API
    │   ├── BleBeaconService.cs      # Servicio BLE Advertising
    │   └── FileLogger.cs            # Logger local en fichero
    │
    └── ViewModels/
        └── MainViewModel.cs         # ViewModel principal (toda la lógica de negocio)
    │
    └── Documentación:
        ├── CAMBIOS-MODO-LECTURA.md
        ├── DIAGRAMA-FUNCIONAMIENTO.md
        ├── DOCUMENTACION-CODIGO.md
        ├── IMPLEMENTACION-COMPLETA.md
        ├── INSTRUCCIONES.md
        ├── README.md
        ├── README-DEV.md
        ├── REFERENCIA-API.md
        └── RESUMEN-IMPLEMENTACION.md
```

---

## Módulos y Ficheros Clave

### Config (Configuración)

#### `Config/BeaconConfigService.cs`
Gestiona la configuración persistente de la baliza en el fichero `beacon_config.json`.

**Funcionamiento:**
1. Al iniciar la app, llama a `ReadOrCreateConfig()`.
2. Si existe `beacon_config.json` en el directorio de la app, lo lee.
3. Si no existe, crea uno nuevo con valores por defecto y lo guarda.
4. Retorna el objeto `BeaconConfig` para usar en toda la app.

**Campos de `beacon_config.json`:**
```json
{
  "beaconId": "BEACON-UUID-AQUI",
  "name": "Baliza Sector 1",
  "description": "Entrada principal Sector 1",
  "zoneId": 1,
  "latitude": 41.123456,
  "longitude": 2.654321,
  "apiBaseUrl": "https://alpo.myqnapcloud.com:4010/api/"
}
```

**¿Por qué fichero JSON y no la base de datos?**  
La baliza necesita saber su propio ID incluso antes de conectarse al servidor. El fichero local garantiza que siempre tenga su identidad aunque no haya internet.

---

### Models (Modelos)

#### `Models/BeaconModels.cs`
Define todos los modelos de datos usados para comunicarse con la API.

**`BeaconHeartbeatRequest`**  
Payload del heartbeat que la baliza envía cada 10 segundos. Incluye:
- `beacon_uid` — ID único de la baliza.
- `name`, `description` — Metadatos descriptivos.
- `zone_id`, `latitude`, `longitude` — Posición.
- `has_screen` — Si la baliza tiene pantalla (siempre 1 en Noah).
- `mode` — Modo actual (NORMAL, EVACUATION, etc.).
- `arrow_direction` — Dirección actual de la flecha.
- `message` — Texto mostrado actualmente.
- `color` — Color de fondo actual (#RRGGBB).
- `brightness` — Brillo actual (0-100).
- `battery_level` — Nivel de batería del PC.

**`BeaconCommandDto`**  
Modelo para deserializar los comandos recibidos desde la API:
- `id` — ID del comando en la BD.
- `beacon_uid` — UID de la baliza destinataria.
- `command` — Tipo de comando (UPDATE_CONFIG, RESTART, etc.).
- `value` — Payload JSON del comando.
- `status` — Estado (PENDING, EXECUTED).
- `created_at` / `executed_at` — Timestamps con deserializador custom.

**`BeaconConfigUpdate`**  
Modelo para deserializar el JSON del campo `value` cuando el comando es `UPDATE_CONFIG`:
- `mode`, `arrow`, `message`, `color`, `brightness`, `zone`, `evacuation_exit`.

**`CircuitState`**  
Modelo del estado global del circuito:
- `global_mode` — NORMAL/EVACUATION/SAFETY_CAR/RED_FLAG.
- `temperature` — Temperatura del circuito (soporta string "11.3°C" o número).
- `message`, `evacuation_route`.

**`CustomDateTimeConverter`**  
Converter JSON custom para fechas. El servidor puede enviar fechas como `"2024-01-15 14:30:00"` (formato BD con espacio) o como ISO 8601. El converter soporta ambos formatos usando `CultureInfo.InvariantCulture` para evitar problemas con configuraciones regionales (ej: ES usa coma como separador decimal).

---

### Services (Servicios)

#### `Services/ApiClient.cs`
Cliente HTTP para comunicarse con la API REST de GeoRacing.

**Constructor:**
```csharp
public ApiClient(string baseUrl)
{
    // Acepta certificados SSL autofirmados (servidor QNAP)
    var handler = new HttpClientHandler
    {
        ServerCertificateCustomValidationCallback = (msg, cert, chain, errors) => true
    };
    _httpClient = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(10) };
}
```

**¿Por qué ignorar certificados SSL?**  
El servidor QNAP usa un certificado SSL autofirmado o con dominio dinámico DDNS. En producción se debería instalar un certificado válido, pero en desarrollo/despliegue local se ignora la validación para simplificar.

**Métodos principales:**

- **`CheckHealthAsync()`** — GET `/health`. Comprueba si el servidor está disponible.

- **`SendHeartbeatAsync(request)`** — POST `/beacons/heartbeat`. Registra la presencia de la baliza y su estado actual. También hace un `_upsert` directo para asegurar que `battery_level` se guarda aunque el endpoint heartbeat lo ignore.

- **`GetPendingCommandsAsync(beaconUid)`** — GET `/commands/pending/{uid}`. Obtiene la lista de comandos pendientes. Retorna lista vacía si hay errores (no crashea el bucle).

- **`GetBeaconConfigAsync(beaconUid)`** — POST `/_get` (tabla `beacons`, filtrado por `beacon_uid`). Lee la configuración actual de la baliza en la BD para sincronizar el estado.

- **`GetCircuitStateAsync()`** — POST `/_get` (tabla `circuit_state`, id=1). Lee el estado global del circuito. Soporta temperatura como string ("11.3°C") o como número.

- **`UpsertAsync(table, data)`** — POST `/_upsert`. Operación genérica de inserción/actualización.

- **`DeleteAsync(table, where)`** — POST `/_delete`. Elimina un registro (usado para marcar comandos como ejecutados).

- **`ExecuteCommandAsync(commandId)`** — POST `/commands/{id}/execute`. Alternativa REST para marcar comandos ejecutados.

- **`CreateCommandAsync(beaconUid, command, value?)`** — POST `/commands`. Crea un nuevo comando desde la baliza hacia el servidor. Útil para el panel local de la baliza.

#### `Services/BleBeaconService.cs`
Servicio de **Bluetooth Low Energy Advertising** para Windows.

**Protocolo BLE:**  
La baliza emite continuamente un paquete BLE con Manufacturer ID `0x1234` y un payload de **9 bytes**:

| Byte | Campo | Valor/Descripción |
|---|---|---|
| 0 | Version | Siempre `0x01` |
| 1-2 | Zone ID | ID de zona en Big Endian |
| 3 | Mode | `0x00`=NORMAL, `0x01`=CONGESTION, `0x02`=EMERGENCY/RED_FLAG, `0x03`=EVACUATION |
| 4 | Flags | Siempre `0x00` (reservado) |
| 5-6 | Sequence | Contador incremental Big Endian |
| 7 | TTL | Siempre `0x0A` (10 segundos) |
| 8 | Temperature | Temperatura en °C como byte sin signo |

**`Start()`** — Inicializa el `BluetoothLEAdvertisementPublisher` con los datos iniciales y empieza el advertising.

**`Stop()`** — Detiene el advertising.

**`UpdateStatus(mode, temperature)`** — Actualiza el payload BLE cuando el estado cambia:
1. Solo actúa si el modo o la temperatura han cambiado (evita Stop/Start innecesarios).
2. Incrementa el contador de secuencia.
3. Recrea el publisher (la API WinRT no permite modificar el advertising activo).

**`MapModeToByte(mode)`** — Convierte el string del modo al byte del protocolo:
- "NORMAL" → `0x00`
- "CONGESTION" / "SAFETY_CAR" → `0x01`
- "EMERGENCY" / "RED_FLAG" → `0x02`
- "EVACUATION" → `0x03`

**¿Por qué recrear el publisher en cada actualización?**  
La API WinRT de BLE en Windows **no permite modificar el contenido del advertisement mientras está activo**. Es necesario llamar a `Stop()` → configurar → `Start()` cada vez que cambia el payload.

#### `Services/FileLogger.cs`
Logger local que escribe los mensajes en un fichero de texto (`beacon_log.txt`) en el directorio de la aplicación.

- `Log(message)` — Añade una línea con timestamp al fichero.
- `LogError(message, exception)` — Añade el mensaje de error y el stack trace.
- Creación automática del fichero si no existe.
- Rotación de fichero si supera 10 MB.

#### `Services/ApiLogger.cs`
Logger que además de usar `FileLogger` para el log local, envía los mensajes a la API REST para centralizar el logging. Los operadores del panel web pueden ver los logs de todas las balizas en tiempo real.

**`InitializeAsync()`** — Asegura que la tabla `beacon_logs` existe en la BD.

**`Log(level, message)`** — Envía un log a la API via `_upsert` en la tabla `beacon_logs`. Falla silenciosamente si la API no está disponible (el FileLogger siempre funciona como fallback).

---

### ViewModels

#### `ViewModels/MainViewModel.cs`
El corazón de la aplicación. Implementa `INotifyPropertyChanged` para el data binding con WPF.

**Constructor:**
```csharp
public MainViewModel(BeaconConfig config, ApiClient apiClient)
{
    _config = config;
    _apiClient = apiClient;
    _bleService = new BleBeaconService(config.ZoneId);
    _apiLogger = new ApiLogger(apiClient, config.BeaconId);
}
```

**`Start()` — Inicio de servicios:**
1. Comprueba la conectividad con `CheckHealthAsync()`.
2. Sincroniza el estado inicial con `SyncConfigAsync()`.
3. Inicializa el `ApiLogger`.
4. Inicia dos timers:
   - **Timer de polling** (cada **300ms**): `CheckGlobalStateAsync()` + `SyncConfigAsync()` + `PollCommandsAsync()`.
   - **Timer de heartbeat** (cada **10 segundos**): `SendHeartbeatAsync()`.
5. Inicia el BLE Advertising con `_bleService.Start()`.

**`Stop()`** — Para los timers, el BLE y cancela el CancellationToken.

**Propiedades observables (INotifyPropertyChanged):**

| Propiedad | Tipo | Descripción |
|---|---|---|
| `CurrentMode` | string | Modo actual (NORMAL/EVACUATION/etc.). Al cambiar, actualiza el display y el BLE. |
| `CurrentArrow` | string | Dirección de la flecha (NONE/LEFT/RIGHT/UP/etc.). |
| `DisplayText` | string | Texto mostrado en la pantalla de la baliza. |
| `BackgroundColor` | string | Color de fondo en hex (#RRGGBB). |
| `CurrentBrightness` | int | Brillo 0-100. Al cambiar, llama a PowerShell para ajustar el brillo del monitor. |
| `CurrentZone` | string | Nombre de la zona actual. |
| `CurrentEvacuationExit` | string | Nombre de la salida de evacuación asignada. |
| `CurrentLanguage` | string | Idioma actual (ES/EN/FR/etc.). |
| `IsConfigured` | bool | Si la baliza ha sido configurada desde el panel. |
| `StatusMessage` | string | Mensaje de estado de la conexión (visible en la UI). |

**`SyncConfigAsync()`**  
Lee la configuración de la baliza desde la API y actualiza el ViewModel. Incluye **lógica de resolución de conflictos**:
1. Si el modo global es EVACUATION y la BD individual dice NORMAL → **ignora** el downgrade (el global tiene prioridad).
2. Si se acaba de salir de una evacuación global, hay un periodo de gracia de 5 segundos durante el cual se ignoran las actualizaciones de EVACUATION desde la BD individual (para evitar "parpadeo" por lag de la BD).

**`CheckGlobalStateAsync()`**  
Lee el estado global del circuito y actualiza el BLE + pantalla:
1. Obtiene `CircuitState` completo (modo + temperatura).
2. Actualiza el BLE con `_bleService.UpdateStatus(globalMode, temperature)`.
3. Si el modo global es EVACUATION y la baliza no lo estaba → activa EVACUATION localmente.
4. Si el modo global deja de ser EVACUATION y antes lo era → restaura el modo normal y activa el periodo de gracia.

**`SendHeartbeatAsync()`**  
Construye y envía el heartbeat:
- Incluye el nivel de batería del PC via `SystemInformation.PowerStatus.BatteryLifePercent`.
- Si el PC no tiene batería (desktop), reporta 100%.

**`PollCommandsAsync()`**  
Obtiene y ejecuta los comandos pendientes:
1. Filtra comandos expirados (>60 minutos) y los elimina.
2. Para cada comando válido, llama a `ProcessCommandAsync()`.
3. Si el comando se ejecuta con éxito, lo elimina de la BD.

**`ProcessCommandAsync(cmd)`**  
Dispatcher de comandos:
- `UPDATE_CONFIG` → `ProcessUpdateConfig()` (actualiza propiedades del ViewModel).
- `RESTART` → `shutdown.exe /r /f /t 3` (reinicia Windows en 3s).
- `SHUTDOWN` → `shutdown.exe /s /f /t 3` (apaga Windows en 3s).
- `CLOSE` / `CLOSE_APP` → `Application.Current.Shutdown()` (cierra la app).

**`UpdateDisplayForMode()`**  
Cuando el modo cambia, actualiza el texto y color de fondo a los valores por defecto del modo:

| Modo | Color de fondo | Texto por defecto |
|---|---|---|
| UNCONFIGURED | `#1565C0` (azul) | "SIN CONFIGURAR" |
| NORMAL | `#2E7D32` (verde) | "MODO NORMAL" |
| CONGESTION | `#F57C00` (naranja) | "⚠️ CONGESTIÓN" |
| EMERGENCY | `#C62828` (rojo) | "🚨 EMERGENCIA" |
| EVACUATION | `#D32F2F` (rojo) | "🚨 EVACUACIÓN" |
| MAINTENANCE | `#7B1FA2` (morado) | "🔧 MANTENIMIENTO" |

**`SetWindowsBrightness(brightness)`**  
Ajusta el brillo del monitor de Windows mediante PowerShell:
```powershell
(Get-WmiObject -Namespace root/wmi -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, {brightness})
```
Esto permite al operador del panel controlar el brillo de la pantalla de la baliza remotamente.

---

### MainWindow (Ventana Principal)

#### `MainWindow.xaml`
La interfaz gráfica principal de la baliza. Es una ventana WPF a pantalla completa.

**Estructura de la UI (XAML):**
- Fondo que cambia de color dinámicamente (binding a `BackgroundColor`).
- Texto principal grande con el mensaje actual (binding a `DisplayText`).
- Icono/imagen de la flecha direccional (binding a `CurrentArrow` con DataTriggers).
- Texto secundario con la zona (binding a `CurrentZone`).
- Reloj en tiempo real (actualizado por `_clockTimer`).
- Indicador de estado de conexión (binding a `StatusMessage`).
- Panel de control (visible para administradores): campo de comando, botón de envío, botón de reinicio.

**Data Binding en WPF:**
```xml
<!-- Ejemplo de binding -->
<TextBlock Text="{Binding DisplayText}"
           FontSize="80"
           Foreground="White"
           HorizontalAlignment="Center"/>

<!-- DataTrigger para cambiar la imagen de la flecha -->
<DataTrigger Binding="{Binding CurrentArrow}" Value="LEFT">
    <Setter Property="Source" Value="/Assets/arrow_left.png"/>
</DataTrigger>
```

#### `MainWindow.xaml.cs`
Code-behind de la ventana principal.

**Responsabilidades:**
1. **Inicialización** (`MainWindow_Loaded`):
   - Lee/crea la configuración con `BeaconConfigService.ReadOrCreateConfig()`.
   - Crea `ApiClient` y `MainViewModel`.
   - Establece el `DataContext = _viewModel` (conecta ViewModel con la View via WPF binding).
   - Inicia los servicios con `_viewModel.Start()`.
   - Inicia el reloj con `_clockTimer`.

2. **Cierre** (`MainWindow_Closing`):
   - Llama a `_viewModel.Stop()` para parar los timers y el BLE.
   - Para el timer del reloj.

3. **Gestión de teclas** (`Window_KeyDown`):
   - ESC → cierra la aplicación.

4. **Comandos locales** (`SendCommandButton_Click`, `RestartButton_Click`):
   - Envía comandos al servidor desde el panel local de la baliza.

5. **`ExecuteSystemCommand(command, value)`**:
   - Ejecuta comandos del sistema localmente: RESTART, SHUTDOWN, CLOSE_APP.

---

## Ciclo de Vida de la Aplicación

```
Windows inicia la app (autorun o manualmente)
    │
    ▼
App.xaml.cs → new MainWindow()
    │
    ▼
MainWindow.xaml.cs → MainWindow_Loaded
    │
    ▼
BeaconConfigService.ReadOrCreateConfig()
    │ Lee beacon_config.json (o lo crea si no existe)
    ▼
new ApiClient(config.ApiBaseUrl)
new MainViewModel(config, apiClient)
DataContext = _viewModel
    │
    ▼
_viewModel.Start()
    ├── ApiClient.CheckHealthAsync()
    ├── ApiClient.GetBeaconConfigAsync() → SyncConfigAsync()
    ├── ApiLogger.InitializeAsync()
    ├── Timer polling (300ms) → CheckGlobalState + SyncConfig + PollCommands
    ├── Timer heartbeat (10s) → SendHeartbeat
    └── BleBeaconService.Start()
    │
    ▼
Loop principal (WPF message pump)
    │
    ├── Cada 300ms: poll API → actualizar pantalla BLE
    ├── Cada 10s: heartbeat → reportar estado
    └── Al recibir UPDATE_CONFIG: actualizar pantalla instantáneamente
    │
    ▼
Cierre (ESC o señal del sistema)
    │
    ▼
MainWindow_Closing
    ├── _viewModel.Stop() → timers + BLE
    └── Aplicación cerrada
```

---

## Protocolo BLE

### Estructura del Payload (9 bytes)

```
Byte 0: Version (0x01)
Bytes 1-2: Zone ID (Big Endian)
    - Ejemplo: Zone 1001 = 0x03 0xE9
Byte 3: Mode
    - 0x00 = NORMAL
    - 0x01 = CONGESTION / SAFETY_CAR
    - 0x02 = EMERGENCY / RED_FLAG
    - 0x03 = EVACUATION
Byte 4: Flags (0x00 reservado)
Bytes 5-6: Sequence (Big Endian, incrementa con cada actualización)
Byte 7: TTL (0x0A = 10 segundos)
Byte 8: Temperature (°C como byte sin signo, max 255°C)
```

### Manufacturer ID
```
0x1234 (Company ID de prueba/desarrollo GeoRacing)
```

### Frecuencia de emisión
El BLE advertising se emite continuamente a la frecuencia que el stack BLE de Windows decida (típicamente cada 100-500ms). El payload solo se actualiza cuando el modo o la temperatura cambian.

---

## Sistema de Comandos

### Flujo completo

```
Panel Web (operador)
    │ Crea comando UPDATE_CONFIG en tabla "commands"
    ▼
API (MySQL)
    │ Comando PENDING en tabla commands
    ▼
Baliza (timer 300ms)
    │ GET /commands/pending/{uid}
    ▼
PollCommandsAsync()
    │ Verifica expiración (>60 min → DELETE)
    ▼
ProcessCommandAsync()
    ├── UPDATE_CONFIG → ProcessUpdateConfig() → Actualiza pantalla y BLE
    ├── RESTART → shutdown.exe /r → Windows reinicia en 3s
    ├── SHUTDOWN → shutdown.exe /s → Windows se apaga en 3s
    └── CLOSE_APP → Application.Current.Shutdown() → App cerrada
    │
    ▼
_apiClient.DeleteAsync("commands", {id: cmd.Id})
    │ Elimina el comando de la BD (no se re-ejecuta)
    ▼
Listo - próximo poll en 300ms
```

### Resolución de conflictos Estado Global vs. Individual

La baliza puede recibir instrucciones desde dos fuentes:
1. **Estado global** (`circuit_state`, modo para todo el circuito).
2. **Configuración individual** (tabla `beacons`, configuración específica de esta baliza).

**Regla 1: El global EVACUATION tiene prioridad absoluta.**  
Si el modo global es EVACUATION, se ignoran los comandos individuales de NORMAL.

**Regla 2: Periodo de gracia al salir de evacuación.**  
Cuando el modo global vuelve a NORMAL después de EVACUATION, hay una ventana de 5 segundos durante la cual se ignoran los comandos EVACUATION de la tabla individual (porque la BD puede tardar en actualizarse y enviaría comandos "stale").

---

## Modos de la Baliza

| Modo | Color UI | BLE Byte | Descripción |
|---|---|---|---|
| UNCONFIGURED | Azul `#1565C0` | N/A | Baliza recién instalada, sin configurar |
| NORMAL | Verde `#2E7D32` | `0x00` | Funcionamiento normal del circuito |
| CONGESTION | Naranja `#F57C00` | `0x01` | Zona congestionada, precaución |
| EMERGENCY | Rojo `#C62828` | `0x02` | Emergencia activa |
| EVACUATION | Rojo oscuro `#D32F2F` | `0x03` | Evacuación en progreso |
| MAINTENANCE | Morado `#7B1FA2` | N/A | Baliza en mantenimiento |

---

## Sistema de Logging

La baliza usa un sistema de logging de dos capas:

### 1. FileLogger (local)
- Escribe en `beacon_log.txt` en el directorio de la app.
- Funciona sin internet.
- Rotación automática a 10 MB.
- Formato: `[HH:mm:ss] [NIVEL] mensaje`

### 2. ApiLogger (remoto)
- Envía logs a la tabla `beacon_logs` en la BD.
- Los operadores del panel web los ven en tiempo real en la sección "Logs".
- Falla silenciosamente si no hay internet (fallback al FileLogger).

### Niveles de log
- `INFO` — Operaciones normales (heartbeat enviado, config sincronizada).
- `WARN` — Situaciones anómalas no críticas (comando desconocido, timeout API).
- `ERROR` — Errores que impiden funcionalidad (error BLE, error crítico API).

---

## Configuración del Sistema

### Fichero `beacon_config.json`

```json
{
  "beaconId": "BEACON-001-SECTOR-1",
  "name": "Baliza Entrada Sector 1",
  "description": "Acceso principal al Sector 1 desde aparcamiento",
  "zoneId": 1,
  "latitude": 41.383,
  "longitude": 2.182,
  "apiBaseUrl": "https://alpo.myqnapcloud.com:4010/api/"
}
```

El `beaconId` es el identificador único de la baliza. Debe coincidir con el que se registre en la BD del servidor.

### Inicio automático en Windows

Para que la baliza se inicie automáticamente cuando Windows arranca:
1. Añadir acceso directo a la app en `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`.
2. O configurar una tarea en el Programador de tareas de Windows.
3. O usar el registro: `HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`.

### Configuración de pantalla

Para garantizar que la ventana WPF siempre esté a pantalla completa sin posibilidad de minimizar:
- La ventana debe configurarse con `WindowStyle="None"` y `WindowState="Maximized"`.
- El `ResizeMode` debe ser `NoResize`.
- El `Topmost` puede activarse para que no se tape con otras ventanas.
