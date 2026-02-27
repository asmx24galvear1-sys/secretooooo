# iOS_App — Documentación Técnica Completa

## Índice

1. [Descripción General](#descripción-general)
2. [Tecnologías y Dependencias](#tecnologías-y-dependencias)
3. [Arquitectura](#arquitectura)
4. [Estructura de Carpetas](#estructura-de-carpetas)
5. [Módulos y Ficheros Clave](#módulos-y-ficheros-clave)
   - [Punto de Entrada](#punto-de-entrada)
   - [Core (Núcleo)](#core-núcleo)
   - [Domain (Dominio)](#domain-dominio)
   - [Data (Datos)](#data-datos)
   - [Presentation (Presentación)](#presentation-presentación)
   - [CarPlay](#carplay)
   - [Backend Auxiliar](#backend-auxiliar)
6. [Funcionalidades Principales](#funcionalidades-principales)
7. [Flujo de Autenticación](#flujo-de-autenticación)
8. [Sistema BLE (CoreBluetooth)](#sistema-ble-corebluetooth)
9. [Integración con CarPlay](#integración-con-carplay)

---

## Descripción General

La aplicación iOS de GeoRacing es la versión para iPhone/iPad de la app para asistentes al evento. Busca paridad de funcionalidades con la app Android, adaptando el diseño y las APIs al ecosistema Apple.

**Características clave:**
- Mapa del circuito con navegación peatonal (MapKit).
- Estado del circuito en tiempo real via Firestore y BLE.
- Sistema de grupos con ubicación compartida.
- Fan Zone: noticias, quiz, encuestas.
- Sistema de pedidos (comida y merchandising).
- Integración con CarPlay para navegación en el coche.
- Escaneo BLE de balizas físicas del circuito.
- Gamificación y coleccionables.
- Modo staff para el personal del evento.

---

## Tecnologías y Dependencias

### Lenguaje y Framework

| Tecnología | Versión | Justificación |
|---|---|---|
| **Swift** | 5.x | Lenguaje oficial de Apple. Seguro, moderno y eficiente. |
| **SwiftUI** | iOS 16+ | Framework declarativo de UI de Apple. Permite crear interfaces reactivas con poco código. |
| **Combine / async-await** | - | Programación reactiva y asíncrona. `async/await` para operaciones de red, `@Published` para estado reactivo. |

### Firebase (via CocoaPods)

| Pod | Justificación |
|---|---|
| `Firebase/Auth` | Autenticación de usuarios (email, Google). Base para controlar el acceso a funcionalidades según el rol del usuario. |
| `Firebase/Firestore` | Base de datos NoSQL en la nube para datos en tiempo real: noticias, estado del circuito, pedidos, noticias, ubicaciones de grupo. |
| `GoogleSignIn` | Permite el inicio de sesión con cuenta de Google, integrado con Firebase Auth. |

### Mapas y Localización

| Framework/SDK | Justificación |
|---|---|
| **MapKit** | Framework de mapas de Apple. Integrado en el sistema iOS, sin coste de licencia. Soporte para anotaciones, overlays, rutas y búsqueda de lugares. |
| **CoreLocation** | Acceso a GPS, brújula y geofencing. Base para la navegación peatonal y la detección de zonas. |

### Bluetooth

| Framework | Justificación |
|---|---|
| **CoreBluetooth** | Framework nativo de Apple para BLE. Permite escanear las señales de las balizas físicas del circuito. |

### CarPlay

| Framework | Justificación |
|---|---|
| **CarPlay** | Framework de Apple para integración con la pantalla de vehículos. Requiere entitlement especial de Apple. |

### Sistema

| Framework | Justificación |
|---|---|
| **AVFoundation** | Síntesis de voz (TTS) para instrucciones de navegación. |
| **AVKit** | Reproducción de vídeo en la Fan Zone. |
| **HealthKit** | Acceso a datos de salud del usuario (pasos, distancia) para el EcoMeter. |
| **UserNotifications** | Notificaciones locales para alertas de emergencia y estado del circuito. |
| **StoreKit** | Compras dentro de la app. |
| **Vision** | Escaneo de códigos QR via cámara. |
| **ARKit** | Realidad Aumentada básica. |

### CocoaPods (Gestor de dependencias)

El fichero `Podfile` define las dependencias externas:
```ruby
platform :ios, '16.0'
use_frameworks!

target 'GeoRacing' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'GoogleSignIn'
end
```

**¿Por qué CocoaPods y no Swift Package Manager?**  
Firebase para iOS recomienda CocoaPods como método de integración principal. Aunque SPM ya está disponible, la compatibilidad es más robusta con CocoaPods.

---

## Arquitectura

La app sigue **MVVM + Clean Architecture** adaptada a SwiftUI:

```
┌─────────────────────────────────────────┐
│     Presentation Layer (SwiftUI)         │
│   Views + ViewModels (@ObservableObject) │
└──────────────────┬──────────────────────┘
                   │ @Published / ObservableObject
┌──────────────────▼──────────────────────┐
│     Domain Layer                         │
│   Models + Services (protocolos)        │
│   + Features (FeatureRegistry)          │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│     Data Layer                           │
│   Repositories + BLE Scanner            │
│   + API Services + Auth                 │
└─────────────────────────────────────────┘
```

**Patrones usados:**
- **MVVM** — Views observan ViewModels via `@ObservableObject` / `@StateObject`.
- **Repository Pattern** — Las views y VMs nunca acceden directamente a la red o Firestore.
- **Dependency Injection** — Los servicios se inyectan via inicializadores o via `@EnvironmentObject`.
- **Combine / async-await** — Para operaciones asíncronas y streams de datos.

---

## Estructura de Carpetas

```
iOS_App/
│
├── GeoRacing/                       # Código fuente principal
│   ├── GeoRacingApp.swift           # @main — Punto de entrada de la app
│   ├── ContentView.swift            # Vista raíz de la app
│   ├── GoogleService-Info.plist     # Configuración Firebase (iOS)
│   ├── Info.plist                   # Permisos y configuración del bundle
│   │
│   ├── Core/                        # Utilidades y código de núcleo
│   │   ├── Constants/
│   │   │   └── AppConstants.swift   # Constantes globales (URLs, configuración)
│   │   ├── Enums/
│   │   │   └── TabIdentifier.swift  # Identificadores de tabs de navegación
│   │   ├── Extensions/
│   │   │   └── MKMapItem+Coordinate.swift  # Extensión de MapKit
│   │   └── Utilities/
│   │       ├── LocalNotificationManager.swift  # Notificaciones locales
│   │       ├── LocalizationUtils.swift          # Utilidades de localización
│   │       ├── LocationManager.swift            # Gestión de GPS (CoreLocation)
│   │       ├── Logger.swift                     # Sistema de logging
│   │       ├── PolylineUtils.swift              # Utilidades para polilíneas de rutas
│   │       ├── RacingDesignSystem.swift         # Sistema de diseño de GeoRacing
│   │       └── UserPreferences.swift            # Preferencias del usuario (UserDefaults)
│   │
│   ├── Domain/                      # Capa de dominio
│   │   ├── Models/                  # Modelos de datos
│   │   │   ├── AppUser.swift        # Modelo de usuario de la app
│   │   │   ├── BeaconModels.swift   # Modelos de balizas BLE
│   │   │   ├── CircuitModels.swift  # Modelos del circuito
│   │   │   ├── FanZoneModels.swift  # Modelos de la Fan Zone
│   │   │   ├── GroupModels.swift    # Modelos de grupos
│   │   │   ├── MapModels.swift      # Modelos de mapa (POIs, overlays)
│   │   │   ├── ParkingModels.swift  # Modelos de aparcamiento
│   │   │   ├── PoiModels.swift      # Modelos de puntos de interés
│   │   │   ├── RouteModels.swift    # Modelos de rutas
│   │   │   ├── ServiceModels.swift  # Modelos de servicios del circuito
│   │   │   ├── ShopModels.swift     # Modelos de la tienda
│   │   │   ├── SocialModels.swift   # Modelos sociales (posts, likes)
│   │   │   └── TrackStatus.swift    # Estado de la pista (bandera, modo)
│   │   ├── Services/                # Servicios de dominio
│   │   │   ├── CartManager.swift               # Gestión del carrito de compra
│   │   │   ├── EmergencyImageGenerator.swift   # Generador de imágenes de emergencia
│   │   │   ├── EnergyManagementService.swift   # Gestión de energía/batería
│   │   │   ├── HealthService.swift             # Servicio de salud (HealthKit)
│   │   │   ├── MapStyleManager.swift           # Gestión de estilos de mapa
│   │   │   ├── OffRouteDetector.swift          # Detector de desvío de ruta
│   │   │   ├── RouteManager.swift              # Gestión de rutas de navegación
│   │   │   ├── RouteSnapper.swift              # Ajuste de posición a ruta
│   │   │   ├── StaffBeaconService.swift        # Servicio BLE para staff
│   │   │   ├── SyncQueueManager.swift          # Cola de sincronización offline
│   │   │   ├── TTSManager.swift                # Text-to-Speech
│   │   │   ├── TelemetryLogger.swift           # Telemetría y analytics
│   │   │   └── ThermalRoutingService.swift     # Enrutamiento considerando calor/sombra
│   │   └── Features/
│   │       ├── FeatureRegistry.swift           # Registro de features habilitables
│   │       └── FeatureViewFactory.swift        # Factory para crear vistas de features
│   │
│   ├── Data/                        # Capa de datos
│   │   ├── BLE/
│   │   │   ├── BeaconScanner.swift  # Escáner BLE (CoreBluetooth)
│   │   │   └── BleCircuitSignal.swift  # Modelo de señal BLE parseada
│   │   ├── Repositories/
│   │   │   ├── CircuitStatusRepository.swift   # Estado del circuito (Firestore + API)
│   │   │   ├── GroupLocationRepository.swift   # Ubicaciones del grupo
│   │   │   ├── GroupRepository.swift           # Datos de grupos
│   │   │   ├── HybridCircuitStateRepository.swift  # Hybrid: Firestore + BLE
│   │   │   ├── NewsRepository.swift            # Noticias de fans
│   │   │   ├── OrdersRepository.swift          # Pedidos
│   │   │   ├── ProductRepository.swift         # Catálogo de productos
│   │   │   ├── RouteRepository.swift           # Rutas del circuito
│   │   │   ├── ShareSessionRepository.swift    # Sesiones de compartir ubicación
│   │   │   └── UserProfileRepository.swift     # Perfil de usuario
│   │   └── Services/
│   │       ├── APIModels.swift          # Modelos de la API REST
│   │       ├── APIService.swift         # Cliente de la API REST
│   │       ├── AuthService.swift        # Servicio de autenticación Firebase
│   │       ├── CrowdDensityService.swift # Densidad de gente por zona
│   │       ├── DatabaseClient.swift     # Cliente de Firestore
│   │       ├── FanNewsService.swift     # Servicio de noticias para fans
│   │       ├── NavigationService.swift  # Servicio de navegación
│   │       ├── ParkingService.swift     # Servicio de aparcamiento
│   │       ├── QuestionService.swift    # Servicio de preguntas/quiz
│   │       ├── RewardService.swift      # Servicio de recompensas/gamificación
│   │       ├── SpeechService.swift      # Síntesis de voz
│   │       ├── TeamAssetManager.swift   # Assets de equipos de F1
│   │       ├── TeamCatalogLoader.swift  # Cargador del catálogo de equipos
│   │       ├── TeamCatalogService.swift # Servicio del catálogo de equipos
│   │       ├── TransportAPIClient.swift # Cliente de API de transporte público
│   │       └── TransportLocalFallback.swift # Fallback local de transporte
│   │
│   ├── Presentation/                # Capa de presentación
│   │   ├── ViewModels/
│   │   │   ├── AlertsViewModel.swift          # ViewModel de alertas
│   │   │   ├── FanZoneViewModel.swift         # ViewModel de la Fan Zone
│   │   │   ├── GroupViewModel.swift           # ViewModel de grupos
│   │   │   ├── GuidanceViewModel.swift        # ViewModel de guía/navegación
│   │   │   ├── HomeViewModel.swift            # ViewModel de la pantalla principal
│   │   │   ├── IncidentViewModel.swift        # ViewModel de incidentes
│   │   │   ├── MapViewModel.swift             # ViewModel del mapa
│   │   │   ├── NavigationViewModel.swift      # ViewModel de navegación
│   │   │   ├── OrdersViewModel.swift          # ViewModel de pedidos
│   │   │   ├── PublicTransportViewModel.swift # ViewModel de transporte público
│   │   │   └── SocialViewModel.swift          # ViewModel social
│   │   ├── Views/                   # Vistas SwiftUI
│   │   │   ├── HomeView.swift               # Pantalla principal
│   │   │   ├── LoginView.swift              # Login
│   │   │   ├── OnboardingView.swift         # Onboarding
│   │   │   ├── MapView → CircuitMapView.swift # Mapa del circuito
│   │   │   ├── NavigationScreen.swift       # Navegación peatonal
│   │   │   ├── GuidanceView.swift           # Guía paso a paso
│   │   │   ├── FanZoneView.swift            # Zona de fans
│   │   │   ├── FanNewsView.swift            # Noticias de fans
│   │   │   ├── GroupView.swift              # Vista de grupos
│   │   │   ├── OrdersView.swift             # Lista de pedidos
│   │   │   ├── MyOrdersView.swift           # Mis pedidos
│   │   │   ├── PoiListView.swift            # Lista de POIs
│   │   │   ├── SettingsView.swift           # Configuración
│   │   │   ├── SocialView.swift             # Vista social
│   │   │   ├── StaffModeView.swift          # Modo staff
│   │   │   ├── IncidentReportView.swift     # Reporte de incidentes
│   │   │   ├── EmergencySetupView.swift     # Configuración de emergencia
│   │   │   ├── EvacuationView.swift         # Vista de evacuación
│   │   │   ├── CircuitControlView.swift     # Control del circuito (staff)
│   │   │   ├── SeatSetupView.swift          # Configuración del asiento
│   │   │   ├── QRScannerView.swift          # Escáner de QR
│   │   │   ├── QuizView.swift               # Quiz/trivial
│   │   │   ├── RoadmapView.swift            # Roadmap/itinerario
│   │   │   ├── TeamSelectorView.swift       # Selector de equipo favorito
│   │   │   ├── CardView.swift               # Tarjeta genérica
│   │   │   ├── CardCollectionView.swift     # Colección de tarjetas
│   │   │   ├── SideMenuView.swift           # Menú lateral
│   │   │   ├── FeaturesOverviewView.swift   # Resumen de features
│   │   │   ├── HomeCustomizeView.swift      # Personalización de la home
│   │   │   ├── ServiceViews.swift           # Vistas de servicios del circuito
│   │   │   ├── NewsItemView.swift           # Elemento de noticia
│   │   │   ├── ItineraryDetailSheet.swift   # Detalle del itinerario
│   │   │   ├── PublicTransportSheetView.swift # Transporte público
│   │   │   └── Shared/                     # Vistas compartidas reutilizables
│   │   ├── Components/              # Componentes UI reutilizables
│   │   │   ├── DashboardButton.swift   # Botón del dashboard
│   │   │   ├── GPSMapView.swift        # Vista del mapa GPS
│   │   │   ├── QRCodeScannerView.swift # Escáner QR (UIViewRepresentable)
│   │   │   └── WebView.swift           # WebView (UIViewRepresentable)
│   │   ├── ContextualCard/          # Tarjetas contextuales
│   │   ├── Parking/                 # Componentes de aparcamiento
│   │   └── Theme/                   # Tema visual de la app
│   │
│   ├── CarPlay/                     # Módulo CarPlay
│   │   └── (Implementación de CarPlay Scene Delegate)
│   │
│   ├── Assets.xcassets              # Imágenes, iconos y colores
│   └── Resources/                   # Fuentes, archivos de localización, etc.
│
├── GeoRacingTests/                  # Tests unitarios
├── GeoRacingUITests/                # Tests de UI (XCUITest)
├── GeoRacing.xcodeproj/             # Proyecto Xcode
├── Podfile                          # Dependencias CocoaPods
├── FEATURES.md                      # Lista de features implementadas
├── PARITY_CHECKLIST.md              # Checklist de paridad con Android
└── backend/                         # Backends auxiliares
    ├── otp/                         # Servidor OTP (One Time Password)
    └── transport-api/               # API de transporte público local
```

---

## Módulos y Ficheros Clave

### Punto de Entrada

#### `GeoRacingApp.swift`
El punto de entrada de la aplicación iOS, marcado con `@main`.

**Responsabilidades:**
1. **`AppDelegate`** — Configura Firebase al iniciar la app con `FirebaseApp.configure()`.
2. **Escenas de CarPlay** — Detecta si la escena conectada es de CarPlay (`carTemplateApplication`) y asigna `CarPlaySceneDelegate` como delegado.
3. **`GeoRacingApp` struct** — Cuerpo principal de la app (`WindowGroup`) que muestra el `ContentView`.
4. Al aparecer (`onAppear`):
   - `BeaconScanner.shared.loadBeacons()` — Carga las balizas conocidas.
   - `LocalNotificationManager.shared.requestPermission()` — Pide permiso para notificaciones.
5. Gestiona la apertura de URLs para Google Sign-In OAuth (`GIDSignIn.sharedInstance.handle(url)`).

---

### Core (Núcleo)

#### `Core/Constants/AppConstants.swift`
Constantes globales de la aplicación: URLs de la API, identificadores de Firestore, configuraciones de BLE (UUID del servicio, Manufacturer ID), límites de timeout, etc.

#### `Core/Enums/TabIdentifier.swift`
Enum que define los identificadores de las tabs de la barra de navegación inferior. Permite la navegación programática entre tabs.

#### `Core/Extensions/MKMapItem+Coordinate.swift`
Extensión de la clase `MKMapItem` de MapKit. Añade una propiedad `coordinate` de acceso rápido a la coordenada CLLocationCoordinate2D del ítem. Simplifica el código que trabaja con destinos de MapKit.

#### `Core/Utilities/LocationManager.swift`
Wrapper sobre `CLLocationManager` de CoreLocation.
- Solicita permisos de ubicación.
- Publica la ubicación actual via `@Published`.
- Gestiona la precisión de ubicación (más alta para navegación, más baja para background).
- Soporte para geofencing (alertas de entrada/salida de zonas del circuito).

#### `Core/Utilities/LocalNotificationManager.swift`
Gestiona el ciclo de vida de las notificaciones locales con `UNUserNotificationCenter`:
- Solicita permisos.
- Programa notificaciones de emergencia (evacuación, bandera roja).
- Cancela notificaciones cuando la situación se normaliza.

#### `Core/Utilities/TTSManager.swift`
Text-to-Speech con `AVSpeechSynthesizer`:
- Instrucciones de navegación en el idioma del dispositivo.
- Alertas de emergencia con prioridad máxima (interrumpe la música).
- Soporte multiidioma.

#### `Core/Utilities/RacingDesignSystem.swift`
Sistema de diseño de GeoRacing: colores por modo del circuito (verde=normal, naranja=safety car, rojo=emergencia/evacuación), tipografías, dimensiones estándar. Garantiza consistencia visual en todas las vistas.

#### `Core/Utilities/UserPreferences.swift`
Wrapper sobre `UserDefaults` para gestionar las preferencias del usuario:
- Equipo favorito seleccionado.
- Preferencias de notificaciones.
- Configuración del mapa.
- Historial de asientos visitados.

---

### Domain (Dominio)

#### `Domain/Models/`

**`TrackStatus.swift`**  
Enum y struct que modela el estado de la pista:
- `TrackMode`: `.normal`, `.safetyCar`, `.redFlag`, `.evacuation`, `.unknown`
- Incluye temperatura, mensaje, ruta de evacuación.

**`BeaconModels.swift`**  
Modelos para las balizas BLE:
- `GeoBeacon` — Representa una baliza detectada (ID de zona, modo, RSSI, distancia estimada).
- `BlePayload` — Estructura del payload BLE de 9 bytes.

**`CircuitModels.swift`**  
Modelos del circuito: zonas, sectores, curvas, rectas, puntos de interés.

**`GroupModels.swift`**  
- `GroupMember` — Miembro de un grupo con nombre, ubicación y timestamp.
- `Group` — Grupo de usuarios con un código de invitación.

**`ShopModels.swift`**  
- `Product` — Producto con nombre, descripción, precio, imagen.
- `CartItem` — Ítem del carrito.
- `Order` — Pedido confirmado con estado.

**`SocialModels.swift`**  
Modelos para el feed social: posts, comentarios, likes, fotos del evento.

#### `Domain/Services/`

**`CartManager.swift`**  
Gestor del carrito de compras. Singleton que mantiene el estado del carrito entre vistas. Lógica de añadir, eliminar, actualizar cantidades, calcular totales.

**`RouteManager.swift`**  
Gestiona las rutas de navegación peatonal. Calcula rutas usando el grafo del circuito o la API de transporte. Emite actualizaciones de ruta via `@Published`.

**`OffRouteDetector.swift`**  
Detecta si el usuario se ha desviado de la ruta. Si supera el umbral de metros configurado, notifica al `RouteManager` para recalcular.

**`ThermalRoutingService.swift`**  
Servicio innovador que recomienda rutas teniendo en cuenta el calor del sol. Prefiere rutas con sombra en días calurosos, datos de temperatura del circuito obtenidos del estado global.

**`SyncQueueManager.swift`**  
Cola de sincronización para operaciones que fallan sin internet. Almacena las operaciones pendientes y las reintenta cuando la conectividad se restaura.

**`TelemetryLogger.swift`**  
Registra eventos analíticos del uso de la app (pantallas visitadas, funciones usadas, tiempos de carga). Los datos se envían en batch a Firestore.

**`EnergyManagementService.swift`**  
Similar al `EnergyMonitor` de Android. Monitorea la batería del dispositivo y ajusta el comportamiento de la app (frecuencia de actualización del GPS, BLE, etc.) según el nivel de batería.

**`StaffBeaconService.swift`**  
Servicio BLE específico para el personal del evento. Emite señales BLE de identificación de staff usando `CBPeripheralManager`.

**`EmergencyImageGenerator.swift`**  
Genera una imagen con la información médica de emergencia del usuario para mostrar en la pantalla de bloqueo.

#### `Domain/Features/`

**`FeatureRegistry.swift`**  
Registro de features que pueden habilitarse/deshabilitarse dinámicamente:
- Permite activar features en pruebas A/B.
- Permite desactivar features con bugs sin publicar una nueva versión.
- Las features se configuran desde Firestore (Remote Config).

**`FeatureViewFactory.swift`**  
Factory pattern para crear las vistas de cada feature. Desacopla la creación de vistas del sistema de navegación.

---

### Data (Datos)

#### `Data/BLE/BeaconScanner.swift`
Singleton que gestiona el escaneo BLE con `CBCentralManager`:

1. Solicita permiso de Bluetooth.
2. Escanea todos los periféricos BLE en background.
3. Filtra por `CBAdvertisementDataManufacturerDataKey` con el Manufacturer ID `0x1234`.
4. Parsea el payload de 9 bytes (mismo protocolo que las balizas).
5. Calcula la distancia estimada usando la fórmula de propagación de radio (RSSI + potencia de transmisión).
6. Publica las balizas detectadas via `@Published var detectedBeacons`.
7. Gestiona la carga inicial de balizas conocidas (`loadBeacons()`).

**¿Por qué CoreBluetooth?**  
CoreBluetooth es la API nativa de Apple para BLE en iOS. No hay alternativa para el escaneo de periféricos en iOS.

#### `Data/BLE/BleCircuitSignal.swift`
Struct que modela una señal BLE parseada del circuito:
```swift
struct BleCircuitSignal {
    let version: UInt8
    let zoneId: UInt16
    let mode: BeaconMode
    let flags: UInt8
    let sequence: UInt16
    let ttlSeconds: UInt8
    let temperature: UInt8
    let rssi: Int
}
```

#### `Data/Repositories/`

**`HybridCircuitStateRepository.swift`**  
Combina datos de **Firestore** y **BLE** para el estado del circuito:
- Escucha en tiempo real Firestore para actualizaciones del `circuit_state`.
- Cuando detecta señales BLE, las usa como override local si el TTL es válido.
- Prioriza BLE sobre Firestore porque refleja el estado físico más cercano al usuario.

**`CircuitStatusRepository.swift`**  
Lee el estado del circuito exclusivamente de la API REST y Firestore.

**`GroupLocationRepository.swift`**  
- Escucha en tiempo real las ubicaciones de los miembros del grupo en Firestore.
- Actualiza la posición propia del usuario cada X segundos.

**`NewsRepository.swift`**  
Obtiene las noticias para fans de Firestore. Soporte para paginación y actualización en tiempo real.

**`OrdersRepository.swift`**  
CRUD de pedidos en Firestore. Escucha en tiempo real el estado de los pedidos activos.

#### `Data/Services/`

**`APIService.swift`**  
Cliente HTTP de la API REST (`https://alpo.myqnapcloud.com:4010/api`). Usa `URLSession` con `async/await`:
- `get<T>(table:where:)` — Consulta genérica.
- `upsert(table:data:)` — Inserción/actualización genérica.
- `delete(table:where:)` — Eliminación genérica.
- Soporte para certificados SSL autofirmados (necesario para el servidor QNAP).
- Reintentos automáticos con backoff exponencial.

**`AuthService.swift`**  
Gestiona la autenticación Firebase:
- Login con email/contraseña.
- Login con Google via `GoogleSignIn`.
- Logout.
- Escucha de cambios de estado de autenticación (`Auth.auth().addStateDidChangeListener`).
- Publica `@Published var currentUser: User?`.

**`DatabaseClient.swift`**  
Wrapper sobre Firestore:
- Operaciones genéricas de lectura/escritura.
- Soporte para listeners en tiempo real (`addSnapshotListener`).
- Manejo de errores y reintentos.

**`TeamCatalogService.swift`** / **`TeamCatalogLoader.swift`** / **`TeamAssetManager.swift`**  
Gestión del catálogo de equipos de Fórmula 1. Carga los assets (logos, colores) de cada equipo. Permite al usuario seleccionar su equipo favorito.

**`TransportAPIClient.swift`**  
Cliente para la API de transporte público (OTP - OpenTripPlanner). Obtiene itinerarios de transporte público para llegar/salir del circuito.

**`TransportLocalFallback.swift`**  
Fallback con datos locales de transporte cuando la API no está disponible.

**`CrowdDensityService.swift`**  
Obtiene datos de densidad de gente por zona del circuito desde la API. Permite mostrar zonas saturadas en el mapa.

**`ParkingService.swift`**  
Gestiona la información de aparcamientos: disponibilidad, ubicaciones, rutas de acceso.

---

### Presentation (Presentación)

#### ViewModels

**`HomeViewModel.swift`**  
- Coordina los datos para la pantalla principal.
- Carga el estado del circuito, noticias destacadas, alertas activas.
- Gestiona los widgets del dashboard personalizable.

**`MapViewModel.swift`**  
- Gestiona el estado del mapa: ubicación del usuario, anotaciones, overlays.
- Coordina con `LocationManager` para la posición del usuario.
- Gestiona la selección de POIs y la navegación hacia ellos.
- Actualiza el heatmap de densidad de gente.

**`GuidanceViewModel.swift`** / **`NavigationViewModel.swift`**  
- Gestionan la navegación peatonal paso a paso.
- Coordinan con `RouteManager`, `OffRouteDetector` y `TTSManager`.
- Publican la instrucción actual, distancia restante y ETA.

**`GroupViewModel.swift`**  
- Crea y gestiona grupos de usuarios.
- Actualiza la posición propia en Firestore periódicamente.
- Escucha las posiciones de los demás miembros.

**`OrdersViewModel.swift`**  
- Gestiona el flujo de pedidos.
- Coordina con `CartManager` y `OrdersRepository`.
- Gestiona el estado de los pedidos activos.

**`FanZoneViewModel.swift`**  
- Carga noticias, quiz, encuestas para la Fan Zone.
- Gestiona la participación en encuestas y el envío de respuestas al quiz.

**`IncidentViewModel.swift`**  
- Gestiona el formulario de reporte de incidentes.
- Envía el reporte a la API con la ubicación del usuario.

#### Vistas Principales

**`ContentView.swift`**  
Vista raíz de la app. Contiene la lógica de autenticación:
- Si el usuario no está autenticado → muestra `LoginView`.
- Si está autenticado → muestra la barra de tabs principal.

**`HomeView.swift`**  
Dashboard principal con:
- Widget de estado del circuito (bandera actual, temperatura).
- Accesos rápidos a las funcionalidades más usadas.
- Noticias destacadas.
- Estado de los pedidos activos.
- Mapa miniatura con la posición del usuario.

**`CircuitMapView.swift`**  
Mapa completo del circuito usando MapKit:
- Overlay del trazado del circuito.
- Anotaciones de balizas, POIs, servicios.
- Heatmap de densidad de gente.
- Posición del usuario y los miembros del grupo.
- Botón de "centrar en mi posición".

**`NavigationScreen.swift`** / **`GuidanceView.swift`**  
Vista de navegación peatonal paso a paso:
- Flechas de dirección.
- Distancia al siguiente giro.
- ETA al destino.
- Mini mapa de contexto.

**`EvacuationView.swift`**  
Vista de evacuación de emergencia (se activa cuando `TrackMode == .evacuation`):
- Flecha grande hacia la salida más cercana.
- Mensaje de evacuación.
- Indicador de distancia a la salida.
- Color de fondo rojo pulsante.

**`FanZoneView.swift`** / **`FanNewsView.swift`**  
Fan Zone con noticias del evento, clasificaciones, redes sociales oficiales.

**`QuizView.swift`**  
Quiz interactivo de Fórmula 1 con preguntas y puntuaciones.

**`StaffModeView.swift`** / **`CircuitControlView.swift`**  
Vistas exclusivas para el personal del evento:
- Control del estado del circuito.
- Gestión de incidentes.
- Visualización de todas las balizas.

**`QRScannerView.swift`**  
Escáner de códigos QR usando Vision framework y AVCaptureSession. Se usa para:
- Entrar a un grupo.
- Posicionamiento preciso en el circuito.
- Validar tickets.

---

### CarPlay

#### `CarPlay/CarPlaySceneDelegate`
Implementación del delegado de la escena CarPlay. Se activa cuando el usuario conecta el iPhone a un coche compatible.

**Funcionalidades CarPlay:**
- Mapa del circuito adaptado a la pantalla del coche.
- Navegación peatonal con instrucciones turn-by-turn.
- Estado del circuito simplificado (bandera actual).
- Lista de POIs cercanos.
- Botón de emergencia para contactar con el staff.

**¿Por qué CarPlay?**  
CarPlay permite que los usuarios consulten información del circuito mientras conducen hacia o desde el evento sin usar el teléfono con las manos, mejorando la seguridad vial.

---

### Backend Auxiliar

#### `backend/otp/`
Servidor **OpenTripPlanner (OTP)** para el cálculo de rutas de transporte público. OTP es un motor de enrutamiento multimodal open-source que combina GTFS (datos de transporte público) con OSM (OpenStreetMap) para calcular itinerarios.

**¿Por qué OTP?**  
El circuito está en una zona con transporte público local (autobuses lanzadera, tren). OTP permite ofrecer itinerarios "puerta a puerta" desde el hotel o la ciudad al circuito, incluyendo horarios de transporte real.

#### `backend/transport-api/`
API REST local que expone los datos de OTP en un formato simplificado que consume el `TransportAPIClient` de la app.

---

## Funcionalidades Principales

### Estado del Circuito

La app muestra el estado del circuito en tiempo real en toda la interfaz:
- **Barra de estado** superior siempre visible con el color de la bandera actual.
- **Notificaciones locales** cuando el estado cambia (especialmente en evacuación).
- **TTS** que anuncia los cambios de estado en voz alta.

### Sistema de Grupos

1. El creador del grupo obtiene un código QR.
2. Los demás miembros escanean el QR para unirse.
3. Cada miembro actualiza su posición en Firestore cada 15 segundos.
4. El `GroupLocationRepository` escucha los cambios y actualiza el mapa.

### Gamificación

La app incluye elementos de gamificación para hacer la experiencia más inmersiva:
- **Coleccionables** — Tarjetas virtuales de pilotos que se "coleccionan" visitando zonas específicas del circuito.
- **Quiz** — Preguntas sobre F1 con puntuación.
- **Retos** — Retos del evento (visita X sectores, prueba Y servicio).
- **Logros** — Badges desbloqueables.

---

## Flujo de Autenticación

```
Inicio de App
    │
    ▼
GeoRacingApp.swift (FirebaseApp.configure)
    │
    ▼
ContentView
    │ Auth.auth().addStateDidChangeListener
    ├── Sin sesión activa → LoginView
    │       ├── Email/Contraseña → AuthService.signIn()
    │       └── Google Sign-In → GIDSignIn → AuthService.signInWithGoogle()
    │               └── onOpenURL → GIDSignIn.handle(url)
    └── Con sesión activa → TabView principal
            └── SplashScreen breve → HomeView
```

---

## Sistema BLE (CoreBluetooth)

### Permisos requeridos en Info.plist
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Necesitamos Bluetooth para detectar balizas del circuito y mostrarte información de tu zona.</string>
```

### Ciclo de vida del BeaconScanner

```
App inicia
    │
    ▼
BeaconScanner.shared.loadBeacons()
    │
    ▼
CBCentralManager inicializado
    │
    ├── Bluetooth disponible → startScanning()
    └── No disponible → estado "unavailable"
            │
            ▼
        centralManager.scanForPeripherals(
            withServices: nil,  // Escanea todo
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
            │
            ▼
        didDiscover peripheral
            │
            ├── Extraer ManufacturerData
            ├── Verificar CompanyID == 0x1234
            ├── Parsear payload 9 bytes
            ├── Verificar TTL válido
            ├── Verificar Sequence cambiado
            └── Publicar @Published detectedBeacons
                    │
                    └── HybridCircuitStateRepository actualiza estado
```

---

## Integración con CarPlay

### Entitlement requerido
La integración con CarPlay requiere un entitlement especial de Apple:
```
com.apple.developer.carplay-navigation = YES
```

Este entitlement solo se concede a través del portal de desarrolladores de Apple para apps de navegación.

### Escenas de CarPlay

iOS 14+ gestiona CarPlay como una **escena separada** (`UISceneConfiguration` con role `.carTemplateApplication`). El `AppDelegate` devuelve `CarPlaySceneDelegate` para las escenas de CarPlay:

```swift
func application(_ application: UIApplication,
                 configurationForConnecting connectingSceneSession: UISceneSession,
                 options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    if connectingSceneSession.role == .carTemplateApplication {
        let config = UISceneConfiguration(name: "CarPlay Configuration",
                                          sessionRole: .carTemplateApplication)
        config.delegateClass = CarPlaySceneDelegate.self
        return config
    }
    // Default iPhone scene...
}
```

### Templates de CarPlay

CarPlay usa un sistema de **templates** (no SwiftUI) para las pantallas del coche:
- `CPMapTemplate` — Mapa interactivo.
- `CPListTemplate` — Lista de POIs.
- `CPInformationTemplate` — Información del circuito.
- `CPAlertTemplate` — Alertas de emergencia.
