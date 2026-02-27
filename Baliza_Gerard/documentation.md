# Baliza_Gerard — Documentación Técnica Completa

## Índice

1. [Descripción General](#descripción-general)
2. [Tecnologías y Dependencias](#tecnologías-y-dependencias)
3. [Comparación con Baliza Noah](#comparación-con-baliza-noah)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Módulos y Ficheros Clave](#módulos-y-ficheros-clave)
   - [Program.cs — Lógica Principal](#programcs--lógica-principal)
   - [BeaconGui — Proyecto de GUI](#beacongui--proyecto-de-gui)
6. [Ciclo de Vida del Programa](#ciclo-de-vida-del-programa)
7. [Protocolo BLE](#protocolo-ble)
8. [Configuración](#configuración)
9. [Diferencias de Implementación vs. Noah](#diferencias-de-implementación-vs-noah)

---

## Descripción General

**Baliza Gerard** es el prototipo original de la baliza activa. Es una aplicación de **consola** (sin interfaz gráfica) que:

1. Se conecta a la API REST del circuito.
2. Lee el estado global del circuito cada 2 segundos.
3. Emite una señal BLE con el estado actual del circuito.
4. Mantiene el último estado conocido si la API falla (resiliencia).

Es un **prototipo de referencia** diseñado para:
- Probar el protocolo BLE antes de integrar en la baliza WPF completa (Noah).
- Despliegue en hardware dedicado (mini PC, Raspberry Pi con Windows) donde no se necesita interfaz gráfica.
- Debugging del protocolo BLE y del endpoint de la API.

**Estado del proyecto:** Prototipo funcional. La versión productiva es `Baliza_Noah`.

---

## Tecnologías y Dependencias

### Lenguaje y Framework

| Tecnología | Versión | Justificación |
|---|---|---|
| **C#** | 10+ | Lenguaje .NET para Windows. Compatibilidad nativa con WinRT APIs. |
| **.NET** | 7+ | Runtime de ejecución. |
| **Aplicación de Consola** | - | Sin UI gráfica, solo salida por consola (`Console.WriteLine`). |

### Bluetooth

| API | Versión | Justificación |
|---|---|---|
| **Windows.Devices.Bluetooth (WinRT)** | Windows 10+ | API BLE nativa de Windows. `BluetoothLEAdvertisementPublisher` para emitir señales BLE. `BluetoothAdapter.GetDefaultAsync()` para obtener información del adaptador BLE (dirección MAC). |
| **Windows.Storage.Streams.DataWriter** | - | Buffer de escritura para construir el payload BLE en formato binario. |

### HTTP y Serialización

| Librería | Justificación |
|---|---|
| **System.Net.Http.HttpClient** | Cliente HTTP nativo .NET. |
| **Newtonsoft.Json** | Librería JSON de terceros. Elegida por su facilidad de uso y madurez. A diferencia de `System.Text.Json`, es más permisiva con fechas y tipos no estándar. |

**¿Por qué Newtonsoft.Json en Gerard y System.Text.Json en Noah?**  
Gerard es el prototipo original, escrito antes de que `System.Text.Json` fuese tan maduro. Noah es la versión refinada que usa las APIs más modernas de .NET.

### Proyectos en la solución

```
Baliza_Gerard/
├── BeaconActivePc.csproj    # Proyecto principal (consola)
└── BeaconGui/               # Proyecto de GUI alternativo (WPF)
    └── BeaconGui.csproj
```

---

## Comparación con Baliza Noah

| Característica | Baliza Gerard | Baliza Noah |
|---|---|---|
| Interfaz | Consola (sin UI) | WPF a pantalla completa |
| Señalización visual | ❌ No | ✅ Pantalla con texto, flechas, colores |
| BLE Advertising | ✅ Sí | ✅ Sí |
| Heartbeat | ❌ No (solo lee estado) | ✅ Sí (cada 10s) |
| Polling de comandos | ❌ No | ✅ Sí (cada 300ms) |
| Configuración dinámica | ❌ No | ✅ Sí (UPDATE_CONFIG) |
| Logging | Consola + básico | Fichero + API |
| Resolución de conflictos global/individual | ❌ No | ✅ Sí |
| Dependencias externas | Newtonsoft.Json | Ninguna externa |
| Endpoint API | `/api/state` (legacy) | `/_get`, `/_upsert` (genérico) |
| Temperatura en BLE | ✅ Sí | ✅ Sí |
| Mostrar MAC address | ✅ Sí (al inicio) | ❌ No necesario |
| Uso previsto | Prototipo / hardware dedicado | Producción con pantalla |

---

## Estructura de Carpetas

```
Baliza_Gerard/
│
├── BeaconActivePc.csproj         # Proyecto de consola (.NET)
├── Program.cs                    # TODA la lógica del programa (un solo fichero)
│
└── BeaconGui/                    # Proyecto WPF alternativo (GUI básica)
    ├── BeaconGui.csproj
    ├── App.xaml                  # Aplicación WPF
    ├── App.xaml.cs
    ├── AssemblyInfo.cs
    ├── MainWindow.xaml           # Ventana principal
    └── MainWindow.xaml.cs        # Code-behind básico
```

**¿Por qué todo en un solo fichero `Program.cs`?**  
Es un prototipo de rápido desarrollo. La simplicidad de tener todo en un fichero facilita:
- Copiar y pegar el código completo para pruebas.
- Modificar rápidamente sin navegar entre ficheros.
- Despliegue en entornos de test donde la mantenibilidad no es prioritaria.

---

## Módulos y Ficheros Clave

### `Program.cs` — Lógica Principal

El fichero único contiene toda la lógica en la clase `Program` y un DTO `CircuitStateDto`.

#### Constantes de configuración

```csharp
private const string API_URL = "https://alpo.myqnapcloud.com:4010/api/state";
private const ushort MANUFACTURER_ID = 0x1234;
private const int POLL_INTERVAL_MS = 2000;           // 2 segundos entre polls
private const ushort ZONE_ID = 1001;                  // ID de zona de esta baliza
```

**Diferencias con Noah:**
- Endpoint `api/state` (legacy) vs `_get` (genérico) en Noah.
- `POLL_INTERVAL_MS = 2000` (2 segundos) vs 300ms en Noah.
- Sin sistema de configuración externa (todo hardcodeado).

#### Variables de estado

```csharp
private static HttpClient client;
private static BluetoothLEAdvertisementPublisher publisher;
private static ushort sequenceConfig = 0;    // Contador de secuencia BLE
private static byte currentMode = 0;          // Modo actual (0=NORMAL)
private static string lastKnownTemp = "";     // Última temperatura conocida
```

**`lastKnownTemp`** — Almacena la última temperatura conocida como string (ej: "11.3°C"). Si la API falla, la baliza sigue emitiendo BLE con la última temperatura conocida, en lugar de resetear a 0.

#### `Main(string[] args)` — Método de entrada

```csharp
static async Task Main(string[] args)
{
    // 1. Inicializar HttpClient con SSL desactivado
    var handler = new HttpClientHandler();
    handler.ServerCertificateCustomValidationCallback = (req, cert, chain, errors) => true;
    client = new HttpClient(handler);

    // 2. Mostrar información de la baliza
    Console.WriteLine("=== GeoRacing Active Beacon (PC) ===");

    // 3. Obtener y mostrar la dirección MAC del adaptador BLE
    var adapter = await BluetoothAdapter.GetDefaultAsync();
    string mac = FormatMacAddress(adapter.BluetoothAddress);
    Console.WriteLine($"My MAC Address: {mac}");
    Console.WriteLine($"API: {API_URL} | Zone: {ZONE_ID}");

    // 4. Inicializar el publisher BLE
    publisher = new BluetoothLEAdvertisementPublisher();
    publisher.StatusChanged += Publisher_StatusChanged;

    // 5. Iniciar el bucle de polling en background
    _ = Task.Run(PollApiLoop);

    // 6. Esperar tecla para salir
    Console.ReadKey();
    publisher.Stop();
}
```

**¿Por qué mostrar la MAC address?**  
Es útil para identificar físicamente la baliza en el entorno. Cuando hay varias balizas idénticas, la MAC address permite saber cuál es cuál sin abrir el PC o mirar la etiqueta.

#### `PollApiLoop()` — Bucle de polling

```csharp
private static async Task PollApiLoop()
{
    while (true)
    {
        try
        {
            // 1. Fetch del estado de la API
            var json = await client.GetStringAsync(API_URL);
            var state = JsonConvert.DeserializeObject<CircuitStateDto>(json);

            if (state != null)
            {
                // 2. Mapear modo string a byte
                var newMode = MapModeToByte(state.global_mode ?? state.mode);
                lastKnownTemp = state.temperature;  // Guardar temperatura

                // 3. Actualizar advertising BLE
                UpdateAdvertising(newMode);

                Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] API OK. Mode: {state.global_mode} -> {newMode}. Seq: {sequenceConfig}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] API Error: {ex.Message}");
            // Sigue broadcasting el último estado conocido (comportamiento resiliente)
        }

        await Task.Delay(POLL_INTERVAL_MS);  // Esperar 2 segundos
    }
}
```

**Comportamiento ante fallos de red:**  
Si la API no responde, la baliza **continúa emitiendo el último estado BLE conocido** en lugar de resetear a NORMAL. Esto es importante porque en una situación de emergencia, si la red falla, las balizas deben seguir mostrando el estado de emergencia.

#### `UpdateAdvertising(byte mode)` — Actualizar BLE

```csharp
private static void UpdateAdvertising(byte mode)
{
    sequenceConfig++;    // Incrementar secuencia
    byte ttl = 10;       // 10 segundos de validez
    byte flags = 0x00;
    byte tempByte = ParseTemperature(lastKnownTemp);

    // Construir payload de 9 bytes
    var writer = new DataWriter();
    writer.WriteByte(0x01);           // Version
    writer.WriteUInt16(ZONE_ID);      // Zone ID (Little Endian con DataWriter)
    writer.WriteByte(mode);           // Mode
    writer.WriteByte(flags);          // Flags
    writer.WriteUInt16(sequenceConfig); // Sequence
    writer.WriteByte(ttl);            // TTL
    writer.WriteByte(tempByte);       // Temperature

    var buffer = writer.DetachBuffer();
    var manufacturerData = new BluetoothLEManufacturerData(MANUFACTURER_ID, buffer);

    // Reiniciar publisher con nuevo payload
    publisher.Stop();
    publisher.Advertisement.ManufacturerData.Clear();
    publisher.Advertisement.ManufacturerData.Add(manufacturerData);
    publisher.Start();
}
```

**Parsing de temperatura:**  
La temperatura viene como string desde la API (ej: "11.3°C" o "23"). El código extrae solo los dígitos numéricos:
```csharp
var digits = new string(lastKnownTemp.Where(char.IsDigit).ToArray());
if (byte.TryParse(digits, out byte t)) tempByte = t;
```

**Nota:** Este parsing es simplista y puede fallar si la temperatura tiene decimales (ej: "11.3" → extraería "113" en lugar de 11 o 12). Noah usa un parser más robusto.

#### `MapModeToByte(string modeString)` — Conversión de modo

```csharp
return modeString.ToUpper() switch
{
    "NORMAL" => 0,
    "SAFETY_CAR" => 1,
    "RED_FLAG" => 2,
    "EVACUATION" => 3,
    _ => 0  // Default: NORMAL
};
```

**Diferencias con Noah:** Gerard mapea `SAFETY_CAR → 1` y `RED_FLAG → 2`. Noah además mapea `CONGESTION → 1` y `EMERGENCY → 2` (más modos soportados).

#### `CircuitStateDto` — DTO de la API

```csharp
class CircuitStateDto
{
    public string id { get; set; }
    public string global_mode { get; set; }
    public string mode { get; set; }     // Campo legacy/alternativo
    public string message { get; set; }
    public string temperature { get; set; }  // Puede ser "11.3°C" o número
}
```

El código usa `state.global_mode ?? state.mode` para soportar tanto el campo nuevo (`global_mode`) como el antiguo (`mode`), garantizando compatibilidad con diferentes versiones del endpoint.

---

### BeaconGui — Proyecto de GUI

El directorio `BeaconGui/` contiene una versión alternativa con interfaz gráfica WPF básica.

#### `BeaconGui/MainWindow.xaml.cs`
Ventana WPF básica con:
- Visualización del estado actual del circuito.
- Indicador de conexión a la API.
- Botón para forzar actualización.

**Estado:** Prototipo básico, no tiene la funcionalidad completa de la Baliza Noah.

---

## Ciclo de Vida del Programa

```
Inicio del programa
    │
    ▼
Main() en Program.cs
    │
    ▼
1. Crear HttpClient (SSL desactivado)
    │
    ▼
2. Obtener y mostrar MAC address BLE
    │ BluetoothAdapter.GetDefaultAsync()
    ▼
3. Inicializar BluetoothLEAdvertisementPublisher
    │ Suscribir a StatusChanged
    ▼
4. Task.Run(PollApiLoop) — Bucle en background
    │
    ▼
5. Console.ReadKey() — Esperar tecla del usuario
    │
    │ LOOP PRINCIPAL (background):
    │   ┌────────────────────────────────┐
    │   │ GET api/state                  │
    │   │ → Deserializar CircuitStateDto  │
    │   │ → MapModeToByte(global_mode)   │
    │   │ → UpdateAdvertising(newMode)   │
    │   │   → publisher.Stop()           │
    │   │   → Construir payload 9 bytes  │
    │   │   → publisher.Start()          │
    │   │ Esperar 2000ms                 │
    │   └────────────────────────────────┘
    │
    ▼
6. Tecla presionada → publisher.Stop() → Fin
```

---

## Protocolo BLE

### Payload de 9 bytes

La estructura es idéntica al protocolo de Noah (misma spec), aunque con algunas diferencias de implementación:

| Byte | Campo | Valor |
|---|---|---|
| 0 | Version | `0x01` |
| 1-2 | Zone ID | `ZONE_ID` = 1001 = `0x03 0xE9` |
| 3 | Mode | `0x00`-`0x03` |
| 4 | Flags | `0x00` |
| 5-6 | Sequence | Incrementa en cada actualización |
| 7 | TTL | `0x0A` (10 segundos) |
| 8 | Temperature | Temperatura en °C |

### Diferencia de endianness

**Gerard** usa `DataWriter.WriteUInt16(ZONE_ID)` que escribe en **Little Endian** (por defecto en DataWriter de WinRT).

**Noah** construye el payload manualmente con Big Endian:
```csharp
payload[1] = (byte)((zoneId >> 8) & 0xFF);  // High byte
payload[2] = (byte)(zoneId & 0xFF);          // Low byte
```

**Implicación:** Las apps móviles deben tener en cuenta el endianness al parsear el Zone ID. Si Gerard y Noah usan diferente endianness para el mismo campo, puede haber inconsistencias. En el código actual de las apps, se asume Big Endian (protocolo de Noah).

---

## Configuración

A diferencia de Noah que usa un fichero `beacon_config.json`, Gerard tiene toda la configuración **hardcodeada** en constantes al inicio de `Program.cs`:

```csharp
private const string API_URL = "https://alpo.myqnapcloud.com:4010/api/state";
private const ushort MANUFACTURER_ID = 0x1234;
private const int POLL_INTERVAL_MS = 2000;
private const ushort ZONE_ID = 1001;
```

**Para cambiar la configuración de una baliza Gerard**, se debe:
1. Modificar las constantes en `Program.cs`.
2. Recompilar el proyecto.
3. Desplegar el nuevo ejecutable.

Esto hace que Gerard sea menos flexible que Noah para gestión masiva de balizas, pero más sencillo para prototipado.

---

## Diferencias de Implementación vs. Noah

### 1. Endpoint de la API

**Gerard:**
```
GET https://alpo.myqnapcloud.com:4010/api/state
```
Devuelve directamente el estado del circuito. Endpoint simple y directo.

**Noah:**
```
POST https://alpo.myqnapcloud.com:4010/api/_get
Body: { "table": "circuit_state", "where": { "id": "1" } }
```
Endpoint genérico que permite consultar cualquier tabla. Más flexible pero más verboso.

### 2. Frecuencia de polling

| Aspecto | Gerard | Noah |
|---|---|---|
| Estado global | 2 segundos | 300ms |
| Config individual | No | 300ms |
| Heartbeat | No | 10 segundos |
| Latencia de respuesta | ~2 segundos | ~300ms |

La diferencia es significativa en situaciones de emergencia: Noah responde en 300ms mientras que Gerard puede tardar hasta 2 segundos.

### 3. Manejo de temperatura

**Gerard:** Parsing simple extrayendo solo dígitos del string. Puede fallar con decimales.

**Noah:** Parsing robusto con `double.TryParse()` y `CultureInfo.InvariantCulture`. Soporta tanto strings ("11.3°C") como números.

### 4. Gestión del publisher BLE

**Ambos** recrean el publisher en cada actualización (necesario por la API WinRT).

**Gerard:** Siempre actualiza en cada poll, aunque el modo no haya cambiado.

**Noah:** Solo actualiza si el modo o la temperatura han cambiado realmente, evitando Stop/Start innecesarios.

### 5. Resiliencia ante fallos

**Gerard:** Mantiene el último estado BLE si la API falla (comportamiento básico).

**Noah:** Sistema completo de resolución de conflictos, periodo de gracia, prioridad del estado global, etc.

### 6. Heartbeat

**Gerard:** No envía heartbeat. El servidor no sabe si la baliza está online o no.

**Noah:** Heartbeat cada 10 segundos con estado completo (modo, flecha, mensaje, batería). El panel web puede ver si la baliza está online/offline.

### 7. Comandos

**Gerard:** No procesa comandos desde el servidor. Solo lee estado.

**Noah:** Polling completo de comandos. Soporta UPDATE_CONFIG, RESTART, SHUTDOWN, CLOSE_APP.
