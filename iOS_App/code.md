# iOS_App — Todo el Código Fuente

Este archivo contiene todos los archivos de código fuente de la carpeta `iOS_App/` concatenados.

---

## `iOS_App/GeoRacing/CarPlay/CarPlayCoordinator.swift`

```swift
import CarPlay
import Combine

/// Coordinator that manages CarPlay template navigation and state
@MainActor
class CarPlayCoordinator {
    
    // MARK: - Properties
    
    private let interfaceController: CPInterfaceController
    private let templateFactory: CarPlayTemplateFactory
    private var cancellables = Set<AnyCancellable>()
    
    /// Current navigation state
    private var isNavigating = false
    
    // MARK: - Initialization
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        self.templateFactory = CarPlayTemplateFactory(coordinator: nil)
        self.templateFactory.coordinator = self
        
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Start CarPlay UI with root template
    func start() {
        let rootTemplate = templateFactory.createRootTemplate()
        
        interfaceController.setRootTemplate(rootTemplate, animated: true) { success, error in
            if let error = error {
                Logger.error("[CarPlay] Error setting root template: \(error)")
            } else {
                Logger.info("[CarPlay] Root template set successfully")
            }
        }
    }
    
    // MARK: - Navigation Actions
    
    /// Navigate to a destination
    func navigateTo(destination: CarPlayDestination) {
        Logger.debug("[CarPlay] Navigating to: \(destination.name)")
        
        // Create navigation template
        let navTemplate = templateFactory.createNavigationTemplate(for: destination)
        
        interfaceController.pushTemplate(navTemplate, animated: true) { success, error in
            if success {
                self.isNavigating = true
                // Start actual navigation via RouteManager
                self.startNavigation(to: destination)
            }
        }
    }
    
    /// Show parking list
    func showParkingList() {
        let parkingTemplate = templateFactory.createParkingTemplate()
        interfaceController.pushTemplate(parkingTemplate, animated: true, completion: nil)
    }
    
    /// Save current parking location
    func saveCurrentParking() {
        // Get current location from LocationManager
        guard let location = LocationManager.shared.location else {
            showAlert(title: "Error", message: LocalizationUtils.string("Could not get current location"))
            return
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(location.latitude, forKey: "savedParkingLat")
        UserDefaults.standard.set(location.longitude, forKey: "savedParkingLon")
        UserDefaults.standard.set(Date(), forKey: "savedParkingDate")
        
        showAlert(title: LocalizationUtils.string("Saved"), message: LocalizationUtils.string("Parking location saved"))
        Logger.info("[CarPlay] Parking saved at: \(location)")
    }
    
    /// Navigate to saved parking
    func navigateToSavedParking() {
        guard let lat = UserDefaults.standard.object(forKey: "savedParkingLat") as? Double,
              let lon = UserDefaults.standard.object(forKey: "savedParkingLon") as? Double else {
            showAlert(title: "No data", message: "No saved parking")
            return
        }
        
        let destination = CarPlayDestination(
            id: "saved_parking",
            name: LocalizationUtils.string("Go to My Car"),
            subtitle: LocalizationUtils.string("Saved location"),
            latitude: lat,
            longitude: lon,
            type: .parking
        )
        
        navigateTo(destination: destination)
    }
    
    /// End current navigation
    func endNavigation() {
        isNavigating = false
        interfaceController.popToRootTemplate(animated: true, completion: nil)
        
        // Stop RouteManager navigation
        // RouteManager.shared.stopNavigation() // Uncomment when method exists
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe location updates for navigation
        // This syncs with the existing LocationManager
    }
    
    private func startNavigation(to destination: CarPlayDestination) {
        // Integration point with existing RouteManager
        // RouteManager.shared.startNavigation(to: CLLocationCoordinate2D(...))
        Logger.debug("[CarPlay] Starting navigation to \(destination.name)")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = CPAlertTemplate(titleVariants: [title], actions: [
            CPAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                self?.interfaceController.dismissTemplate(animated: true, completion: nil)
            })
        ])
        
        interfaceController.presentTemplate(alert, animated: true, completion: nil)
    }
}

// MARK: - CarPlay Destination Model

struct CarPlayDestination: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let type: DestinationType
    
    enum DestinationType {
        case circuit
        case parking
        case poi
        case savedLocation
    }
}

```

---

## `iOS_App/GeoRacing/CarPlay/CarPlaySceneDelegate.swift`

```swift
import CarPlay
import UIKit

/// CarPlay Scene Delegate - Entry point for CarPlay UI
/// Manages the lifecycle and interface controller for CarPlay
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    // MARK: - Properties
    
    /// The interface controller provided by CarPlay
    private(set) var interfaceController: CPInterfaceController?
    
    /// Coordinator that manages navigation between templates
    private var coordinator: CarPlayCoordinator?
    
    /// Reference to the CarPlay window
    var carPlayWindow: CPWindow?
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                   didConnect interfaceController: CPInterfaceController) {
        Logger.info("[CarPlay] Connected")
        
        self.interfaceController = interfaceController
        self.carPlayWindow = templateApplicationScene.carWindow
        
        // Initialize coordinator with interface controller
        coordinator = CarPlayCoordinator(interfaceController: interfaceController)
        
        // Set up root template
        coordinator?.start()
        
        // Notify app that CarPlay is connected
        NotificationCenter.default.post(name: .carPlayDidConnect, object: nil)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                   didDisconnect interfaceController: CPInterfaceController) {
        Logger.info("[CarPlay] Disconnected")
        
        self.interfaceController = nil
        self.coordinator = nil
        self.carPlayWindow = nil
        
        // Notify app that CarPlay disconnected
        NotificationCenter.default.post(name: .carPlayDidDisconnect, object: nil)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                   didSelect navigationAlert: CPNavigationAlert) {
        // Handle navigation alert selection
        Logger.debug("[CarPlay] Navigation alert selected")
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                   didSelect maneuver: CPManeuver) {
        // Handle maneuver selection (for navigation apps)
        Logger.debug("[CarPlay] Maneuver selected")
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let carPlayDidConnect = Notification.Name("carPlayDidConnect")
    static let carPlayDidDisconnect = Notification.Name("carPlayDidDisconnect")
}

```

---

## `iOS_App/GeoRacing/CarPlay/Services/CarPlayStateSync.swift`

```swift
import Foundation
import Combine

/// Service that synchronizes state between iPhone and CarPlay
/// Ensures both interfaces show consistent data
class CarPlayStateSync: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CarPlayStateSync()
    
    // MARK: - Published State
    
    /// Is CarPlay currently connected?
    @Published private(set) var isCarPlayConnected = false
    
    /// Is navigation active on either device?
    @Published var isNavigating = false
    
    /// Current destination (if navigating)
    @Published var currentDestination: CarPlayDestination?
    
    /// Saved parking location
    @Published var savedParkingLocation: SavedParking?
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
        loadSavedParking()
    }
    
    // MARK: - Public Methods
    
    /// Save parking location (callable from iPhone or CarPlay)
    func saveParkingLocation(latitude: Double, longitude: Double) {
        let parking = SavedParking(
            latitude: latitude,
            longitude: longitude,
            savedAt: Date()
        )
        
        savedParkingLocation = parking
        
        // Persist
        UserDefaults.standard.set(latitude, forKey: "savedParkingLat")
        UserDefaults.standard.set(longitude, forKey: "savedParkingLon")
        UserDefaults.standard.set(Date(), forKey: "savedParkingDate")
        
        // Notify both interfaces
        NotificationCenter.default.post(name: .parkingLocationSaved, object: parking)
    }
    
    /// Clear saved parking
    func clearSavedParking() {
        savedParkingLocation = nil
        UserDefaults.standard.removeObject(forKey: "savedParkingLat")
        UserDefaults.standard.removeObject(forKey: "savedParkingLon")
        UserDefaults.standard.removeObject(forKey: "savedParkingDate")
    }
    
    /// Start navigation to destination (syncs to both interfaces)
    func startNavigation(to destination: CarPlayDestination) {
        currentDestination = destination
        isNavigating = true
        
        NotificationCenter.default.post(name: .navigationStarted, object: destination)
    }
    
    /// End navigation (syncs to both interfaces)
    func endNavigation() {
        currentDestination = nil
        isNavigating = false
        
        NotificationCenter.default.post(name: .navigationEnded, object: nil)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        // Listen for CarPlay connection state
        NotificationCenter.default.publisher(for: .carPlayDidConnect)
            .sink { [weak self] _ in
                self?.isCarPlayConnected = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .carPlayDidDisconnect)
            .sink { [weak self] _ in
                self?.isCarPlayConnected = false
            }
            .store(in: &cancellables)
    }
    
    private func loadSavedParking() {
        guard let lat = UserDefaults.standard.object(forKey: "savedParkingLat") as? Double,
              let lon = UserDefaults.standard.object(forKey: "savedParkingLon") as? Double,
              let date = UserDefaults.standard.object(forKey: "savedParkingDate") as? Date else {
            return
        }
        
        savedParkingLocation = SavedParking(
            latitude: lat,
            longitude: lon,
            savedAt: date
        )
    }
}

// MARK: - Models

struct SavedParking: Codable {
    let latitude: Double
    let longitude: Double
    let savedAt: Date
    
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.localizedString(for: savedAt, relativeTo: Date())
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let parkingLocationSaved = Notification.Name("parkingLocationSaved")
    static let navigationStarted = Notification.Name("navigationStarted")
    static let navigationEnded = Notification.Name("navigationEnded")
}

```

---

## `iOS_App/GeoRacing/CarPlay/Templates/CarPlayTemplateFactory.swift`

```swift
import CarPlay
import CoreLocation

/// Factory for creating CarPlay templates
/// Centralizes template creation logic and keeps UI separate from business logic
@MainActor
class CarPlayTemplateFactory {
    
    // MARK: - Properties
    
    weak var coordinator: CarPlayCoordinator?
    
    // MARK: - Initialization
    
    init(coordinator: CarPlayCoordinator?) {
        self.coordinator = coordinator
    }
    
    // MARK: - Root Template
    
    /// Creates the main TabBar template (root of CarPlay UI)
    func createRootTemplate() -> CPTabBarTemplate {
        let tabs = [
            createNavigationTab(),
            createParkingTab(),
            createEventTab(),
            createSettingsTab()
        ]
        
        let tabBar = CPTabBarTemplate(templates: tabs)
        return tabBar
    }
    
    // MARK: - Tab Templates
    
    /// Navigation tab - destinations list
    private func createNavigationTab() -> CPListTemplate {
        let destinations = getDestinations()
        
        let items = destinations.map { destination -> CPListItem in
            let item = CPListItem(
                text: destination.name,
                detailText: destination.subtitle,
                image: UIImage(systemName: destination.type == .circuit ? "flag.checkered" : "mappin.circle")
            )
            
            item.handler = { [weak self] _, completion in
                self?.coordinator?.navigateTo(destination: destination)
                completion()
            }
            
            return item
        }
        
        let section = CPListSection(items: items, header: LocalizationUtils.string("Destinations"), sectionIndexTitle: nil)
        let template = CPListTemplate(title: LocalizationUtils.string("Navigate"), sections: [section])
        template.tabSystemItem = .search
        template.tabImage = UIImage(systemName: "location.fill")
        
        return template
    }
    
    /// Parking tab - parking locations and save feature
    private func createParkingTab() -> CPListTemplate {
        var items: [CPListItem] = []
        
        // Save current location button
        let saveItem = CPListItem(
            text: LocalizationUtils.string("Save My Location"),
            detailText: LocalizationUtils.string("Remember where you parked"),
            image: UIImage(systemName: "pin.fill")
        )
        saveItem.handler = { [weak self] _, completion in
            self?.coordinator?.saveCurrentParking()
            completion()
        }
        items.append(saveItem)
        
        // Navigate to saved parking
        if hasSavedParking() {
            let navigateItem = CPListItem(
                text: LocalizationUtils.string("Go to My Car"),
                detailText: getSavedParkingDescription(),
                image: UIImage(systemName: "car.fill")
            )
            navigateItem.handler = { [weak self] _, completion in
                self?.coordinator?.navigateToSavedParking()
                completion()
            }
            items.append(navigateItem)
        }
        
        // Separator
        let separatorSection = CPListSection(items: items, header: LocalizationUtils.string("Your Parking"), sectionIndexTitle: nil)
        
        // Available parkings
        let parkingItems = getParkingLocations().map { parking -> CPListItem in
            let item = CPListItem(
                text: parking.name,
                detailText: parking.subtitle,
                image: UIImage(systemName: "p.circle.fill")
            )
            item.handler = { [weak self] _, completion in
                self?.coordinator?.navigateTo(destination: parking)
                completion()
            }
            return item
        }
        
        let parkingSection = CPListSection(items: parkingItems, header: LocalizationUtils.string("Available Parkings"), sectionIndexTitle: nil)
        
        let template = CPListTemplate(title: "Parking", sections: [separatorSection, parkingSection])
        template.tabImage = UIImage(systemName: "p.circle.fill")
        
        return template
    }
    
    /// Event tab - race status (read-only)
    private func createEventTab() -> CPInformationTemplate {
        let eventInfo = getEventInfo()
        
        let items = [
            CPInformationItem(title: LocalizationUtils.string("Event"), detail: eventInfo.name),
            CPInformationItem(title: LocalizationUtils.string("Status"), detail: eventInfo.status),
            CPInformationItem(title: LocalizationUtils.string("Time"), detail: eventInfo.time),
            CPInformationItem(title: LocalizationUtils.string("Gates"), detail: eventInfo.gatesOpen ? LocalizationUtils.string("Open") : LocalizationUtils.string("Closed"))
        ]
        
        let template = CPInformationTemplate(
            title: LocalizationUtils.string("Event"),
            layout: .twoColumn,
            items: items,
            actions: []
        )
        template.tabImage = UIImage(systemName: "flag.checkered")
        
        return template
    }
    
    /// Settings tab - offline mode toggle
    private func createSettingsTab() -> CPListTemplate {
        let offlineItem = CPListItem(
            text: LocalizationUtils.string("Offline Mode"),
            detailText: UserDefaults.standard.bool(forKey: "offlineMode") ? LocalizationUtils.string("Enabled") : LocalizationUtils.string("Disabled"),
            image: UIImage(systemName: "wifi.slash")
        )
        offlineItem.handler = { _, completion in
            let current = UserDefaults.standard.bool(forKey: "offlineMode")
            UserDefaults.standard.set(!current, forKey: "offlineMode")
            // Would need to refresh template to update text
            completion()
        }
        
        let versionItem = CPListItem(
            text: LocalizationUtils.string("Version"),
            detailText: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            image: UIImage(systemName: "info.circle")
        )
        versionItem.handler = { _, completion in completion() }
        
        let section = CPListSection(items: [offlineItem, versionItem])
        let template = CPListTemplate(title: LocalizationUtils.string("Settings"), sections: [section])
        template.tabImage = UIImage(systemName: "gearshape.fill")
        
        return template
    }
    
    // MARK: - Navigation Template
    
    /// Creates a map template for active navigation
    func createNavigationTemplate(for destination: CarPlayDestination) -> CPMapTemplate {
        let template = CPMapTemplate()
        template.hidesButtonsWithNavigationBar = false
        
        // Add trip info
        let tripInfo = createTripEstimates(for: destination)
        template.updateEstimates(tripInfo, for: CPTrip(origin: MKMapItem.forCurrentLocation(), destination: MKMapItem.fromCoordinate(CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude)), routeChoices: []))

        
        // Add navigation bar buttons
        let endButton = CPBarButton(title: LocalizationUtils.string("Finish")) { [weak self] _ in
            self?.coordinator?.endNavigation()
        }
        template.leadingNavigationBarButtons = [endButton]
        
        return template
    }
    
    /// Creates parking list template
    func createParkingTemplate() -> CPListTemplate {
        let items = getParkingLocations().map { parking -> CPListItem in
            let item = CPListItem(
                text: parking.name,
                detailText: parking.subtitle,
                image: UIImage(systemName: "p.circle.fill")
            )
            item.handler = { [weak self] _, completion in
                self?.coordinator?.navigateTo(destination: parking)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        return CPListTemplate(title: "Parkings", sections: [section])
    }
    
    // MARK: - Data Providers (Mock - Replace with real services)
    
    private func getDestinations() -> [CarPlayDestination] {
        return [
            CarPlayDestination(
                id: "circuit_main",
                name: "Circuit de Barcelona-Catalunya",
                subtitle: LocalizationUtils.string("Main Entry"),
                latitude: 41.5700,
                longitude: 2.2611,
                type: .circuit
            ),
            CarPlayDestination(
                id: "circuit_paddock",
                name: LocalizationUtils.string("Paddock Access"),
                subtitle: LocalizationUtils.string("Pass only"),
                latitude: 41.5690,
                longitude: 2.2600,
                type: .circuit
            ),
            CarPlayDestination(
                id: "grandstand_main",
                name: "Tribuna Principal",
                subtitle: LocalizationUtils.string("Main Straight"),
                latitude: 41.5705,
                longitude: 2.2620,
                type: .poi
            )
        ]
    }
    
    private func getParkingLocations() -> [CarPlayDestination] {
        return [
            CarPlayDestination(
                id: "parking_a",
                name: "Parking A",
                subtitle: "Cercano a entrada - 10€",
                latitude: 41.5720,
                longitude: 2.2650,
                type: .parking
            ),
            CarPlayDestination(
                id: "parking_b",
                name: "Parking B",
                subtitle: "General - 5€",
                latitude: 41.5680,
                longitude: 2.2580,
                type: .parking
            ),
            CarPlayDestination(
                id: "parking_vip",
                name: "Parking VIP",
                subtitle: LocalizationUtils.string("Credentials only"),
                latitude: 41.5695,
                longitude: 2.2590,
                type: .parking
            )
        ]
    }
    
    private func getEventInfo() -> (name: String, status: String, time: String, gatesOpen: Bool) {
        // TODO: Connect to real EventService
        return (
            name: "GP España F1 2025",
            status: "En curso - Vuelta 23/66",
            time: "14:00 - 16:00",
            gatesOpen: true
        )
    }
    
    private func hasSavedParking() -> Bool {
        return UserDefaults.standard.object(forKey: "savedParkingLat") != nil
    }
    
    private func getSavedParkingDescription() -> String {
        guard let date = UserDefaults.standard.object(forKey: "savedParkingDate") as? Date else {
            return LocalizationUtils.string("Saved location")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        return "Guardado \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
    
    private func createTripEstimates(for destination: CarPlayDestination) -> CPTravelEstimates {
        // Mock estimates - would come from RouteManager
        return CPTravelEstimates(
            distanceRemaining: Measurement(value: 5.2, unit: .kilometers),
            timeRemaining: 600 // 10 minutes in seconds
        )
    }
}

```

---

## `iOS_App/GeoRacing/ContentView.swift`

```swift
//
//  ContentView.swift
//  GeoRacing
//
//  Created by Daniel Colet on 15/12/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab: TabIdentifier = .home
    @StateObject private var circuitState = HybridCircuitStateRepository()
    
    // Side Menu States
    @State private var isShowingSideMenu = false
    @State private var showSocial = false
    @State private var showReport = false
    @State private var showControl = false
    @State private var showOverview = false
    @State private var selectedFeature: Feature? = nil
    @State private var showParking = false // Parking Module State
    
    // Watch for theme changes via Preferences or Environment? 
    // Since UserPreferences is a singleton, we might need a small observable wrapper or manually check on appear.
    // For simplicity, let's use AppStorage for themeID if possible, or just read it.
    @AppStorage("theme") private var themeRaw: String = "system"
    @AppStorage("language") private var languageCode: String = "es" // Watch language to trigger redraw
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    @ObservedObject private var authService = AuthService.shared
    
    var body: some View {
        if authService.isAuthenticated {
            ZStack {
                TabView(selection: $selectedTab) {
                    
                    // Tab 0: Home
                    HomeView(selectedTab: $selectedTab, showMenu: $isShowingSideMenu, showParkingSheet: $showParking)
                        .tabItem {
                            Label(LocalizationUtils.string("Home"), systemImage: "house.fill")
                        }
                        .tag(TabIdentifier.home)
                    
                    // Tab 1: Map
                    CircuitMapView()
                        .tabItem {
                            Label(LocalizationUtils.string("Map"), systemImage: "map")
                        }
                        .tag(TabIdentifier.map)
                    
                    // Tab 2: Alerts
                    AlertsView()
                        .tabItem {
                            Label(LocalizationUtils.string("Alerts"), systemImage: "bell")
                        }
                        .tag(TabIdentifier.alerts)
                    
                    // Tab 3: Shop
                    OrdersView()
                        .tabItem {
                            Label(LocalizationUtils.string("Shop"), systemImage: "cart")
                        }
                        .tag(TabIdentifier.shop)
                    
                    // Tab 4: Settings / Seat
                    SettingsView()
                        .tabItem {
                            Label(LocalizationUtils.string("Settings"), systemImage: "gear")
                        }
                        .tag(TabIdentifier.seat)
                }
                
                // Side Menu Overlay
                SideMenuView(
                    isShowing: $isShowingSideMenu,
                    selectedTab: $selectedTab,
                    onOverview: { showOverview = true },
                    onSelectFeature: { feature in
                        self.selectedFeature = feature
                    },
                    onSocial: { showSocial = true },
                    onReport: { showReport = true },
                    onCircuitControl: { showControl = true }
                )
            }
            // Force redraw when language changes (id hack)
            .id(languageCode)
            .preferredColorScheme(scheme(for: themeRaw))
            .environmentObject(circuitState)
            .onAppear { circuitState.start() }
            // Global Evacuation Overlay
            .fullScreenCover(
                isPresented: Binding<Bool>(
                    get: { circuitState.mode == .evacuation },
                    set: { _ in }
                )
            ) {
                EvacuationView()
            }
            // Onboarding Flow
            .fullScreenCover(isPresented: Binding(
                get: { !hasSeenOnboarding },
                set: { _ in }
            )) {
                OnboardingView(isPresented: Binding(
                    get: { true },
                    set: { if !$0 { hasSeenOnboarding = true } }
                ))
            }
            // Side Menu Sheets
            .sheet(isPresented: $showSocial) { SocialView() }
            .sheet(isPresented: $showReport) { IncidentReportView() }
            .sheet(isPresented: $showControl) { NavigationView { CircuitControlView() } }
            .sheet(isPresented: $showParking) { ParkingContainerView() } // Parking Module
            // Feature Navigation
            .sheet(isPresented: $showOverview) { FeaturesOverviewView() }
            .sheet(item: $selectedFeature) { feature in
                // We wrap real views in NavigationView if they don't have one, 
                // but FeatureViewFactory might return view with or without it. 
                // Placeholder has titleDisplayMode inline so it expects nav.
                NavigationView {
                    FeatureViewFactory.view(for: feature)
                        .toolbar {
                             ToolbarItem(placement: .navigationBarTrailing) {
                                 Button(LocalizationUtils.string("Close")) { selectedFeature = nil }
                             }
                        }
                }
            }
        } else {
            LoginView()
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView(isPresented: Binding(
                        get: { true },
                        set: { if !$0 { hasSeenOnboarding = true } }
                    ))
                }
        }
    }
    
    func scheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

#Preview {
    ContentView()
}

```

---

## `iOS_App/GeoRacing/Core/Constants/AppConstants.swift`

```swift
import Foundation

struct AppConstants {
    static let osrmBaseUrl = "https://router.project-osrm.org"
    static let apiBaseUrl = "https://alpo.myqnapcloud.com:4010/api"
    
    static let offRouteDistanceThreshold: Double = 50.0 // meters
    static let offRouteTimeThreshold: Double = 10.0 // seconds
    static let locationUpdateInterval: Double = 1.0 // seconds
}

```

---

## `iOS_App/GeoRacing/Core/Enums/TabIdentifier.swift`

```swift
import Foundation

enum TabIdentifier: Hashable {
    case home
    case map
    case shop
    case report
    case seat
    case alerts
}

```

---

## `iOS_App/GeoRacing/Core/Extensions/MKMapItem+Coordinate.swift`

```swift
import MapKit
import CoreLocation

extension MKMapItem {
    /// Creates an MKMapItem from a coordinate.
    ///
    /// Centralizes MKPlacemark usage for easy migration
    /// when targeting iOS 26+ (`MKMapItem(location:address:)`).
    static func fromCoordinate(_ coordinate: CLLocationCoordinate2D) -> MKMapItem {
        MKMapItem(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil
        )
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/LocalNotificationManager.swift`

```swift
import Foundation
import UserNotifications

class LocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = LocalNotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.error("[Notifications] Permission error: \(error.localizedDescription)")
            } else {
                Logger.info("[Notifications] Permission granted: \(granted)")
            }
        }
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Show immediately
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("[Notifications] Failed to add request: \(error.localizedDescription)")
            }
        }
    }
    
    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/LocalizationUtils.swift`

```swift
import Foundation
import Combine

@MainActor
class LocalizationUtils {
    
    // Simple localization dictionary for MVP
    // Key: [LanguageCode: String]
    private static let translations: [String: [String: String]] = [
        "Home": ["en": "Home", "es": "Inicio", "ca": "Inici"],
        "Map": ["en": "Map", "es": "Mapa", "ca": "Mapa"],
        "Shop": ["en": "Shop", "es": "Tienda", "ca": "Botiga"],
        "Report": ["en": "Report", "es": "Reportar", "ca": "Reportar"],
        "Settings": ["en": "Settings", "es": "Ajustes", "ca": "Configuració"],
        "Alerts": ["en": "Alerts", "es": "Alertas", "ca": "Alertes"],
        "Seat": ["en": "Seat", "es": "Asiento", "ca": "Seient"],
        
        // Home
        "Good Morning": ["en": "Good Morning", "es": "Buenos días", "ca": "Bon dia"],
        "Good Afternoon": ["en": "Good Afternoon", "es": "Buenas tardes", "ca": "Bona tarda"],
        "Good Evening": ["en": "Good Evening", "es": "Buenas noches", "ca": "Bona nit"],
        
        "Food": ["en": "Food", "es": "Comida", "ca": "Menjar"],
        "WC": ["en": "WC", "es": "Baños", "ca": "Banys"],
        "Parking": ["en": "Parking", "es": "Parking", "ca": "Pàrquing"],
        "Schedule": ["en": "Schedule", "es": "Horario", "ca": "Horari"],
        "Social": ["en": "Social", "es": "Social", "ca": "Social"],
        "Incidents": ["en": "Incidents", "es": "Incidencias", "ca": "Incidències"],
        
        // Settings
        "General": ["en": "General", "es": "General", "ca": "General"],
        "Language": ["en": "Language", "es": "Idioma", "ca": "Idioma"],
        "Appearance": ["en": "Appearance", "es": "Apariencia", "ca": "Aparença"],
        "My Seat Location": ["en": "My Seat Location", "es": "Mi Asiento", "ca": "El meu seient"],
        "Grandstand": ["en": "Grandstand", "es": "Tribuna", "ca": "Tribuna"],
        "Zone": ["en": "Zone", "es": "Zona", "ca": "Zona"],
        "Row": ["en": "Row", "es": "Fila", "ca": "Fila"],
        "Seat Number": ["en": "Seat Number", "es": "Asiento", "ca": "Seient"],
        "Save Seat Config": ["en": "Save Seat Config", "es": "Guardar Asiento", "ca": "Desar"],
        
        // Orders
        "Fan Shop": ["en": "Fan Shop", "es": "Tienda", "ca": "Botiga"],
        "Add": ["en": "Add", "es": "Añadir", "ca": "Afegir"],
        "Cart Total: $": ["en": "Cart Total: $", "es": "Total: $", "ca": "Total: $"],
        "Checkout": ["en": "Checkout", "es": "Comprar", "ca": "Comprar"],
        
        // Report Incident
        "Report Incident": ["en": "Report Incident", "es": "Reportar Incidencia", "ca": "Reportar Incidència"],
        "Category": ["en": "Category", "es": "Categoría", "ca": "Categoria"],
        "Description": ["en": "Description", "es": "Descripción", "ca": "Descripció"],
        "Select": ["en": "Select", "es": "Seleccionar", "ca": "Seleccionar"],
        "Submit Report": ["en": "Submit Report", "es": "Enviar Reporte", "ca": "Enviar"],
        "Report submitted successfully.": ["en": "Report submitted successfully.", "es": "Reporte enviado con éxito.", "ca": "Report enviat."],
        "Success": ["en": "Success", "es": "Éxito", "ca": "Èxit"],
        
        // Alerts
        "Alerts Title": ["en": "Alerts", "es": "Alertas", "ca": "Alertes"],
        
        // Dynamic & Badges
        "LIVE EVENT": ["en": "LIVE EVENT", "es": "EN VIVO", "ca": "EN DIRECTE"],
        "NEWS": ["en": "NEWS", "es": "NOTICIAS", "ca": "NOTÍCIES"],
        
        // Track Status
        "TRACK CLEAR": ["en": "TRACK CLEAR", "es": "PISTA LIBRE", "ca": "PISTA LLIURE"],
        "YELLOW FLAG": ["en": "YELLOW FLAG", "es": "BANDERA AMARILLA", "ca": "BANDERA GROGA"],
        "RED FLAG": ["en": "RED FLAG", "es": "BANDERA ROJA", "ca": "BANDERA VERMELLA"],
        "SAFETY CAR": ["en": "SAFETY CAR", "es": "SAFETY CAR", "ca": "COTXE DE SEGURETAT"],
        "VIRTUAL SC": ["en": "VIRTUAL SC", "es": "VIRTUAL SC", "ca": "VIRTUAL SC"],
        
        "Track is Green. Racing resumes.": ["en": "Track is Green. Racing resumes.", "es": "Pista libre. Carrera reanudada.", "ca": "Pista lliure. Cursa reanudada."],
        "Hazard reported. Slow down.": ["en": "Hazard reported. Slow down.", "es": "Peligro en pista. Reduzca velocidad.", "ca": "Perill en pista. Reduïu velocitat."],
        "Session Suspended. Return to pits.": ["en": "Session Suspended. Return to pits.", "es": "Sesión suspendida. Volver a boxes.", "ca": "Sessió suspesa. Tornar a boxes."],
        "Safety Car deployed.": ["en": "Safety Car deployed.", "es": "Safety Car desplegado.", "ca": "Cotxe de seguretat desplegat."],
        
        // Common UI Actions
        "Close": ["en": "Close", "es": "Cerrar", "ca": "Tancar"],
        "Cancel": ["en": "Cancel", "es": "Cancelar", "ca": "Cancel·lar"],
        "Save": ["en": "Save", "es": "Guardar", "ca": "Desar"],
        "Loading...": ["en": "Loading...", "es": "Cargando...", "ca": "Carregant..."],
        "Search...": ["en": "Search...", "es": "Buscar...", "ca": "Cercar..."],
        "All": ["en": "All", "es": "Todo", "ca": "Tot"],
        "Sign Out": ["en": "Sign Out", "es": "Cerrar sesión", "ca": "Tancar sessió"],
        "Sign Out?": ["en": "Sign Out?", "es": "¿Cerrar sesión?", "ca": "Tancar sessió?"],
        "Share": ["en": "Share", "es": "Compartir", "ca": "Compartir"],
        "Exit": ["en": "Exit", "es": "Salir", "ca": "Sortir"],
        "Loading products...": ["en": "Loading products...", "es": "Cargando productos...", "ca": "Carregant productes..."],
        "No results found": ["en": "No results found", "es": "No se encontraron resultados", "ca": "No s'han trobat resultats"],
        "Create New Group": ["en": "Create New Group", "es": "Crear Nuevo Grupo", "ca": "Crear Nou Grup"],
        "Leave Group": ["en": "Leave Group", "es": "Salir del Grupo", "ca": "Sortir del Grup"],
        "Order processed successfully": ["en": "Your order has been processed. Thank you!", "es": "Tu pedido ha sido procesado correctamente. ¡Gracias!", "ca": "La teva comanda s'ha processat correctament. Gràcies!"],
        "Customize Home": ["en": "Customize Home", "es": "Personalizar Inicio", "ca": "Personalitzar Inici"],
        "Save Seat": ["en": "Save Seat", "es": "Guardar Localidad", "ca": "Desar Localitat"],
        "Enable Notifications": ["en": "Enable Notifications", "es": "Habilitar Notificaciones", "ca": "Activar Notificacions"],
        "Open Settings": ["en": "Open Settings", "es": "Abrir Ajustes", "ca": "Obrir Configuració"],
        "Loading orders...": ["en": "Loading orders...", "es": "Cargando pedidos...", "ca": "Carregant comandes..."],
        "Add Widget": ["en": "Add Widget", "es": "Añadir Widget", "ca": "Afegir Widget"],
        "My Seat": ["en": "My Seat", "es": "Mi Localidad", "ca": "La meva Localitat"],
        "Seat Setup": ["en": "Seat Setup", "es": "Configuración de asiento", "ca": "Configuració de seient"],
        "Fan Settings": ["en": "Fan Settings", "es": "Configuración Fan", "ca": "Configuració Fan"],
        
        // Search function (used as placeholder)
        "Search function...": ["en": "Search function...", "es": "Buscar función...", "ca": "Cercar funció..."],
        
        // Error messages 
        "Description cannot be empty.": ["en": "Description cannot be empty.", "es": "La descripción no puede estar vacía.", "ca": "La descripció no pot estar buida."],
        "You must be logged in to report.": ["en": "You must be logged in to report.", "es": "Debes iniciar sesión para reportar.", "ca": "Has d'iniciar sessió per reportar."],
        "Could not get current location": ["en": "Could not get current location", "es": "No se pudo obtener la ubicación actual", "ca": "No s'ha pogut obtenir la ubicació actual"],
        "No route found": ["en": "No route found", "es": "No se encontró una ruta disponible", "ca": "No s'ha trobat cap ruta disponible"],
        "No routes found.": ["en": "No routes found.", "es": "No se encontraron rutas.", "ca": "No s'han trobat rutes."],
        
        // Staff Mode
        "Staff Mode": ["en": "Staff Mode", "es": "Modo Staff", "ca": "Mode Staff"],
        "Enter access PIN": ["en": "Enter access PIN", "es": "Introduce el PIN de acceso", "ca": "Introdueix el PIN d'accés"],
        "Control Panel": ["en": "Control Panel", "es": "Panel de Control", "ca": "Panell de Control"],
        "Section": ["en": "Section", "es": "Sección", "ca": "Secció"],
        "Status": ["en": "Status", "es": "Estado", "ca": "Estat"],
        "Send Alert": ["en": "Send Alert", "es": "Enviar Alerta", "ca": "Enviar Alerta"],
        "General Alert": ["en": "General Alert", "es": "Alerta General", "ca": "Alerta General"],
        "Send message to all users": ["en": "Send message to all users", "es": "Enviar mensaje a todos los usuarios", "ca": "Enviar missatge a tots els usuaris"],
        "Emergency": ["en": "Emergency", "es": "Emergencia", "ca": "Emergència"],
        "Activate emergency protocol": ["en": "Activate emergency protocol", "es": "Activar protocolo de emergencia", "ca": "Activar protocol d'emergència"],
        "Announcement": ["en": "Announcement", "es": "Anuncio", "ca": "Anunci"],
        "Send general information": ["en": "Send general information", "es": "Enviar información general", "ca": "Enviar informació general"],
        "Beacon Control": ["en": "Beacon Control", "es": "Control de Beacons", "ca": "Control de Beacons"],
        "Circuit Status": ["en": "Circuit Status", "es": "Estado del Circuito", "ca": "Estat del Circuit"],
        "Current Status": ["en": "Current Status", "es": "Estado Actual", "ca": "Estat Actual"],
        "GREEN FLAG": ["en": "GREEN FLAG", "es": "BANDERA VERDE", "ca": "BANDERA VERDA"],
        "Active Users": ["en": "Active Users", "es": "Usuarios Activos", "ca": "Usuaris Actius"],
        "Pending Alerts": ["en": "Pending Alerts", "es": "Alertas Pendientes", "ca": "Alertes Pendents"],
        "Active Beacons": ["en": "Active Beacons", "es": "Beacons Activos", "ca": "Beacons Actius"],
        
        // QR Scanner
        "Scan QR": ["en": "Scan QR", "es": "Escanear QR", "ca": "Escanejar QR"],
        "Point at QR code": ["en": "Point at QR code", "es": "Apunta al código QR", "ca": "Apunta al codi QR"],
        "Camera access needed": ["en": "Camera access needed", "es": "Se necesita acceso a la cámara", "ca": "Cal accés a la càmera"],
        "Could not access camera": ["en": "Could not access camera", "es": "No se pudo acceder a la cámara", "ca": "No s'ha pogut accedir a la càmera"],
        "Could not activate flash": ["en": "Could not activate flash", "es": "No se pudo activar el flash", "ca": "No s'ha pogut activar el flaix"],
        
        // Place names (Staff beacons)
        "Main Entrance": ["en": "Main Entrance", "es": "Entrada Principal", "ca": "Entrada Principal"],
        "Grandstand A": ["en": "Grandstand A", "es": "Tribuna A", "ca": "Tribuna A"],
        "Grandstand B": ["en": "Grandstand B", "es": "Tribuna B", "ca": "Tribuna B"],
        
        // SideMenuView
        "Quick Access": ["en": "Quick Access", "es": "Acceso Rápido", "ca": "Accés Ràpid"],
        "My Orders": ["en": "My Orders", "es": "Mis Pedidos", "ca": "Les meves Comandes"],
        "Purchase History": ["en": "Purchase History", "es": "Historial de compras", "ca": "Historial de compres"],
        "POI List": ["en": "POI List", "es": "Lista de POIs", "ca": "Llista de POIs"],
        "Points of Interest": ["en": "Points of Interest", "es": "Puntos de interés", "ca": "Punts d'interès"],
        "Project Progress": ["en": "Project Progress", "es": "Progreso del proyecto", "ca": "Progrés del projecte"],
        "GeoRacing Features": ["en": "GeoRacing Features", "es": "Funciones GeoRacing", "ca": "Funcions GeoRacing"],
        "Overview": ["en": "Overview", "es": "Vista General", "ca": "Vista General"],
        
        // GroupView
        "Connect with your group": ["en": "Connect with your group", "es": "Conéctate con tu grupo", "ca": "Connecta't amb el teu grup"],
        "Create a group to share location in real time at the circuit.": ["en": "Create a group to share location in real time at the circuit.", "es": "Crea un grupo para compartir ubicación en tiempo real en el circuito.", "ca": "Crea un grup per compartir ubicació en temps real al circuit."],
        "Group Code": ["en": "Group Code", "es": "Código de Grupo", "ca": "Codi de Grup"],
        "Join": ["en": "Join", "es": "Unirse", "ca": "Unir-se"],
        "Or": ["en": "Or", "es": "O", "ca": "O"],
        "View on Map": ["en": "View on Map", "es": "Ver en Mapa", "ca": "Veure al Mapa"],
        
        // SeatSetupView
        "Seat saved": ["en": "Seat saved", "es": "Localidad guardada", "ca": "Localitat desada"],
        "Your seat has been saved. You can use it to navigate directly to your seat.": ["en": "Your seat has been saved. You can use it to navigate directly to your seat.", "es": "Tu localidad ha sido guardada. Podrás usarla para navegar directamente a tu asiento.", "ca": "La teva localitat s'ha desat. Podràs usar-la per navegar directament al teu seient."],
        "Configure your seat": ["en": "Configure your seat", "es": "Configura tu asiento", "ca": "Configura el teu seient"],
        "Save your seat to navigate directly to it from anywhere in the circuit.": ["en": "Save your seat to navigate directly to it from anywhere in the circuit.", "es": "Guarda tu localidad para poder navegar directamente a ella desde cualquier punto del circuito.", "ca": "Desa la teva localitat per poder navegar directament des de qualsevol punt del circuit."],
        "e.g. Main Grandstand": ["en": "e.g. Main Grandstand", "es": "Ej: Tribuna Principal", "ca": "Ex: Tribuna Principal"],
        "e.g. Zone A": ["en": "e.g. Zone A", "es": "Ej: Zona A", "ca": "Ex: Zona A"],
        "e.g. Row 12": ["en": "e.g. Row 12", "es": "Ej: Fila 12", "ca": "Ex: Fila 12"],
        "e.g. 24": ["en": "e.g. 24", "es": "Ej: 24", "ca": "Ex: 24"],
        
        // ParkingHomeView
        "Parking Management": ["en": "Parking Management", "es": "Gestión de Parking", "ca": "Gestió de Pàrquing"],
        "View Route": ["en": "View Route", "es": "Ver Ruta", "ca": "Veure Ruta"],
        "Release / Change Assignment": ["en": "Release / Change Assignment", "es": "Liberar / Cambiar Asignación", "ca": "Alliberar / Canviar Assignació"],
        "Loading assignment...": ["en": "Loading assignment...", "es": "Cargando asignación...", "ca": "Carregant assignació..."],
        "No parking assigned": ["en": "No parking assigned", "es": "No tienes parking asignado", "ca": "No tens pàrquing assignat"],
        "Assign my spot": ["en": "Assign my spot", "es": "Asignar mi plaza", "ca": "Assignar la meva plaça"],
        
        // ParkingWizardViews
        "Step 1 of 3": ["en": "Step 1 of 3", "es": "Paso 1 de 3", "ca": "Pas 1 de 3"],
        "Scan your ticket": ["en": "Scan your ticket", "es": "Escanea tu entrada", "ca": "Escaneja la teva entrada"],
        "Simulating camera...": ["en": "Simulating camera...", "es": "Simulando cámara...", "ca": "Simulant càmera..."],
        "Simulate Scan": ["en": "Simulate Scan", "es": "Simular Escaneo", "ca": "Simular Escaneig"],
        "Ticket Detected": ["en": "Ticket Detected", "es": "Ticket Detectado", "ca": "Tiquet Detectat"],
        "Enter code manually": ["en": "Enter code manually", "es": "Introducir código manualmente", "ca": "Introduir codi manualment"],
        "Continue": ["en": "Continue", "es": "Continuar", "ca": "Continuar"],
        "Step 2 of 3": ["en": "Step 2 of 3", "es": "Paso 2 de 3", "ca": "Pas 2 de 3"],
        "Enter your license plate": ["en": "Enter your license plate", "es": "Introduce tu matrícula", "ca": "Introdueix la teva matrícula"],
        "Required to validate your parking access.": ["en": "Required to validate your parking access.", "es": "Necesaria para validar tu acceso al parking.", "ca": "Necessària per validar el teu accés al pàrquing."],
        "Confirm": ["en": "Confirm", "es": "Confirmar", "ca": "Confirmar"],
        "Review details": ["en": "Review details", "es": "Revisa los datos", "ca": "Revisa les dades"],
        "Ticket": ["en": "Ticket", "es": "Entrada", "ca": "Entrada"],
        "Valid until end of day": ["en": "Valid until end of day", "es": "Válido hasta el final del día", "ca": "Vàlid fins al final del dia"],
        "Vehicle": ["en": "Vehicle", "es": "Vehículo", "ca": "Vehicle"],
        "License Plate": ["en": "License Plate", "es": "Matrícula", "ca": "Matrícula"],
        "Confirm and Assign": ["en": "Confirm and Assign", "es": "Confirmar y Asignar", "ca": "Confirmar i Assignar"],
        "Spot Assigned!": ["en": "Spot Assigned!", "es": "¡Plaza Asignada!", "ca": "Plaça Assignada!"],
        "Go to Zone": ["en": "Go to Zone", "es": "Dirígete a la Zona", "ca": "Dirigeix-te a la Zona"],
        "Virtual Spot": ["en": "Virtual Spot", "es": "Plaza Virtual", "ca": "Plaça Virtual"],
        "Staff Validation": ["en": "Staff Validation", "es": "Validación Staff", "ca": "Validació Staff"],
        "This QR code is your confirmed access pass. Show it to security staff to enter your zone.": ["en": "This QR code is your confirmed access pass. Show it to security staff to enter your zone.", "es": "Este código QR es tu pase de acceso confirmado. Muéstralo al personal de seguridad para entrar a tu zona.", "ca": "Aquest codi QR és el teu passi d'accés confirmat. Mostra'l al personal de seguretat per entrar a la teva zona."],
        "Go to Home": ["en": "Go to Home", "es": "Ir al Inicio", "ca": "Anar a l'Inici"],
        
        // ParkingDetailViews
        "Validation Code": ["en": "Validation Code", "es": "Código de Validación", "ca": "Codi de Validació"],
        "This QR code validates your access to the assigned zone. Keep brightness high when scanning.": ["en": "This QR code validates your access to the assigned zone. Keep brightness high when scanning.", "es": "Este código QR valida tu acceso a la zona asignada. Mantén brillo alto al escanear.", "ca": "Aquest codi QR valida el teu accés a la zona assignada. Mantén la brillantor alta en escanejar."],
        "Access Instructions": ["en": "Access Instructions", "es": "Instrucciones de Acceso", "ca": "Instruccions d'Accés"],
        "Follow signs to Zone %@. Upon arrival, show this code to staff or scan the QR at the barrier if available.": ["en": "Follow signs to Zone %@. Upon arrival, show this code to staff or scan the QR at the barrier if available.", "es": "Sigue las señales hacia la Zona %@. Al llegar, muestra este código al personal o escanea el QR en la barrera si está disponible.", "ca": "Segueix els senyals cap a la Zona %@. En arribar, mostra aquest codi al personal o escaneja el QR a la barrera si està disponible."],
        "View location on map": ["en": "View location on map", "es": "Ver ubicación en mapa", "ca": "Veure ubicació al mapa"],
        "No active assignment": ["en": "No active assignment", "es": "No hay asignación activa", "ca": "No hi ha assignació activa"],
        "Parking Detail": ["en": "Parking Detail", "es": "Detalle Parking", "ca": "Detall Pàrquing"],
        "Guidance In Progress": ["en": "Guidance In Progress", "es": "Guiado en Curso", "ca": "Guiatge en Curs"],
        "Head to Zone %@": ["en": "Head to Zone %@", "es": "Dirígete hacia la Zona %@", "ca": "Dirigeix-te cap a la Zona %@"],
        "End Navigation": ["en": "End Navigation", "es": "Terminar Navegación", "ca": "Finalitzar Navegació"],
        "FAQ": ["en": "FAQ", "es": "Preguntas Frecuentes", "ca": "Preguntes Freqüents"],
        "Date": ["en": "Date", "es": "Fecha", "ca": "Data"],
        
        // CarPlayTemplateFactory
        "Destinations": ["en": "Destinations", "es": "Destinos", "ca": "Destinacions"],
        "Navigate": ["en": "Navigate", "es": "Navegar", "ca": "Navegar"],
        "Save My Location": ["en": "Save My Location", "es": "Guardar Mi Ubicación", "ca": "Desar La Meva Ubicació"],
        "Remember where you parked": ["en": "Remember where you parked", "es": "Recuerda dónde aparcaste", "ca": "Recorda on has aparcat"],
        "Go to My Car": ["en": "Go to My Car", "es": "Ir a Mi Coche", "ca": "Anar al Meu Cotxe"],
        "Your Parking": ["en": "Your Parking", "es": "Tu Parking", "ca": "El teu Pàrquing"],
        "Available Parkings": ["en": "Available Parkings", "es": "Parkings Disponibles", "ca": "Pàrquings Disponibles"],
        "Event": ["en": "Event", "es": "Evento", "ca": "Esdeveniment"],
        "Time": ["en": "Time", "es": "Hora", "ca": "Hora"],
        "Gates": ["en": "Gates", "es": "Puertas", "ca": "Portes"],
        "Open": ["en": "Open", "es": "Abiertas", "ca": "Obertes"],
        "Closed": ["en": "Closed", "es": "Cerradas", "ca": "Tancades"],
        "Offline Mode": ["en": "Offline Mode", "es": "Modo Offline", "ca": "Mode Offline"],
        "Enabled": ["en": "Enabled", "es": "Activado", "ca": "Activat"],
        "Disabled": ["en": "Disabled", "es": "Desactivado", "ca": "Desactivat"],
        "Version": ["en": "Version", "es": "Versión", "ca": "Versió"],
        "Finish": ["en": "Finish", "es": "Terminar", "ca": "Finalitzar"],
        "Main Entry": ["en": "Main Entry", "es": "Entrada Principal", "ca": "Entrada Principal"],
        "Paddock Access": ["en": "Paddock Access", "es": "Acceso Paddock", "ca": "Accés Paddock"],
        "Pass only": ["en": "Pass only", "es": "Solo con pase", "ca": "Només amb passi"],
        "Main Straight": ["en": "Main Straight", "es": "Recta Meta", "ca": "Recta Meta"],
        "Near entrance": ["en": "Near entrance", "es": "Cercano a entrada", "ca": "Proper a entrada"],
        "Credentials only": ["en": "Credentials only", "es": "Solo con acreditación", "ca": "Només amb acreditació"],
        "Saved location": ["en": "Saved location", "es": "Ubicación guardada", "ca": "Ubicació desada"],
        "Saved": ["en": "Saved", "es": "Guardado", "ca": "Desat"],
        "Parking location saved": ["en": "Parking location saved", "es": "Ubicación del parking guardada", "ca": "Ubicació del pàrquing desada"],
        
        // NavigationService / TransportMode
        "Car": ["en": "Car", "es": "Coche", "ca": "Cotxe"],
        "On foot": ["en": "On foot", "es": "A pie", "ca": "A peu"],
        "Transit": ["en": "Transit", "es": "Transporte", "ca": "Transport"],
        
        // MapViewModel errors
        "Could not get your location": ["en": "Could not get your location", "es": "No se pudo obtener tu ubicación", "ca": "No s'ha pogut obtenir la teva ubicació"],
        "Route calculation error": ["en": "Route calculation error: %@", "es": "Error al calcular ruta: %@", "ca": "Error en calcular ruta: %@"],
        "You have arrived at your destination.": ["en": "You have arrived at your destination.", "es": "Has llegado a tu destino.", "ca": "Has arribat a la teva destinació."],
        
        // OrdersViewModel errors
        "You must be logged in to place an order": ["en": "You must be logged in to place an order", "es": "Debes iniciar sesión para realizar un pedido", "ca": "Has d'iniciar sessió per fer una comanda"],
        "Cart is empty": ["en": "Cart is empty", "es": "El carrito está vacío", "ca": "El carret està buit"],
        "Order processing error": ["en": "Order processing error: %@", "es": "Error al procesar el pedido: %@", "ca": "Error en processar la comanda: %@"],
        
        // PublicTransportViewModel errors
        "Connection error": ["en": "Connection error: %@", "es": "Error de conexión: %@", "ca": "Error de connexió: %@"],
        
        // ParkingModels errors
        "Invalid license plate.": ["en": "The license plate entered is not valid.", "es": "La matrícula introducida no es válida.", "ca": "La matrícula introduïda no és vàlida."],
        "Invalid ticket.": ["en": "The ticket is not valid or could not be read.", "es": "El ticket no es válido o no se ha podido leer.", "ca": "El tiquet no és vàlid o no s'ha pogut llegir."],
        "Could not save the assignment.": ["en": "Could not save the assignment.", "es": "No se ha podido guardar la asignación.", "ca": "No s'ha pogut desar l'assignació."],
        "An unknown error occurred.": ["en": "An unknown error occurred.", "es": "Ha ocurrido un error desconocido.", "ca": "S'ha produït un error desconegut."],
        
        // GuidanceViewModel TTS
        "Walk to %@. You are %d meters away.": ["en": "Walk to %@. You are %d meters away.", "es": "Camina hacia %@. Estás a %d metros.", "ca": "Camina cap a %@. Ets a %d metres."],
        "Board bus %@ towards %@.": ["en": "Board bus %@ towards %@.", "es": "Sube al autobús %@ hacia %@.", "ca": "Puja a l'autobús %@ cap a %@."],
        "Take train %@ direction %@.": ["en": "Take train %@ direction %@.", "es": "Toma el tren %@ dirección %@.", "ca": "Agafa el tren %@ direcció %@."],
        "Head to %@": ["en": "Head to %@", "es": "Dirígete a %@", "ca": "Dirigeix-te a %@"],
        
        // RoadmapView status
        "Completed": ["en": "Completed", "es": "Completado", "ca": "Completat"],
        "In Progress": ["en": "In Progress", "es": "En progreso", "ca": "En progrés"],
        "Planned": ["en": "Planned", "es": "Planeado", "ca": "Planejat"],
        "Future": ["en": "Future", "es": "Futuro", "ca": "Futur"],
        
        // SettingsView
        "Notifications": ["en": "Notifications", "es": "Notificaciones", "ca": "Notificacions"],
        "Push Notifications": ["en": "Push Notifications", "es": "Notificaciones push", "ca": "Notificacions push"],
        "Configure my seat": ["en": "Configure my seat", "es": "Configurar mi localidad", "ca": "Configurar la meva localitat"],
        
        // CircuitMapView
        "Go to Circuit": ["en": "Go to Circuit", "es": "Ir al Circuito", "ca": "Anar al Circuit"],
        "Follow the route": ["en": "Follow the route", "es": "Sigue la ruta", "ca": "Segueix la ruta"],
        
        // PublicTransportSheetView / Transit
        "Open in Apple Maps": ["en": "Open in Apple Maps", "es": "Abrir en Apple Maps", "ca": "Obrir a Apple Maps"],
        "Public Transport": ["en": "Public Transport", "es": "Transporte Público", "ca": "Transport Públic"],
        "Transit opens in Apple Maps": ["en": "Transit directions will open in Apple Maps", "es": "Las indicaciones de transporte público se abrirán en Apple Maps", "ca": "Les indicacions de transport públic s'obriran a Apple Maps"],
        
        // OnboardingView
        "The ultimate circuit experience. Follow the race, track status and locate services.": ["en": "The ultimate circuit experience. Follow the race, track status and locate services.", "es": "La experiencia definitiva en el circuito. Sigue la carrera, el estado de la pista y localiza servicios.", "ca": "L'experiència definitiva al circuit. Segueix la cursa, l'estat de la pista i localitza serveis."],
        "Find food, WC, parking and your friends on the interactive circuit map.": ["en": "Find food, WC, parking and your friends on the interactive circuit map.", "es": "Encuentra comida, WC, parking y a tus amigos en el mapa interactivo del circuito.", "ca": "Troba menjar, WC, pàrquing i els teus amics al mapa interactiu del circuit."],
        "To alert you about Safety Cars and emergencies, we need to send you notifications.": ["en": "To alert you about Safety Cars and emergencies, we need to send you notifications.", "es": "Para avisarte de Safety Cars y emergencias, necesitamos enviarte notificaciones.", "ca": "Per avisar-te de Safety Cars i emergències, necessitem enviar-te notificacions."],
        
        // FeaturePlaceholderView
        "Simulation Environment": ["en": "Simulation Environment", "es": "Entorno de Simulación", "ca": "Entorn de Simulació"],
        
        // GuidanceView
        "Route Guidance": ["en": "Route Guidance", "es": "Guiado en Ruta", "ca": "Guiatge en Ruta"],
        
        // ItineraryDetailSheet
        "Trip Detail": ["en": "Trip Detail", "es": "Detalle del Viaje", "ca": "Detall del Viatge"],
        
        // FanZoneView
        "Checkpoint: Trivia": ["en": "Checkpoint: Trivia", "es": "Punto de Control: Trivia", "ca": "Punt de Control: Trivia"],
        
        // PoiListView
        "Entries": ["en": "Entries", "es": "Entradas", "ca": "Entrades"],
        
        // NavigationScreen (GPS)
        "Destination": ["en": "Destination", "es": "Destino", "ca": "Destinació"],
        "Start Navigation": ["en": "Start Navigation", "es": "Iniciar Navegación", "ca": "Iniciar Navegació"],
        "Calculating route...": ["en": "Calculating route...", "es": "Calculando ruta...", "ca": "Calculant ruta..."],
        "Recalculating route": ["en": "Recalculating route", "es": "Recalculando ruta", "ca": "Recalculant ruta"],
        "You have arrived!": ["en": "You have arrived!", "es": "¡Has llegado!", "ca": "Has arribat!"],
        "Arrival": ["en": "Arrival", "es": "Llegada", "ca": "Arribada"],
        "remaining": ["en": "remaining", "es": "restante", "ca": "restant"],
        "distance": ["en": "distance", "es": "distancia", "ca": "distància"],
        "Retry": ["en": "Retry", "es": "Reintentar", "ca": "Reintentar"],
        "Location permission required": ["en": "Location permission required", "es": "Se necesita permiso de ubicación", "ca": "Cal permís d'ubicació"],
        "No GPS permission": ["en": "No GPS permission", "es": "Sin permiso GPS", "ca": "Sense permís GPS"],
        "Searching GPS...": ["en": "Searching GPS...", "es": "Buscando GPS...", "ca": "Cercant GPS..."],
        "Low GPS accuracy": ["en": "Low GPS accuracy", "es": "Precisión GPS baja", "ca": "Precisió GPS baixa"],
        
        // Fan Zone
        "Fan Zone": ["en": "Fan Zone", "es": "Fan Zone", "ca": "Fan Zone"],
        "Choose Your Team": ["en": "Choose Your Team", "es": "Elige Tu Equipo", "ca": "Tria el Teu Equip"],
        "Done": ["en": "Done", "es": "Listo", "ca": "Fet"],
        "Trivia": ["en": "Trivia", "es": "Trivia", "ca": "Trivia"],
        "played": ["en": "played", "es": "jugadas", "ca": "jugades"],
        "News": ["en": "News", "es": "Noticias", "ca": "Notícies"],
        "articles": ["en": "articles", "es": "artículos", "ca": "articles"],
        "Cards": ["en": "Cards", "es": "Cromos", "ca": "Cromos"],
        "Latest News": ["en": "Latest News", "es": "Últimas Noticias", "ca": "Últimes Notícies"],
        "See all": ["en": "See all", "es": "Ver todo", "ca": "Veure tot"],
        "Loading news...": ["en": "Loading news...", "es": "Cargando noticias...", "ca": "Carregant notícies..."],
        "Quick Trivia": ["en": "Quick Trivia", "es": "Trivia Rápida", "ca": "Trivia Ràpida"],
        "My Collection": ["en": "My Collection", "es": "Mi Colección", "ca": "La Meva Col·lecció"],
        "Card Unlocked!": ["en": "Card Unlocked!", "es": "¡Cromo Desbloqueado!", "ca": "Cromo Desbloquejat!"],
        "Select Team": ["en": "Select Team", "es": "Seleccionar Equipo", "ca": "Seleccionar Equip"],

        // Quiz
        "Question": ["en": "Question", "es": "Pregunta", "ca": "Pregunta"],
        "Streak": ["en": "Streak", "es": "Racha", "ca": "Ratxa"],
        "Correct!": ["en": "Correct!", "es": "¡Correcto!", "ca": "Correcte!"],
        "Incorrect": ["en": "Incorrect", "es": "Incorrecto", "ca": "Incorrecte"],
        "Next": ["en": "Next", "es": "Siguiente", "ca": "Següent"],
        "See Results": ["en": "See Results", "es": "Ver Resultados", "ca": "Veure Resultats"],
        "Quiz Complete!": ["en": "Quiz Complete!", "es": "¡Quiz Completado!", "ca": "Quiz Completat!"],
        "Perfect!": ["en": "Perfect!", "es": "¡Perfecto!", "ca": "Perfecte!"],
        "Excellent!": ["en": "Excellent!", "es": "¡Excelente!", "ca": "Excel·lent!"],
        "Good job!": ["en": "Good job!", "es": "¡Buen trabajo!", "ca": "Bon treball!"],
        "Keep trying!": ["en": "Keep trying!", "es": "¡Sigue intentándolo!", "ca": "Segueix intentant-ho!"],
        "Play Again": ["en": "Play Again", "es": "Jugar de Nuevo", "ca": "Jugar de Nou"],
        "Back to Fan Zone": ["en": "Back to Fan Zone", "es": "Volver al Fan Zone", "ca": "Tornar al Fan Zone"],
        "Accuracy": ["en": "Accuracy", "es": "Precisión", "ca": "Precisió"],
        "Best Streak": ["en": "Best Streak", "es": "Mejor Racha", "ca": "Millor Ratxa"],
        "Total": ["en": "Total", "es": "Total", "ca": "Total"],
        "Loading questions...": ["en": "Loading questions...", "es": "Cargando preguntas...", "ca": "Carregant preguntes..."],

        // Fan News
        "Updated": ["en": "Updated", "es": "Actualizado", "ca": "Actualitzat"],
        "Never": ["en": "Never", "es": "Nunca", "ca": "Mai"],
        "Just now": ["en": "Just now", "es": "Ahora", "ca": "Ara"],
        "No news available": ["en": "No news available", "es": "No hay noticias", "ca": "No hi ha notícies"],
        "Refresh": ["en": "Refresh", "es": "Actualizar", "ca": "Actualitzar"],

        // Card Collection
        "Collection Progress": ["en": "Collection Progress", "es": "Progreso de Colección", "ca": "Progrés de Col·lecció"],
        "Unlocked": ["en": "Unlocked", "es": "Desbloqueados", "ca": "Desbloquejats"],
        "Locked": ["en": "Locked", "es": "Bloqueados", "ca": "Bloquejats"],
        "Common": ["en": "Common", "es": "Común", "ca": "Comú"],
        "Rare": ["en": "Rare", "es": "Raro", "ca": "Rar"],
        "Epic": ["en": "Epic", "es": "Épico", "ca": "Èpic"],
        "Legendary": ["en": "Legendary", "es": "Legendario", "ca": "Llegendari"],
        "No cards in this filter": ["en": "No cards in this filter", "es": "No hay cromos en este filtro", "ca": "No hi ha cromos en aquest filtre"],
        "Formula 1": ["en": "Formula 1", "es": "Fórmula 1", "ca": "Fórmula 1"]
    ]
    
    static func string(_ key: String) -> String {
        let lang = UserPreferences.shared.languageCode
        return translations[key]?[lang] ?? key
    }
    
    static var locale: Locale {
        return Locale(identifier: UserPreferences.shared.languageCode)
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/LocationManager.swift`

```swift
import Foundation
import CoreLocation
import Combine

/// Manages real-time GPS location, heading, and speed for navigation.
/// Uses high-accuracy updates suitable for turn-by-turn guidance.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    // MARK: - Published State
    
    /// Current user coordinate (updated every ~5 m)
    @Published var location: CLLocationCoordinate2D?
    
    /// Full CLLocation with altitude, speed, course, accuracy
    @Published var clLocation: CLLocation?
    
    /// Device heading in degrees (0-360, relative to true north)
    @Published var heading: CLLocationDirection = 0
    
    /// Current speed in m/s (-1 if unavailable)
    @Published var speed: CLLocationSpeed = -1
    
    /// Course (direction of travel) in degrees
    @Published var course: CLLocationDirection = -1
    
    /// Authorization status
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Human-readable GPS state
    @Published var gpsState: GPSState = .searching
    
    enum GPSState: Equatable {
        case unauthorized
        case searching
        case lowAccuracy
        case active
        case error(String)
    }
    
    // MARK: - Init
    
    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5 // Update every 5 meters
        manager.activityType = .automotiveNavigation
        manager.allowsBackgroundLocationUpdates = false // Enable if Info.plist has bg modes
        manager.pausesLocationUpdatesAutomatically = false
        manager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Control
    
    /// Start GPS updates (called automatically on authorization)
    func startUpdating() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    /// Stop GPS updates (battery savings)
    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            gpsState = .searching
            startUpdating()
        case .denied, .restricted:
            gpsState = .unauthorized
        default:
            gpsState = .searching
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        
        // Filter out stale / inaccurate readings
        let age = -loc.timestamp.timeIntervalSinceNow
        guard age < 10, loc.horizontalAccuracy >= 0 else { return }
        
        self.clLocation = loc
        self.location = loc.coordinate
        self.speed = loc.speed
        self.course = loc.course
        
        // Update GPS state based on accuracy
        if loc.horizontalAccuracy > 100 {
            gpsState = .lowAccuracy
        } else {
            gpsState = .active
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
        } else {
            heading = newHeading.magneticHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.error("[LocationManager] Error: \(error)")
        if let clError = error as? CLError, clError.code == .denied {
            gpsState = .unauthorized
        } else {
            gpsState = .error(error.localizedDescription)
        }
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/Logger.swift`

```swift
import Foundation
import os

struct Logger {
    private static let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.georacing", category: "General")

    static func debug(_ message: String) {
        logger.debug("[DEBUG] \(message)")
    }

    static func info(_ message: String) {
        logger.info("[INFO] \(message)")
    }

    static func warning(_ message: String) {
        logger.warning("[WARNING] \(message)")
    }

    static func error(_ message: String) {
        logger.error("[ERROR] \(message)")
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/PolylineUtils.swift`

```swift
import Foundation
import CoreLocation

struct PolylineUtils {
    
    /// Decodes a polyline string into an array of coordinates.
    /// - Parameters:
    ///   - polyline: The encoded polyline string.
    ///   - precision: The precision of the encoding (e.g., 1e5 for 5 digits, 1e6 for 6 digits).
    /// - Returns: Array of CLLocationCoordinate2D.
    static func decode(_ polyline: String, precision: Double = 1e6) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = polyline.startIndex
        
        var lat = 0
        var lng = 0
        
        while index < polyline.endIndex {
            var b: Int
            var shift = 0
            var result = 0
            
            repeat {
                if index >= polyline.endIndex { break }
                let char = polyline[index]
                b = Int(char.asciiValue! - 63)
                index = polyline.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20
            
            let dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += dLat
            
            shift = 0
            result = 0
            
            repeat {
                if index >= polyline.endIndex { break }
                let char = polyline[index]
                b = Int(char.asciiValue! - 63)
                index = polyline.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20
            
            let dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += dLng
            
            let latitude = Double(lat) / precision
            let longitude = Double(lng) / precision
            
            coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        
        return coordinates
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/RacingDesignSystem.swift`

```swift
import SwiftUI

struct RacingColors {
    static let red = Color(red: 0.85, green: 0.1, blue: 0.1) // Ferrari/Racing Red
    static let darkBackground = Color(red: 0.1, green: 0.12, blue: 0.15) // Asphalt Dark
    static let cardBackground = Color(red: 0.15, green: 0.18, blue: 0.22)
    static let white = Color.white
    static let silver = Color(red: 0.8, green: 0.8, blue: 0.82)
}

struct RacingFont {
    static func header(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .black, design: .rounded).italic()
    }
    
    static func subheader(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

// MARK: - Modifiers

struct RacingCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(RacingColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12)) // Alternatively use skewed text for headers, but rounded cards are cleaner for UI
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [RacingColors.red.opacity(0.8), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

struct RacingButtonModifier: ViewModifier {
    var color: Color = RacingColors.red
    
    func body(content: Content) -> some View {
        content
            .font(RacingFont.subheader())
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
    }
}

extension View {
    func racingCard() -> some View {
        self.modifier(RacingCardModifier())
    }
    
    func racingButton(color: Color = RacingColors.red) -> some View {
        self.modifier(RacingButtonModifier(color: color))
    }
    
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

```

---

## `iOS_App/GeoRacing/Core/Utilities/UserPreferences.swift`

```swift
import Foundation

@MainActor
class UserPreferences {
    static let shared = UserPreferences()
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let onboardingCompleted = "onboardingCompleted"
        static let language = "language"
        static let theme = "theme" // NEW
        static let highContrast = "highContrast"
        static let largeFont = "largeFont"
        
        static let grandstand = "seat_grandstand"
        static let zone = "seat_zone"
        static let row = "seat_row"
        static let seatNumber = "seat_number"
        static let dashboardWidgets = "dashboard_widgets"
        static let favoriteSeries = "favorite_series"
        static let favoriteTeam = "favorite_team"
        static let favoriteTeamId = "favorite_team_id"
    }

    enum AppTheme: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        var id: String { self.rawValue }
    }
    
    var theme: AppTheme {
        get {
            guard let raw = defaults.string(forKey: Keys.theme), let theme = AppTheme(rawValue: raw) else {
                return .system
            }
            return theme
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.theme) }
    }
    
    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }
    
    var languageCode: String {
        get { defaults.string(forKey: Keys.language) ?? "es" }
        set { defaults.set(newValue, forKey: Keys.language) }
    }
    
    var isHighContrastEnabled: Bool {
        get { defaults.bool(forKey: Keys.highContrast) }
        set { defaults.set(newValue, forKey: Keys.highContrast) }
    }
    
    var isLargeFontEnabled: Bool {
        get { defaults.bool(forKey: Keys.largeFont) }
        set { defaults.set(newValue, forKey: Keys.largeFont) }
    }
    
    // MARK: - Seat Configuration
    var grandstand: String? {
        get { defaults.string(forKey: Keys.grandstand) }
        set { defaults.set(newValue, forKey: Keys.grandstand) }
    }
    
    var zone: String? {
        get { defaults.string(forKey: Keys.zone) }
        set { defaults.set(newValue, forKey: Keys.zone) }
    }
    
    var row: String? {
        get { defaults.string(forKey: Keys.row) }
        set { defaults.set(newValue, forKey: Keys.row) }
    }
    
    var seatNumber: String? {
        get { defaults.string(forKey: Keys.seatNumber) }
        set { defaults.set(newValue, forKey: Keys.seatNumber) }
    }
    
    // MARK: - Dashboard Config
    var dashboardWidgets: [String] {
        get { defaults.stringArray(forKey: Keys.dashboardWidgets) ?? ["map", "shop", "food", "wc", "parking", "schedule", "social", "incidents"] }
        set { defaults.set(newValue, forKey: Keys.dashboardWidgets) }
    }
    
    // MARK: - Fan Zone Config
    var favoriteSeries: String {
        get { defaults.string(forKey: Keys.favoriteSeries) ?? "F1" }
        set { defaults.set(newValue, forKey: Keys.favoriteSeries) }
    }
    
    var favoriteTeam: String {
        get { defaults.string(forKey: Keys.favoriteTeam) ?? "Ferrari" }
        set { defaults.set(newValue, forKey: Keys.favoriteTeam) }
    }
    
    /// New team ID system (e.g. "f1_ferrari"). Falls back to empty for migration.
    var favoriteTeamId: String {
        get { defaults.string(forKey: Keys.favoriteTeamId) ?? "" }
        set { defaults.set(newValue, forKey: Keys.favoriteTeamId) }
    }
}

```

---

## `iOS_App/GeoRacing/Data/BLE/BeaconScanner.swift`

```swift
import Foundation
import CoreLocation
import Combine

@MainActor
class BeaconScanner: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = BeaconScanner()
    
    private var locationManager: CLLocationManager?

    @Published var foundBeacons: [CLBeacon] = []
    
    // API Integrated Beacons
    @Published var configBeacons: [BeaconDto] = []
    @Published var currentBeacon: BeaconDto?
    
    private var monitoredRegions: [CLBeaconRegion] = []
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.requestAlwaysAuthorization()
    }
    
    func loadBeacons() {
        Task {
            do {
                let beacons = try await APIService.shared.fetchBeacons()
                self.configBeacons = beacons
                self.startScanning()
            } catch {
                Logger.error("Failed to fetch beacons: \(error)")
            }
        }
    }
    
    func startScanning() {
        guard !configBeacons.isEmpty else { return }
        
        // Group by UUID to monitor unique UUIDs
        let uniqueUUIDs = Set(configBeacons.compactMap { UUID(uuidString: $0.uuid) })
        
        for uuid in uniqueUUIDs {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid)
            let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "GeoRacing_\(uuid.uuidString)")
            
            locationManager?.startMonitoring(for: region)
            locationManager?.startRangingBeacons(satisfying: constraint)
            monitoredRegions.append(region)
        }
    }
    
    func stopScanning() {
        for region in monitoredRegions {
            locationManager?.stopMonitoring(for: region)
            locationManager?.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
        monitoredRegions.removeAll()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        self.foundBeacons = beacons
        updateCurrentBeacon(from: beacons)
    }
    
    private func updateCurrentBeacon(from clBeacons: [CLBeacon]) {
        // Find the closest beacon from the ranged list
        // CLBeacon already sort by proximity usually, but let's be safe.
        // We need to match major/minor/uuid to our configBeacons
        
        // Closest beacon by accuracy (immediate/near)
        if let closest = clBeacons.first(where: { $0.accuracy != -1 && $0.accuracy < 5.0 }) { // 5 meters threshold
             // Matche with config
            if let matched = configBeacons.first(where: {
                $0.uuid.caseInsensitiveCompare(closest.uuid.uuidString) == .orderedSame &&
                $0.major == closest.major.intValue &&
                $0.minor == closest.minor.intValue
            }) {
                // Update current beacon only if it changed
                if self.currentBeacon?.id != matched.id {
                    self.currentBeacon = matched
                    Logger.info("Locked on beacon: \(matched.name)")
                }
                return
            }
        }
        
        // If we lost proximity or empty, maybe reset?
        // Or keep last known? For incident reporting, immediate presence is key.
        // Let's reset if list is empty or far.
        if clBeacons.isEmpty {
           // We might want to keep it for a few seconds (hysteresis), but for simple impl:
           // self.currentBeacon = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Logger.debug("Entered beacon region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.debug("Exited beacon region: \(region.identifier)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if configBeacons.isEmpty {
                loadBeacons()
            } else {
                startScanning()
            }
        default:
            break
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/BLE/BleCircuitSignal.swift`

```swift
import Foundation
import Combine

/// Manages BLE circuit signal detection for proximity-based features.
///
/// **Current Status: Intentional Stub**
/// This class is a placeholder for future BLE-based circuit signal detection.
/// Real implementation will use CoreBluetooth to detect circuit-specific BLE beacons
/// and update `isConnected` based on signal presence/strength.
/// The primary BLE scanning logic lives in `BeaconScanner` (iBeacon-based).
/// This class is reserved for non-iBeacon BLE peripherals (e.g., custom circuit hardware).
class BleCircuitSignal: ObservableObject {
    static let shared = BleCircuitSignal()
    
    @Published var isConnected = false
    
    private init() {}
    
    func startScanning() {
        Logger.debug("[BleCircuitSignal] Stub: Start Scanning")
    }
    
    func stopScanning() {
        Logger.debug("[BleCircuitSignal] Stub: Stop Scanning")
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/CircuitStatusRepository.swift`

```swift
import Foundation
import Combine

class CircuitStatusRepository: ObservableObject {
    static let shared = CircuitStatusRepository()
    
    @Published var currentStatus: TrackStatus = .green
    @Published var statusMessage: String = ""
    // Removed isEvacuation boolean, now handled by .evacuation case in TrackStatus
    
    private var timer: Timer?
    private let pollInterval: TimeInterval = 5.0
    private let cacheKey = "cached_circuit_state"
    
    struct CachedCircuitState: Codable {
        let status: String
        let message: String
        let timestamp: Date
    }
    
    private init() {
        loadFromCache()
        startPolling()
    }
    
    func startPolling() {
        stopPolling() // Ensure no duplicates
        
        // Initial fetch
        fetchStatus()
        
        // Schedule timer
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.fetchStatus()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchStatus() {
        Task {
            do {
                // Use APIService to fetch state (Single Source of Truth)
                let (status, message) = try await APIService.shared.fetchCircuitState()
                
                await MainActor.run {
                    // Only print if status actually changes
                    if self.currentStatus != status {
                         Logger.info("[CircuitStatusRepo] Status Changed: \(self.currentStatus) -> \(status)")
                         
                         // NOTIFICATIONS: Alert user of status change
                         // Only notify for "Active" states (Yellow, Red, SC, Evacuation), or all? 
                         // Generally Green->Red needs alert. Red->Green is good news.
                         // Let's notify for ALL changes for parity, unless Android does otherwise.
                         if status != .green && status != .unknown {
                             LocalNotificationManager.shared.sendNotification(
                                 title: LocalizationUtils.string(status.titleKey),
                                 body: message ?? LocalizationUtils.string(status.messageKey)
                             )
                         }
                    }
                    
                    self.currentStatus = status
                    self.statusMessage = message ?? ""
                    
                    // Persist to cache
                    self.saveToCache(status: status, message: message ?? "")
                }
            } catch {
                Logger.error("[CircuitStatusRepo] Polling Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveToCache(status: TrackStatus, message: String) {
        let cached = CachedCircuitState(status: status.rawValue, message: message, timestamp: Date())
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedCircuitState.self, from: data),
              let status = TrackStatus(rawValue: cached.status) else { return }
        
        self.currentStatus = status
        self.statusMessage = cached.message
        Logger.debug("[CircuitStatusRepo] Loaded cached state: \(status) (\(cached.timestamp))")
    }
    
    // MARK: - Write State
    
    func updateStatus(mode: TrackStatus, message: String) async throws {
        // Fetch existing records
        let records = try? await DatabaseClient.shared.read(table: "circuit_state")
        
        let flagString: String
        switch mode {
        case .green: flagString = "GREEN_FLAG"
        case .yellow: flagString = "YELLOW_FLAG"
        case .red: flagString = "RED_FLAG"
        case .sc: flagString = "SC_DEPLOYED"
        case .vsc: flagString = "VSC_DEPLOYED"
        case .evacuation: flagString = "EVACUATION_MODE"
        case .unknown: flagString = "UNKNOWN"
        }
        
        // Prepare data payload minus ID
        let baseData: [String: Any] = [
            "global_mode": flagString,
            "message": message,
            "updated_at": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        
        if let existingRecords = records, !existingRecords.isEmpty {
            // Update ALL existing records
            for record in existingRecords {
                if let existingId = record["id"] as? String {
                    var data = baseData
                    data["id"] = existingId
                    try await DatabaseClient.shared.upsert(table: "circuit_state", data: data)
                }
            }
        } else {
            // Create new default record
            var data = baseData
            data["id"] = "global_circuit_state"
            try await DatabaseClient.shared.upsert(table: "circuit_state", data: data)
        }
        
        // Optimistic update locally
        await MainActor.run {
            self.currentStatus = mode
            self.statusMessage = message
            
            // Optimistic update locally
            // Note: isEvacuation was removed. If message contains EVACUATION, 
            // the mode passed in should ideally be .evacuation, or we trust the next poll.
            // For now, we rely on the `mode` argument being correct.

        }
    }
    
    private func mapStatus(_ flag: String) -> TrackStatus {
        // Map from DB values (RED_FLAG, GREEN_FLAG, etc)
        let normalized = flag.uppercased()
        
        if normalized.contains("RED") { return .red }
        if normalized.contains("YELLOW") { return .yellow }
        if normalized.contains("GREEN") { return .green }
        // VSC check MUST be before SC check because "VSC" contains "SC"
        if normalized.contains("VSC") { return .vsc }
        if normalized.contains("SC") { return .sc }
        
        return .green
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/GroupLocationRepository.swift`

```swift
import Foundation
import Combine
import CoreLocation

struct GroupLocation: Identifiable, Codable, Sendable {
    let id: String
    let userId: String
    let displayName: String
    let coordinate: CLLocationCoordinate2D
    let lastUpdatedMs: Int64
    let sharing: Bool

    enum CodingKeys: String, CodingKey {
        case id, userId, displayName, latitude, longitude, lastUpdatedMs, sharing
    }

    init(id: String, userId: String, displayName: String, coordinate: CLLocationCoordinate2D, lastUpdatedMs: Int64, sharing: Bool) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.coordinate = coordinate
        self.lastUpdatedMs = lastUpdatedMs
        self.sharing = sharing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        displayName = try container.decode(String.self, forKey: .displayName)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        lastUpdatedMs = try container.decode(Int64.self, forKey: .lastUpdatedMs)
        sharing = try container.decode(Bool.self, forKey: .sharing)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(lastUpdatedMs, forKey: .lastUpdatedMs)
        try container.encode(sharing, forKey: .sharing)
    }
}

protocol GroupLocationRepositoryProtocol {
    func startPolling(groupName: String, currentUserId: String) -> AnyPublisher<[GroupLocation], Error>
    func updateMyLocation(groupName: String, userId: String, location: CLLocationCoordinate2D, displayName: String) async throws
}

final class GroupLocationRepository: GroupLocationRepositoryProtocol {

    private var timer: AnyCancellable?

    func startPolling(groupName: String, currentUserId: String) -> AnyPublisher<[GroupLocation], Error> {
        let subject = PassthroughSubject<[GroupLocation], Error>()

        timer?.cancel()
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    do {
                        let members = try await APIService.shared.fetchGroupMembers(groupName: groupName)
                        let mapped: [GroupLocation] = members.compactMap { m in
                            guard m.user_uuid != currentUserId else { return nil }
                            return GroupLocation(
                                id: m.user_uuid,
                                userId: m.user_uuid,
                                displayName: m.displayName ?? ("User " + m.user_uuid.prefix(6)),
                                coordinate: CLLocationCoordinate2D(latitude: m.lat, longitude: m.lon),
                                lastUpdatedMs: m.timestamp ?? 0,
                                sharing: true
                            )
                        }
                        subject.send(mapped)
                    } catch {
                        // No cortamos el stream en errores transitorios
                        // Si quieres cortar, usa subject.send(completion: .failure(error))
                    }
                }
            }

        return subject.eraseToAnyPublisher()
    }

    func updateMyLocation(groupName: String, userId: String, location: CLLocationCoordinate2D, displayName: String) async throws {
        let req = GroupLocationRequest(
            user_uuid: userId,
            group_name: groupName,
            lat: location.latitude,
            lon: location.longitude,
            displayName: displayName
        )
        try await APIService.shared.upsertGroupLocation(req)
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/GroupRepository.swift`

```swift
import Foundation
import Combine
import CoreLocation

class GroupRepository: ObservableObject {
    static let shared = GroupRepository()
    
    @Published var currentGroup: Group?
    @Published var groupMembers: [GroupMember] = []
    
    private let locationRepository = GroupLocationRepository()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Mock default state: No group
    }
    
    func createGroup() async throws -> Group {
        let newGroup = Group(id: "group_\(Int.random(in: 1000...9999))", name: "My Racing Group", ownerId: AuthService.shared.currentUser?.uid ?? "me", members: [])
        
        await MainActor.run {
            self.currentGroup = newGroup
            self.startPollingMembers()
        }
        return newGroup
    }
    
    func joinGroup(groupId: String) async throws {
         await MainActor.run {
             self.currentGroup = Group(id: groupId, name: "Joined Group", ownerId: "friend", members: [])
             self.startPollingMembers()
         }
    }
    
    func leaveGroup() {
        self.currentGroup = nil
        self.groupMembers = []
        cancellables.removeAll()
    }
    
    private func startPollingMembers() {
        guard let group = currentGroup else { return }
        // Don't cancel everything, we might want to keep location sharing? 
        // Actually, simpler to restart everything on group change.
        cancellables.removeAll()
        
        let userId = AuthService.shared.currentUser?.uid ?? "guest_user"
        
        // 1. Poll Members
        locationRepository
            .startPolling(groupName: group.id, currentUserId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] locations in
                self?.groupMembers = locations.map { loc in
                    GroupMember(id: loc.userId, displayName: loc.displayName, coordinate: loc.coordinate, isSharing: loc.sharing)
                }
            })
            .store(in: &cancellables)
            
        // 2. Start Sharing My Location
        startSharingLocation()
    }
    
    func generateInviteLink() -> String {
        guard let group = currentGroup else { return "" }
        return "georacing://join?groupId=\(group.id)"
    }
    
    private func startSharingLocation() {
        // Stop previous sharing if any
        // We will piggyback on the same timer logic or a new subscription?
        // Using Combine to observe LocationManager + Throttle
        
        // Subscription to LocationManager
        LocationManager.shared.$location
            .compactMap { $0 }
            .throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] loc in
                guard let self = self, let group = self.currentGroup else { return }
                guard let user = AuthService.shared.currentUser else { return } 
                 // Assuming AuthService has user. If not, fallback.
                let userId = user.uid
                let displayName = user.displayName ?? "User"
                
                Task {
                    try? await self.locationRepository.updateMyLocation(
                        groupName: group.id,
                        userId: userId,
                        location: loc,
                        displayName: displayName
                    )
                }
            }
            .store(in: &cancellables)
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/HybridCircuitStateRepository.swift`

```swift
import Foundation
import Combine

public class HybridCircuitStateRepository: ObservableObject {
    public static let shared = HybridCircuitStateRepository()
    
    @Published public var mode: TrackStatus = .green
    @Published public var message: String = ""
    @Published public var updatedAt: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
    
    public init() {
        // Observe the polling repository
        CircuitStatusRepository.shared.$currentStatus
            .combineLatest(CircuitStatusRepository.shared.$statusMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] (trackStatus, msg) in
                self?.updateState(trackStatus: trackStatus, message: msg)
            }
            .store(in: &cancellables)
    }
    
    public func start() {
        CircuitStatusRepository.shared.startPolling()
    }
    
    private func updateState(trackStatus: TrackStatus, message: String) {
        self.message = message
        self.mode = trackStatus
        updatedAt = Self.formatter.string(from: Date())
    }
    
    /// Resolves the current track status, using a fallback for `.unknown`.
    /// - Parameter fallback: The status to use when `mode` is `.unknown`. Defaults to `.green`.
    /// - Returns: The resolved `TrackStatus`.
    public func resolvedTrackStatus(fallback: TrackStatus = .green) -> TrackStatus {
        switch mode {
        case .evacuation: return .red
        case .unknown: return fallback
        default: return mode
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/NewsRepository.swift`

```swift
import Foundation

struct NewsArticle: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let content: String?
    let imageUrl: String?
    let timestamp: Double
    
    var date: Date {
        Date(timeIntervalSince1970: timestamp / 1000)
    }
}

class NewsRepository {
    static let shared = NewsRepository()
    private init() {}
    
    func fetchNews() async throws -> [NewsArticle] {
        // Try 'news' first, if fails maybe 'articles'?
        // Since we don't know the exact table, we default to 'news'
        let records = try await DatabaseClient.shared.read(table: "news")
        
        return records.compactMap { dict in
            // Map dictionary to NewsArticle
            guard let id = dict["id"] as? String ?? dict["_id"] as? String,
                  let title = dict["title"] as? String else {
                return nil
            }
            
            return NewsArticle(
                id: id,
                title: title,
                subtitle: dict["subtitle"] as? String,
                content: dict["content"] as? String,
                imageUrl: dict["image_url"] as? String,
                timestamp: dict["timestamp"] as? Double ?? Date().timeIntervalSince1970 * 1000
            )
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/OrdersRepository.swift`

```swift
import Foundation
import Combine

// MARK: - Cart Item (Local model for cart state)

struct CartItem: Identifiable, Equatable {
    var id: String { productId }
    let productId: String
    let product: Product
    var quantity: Int
    
    var subtotal: Double {
        product.price * Double(quantity)
    }
    
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        lhs.productId == rhs.productId && lhs.quantity == rhs.quantity
    }
}

// MARK: - Orders Repository Protocol

protocol OrdersRepositoryProtocol {
    func fetchProducts() async throws -> [Product]
    func fetchOrders(userId: String) async throws -> [Order]
    func createOrder(userId: String, items: [CartItem]) async throws -> Order
}

// MARK: - Orders Repository Implementation

final class OrdersRepository: OrdersRepositoryProtocol {
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async throws -> [Product] {
        guard let url = URL(string: "\(AppConstants.apiBaseUrl)/products") else {
            Logger.warning("[OrdersRepository] Invalid URL")
            return Self.mockProducts
        }
        
        Logger.debug("[OrdersRepository] Fetching products from: \(url)")
        
        do {
            let products = try await apiService.fetchProducts()
            Logger.info("[OrdersRepository] Loaded \(products.count) products from API")
            
            // Debug: Log each product
            for product in products {
                Logger.debug("  [Product] \(product.name) - \(product.price)€ - \(product.category) \(product.emoji ?? "")")
            }
            
            return products
        } catch {
            Logger.error("[OrdersRepository] API Error: \(error.localizedDescription)")
            Logger.error("[OrdersRepository] Full error: \(error)")
            Logger.warning("[OrdersRepository] Using mock products as fallback")
            return Self.mockProducts
        }
    }
    
    // MARK: - Fetch Orders
    
    func fetchOrders(userId: String) async throws -> [Order] {
        // For now, return mock orders - can be extended to fetch from API
        return Self.mockOrders(for: userId)
    }
    
    // MARK: - Create Order
    
    func createOrder(userId: String, items: [CartItem]) async throws -> Order {
        let total = items.reduce(0) { $0 + $1.subtotal }
        
        // Simulate order creation - in production this would POST to API
        let orderItems = items.map { item in
            OrderItem(
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.product.price
            )
        }
        
        return Order(
            id: UUID().uuidString,
            orderId: "ORD-\(Int.random(in: 1000...9999))",
            userUid: userId,
            status: .pending,
            items: orderItems,
            totalAmount: total,
            platform: "iOS",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Mock Data
    
    static let mockProducts: [Product] = [
        Product(id: "1", productId: "prod-1", name: "Camiseta Circuit", description: "Camiseta oficial del circuito", price: 35.99, stock: 100, category: "merchandise", imageUrl: nil, emoji: "tshirt.fill", isActive: true),
        Product(id: "2", productId: "prod-2", name: "Gorra Racing", description: "Gorra oficial de carreras", price: 24.99, stock: 50, category: "merchandise", imageUrl: nil, emoji: "crown.fill", isActive: true),
        Product(id: "3", productId: "prod-3", name: "Bocadillo", description: "Bocadillo de jamón serrano", price: 8.50, stock: 200, category: "food", imageUrl: nil, emoji: "fork.knife", isActive: true),
        Product(id: "4", productId: "prod-4", name: "Hamburguesa", description: "Hamburguesa premium con patatas", price: 12.99, stock: 150, category: "food", imageUrl: nil, emoji: "fork.knife", isActive: true),
        Product(id: "5", productId: "prod-5", name: "Coca-Cola", description: "Refresco 500ml", price: 3.50, stock: 500, category: "drinks", imageUrl: nil, emoji: "cup.and.saucer.fill", isActive: true),
        Product(id: "6", productId: "prod-6", name: "Agua", description: "Agua mineral 500ml", price: 2.50, stock: 600, category: "drinks", imageUrl: nil, emoji: "drop.fill", isActive: true),
        Product(id: "7", productId: "prod-7", name: "Cerveza", description: "Cerveza nacional 330ml", price: 5.00, stock: 300, category: "drinks", imageUrl: nil, emoji: "mug.fill", isActive: true),
        Product(id: "8", productId: "prod-8", name: "Llavero", description: "Llavero conmemorativo", price: 9.99, stock: 80, category: "merchandise", imageUrl: nil, emoji: "key.fill", isActive: true),
    ]
    
    static func mockOrders(for userId: String) -> [Order] {
        [
            Order(
                id: "order-1",
                orderId: "ORD-1234",
                userUid: userId,
                status: .delivered,
                items: [
                    OrderItem(productId: "1", quantity: 1, unitPrice: 35.99),
                    OrderItem(productId: "5", quantity: 2, unitPrice: 3.50)
                ],
                totalAmount: 42.99,
                platform: "iOS",
                createdAt: "2026-01-28T10:30:00Z"
            )
        ]
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/ProductRepository.swift`

```swift
import Foundation
import Combine

class ProductRepository {
    static let shared = ProductRepository()
    private init() {}
    
    func fetchProducts() async throws -> [Product] {
        // Read directly from 'products' table
        Logger.debug("[ProductRepo] Fetching from table 'products'...")
        let records = try await DatabaseClient.shared.read(table: "products")
        Logger.debug("[ProductRepo] Raw records found: \(records.count)")
        
        let products = records.compactMap { dict -> Product? in
            // Convert dictionary to JSON data for decoding
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { 
                Logger.warning("[ProductRepo] Failed to serialize dict: \(dict)")
                return nil 
            }
            
            do {
                let product = try JSONDecoder().decode(Product.self, from: jsonData)
                
                // Debugging "Invisible" Products
                if !product.isActive {
                    Logger.debug("[ProductRepo] Hidden (Inactive): \(product.name)")
                }
                
                return product.isActive ? product : nil 
            } catch {
                Logger.error("[ProductRepo] Decoding Error for item: \(dict). Reason: \(error)")
                return nil
            }
        }
        
        Logger.info("[ProductRepo] Final visible products: \(products.count)")
        return products
    }
    
    // Create 'orders' entry
    func submitOrder(items: [OrderItem], total: Double, user: AppUser) async throws -> String {
        let orderId = UUID().uuidString
        let itemsData = try JSONEncoder().encode(items)
        let itemsJson = String(data: itemsData, encoding: .utf8) ?? "[]"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let createdAt = dateFormatter.string(from: Date())
        
        let orderData: [String: Any] = [
            "order_id": orderId,
            "user_uid": user.uid,
            "status": "PENDING",
            "items_json": itemsJson,
            "total_amount": total,
            "platform": "IOS",
            "created_at": createdAt
        ]
        
        try await DatabaseClient.shared.upsert(table: "orders", data: orderData)
        return orderId
    }
}


```

---

## `iOS_App/GeoRacing/Data/Repositories/RouteRepository.swift`

```swift
import Foundation
import CoreLocation
import Combine

class RouteRepository {
    
    static let shared = RouteRepository()
    
    private let baseURL = AppConstants.osrmBaseUrl
    private let session = URLSession.shared
    
    private init() {}
    
    /// Fetches a route from Origin to Destination using OSRM
    /// Android Spec 1.1: /route/v1/driving/{lon},{lat};{lon},{lat}?overview=full&steps=true
    func fetchRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteResult {
        
        // Format URL: OSRM uses {lon},{lat}
        let coordinates = "\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude)"
        
        // Ensure we request polyline6 if needed by spec (Android doc says Polyline6), otherwise standard is 5.
        // We will request geometries=polyline6 explicitly to be safe and match PolylineUtils default
        let queryItems = [
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "steps", value: "true"),
            URLQueryItem(name: "geometries", value: "polyline6")
        ]
        
        var urlComps = URLComponents(string: "\(baseURL)/route/v1/driving/\(coordinates)")
        urlComps?.queryItems = queryItems
        
        guard let url = urlComps?.url else {
            throw URLError(.badURL)
        }
        
        Logger.debug("[RouteRepo] Requesting Route: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            Logger.error("[RouteRepo][ERROR] HTTP Error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw URLError(.badServerResponse)
        }
        
        // Decode OSRM Response
        let osrmResponse = try JSONDecoder().decode(OSRMResponse.self, from: data)
        
        guard let primaryRoute = osrmResponse.routes.first else {
            throw URLError(.cannotParseResponse)
        }
        
        return try mapToDomain(osrmRoute: primaryRoute)
    }
    
    private func mapToDomain(osrmRoute: OSRMRoute) throws -> RouteResult {
        // 1. Decode Geometry (Polyline6)
        // Android Spec 1.1.3: Decodificación de Polilínea
        let geometry = PolylineUtils.decode(osrmRoute.geometry, precision: 1e6)
        
        // 2. Extract Steps
        // Android Spec 1.1.4: Extracción de Pasos (Steps)
        var steps: [RouteStep] = []
        
        // OSRM usually has one 'leg' for point A to B
        if let leg = osrmRoute.legs.first {
            steps = leg.steps.map { osrmStep in
                // Each step also has geometry, we can decode if needed for turn-by-turn highlighting,
                // but essential for instruction list.
                // Required fields: Type, Modifier, Name, Distance.
                
                return RouteStep(
                    id: UUID(),
                    instruction: buildInstruction(step: osrmStep),
                    distance: osrmStep.distance,
                    duration: osrmStep.duration,
                    maneuverType: osrmStep.maneuver.type,
                    maneuverModifier: osrmStep.maneuver.modifier
                )
            }
        }
        
        return RouteResult(
            geometry: geometry,
            duration: osrmRoute.duration,
            distance: osrmRoute.distance,
            steps: steps
        )
    }
    
    private func buildInstruction(step: OSRMStep) -> String {
        // Simple formatter. Real implementations often use OSRM Text Instructions library.
        // Android Spec 1.4: mentions "Gira a la derecha", etc.
        // We do a basic mapping here for parity.
        
        let type = step.maneuver.type
        let modifier = step.maneuver.modifier ?? ""
        let name = step.name.isEmpty ? "" : "en \(step.name)"
        
        switch type {
        case "depart": return "Salida"
        case "arrive": return "Has llegado a tu destino"
        case "turn":
            if modifier.contains("left") { return "Gira a la izquierda \(name)" }
            if modifier.contains("right") { return "Gira a la derecha \(name)" }
            return "Gira \(name)"
        case "roundabout":
            return "En la rotonda, toma la salida \(step.maneuver.modifier ?? "")"
        default:
            return "\(type.capitalized) \(modifier) \(name)"
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/ShareSessionRepository.swift`

```swift
import Foundation

protocol ShareSessionRepositoryProtocol {
    func createSession(ownerId: String, groupId: String) async throws -> ShareSession
    func joinSession(sessionId: String, userId: String) async throws -> String // Returns GroupID
}

class ShareSessionRepository: ShareSessionRepositoryProtocol {
    
    // Mock Database
    private var sessions: [String: ShareSession] = [:]
    
    func createSession(ownerId: String, groupId: String) async throws -> ShareSession {
        let uuid = UUID().uuidString
        // Expires end of day
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        components.second = 59
        let expiresAt = calendar.date(from: components) ?? Date().addingTimeInterval(86400)
        
        let session = ShareSession(id: uuid, ownerId: ownerId, groupId: groupId, expiresAt: expiresAt)
        
        // Save to DB (Mock)
        sessions[uuid] = session
        Logger.info("Created session \(uuid) for group \(groupId)")
        
        return session
    }
    
    func joinSession(sessionId: String, userId: String) async throws -> String {
        // 1. Consult UUID
        guard let session = sessions[sessionId] else {
            throw NSError(domain: "ShareSession", code: 404, userInfo: [NSLocalizedDescriptionKey: "Session not found"])
        }
        
        // 2. Validate Expiry
        guard session.isValid else {
            throw NSError(domain: "ShareSession", code: 400, userInfo: [NSLocalizedDescriptionKey: "Session expired"])
        }
        
        // 3. Join (Add user to group members in DB)
        Logger.info("User \(userId) joining group \(session.groupId)")
        
        return session.groupId
    }
}

```

---

## `iOS_App/GeoRacing/Data/Repositories/UserProfileRepository.swift`

```swift
import Foundation

class UserProfileRepository {
    static let shared = UserProfileRepository()
    
    private init() {}
    
    /// Syncs user data to the backend 'users' table.
    /// Replicates Android's NetworkUserRepository.
    func syncUser(_ user: AppUser) async throws {
        let data: [String: Any] = [
            "uid": user.uid,
            "email": user.email,
            "display_name": user.displayName ?? "",
            "photo_url": user.photoURL ?? "",
            "last_login": Date().timeIntervalSince1970 * 1000 // Android usually sends MS
        ]
        
        try await DatabaseClient.shared.upsert(table: "users", data: data)
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/APIModels.swift`

```swift
import Foundation

struct CircuitStateDto: Codable, Sendable {
    let flag: String
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case flag = "global_mode" // Critical: Map backend 'global_mode' to our 'flag' property
        case message
    }
}

struct PoiDto: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let type: String
    let description: String?
    let zone: String?
    let map_x: Double
    let map_y: Double
}

struct BeaconDto: Codable, Identifiable, Sendable {
    let id: String
    let uuid: String
    let major: Int
    let minor: Int
    let name: String
    let map_x: Double
    let map_y: Double
}

struct IncidentReportDto: Codable, Sendable {
    let category: String
    let description: String
    let beacon_id: String?
    let zone: String?
    let timestamp: Int64
}

struct GroupLocationRequest: Codable, Sendable {
    let user_uuid: String
    let group_name: String
    let lat: Double
    let lon: Double
    let displayName: String
}

struct GroupMemberDto: Codable, Sendable {
    let user_uuid: String
    let displayName: String?
    let lat: Double
    let lon: Double
    let timestamp: Int64?
}

struct ZoneDensityDto: Codable, Identifiable, Sendable {
    var id: String { zone_id }
    let zone_id: String
    let density_level: String // LOW, MEDIUM, HIGH, CRITICAL
    let estimated_wait_minutes: Int
    let trend: String // RISING, FALLING, STABLE
}


```

---

## `iOS_App/GeoRacing/Data/Services/APIService.swift`

```swift
import Foundation

class APIService: NSObject, URLSessionDelegate {
        
    static let shared = APIService()
    
    private let baseURL = AppConstants.apiBaseUrl
    
    // We use an implicitly unwrapped optional or just a regular optional 
    // to allow 'self' to be used in init.
    // However, it's cleaner to assign it lazily but ensuring thread safety is harder.
    // The previous implementation used lazy var which was MainActor isolated.
    // Here we will use a private var and a public accessor or just initialize it in a way that respects Swift's init rules.
    var session: URLSession!
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        // Now 'self' is fully initialized, we can pass it as delegate
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    // MARK: - Endpoints
    
    func fetchCircuitState() async throws -> (status: TrackStatus, message: String?) {
        guard let url = URL(string: "\(baseURL)/state") else { throw URLError(.badURL) }
        
        // Debugging: Print Request URL
        Logger.debug("[APIService] Fetching Circuit State from: \(url)")
        
        let (data, _) = try await session.data(from: url)
        
        // Debugging: Convert data to string to see RAW RESPONSE
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.debug("[APIService] Raw Response: \(jsonString)")
        }
        
        // Explicitly catching decoding errors to print them clearly
        do {
            let dto = try JSONDecoder().decode(CircuitStateDto.self, from: data)
            Logger.debug("[APIService] Decoded DTO: flag='\(dto.flag)', message='\(dto.message ?? "nil")'")
            return (mapStatus(dto.flag), dto.message)
        } catch {
            Logger.error("[APIService] JSON Decode Error: \(error)")
            throw error
        }
    }
    
    func fetchProducts() async throws -> [Product] {
        guard let url = URL(string: "\(baseURL)/products") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Product].self, from: data)
    }

    func fetchPois() async throws -> [PoiDto] {
        guard let url = URL(string: "\(baseURL)/pois") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([PoiDto].self, from: data)
    }
    
    func fetchBeacons() async throws -> [BeaconDto] {
        guard let url = URL(string: "\(baseURL)/beacons") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([BeaconDto].self, from: data)
    }
    
    func sendIncident(_ report: IncidentReportDto) async throws {
        guard let url = URL(string: "\(baseURL)/incidents") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(report)
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchGroupMembers(groupName: String) async throws -> [GroupMemberDto] {
        // GET /groups/{groupName}/members
        guard let url = URL(string: "\(baseURL)/groups/\(groupName)/members") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([GroupMemberDto].self, from: data)
    }

    func upsertGroupLocation(_ req: GroupLocationRequest) async throws {
        // POST /groups/location
        guard let url = URL(string: "\(baseURL)/groups/location") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(req)
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchZoneDensities() async throws -> [ZoneDensityDto] {
        guard let url = URL(string: "\(baseURL)/zones/density") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([ZoneDensityDto].self, from: data)
    }
    
    private func mapStatus(_ flag: String) -> TrackStatus {
        let normalized = flag.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 0. EVACUATION (Highest Priority)
        if normalized.contains("EVACUATION") {
            return .evacuation
        }
        
        // 1. RED / CLOSED / STOP
        if normalized.contains("RED") || normalized.contains("STOP") || normalized.contains("BLOCK") || normalized.contains("CLOSE") {
            return .red
        }
        
        // 2. ORANGE / CAUTION / SAFETY CAR / YELLOW
        if normalized.contains("SC") || normalized.contains("SAFETY") || normalized.contains("VSC") || normalized.contains("VIRTUAL") || normalized.contains("CAUTION") || normalized.contains("WARN") || normalized.contains("YELLOW") {
            return .sc 
        }

        // 3. GREEN / CLEAN
        if normalized.contains("GREEN") || normalized.contains("CLEAN") || normalized.contains("CLEAR") || normalized.contains("PISTA") {
            return .green
        }
        
        // 4. UNKNOWN - Strict parity rule: don't hide unknown states
        Logger.warning("[APIService] Unknown Status String: '\(normalized)' -> Mapped to .unknown")
        return .unknown
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/AuthService.swift`

```swift
import Foundation
import SwiftUI
import Combine

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    
    private init() {
        #if canImport(FirebaseAuth)
        // Check existing session
        if let firebaseUser = Auth.auth().currentUser {
            self.mapFirebaseUser(firebaseUser)
        }
        #endif
    }
    
    @MainActor
    func signInWithGoogle() async throws {
        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // 1. Google Sign In
        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw customError("Could not get ID Token from Google")
        }
        let accessToken = gidResult.user.accessToken.tokenString
        
        // 2. Firebase Credential
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
        
        // 3. Firebase Auth
        let authResult = try await Auth.auth().signIn(with: credential)
        
        // 4. Update State & Sync
        let user = self.mapFirebaseUser(authResult.user)
        
        // 5. Sync to Backend (Async, don't block UI)
        Task {
            do {
                try await UserProfileRepository.shared.syncUser(user)
                Logger.info("[AuthService] User Synced to Backend")
            } catch {
                Logger.error("[AuthService] User Sync Failed: \(error)")
            }
        }
        #else
        // Stub Implementation for Dev/Demo when pods are missing
        Logger.warning("[AuthService] Dependencies missing. Using Stub Auth.")
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000) // Simulate delay
        let stubUser = AppUser(uid: "stub_123", email: "demo@georacing.com", displayName: "Demo Driver", photoURL: nil)
        self.currentUser = stubUser
        self.isAuthenticated = true
        #endif
    }
    
    func signOut() {
        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            Logger.error("Error signing out: \(error)")
        }
        #else
        self.currentUser = nil
        self.isAuthenticated = false
        #endif
    }
    
    #if canImport(FirebaseAuth)
    @discardableResult
    private func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> AppUser {
        let user = AppUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString
        )
        
        Task { @MainActor in
            self.currentUser = user
            self.isAuthenticated = true
        }
        return user
    }
    #endif
    
    private func customError(_ msg: String) -> NSError {
        NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/CrowdDensityService.swift`

```swift
import Foundation
import Combine

class CrowdDensityService: ObservableObject {
    static let shared = CrowdDensityService()
    
    @Published var densities: [String: ZoneDensityDto] = [:]
    
    private var timer: Timer?
    private let apiService = APIService.shared
    
    init() {
        // Start polling
        startPolling()
    }
    
    func startPolling() {
        stopPolling()
        fetchData() // initial fetch
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.fetchData()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchData() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await self.apiService.fetchZoneDensities()
                await MainActor.run {
                    self.densities = Dictionary(uniqueKeysWithValues: list.map { ($0.zone_id, $0) })
                }
            } catch {
                Logger.error("[CrowdDensityService] Error fetching crowd density: \(error)")
            }
        }
    }
    
    // Logic to find if a better route exists
    func getEfficientRoute(from: String, to: String) -> RouteSuggestion? {
        // MOCK LOGIC: In a real app, this would use a graph.
        // Simplified: Check if "Gate A" is congested, suggest "Gate B"
        
        let destinationDensity = densities[to]
        
        if let density = destinationDensity, density.density_level == "CRITICAL" || density.density_level == "HIGH" {
            // Suggest alternative
            return RouteSuggestion(
                target: to,
                originalEta: "\(density.estimated_wait_minutes + 10) min",
                newEta: "\(density.estimated_wait_minutes / 2) min",
                instruction: "Use alternative Route B to avoid queues",
                timeSaved: "\(density.estimated_wait_minutes / 2)m saved"
            )
        }
        
        return nil
    }
}

struct RouteSuggestion: Equatable {
    let target: String
    let originalEta: String
    let newEta: String
    let instruction: String
    let timeSaved: String
}

```

---

## `iOS_App/GeoRacing/Data/Services/DatabaseClient.swift`

```swift
import Foundation

/// A generic client for the "FirestoreLike" API used in the project.
/// Replicates Android's FirestoreLikeClient / FirestoreLikeApi.
@MainActor
class DatabaseClient {
    static let shared = DatabaseClient()
    
    private let baseURL = AppConstants.apiBaseUrl
    private let session: URLSession
    
    private init() {
        // Reuse the same unsafe configuration as APIService given it's the same dev server
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config, delegate: APIService.shared, delegateQueue: nil)
    }
    
    // MARK: - API Response Types
    
    struct UpsertRequest: Encodable {
        let table: String
        let data: [String: AnyEncodable]
    }
    
    struct GetRequest: Encodable {
        let table: String
        let whereClause: [String: AnyEncodable]
        
        enum CodingKeys: String, CodingKey {
            case table
            case whereClause = "where"
        }
    }
    
    // MARK: - Methods
    
    /// Replicates `GET /_read?table={table}`
    func read(table: String) async throws -> [[String: Any]] {
        guard let url = URL(string: "\(baseURL)/_read?table=\(table)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // The API returns a list of maps (JSON Objects)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: [])
        guard let list = jsonResult as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return list
    }
    
    /// Replicates `POST /_get` with body { table, where }
    func get(table: String, where criteria: [String: Any]) async throws -> [[String: Any]] {
        guard let url = URL(string: "\(baseURL)/_get") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let wrappedCriteria = criteria.mapValues { AnyEncodable($0) }
        let bodyObj = GetRequest(table: table, whereClause: wrappedCriteria)
        request.httpBody = try JSONEncoder().encode(bodyObj)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: [])
        guard let list = jsonResult as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return list
    }
    
    /// Replicates `POST /_upsert` with body { table, data }
    func upsert(table: String, data: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/_upsert") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let wrappedData = data.mapValues { AnyEncodable($0) }
        let bodyObj = UpsertRequest(table: table, data: wrappedData)
        let bodyData = try JSONEncoder().encode(bodyObj)
        request.httpBody = bodyData
        
        // Check local network monitor state first if possible, or attempt directly
        let isOnline = await SyncQueueManager.shared.isOnline
        
        if !isOnline {
            Logger.warning("[DatabaseClient] Device is offline. Queuing upsert to table: \(table)")
            await SyncQueueManager.shared.enqueue(table: table, rawBody: bodyData)
            return // Return success locally (Deferred execution)
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("[DatabaseClient] Server error. Queuing upsert to table: \(table)")
                await SyncQueueManager.shared.enqueue(table: table, rawBody: bodyData)
                return
            }
            
            Logger.info("[DatabaseClient] Upsert successful to table: \(table)")
        } catch {
            Logger.warning("[DatabaseClient] Network/Timeout error. Queuing upsert to table: \(table)")
            await SyncQueueManager.shared.enqueue(table: table, rawBody: bodyData)
        }
    }
}

extension DatabaseClient {
    // Compatibilidad con codigo previo (no cambia la API real)
    func upsert(table: String, key: String, value: Any, data: [String: Any]) async throws {
        var merged = data
        merged[key] = value
        try await upsert(table: table, data: merged)
    }
}

// MARK: - Helper for Any encoding
struct AnyEncodable: Encodable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let string as String: try container.encode(string)
        case let bool as Bool: try container.encode(bool)
        // Add other types as needed
        default:
            let context = EncodingError.Context(codingPath: [], debugDescription: "Invalid JSON value")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/FanNewsService.swift`

```swift
import Foundation
import Combine
import UIKit

// MARK: - Fan News Service

/// Aggregates motorsport news from RSS feeds.
/// Supports multiple sources, deduplication, caching, and offline mode.
@MainActor
final class FanNewsService: ObservableObject {
    
    static let shared = FanNewsService()
    
    // MARK: - Published
    
    @Published private(set) var articles: [FeedArticle] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastRefreshed: Date?
    @Published private(set) var errorMessage: String?
    
    // MARK: - Config
    
    /// RSS feed sources
    private let feeds: [(url: String, source: String, championship: Championship)] = [
        ("https://www.motorsport.com/rss/f1/news/", "Motorsport.com", .f1),
        ("https://www.motorsport.com/rss/motogp/news/", "Motorsport.com", .motogp),
        ("https://www.autosport.com/rss/feed/f1", "Autosport", .f1),
        ("https://www.autosport.com/rss/feed/motogp", "Autosport", .motogp),
    ]
    
    /// Cache keys
    private let cacheKey = "fan_news_cache"
    private let cacheTimestampKey = "fan_news_timestamp"
    
    /// Refresh minimum interval (5 minutes)
    private let refreshInterval: TimeInterval = 5 * 60
    
    /// Max articles to keep
    private let maxArticles = 100
    
    // MARK: - Init
    
    private init() {
        loadFromCache()
    }
    
    // MARK: - Public API
    
    /// Fetch latest news from all feeds
    func refreshNews() async {
        // Throttle: don't refresh too frequently
        if let last = lastRefreshed, Date().timeIntervalSince(last) < refreshInterval {
            Logger.debug("[FanNews] Throttled, last refresh \(Int(Date().timeIntervalSince(last)))s ago")
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        var allArticles: [FeedArticle] = []
        
        await withTaskGroup(of: [FeedArticle].self) { group in
            for feed in feeds {
                group.addTask { [weak self] in
                    await self?.fetchFeed(urlString: feed.url, source: feed.source, championship: feed.championship) ?? []
                }
            }
            
            for await feedArticles in group {
                allArticles.append(contentsOf: feedArticles)
            }
        }
        
        if allArticles.isEmpty && articles.isEmpty {
            errorMessage = "No news available"
            Logger.warning("[FanNews] No articles fetched")
            return
        }
        
        // Deduplicate
        var deduped = FeedArticle.deduplicateURL(allArticles)
        deduped = FeedArticle.deduplicateTitle(deduped)
        
        // Sort by date (newest first)
        deduped.sort { $0.publishedAt > $1.publishedAt }
        
        // Limit
        if deduped.count > maxArticles {
            deduped = Array(deduped.prefix(maxArticles))
        }
        
        articles = deduped
        lastRefreshed = Date()
        saveToCache()
        
        Logger.info("[FanNews] Refreshed: \(deduped.count) articles from \(feeds.count) feeds")
    }
    
    /// Force refresh (ignore throttle)
    func forceRefresh() async {
        lastRefreshed = nil
        await refreshNews()
    }
    
    /// Get articles for a specific championship
    func articles(for championship: Championship) -> [FeedArticle] {
        articles.filter { $0.championship == championship }
    }
    
    /// Human-readable "last updated" label
    var lastRefreshedText: String {
        guard let date = lastRefreshed else {
            return LocalizationUtils.string("Never")
        }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return LocalizationUtils.string("Just now")
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins) min"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        }
    }
    
    /// Track that a user read an article (for rewards)
    func markAsRead(_ articleId: String) {
        var readIds = UserDefaults.standard.stringArray(forKey: "fan_news_read_ids") ?? []
        if !readIds.contains(articleId) {
            readIds.append(articleId)
            UserDefaults.standard.set(readIds, forKey: "fan_news_read_ids")
            // Notify reward service
            RewardService.shared.recordEvent(.newsRead)
        }
    }
    
    var totalRead: Int {
        (UserDefaults.standard.stringArray(forKey: "fan_news_read_ids") ?? []).count
    }
    
    // MARK: - RSS Fetch
    
    private func fetchFeed(urlString: String, source: String, championship: Championship) async -> [FeedArticle] {
        guard let url = URL(string: urlString), url.scheme == "https" else { return [] }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("GeoRacing/1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return [] }
            
            let parser = RSSParser(source: source, championship: championship)
            return parser.parse(data: data)
        } catch {
            Logger.warning("[FanNews] Feed fetch failed (\(source)): \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Cache
    
    private func saveToCache() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(articles)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        } catch {
            Logger.error("[FanNews] Cache save failed: \(error)")
        }
    }
    
    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            articles = try decoder.decode([FeedArticle].self, from: data)
            let ts = UserDefaults.standard.double(forKey: cacheTimestampKey)
            if ts > 0 { lastRefreshed = Date(timeIntervalSince1970: ts) }
            Logger.debug("[FanNews] Loaded \(articles.count) articles from cache")
        } catch {
            Logger.error("[FanNews] Cache decode failed: \(error)")
        }
    }
}

// MARK: - RSS XML Parser

/// Lightweight RSS/Atom parser using Foundation's XMLParser.
final class RSSParser: NSObject, XMLParserDelegate {
    
    private let source: String
    private let championship: Championship
    
    private var articles: [FeedArticle] = []
    
    // Parsing state
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentImageUrl: String?
    private var isInsideItem = false
    
    // Date formatters for RSS
    private lazy var rssDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return fmt
    }()
    
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt
    }()
    
    init(source: String, championship: Championship) {
        self.source = source
        self.championship = championship
    }
    
    func parse(data: Data) -> [FeedArticle] {
        articles = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" || elementName == "entry" {
            isInsideItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentImageUrl = nil
        }
        
        // Atom link
        if elementName == "link" && isInsideItem, let href = attributeDict["href"] {
            currentLink = href
        }
        
        // Media thumbnail
        if (elementName == "media:thumbnail" || elementName == "media:content"),
           let url = attributeDict["url"] {
            currentImageUrl = url
        }
        
        // Enclosure (some feeds use this for images)
        if elementName == "enclosure",
           let type = attributeDict["type"], type.hasPrefix("image"),
           let url = attributeDict["url"] {
            currentImageUrl = url
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description", "summary", "content": currentDescription += string
        case "pubDate", "published", "updated": currentPubDate += string
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            isInsideItem = false
            
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let link = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !title.isEmpty, !link.isEmpty else { return }
            
            // Parse date
            let dateStr = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
            let date = rssDateFormatter.date(from: dateStr)
                ?? iso8601Formatter.date(from: dateStr)
                ?? Date()
            
            // Clean description (strip HTML)
            let summary = currentDescription
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .strippingHTML()
                .prefix(300)
            
            // Extract image from description if no media tag
            let imageUrl = currentImageUrl ?? extractImageUrl(from: currentDescription)
            
            // Generate stable ID from URL
            let id = link.lowercased().data(using: .utf8).map {
                $0.map { String(format: "%02x", $0) }.joined()
            } ?? UUID().uuidString
            
            let article = FeedArticle(
                id: String(id.prefix(32)),
                title: title,
                summary: String(summary),
                source: source,
                publishedAt: date,
                url: link,
                imageUrl: imageUrl,
                championship: championship,
                tags: []
            )
            
            articles.append(article)
        }
    }
    
    // MARK: - Helpers
    
    /// Extract first image URL from HTML content
    private func extractImageUrl(from html: String) -> String? {
        guard let range = html.range(of: "src=\"", options: .caseInsensitive) else { return nil }
        let after = html[range.upperBound...]
        guard let endRange = after.range(of: "\"") else { return nil }
        let url = String(after[..<endRange.lowerBound])
        return url.hasPrefix("http") ? url : nil
    }
}

// MARK: - HTML Stripping

extension String {
    /// Remove HTML tags from string
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) {
            return attributed.string
        }
        
        // Fallback: regex strip
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/NavigationService.swift`

```swift
import Foundation
import MapKit
import CoreLocation

/// Transport modes for navigation
enum TransportMode: String, CaseIterable {
    case automobile = "car"
    case walking = "walk"
    case transit = "transit"
    
    var icon: String {
        switch self {
        case .automobile: return "car.fill"
        case .walking: return "figure.walk"
        case .transit: return "bus.fill"
        }
    }
    
    var title: String {
        switch self {
        case .automobile: return "Car"
        case .walking: return "On foot"
        case .transit: return "Transit"
        }
    }
    
    @MainActor
    var localizedTitle: String {
        LocalizationUtils.string(title)
    }
    
    var mkDirectionsTransportType: MKDirectionsTransportType {
        switch self {
        case .automobile: return .automobile
        case .walking: return .walking
        case .transit: return .transit
        }
    }
}

/// Route information wrapper
struct NavigationRoute {
    let route: MKRoute
    let destination: CLLocationCoordinate2D
    let destinationName: String
    let transportMode: TransportMode
    
    var distance: CLLocationDistance { route.distance }
    var expectedTravelTime: TimeInterval { route.expectedTravelTime }
    var steps: [MKRoute.Step] { route.steps }
    
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var formattedETA: String {
        let hours = Int(expectedTravelTime) / 3600
        let minutes = (Int(expectedTravelTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Service for calculating navigation routes using MapKit
class NavigationService {
    
    static let shared = NavigationService()
    
    private init() {}
    
    // MARK: - Circuit Destination
    
    /// Circuit de Barcelona-Catalunya main entrance
    static let circuitCoordinate = CLLocationCoordinate2D(latitude: 41.5700, longitude: 2.2611)
    static let circuitName = "Circuit de Barcelona-Catalunya"
    
    // MARK: - Route Calculation
    
    /// Calculate route from user's current location to destination
    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        destinationName: String,
        transportMode: TransportMode
    ) async throws -> NavigationRoute {
        
        let request = MKDirections.Request()
        request.source = MKMapItem.fromCoordinate(origin)
        request.destination = MKMapItem.fromCoordinate(destination)
        request.transportType = transportMode.mkDirectionsTransportType
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw NavigationError.noRouteFound
        }
        
        return NavigationRoute(
            route: route,
            destination: destination,
            destinationName: destinationName,
            transportMode: transportMode
        )
    }
    
    /// Calculate route to the circuit
    func calculateRouteToCircuit(
        from origin: CLLocationCoordinate2D,
        transportMode: TransportMode
    ) async throws -> NavigationRoute {
        try await calculateRoute(
            from: origin,
            to: Self.circuitCoordinate,
            destinationName: Self.circuitName,
            transportMode: transportMode
        )
    }
    
    // MARK: - Open in Apple Maps
    
    /// Open Apple Maps with directions to destination
    func openInAppleMaps(
        destination: CLLocationCoordinate2D,
        destinationName: String,
        transportMode: TransportMode
    ) {
        let destinationItem = MKMapItem.fromCoordinate(destination)
        destinationItem.name = destinationName
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: transportMode.appleMapsDirectionsMode
        ]
        
        destinationItem.openInMaps(launchOptions: launchOptions)
    }
    
    /// Open Apple Maps with directions to the circuit
    func openCircuitInAppleMaps(transportMode: TransportMode) {
        openInAppleMaps(
            destination: Self.circuitCoordinate,
            destinationName: Self.circuitName,
            transportMode: transportMode
        )
    }
}

// MARK: - Transport Mode Apple Maps Extension

extension TransportMode {
    var appleMapsDirectionsMode: String {
        switch self {
        case .automobile: return MKLaunchOptionsDirectionsModeDriving
        case .walking: return MKLaunchOptionsDirectionsModeWalking
        case .transit: return MKLaunchOptionsDirectionsModeTransit
        }
    }
}

// MARK: - Errors

enum NavigationError: LocalizedError {
    case noRouteFound
    case locationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "No se encontró una ruta disponible"
        case .locationNotAvailable:
            return "No se pudo obtener tu ubicación"
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/ParkingService.swift`

```swift
import Foundation

// MARK: - Assignment Service Logic

protocol ParkingAssignmentServiceProtocol {
    func assignParking(licensePlate: String, ticketId: String) async throws -> ParkingAssignment
}

class ParkingAssignmentService: ParkingAssignmentServiceProtocol {
    
    // Simulate capacity for zones (MVP logic)
    private let zoneCapacities: [ParkingZone: Int] = [
        .zoneA: 5500,
        .zoneB: 4500,
        .zoneC: 6500,
        .zoneD: 2500
    ]
    
    // Weights for distribution
    private let zoneWeights: [ParkingZone: Double] = [
        .zoneC: 0.35,
        .zoneA: 0.28,
        .zoneB: 0.25,
        .zoneD: 0.12
    ]
    
    func assignParking(licensePlate: String, ticketId: String) async throws -> ParkingAssignment {
        // 1. Deterministic hashing to select a zone and spot
        let seed = "\(ticketId)-\(licensePlate)".uppercased()
        let hash = abs(seed.hashValue)
        
        // 2. Select Zone based on weights (simplistic weighted random simulation using hash)
        let zone = selectZone(hash: hash)
        
        // 3. Generate Spot ID
        // Format: [Zone]-Fila-[Row]-[Number] or similar. Let's use simple C-4321 style as requested.
        // We use the hash again to determine the number part.
        let spotNumber = (hash % 1000) + 1 // 1...1000
        let spotString = "\(zone.rawValue)-\(String(format: "%04d", spotNumber))"
        
        // Calculate Expiration: End of current day
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60 - 1)
        
        // 4. Create Assignment
        return ParkingAssignment(
            zone: zone,
            virtualSpot: spotString,
            licensePlate: licensePlate,
            ticketId: ticketId,
            createdAt: Date(),
            expirationDate: endOfDay,
            status: .confirmed,
            notes: "Asignación automática basada en ticket."
        )
    }
    
    private func selectZone(hash: Int) -> ParkingZone {
        // Normalized value 0.0 - 1.0 from hash
        let normalized = Double(hash % 100) / 100.0
        
        var cumulative: Double = 0.0
        
        // Order by weight descending to fill largest first effectively in this crude simulation,
        // or just iterate.
        let sortedZones = zoneWeights.sorted { $0.value > $1.value }
        
        for (zone, weight) in sortedZones {
            cumulative += weight
            if normalized <= cumulative {
                return zone
            }
        }
        return .zoneC // Default fallback
    }
}

// MARK: - Repository (Persistence)

protocol ParkingRepositoryProtocol {
    func saveAssignment(_ assignment: ParkingAssignment)
    func getAssignment() -> ParkingAssignment?
    func clearAssignment()
}

struct ParkingStorageContainer: Codable {
    let schemaVersion: Int
    let assignment: ParkingAssignment
}

class ParkingRepository: ParkingRepositoryProtocol {
    
    private let key = "saved_parking_assignment"
    private let currentSchemaVersion = 1
    
    func saveAssignment(_ assignment: ParkingAssignment) {
        let container = ParkingStorageContainer(schemaVersion: currentSchemaVersion, assignment: assignment)
        if let data = try? JSONEncoder().encode(container) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // Cleaned up orphaned code block
    
    func getAssignment() -> ParkingAssignment? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        var retrievedAssignment: ParkingAssignment?
        
        // Try decoding versioned container
        if let container = try? JSONDecoder().decode(ParkingStorageContainer.self, from: data) {
            retrievedAssignment = container.assignment
        }
        // Fallback for legacy
        else if let legacyAssignment = try? JSONDecoder().decode(ParkingAssignment.self, from: data) {
            retrievedAssignment = legacyAssignment
        }
        
        // Valid Expiration Check
        if let assignment = retrievedAssignment {
            if Date() > assignment.expirationDate {
                // Expired: Clear and return nil
                clearAssignment()
                return nil
            }
            return assignment
        }
        
        return nil
    }
    
    func clearAssignment() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/QuestionService.swift`

```swift
import Foundation
import Combine

// MARK: - Question Service

/// Manages quiz questions: remote fetch, caching, rotation, difficulty adjustment.
/// Questions are never repeated until the pool is exhausted.
@MainActor
final class QuestionService: ObservableObject {
    
    static let shared = QuestionService()
    
    // MARK: - Published
    
    @Published private(set) var allQuestions: [QuizQuestion] = []
    @Published private(set) var isLoading = false
    
    // MARK: - State
    
    /// IDs of questions already answered in this rotation cycle
    private var answeredIds: Set<String> = []
    
    /// User's running score for difficulty adjustment
    private var recentCorrectCount: Int = 0
    private var recentTotalCount: Int = 0
    
    /// Persistent keys
    private let cacheKey = "quiz_questions_cache"
    private let answeredKey = "quiz_answered_ids"
    private let statsKey = "quiz_stats"
    
    // MARK: - Config
    
    private let remoteURL: URL? = URL(string: "\(AppConstants.apiBaseUrl)/fanzone/questions")
    private let cacheTTL: TimeInterval = 7 * 86_400 // 7 days
    
    // MARK: - Init
    
    private init() {
        loadAnsweredIds()
        loadStats()
        allQuestions = Self.embeddedQuestions
    }
    
    // MARK: - Public API
    
    /// Load questions: remote → cache → embedded
    func loadQuestions() async {
        isLoading = true
        defer { isLoading = false }
        
        if let remote = await fetchRemote() {
            allQuestions = remote
            saveToCache(remote)
            Logger.info("[QuestionService] Loaded \(remote.count) questions from remote")
            return
        }
        
        if let cached = loadFromCache() {
            allQuestions = cached
            Logger.info("[QuestionService] Loaded \(cached.count) questions from cache")
            return
        }
        
        allQuestions = Self.embeddedQuestions
        Logger.info("[QuestionService] Using \(allQuestions.count) embedded questions")
    }
    
    /// Get next question based on championship, team, and difficulty
    func nextQuestion(
        championship: Championship? = nil,
        teamId: String? = nil,
        targetDifficulty: Int? = nil
    ) -> QuizQuestion? {
        var pool = allQuestions
        
        // Filter by championship
        if let champ = championship {
            pool = pool.filter { $0.championship == champ }
        }
        
        // Filter by team (include general questions too)
        if let team = teamId {
            pool = pool.filter { $0.teamId == nil || $0.teamId == team }
        }
        
        // Filter by validity period
        let now = Date()
        pool = pool.filter { q in
            if let from = q.validFrom, now < from { return false }
            if let to = q.validTo, now > to { return false }
            return true
        }
        
        // Exclude already answered
        let unanswered = pool.filter { !answeredIds.contains($0.id) }
        
        // Reset rotation if all exhausted
        let candidates: [QuizQuestion]
        if unanswered.isEmpty {
            answeredIds.removeAll()
            saveAnsweredIds()
            candidates = pool
        } else {
            candidates = unanswered
        }
        
        guard !candidates.isEmpty else { return nil }
        
        // Difficulty adjustment
        let difficulty = targetDifficulty ?? adaptiveDifficulty()
        let sorted = candidates.sorted {
            abs($0.difficulty - difficulty) < abs($1.difficulty - difficulty)
        }
        
        // Pick from top 5 closest difficulty, randomly
        let topN = min(5, sorted.count)
        return sorted[Int.random(in: 0..<topN)]
    }
    
    /// Get a batch of questions for a quiz session
    func quizSession(
        count: Int = 10,
        championship: Championship? = nil,
        teamId: String? = nil
    ) -> [QuizQuestion] {
        var result: [QuizQuestion] = []
        var usedIds = Set<String>()
        
        for _ in 0..<count {
            var pool = allQuestions
            
            if let champ = championship {
                pool = pool.filter { $0.championship == champ }
            }
            if let team = teamId {
                pool = pool.filter { $0.teamId == nil || $0.teamId == team }
            }
            
            pool = pool.filter { !usedIds.contains($0.id) && !answeredIds.contains($0.id) }
            
            if pool.isEmpty {
                // Reset and retry
                pool = allQuestions
                if let champ = championship { pool = pool.filter { $0.championship == champ } }
                if let team = teamId { pool = pool.filter { $0.teamId == nil || $0.teamId == team } }
                pool = pool.filter { !usedIds.contains($0.id) }
            }
            
            guard let question = pool.randomElement() else { break }
            result.append(question)
            usedIds.insert(question.id)
        }
        
        return result
    }
    
    /// Record an answer
    func recordAnswer(questionId: String, wasCorrect: Bool) {
        answeredIds.insert(questionId)
        recentTotalCount += 1
        if wasCorrect { recentCorrectCount += 1 }
        saveAnsweredIds()
        saveStats()
    }
    
    /// Reset all progress
    func resetProgress() {
        answeredIds.removeAll()
        recentCorrectCount = 0
        recentTotalCount = 0
        saveAnsweredIds()
        saveStats()
    }
    
    /// Current accuracy percentage
    var accuracy: Double {
        guard recentTotalCount > 0 else { return 0 }
        return Double(recentCorrectCount) / Double(recentTotalCount) * 100
    }
    
    /// Total questions answered
    var totalAnswered: Int { recentTotalCount }
    
    /// Current streak (loaded separately if needed)
    var currentStreak: Int {
        UserDefaults.standard.integer(forKey: "quiz_current_streak")
    }
    
    func updateStreak(correct: Bool) {
        if correct {
            UserDefaults.standard.set(currentStreak + 1, forKey: "quiz_current_streak")
        } else {
            let best = max(bestStreak, currentStreak)
            UserDefaults.standard.set(best, forKey: "quiz_best_streak")
            UserDefaults.standard.set(0, forKey: "quiz_current_streak")
        }
    }
    
    var bestStreak: Int {
        UserDefaults.standard.integer(forKey: "quiz_best_streak")
    }
    
    // MARK: - Adaptive Difficulty
    
    private func adaptiveDifficulty() -> Int {
        guard recentTotalCount >= 5 else { return 3 } // Default medium
        let ratio = Double(recentCorrectCount) / Double(recentTotalCount)
        switch ratio {
        case 0.9...: return 5
        case 0.75..<0.9: return 4
        case 0.5..<0.75: return 3
        case 0.3..<0.5: return 2
        default: return 1
        }
    }
    
    // MARK: - Persistence
    
    private func loadAnsweredIds() {
        answeredIds = Set(UserDefaults.standard.stringArray(forKey: answeredKey) ?? [])
    }
    
    private func saveAnsweredIds() {
        UserDefaults.standard.set(Array(answeredIds), forKey: answeredKey)
    }
    
    private func loadStats() {
        recentCorrectCount = UserDefaults.standard.integer(forKey: "\(statsKey)_correct")
        recentTotalCount = UserDefaults.standard.integer(forKey: "\(statsKey)_total")
    }
    
    private func saveStats() {
        UserDefaults.standard.set(recentCorrectCount, forKey: "\(statsKey)_correct")
        UserDefaults.standard.set(recentTotalCount, forKey: "\(statsKey)_total")
    }
    
    // MARK: - Remote
    
    private func fetchRemote() async -> [QuizQuestion]? {
        guard let url = remoteURL else { return nil }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([QuizQuestion].self, from: data)
        } catch {
            Logger.warning("[QuestionService] Remote fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache
    
    private func saveToCache(_ questions: [QuizQuestion]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(questions)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            Logger.error("[QuestionService] Cache save failed: \(error)")
        }
    }
    
    private func loadFromCache() -> [QuizQuestion]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([QuizQuestion].self, from: data)
        } catch {
            Logger.error("[QuestionService] Cache decode failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Embedded Questions (2026 Season)
    
    // swiftlint:disable function_body_length
    static let embeddedQuestions: [QuizQuestion] = [
        // ───── F1 General ─────
        QuizQuestion(id: "f1_gen_01", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many teams are on the F1 2026 grid?",
                     options: ["10", "11", "12", "9"],
                     correctAnswer: 1, explanation: "Cadillac joins as the 11th team for 2026.",
                     difficulty: 1, tags: ["rules", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_02", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which new team joins F1 in 2026?",
                     options: ["Cadillac", "Porsche", "Andretti", "Toyota"],
                     correctAnswer: 0, explanation: "Cadillac (GM) is the 11th team on the 2026 grid.",
                     difficulty: 1, tags: ["2026", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_03", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What major regulation change defines F1 2026?",
                     options: ["Active aerodynamics", "V8 engines", "Wider cars", "No DRS"],
                     correctAnswer: 0, explanation: "2026 introduces active aero with movable front and rear wing elements.",
                     difficulty: 2, tags: ["rules", "tech", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_04", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the new F1 engine formula for 2026?",
                     options: ["1.6L V6 turbo with 50% electric power", "2.0L V6 turbo", "1.6L V6 hybrid (same)", "Full electric"],
                     correctAnswer: 0, explanation: "The 2026 PU splits power roughly 50/50 between ICE and electric motor.",
                     difficulty: 3, tags: ["tech", "rules", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_05", season: 2026, championship: .f1, teamId: nil,
                     type: .trueFalse,
                     prompt: "True or False: The MGU-H is removed from the 2026 power unit.",
                     options: ["True", "False"],
                     correctAnswer: 0, explanation: "The MGU-H has been dropped from the 2026 regulations to reduce costs and attract new manufacturers.",
                     difficulty: 3, tags: ["tech", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_06", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which brand replaces Sauber on the F1 grid in 2026?",
                     options: ["Audi", "Porsche", "BMW", "Lamborghini"],
                     correctAnswer: 0, explanation: "Audi takes over the Sauber entry for 2026.",
                     difficulty: 1, tags: ["teams", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_07", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which fuel will F1 cars use from 2026?",
                     options: ["100% sustainable fuel", "E10 fuel", "Standard gasoline", "Hydrogen"],
                     correctAnswer: 0, explanation: "F1 mandates fully sustainable fuel from 2026 onwards.",
                     difficulty: 2, tags: ["tech", "rules", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_08", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many World Constructors' Championships has Ferrari won?",
                     options: ["16", "12", "21", "8"],
                     correctAnswer: 0, explanation: "Ferrari holds the record with 16 Constructors' Championships.",
                     difficulty: 2, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_09", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Who holds the record for most F1 race wins?",
                     options: ["Lewis Hamilton", "Michael Schumacher", "Max Verstappen", "Ayrton Senna"],
                     correctAnswer: 0, explanation: "Lewis Hamilton holds the all-time record with 100+ Grand Prix victories.",
                     difficulty: 1, tags: ["drivers", "history"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_10", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the minimum weight of an F1 car in 2026 (without driver)?",
                     options: ["768 kg", "798 kg", "740 kg", "820 kg"],
                     correctAnswer: 0, explanation: "The 2026 regulations target a lighter car at approximately 768 kg.",
                     difficulty: 4, tags: ["tech", "rules", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_11", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which circuit hosts the first race of a typical F1 season?",
                     options: ["Bahrain", "Australia", "Saudi Arabia", "Monaco"],
                     correctAnswer: 0, explanation: "Bahrain has become the traditional season opener in recent years.",
                     difficulty: 2, tags: ["circuits"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_12", season: 2026, championship: .f1, teamId: nil,
                     type: .trueFalse,
                     prompt: "True or False: DRS is removed in 2026 F1 regulations.",
                     options: ["True", "False"],
                     correctAnswer: 0, explanation: "DRS is replaced by active aerodynamics in 2026.",
                     difficulty: 3, tags: ["rules", "tech", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_13", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many points does a race winner receive?",
                     options: ["25", "30", "20", "10"],
                     correctAnswer: 0, explanation: "The race winner receives 25 points.",
                     difficulty: 1, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_14", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which driver has the most consecutive World Championships?",
                     options: ["Max Verstappen (4)", "Michael Schumacher (5)", "Sebastian Vettel (4)", "Lewis Hamilton (4)"],
                     correctAnswer: 1, explanation: "Schumacher holds the record with 5 consecutive titles (2000-2004).",
                     difficulty: 3, tags: ["history", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_15", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What does a red flag during a race mean?",
                     options: ["Session stopped", "Last lap", "Pit lane open", "DRS enabled"],
                     correctAnswer: 0, explanation: "A red flag means the session is immediately stopped, usually due to unsafe conditions.",
                     difficulty: 1, tags: ["rules"], validFrom: nil, validTo: nil),
        
        // ───── F1 Team-Specific ─────
        QuizQuestion(id: "f1_fer_01", season: 2026, championship: .f1, teamId: "f1_ferrari",
                     type: .multipleChoice,
                     prompt: "In what year was Scuderia Ferrari founded?",
                     options: ["1929", "1947", "1950", "1935"],
                     correctAnswer: 0, explanation: "Enzo Ferrari founded Scuderia Ferrari in 1929 in Modena, Italy.",
                     difficulty: 3, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_fer_02", season: 2026, championship: .f1, teamId: "f1_ferrari",
                     type: .multipleChoice,
                     prompt: "Who is Ferrari's team principal (2026)?",
                     options: ["Frédéric Vasseur", "Mattia Binotto", "Maurizio Arrivabene", "Stefano Domenicali"],
                     correctAnswer: 0, explanation: "Frédéric Vasseur leads Ferrari since 2023.",
                     difficulty: 2, tags: ["teams", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_rbr_01", season: 2026, championship: .f1, teamId: "f1_red_bull",
                     type: .multipleChoice,
                     prompt: "In what year did Red Bull Racing win their first Constructors' Championship?",
                     options: ["2010", "2008", "2012", "2011"],
                     correctAnswer: 0, explanation: "Red Bull won their first Constructors' title in 2010 with Sebastian Vettel.",
                     difficulty: 2, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_rbr_02", season: 2026, championship: .f1, teamId: "f1_red_bull",
                     type: .multipleChoice,
                     prompt: "What is the name of Red Bull Racing's F1 car factory location?",
                     options: ["Milton Keynes", "Maranello", "Enstone", "Brackley"],
                     correctAnswer: 0, explanation: "Red Bull Racing is based in Milton Keynes, England.",
                     difficulty: 3, tags: ["teams", "trivia"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_mer_01", season: 2026, championship: .f1, teamId: "f1_mercedes",
                     type: .multipleChoice,
                     prompt: "How many consecutive Constructors' Championships did Mercedes win (2014-2021)?",
                     options: ["8", "6", "7", "5"],
                     correctAnswer: 0, explanation: "Mercedes won 8 straight Constructors' titles from 2014 to 2021.",
                     difficulty: 2, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_mcl_01", season: 2026, championship: .f1, teamId: "f1_mclaren",
                     type: .multipleChoice,
                     prompt: "Who was the last World Champion driving for McLaren?",
                     options: ["Lewis Hamilton (2008)", "Mika Häkkinen (1999)", "Ayrton Senna (1991)", "Alain Prost (1989)"],
                     correctAnswer: 0, explanation: "Lewis Hamilton won his first title with McLaren in 2008.",
                     difficulty: 2, tags: ["history", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_amr_01", season: 2026, championship: .f1, teamId: "f1_aston_martin",
                     type: .multipleChoice,
                     prompt: "What was Aston Martin's team name before 2021?",
                     options: ["Racing Point", "Force India", "Jordan", "Spyker"],
                     correctAnswer: 0, explanation: "The team was Racing Point (2019-2020) before becoming Aston Martin in 2021.",
                     difficulty: 2, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_alp_01", season: 2026, championship: .f1, teamId: "f1_alpine",
                     type: .multipleChoice,
                     prompt: "Which manufacturer owns Alpine F1 Team?",
                     options: ["Renault", "Peugeot", "Citroën", "Bugatti"],
                     correctAnswer: 0, explanation: "Alpine is the motorsport brand of the Renault Group.",
                     difficulty: 2, tags: ["teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_wil_01", season: 2026, championship: .f1, teamId: "f1_williams",
                     type: .multipleChoice,
                     prompt: "How many Constructors' Championships has Williams won?",
                     options: ["9", "7", "5", "11"],
                     correctAnswer: 0, explanation: "Williams has won 9 Constructors' Championships in its history.",
                     difficulty: 3, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_haa_01", season: 2026, championship: .f1, teamId: "f1_haas",
                     type: .multipleChoice,
                     prompt: "In what year did Haas F1 Team debut in Formula 1?",
                     options: ["2016", "2018", "2014", "2020"],
                     correctAnswer: 0, explanation: "Haas made their F1 debut in 2016, the first American team in decades.",
                     difficulty: 2, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_cad_01", season: 2026, championship: .f1, teamId: "f1_cadillac",
                     type: .trueFalse,
                     prompt: "True or False: Cadillac is General Motors' first factory F1 entry.",
                     options: ["True", "False"],
                     correctAnswer: 0, explanation: "Cadillac, backed by GM, enters F1 in 2026 as the 11th team.",
                     difficulty: 2, tags: ["teams", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_aud_01", season: 2026, championship: .f1, teamId: "f1_audi",
                     type: .multipleChoice,
                     prompt: "Which team did Audi take over to enter F1 in 2026?",
                     options: ["Sauber", "Williams", "Haas", "Alpine"],
                     correctAnswer: 0, explanation: "Audi acquired the Sauber F1 team to enter the championship in 2026.",
                     difficulty: 1, tags: ["teams", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_circuits_01", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which is the longest circuit on the F1 calendar?",
                     options: ["Spa-Francorchamps", "Silverstone", "Monza", "Jeddah"],
                     correctAnswer: 0, explanation: "Spa-Francorchamps in Belgium is the longest at 7.004 km.",
                     difficulty: 2, tags: ["circuits"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_circuits_02", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "In which country is the Circuit de Barcelona-Catalunya?",
                     options: ["Spain", "Italy", "France", "Portugal"],
                     correctAnswer: 0, explanation: "The Circuit de Barcelona-Catalunya is located in Montmeló, Spain.",
                     difficulty: 1, tags: ["circuits"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_circuits_03", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which F1 circuit is known as 'The Temple of Speed'?",
                     options: ["Monza", "Silverstone", "Spa", "Suzuka"],
                     correctAnswer: 0, explanation: "Monza in Italy is nicknamed 'The Temple of Speed' for its ultra-high velocities.",
                     difficulty: 1, tags: ["circuits", "trivia"], validFrom: nil, validTo: nil),
        
        // ───── MotoGP General ─────
        QuizQuestion(id: "mgp_gen_01", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Who holds the record for most MotoGP premier class titles?",
                     options: ["Giacomo Agostini (8)", "Valentino Rossi (7)", "Marc Márquez (6)", "Mick Doohan (5)"],
                     correctAnswer: 0, explanation: "Giacomo Agostini holds 8 premier class titles (500cc era).",
                     difficulty: 3, tags: ["history", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_02", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What engine configuration do MotoGP bikes use?",
                     options: ["1000cc 4-cylinder", "750cc 3-cylinder", "800cc 4-cylinder", "1200cc V-twin"],
                     correctAnswer: 0, explanation: "MotoGP bikes use 1000cc 4-cylinder engines (inline-4 or V4).",
                     difficulty: 2, tags: ["tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_03", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the maximum number of engines a MotoGP rider can use per season?",
                     options: ["7", "5", "9", "Unlimited"],
                     correctAnswer: 0, explanation: "Each rider is allocated 7 engines per season.",
                     difficulty: 4, tags: ["rules", "tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_04", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which circuit is known as the 'Cathedral of Speed' in MotoGP?",
                     options: ["Mugello", "Assen", "Phillip Island", "Sachsenring"],
                     correctAnswer: 0, explanation: "Mugello in Italy is often called the Cathedral of MotoGP for its iconic status.",
                     difficulty: 2, tags: ["circuits", "trivia"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_05", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many points does a MotoGP race winner receive?",
                     options: ["25", "20", "30", "15"],
                     correctAnswer: 0, explanation: "The winner gets 25 points in a conventional race. Sprint races award fewer.",
                     difficulty: 1, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_06", season: 2026, championship: .motogp, teamId: nil,
                     type: .trueFalse,
                     prompt: "True or False: MotoGP sprint races award half the points of a full race.",
                     options: ["True", "False"],
                     correctAnswer: 1, explanation: "Sprint race points use a different scale — not exactly half. The sprint winner gets 12 points.",
                     difficulty: 3, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_07", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the typical top speed of a MotoGP bike?",
                     options: ["Over 350 km/h", "280 km/h", "300 km/h", "400 km/h"],
                     correctAnswer: 0, explanation: "MotoGP bikes regularly exceed 350 km/h on straights like Mugello.",
                     difficulty: 2, tags: ["tech", "trivia"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_08", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which circuit is known as 'The Cathedral' (oldest circuit) in MotoGP?",
                     options: ["Assen", "Mugello", "Silverstone", "Sachsenring"],
                     correctAnswer: 0, explanation: "Assen is the oldest circuit on the MotoGP calendar, called 'The Cathedral of Motorcycling'.",
                     difficulty: 2, tags: ["circuits", "history"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_09", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many races did Marc Márquez win in his debut MotoGP season (2013)?",
                     options: ["6", "3", "10", "1"],
                     correctAnswer: 0, explanation: "Márquez won 6 races in his rookie MotoGP season to clinch the title at age 20.",
                     difficulty: 4, tags: ["drivers", "history"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_10", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What tire manufacturer is the sole MotoGP supplier?",
                     options: ["Michelin", "Bridgestone", "Pirelli", "Dunlop"],
                     correctAnswer: 0, explanation: "Michelin has been the sole tire supplier for MotoGP since 2016.",
                     difficulty: 1, tags: ["tech"], validFrom: nil, validTo: nil),
        
        // ───── MotoGP Team-Specific ─────
        QuizQuestion(id: "mgp_duc_01", season: 2026, championship: .motogp, teamId: "motogp_ducati_factory",
                     type: .multipleChoice,
                     prompt: "Who scored Ducati's first MotoGP race win?",
                     options: ["Loris Capirossi", "Casey Stoner", "Andrea Dovizioso", "Valentino Rossi"],
                     correctAnswer: 0, explanation: "Loris Capirossi won Ducati's first MotoGP race at Catalunya in 2003.",
                     difficulty: 4, tags: ["history", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_duc_02", season: 2026, championship: .motogp, teamId: "motogp_ducati_factory",
                     type: .multipleChoice,
                     prompt: "What type of engine does the Ducati Desmosedici use?",
                     options: ["V4 90°", "Inline-4", "V4 75°", "V-twin"],
                     correctAnswer: 0, explanation: "The Ducati Desmosedici features a 90-degree V4 engine with desmodromic valves.",
                     difficulty: 3, tags: ["tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_yam_01", season: 2026, championship: .motogp, teamId: "motogp_yamaha_factory",
                     type: .multipleChoice,
                     prompt: "Who won Yamaha's last MotoGP World Championship?",
                     options: ["Fabio Quartararo (2021)", "Valentino Rossi (2009)", "Jorge Lorenzo (2015)", "Ben Spies (2011)"],
                     correctAnswer: 0, explanation: "Fabio Quartararo won the 2021 MotoGP title with Yamaha.",
                     difficulty: 2, tags: ["history", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_hon_01", season: 2026, championship: .motogp, teamId: "motogp_honda_hrc",
                     type: .multipleChoice,
                     prompt: "How many premier class Constructors' titles does Honda have?",
                     options: ["25+", "15", "10", "5"],
                     correctAnswer: 0, explanation: "Honda holds over 25 premier class Constructors' championships (500cc + MotoGP).",
                     difficulty: 3, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_ktm_01", season: 2026, championship: .motogp, teamId: "motogp_ktm_factory",
                     type: .multipleChoice,
                     prompt: "In what year did KTM make their MotoGP debut?",
                     options: ["2017", "2015", "2019", "2020"],
                     correctAnswer: 0, explanation: "KTM entered MotoGP in 2017 with the RC16.",
                     difficulty: 2, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_apr_01", season: 2026, championship: .motogp, teamId: "motogp_aprilia",
                     type: .multipleChoice,
                     prompt: "What engine layout does the Aprilia RS-GP use?",
                     options: ["V4 90°", "Inline-4", "V4 65°", "V-twin"],
                     correctAnswer: 2, explanation: "The Aprilia RS-GP uses a narrow-angle V4 (approximately 65°).",
                     difficulty: 4, tags: ["tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_vr46_01", season: 2026, championship: .motogp, teamId: "motogp_vr46",
                     type: .multipleChoice,
                     prompt: "Who founded the VR46 Racing Team?",
                     options: ["Valentino Rossi", "Luca Marini", "Marco Bezzecchi", "Uccio Salucci"],
                     correctAnswer: 0, explanation: "Valentino Rossi founded VR46 Racing, named after his iconic #46.",
                     difficulty: 1, tags: ["teams", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_trk_01", season: 2026, championship: .motogp, teamId: "motogp_trackhouse",
                     type: .trueFalse,
                     prompt: "True or False: Trackhouse Racing is the first American-owned team in MotoGP.",
                     options: ["True", "False"],
                     correctAnswer: 0, explanation: "Trackhouse Racing, owned by Justin Marks, became the first American-owned MotoGP team.",
                     difficulty: 2, tags: ["teams", "trivia"], validFrom: nil, validTo: nil),
        
        // ───── Mixed / Trivia ─────
        QuizQuestion(id: "mix_01", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which driver won the most Monaco Grand Prix races?",
                     options: ["Ayrton Senna (6)", "Graham Hill (5)", "Michael Schumacher (5)", "Lewis Hamilton (3)"],
                     correctAnswer: 0, explanation: "Ayrton Senna holds the record with 6 Monaco GP victories.",
                     difficulty: 3, tags: ["history", "circuits", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_02", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What color flag indicates dangerous conditions and no overtaking?",
                     options: ["Yellow", "Red", "Blue", "White"],
                     correctAnswer: 0, explanation: "A yellow flag warns of danger ahead and prohibits overtaking.",
                     difficulty: 1, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_03", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What does the black flag with an orange circle mean?",
                     options: ["Mechanical problem, return to pits", "Disqualified", "Penalty", "Last lap"],
                     correctAnswer: 0, explanation: "The meatball flag signals a mechanical problem and the rider must return to the pits.",
                     difficulty: 3, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_04", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the fastest pit stop ever recorded in F1?",
                     options: ["Under 2 seconds", "2.5 seconds", "3 seconds", "4 seconds"],
                     correctAnswer: 0, explanation: "Red Bull holds the record with pit stops under 2 seconds.",
                     difficulty: 2, tags: ["trivia", "tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_05", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the penalty for exceeding track limits 3 times?",
                     options: ["Black and white flag warning", "5-second penalty", "Drive through", "No penalty"],
                     correctAnswer: 0, explanation: "After 3 track limit violations, the driver receives a black and white flag warning.",
                     difficulty: 3, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_06", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is 'arm pump' in MotoGP?",
                     options: ["Compartment syndrome in forearms", "Engine vibration issue", "Tire degradation", "Aerodynamic effect"],
                     correctAnswer: 0, explanation: "Arm pump is compartment syndrome caused by intense braking forces on the forearms.",
                     difficulty: 3, tags: ["tech", "trivia"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_07", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How much downforce does a modern F1 car generate at 250 km/h?",
                     options: ["Over 1000 kg", "500 kg", "300 kg", "200 kg"],
                     correctAnswer: 0, explanation: "Modern F1 cars generate over 1 tonne of downforce at high speed.",
                     difficulty: 4, tags: ["tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_08", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is 'ride height device' in MotoGP?",
                     options: ["Lowers bike for better starts", "Adjusts suspension mid-corner", "Controls wheelie", "Reduces drag"],
                     correctAnswer: 0, explanation: "The ride height device lowers the rear of the bike for better traction off the line.",
                     difficulty: 4, tags: ["tech"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_09", season: 2026, championship: .f1, teamId: nil,
                     type: .trueFalse,
                     prompt: "True or False: F1 drivers can lose up to 3 kg of body weight during a race.",
                     options: ["True", "False"],
                     correctAnswer: 0, explanation: "F1 drivers can lose 2-3 kg through sweating during a race, especially in hot conditions.",
                     difficulty: 2, tags: ["trivia", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mix_10", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What does parc fermé mean in F1?",
                     options: ["No modifications allowed to the car", "Pit lane closure", "Car impounded after race", "Start procedure"],
                     correctAnswer: 0, explanation: "Parc fermé rules prohibit changes to the car between qualifying and the race.",
                     difficulty: 2, tags: ["rules"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_16", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "Which F1 team has won the most Constructors' Championships?",
                     options: ["Ferrari (16)", "McLaren (8)", "Williams (9)", "Mercedes (8)"],
                     correctAnswer: 0, explanation: "Ferrari holds the record with 16 Constructors' Championships.",
                     difficulty: 1, tags: ["history", "teams"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_11", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many MotoGP titles did Valentino Rossi win?",
                     options: ["7", "9", "5", "6"],
                     correctAnswer: 0, explanation: "Valentino Rossi won 7 MotoGP/500cc premier class World Championships.",
                     difficulty: 2, tags: ["history", "drivers"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_12", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the lean angle MotoGP riders can achieve?",
                     options: ["Over 60°", "45°", "50°", "30°"],
                     correctAnswer: 0, explanation: "MotoGP riders regularly lean their bikes beyond 60 degrees in corners.",
                     difficulty: 3, tags: ["tech", "trivia"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_17", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is the cost cap for F1 teams in 2026?",
                     options: ["~$135 million", "$200 million", "$100 million", "No cap"],
                     correctAnswer: 0, explanation: "The F1 cost cap is approximately $135 million, with some exclusions.",
                     difficulty: 4, tags: ["rules", "2026"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "f1_gen_18", season: 2026, championship: .f1, teamId: nil,
                     type: .multipleChoice,
                     prompt: "How many G-forces does an F1 driver experience during heavy braking?",
                     options: ["Up to 6G", "3G", "8G", "2G"],
                     correctAnswer: 0, explanation: "F1 drivers experience up to 6G under heavy braking.",
                     difficulty: 3, tags: ["tech", "trivia"], validFrom: nil, validTo: nil),
        
        QuizQuestion(id: "mgp_gen_13", season: 2026, championship: .motogp, teamId: nil,
                     type: .multipleChoice,
                     prompt: "What is a 'long lap penalty' in MotoGP?",
                     options: ["Extended loop through a wider section of track", "10-second time penalty", "Ride through pit lane", "Position drop"],
                     correctAnswer: 0, explanation: "A long lap penalty requires the rider to take a designated extended loop, costing several seconds.",
                     difficulty: 2, tags: ["rules"], validFrom: nil, validTo: nil),
    ]
    // swiftlint:enable function_body_length
}

```

---

## `iOS_App/GeoRacing/Data/Services/RewardService.swift`

```swift
import Foundation
import Combine

// MARK: - Reward Event Types

/// Events that can trigger card progress
enum RewardEvent: Sendable {
    case quizCorrect
    case quizStreak(Int)
    case quizPerfect
    case firstQuiz
    case fanZoneVisit
    case newsRead
    case teamLoyaltyDay
    case collectionMilestone(Int)
}

// MARK: - Reward Service

/// Manages the collectible card system: catalog, progress, and unlocking.
@MainActor
final class RewardService: ObservableObject {
    
    static let shared = RewardService()
    
    // MARK: - Published
    
    @Published private(set) var cardDefinitions: [RewardCardDefinition] = []
    @Published private(set) var progress: [String: CardProgress] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var recentlyUnlocked: RewardCardDefinition?
    
    // MARK: - Config
    
    private let remoteURL: URL? = URL(string: "\(AppConstants.apiBaseUrl)/fanzone/rewards")
    private let progressKey = "reward_card_progress"
    private let catalogCacheKey = "reward_catalog_cache"
    private let visitDatesKey = "fanzone_visit_dates"
    private let teamLoyaltyKey = "fanzone_team_loyalty"
    
    // MARK: - Init
    
    private init() {
        cardDefinitions = Self.embeddedCards
        loadProgress()
    }
    
    // MARK: - Public API
    
    /// Load card catalog: remote → cache → embedded
    func loadCatalog() async {
        isLoading = true
        defer { isLoading = false }
        
        if let remote = await fetchRemoteCatalog() {
            cardDefinitions = remote
            saveCatalogCache(remote)
            Logger.info("[RewardService] Loaded \(remote.count) cards from remote")
        } else if let cached = loadCatalogCache() {
            cardDefinitions = cached
            Logger.info("[RewardService] Loaded \(cached.count) cards from cache")
        } else {
            Logger.info("[RewardService] Using \(cardDefinitions.count) embedded cards")
        }
        
        // Initialize progress entries for any new cards
        for card in cardDefinitions where progress[card.id] == nil {
            progress[card.id] = CardProgress(id: card.id, currentValue: 0, isUnlocked: false, unlockedAt: nil)
        }
        saveProgress()
    }
    
    /// Record an event and update all relevant card progress
    func recordEvent(_ event: RewardEvent) {
        var newlyUnlocked: RewardCardDefinition?
        
        for card in cardDefinitions {
            guard var prog = progress[card.id], !prog.isUnlocked else { continue }
            
            let shouldIncrement: Bool
            switch (event, card.unlockCondition.type) {
            case (.quizCorrect, .quizTotal):
                shouldIncrement = true
            case (.quizStreak(let streak), .quizStreak):
                shouldIncrement = streak >= card.unlockCondition.threshold
            case (.quizPerfect, .perfectQuiz):
                shouldIncrement = true
            case (.firstQuiz, .firstQuiz):
                shouldIncrement = true
            case (.fanZoneVisit, .fanZoneVisits):
                shouldIncrement = true
            case (.newsRead, .newsRead):
                shouldIncrement = true
            case (.teamLoyaltyDay, .teamLoyalty):
                shouldIncrement = true
            case (.collectionMilestone(let count), .collectionMilestone):
                shouldIncrement = count >= card.unlockCondition.threshold
            default:
                shouldIncrement = false
            }
            
            if shouldIncrement {
                prog.currentValue += 1
                
                if prog.currentValue >= card.unlockCondition.threshold {
                    prog.isUnlocked = true
                    prog.unlockedAt = Date()
                    newlyUnlocked = card
                    Logger.info("[RewardService] Card unlocked: \(card.title)")
                }
                
                progress[card.id] = prog
            }
        }
        
        saveProgress()
        
        if let unlocked = newlyUnlocked {
            recentlyUnlocked = unlocked
            // Check collection milestones
            let totalUnlocked = unlockedCards.count
            recordEvent(.collectionMilestone(totalUnlocked))
        }
    }
    
    /// Record a Fan Zone visit (once per day)
    func recordFanZoneVisit() {
        let today = Calendar.current.startOfDay(for: Date())
        var dates = visitDates
        if !dates.contains(today) {
            dates.append(today)
            UserDefaults.standard.set(dates.map { $0.timeIntervalSince1970 }, forKey: visitDatesKey)
            recordEvent(.fanZoneVisit)
        }
    }
    
    /// Dismiss the "recently unlocked" notification
    func dismissUnlockNotification() {
        recentlyUnlocked = nil
    }
    
    // MARK: - Computed
    
    /// All unlocked cards
    var unlockedCards: [RewardCardDefinition] {
        cardDefinitions.filter { progress[$0.id]?.isUnlocked == true }
    }
    
    /// All locked cards
    var lockedCards: [RewardCardDefinition] {
        cardDefinitions.filter { progress[$0.id]?.isUnlocked != true }
    }
    
    /// Progress for a specific card (0.0 - 1.0)
    func progressRatio(for cardId: String) -> Double {
        guard let prog = progress[cardId],
              let card = cardDefinitions.first(where: { $0.id == cardId }) else { return 0 }
        guard card.unlockCondition.threshold > 0 else { return 0 }
        return min(1.0, Double(prog.currentValue) / Double(card.unlockCondition.threshold))
    }
    
    /// Cards for a specific team (includes global cards)
    func cards(for teamId: String?) -> [RewardCardDefinition] {
        cardDefinitions.filter { $0.teamId == nil || $0.teamId == teamId }
    }
    
    /// Cards filtered by rarity
    func cards(rarity: CardRarity) -> [RewardCardDefinition] {
        cardDefinitions.filter { $0.rarity == rarity }
    }
    
    /// Total collection count string (e.g. "5/20")
    var collectionSummary: String {
        "\(unlockedCards.count)/\(cardDefinitions.count)"
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: progressKey)
        } catch {
            Logger.error("[RewardService] Progress save failed: \(error)")
        }
    }
    
    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else { return }
        do {
            progress = try JSONDecoder().decode([String: CardProgress].self, from: data)
        } catch {
            Logger.error("[RewardService] Progress load failed: \(error)")
        }
    }
    
    private var visitDates: [Date] {
        let timestamps = UserDefaults.standard.array(forKey: visitDatesKey) as? [Double] ?? []
        return timestamps.map { Date(timeIntervalSince1970: $0) }
    }
    
    // MARK: - Remote
    
    private func fetchRemoteCatalog() async -> [RewardCardDefinition]? {
        guard let url = remoteURL else { return nil }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            return try JSONDecoder().decode([RewardCardDefinition].self, from: data)
        } catch {
            Logger.warning("[RewardService] Remote fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveCatalogCache(_ cards: [RewardCardDefinition]) {
        do {
            let data = try JSONEncoder().encode(cards)
            UserDefaults.standard.set(data, forKey: catalogCacheKey)
        } catch {
            Logger.error("[RewardService] Catalog cache save failed: \(error)")
        }
    }
    
    private func loadCatalogCache() -> [RewardCardDefinition]? {
        guard let data = UserDefaults.standard.data(forKey: catalogCacheKey) else { return nil }
        return try? JSONDecoder().decode([RewardCardDefinition].self, from: data)
    }
    
    // MARK: - Embedded Card Catalog (2026)
    
    static let embeddedCards: [RewardCardDefinition] = [
        // ───── Common Cards ─────
        RewardCardDefinition(
            id: "card_first_quiz", teamId: nil, season: 2026, rarity: .common,
            title: "Rookie Driver", description: "Complete your first quiz in Fan Zone.",
            unlockCondition: UnlockCondition(type: .firstQuiz, threshold: 1),
            artTemplate: "template_rookie", badgeIcon: "play.circle.fill",
            number: 1, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_quiz_5", teamId: nil, season: 2026, rarity: .common,
            title: "Knowledge Pit Stop", description: "Answer 5 quiz questions correctly.",
            unlockCondition: UnlockCondition(type: .quizTotal, threshold: 5),
            artTemplate: "template_quiz", badgeIcon: "brain.fill",
            number: 2, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_news_3", teamId: nil, season: 2026, rarity: .common,
            title: "Press Pass", description: "Read 3 news articles.",
            unlockCondition: UnlockCondition(type: .newsRead, threshold: 3),
            artTemplate: "template_news", badgeIcon: "newspaper.fill",
            number: 3, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_visit_1", teamId: nil, season: 2026, rarity: .common,
            title: "Paddock Access", description: "Visit Fan Zone for the first time.",
            unlockCondition: UnlockCondition(type: .fanZoneVisits, threshold: 1),
            artTemplate: "template_visit", badgeIcon: "door.left.hand.open",
            number: 4, totalInSet: 20
        ),
        
        // ───── Rare Cards ─────
        RewardCardDefinition(
            id: "card_quiz_25", teamId: nil, season: 2026, rarity: .rare,
            title: "Race Engineer", description: "Answer 25 questions correctly.",
            unlockCondition: UnlockCondition(type: .quizTotal, threshold: 25),
            artTemplate: "template_engineer", badgeIcon: "wrench.and.screwdriver.fill",
            number: 5, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_streak_5", teamId: nil, season: 2026, rarity: .rare,
            title: "Hot Streak", description: "Answer 5 questions correctly in a row.",
            unlockCondition: UnlockCondition(type: .quizStreak, threshold: 5),
            artTemplate: "template_streak", badgeIcon: "flame.fill",
            number: 6, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_news_10", teamId: nil, season: 2026, rarity: .rare,
            title: "Journalist", description: "Read 10 news articles.",
            unlockCondition: UnlockCondition(type: .newsRead, threshold: 10),
            artTemplate: "template_journalist", badgeIcon: "text.book.closed.fill",
            number: 7, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_visit_3", teamId: nil, season: 2026, rarity: .rare,
            title: "Regular Fan", description: "Visit Fan Zone on 3 different days.",
            unlockCondition: UnlockCondition(type: .fanZoneVisits, threshold: 3),
            artTemplate: "template_fan", badgeIcon: "person.fill.checkmark",
            number: 8, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_loyalty_7", teamId: nil, season: 2026, rarity: .rare,
            title: "Team Loyal", description: "Keep your team for 7 days.",
            unlockCondition: UnlockCondition(type: .teamLoyalty, threshold: 7),
            artTemplate: "template_loyalty", badgeIcon: "heart.fill",
            number: 9, totalInSet: 20
        ),
        
        // ───── Epic Cards ─────
        RewardCardDefinition(
            id: "card_quiz_50", teamId: nil, season: 2026, rarity: .epic,
            title: "Team Principal", description: "Answer 50 questions correctly.",
            unlockCondition: UnlockCondition(type: .quizTotal, threshold: 50),
            artTemplate: "template_principal", badgeIcon: "star.circle.fill",
            number: 10, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_streak_10", teamId: nil, season: 2026, rarity: .epic,
            title: "Pole Position", description: "Answer 10 questions correctly in a row.",
            unlockCondition: UnlockCondition(type: .quizStreak, threshold: 10),
            artTemplate: "template_pole", badgeIcon: "flag.checkered.2.crossed",
            number: 11, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_perfect", teamId: nil, season: 2026, rarity: .epic,
            title: "Grand Slam", description: "Get a perfect score on a quiz session.",
            unlockCondition: UnlockCondition(type: .perfectQuiz, threshold: 1),
            artTemplate: "template_slam", badgeIcon: "trophy.fill",
            number: 12, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_news_25", teamId: nil, season: 2026, rarity: .epic,
            title: "Editor-in-Chief", description: "Read 25 news articles.",
            unlockCondition: UnlockCondition(type: .newsRead, threshold: 25),
            artTemplate: "template_editor", badgeIcon: "doc.text.magnifyingglass",
            number: 13, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_visit_7", teamId: nil, season: 2026, rarity: .epic,
            title: "VIP Pass", description: "Visit Fan Zone on 7 different days.",
            unlockCondition: UnlockCondition(type: .fanZoneVisits, threshold: 7),
            artTemplate: "template_vip", badgeIcon: "crown.fill",
            number: 14, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_collection_5", teamId: nil, season: 2026, rarity: .epic,
            title: "Collector", description: "Unlock 5 cards in your collection.",
            unlockCondition: UnlockCondition(type: .collectionMilestone, threshold: 5),
            artTemplate: "template_collector", badgeIcon: "square.stack.3d.up.fill",
            number: 15, totalInSet: 20
        ),
        
        // ───── Legendary Cards ─────
        RewardCardDefinition(
            id: "card_quiz_100", teamId: nil, season: 2026, rarity: .legendary,
            title: "World Champion", description: "Answer 100 questions correctly.",
            unlockCondition: UnlockCondition(type: .quizTotal, threshold: 100),
            artTemplate: "template_champion", badgeIcon: "medal.fill",
            number: 16, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_streak_20", teamId: nil, season: 2026, rarity: .legendary,
            title: "Dominant Era", description: "Answer 20 questions correctly in a row.",
            unlockCondition: UnlockCondition(type: .quizStreak, threshold: 20),
            artTemplate: "template_dominant", badgeIcon: "bolt.shield.fill",
            number: 17, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_loyalty_30", teamId: nil, season: 2026, rarity: .legendary,
            title: "Lifetime Contract", description: "Keep your team for 30 days.",
            unlockCondition: UnlockCondition(type: .teamLoyalty, threshold: 30),
            artTemplate: "template_lifetime", badgeIcon: "signature",
            number: 18, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_collection_15", teamId: nil, season: 2026, rarity: .legendary,
            title: "Hall of Fame", description: "Unlock 15 cards in your collection.",
            unlockCondition: UnlockCondition(type: .collectionMilestone, threshold: 15),
            artTemplate: "template_hall", badgeIcon: "building.columns.fill",
            number: 19, totalInSet: 20
        ),
        RewardCardDefinition(
            id: "card_news_50", teamId: nil, season: 2026, rarity: .legendary,
            title: "Motorsport Guru", description: "Read 50 news articles.",
            unlockCondition: UnlockCondition(type: .newsRead, threshold: 50),
            artTemplate: "template_guru", badgeIcon: "graduationcap.fill",
            number: 20, totalInSet: 20
        ),
    ]
}

```

---

## `iOS_App/GeoRacing/Data/Services/SpeechService.swift`

```swift
import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    
    // Voices for supported languages
    private var voice: AVSpeechSynthesisVoice? {
        // Prefer Spanish
        return AVSpeechSynthesisVoice(language: "es-ES") ?? AVSpeechSynthesisVoice(language: "en-US")
    }
    
    func speak(_ text: String) {
        // Stop current speech to say new instruction immediately
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.5 // Normal speaking rate
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/TeamAssetManager.swift`

```swift
import Foundation
import SwiftUI
import Combine

// MARK: - Team Asset Manager

/// Downloads, caches, and serves team logos.
/// Pipeline: Memory → Disk → Remote → Local Asset → SF Symbol Fallback
@MainActor
final class TeamAssetManager: ObservableObject {
    
    static let shared = TeamAssetManager()
    
    // MARK: - Config
    
    /// Disk cache TTL (30 days)
    private let cacheTTL: TimeInterval = 30 * 24 * 3600
    
    /// In-memory cache (team ID → UIImage)
    private var memoryCache: [String: UIImage] = [:]
    
    /// Active download tasks (prevent duplicates)
    private var activeTasks: Set<String> = []
    
    /// Disk cache directory
    private lazy var cacheDirectory: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TeamLogos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get logo image for a team. Returns cached or downloads.
    func logo(for team: RacingTeam) -> UIImage? {
        // 1) Memory cache
        if let cached = memoryCache[team.id] {
            return cached
        }
        
        // 2) Disk cache
        if let diskImage = loadFromDisk(teamId: team.id) {
            memoryCache[team.id] = diskImage
            return diskImage
        }
        
        // 3) Local asset bundle
        if let bundled = UIImage(named: team.logo) {
            memoryCache[team.id] = bundled
            return bundled
        }
        
        // 4) Trigger async download if remote URL exists
        if team.logoRemoteUrl != nil && !activeTasks.contains(team.id) {
            Task { await downloadLogo(for: team) }
        }
        
        return nil
    }
    
    /// Pre-load logos for a set of teams
    func preloadLogos(for teams: [RacingTeam]) async {
        await withTaskGroup(of: Void.self) { group in
            for team in teams {
                if memoryCache[team.id] == nil && team.logoRemoteUrl != nil {
                    group.addTask { [weak self] in
                        await self?.downloadLogo(for: team)
                    }
                }
            }
        }
    }
    
    /// Clear all caches
    func clearCache() {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        Logger.info("[TeamAssets] Cache cleared")
    }
    
    // MARK: - Download
    
    private func downloadLogo(for team: RacingTeam) async {
        guard let urlString = team.logoRemoteUrl,
              let url = URL(string: urlString),
              url.scheme == "https" else { return }
        
        guard !activeTasks.contains(team.id) else { return }
        activeTasks.insert(team.id)
        defer { activeTasks.remove(team.id) }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                Logger.warning("[TeamAssets] Download failed for \(team.id)")
                return
            }
            
            // Save to memory + disk
            memoryCache[team.id] = image
            saveToDisk(data: data, teamId: team.id)
            
            Logger.debug("[TeamAssets] Downloaded logo for \(team.id)")
        } catch {
            Logger.warning("[TeamAssets] Download error for \(team.id): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Disk Cache
    
    private func diskCachePath(teamId: String) -> URL {
        cacheDirectory.appendingPathComponent("\(teamId).png")
    }
    
    private func saveToDisk(data: Data, teamId: String) {
        let path = diskCachePath(teamId: teamId)
        do {
            try data.write(to: path)
        } catch {
            Logger.error("[TeamAssets] Disk save failed: \(error)")
        }
    }
    
    private func loadFromDisk(teamId: String) -> UIImage? {
        let path = diskCachePath(teamId: teamId)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        
        // Check TTL
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path.path),
           let modified = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) > cacheTTL {
            try? FileManager.default.removeItem(at: path)
            return nil
        }
        
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - SwiftUI View: Team Logo

/// Displays a team logo with fallback chain:
/// 1. Local asset catalog (SVG vector) via SwiftUI Image
/// 2. Cached/downloaded image via TeamAssetManager
/// 3. SF Symbol fallback in team color
struct TeamLogoView: View {
    let team: RacingTeam
    let size: CGFloat
    
    @ObservedObject private var assetManager = TeamAssetManager.shared
    
    /// Check if a named image exists in the asset catalog
    private var hasLocalAsset: Bool {
        UIImage(named: team.logo) != nil
    }
    
    var body: some View {
        ZStack {
            if hasLocalAsset {
                // Prefer SwiftUI Image for crisp vector SVG rendering
                Image(team.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.1)
            } else if let image = assetManager.logo(for: team) {
                // Downloaded / disk-cached raster image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.1)
            } else {
                // Fallback: SF Symbol in team color circle
                Image(systemName: team.fallbackIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.2)
                    .foregroundColor(team.primarySwiftColor)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(
            Circle()
                .fill(team.primarySwiftColor.opacity(0.1))
        )
        .overlay(
            Circle()
                .stroke(team.primarySwiftColor.opacity(0.5), lineWidth: 1.5)
        )
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/TeamCatalogLoader.swift`

```swift
import Foundation

// MARK: - Team Catalog Loader

/// Loads team catalog from:
/// 1. Remote API (optional)
/// 2. Bundled team_catalog.json (offline-first fallback)
///
/// Works in conjunction with TeamCatalogService.
/// The embedded Swift array in TeamCatalogService is the ultimate fallback;
/// this loader provides a JSON-driven alternative that's easier to update.
@MainActor
final class TeamCatalogLoader {
    
    static let shared = TeamCatalogLoader()
    
    private init() {}
    
    // MARK: - JSON Model (matches team_catalog.json)
    
    private struct CatalogFile: Codable {
        let version: String
        let season: Int
        let lastUpdated: String
        let teams: [TeamEntry]
    }
    
    private struct TeamEntry: Codable {
        let id: String
        let name: String
        let championship: String
        let shortName: String
        let primaryColor: String
        let secondaryColor: String
        let logo: String
        let logoRemoteUrl: String?
        let fallbackIcon: String
        let isActive: Bool
        let season: Int
        let concept: String?
    }
    
    // MARK: - Public API
    
    /// Load teams from the bundled team_catalog.json file.
    /// Returns nil if file not found or parsing fails.
    func loadFromBundle() -> [RacingTeam]? {
        guard let url = Bundle.main.url(forResource: "team_catalog", withExtension: "json") else {
            Logger.warning("[TeamCatalogLoader] team_catalog.json not found in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(CatalogFile.self, from: data)
            
            let teams = catalog.teams.compactMap { entry -> RacingTeam? in
                guard let championship = Championship(rawValue: entry.championship) else {
                    Logger.warning("[TeamCatalogLoader] Unknown championship: \(entry.championship)")
                    return nil
                }
                
                return RacingTeam(
                    id: entry.id,
                    name: entry.name,
                    championship: championship,
                    shortName: entry.shortName,
                    primaryColor: entry.primaryColor,
                    secondaryColor: entry.secondaryColor,
                    logo: entry.logo,
                    logoRemoteUrl: entry.logoRemoteUrl,
                    fallbackIcon: entry.fallbackIcon,
                    isActive: entry.isActive,
                    season: entry.season,
                    lastUpdated: ISO8601DateFormatter().date(from: catalog.lastUpdated) ?? Date()
                )
            }
            
            Logger.info("[TeamCatalogLoader] Loaded \(teams.count) teams from bundle JSON")
            return teams
        } catch {
            Logger.error("[TeamCatalogLoader] Failed to parse team_catalog.json: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Load from a remote URL (for future OTA catalog updates)
    func loadFromRemote(url: URL) async -> [RacingTeam]? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return nil
            }
            
            let catalog = try JSONDecoder().decode(CatalogFile.self, from: data)
            
            return catalog.teams.compactMap { entry -> RacingTeam? in
                guard let championship = Championship(rawValue: entry.championship) else { return nil }
                return RacingTeam(
                    id: entry.id,
                    name: entry.name,
                    championship: championship,
                    shortName: entry.shortName,
                    primaryColor: entry.primaryColor,
                    secondaryColor: entry.secondaryColor,
                    logo: entry.logo,
                    logoRemoteUrl: entry.logoRemoteUrl,
                    fallbackIcon: entry.fallbackIcon,
                    isActive: entry.isActive,
                    season: entry.season,
                    lastUpdated: ISO8601DateFormatter().date(from: catalog.lastUpdated) ?? Date()
                )
            }
        } catch {
            Logger.warning("[TeamCatalogLoader] Remote catalog fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
}

```

---

## `iOS_App/GeoRacing/Data/Services/TeamCatalogService.swift`

```swift
import Foundation
import Combine

// MARK: - Team Catalog Service

/// Loads and caches the team catalog.
/// Priority: Remote → Disk Cache → Embedded Fallback
@MainActor
final class TeamCatalogService: ObservableObject {
    
    static let shared = TeamCatalogService()
    
    // MARK: - Published
    
    @Published private(set) var teams: [RacingTeam] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date?
    
    // MARK: - Config
    
    /// Remote catalog URL (update this to your actual endpoint)
    private let remoteURL: URL? = URL(string: "\(AppConstants.apiBaseUrl)/fanzone/teams")
    
    /// Disk cache key
    private let cacheKey = "team_catalog_cache"
    private let cacheTimestampKey = "team_catalog_timestamp"
    
    /// Cache TTL: 24 hours
    private let cacheTTL: TimeInterval = 86_400
    
    // MARK: - Init
    
    private init() {
        // Start with embedded fallback immediately so UI is never empty
        teams = Self.embeddedCatalog
    }
    
    // MARK: - Public API
    
    /// Load catalog: try remote → cached → bundled JSON → embedded
    func loadCatalog() async {
        isLoading = true
        defer { isLoading = false }
        
        // 1) Try remote
        if let remote = await fetchRemote() {
            teams = remote
            saveToDiskCache(remote)
            lastUpdated = Date()
            Logger.info("[TeamCatalog] Loaded \(remote.count) teams from remote")
            return
        }
        
        // 2) Try disk cache
        if let cached = loadFromDiskCache() {
            teams = cached.teams
            lastUpdated = cached.timestamp
            Logger.info("[TeamCatalog] Loaded \(cached.teams.count) teams from cache")
            return
        }
        
        // 3) Try bundled JSON catalog (team_catalog.json)
        if let bundled = TeamCatalogLoader.shared.loadFromBundle() {
            teams = bundled
            lastUpdated = bundled.first?.lastUpdated
            Logger.info("[TeamCatalog] Loaded \(bundled.count) teams from bundled JSON")
            return
        }
        
        // 4) Embedded fallback (already set in init)
        lastUpdated = nil
        Logger.info("[TeamCatalog] Using embedded catalog (\(teams.count) teams)")
    }
    
    /// Get teams by championship
    func teams(for championship: Championship) -> [RacingTeam] {
        teams.filter { $0.championship == championship && $0.isActive }
    }
    
    /// Find team by ID
    func team(byId id: String) -> RacingTeam? {
        teams.first { $0.id == id }
    }
    
    // MARK: - Remote Fetch
    
    private func fetchRemote() async -> [RacingTeam]? {
        guard let url = remoteURL else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("[TeamCatalog] Remote returned non-200 status")
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([RacingTeam].self, from: data)
        } catch {
            Logger.warning("[TeamCatalog] Remote fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Disk Cache
    
    private func saveToDiskCache(_ teams: [RacingTeam]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(teams)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        } catch {
            Logger.error("[TeamCatalog] Cache save failed: \(error)")
        }
    }
    
    private func loadFromDiskCache() -> (teams: [RacingTeam], timestamp: Date)? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        
        // Check TTL
        guard Date().timeIntervalSince(cacheDate) < cacheTTL else {
            Logger.debug("[TeamCatalog] Cache expired")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let teams = try decoder.decode([RacingTeam].self, from: data)
            return (teams, cacheDate)
        } catch {
            Logger.error("[TeamCatalog] Cache decode failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Embedded Fallback (2026 Season)
    
    // swiftlint:disable function_body_length
    static let embeddedCatalog: [RacingTeam] = {
        let now = Date()
        return [
            // ─────────────────── F1 2026 ───────────────────
            RacingTeam(
                id: "f1_alpine", name: "Alpine", championship: .f1,
                shortName: "ALP", primaryColor: "#0093CC", secondaryColor: "#FF87BC",
                logo: "logo_alpine", logoRemoteUrl: nil, fallbackIcon: "mountain.2.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_aston_martin", name: "Aston Martin", championship: .f1,
                shortName: "AMR", primaryColor: "#006F62", secondaryColor: "#CEDC00",
                logo: "logo_aston_martin", logoRemoteUrl: nil, fallbackIcon: "leaf.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_audi", name: "Audi", championship: .f1,
                shortName: "AUD", primaryColor: "#0F0F0F", secondaryColor: "#E10600",
                logo: "logo_audi", logoRemoteUrl: nil, fallbackIcon: "circle.grid.2x2.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_cadillac", name: "Cadillac", championship: .f1,
                shortName: "CAD", primaryColor: "#1A1A2E", secondaryColor: "#D4AF37",
                logo: "logo_cadillac", logoRemoteUrl: nil, fallbackIcon: "shield.lefthalf.filled",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_ferrari", name: "Ferrari", championship: .f1,
                shortName: "FER", primaryColor: "#DC0000", secondaryColor: "#FFF200",
                logo: "logo_ferrari", logoRemoteUrl: nil, fallbackIcon: "car.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_haas", name: "Haas F1 Team", championship: .f1,
                shortName: "HAA", primaryColor: "#B6BABD", secondaryColor: "#E6002B",
                logo: "logo_haas", logoRemoteUrl: nil, fallbackIcon: "wrench.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_mclaren", name: "McLaren", championship: .f1,
                shortName: "MCL", primaryColor: "#FF8700", secondaryColor: "#47C7FC",
                logo: "logo_mclaren", logoRemoteUrl: nil, fallbackIcon: "flame.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_mercedes", name: "Mercedes", championship: .f1,
                shortName: "MER", primaryColor: "#27F4D2", secondaryColor: "#000000",
                logo: "logo_mercedes", logoRemoteUrl: nil, fallbackIcon: "star.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_racing_bulls", name: "Racing Bulls", championship: .f1,
                shortName: "RCB", primaryColor: "#2B4562", secondaryColor: "#FFFFFF",
                logo: "logo_racing_bulls", logoRemoteUrl: nil, fallbackIcon: "hare.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_red_bull", name: "Red Bull Racing", championship: .f1,
                shortName: "RBR", primaryColor: "#3671C6", secondaryColor: "#FCD700",
                logo: "logo_red_bull", logoRemoteUrl: nil, fallbackIcon: "bolt.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "f1_williams", name: "Williams", championship: .f1,
                shortName: "WIL", primaryColor: "#64C4FF", secondaryColor: "#005AFF",
                logo: "logo_williams", logoRemoteUrl: nil, fallbackIcon: "shield.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            
            // ─────────────────── MotoGP 2026 ───────────────────
            RacingTeam(
                id: "motogp_aprilia", name: "Aprilia Racing", championship: .motogp,
                shortName: "APR", primaryColor: "#000000", secondaryColor: "#E10600",
                logo: "logo_aprilia", logoRemoteUrl: nil, fallbackIcon: "a.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_ducati_factory", name: "Ducati Team", championship: .motogp,
                shortName: "DUC", primaryColor: "#CC0000", secondaryColor: "#FFFFFF",
                logo: "logo_ducati", logoRemoteUrl: nil, fallbackIcon: "bolt.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_gresini", name: "Gresini Racing", championship: .motogp,
                shortName: "GRE", primaryColor: "#0046AD", secondaryColor: "#E10600",
                logo: "logo_gresini", logoRemoteUrl: nil, fallbackIcon: "flag.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_honda_hrc", name: "Honda HRC", championship: .motogp,
                shortName: "HON", primaryColor: "#CC0000", secondaryColor: "#003DA5",
                logo: "logo_honda", logoRemoteUrl: nil, fallbackIcon: "circle.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_pramac", name: "Pramac Racing", championship: .motogp,
                shortName: "PRA", primaryColor: "#7B2D8E", secondaryColor: "#1E90FF",
                logo: "logo_pramac", logoRemoteUrl: nil, fallbackIcon: "p.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_ktm_factory", name: "Red Bull KTM Factory Racing", championship: .motogp,
                shortName: "KTM", primaryColor: "#FF6600", secondaryColor: "#000000",
                logo: "logo_ktm", logoRemoteUrl: nil, fallbackIcon: "flame.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_lcr_honda", name: "LCR Honda", championship: .motogp,
                shortName: "LCR", primaryColor: "#006400", secondaryColor: "#CC0000",
                logo: "logo_lcr", logoRemoteUrl: nil, fallbackIcon: "l.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_vr46", name: "VR46 Racing Team", championship: .motogp,
                shortName: "VR46", primaryColor: "#FFDD00", secondaryColor: "#000000",
                logo: "logo_vr46", logoRemoteUrl: nil, fallbackIcon: "46.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_ktm_tech3", name: "Red Bull KTM Tech3", championship: .motogp,
                shortName: "TE3", primaryColor: "#FF6600", secondaryColor: "#1E3A5F",
                logo: "logo_tech3", logoRemoteUrl: nil, fallbackIcon: "3.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_trackhouse", name: "Trackhouse Racing", championship: .motogp,
                shortName: "TRK", primaryColor: "#5B2C6F", secondaryColor: "#FF4500",
                logo: "logo_trackhouse", logoRemoteUrl: nil, fallbackIcon: "t.circle.fill",
                isActive: true, season: 2026, lastUpdated: now
            ),
            RacingTeam(
                id: "motogp_yamaha_factory", name: "Yamaha Factory Racing", championship: .motogp,
                shortName: "YAM", primaryColor: "#0041C4", secondaryColor: "#FFFFFF",
                logo: "logo_yamaha", logoRemoteUrl: nil, fallbackIcon: "tuningfork",
                isActive: true, season: 2026, lastUpdated: now
            ),
        ]
    }()
    // swiftlint:enable function_body_length
}

```

---

## `iOS_App/GeoRacing/Data/Services/TransportAPIClient.swift`

```swift
import Foundation
import CoreLocation

// MARK: - API Client

class TransportAPIClient {
    static let shared = TransportAPIClient()
    
    // In production, this would be configurable. For now, localhost for simulator needs careful handling.
    // If running on simulator, localhost refers to the Mac.
    private let baseURL = "http://localhost:3000/v1/transport"
    
    func planTrip(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> TransportPlanResponse {
        var components = URLComponents(string: "\(baseURL)/plan")!
        components.queryItems = [
            URLQueryItem(name: "fromLat", value: "\(from.latitude)"),
            URLQueryItem(name: "fromLon", value: "\(from.longitude)"),
            URLQueryItem(name: "toLat", value: "\(to.latitude)"),
            URLQueryItem(name: "toLon", value: "\(to.longitude)"),
            URLQueryItem(name: "arriveBy", value: "false")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(TransportPlanResponse.self, from: data)
    }
    
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Models

struct TransportPlanResponse: Codable {
    let itineraries: [Itinerary]
}

struct Itinerary: Codable, Identifiable {
    let id = UUID()
    let duration: Int // Seconds
    let startTime: Int // Epoch millis
    let endTime: Int // Epoch millis
    let walkTime: Int
    let transitTime: Int
    let legs: [Leg]
    
    private enum CodingKeys: String, CodingKey {
        case duration, startTime, endTime, walkTime, transitTime, legs
    }
}

struct Leg: Codable, Identifiable {
    let id = UUID()
    let mode: String
    let route: String?
    let routeColor: String?
    let routeShortName: String?
    let routeLongName: String?
    let from: Place
    let to: Place
    let realTime: Bool?
    let distance: Double?
    let legGeometry: String? // Encoded polyline usually, but our API returns points string? Needs verification.
    
    private enum CodingKeys: String, CodingKey {
        case mode, route, routeColor, routeShortName, routeLongName, from, to, realTime, distance, legGeometry
    }
    
    var duration: Int {
        guard let start = from.departureTime, let end = to.arrivalTime else { return 0 }
        return (end - start) / 1000
    }
}

struct Place: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let departureTime: Int?
    let arrivalTime: Int?
}

```

---

## `iOS_App/GeoRacing/Data/Services/TransportLocalFallback.swift`

```swift
import Foundation
import CoreLocation

// MARK: - Routing Data Models

struct TransportStop {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let lines: [String]
    let type: StopType
    let timeOffsetFromSants: Int // Minutes from Sants departure for R2N
}

enum StopType {
    case trainStation
    case metroStation // Generic representation for heuristic
    case busStop
}

struct Departure {
    let time: Int // Timestamp
    let line: String
    let destination: String
}

// MARK: - Routing Engine

class TransportLocalFallback {
    static let shared = TransportLocalFallback()
    
    // MARK: - Network Data (R2 Nord Configuration)
    
    private let montmeloStation = TransportStop(
        id: "montmelo", name: "Estación de Montmeló",
        coordinate: CLLocationCoordinate2D(latitude: 41.551, longitude: 2.247),
        lines: ["R2", "R2N"], type: .trainStation, timeOffsetFromSants: 30
    )
    
    // Major R2N Stops (Order: Sants -> North)
    private let networkPoints: [TransportStop] = [
        TransportStop(id: "sants", name: "Barcelona Sants", coordinate: CLLocationCoordinate2D(latitude: 41.379, longitude: 2.140), lines: ["R2N", "L3", "L5"], type: .trainStation, timeOffsetFromSants: 0),
        TransportStop(id: "pdg", name: "Passeig de Gràcia", coordinate: CLLocationCoordinate2D(latitude: 41.392, longitude: 2.165), lines: ["R2N", "L2", "L3", "L4"], type: .trainStation, timeOffsetFromSants: 5),
        TransportStop(id: "clot", name: "El Clot-Aragó", coordinate: CLLocationCoordinate2D(latitude: 41.407, longitude: 2.187), lines: ["R2N", "L1", "L2"], type: .trainStation, timeOffsetFromSants: 9),
        TransportStop(id: "standreu", name: "Sant Andreu Comtal", coordinate: CLLocationCoordinate2D(latitude: 41.436, longitude: 2.190), lines: ["R2N", "L1"], type: .trainStation, timeOffsetFromSants: 14), // Approx
        TransportStop(id: "granollers", name: "Granollers Centre", coordinate: CLLocationCoordinate2D(latitude: 41.597, longitude: 2.290), lines: ["R2N", "R8"], type: .trainStation, timeOffsetFromSants: 38) // North of Circuit
    ]
    
    // MARK: - Public Interface
    
    func generateFallbackItinerary(from userLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Itinerary {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let origin = Place(name: "Tu Ubicación", lat: userLocation.latitude, lon: userLocation.longitude, departureTime: nil, arrivalTime: nil)
        let finalDest = Place(name: "Circuit (Acceso Recomendado)", lat: destination.latitude, lon: destination.longitude, departureTime: nil, arrivalTime: nil)
        
        // 1. Find Optimal Entry Station (Graph Search: Walk vs Metro+Walk)
        let bestPath = calculateBestEntryStation(userLocation: userLocation, startTime: now)
        
        guard let entryStation = bestPath.station else {
            // Fallback: If no station reachable reasonably, assumes close to circuit or error.
            return generateWalkingItinerary(from: origin, to: finalDest, startTime: now)
        }
        
        // 2. Find Next Train for Entry Station
        let arrivalAtStationTime = bestPath.arrivalTime
        let nextTrain = findNextTrain(for: entryStation, after: arrivalAtStationTime)
        
        // 3. Build Itinerary
        var legs: [Leg] = []
        var currentTime = now
        
        // Leg A: Access to Station (Walk or Metro)
        legs.append(contentsOf: bestPath.legs)
        currentTime = nextTrain.departureTime
        
        // Leg B: Train Ride (Entry -> Montmelo)
        let trainTime = abs(montmeloStation.timeOffsetFromSants - entryStation.timeOffsetFromSants) * 60
        // Adjust for Granollers (North -> South)? Assuming South -> North flow mostly for BCN users.
        // Logic handles generic time offsets.
        
        legs.append(Leg(
            mode: "RAIL",
            route: "R2N",
            routeColor: "009900",
            routeShortName: "R2N",
            routeLongName: nextTrain.destination,
            from: Place(name: entryStation.name, lat: entryStation.coordinate.latitude, lon: entryStation.coordinate.longitude, departureTime: nextTrain.departureTime, arrivalTime: nil),
            to: Place(name: montmeloStation.name, lat: montmeloStation.coordinate.latitude, lon: montmeloStation.coordinate.longitude, departureTime: nil, arrivalTime: nextTrain.departureTime + (trainTime * 1000)),
            realTime: true,
            distance: Double(trainTime) * 15.0, // Rough physics
            legGeometry: nil
        ))
        
        currentTime = nextTrain.departureTime + (trainTime * 1000)
        
        // Leg C: Shuttle Bus or Walk from Montmelo to Circuit
        // Shuttle usually runs on F1 weekends. Let's add Shuttle logic if time is right (Daytime).
        let shuttleLegs = generateLastMile(from: montmeloStation, to: finalDest, startTime: currentTime)
        legs.append(contentsOf: shuttleLegs.legs)
        
        let totalDuration = (shuttleLegs.endTime - now) / 1000
        
        // Calculate Totals properly
        let walkTime = legs.filter { $0.mode == "WALK" }.reduce(0) { $0 + ($1.duration) }
        let transitTime = legs.filter { $0.mode != "WALK" }.reduce(0) { $0 + ($1.duration) }
        
        return Itinerary(
            duration: totalDuration,
            startTime: now,
            endTime: shuttleLegs.endTime,
            walkTime: walkTime,
            transitTime: transitTime,
            legs: legs
        )
    }
    
    // MARK: - Logic Core
    
    struct StationPath {
        let station: TransportStop?
        let arrivalTime: Int
        let legs: [Leg]
        let score: Double // Time driven score
    }
    
    // Calculates best way to get to *any* R2N station
    private func calculateBestEntryStation(userLocation: CLLocationCoordinate2D, startTime: Int) -> StationPath {
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        var bestPath: StationPath? = nil
        
        for station in networkPoints {
            let stationLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            let directDistance = userLoc.distance(from: stationLoc)
            
            // Path 1: Direct Walk
            let walkTimeSec = Int(directDistance / 1.2)
            let walkArrival = startTime + (walkTimeSec * 1000)
            
            // Heuristic for Metro: If Walk > 20 mins, assume Metro exists in BCN center
            // Simple generic Metro model: 5 min walk + 5 min wait + (Distance / 30kmh)
            var metroTimeSec = 999999
            if directDistance > 1200 { // Only consider metro if far
                let speedMps = 30.0 * 1000 / 3600 // ~8.3 m/s
                let rideTime = Int(directDistance / speedMps)
                metroTimeSec = 300 + 300 + rideTime // Walk 5 + Wait 5 + Ride
            }
            
            // Check Train Schedule for this station (Wait Time penalty)
            let nextTrain = findNextTrain(for: station, after: min(walkArrival, startTime + (metroTimeSec * 1000)))
            let waitTime = (nextTrain.departureTime - min(walkArrival, startTime + (metroTimeSec * 1000))) / 1000
            
            // Total Time to DEPARTURE (Cost Function)
            // We want to minimize time until we are ON the train
            let costWalk = walkTimeSec + waitTime
            let costMetro = metroTimeSec + waitTime
            
            // Decide Walk vs Metro for THIS station
            let useMetro = costMetro < costWalk
            let finalArrivalAtStation = useMetro ? (startTime + metroTimeSec * 1000) : walkArrival
            let totalCost = useMetro ? costMetro : costWalk
            
            // Compare with other stations
            if bestPath == nil || totalCost < Int(bestPath?.score ?? .infinity) {
                var legs: [Leg] = []
                let origin = Place(name: "Tu Ubicación", lat: userLocation.latitude, lon: userLocation.longitude, departureTime: nil, arrivalTime: nil)
                
                if useMetro {
                    // Walk to Metro
                    legs.append(Leg(mode: "WALK", route: nil, routeColor: nil, routeShortName: nil, routeLongName: nil, from: origin, to: Place(name: "Metro/Bus", lat: 0, lon: 0, departureTime: nil, arrivalTime: nil), realTime: false, distance: 400, legGeometry: nil))
                    // Metro Ride
                    legs.append(Leg(
                        mode: "SUBWAY", route: "L-Metro", routeColor: "FF0000", routeShortName: "Metro", routeLongName: "Dirección \(station.name)",
                        from: Place(name: "Red TMB", lat: 0, lon: 0, departureTime: nil, arrivalTime: nil),
                        to: Place(name: station.name, lat: station.coordinate.latitude, lon: station.coordinate.longitude, departureTime: nil, arrivalTime: nil),
                        realTime: false, distance: directDistance, legGeometry: nil))
                } else {
                    // Walk Direct
                    legs.append(Leg(
                        mode: "WALK", route: nil, routeColor: nil, routeShortName: nil, routeLongName: nil,
                        from: origin,
                        to: Place(name: station.name, lat: station.coordinate.latitude, lon: station.coordinate.longitude, departureTime: nil, arrivalTime: nil),
                        realTime: false, distance: directDistance, legGeometry: nil))
                }
                
                bestPath = StationPath(station: station, arrivalTime: finalArrivalAtStation, legs: legs, score: Double(totalCost))
            }
        }
        
        return bestPath ?? StationPath(station: nil, arrivalTime: 0, legs: [], score: 9999999)
    }
    
    // Finds next R2N departure based on fixed pattern :08 / :38
    private func findNextTrain(for station: TransportStop, after timestamp: Int) -> (departureTime: Int, destination: String) {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Schedule Pattern: Sants departures at :08 and :38
        // Station departure = Sants departure + offset
        let offset = station.timeOffsetFromSants
        
        // Candidates for current hour
        let dep1Candidate = (hour * 60) + 8 + offset
        let dep2Candidate = (hour * 60) + 38 + offset
        
        // Candidates for next hour
        let dep3Candidate = ((hour + 1) * 60) + 8 + offset
        let dep4Candidate = ((hour + 1) * 60) + 38 + offset
        
        let currentMinutesOfDay = (hour * 60) + minute
        
        let candidates = [dep1Candidate, dep2Candidate, dep3Candidate, dep4Candidate]
        
        // Find first candidate > current time
        let nextDepMinutes = candidates.first { $0 > currentMinutesOfDay + 1 } ?? dep3Candidate // +1 min buffer
        
        // Convert back to timestamp
        let nextHour = nextDepMinutes / 60
        let nextMinute = nextDepMinutes % 60
        
        // Construct New Date
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = nextHour
        components.minute = nextMinute
        components.second = 0
        
        let departureDate = calendar.date(from: components) ?? date.addingTimeInterval(1800)
        
        return (Int(departureDate.timeIntervalSince1970 * 1000), "Maçanet-Massanes / St. Celoni")
    }
    
    // Shuttle Bus (Montmeló -> Circuit) - Only on Race Days logic
    private func generateLastMile(from: TransportStop, to: Place, startTime: Int) -> (legs: [Leg], endTime: Int) {
        // Shuttle runs frequently on race days. Approx 10 mins ride.
        // Or walk 25 mins.
        // We propose Shuttle for comfort.
        
        var legs: [Leg] = []
        var currentTime = startTime
        
        // Walk station to shuttle stop (2 mins)
        legs.append(Leg(
            mode: "WALK", route: nil, routeColor: nil, routeShortName: nil, routeLongName: nil,
            from: Place(name: from.name, lat: from.coordinate.latitude, lon: from.coordinate.longitude, departureTime: nil, arrivalTime: nil),
            to: Place(name: "Parada Shuttle F1", lat: from.coordinate.latitude + 0.001, lon: from.coordinate.longitude + 0.001, departureTime: nil, arrivalTime: nil),
            realTime: false, distance: 100, legGeometry: nil
        ))
        currentTime += 120000
        
        // Shuttle Ride
        let rideTimeSec = 600 // 10 mins
        legs.append(Leg(
            mode: "BUS", route: "Shuttle F1", routeColor: "FF0000", routeShortName: "Shuttle F1", routeLongName: "Directo al Circuito",
            from: Place(name: "Parada Shuttle F1", lat: 0, lon: 0, departureTime: currentTime, arrivalTime: nil),
            to: Place(name: "Acceso Circuito", lat: to.lat, lon: to.lon, departureTime: nil, arrivalTime: currentTime + (rideTimeSec * 1000)),
            realTime: true, distance: 2000, legGeometry: nil
        ))
        
        currentTime += (rideTimeSec * 1000)
        
        return (legs, currentTime)
    }
    
    // Fallback for weird cases
    private func generateWalkingItinerary(from: Place, to: Place, startTime: Int) -> Itinerary {
        let dist = CLLocation(latitude: from.lat, longitude: from.lon).distance(from: CLLocation(latitude: to.lat, longitude: to.lon))
        let time = Int(dist / 1.2)
        let leg = Leg(mode: "WALK", route: nil, routeColor: nil, routeShortName: nil, routeLongName: nil, from: from, to: to, realTime: false, distance: dist, legGeometry: nil)
        return Itinerary(duration: time, startTime: startTime, endTime: startTime + time*1000, walkTime: time, transitTime: 0, legs: [leg])
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Features/FeatureRegistry.swift`

```swift
import Foundation
import SwiftUI

// MARK: - Models

public enum FeatureCategory: String, CaseIterable, Identifiable {
    case core = "Core"
    case navigation = "Navegación"
    case social = "Social"
    case fan = "Fan Experience"
    case staff = "Staff & Ops"
    case advanced = "Avanzado"
    case visionary = "Visionario"
    
    public var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .core: return "cpu"
        case .navigation: return "location.fill"
        case .social: return "person.3.fill"
        case .fan: return "star.fill"
        case .staff: return "briefcase.fill"
        case .advanced: return "wand.and.stars"
        case .visionary: return "eye.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .core: return .blue
        case .navigation: return .orange
        case .social: return .green
        case .fan: return .purple
        case .staff: return .gray
        case .advanced: return .indigo
        case .visionary: return .pink
        }
    }
}

public enum FeatureStatus: String, Codable {
    case placeholder = "PLACEHOLDER" // Not started or just a shell
    case basic = "BÁSICO"            // Partially implemented or MVP
    case complete = "COMPLETE"       // Parity achieved / Production ready
    
    var color: Color {
        switch self {
        case .placeholder: return .gray
        case .basic: return .orange
        case .complete: return .green
        }
    }
}

public enum FeatureAudience: String, Codable {
    case `public`
    case staffOnly
}

public struct Feature: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let category: FeatureCategory
    public let priority: Int // 1 (High) to 10 (Low)
    public let status: FeatureStatus
    public let icon: String
    public let audience: FeatureAudience
    
    // UI Helper for Next Steps (Placeholder View)
    public let nextSteps: [String]
    
    public init(id: String, title: String, subtitle: String, category: FeatureCategory, priority: Int, status: FeatureStatus, icon: String, audience: FeatureAudience = .public, nextSteps: [String]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.priority = priority
        self.status = status
        self.icon = icon
        self.audience = audience
        self.nextSteps = nextSteps
    }
}

// MARK: - Registry

/// Single source of truth for all app features and their implementation status.
///
/// **Localization Note:** Feature titles, subtitles, and nextSteps are currently hardcoded
/// in Spanish as domain content. In production, these would be served from a CMS/API
/// and localized server-side, not through `LocalizationUtils`.
public class FeatureRegistry {
    public static let shared = FeatureRegistry()
    
    // Single Source of Truth
    private let _allFeatures: [Feature]
    
    // Public Accessor (Reflects current mode visibility)
    // For now, hardcoded to PUBLIC ONLY.
    public var visibleFeatures: [Feature] {
        return _allFeatures.filter { $0.audience == .public }
    }
    
    private init() {
        self._allFeatures = [
            // --- CORE ---
            Feature(id: "core.circuit_state", title: "Estado del Circuito", subtitle: "Monitorización en tiempo real de banderas y seguridad", category: .core, priority: 1, status: .complete, icon: "flag.fill", nextSteps: ["Optimizar polling", "Añadir histórico"]),
            Feature(id: "core.context_card", title: "Card Contextual", subtitle: "Widgets dinámicos según el estado de carrera", category: .core, priority: 2, status: .complete, icon: "rectangle.grid.1x2.fill", nextSteps: ["Animaciones de transición"]),
            Feature(id: "core.offline_map", title: "Mapa Vivo Offline", subtitle: "Acceso a mapa y POIs sin conexión", category: .core, priority: 3, status: .basic, icon: "map.fill", nextSteps: ["Persistencia completa de tiles", "Sincronización delta"]),
            Feature(id: "core.pois", title: "Puntos de Interés", subtitle: "Filtros y localización de servicios", category: .core, priority: 4, status: .complete, icon: "mappin.and.ellipse", nextSteps: []),
            Feature(id: "core.qr_position", title: "Posicionamiento QR", subtitle: "Escanear para ubicarte en el mapa", category: .core, priority: 5, status: .placeholder, icon: "qrcode.viewfinder", nextSteps: ["Implementar escáner en mapa", "Lógica de triangulación"]),
            Feature(id: "core.ble", title: "Balizas Inteligentes", subtitle: "Detección de zonas por Bluetooth", category: .core, priority: 6, status: .complete, icon: "antenna.radiowaves.left.and.right", nextSteps: ["Calibración fina de RSSI"]),
            Feature(id: "core.offline_mode", title: "Modo Sin Conexión", subtitle: "Funcionalidad completa sin internet", category: .core, priority: 7, status: .basic, icon: "wifi.slash", nextSteps: ["Cola de peticiones POST", "Cacheo de tiendas"]),
            Feature(id: "core.alerts", title: "Centro de Alertas", subtitle: "Historial de notificaciones push", category: .core, priority: 8, status: .basic, icon: "bell.badge.fill", nextSteps: ["Persistencia local de alertas leídas"]),
            Feature(id: "core.notifications", title: "Notificaciones Críticas", subtitle: "Alertas push locales por seguridad", category: .core, priority: 9, status: .complete, icon: "exclamationmark.bubble.fill", nextSteps: []),
            Feature(id: "core.feedback", title: "Incidencias", subtitle: "Reporte de problemas en pista", category: .core, priority: 10, status: .complete, icon: "exclamationmark.triangle.fill", nextSteps: ["Añadir fotos al reporte"]),

            // --- NAVEGACIÓN ---
            Feature(id: "nav.ar_guide", title: "Guía AR al Asiento", subtitle: "Navegación aumentada con cámara", category: .navigation, priority: 1, status: .placeholder, icon: "camera.viewfinder", nextSteps: ["Integrar ARKit", "Mapeo de gradas"]),
            Feature(id: "nav.anticalas", title: "Rutas Anti-colas", subtitle: "Algoritmo de desvío por tráfico", category: .navigation, priority: 2, status: .placeholder, icon: "arrow.triangle.swap", nextSteps: ["Conectar API de afluencia", "Lógica de grafo"]),
            Feature(id: "nav.services", title: "Rutas a Servicios", subtitle: "Camino más rápido a WC/Comida", category: .navigation, priority: 3, status: .placeholder, icon: "figure.walk", nextSteps: ["Implementar OSRM routing", "UX de guiado"]),
            Feature(id: "nav.state_routes", title: "Rutas Dinámicas", subtitle: "Cambio de ruta según estado circuito", category: .navigation, priority: 4, status: .placeholder, icon: "shuffle", nextSteps: ["Lógica de zonas cerradas"]),
            Feature(id: "nav.evacuation", title: "Evacuación Dinámica", subtitle: "Guiado de emergencia a salidas seguras", category: .navigation, priority: 5, status: .complete, icon: "exclamationmark.shield.fill", nextSteps: ["Simulacros"]),

            // --- SOCIAL ---
            Feature(id: "social.follow_group", title: "Seguir al Grupo", subtitle: "Ver ubicación de amigos en tiempo real", category: .social, priority: 1, status: .basic, icon: "person.2.circle.fill", nextSteps: ["Mejorar refresco de posición"]),
            Feature(id: "social.meetup", title: "Punto de Encuentro", subtitle: "Establecer meeting point compartido", category: .social, priority: 2, status: .placeholder, icon: "flag.2.crossed.fill", nextSteps: ["UI de selección en mapa", "Notificación de llegada"]),

            // --- FAN ---
            Feature(id: "fan.immersive", title: "Fan Immersive Mode", subtitle: "Experiencia augmentada durante carrera", category: .fan, priority: 1, status: .placeholder, icon: "headset", nextSteps: ["Audio 3D", "Stats en vivo"]),
            Feature(id: "fan.360", title: "Momento 360", subtitle: "Replay de momentos clave en 360", category: .fan, priority: 2, status: .placeholder, icon: "arrow.triangle.2.circlepath.camera.fill", nextSteps: ["Player de video 360", "Integración content delivery"]),

            // --- STAFF (HIDDEN FOR PUBLIC) ---
            Feature(id: "staff.panel", title: "Panel Interno Staff", subtitle: "Gestión y métricas para operarios", category: .staff, priority: 1, status: .basic, icon: "idcard.fill", audience: .staffOnly, nextSteps: ["Login de staff específico", "Métricas de afluencia"]),
            Feature(id: "staff.beacon_remote", title: "Control Remoto Baliza", subtitle: "Forzar estados de baliza manualmente", category: .staff, priority: 2, status: .placeholder, icon: "remote", audience: .staffOnly, nextSteps: ["API de control", "Permisos de admin"]),
            Feature(id: "staff.safezone", title: "SafeZone Live", subtitle: "Monitorización de áreas seguras", category: .staff, priority: 3, status: .placeholder, icon: "shield.check.fill", audience: .staffOnly, nextSteps: ["Heatmap de densidad"]),

            // --- AVANZADO ---
            Feature(id: "adv.flowsense", title: "FlowSense", subtitle: "Análisis de flujos de movimiento", category: .advanced, priority: 1, status: .placeholder, icon: "wave.3.right", nextSteps: ["Integración CoreMotion"]),
            Feature(id: "adv.ghostpath", title: "GhostPath AR", subtitle: "Sigue la traza fantasma en AR", category: .advanced, priority: 2, status: .placeholder, icon: "ghost.fill", nextSteps: []),
            Feature(id: "adv.clima", title: "ClimaSmart IA", subtitle: "Predicción micro-climática", category: .advanced, priority: 3, status: .placeholder, icon: "cloud.sun.rain.fill", nextSteps: []),
            Feature(id: "adv.soundtags", title: "SoundTags 3D", subtitle: "Audio espacial geolocalizado", category: .advanced, priority: 4, status: .placeholder, icon: "speaker.wave.3.fill", nextSteps: []),
            Feature(id: "adv.ecometer", title: "EcoMeter", subtitle: "Huella de carbono en tiempo real", category: .advanced, priority: 5, status: .placeholder, icon: "leaf.fill", nextSteps: []),
            Feature(id: "adv.ai_qr", title: "QR Inteligentes IA", subtitle: "Códigos contextuales generativos", category: .advanced, priority: 6, status: .placeholder, icon: "qrcode", nextSteps: []),
            Feature(id: "adv.parking", title: "Parking SmartView", subtitle: "Visualización de plazas libres", category: .advanced, priority: 7, status: .placeholder, icon: "parkingsign.circle", nextSteps: []),
            Feature(id: "adv.transport", title: "Transporte Sincro", subtitle: "Shuttles coordinados con carrera", category: .advanced, priority: 8, status: .placeholder, icon: "bus.fill", nextSteps: []),
            Feature(id: "adv.adv_alerts", title: "Alertas Avanzadas", subtitle: "Priorización por IA", category: .advanced, priority: 9, status: .placeholder, icon: "bell.and.waves.left.and.right", nextSteps: []),
            Feature(id: "adv.follow_pilot", title: "Sigue al Piloto", subtitle: "Tracking específico de corredor", category: .advanced, priority: 10, status: .placeholder, icon: "helmet.fill", nextSteps: []),

            // --- VISIONARIO ---
            Feature(id: "vis.detect", title: "GeoRacing Neural Network", subtitle: "Cerebro central de operaciones", category: .visionary, priority: 1, status: .placeholder, icon: "network", nextSteps: []),
            Feature(id: "vis.heatmap", title: "EmoHeatmap", subtitle: "Mapa de calor emocional del público", category: .visionary, priority: 2, status: .placeholder, icon: "heart.fill", nextSteps: []),
            Feature(id: "vis.ticket_ar", title: "Ticket AR", subtitle: "Entrada holográfica", category: .visionary, priority: 3, status: .placeholder, icon: "ticket.fill", nextSteps: []),
            Feature(id: "vis.pulse", title: "Fan Pulse", subtitle: "Ritmo cardíaco colectivo", category: .visionary, priority: 4, status: .placeholder, icon: "waveform.path.ecg", nextSteps: []),
            Feature(id: "vis.chat_ai", title: "Chat IA Contextual", subtitle: "Asistente inteligente de carrera", category: .visionary, priority: 5, status: .placeholder, icon: "message.and.waveform.fill", nextSteps: []),
            Feature(id: "vis.glasses", title: "Modo Gafas AR", subtitle: "Segunda pantalla en gafas", category: .visionary, priority: 6, status: .placeholder, icon: "eyeglasses", nextSteps: []),
            Feature(id: "vis.cooling", title: "Smart Cooling", subtitle: "Gestión de zonas de frescor", category: .visionary, priority: 7, status: .placeholder, icon: "thermometer.snowflake", nextSteps: []),
            Feature(id: "vis.solar", title: "Puntos Solar", subtitle: "Carga verde optimizada", category: .visionary, priority: 8, status: .placeholder, icon: "sun.max.fill", nextSteps: [])
        ]
    }
    
    // Helpers
    public func features(for category: FeatureCategory) -> [Feature] {
        visibleFeatures.filter { $0.category == category }.sorted { $0.priority < $1.priority }
    }
    
    public func totalCount(for category: FeatureCategory) -> Int {
        features(for: category).count
    }
    
    public func completedCount(for category: FeatureCategory) -> Int {
        features(for: category).filter { $0.status == .complete }.count
    }
    
    public func feature(id: String) -> Feature? {
        visibleFeatures.first { $0.id == id }
    }
    
    // Admin/Internal Accessor if needed
    public func allFeaturesIncludingHidden() -> [Feature] {
        _allFeatures
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Features/FeatureViewFactory.swift`

```swift
import SwiftUI

struct FeatureViewFactory {
    
    @ViewBuilder
    static func view(for feature: Feature) -> some View {
        // Here we map Feature IDs to real implementations if they exist.
        // Otherwise, we return the FeaturePlaceholderView.
        
        switch feature.id {
            
        // --- CORE ---
        case "core.notifications", "core.alerts":
            AlertsView()
        
        case "core.pois", "core.offline_map":
            CircuitMapView()
            
        case "core.poi_list":
            PoiListView()
            
        case "core.feedback":
            IncidentReportView()
            
        case "core.qr_position", "social.qr_share":
            SocialView()
            
        case "core.qr_scanner":
            QRScannerView { _ in }
            
        // --- NAVIGATION ---
        case "nav.evacuation":
            EvacuationView()
            
        // --- SOCIAL ---
        case "social.follow_group":
            GroupView()
            
        // --- COMMERCE ---
        case "commerce.orders", "commerce.shop":
            OrdersView()
            
        case "commerce.history", "commerce.my_orders":
            MyOrdersView()
            
        // --- SETTINGS ---
        case "settings.seat", "seat.setup":
            SeatSetupView()
            
        case "settings.main":
            SettingsView()
            
        // --- STAFF ---
        case "staff.panel", "staff.mode":
            StaffModeView()
            
        // --- ROADMAP ---
        case "roadmap", "app.roadmap":
            RoadmapView()
            
        // --- DEFAULT / PLACEHOLDER ---
        default:
            FeaturePlaceholderView(feature: feature)
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Models/AppUser.swift`

```swift
import Foundation

struct AppUser: Codable, Identifiable, Sendable {
    let uid: String
    let email: String
    let displayName: String?
    let photoURL: String?
    
    var id: String { uid }
}

```

---

## `iOS_App/GeoRacing/Domain/Models/BeaconModels.swift`

```swift
// Legacy placeholder for beacon-related models.
// Active implementations live in MapModels.swift (BeaconConfig).

```

---

## `iOS_App/GeoRacing/Domain/Models/CircuitModels.swift`

```swift
import Foundation
import CoreLocation

public struct MapBounds: Sendable {
    public let minLat: Double
    public let maxLat: Double
    public let minLon: Double
    public let maxLon: Double
    
    public init(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        self.minLat = minLat
        self.maxLat = maxLat
        self.minLon = minLon
        self.maxLon = maxLon
    }
    
    public var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
    }
}

public struct Circuit: Sendable {
    public let name: String
    public let bounds: MapBounds
    public let imageAssetName: String // e.g. "circuit_map"
    
    public init(name: String, bounds: MapBounds, imageAssetName: String) {
        self.name = name
        self.bounds = bounds
        self.imageAssetName = imageAssetName
    }
    
    // Default circuit configuration (Barcelona-Catalunya as placeholder/defaults)
    public static let montmelo = Circuit(
        name: "Circuit de Barcelona-Catalunya",
        bounds: MapBounds(
            minLat: 41.565,
            maxLat: 41.575,
            minLon: 2.250,
            maxLon: 2.265
        ),
        imageAssetName: "circuit_overlay"
    )
}

```

---

## `iOS_App/GeoRacing/Domain/Models/FanZoneModels.swift`

```swift
import Foundation
import SwiftUI

// MARK: - Championship

/// Championship type (F1 or MotoGP)
enum Championship: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case f1 = "F1"
    case motogp = "MotoGP"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .f1: return "Formula 1"
        case .motogp: return "MotoGP"
        }
    }
    
    var icon: String {
        switch self {
        case .f1: return "car.fill"
        case .motogp: return "bicycle"
        }
    }
}

// MARK: - Racing Team

/// A team in the catalog (F1 or MotoGP)
struct RacingTeam: Identifiable, Codable, Hashable, Sendable {
    let id: String               // e.g. "f1_ferrari", "motogp_ducati_factory"
    let name: String             // "Ferrari"
    let championship: Championship
    let shortName: String        // "FER"
    let primaryColor: String     // hex "#DC0000"
    let secondaryColor: String   // hex "#FFF200"
    let logo: String             // local asset name
    let logoRemoteUrl: String?   // optional remote URL
    let fallbackIcon: String     // SF Symbol fallback
    let isActive: Bool
    let season: Int
    let lastUpdated: Date
    
    /// Convert hex string to SwiftUI Color
    var primarySwiftColor: Color {
        Color(hex: primaryColor)
    }
    
    var secondarySwiftColor: Color {
        Color(hex: secondaryColor)
    }
    
    /// Gradient for UI backgrounds
    var gradient: LinearGradient {
        LinearGradient(
            colors: [primarySwiftColor.opacity(0.7), primarySwiftColor.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Quiz Question

/// Question types for trivia
enum QuestionType: String, Codable, CaseIterable, Sendable {
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"
}

/// A quiz question with metadata
struct QuizQuestion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let season: Int
    let championship: Championship
    let teamId: String?          // nil = general question
    let type: QuestionType
    let prompt: String
    let options: [String]
    let correctAnswer: Int       // index into options[]
    let explanation: String
    let difficulty: Int          // 1-5
    let tags: [String]           // ["history", "drivers", "circuits", "rules", "tech", "trivia"]
    let validFrom: Date?
    let validTo: Date?
}

// MARK: - Feed Article (News)

/// A normalized news article from RSS or API
struct FeedArticle: Identifiable, Codable, Hashable, Sendable {
    let id: String              // SHA256 hash of url
    let title: String
    let summary: String
    let source: String          // "Motorsport.com", "Autosport"
    let publishedAt: Date
    let url: String
    let imageUrl: String?
    let championship: Championship
    let tags: [String]          // team, driver, circuit tags
    
    /// Deduplicate by URL
    static func deduplicateURL(_ articles: [FeedArticle]) -> [FeedArticle] {
        var seen = Set<String>()
        return articles.filter { article in
            let key = article.url.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
    
    /// Deduplicate by similar title (Levenshtein threshold)
    static func deduplicateTitle(_ articles: [FeedArticle], threshold: Double = 0.85) -> [FeedArticle] {
        var result: [FeedArticle] = []
        for article in articles {
            let isDuplicate = result.contains { existing in
                existing.title.lowercased().similarityTo(article.title.lowercased()) > threshold
            }
            if !isDuplicate {
                result.append(article)
            }
        }
        return result
    }
}

// MARK: - Reward Card

/// Card rarity levels
enum CardRarity: String, Codable, CaseIterable, Comparable, Sendable {
    case common
    case rare
    case epic
    case legendary
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var frameGradient: LinearGradient {
        switch self {
        case .common:
            return LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        case .rare:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .epic:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .legendary:
            return LinearGradient(colors: [.orange, .yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var sortOrder: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }
    
    static func < (lhs: CardRarity, rhs: CardRarity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

/// Unlock condition types
enum UnlockConditionType: String, Codable, Sendable {
    case quizStreak          // Answer N correct in a row
    case quizTotal           // Answer N total correct
    case fanZoneVisits       // Visit Fan Zone on N different days
    case newsRead            // Read N news articles
    case firstQuiz           // Complete first quiz
    case perfectQuiz         // Get 100% on a quiz session
    case teamLoyalty         // Keep same team for N days
    case eventAttendance     // Be at a circuit event
    case collectionMilestone // Unlock N other cards
}

/// Describes what the user must do to unlock a card
struct UnlockCondition: Codable, Hashable, Sendable {
    let type: UnlockConditionType
    let threshold: Int
    
    var description: String {
        switch type {
        case .quizStreak: return "Answer \(threshold) questions correctly in a row"
        case .quizTotal: return "Answer \(threshold) questions correctly"
        case .fanZoneVisits: return "Visit Fan Zone \(threshold) days"
        case .newsRead: return "Read \(threshold) news articles"
        case .firstQuiz: return "Complete your first quiz"
        case .perfectQuiz: return "Get a perfect score on a quiz"
        case .teamLoyalty: return "Keep your team for \(threshold) days"
        case .eventAttendance: return "Attend a circuit event"
        case .collectionMilestone: return "Unlock \(threshold) cards"
        }
    }
    
    /// Localized description (call from @MainActor context only)
    @MainActor
    var localizedDescription: String {
        LocalizationUtils.string(description)
    }
}

/// A collectible reward card definition (from catalog)
struct RewardCardDefinition: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let teamId: String?        // nil = global card
    let season: Int
    let rarity: CardRarity
    let title: String
    let description: String
    let unlockCondition: UnlockCondition
    let artTemplate: String    // template name for rendering
    let badgeIcon: String?     // SF Symbol
    let number: Int            // card number in collection
    let totalInSet: Int        // total cards in this set
}

/// User's progress toward unlocking a card
struct CardProgress: Codable, Identifiable, Sendable {
    let id: String             // matches RewardCardDefinition.id
    var currentValue: Int      // current progress count
    var isUnlocked: Bool
    var unlockedAt: Date?
    
    var progress: Double {
        return 1.0 // placeholder; actual progress computed via condition threshold
    }
}

// MARK: - Color Hex Extension

extension Color {
    /// Convert Color to hex string
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - String Similarity (for news dedup)

extension String {
    /// Jaccard similarity coefficient for quick title comparison
    func similarityTo(_ other: String) -> Double {
        let set1 = Set(self.split(separator: " ").map { $0.lowercased() })
        let set2 = Set(other.split(separator: " ").map { $0.lowercased() })
        guard !set1.isEmpty || !set2.isEmpty else { return 1.0 }
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        return Double(intersection) / Double(union)
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Models/GroupModels.swift`

```swift
import Foundation
import CoreLocation

struct Group: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let ownerId: String
    let members: [String] // User IDs
}

struct GroupMember: Identifiable, Codable, Sendable {
    let id: String // User ID
    let displayName: String
    let coordinate: CLLocationCoordinate2D?
    let isSharing: Bool
    
    // Custom coding for Coordinate
    enum CodingKeys: String, CodingKey {
        case id, displayName, latitude, longitude, isSharing
    }
    
    public init(id: String, displayName: String, coordinate: CLLocationCoordinate2D?, isSharing: Bool) {
        self.id = id
        self.displayName = displayName
        self.coordinate = coordinate
        self.isSharing = isSharing
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        isSharing = try container.decode(Bool.self, forKey: .isSharing)
        
        if let lat = try? container.decode(Double.self, forKey: .latitude),
           let lon = try? container.decode(Double.self, forKey: .longitude) {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(isSharing, forKey: .isSharing)
        if let coord = coordinate {
            try container.encode(coord.latitude, forKey: .latitude)
            try container.encode(coord.longitude, forKey: .longitude)
        }
    }
}

// ShareSession is defined in SocialModels.swift

```

---

## `iOS_App/GeoRacing/Domain/Models/MapModels.swift`

```swift
import Foundation
import CoreLocation

public enum PoiType: String, Codable, CaseIterable, Sendable {
    case wc = "WC"
    case food = "FOOD"
    case parking = "PARKING"
    case grandstand = "GRANDSTAND"
    case medical = "MEDICAL"
    case merch = "MERCH"
    case access = "ACCESS"
    case exit = "EXIT"
    case gate = "GATE"
    case fanzone = "FANZONE"
    case service = "SERVICE"
    case other = "OTHER"
}

public struct Poi: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let type: PoiType
    public let description: String?
    public let zone: String?
    public let mapX: Float
    public let mapY: Float
    
    // Optional: for cases where we have lat/lon logic, but mapX/Y is primary for image overlay
    public var coordinate: CLLocationCoordinate2D? = nil // Not Codable by default
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description, zone
        case mapX = "map_x"
        case mapY = "map_y"
    }
    
    // Helper init for mapping from DTO
    init(from dto: PoiDto) {
        self.id = dto.id
        self.name = dto.name
        self.type = PoiType(rawValue: dto.type) ?? .other
        self.description = dto.description
        self.zone = dto.zone
        self.mapX = Float(dto.map_x)
        self.mapY = Float(dto.map_y)
    }
}

public struct BeaconConfig: Identifiable, Codable, Sendable {
    public let id: String
    public let uuid: String
    public let major: Int
    public let minor: Int
    public let name: String
    public let mapX: Float
    public let mapY: Float
    
    enum CodingKeys: String, CodingKey {
        case id, uuid, major, minor, name
        case mapX = "map_x"
        case mapY = "map_y"
    }
    
    init(from dto: BeaconDto) {
        self.id = dto.id
        self.uuid = dto.uuid
        self.major = dto.major
        self.minor = dto.minor
        self.name = dto.name
        self.mapX = Float(dto.map_x)
        self.mapY = Float(dto.map_y)
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Models/ParkingModels.swift`

```swift
import Foundation

// MARK: - Models

public enum ParkingZone: String, Codable, CaseIterable, Identifiable {
    case zoneA = "A"
    case zoneB = "B"
    case zoneC = "C"
    case zoneD = "D"
    
    public var id: String { rawValue }
    
    var displayName: String {
        return "Zona \(rawValue)"
    }
    
    var colorName: String {
        // In a real app, these would map to Asset colors
        switch self {
        case .zoneA: return "Red"
        case .zoneB: return "Blue"
        case .zoneC: return "Green"
        case .zoneD: return "Yellow"
        }
    }
}

public enum AssignmentStatus: String, Codable {
    case pending
    case confirmed
    case expired
}

public struct ParkingAssignment: Codable, Identifiable {
    public let id: UUID
    public let zone: ParkingZone
    public let virtualSpot: String // e.g., "C-4321"
    public let licensePlate: String
    public let ticketId: String
    public let createdAt: Date
    public let expirationDate: Date
    public var status: AssignmentStatus
    public let notes: String?
    
    public init(id: UUID = UUID(), zone: ParkingZone, virtualSpot: String, licensePlate: String, ticketId: String, createdAt: Date = Date(), expirationDate: Date, status: AssignmentStatus = .confirmed, notes: String? = nil) {
        self.id = id
        self.zone = zone
        self.virtualSpot = virtualSpot
        self.licensePlate = licensePlate
        self.ticketId = ticketId
        self.createdAt = createdAt
        self.expirationDate = expirationDate
        self.status = status
        self.notes = notes
    }
}

public struct TicketInfo: Codable {
    public let ticketId: String
    public let eventName: String?
    public let eventDate: Date?
    
    public init(ticketId: String, eventName: String? = nil, eventDate: Date? = nil) {
        self.ticketId = ticketId
        self.eventName = eventName
        self.eventDate = eventDate
    }
}

public enum ParkingError: LocalizedError {
    case invalidLicensePlate
    case invalidTicket
    case persistenceFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidLicensePlate:
            return "Invalid license plate."
        case .invalidTicket:
            return "Invalid ticket."
        case .persistenceFailed:
            return "Could not save the assignment."
        case .unknown:
            return "An unknown error occurred."
        }
    }
    
    @MainActor
    public var localizedErrorDescription: String {
        LocalizationUtils.string(errorDescription ?? "")
    }
}

// Placeholder for future multi-event support
public struct ParkingEventContext: Codable {
    public let eventId: String
    public let eventDate: Date?
    
    public init(eventId: String, eventDate: Date? = nil) {
        self.eventId = eventId
        self.eventDate = eventDate
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Models/PoiModels.swift`

```swift
// Legacy placeholder for POI models.
// Actual Point of Interest definitions live in MapModels.swift.

```

---

## `iOS_App/GeoRacing/Domain/Models/RouteModels.swift`

```swift
import Foundation
import CoreLocation

// Domain Models

public struct RouteResult: Codable, Identifiable {
    public let id: UUID
    public let geometry: [CLLocationCoordinate2D]
    public let duration: TimeInterval
    public let distance: Double
    public let steps: [RouteStep]
    
    public init(id: UUID = UUID(), geometry: [CLLocationCoordinate2D], duration: TimeInterval, distance: Double, steps: [RouteStep]) {
        self.id = id
        self.geometry = geometry
        self.duration = duration
        self.distance = distance
        self.steps = steps
    }

    enum CodingKeys: String, CodingKey {
        case id, geometry, duration, distance, steps
    }
    
    // Explicitly decode geometry as [[Double]] and convert to [CLLocationCoordinate2D]
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        distance = try container.decode(Double.self, forKey: .distance)
        steps = try container.decode([RouteStep].self, forKey: .steps)
        
        // Decode geometry
        let coords = try container.decode([[Double]].self, forKey: .geometry)
        geometry = coords.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }
    
    // Explicitly encode geometry as [[Double]]
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(duration, forKey: .duration)
        try container.encode(distance, forKey: .distance)
        try container.encode(steps, forKey: .steps)
        
        let coords = geometry.map { [$0.latitude, $0.longitude] }
        try container.encode(coords, forKey: .geometry)
    }
}

public struct RouteStep: Codable, Identifiable {
    public var id = UUID()
    public let instruction: String
    public let distance: Double
    public let duration: TimeInterval
    public let maneuverType: String
    public let maneuverModifier: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case instruction
        case distance
        case duration
        case maneuverType = "maneuver_type"
        case maneuverModifier = "maneuver_modifier"
    }
    
    // Simpler fix:
    // var id = UUID()

}

public struct SnapResult {
    public let snappedLocation: CLLocationCoordinate2D
    public let routeIndex: Int
    public let distanceToRoute: Double // In meters
    public let isSuccessful: Bool
    
    public init(snappedLocation: CLLocationCoordinate2D, routeIndex: Int, distanceToRoute: Double, isSuccessful: Bool) {
        self.snappedLocation = snappedLocation
        self.routeIndex = routeIndex
        self.distanceToRoute = distanceToRoute
        self.isSuccessful = isSuccessful
    }
}

// OSRM DTOs (Data Transfer Objects) - Internal to Data Layer usually, 
// but putting here for visibility in this "Models" file for now or separate file.

struct OSRMResponse: Codable {
    let routes: [OSRMRoute]
    let code: String
}

struct OSRMRoute: Codable {
    let geometry: String // Polyline6 string
    let legs: [OSRMLeg]
    let distance: Double
    let duration: Double
}

struct OSRMLeg: Codable {
    let steps: [OSRMStep]
    let distance: Double
    let duration: Double
}

struct OSRMStep: Codable {
    let geometry: String // Polyline6 for this step
    let maneuver: OSRMManeuver
    let distance: Double
    let duration: Double
    let name: String
}

struct OSRMManeuver: Codable {
    let type: String
    let modifier: String?
    let location: [Double] // [lon, lat]
}

```

---

## `iOS_App/GeoRacing/Domain/Models/ServiceModels.swift`

```swift
import Foundation

// Product and CartItem are defined in ShopModels.swift and CartManager logic is in Domain/Services/CartManager.swift

// MARK: - Incidents

enum IncidentCategory: String, Codable, CaseIterable {
    case medical = "MEDICAL"
    case security = "SECURITY"
    case cleaning = "CLEANING"
    case maintenance = "MAINTENANCE"
}

struct Incident: Codable, Identifiable {
    let id: String
    let userId: String
    let description: String
    let category: IncidentCategory
    let timestamp: Date
    let photoCount: Int
    
    // Status?
}

```

---

## `iOS_App/GeoRacing/Domain/Models/ShopModels.swift`

```swift
import Foundation

struct Product: Identifiable, Codable, Sendable {
    let id: String
    let productId: String? // Nullable in DB
    let name: String
    let description: String
    let price: Double
    let stock: Int
    let category: String
    let imageUrl: String? // "image_url"
    let emoji: String?
    let isActive: Bool // "is_active" 1/0
    
    // API Mapping
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case name, description, price, stock, category, emoji
        case imageUrl = "image_url"
        case isActive = "is_active"
    }
    
    // Memberwise Init
    init(id: String, productId: String?, name: String, description: String, price: Double, stock: Int, category: String, imageUrl: String?, emoji: String?, isActive: Bool) {
        self.id = id
        self.productId = productId
        self.name = name
        self.description = description
        self.price = price
        self.stock = stock
        self.category = category
        self.imageUrl = imageUrl
        self.emoji = emoji
        self.isActive = isActive
    }

    // Custom decoding to handle Int/Bool 1/0 and optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // Relaxed decoding for product_id
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        name = try container.decode(String.self, forKey: .name)
        
        // Relaxed decoding for optional/nullable fields
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        stock = try container.decodeIfPresent(Int.self, forKey: .stock) ?? 0
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "General"
        
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        emoji = try? container.decode(String.self, forKey: .emoji)
        
        if let activeInt = try? container.decode(Int.self, forKey: .isActive) {
            isActive = activeInt == 1
        } else if let activeBool = try? container.decode(Bool.self, forKey: .isActive) {
            isActive = activeBool
        } else {
            // Default to true if missing, or false? Let's say true to be visible
            isActive = true
        }
    }
    
    func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       try container.encode(id, forKey: .id)
       try container.encode(productId, forKey: .productId)
       // ... simplified for saving if needed
    }
}

struct OrderItem: Codable, Sendable {
    let productId: String // UUID or product_id? usage implies UUID in Android typically
    let quantity: Int
    let unitPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
        case unitPrice = "unit_price"
    }
}

enum OrderStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
}

struct Order: Identifiable, Codable, Sendable {
    let id: String // UUID
    let orderId: String?
    let userUid: String
    let status: OrderStatus
    let items: [OrderItem] 
    let totalAmount: Double
    let platform: String
    let createdAt: String
    
    // For manual decoding of "items_json" string if it comes as string
    // But Codable won't handle JSON string automatically. 
    // We'll likely handle this in Repository mapping.
}

```

---

## `iOS_App/GeoRacing/Domain/Models/SocialModels.swift`

```swift
import Foundation

struct ShareSession: Codable, Identifiable, Sendable {
    let id: String // UUID
    let ownerId: String
    let groupId: String
    let expiresAt: Date
    
    var isValid: Bool {
        return Date() < expiresAt
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Models/TrackStatus.swift`

```swift
import Foundation
import SwiftUI

public enum TrackStatus: String, Sendable, CaseIterable {
    case green
    case yellow
    case red
    case sc // Safety Car
    case vsc // Virtual Safety Car
    case evacuation // Emergency Evacuation
    case unknown // Fallback for unmapped states
    
    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return RacingColors.red
        case .sc, .vsc: return .orange
        case .evacuation: return RacingColors.red // Flash or distinct red?
        case .unknown: return .gray
        }
    }
    
    var iconName: String {
        // User requested standard iOS icons (SF Symbols)
        switch self {
        case .green, .yellow, .red: return "flag.fill"
        case .sc, .vsc: return "exclamationmark.triangle.fill"
        case .evacuation: return "exclamationmark.shield.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var titleKey: String {
        switch self {
        case .green: return "TRACK CLEAR"
        case .yellow: return "YELLOW FLAG"
        case .red: return "RED FLAG"
        case .sc: return "SAFETY CAR"
        case .vsc: return "VIRTUAL SC"
        case .evacuation: return "EVACUATION"
        case .unknown: return "UNKNOWN STATE"
        }
    }
    
    var messageKey: String {
        switch self {
        case .green: return "Track is Green. Racing resumes."
        case .yellow: return "Hazard reported. Slow down."
        case .red: return "Session Suspended. Return to pits."
        case .sc, .vsc: return "Safety Car deployed."
        case .evacuation: return "EMERGENCY: EVACUATE CIRCUIT IMMEDIATELY."
        case .unknown: return "Waiting for race control..."
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/CartManager.swift`

```swift
import Foundation
import Combine

class CartManager: ObservableObject {
    @Published var items: [Product] = []
    @Published var products: [Product] = [] // Loaded products
    @Published var isCheckingOut = false
    @Published var checkoutSuccess = false
    @Published var errorMessage: String?
    
    var total: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    func loadProducts() {
        Task {
            do {
                let fetched = try await ProductRepository.shared.fetchProducts()
                await MainActor.run {
                    self.products = fetched
                }
            } catch {
                Logger.error("Failed to load products: \(error)")
                // Fallback mock
                await MainActor.run {
                    self.products = [
                        Product(id: "m1", productId: "1", name: "Cap (Mock)", description: "", price: 25.0, stock: 10, category: "Merch", imageUrl: "cap", emoji: "crown.fill", isActive: true),
                        Product(id: "m2", productId: "2", name: "Water (Mock)", description: "", price: 2.0, stock: 10, category: "Drink", imageUrl: "water", emoji: "drop.fill", isActive: true)
                    ]
                }
            }
        }
    }
    
    func add(product: Product) {
        items.append(product)
    }
    
    func remove(product: Product) {
        if let index = items.firstIndex(where: { $0.id == product.id }) {
            items.remove(at: index)
        }
    }
    
    func checkout() async throws {
        guard let user = AuthService.shared.currentUser else {
            await MainActor.run { errorMessage = "Please sign in to checkout." }
            return
        }
        
        await MainActor.run { isCheckingOut = true }
        
        // Group items to OrderItems
        // Use productId if available (Web Panel Link), otherwise fallback to internal id
        let grouped = Dictionary(grouping: items, by: { $0.productId ?? $0.id })
        let orderItems: [OrderItem] = grouped.map { (pid, list) in
            OrderItem(productId: pid, quantity: list.count, unitPrice: list.first?.price ?? 0.0)
        }
        
        do {
            _ = try await ProductRepository.shared.submitOrder(items: orderItems, total: total, user: user)
            await MainActor.run {
                self.items.removeAll()
                self.isCheckingOut = false
                self.checkoutSuccess = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Checkout failed: \(error.localizedDescription)"
                self.isCheckingOut = false
            }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/EmergencyImageGenerator.swift`

```swift
import SwiftUI
import UIKit

/// Lock Screen Médico de Emergencia
/// Captures a SwiftUI View into a UIImage that the user can set as their Lock Screen.
/// This acts as a physical resilience feature in case of fainting without connectivity.
@MainActor
class EmergencyImageGenerator {
    
    enum GeneratorError: Error {
        case failedToRender
    }
    
    /// Generates a UIImage from any given SwiftUI View.
    /// - Parameters:
    ///   - view: The SwiftUI view providing the layout for the image.
    ///   - size: The target size for the output image. A match with UIScreen.main.bounds works best for wallpapers.
    /// - Returns: The rendered UIImage.
    static func render<Content: View>(view: Content, size: CGSize) throws -> UIImage {
        // Embed the view in an environment with the proper sizing semantics
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.bounds = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .black // Default lockscreen background
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
        
        guard let _ = image.cgImage else {
            throw GeneratorError.failedToRender
        }
        
        return image
    }
    
    /// Helper to save the image directly to the user's photo album.
    /// Requires NSPhotoLibraryAddUsageDescription in Info.plist
    static func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/EnergyManagementService.swift`

```swift
import SwiftUI
import Combine

/// Protocolo de Supervivencia (Energy Shedding)
/// Service responsible for monitoring battery health.
/// When battery drops below 30% and is not charging, we activate a "Survival Mode"
/// to aggressively shed non-critical features and ensure the user's phone survives the event.
@MainActor
class EnergyManagementService: ObservableObject {
    static let shared = EnergyManagementService()
    
    @Published var isSurvivalMode: Bool = false
    @Published var batteryLevel: Float = 1.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    
    private let survivalThreshold: Float = 0.30 // 30% battery threshold
    private var observers: Set<AnyCancellable> = []
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Enable battery monitoring on UIDevice
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Initial setup
        updateBatteryStatus()
        
        // Listen to level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in self?.updateBatteryStatus() }
            .store(in: &observers)
        
        // Listen to state changes (charging vs unplugged)
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in self?.updateBatteryStatus() }
            .store(in: &observers)
    }
    
    private func updateBatteryStatus() {
        self.batteryLevel = UIDevice.current.batteryLevel
        self.batteryState = UIDevice.current.batteryState
        
        // Gracefully handle simulator where batteryLevel might be -1.0
        if batteryLevel < 0 {
            // Simulator or unknown
            self.isSurvivalMode = false
            return
        }
        
        // Survival mode logic
        let isLowBattery = batteryLevel <= survivalThreshold
        let isNotCharging = batteryState == .unplugged || batteryState == .unknown
        
        let newSurvivalStatus = isLowBattery && isNotCharging
        
        if self.isSurvivalMode != newSurvivalStatus {
            self.isSurvivalMode = newSurvivalStatus
            if newSurvivalStatus {
                Logger.info("[EnergyManagement] Activated Survival Mode! Battery: \(Int(batteryLevel * 100))%")
            } else {
                Logger.info("[EnergyManagement] Deactivated Survival Mode. Back to normal operations.")
            }
        }
    }
    
    deinit {
        // Standard cleanup although this is a singleton
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/HealthService.swift`

```swift
import HealthKit
import Combine
import Foundation

/// Integración de Salud Nativa (EcoMeter vía HealthKit)
/// This service provides an offline-first way to measure the user's carbon footprint/activity
/// by reading native step counts without draining the battery using constant background GPS tracking.
/// Handles graceful degradation for devices that do not support HealthKit (like some iPads).
@MainActor
class HealthService: ObservableObject {
    static let shared = HealthService()
    
    @Published var isSupported: Bool = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var currentEcoPoints: Double = 0.0
    @Published var todaySteps: Double = 0.0
    
    private var healthStore: HKHealthStore?
    
    // Constant: 1 step = 0.5 EcoPoints
    private let stepsToEcoPointsMultiplier: Double = 0.5
    
    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            self.isSupported = true
        } else {
            self.isSupported = false
            Logger.info("[HealthService] HealthKit is not supported on this device. Graceful degradation active.")
        }
    }
    
    /// Requests user authorization to read step count data from HealthKit.
    func requestAuthorization() async throws {
        guard let healthStore = healthStore, isSupported else {
            throw HealthError.notSupported
        }
        
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthError.typeNotAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [stepType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            self.authorizationStatus = healthStore.authorizationStatus(for: stepType)
            
            if self.authorizationStatus == .sharingAuthorized {
                await fetchTodaySteps()
            }
        } catch {
            Logger.error("[HealthService] Failed to request authorization: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Asynchronously fetches the total steps taken today (since 00:00).
    func fetchTodaySteps() async {
        guard let healthStore = healthStore, isSupported else { return }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    Logger.error("[HealthService] Failed to fetch steps: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }
                
                var steps = 0.0
                if let sum = result?.sumQuantity() {
                    steps = sum.doubleValue(for: HKUnit.count())
                }
                
                Task { @MainActor in
                    self.todaySteps = steps
                    self.currentEcoPoints = steps * self.stepsToEcoPointsMultiplier
                    Logger.info("[HealthService] Fetched \(Int(steps)) steps. EcoPoints: \(self.currentEcoPoints)")
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    enum HealthError: Error, LocalizedError {
        case notSupported
        case typeNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .notSupported:
                return "HealthKit is not supported on this device."
            case .typeNotAvailable:
                return "The required health data type is not available."
            }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/MapStyleManager.swift`

```swift
import Foundation

enum MapTheme {
    case light
    case dark
}

protocol MapStyleManagerProtocol {
    var currentTheme: MapTheme { get }
    func shouldSwitchTheme(isNightModeSensor: Bool) -> MapTheme
    func forceTheme(_ theme: MapTheme)
}

class MapStyleManager: MapStyleManagerProtocol {
    
    private(set) var currentTheme: MapTheme = .light
    private var isManualOverride: Bool = false
    
    func shouldSwitchTheme(isNightModeSensor: Bool) -> MapTheme {
        if isManualOverride {
            return currentTheme
        }
        
        // Logic: specific sensor input or default to time if sensor not available (mocked here by input)
        // If sensor says night, use dark.
        
        if isNightModeSensor {
            currentTheme = .dark
        } else {
            currentTheme = .light
        }
        
        return currentTheme
    }
    
    func forceTheme(_ theme: MapTheme) {
        self.currentTheme = theme
        self.isManualOverride = true
    }
    
    func clearOverride() {
        self.isManualOverride = false
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/OffRouteDetector.swift`

```swift
import Foundation

class OffRouteDetector {
    
    private var offRouteStartTime: Date?
    
    /// Checks if the user is off-route based on the snap result.
    ///
    /// - Parameters:
    ///   - snapResult: The result from the RouteSnapper.
    /// - Returns: True if confirmed off-route, False otherwise.
    func isUserOffRoute(snapResult: SnapResult) -> Bool {
        // 1. Evaluate distance threshold
        if snapResult.distanceToRoute > AppConstants.offRouteDistanceThreshold {
            // Case YES
            if let startTime = offRouteStartTime {
                // If we already have a timestamp, check if time threshold exceeded
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > AppConstants.offRouteTimeThreshold {
                    return true // Deviation confirmed
                } else {
                    return false // Waiting for confirmation
                }
            } else {
                // First time detected, save timestamp
                offRouteStartTime = Date()
                return false
            }
        } else {
            // Case NO: Reset timer
            offRouteStartTime = nil
            return false
        }
    }
    
    func reset() {
        offRouteStartTime = nil
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/RouteManager.swift`

```swift
import Foundation
import CoreLocation
import Combine

class RouteManager: ObservableObject {
    static let shared = RouteManager()
    
    // Published State
    @Published var currentRoute: [CLLocationCoordinate2D] = []
    @Published var routeSteps: [RouteStep] = []
    @Published var isNavigating = false
    @Published var currentInstruction: String?
    @Published var distanceToNextManeuver: Double = 0
    @Published var isOffRoute = false
    
    // Dependencies
    private let repository = RouteRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Snapping State (Android Spec 1.2)
    private var lastSnappedIndex: Int = 0
    
    // Off-Route State (Android Spec 1.3)
    private var offRouteTimestamp: Date?
    private let offRouteDistanceThreshold: Double = AppConstants.offRouteDistanceThreshold // 50m
    private let offRouteTimeThreshold: TimeInterval = 3.0 // 3 seconds (Android Spec)
    
    private var currentDestination: CLLocationCoordinate2D?
    
    private init() {
        setupLocationSubscription()
    }
    
    private func setupLocationSubscription() {
        LocationManager.shared.$location
            .compactMap { $0 } // Filter nil
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) } // Convert to CLLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                Task {
                    // print("[RouteManager] Location update received")
                    await self?.updateLocation(location)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - API
    
    @MainActor
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async {
        Logger.debug("[RouteManager] Calculating route...")
        self.currentDestination = end
        
        do {
            let result = try await repository.fetchRoute(from: start, to: end)
            
            self.currentRoute = result.geometry
            self.routeSteps = result.steps
            self.isNavigating = true
            self.lastSnappedIndex = 0
            self.offRouteTimestamp = nil
            self.isOffRoute = false
            
            // Initial Instruction
            if let first = result.steps.first {
                self.currentInstruction = first.instruction
                self.distanceToNextManeuver = first.distance
            }
            
            Logger.info("[RouteManager] Route calculated: \(result.distance)m, \(result.steps.count) steps")
            
        } catch {
            Logger.error("[RouteManager] Failed to calculate route: \(error)")
            self.isNavigating = false
        }
    }
    
    @MainActor
    func clearRoute() {
        self.currentRoute = []
        self.routeSteps = []
        self.isNavigating = false
        self.currentInstruction = nil
        self.offRouteTimestamp = nil
    }
    
    // MARK: - Location Updates & Core Logic (Spec 1.2 & 1.3)
    
    @MainActor
    func updateLocation(_ location: CLLocation) {
        guard isNavigating, !currentRoute.isEmpty else { return }
        
        // 1.2 Snap to Route
        let snapResult = snapToRoute(location.coordinate)
        
        // 1.3 Check Off Route
        if checkOffRoute(snapResult) {
            Logger.warning("[RouteManager] USER IS OFF ROUTE! Recalculating...")
            self.isOffRoute = true
            
            // Trigger Recalculation
            // Debounce or immediate? Spec says "Dispara el recálculo inmediato"
            if let dest = currentDestination {
                Task {
                    await calculateRoute(from: location.coordinate, to: dest)
                }
            }
            return
        } else {
            self.isOffRoute = false
        }
        
        // Update Progress (Instruction / Distance)
        // Find next step based on snapped index or distance
        updateNavigationProgress(snapResult)
    }
    
    // MARK: - Private Algorithms
    
    /// Android Spec 1.2: Snap to Route (Optimized)
    private func snapToRoute(_ location: CLLocationCoordinate2D) -> SnapResult {
        let windowSize = 50
        let startIndex = max(0, lastSnappedIndex - windowSize)
        let endIndex = min(currentRoute.count - 1, lastSnappedIndex + windowSize)
        
        var minDistance: Double = .greatestFiniteMagnitude
        var bestIndex = lastSnappedIndex
        var bestPoint = location // Fallback
        
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        // Iterate window
        for i in startIndex...endIndex {
            let point = currentRoute[i]
            let pLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let dist = loc.distance(from: pLoc)
            
            if dist < minDistance {
                minDistance = dist
                bestIndex = i
                bestPoint = point
            }
        }
        
        // Update state
        self.lastSnappedIndex = bestIndex
        
        return SnapResult(
            snappedLocation: bestPoint,
            routeIndex: bestIndex,
            distanceToRoute: minDistance,
            isSuccessful: minDistance <= offRouteDistanceThreshold
        )
    }
    
    /// Android Spec 1.3: Off Route Detector
    private func checkOffRoute(_ snap: SnapResult) -> Bool {
        if snap.distanceToRoute > offRouteDistanceThreshold {
            // Case YES
            if let timestamp = offRouteTimestamp {
                // Already tracking
                if Date().timeIntervalSince(timestamp) > offRouteTimeThreshold {
                    return true // Confirmed Off Route
                }
            } else {
                // Sample 0
                offRouteTimestamp = Date()
                return false // Waiting for confirmation
            }
        } else {
            // Case NO (Back on track)
            offRouteTimestamp = nil
        }
        return false
    }
    
    private func updateNavigationProgress(_ snap: SnapResult) {
        // Logic to update distanceToNextManeuver
        // This is simplified. Real logic projects point to polyline segment.
        // For parity, we assume distance to next step's start node.
        
        // Find the step that corresponds to current index?
        // OSRM steps don't map 1:1 to indices easily without geometry matching.
        // Simplified: Just show first step for now or keep previous instruction.
        // To do this well, we'd need to map route indices to steps (via Leg -> Annotation).
        
        // Stub update for now to just show we are alive
        // self.distanceToNextManeuver = ...
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/RouteSnapper.swift`

```swift
import Foundation
import CoreLocation

class RouteSnapper {
    
    /// Finds the closest point on the route to the current user location.
    /// Utilizes a sliding window optimization based on the last known index.
    ///
    /// - Parameters:
    ///   - currentLocation: The current GPS reading.
    ///   - routePoints: The full list of route coordinates.
    ///   - lastKnownIndex: The index of the last snapped point (for optimization).
    /// - Returns: A SnapResult containing the snapped location and index.
    func snapToRoute(currentLocation: CLLocationCoordinate2D, routePoints: [CLLocationCoordinate2D], lastKnownIndex: Int?) -> SnapResult {
        guard !routePoints.isEmpty else {
            return SnapResult(snappedLocation: currentLocation, routeIndex: -1, distanceToRoute: Double.infinity, isSuccessful: false)
        }
        
        let searchWindowSize = 50
        var startIndex = 0
        var endIndex = routePoints.count - 1
        
        // Window Optimization
        if let lastIndex = lastKnownIndex {
            startIndex = max(0, lastIndex - searchWindowSize)
            endIndex = min(routePoints.count - 1, lastIndex + searchWindowSize)
        }
        
        var closestPoint = routePoints[startIndex]
        var closestIndex = startIndex
        var minDistance = Double.infinity
        
        for i in startIndex...endIndex {
            let point = routePoints[i]
            let distance = currentLocation.distance(to: point)
            
            if distance < minDistance {
                minDistance = distance
                closestPoint = point
                closestIndex = i
            }
        }
        
        let threshold = AppConstants.offRouteDistanceThreshold
        let isSuccessful = minDistance <= threshold
        
        return SnapResult(
            snappedLocation: closestPoint,
            routeIndex: closestIndex,
            distanceToRoute: minDistance,
            isSuccessful: isSuccessful
        )
    }
}

fileprivate extension CLLocationCoordinate2D {
    /// Calculates distance in meters between two coordinates.
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/StaffBeaconService.swift`

```swift
import Foundation
import CoreBluetooth
import Combine

/// Staff como "Balizas Humanas" (Emisión BLE)
/// Acts as a dynamic BLE beacon emitted by Staff devices when physical beacons fail.
/// Needs `NSBluetoothPeripheralUsageDescription` in Info.plist.
@MainActor
class StaffBeaconService: NSObject, ObservableObject {
    static let shared = StaffBeaconService()
    
    @Published var isBroadcasting: Bool = false
    @Published var bluetoothState: CBManagerState = .unknown
    
    private var peripheralManager: CBPeripheralManager?
    
    // An agreed-upon UUID for GeoRacing Staff signals
    private let staffServiceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-1234-56789ABCDEF0")
    
    // We can use a characteristic to embed a short payload
    private var staffCharacteristic: CBMutableCharacteristic?
    
    override private init() {
        super.init()
        // Initialization of CBPeripheralManager is deferred to request permission only when needed
    }
    
    /// Request permissions and initialize the peripheral manager
    func prepare() {
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
    }
    
    /// Start broadcasting as a peripheral (Human Beacon)
    func startBroadcasting(payload: String) {
        guard let manager = peripheralManager, manager.state == .poweredOn else {
            Logger.error("[StaffBeacon] Cannot broadcast. Bluetooth is not powered on or manager is nil.")
            return
        }
        
        // Stop if already advertising
        if isBroadcasting { stopBroadcasting() }
        
        // 1. Create the characteristic containing the payload (e.g. "STATUS: DANGER")
        let payloadData = payload.data(using: .utf8) ?? Data()
        staffCharacteristic = CBMutableCharacteristic(
            type: CBUUID(string: "A1B2C3D4-E5F6-7890-1234-56789ABCDEF1"),
            properties: [.read],
            value: payloadData,
            permissions: [.readable]
        )
        
        // 2. Create the service
        let service = CBMutableService(type: staffServiceUUID, primary: true)
        if let char = staffCharacteristic {
            service.characteristics = [char]
        }
        
        // 3. Add service to manager
        manager.add(service)
        
        // 4. Start advertising the service UUID
        // The local name provides an immediate glance, the service UUID allows background discovery 
        manager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "GeoRacingStaff",
            CBAdvertisementDataServiceUUIDsKey: [staffServiceUUID]
        ])
        
        self.isBroadcasting = true
        Logger.info("[StaffBeacon] Started broadcasting: \(payload)")
    }
    
    /// Stop broadcasting
    func stopBroadcasting() {
        guard let manager = peripheralManager else { return }
        manager.stopAdvertising()
        manager.removeAllServices()
        self.isBroadcasting = false
        Logger.info("[StaffBeacon] Stopped broadcasting.")
    }
}

extension StaffBeaconService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            self.bluetoothState = peripheral.state
            
            switch peripheral.state {
            case .poweredOn:
                Logger.info("[StaffBeacon] Bluetooth is Powered On.")
            case .poweredOff:
                Logger.warning("[StaffBeacon] Bluetooth powered off. Stopping broadcast.")
                if self.isBroadcasting { stopBroadcasting() }
            case .unauthorized:
                Logger.error("[StaffBeacon] Bluetooth unauthorized.")
                if self.isBroadcasting { stopBroadcasting() }
            default:
                break
            }
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            Logger.error("[StaffBeacon] Failed to start advertising: \(error.localizedDescription)")
            Task { @MainActor in self.isBroadcasting = false }
        } else {
            Logger.info("[StaffBeacon] Advertising started successfully.")
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/SyncQueueManager.swift`

```swift
import Foundation
import Network

/// Payload wrapper for storing failed DatabaseClient requests temporarily in User Defaults.
struct SyncPayload: Codable, Identifiable {
    var id: UUID = UUID()
    let table: String
    let dataData: Data // Since [String: Any] doesn't conform to Codable easily, we store the raw JSON payload
    let timestamp: Date
}

/// Resiliencia Offline Real (Sync Queue)
/// Monitors network state via NWPathMonitor.
/// Queues API payloads when offline and flushes them sequentially when connection is restored.
/// Operates on a singleton background actor to prevent data races.
actor SyncQueueManager {
    static let shared = SyncQueueManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.georacing.syncqueue")
    private let defaultsKey = "offline_sync_queue"
    
    // Concurrency safe tracking
    var isOnline: Bool = true
    private var isFlushing: Bool = false
    
    // Expose a stream or published property if needed, but for now we interact directly
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let online = path.status == .satisfied
            
            Task {
                await self.updateStatus(online)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateStatus(_ online: Bool) async {
        let statusChanged = (self.isOnline != online)
        self.isOnline = online
        
        if online {
            Logger.info("[SyncQueueManager] Network Restored. Initiating flush...")
            await flushQueue()
        } else if statusChanged {
            Logger.info("[SyncQueueManager] Network Lost. Entering offline mode.")
        }
    }
    
    /// Enqueues a failed API upsert payload. Converts the raw AnyEncodable dictionary back to Data for stablility.
    func enqueue(table: String, rawBody: Data) {
        let payload = SyncPayload(table: table, dataData: rawBody, timestamp: Date())
        var currentQueue = getStoredQueue()
        currentQueue.append(payload)
        saveQueue(currentQueue)
        
        Logger.info("[SyncQueueManager] Enqueued \(table) payload for later. Queue size: \(currentQueue.count)")
    }
    
    /// Attempts to send all pending payloads to the server sequentially.
    private func flushQueue() async {
        guard !isFlushing else { return }
        isFlushing = true
        defer { isFlushing = false }
        
        var currentQueue = getStoredQueue()
        guard !currentQueue.isEmpty else { return }
        
        Logger.info("[SyncQueueManager] Flushing \(currentQueue.count) pending payloads...")
        
        var remainingQueue: [SyncPayload] = []
        
        for payload in currentQueue {
            do {
                // We recreate the HTTP Request directly to avoid circular dependency with DatabaseClient
                guard let url = URL(string: "\(AppConstants.apiBaseUrl)/_upsert") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = payload.dataData
                
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    Logger.info("[SyncQueueManager] Successfully flushed payload \(payload.id) to table ^\(payload.table)")
                } else {
                    Logger.error("[SyncQueueManager] Flush failed (Server error) for payload \(payload.id) - keeping in queue.")
                    remainingQueue.append(payload)
                }
            } catch {
                Logger.error("[SyncQueueManager] Flush failed (Network error) for payload \(payload.id) - \(error.localizedDescription)")
                remainingQueue.append(payload)
                // If it's a network error, stop flushing to save battery/bandwidth until the connection stabilizes again
                break
            }
        }
        
        // Save whatever couldn't be uploaded back to UserDefaults
        saveQueue(remainingQueue)
    }
    
    // MARK: - Local Storage Helpers
    
    private func getStoredQueue() -> [SyncPayload] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        do {
            return try JSONDecoder().decode([SyncPayload].self, from: data)
        } catch {
            Logger.error("[SyncQueueManager] Failed to decode sync queue: \(error)")
            return []
        }
    }
    
    private func saveQueue(_ queue: [SyncPayload]) {
        do {
            let data = try JSONEncoder().encode(queue)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            Logger.error("[SyncQueueManager] Failed to encode sync queue: \(error)")
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/TTSManager.swift`

```swift
import Foundation
import AVFoundation

@MainActor
class TTSManager: NSObject, AVSpeechSynthesizerDelegate {
    
    private let synthesizer = AVSpeechSynthesizer()
    private var lastDistance: Double = Double.infinity
    
    // Voice cues thresholds in meters
    private let thresholds: [Double] = [800, 200, 100, 50]
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.error("Failed to configure AudioSession: \(error)")
        }
    }
    
    func update(distanceToNextManeuver: Double, instruction: String) {
        // Check if we crossed a threshold downwards
        for threshold in thresholds {
            if lastDistance > threshold && distanceToNextManeuver <= threshold {
                speak(distance: distanceToNextManeuver, instruction: instruction)
                break // Announce only the highest priority crossing
            }
        }
        
        lastDistance = distanceToNextManeuver
    }
    
    private func speak(distance: Double, instruction: String) {
        let text: String
        let cleanInstruction = instruction.replacingOccurrences(of: "slight ", with: "ligeramente a la ")
                                          .replacingOccurrences(of: "turn ", with: "gira ")
                                          // Add more translations or rely on localized instruction from OSRM
        
        if distance > 50 {
            // "En [distancia], [instrucción]"
            text = "En \(Int(distance)) metros, \(cleanInstruction)"
        } else {
            // "Ahora, [instrucción]"
            text = "Ahora, \(cleanInstruction)"
        }
        
        // Don't interrupt if already speaking? Or queue? AVSpeechSynthesizer queues by default.
        // But for nav, we might want to stop previous if it's outdated? 
        // For now, let it queue or stop immediate?
        // Usually immediate updates are better.
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES") // Spanish as per source docs language hint
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
        Logger.info("TTS Speaking: \(text)")
    }
    
    func reset() {
        lastDistance = Double.infinity
        synthesizer.stopSpeaking(at: .immediate)
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/TelemetryLogger.swift`

```swift
import Foundation

/// Defines a single telemetry event for the Black Box system.
struct TelemetryEvent: Codable {
    let id: UUID
    let timestamp: Date
    let name: String
    let metadata: [String: String]
    
    init(name: String, metadata: [String: String]) {
        self.id = UUID()
        self.timestamp = Date()
        self.name = name
        self.metadata = metadata
    }
}

/// Caja Negra Operativa (Telemetría Local)
/// Lightweight logger designed to save critical ops data locally (battery drops, signal loss).
/// Connects to `SyncQueueManager` to periodically upload chunks of data to a remote `QNAP` server transparently.
@MainActor
class TelemetryLogger {
    static let shared = TelemetryLogger()
    
    private let queue = DispatchQueue(label: "com.georacing.telemetry", qos: .background)
    private let fileName = "blackbox_telemetry.json"
    
    // Batch threshold to flush telemetry to SyncQueueManager
    private let batchThreshold = 20
    private var inMemoryLogs: [TelemetryEvent] = []
    
    private init() {
        loadLocalLogs()
    }
    
    /// Records an event locally. Once threshold is met, it queues an automated upload.
    func logEvent(_ name: String, metadata: [String: String] = [:]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let event = TelemetryEvent(name: name, metadata: metadata)
            self.inMemoryLogs.append(event)
            self.saveLocalLogs()
            
            Logger.info("[TelemetryLogger] Logged Event: \(name)")
            
            // Check if threshold reached to trigger a sync
            if self.inMemoryLogs.count >= self.batchThreshold {
                Task {
                    await self.queueForUpload()
                }
            }
        }
    }
    
    /// Flushes all local events as a single json payload to the SyncQueueManager and clears the local file.
    private func queueForUpload() async {
        let eventsToUpload = inMemoryLogs
        guard !eventsToUpload.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(eventsToUpload)
            // By putting it in `SyncQueueManager`, it guarantees delivery when offline
            await SyncQueueManager.shared.enqueue(table: "telemetry_logs", rawBody: data)
            
            // Clear local logs
            queue.async {
                self.inMemoryLogs.removeAll()
                self.saveLocalLogs()
            }
            Logger.info("[TelemetryLogger] Queued \(eventsToUpload.count) events for server sync.")
        } catch {
            Logger.error("[TelemetryLogger] Failed to encode logs for upload: \(error)")
        }
    }
    
    // MARK: - Local Persistence
    
    private var logFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    private func saveLocalLogs() {
        do {
            let data = try JSONEncoder().encode(inMemoryLogs)
            try data.write(to: logFileURL, options: .atomic)
        } catch {
            Logger.error("[TelemetryLogger] Failed to write local telemetry file: \(error)")
        }
    }
    
    private func loadLocalLogs() {
        queue.async {
            guard FileManager.default.fileExists(atPath: self.logFileURL.path) else { return }
            do {
                let data = try Data(contentsOf: self.logFileURL)
                let savedLogs = try JSONDecoder().decode([TelemetryEvent].self, from: data)
                self.inMemoryLogs = savedLogs
            } catch {
                Logger.error("[TelemetryLogger] Failed to read local telemetry file: \(error)")
            }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Domain/Services/ThermalRoutingService.swift`

```swift
import Foundation
import MapKit

/// Navegación Térmica (Grafo de Sombra / Capa Visual)
/// Provides a layer of "Cool Routes" or "Shadow Zones" across the circuit.
/// This allows users to navigate the circuit while avoiding the heat, complementing MapKit
/// which doesn't know about local shaded areas like tree canopies or covered grandstands.
/// Operates Offline-First by keeping polygonal definitions of shaded zones.
@MainActor
class ThermalRoutingService {
    static let shared = ThermalRoutingService()
    
    private init() {}
    
    /// Returns a list of MKPolygons representing areas with assured shadow on the circuit.
    /// In a real scenario, this could be loaded from a GeoJSON or local database.
    func getShadowPolygons() -> [MKPolygon] {
        return [
            createPolygon(coordinates: [
                CLLocationCoordinate2D(latitude: 41.5702, longitude: 2.2590),
                CLLocationCoordinate2D(latitude: 41.5708, longitude: 2.2595),
                CLLocationCoordinate2D(latitude: 41.5705, longitude: 2.2605),
                CLLocationCoordinate2D(latitude: 41.5699, longitude: 2.2600)
            ], title: "Zona Arboleda Norte"),
            
            createPolygon(coordinates: [
                CLLocationCoordinate2D(latitude: 41.5670, longitude: 2.2580),
                CLLocationCoordinate2D(latitude: 41.5675, longitude: 2.2582),
                CLLocationCoordinate2D(latitude: 41.5673, longitude: 2.2590),
                CLLocationCoordinate2D(latitude: 41.5668, longitude: 2.2588)
            ], title: "Tribuna Cubierta Principal"),
            
            createPolygon(coordinates: [
                CLLocationCoordinate2D(latitude: 41.5720, longitude: 2.2620),
                CLLocationCoordinate2D(latitude: 41.5725, longitude: 2.2625),
                CLLocationCoordinate2D(latitude: 41.5722, longitude: 2.2635),
                CLLocationCoordinate2D(latitude: 41.5717, longitude: 2.2630)
            ], title: "Paseo Sombrío Este")
        ]
    }
    
    private func createPolygon(coordinates: [CLLocationCoordinate2D], title: String) -> MKPolygon {
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        polygon.title = title
        return polygon
    }
}

```

---

## `iOS_App/GeoRacing/GeoRacingApp.swift`

```swift
//
//  GeoRacingApp.swift
//  GeoRacing
//
//  Created by Daniel Colet on 15/12/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

import CarPlay

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // MARK: - UISceneSession Lifecycle (Required for CarPlay)
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        // Check if this is a CarPlay scene
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: .carTemplateApplication)
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }
        
        // Default iPhone scene
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        return config
    }
    
    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when user discards a scene session
    }
}

@main
struct GeoRacingApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    BeaconScanner.shared.loadBeacons()
                    LocalNotificationManager.shared.requestPermission()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Components/DashboardButton.swift`

```swift
import SwiftUI

struct DashboardButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Minimalist Premium Style
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RacingColors.cardBackground)
                        .frame(width: 65, height: 65)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(RacingFont.body(12).bold())
                    .foregroundColor(RacingColors.silver)
                    .lineLimit(1)
            }
        }
        .buttonStyle(DashboardButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Button Style

struct DashboardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Components/GPSMapView.swift`

```swift
import SwiftUI
import MapKit
import CoreLocation

/// UIViewRepresentable that wraps MKMapView for real GPS navigation.
/// Renders the route polyline, user location with heading, and destination pin.
struct GPSMapView: UIViewRepresentable {
    
    @Binding var region: MKCoordinateRegion
    let polyline: MKPolyline?
    let destinationCoordinate: CLLocationCoordinate2D
    let destinationName: String
    let isFollowingUser: Bool
    let onUserInteraction: () -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.isPitchEnabled = true
        mapView.setRegion(region, animated: false)
        
        // Add destination annotation
        let destAnnotation = MKPointAnnotation()
        destAnnotation.coordinate = destinationCoordinate
        destAnnotation.title = destinationName
        mapView.addAnnotation(destAnnotation)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update tracking mode
        if isFollowingUser {
            if mapView.userTrackingMode != .followWithHeading {
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
            }
        } else {
            if !context.coordinator.isUserInteracting {
                mapView.setRegion(region, animated: true)
            }
        }
        
        // Update destination annotation position
        let existingDest = mapView.annotations.compactMap { $0 as? MKPointAnnotation }.first
        if let existing = existingDest {
            if existing.coordinate.latitude != destinationCoordinate.latitude ||
               existing.coordinate.longitude != destinationCoordinate.longitude {
                existing.coordinate = destinationCoordinate
                existing.title = destinationName
            }
        } else {
            let annotation = MKPointAnnotation()
            annotation.coordinate = destinationCoordinate
            annotation.title = destinationName
            mapView.addAnnotation(annotation)
        }
        
        // Update route overlay
        let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }
        
        if let newPolyline = polyline {
            // Only add if different reference
            if !existingPolylines.contains(where: { $0 === newPolyline }) {
                mapView.removeOverlays(existingPolylines)
                mapView.addOverlay(newPolyline, level: .aboveRoads)
            }
        } else {
            // Remove all polylines
            mapView.removeOverlays(existingPolylines)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GPSMapView
        var isUserInteracting = false
        
        init(_ parent: GPSMapView) {
            self.parent = parent
        }
        
        // Detect user dragging the map
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Check if change was initiated by user gesture
            if let view = mapView.subviews.first,
               let gestureRecognizers = view.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    if recognizer.state == .began || recognizer.state == .ended || recognizer.state == .changed {
                        isUserInteracting = true
                        parent.onUserInteraction()
                        return
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isUserInteracting = false
        }
        
        // Route polyline renderer
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 6
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Destination pin
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "DestinationPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            }
            view?.annotation = annotation
            view?.markerTintColor = .systemRed
            view?.glyphImage = UIImage(systemName: "flag.checkered")
            return view
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Components/QRCodeScannerView.swift`

```swift
import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    
    var onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scanner = ScannerViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                // Buzz?
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                onCodeScanned(stringValue)
            }
        }
    }
}

class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.layer.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        
        self.captureSession = session
        self.previewLayer = layer

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds // Handle rotation/resize
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Components/WebView.swift`

```swift
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/ContextState.swift`

```swift
import Foundation
import SwiftUI

enum RacePhase: String, Codable {
    case pre = "PRE"
    case formation = "FORMATION"
    case live = "LIVE"
    case safetyCar = "SAFETY_CAR"
    case redFlag = "RED_FLAG"
    case post = "POST"
}

enum CircuitMode: String, Codable {
    case normal = "NORMAL"
    case congestion = "CONGESTION"
    case emergency = "EMERGENCY"
    case evacuation = "EVACUATION"
    case maintenance = "MAINTENANCE"
}

enum DataHealth: String, Codable {
    case ok = "OK"
    case degraded = "DEGRADED"
    case offline = "OFFLINE"
}

enum UserRole: String, Codable {
    case fan = "FAN"
    case staff = "STAFF"
}

enum UserFocus: String, Codable {
    case seat = "SEAT"
    case route = "ROUTE"
    case parking = "PARKING"
    case incidentNearby = "INCIDENT_NEARBY"
    case none = "NONE"
}

struct ContextState: Equatable {
    let racePhase: RacePhase
    let circuitMode: CircuitMode
    let dataHealth: DataHealth
    let userRole: UserRole
    let focus: UserFocus
    let accessibilityEnabled: Bool
    let lastUpdated: Date
    let routeSuggestion: RouteSuggestion?
    
    // Default initial state
    static var initial: ContextState {
        ContextState(
            racePhase: .pre,
            circuitMode: .normal,
            dataHealth: .ok,
            userRole: .fan,
            focus: .none,
            accessibilityEnabled: UIAccessibility.isVoiceOverRunning,
            lastUpdated: Date(),
            routeSuggestion: nil
        )
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/ContextualCardView.swift`

```swift
import SwiftUI

struct ContextualCardView: View {
    @StateObject private var viewModel = ContextualCardViewModel()
    
    var body: some View {
        VStack {
            activeWidgetView
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.activeWidget)
                .id(caseName(for: viewModel.activeWidget)) // Force transition on type change
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Circuit status card")
        }
        .padding()
    }
    
    @ViewBuilder
    private var activeWidgetView: some View {
        switch viewModel.activeWidget {
        case .emergency(let mode):
            EmergencyWidget(mode: mode)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        case .offline(let date):
            OfflineWidget(lastUpdated: date)
                .transition(.opacity)
        case .racePositions(let lap, let total):
            RacePositionsWidget(currentLap: lap, totalLaps: total)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .circuitStatus(let mode):
            CircuitStatusWidget(mode: mode)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .routeGuidance(let target, let eta, let instruction, let badge):
            RouteGuidanceWidget(target: target, eta: eta, instruction: instruction, badge: badge)
                .transition(.slide)
        }
    }
    
    // Helper to identify unique widget types for transitions
    private func caseName(for widget: WidgetType) -> String {
        switch widget {
        case .emergency: return "emergency"
        case .offline: return "offline"
        case .racePositions: return "racePositions"
        case .circuitStatus: return "circuitStatus"
        case .routeGuidance: return "routeGuidance"
        }
    }
}

// MARK: - Previews

struct ContextualCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard Preview
            ZStack {
                GeoToken.background.ignoresSafeArea()
                ContextualCardView()
            }
            .frame(height: 200)
            
            Divider()
            
            // Simulation Preview
            SimulationView()
                .frame(height: 200)
        }
        .background(Color.gray)
    }
    
    struct SimulationView: View {
        @StateObject var vm = ContextualCardViewModel()
        
        var body: some View {
            ZStack {
                GeoToken.background.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Render the widget manually using the VM to test transitions
                    widgetView(for: vm.activeWidget)
                        .animation(.spring(), value: vm.activeWidget)
                        .padding()
                    
                    Spacer()
                    
                    Button("Start Simulation Loop") {
                        vm.simulateChanges()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Stop") {
                        vm.stopSimulation()
                    }
                    .padding(.bottom)
                }
            }
        }
        
        @ViewBuilder
        func widgetView(for widget: WidgetType) -> some View {
            switch widget {
            case .emergency(let mode):
                EmergencyWidget(mode: mode)
            case .offline(let date):
                OfflineWidget(lastUpdated: date)
            case .racePositions(let lap, let total):
                RacePositionsWidget(currentLap: lap, totalLaps: total)
            case .circuitStatus(let mode):
                CircuitStatusWidget(mode: mode)
            case .routeGuidance(let target, let eta, let instruction, let badge):
                RouteGuidanceWidget(target: target, eta: eta, instruction: instruction, badge: badge)
            }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/ContextualCardViewModel.swift`

```swift
import SwiftUI
import Combine

enum WidgetType: Equatable {
    case emergency(CircuitMode)
    case offline(Date)
    case racePositions(lap: Int, total: Int)
    case circuitStatus(CircuitMode)
    case routeGuidance(target: String, eta: String, instruction: String, badge: String? = nil)
}

class ContextualCardViewModel: ObservableObject {
    @Published var activeWidget: WidgetType = .circuitStatus(.normal)
    @Published var currentState: ContextState
    
    // Mock simulation timer
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let densityService = CrowdDensityService.shared
    
    init(initialState: ContextState = .initial) {
        self.currentState = initialState
        self.activeWidget = selectWidget(for: initialState)
        
        // Subscribe to density updates
        densityService.$densities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkForBetterRoutes()
            }
            .store(in: &cancellables)
    }
    
    func updateState(_ newState: ContextState) {
        withAnimation(.easeInOut) {
            self.currentState = newState
            self.activeWidget = selectWidget(for: newState)
        }
    }
    
    private func checkForBetterRoutes() {
        // Example: If user focus is parking or route, check for better path
        if currentState.focus == .route || currentState.focus == .parking {
            // Mock destination "Gate A"
            if let suggestion = densityService.getEfficientRoute(from: "Current Location", to: "Gate A") {
                let newState = ContextState(
                    racePhase: currentState.racePhase,
                    circuitMode: currentState.circuitMode,
                    dataHealth: currentState.dataHealth,
                    userRole: currentState.userRole,
                    focus: currentState.focus,
                    accessibilityEnabled: currentState.accessibilityEnabled,
                    lastUpdated: Date(),
                    routeSuggestion: suggestion
                )
                updateState(newState)
            }
        }
    }
    
    private func selectWidget(for state: ContextState) -> WidgetType {
        // Priority 1: Safety & Emergencies
        if state.circuitMode == .emergency || state.circuitMode == .evacuation {
            return .emergency(state.circuitMode)
        }
        
        // Priority 2: Data Connectivity
        if state.dataHealth == .offline {
            return .offline(state.lastUpdated)
        }
        
        // Priority 3: Anti-Queue / Route Guidance
        if let suggestion = state.routeSuggestion {
            // New "Anti-Queue" widget variant
            return .routeGuidance(target: suggestion.target, eta: suggestion.newEta, instruction: suggestion.instruction, badge: suggestion.timeSaved)
        }
        
        // Priority 3b: Standard Active User Focus
        if state.focus == .route || state.focus == .parking {
            return .routeGuidance(target: "Parking Zone A", eta: "4 min", instruction: "Turn Left at Gate 3", badge: nil)
        }
        
        // Priority 4: Race Context
        switch state.racePhase {
        case .live, .safetyCar, .redFlag:
            // In a real app, we'd check if we have race data
            return .racePositions(lap: 14, total: 56)
        case .formation:
            return .circuitStatus(.normal) // Or specific formation status
        case .pre, .post:
             // Priority 5: Default Environment State
            if state.circuitMode == .congestion {
                return .circuitStatus(.congestion)
            } else if state.circuitMode == .maintenance {
                return .circuitStatus(.maintenance)
            } else {
                return .circuitStatus(.normal)
            }
        }
    }
    
    // DEMO: Function to simulate state changes for preview purposes
    func simulateChanges() {
        timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            let nextState = self.generateNextDemoState()
            self.updateState(nextState)
        }
    }
    
    func stopSimulation() {
        timer?.cancel()
    }
    
    private func generateNextDemoState() -> ContextState {
        // Simple rotation of states for demo
        switch activeWidget {
        case .circuitStatus:
            return ContextState(racePhase: .live, circuitMode: .normal, dataHealth: .ok, userRole: .fan, focus: .none, accessibilityEnabled: false, lastUpdated: Date(), routeSuggestion: nil)
        case .racePositions:
            return ContextState(racePhase: .live, circuitMode: .emergency, dataHealth: .ok, userRole: .fan, focus: .none, accessibilityEnabled: false, lastUpdated: Date(), routeSuggestion: nil)
        case .emergency:
             return ContextState(racePhase: .live, circuitMode: .normal, dataHealth: .offline, userRole: .fan, focus: .none, accessibilityEnabled: false, lastUpdated: Date(), routeSuggestion: nil)
        case .offline:
            // Simulate Anti-Queue Route finding
             return ContextState(
                racePhase: .post,
                circuitMode: .normal,
                dataHealth: .ok,
                userRole: .fan,
                focus: .route,
                accessibilityEnabled: false,
                lastUpdated: Date(),
                routeSuggestion: RouteSuggestion(target: "Gate A", originalEta: "20m", newEta: "10m", instruction: "Take Fast Track >", timeSaved: "10m saved")
             )
        case .routeGuidance:
             return ContextState.initial
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/Widgets/CircuitStatusWidget.swift`

```swift
import SwiftUI

struct CircuitStatusWidget: View {
    let mode: CircuitMode
    
    var statusTitle: String {
        switch mode {
        case .normal: return "CIRCUIT STATUS: GREEN"
        case .congestion: return "HIGH TRAFFIC ALERT"
        case .maintenance: return "MAINTENANCE IN PROGRESS"
        default: return "CIRCUIT STATUS"
        }
    }
    
    var statusIcon: String {
        switch mode {
        case .normal: return "checkmark.circle.fill"
        case .congestion: return "exclamationmark.triangle.fill"
        case .maintenance: return "hammer.fill"
        default: return "info.circle.fill"
    }
    }
    
    var statusColor: Color {
        switch mode {
        case .normal: return .green
        case .congestion: return .orange
        case .maintenance: return .yellow
        default: return GeoToken.primary
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: statusIcon)
                .font(.system(size: 24))
                .foregroundColor(statusColor)
                .frame(width: 48, height: 48)
                .background(statusColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(RacingFont.subheader(16))
                    .foregroundColor(GeoToken.textPrimary)
                
                Text("Tap for details")
                    .font(RacingFont.body(12))
                    .foregroundColor(GeoToken.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(GeoToken.textSecondary)
        }
        .padding()
        .background(GeoToken.surface)
        .cornerRadius(GeoLayout.radius)
    }
}

#Preview {
    ZStack {
        GeoToken.background.ignoresSafeArea()
        VStack {
            CircuitStatusWidget(mode: .normal)
            CircuitStatusWidget(mode: .congestion)
        }
        .padding()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/Widgets/EmergencyWidget.swift`

```swift
import SwiftUI

struct EmergencyWidget: View {
    let mode: CircuitMode
    
    var title: String {
        switch mode {
        case .evacuation: return "EVACUATION ORDER"
        case .emergency: return "EMERGENCY ALERT"
        default: return "ALERT"
        }
    }
    
    var message: String {
        switch mode {
        case .evacuation: return "Please proceed calmly to the nearest exit. Follow staff instructions."
        case .emergency: return "Incident reported nearby. Stay clear of the area."
        default: return "Important safety announcement."
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RacingFont.header(20))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(RacingFont.body(14))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(GeoToken.primary)
        .cornerRadius(GeoLayout.radius)
        .overlay(
            RoundedRectangle(cornerRadius: GeoLayout.radius)
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: GeoToken.primary.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        GeoToken.background.ignoresSafeArea()
        EmergencyWidget(mode: .evacuation)
            .padding()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/Widgets/OfflineWidget.swift`

```swift
import SwiftUI

struct OfflineWidget: View {
    let lastUpdated: Date
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 20))
                .foregroundColor(GeoToken.textSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("YOU ARE OFFLINE")
                    .font(RacingFont.subheader(14))
                    .foregroundColor(GeoToken.textSecondary)
                
                Text("Data last updated at \(timeString)")
                    .font(RacingFont.body(12))
                    .foregroundColor(GeoToken.textSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Text("RETRYING...")
                .font(RacingFont.body(10).bold())
                .foregroundColor(GeoToken.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GeoToken.surfaceHighlight)
                .cornerRadius(4)
        }
        .padding()
        .background(GeoToken.surface.opacity(0.8))
        .cornerRadius(GeoLayout.radius)
        .overlay(
            RoundedRectangle(cornerRadius: GeoLayout.radius)
                .stroke(GeoToken.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        GeoToken.background.ignoresSafeArea()
        OfflineWidget(lastUpdated: Date())
            .padding()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/Widgets/RacePositionsWidget.swift`

```swift
import SwiftUI

struct RacePositionsWidget: View {
    // Mock data for now, ideally this comes from a ViewModel
    let positions = [
        (driver: "VER", team: "Red Bull", gap: "Leader"),
        (driver: "NOR", team: "McLaren", gap: "+2.4s"),
        (driver: "HAM", team: "Mercedes", gap: "+5.1s"),
        (driver: "LEC", team: "Ferrari", gap: "+8.9s"),
        (driver: "PIA", team: "McLaren", gap: "+12.3s")
    ]
    
    let currentLap: Int
    let totalLaps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("LIVE STANDINGS")
                    .font(RacingFont.header(14))
                    .foregroundColor(GeoToken.textSecondary)
                Spacer()
                Text("LAP \(currentLap)/\(totalLaps)")
                    .font(RacingFont.body(12).bold())
                    .foregroundColor(GeoToken.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GeoToken.surfaceHighlight)
                    .cornerRadius(4)
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                    HStack {
                        Text("\(index + 1)")
                            .font(RacingFont.body().bold())
                            .foregroundColor(GeoToken.primary)
                            .frame(width: 24, alignment: .leading)
                        
                        Text(position.driver)
                            .font(RacingFont.body().weight(.heavy))
                            .foregroundColor(GeoToken.textPrimary)
                        
                        Text(position.team)
                            .font(RacingFont.body(12))
                            .foregroundColor(GeoToken.textSecondary)
                        
                        Spacer()
                        
                        Text(position.gap)
                            .font(RacingFont.body(12).monospacedDigit())
                            .foregroundColor(GeoToken.textOnPrimary)
                    }
                    .padding(.vertical, 6)
                    
                    if index < positions.count - 1 {
                        Divider().background(GeoToken.borderSubtle)
                    }
                }
            }
        }
        .padding()
        .background(GeoToken.surface)
        .cornerRadius(GeoLayout.radius)
    }
}

#Preview {
    ZStack {
        GeoToken.background.ignoresSafeArea()
        RacePositionsWidget(currentLap: 12, totalLaps: 56)
            .padding()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ContextualCard/Widgets/RouteGuidanceWidget.swift`

```swift
import SwiftUI

struct RouteGuidanceWidget: View {
    let target: String
    let eta: String
    let instruction: String
    var badge: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(badge != nil ? .teal : GeoToken.primary)
                .frame(width: 48, height: 48)
                .background(badge != nil ? Color.teal.opacity(0.1) : GeoToken.surfaceHighlight)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(instruction)
                        .font(RacingFont.subheader(16))
                        .foregroundColor(GeoToken.textPrimary)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(RacingFont.body(10).bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.teal)
                            .cornerRadius(4)
                    }
                }
                
                Text("To \(target) • \(eta)")
                    .font(RacingFont.body(12))
                    .foregroundColor(GeoToken.textSecondary)
            }
            
            Spacer()
            
            Button("Navigate") {
                // Action
            }
            .font(RacingFont.body(12).bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(badge != nil ? Color.teal : GeoToken.primary)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .padding()
        .background(GeoToken.surface)
        .cornerRadius(GeoLayout.radius)
        .overlay(
             RoundedRectangle(cornerRadius: GeoLayout.radius)
                 .stroke(badge != nil ? Color.teal.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        GeoToken.background.ignoresSafeArea()
        RouteGuidanceWidget(target: "Seat A-12", eta: "5 min", instruction: "Turn Right")
            .padding()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/Navigation/ParkingRoute.swift`

```swift
import Foundation

/// Defines navigation routes for the Parking module.
/// Supports future deep linking integration.
enum ParkingRoute: Hashable {
    case wizardStep1 // License Plate
    case wizardStep2 // Scan Ticket
    case wizardStep3 // Confirm
    case wizardStep4 // Result
    case assignmentDetail
    case navigation
    case support
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/ParkingContainerView.swift`

```swift
import SwiftUI

struct ParkingContainerView: View {
    @StateObject private var viewModel = ParkingViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ParkingHomeView(viewModel: viewModel)
                .navigationDestination(for: ParkingRoute.self) { route in
                    switch route {
                    case .wizardStep1:
                        ParkingWizardStep1View(viewModel: viewModel)
                    case .wizardStep2:
                        ParkingWizardStep2View(viewModel: viewModel)
                    case .wizardStep3:
                        ParkingWizardStep3View(viewModel: viewModel)
                    case .wizardStep4:
                        ParkingWizardStep4View(viewModel: viewModel)
                    case .assignmentDetail:
                        ParkingAssignmentDetailView(viewModel: viewModel)
                    case .navigation:
                        ParkingNavigationView(viewModel: viewModel)
                    case .support:
                        ParkingSupportView()
                    }
                }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/ParkingViewModel.swift`

```swift
import Foundation
import SwiftUI
import Combine

enum ParkingViewState {
    case idle
    case loading
    case loaded(ParkingAssignment)
    case error(ParkingError)
}

@MainActor
class ParkingViewModel: ObservableObject {
    
    // Dependencies
    private let assignmentService: ParkingAssignmentServiceProtocol
    private let repository: ParkingRepositoryProtocol
    
    // Global Navigation
    @Published var navigationPath = NavigationPath()
    
    // Main State
    @Published var viewState: ParkingViewState = .idle
    
    // Wizard Form Data
    @Published var licensePlateInput: String = ""
    @Published var scannedTicketId: String = ""
    // Estimated arrival removed as per requirements (valid for full event day)
    @Published var wizardStep: Int = 1 // 1..4 internal step tracking for progress bar
    
    // Derived
    var hasActiveAssignment: Bool {
        if case .loaded = viewState { return true }
        return false
    }
    
    init(assignmentService: ParkingAssignmentServiceProtocol = ParkingAssignmentService(),
         repository: ParkingRepositoryProtocol = ParkingRepository()) {
        self.assignmentService = assignmentService
        self.repository = repository
        
        // Initial load
        self.loadAssignment()
    }
    
    // MARK: - Core Logic
    
    func loadAssignment() {
        if let assignment = repository.getAssignment() {
            self.viewState = .loaded(assignment)
        } else {
            self.viewState = .idle
        }
    }
    
    func resetFlow() {
        navigationPath = NavigationPath()
        wizardStep = 1
        licensePlateInput = ""
        scannedTicketId = ""
        viewState = .idle
    }
    
    // MARK: - Wizard Actions
    
    func startWizard() {
        // Reset inputs
        licensePlateInput = ""
        scannedTicketId = ""
        wizardStep = 1
        
        // Navigate to Step 1 (Now Ticket Scan)
        navigationPath.append(ParkingRoute.wizardStep1)
    }
    
    func submitTicketScan() {
        guard !scannedTicketId.isEmpty else { return }
        wizardStep = 2
        // Navigate to Step 2 (Now License Plate)
        navigationPath.append(ParkingRoute.wizardStep2)
    }
    
    func submitLicensePlate() {
        guard validateLicensePlate(licensePlateInput) else {
            return
        }
        wizardStep = 3
        navigationPath.append(ParkingRoute.wizardStep3)
    }
    
    func confirmAssignment() async {
        viewState = .loading
        // Delay simulated
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        do {
            let assignment = try await assignmentService.assignParking(
                licensePlate: licensePlateInput,
                ticketId: scannedTicketId
            )
            repository.saveAssignment(assignment)
            viewState = .loaded(assignment)
            
            // Navigate to Result
            wizardStep = 4
            navigationPath.append(ParkingRoute.wizardStep4)
        } catch let err as ParkingError {
            viewState = .error(err)
        } catch {
            viewState = .error(.unknown)
        }
    }
    
    func finishWizard() {
        // Clear stack to return to Home, which will now show the Assignment card
        navigationPath = NavigationPath()
    }
    
    func clearAssignment() {
        repository.clearAssignment()
        viewState = .idle
        navigationPath = NavigationPath()
    }
    
    // MARK: - Navigation Helpers
    
    func navigateToDetail() {
        navigationPath.append(ParkingRoute.assignmentDetail)
    }
    
    func navigateToNavigation() {
        navigationPath.append(ParkingRoute.navigation)
    }
    
    func navigateToSupport() {
        navigationPath.append(ParkingRoute.support)
    }
    
    // MARK: - Validation
    
    func validateLicensePlate(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count >= 4
    }
    
    func simulateScan() {
        self.scannedTicketId = "TICKET-\(Int.random(in: 10000...99999))"
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/Views/ParkingDetailViews.swift`

```swift
import SwiftUI
import MapKit

struct ParkingAssignmentDetailView: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if case .loaded(let assignment) = viewModel.viewState {
                    // Big summary
                    VStack {
                        Text(assignment.zone.rawValue)
                            .font(.system(size: 100, weight: .black))
                            .foregroundColor(Color(assignment.zone.colorName))
                        Text(assignment.virtualSpot)
                            .font(.largeTitle)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    
                    // Staff Validation QR
                    VStack(spacing: 12) {
                        Text(LocalizationUtils.string("Validation Code"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        QRCodeView(content: "GEORACING:\(assignment.id.uuidString)")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        
                        Text(LocalizationUtils.string("This QR code validates your access to the assigned zone. Keep brightness high when scanning."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: LocalizationUtils.string("License Plate"), value: assignment.licensePlate)
                        DetailRow(label: "Ticket ID", value: assignment.ticketId)
                        DetailRow(label: LocalizationUtils.string("Status"), value: assignment.status.rawValue.capitalized)
                        DetailRow(label: LocalizationUtils.string("Date"), value: assignment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizationUtils.string("Access Instructions"))
                            .font(.headline)
                        Text(String(format: LocalizationUtils.string("Follow signs to Zone %@. Upon arrival, show this code to staff or scan the QR at the barrier if available."), assignment.zone.rawValue))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Map Placeholder
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.largeTitle)
                            .padding()
                        Text(LocalizationUtils.string("View location on map"))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .onTapGesture {
                        // Open real map MVP placeholder
                    }
                    
                } else {
                    Text(LocalizationUtils.string("No active assignment"))
                }
            }
            .padding()
        }
        .navigationTitle(LocalizationUtils.string("Parking Detail"))
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct ParkingNavigationView: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        VStack {
            Text(LocalizationUtils.string("Guidance In Progress"))
                .font(.largeTitle)
            Spacer()
            // MVP Text Navigation
            if case .loaded(let assignment) = viewModel.viewState {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .padding()
                
                Text(String(format: LocalizationUtils.string("Head to Zone %@"), assignment.zone.rawValue))
                    .font(.title)
                    .bold()
                
                Text(assignment.virtualSpot)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(LocalizationUtils.string("End Navigation")) {
                viewModel.finishWizard() // Just pops back for MVP
            }
            .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
        }
        .padding()
    }
}

struct ParkingSupportView: View {
    var body: some View {
        List {
            Section(header: Text(LocalizationUtils.string("FAQ"))) {
                Text("¿Qué hago si mi plaza está ocupada?")
                Text("¿Cómo cambio mi matrícula?")
                Text("No tengo cobertura")
            }
            
            Section {
                Button("Contactar Soporte") {
                    // Action
                }
                .buttonStyle(GeoButtonStyle(variant: .secondary, size: .medium))
            }
        }
        .navigationTitle("Ayuda Parking")
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/Views/ParkingHomeView.swift`

```swift
import SwiftUI

struct ParkingHomeView: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "car.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    Text(LocalizationUtils.string("Parking Management"))
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: { viewModel.navigateToSupport() }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content
                if case .loaded(let assignment) = viewModel.viewState {
                    // Active Assignment Card
                    AssignmentCard(assignment: assignment)
                        .onTapGesture {
                            viewModel.navigateToDetail()
                        }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(title: LocalizationUtils.string("View Route"), icon: "map.fill", color: .blue) {
                            viewModel.navigateToNavigation()
                        }
                        
                        ActionButton(title: LocalizationUtils.string("Share"), icon: "square.and.arrow.up", color: .green) {
                            // Mock Share
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(LocalizationUtils.string("Release / Change Assignment")) {
                        viewModel.clearAssignment()
                    }
                    .buttonStyle(GeoButtonStyle(variant: .tertiary, size: .small))
                    .foregroundColor(.red) // Override for destructive action
                    .padding(.bottom)
                    
                } else if case .loading = viewModel.viewState {
                    ProgressView(LocalizationUtils.string("Loading assignment..."))
                    Spacer()
                } else {
                    // Empty State / Call to Action
                    VStack(spacing: 30) {
                        Spacer()
                        Image(systemName: "parkingsign.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text(LocalizationUtils.string("No parking assigned"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            viewModel.startWizard()
                        }) {
                            Text(LocalizationUtils.string("Assign my spot"))
                        }
                        .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

struct AssignmentCard: View {
    let assignment: ParkingAssignment
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("TU PLAZA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Text(assignment.status.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Divider()
            
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Zona")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(assignment.zone.rawValue)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(assignment.zone.colorName))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Plaza Virtual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(assignment.virtualSpot)
                        .font(.title)
                        .bold()
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.secondary)
                Text(assignment.licensePlate)
                    .font(.headline)
                Spacer()
                Text(assignment.ticketId)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GeoButtonStyle(variant: .secondary, size: .medium))
    }
}

struct ParkingViews_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ParkingViewModel()
        ParkingHomeView(viewModel: vm)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/Views/ParkingWizardViews.swift`

```swift
import SwiftUI

struct ParkingWizardStep1View: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            WizardHeader(title: LocalizationUtils.string("Step 1 of 3"), subtitle: LocalizationUtils.string("Scan your ticket"))
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 300)
                
                if viewModel.scannedTicketId.isEmpty {
                    VStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(LocalizationUtils.string("Simulating camera..."))
                            .font(.caption)
                            .padding(.top)
                        
                        Button(LocalizationUtils.string("Simulate Scan")) {
                            viewModel.simulateScan()
                        }
                        .buttonStyle(GeoButtonStyle(variant: .secondary, size: .small))
                        .padding()
                    }
                } else {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text(LocalizationUtils.string("Ticket Detected"))
                            .font(.headline)
                            .padding(.top)
                        Text(viewModel.scannedTicketId)
                            .font(.monospaced(.body)())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.separator))
                Text(LocalizationUtils.string("Or"))
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.separator))
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationUtils.string("Enter code manually"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Ej: TICKET-9999", text: $viewModel.scannedTicketId)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .textInputAutocapitalization(.characters)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: viewModel.submitTicketScan) {
                Text(LocalizationUtils.string("Continue"))
            }
            .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
            .disabled(viewModel.scannedTicketId.isEmpty)
            .padding()
        }
        .padding()
    }
}

struct ParkingWizardStep2View: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            WizardHeader(title: LocalizationUtils.string("Step 2 of 3"), subtitle: LocalizationUtils.string("Enter your license plate"))
            
            TextField("Ej: 1234ABC", text: $viewModel.licensePlateInput)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .textInputAutocapitalization(.characters)
                .padding(.horizontal)
            
            Text(LocalizationUtils.string("Required to validate your parking access."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: viewModel.submitLicensePlate) {
                Text(LocalizationUtils.string("Continue"))
            }
            .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
            .disabled(!viewModel.validateLicensePlate(viewModel.licensePlateInput))
            .padding()
        }
        .padding()
    }
}

struct ParkingWizardStep3View: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            WizardHeader(title: LocalizationUtils.string("Confirm"), subtitle: LocalizationUtils.string("Review details"))
            
            List {
                Section(header: Text(LocalizationUtils.string("Ticket"))) {
                    HStack {
                        Text("Ticket ID")
                        Spacer()
                        Text(viewModel.scannedTicketId)
                            .font(.monospaced(.body)())
                    }

                    Text(LocalizationUtils.string("Valid until end of day"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(LocalizationUtils.string("Vehicle"))) {
                    HStack {
                        Text(LocalizationUtils.string("License Plate"))
                        Spacer()
                        Text(viewModel.licensePlateInput)
                            .bold()
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            if case .error(let error) = viewModel.viewState {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await viewModel.confirmAssignment()
                }
            }) {
                if case .loading = viewModel.viewState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(LocalizationUtils.string("Confirm and Assign"))
                }
            }
            .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
            .padding()
        }
    }
}


struct ParkingWizardStep4View: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text(LocalizationUtils.string("Spot Assigned!"))
                .font(.largeTitle)
                .bold()
            
            if case .loaded(let assignment) = viewModel.viewState {
                VStack {
                    Text(LocalizationUtils.string("Go to Zone"))
                        .foregroundColor(.secondary)
                    Text(assignment.zone.rawValue)
                        .font(.system(size: 80, weight: .heavy))
                        .foregroundColor(Color(assignment.zone.colorName))
                    
                    Text("\(LocalizationUtils.string("Virtual Spot")): \(assignment.virtualSpot)")
                        .font(.title2)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .shadow(radius: 10)
                
                VStack(spacing: 8) {
                    Text(LocalizationUtils.string("Staff Validation"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    QRCodeView(content: "GEORACING:\(assignment.id.uuidString)")
                        .frame(width: 150, height: 150)
                    
                    Text(LocalizationUtils.string("This QR code is your confirmed access pass. Show it to security staff to enter your zone."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(maxWidth: 250)
                }
                .padding(.top)
            }
            
            Spacer()
            
            Button(action: viewModel.finishWizard) {
                Text(LocalizationUtils.string("Go to Home"))
            }
            .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .padding()
    }
}

// Helper for consistency
struct WizardHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(subtitle)
                .font(.title2)
                .bold()
        }
        .padding(.top)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Parking/Views/QRCodeView.swift`

```swift
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let content: String
    
    var body: some View {
        Image(uiImage: generateQRCode(from: content))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Scale up for sharpness (though SwiftUI interpolation(.none) handles viewing)
            // But creating a proper CGImage is safer
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Theme/GeoButtonStyles.swift`

```swift
import SwiftUI

// MARK: - Button System
// Premium minimalist button styles. No glow, no neon.

enum GeoButtonVariant {
    case primary    // Solid Brand Color
    case secondary  // Surface Color + Subtle Border
    case tertiary   // Ghost / Text only
}

enum GeoButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return GeoLayout.buttonHeightSmall
        case .medium: return GeoLayout.buttonHeightMedium
        case .large: return GeoLayout.buttonHeightLarge
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 20
        case .large: return 24
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16 // Body
        case .large: return 17  // Headline equivalent
        }
    }
}

struct GeoButtonStyle: ButtonStyle {
    let variant: GeoButtonVariant
    let size: GeoButtonSize
    
    init(variant: GeoButtonVariant = .primary, size: GeoButtonSize = .large) {
        self.variant = variant
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        return configuration.label
            .font(.system(size: size.fontSize, weight: .semibold, design: .default))
            .foregroundColor(textColor(isPressed: isPressed))
            .frame(height: size.height)
            .frame(maxWidth: variant == .tertiary ? nil : .infinity) // Tertiary fits content, others expand
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundView(isPressed: isPressed))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: GeoLayout.radius)
                .fill(GeoToken.primary)
                // No shadow/glow as strictly requested.
            
        case .secondary:
            RoundedRectangle(cornerRadius: GeoLayout.radius)
                .fill(GeoToken.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: GeoLayout.radius)
                        .stroke(GeoToken.borderSubtle, lineWidth: GeoLayout.borderWidth)
                )
            
        case .tertiary:
            Color.clear // Transparent
        }
    }
    
    // MARK: - Color Logic
    
    private func textColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return GeoToken.textOnPrimary.opacity(isPressed ? 0.9 : 1.0)
        case .secondary:
            return GeoToken.textPrimary.opacity(isPressed ? 0.8 : 1.0)
        case .tertiary:
            return GeoToken.primary.opacity(isPressed ? 0.7 : 1.0) // Link color behavior
        }
    }
}

// MARK: - Check Requirements (Previews)
// Shows Primary, Secondary, Tertiary in Normal, Pressed (Simulated roughly), Disabled.
struct GeoButtonSystem_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GeoToken.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Large Buttons
                VStack(spacing: 16) {
                    Text("Large Variants").foregroundColor(.gray)
                    
                    Button("Primary Action") {}
                        .buttonStyle(GeoButtonStyle(variant: .primary, size: .large))
                    
                    Button("Secondary Action") {}
                        .buttonStyle(GeoButtonStyle(variant: .secondary, size: .large))
                    
                    Button("Tertiary Action") {}
                        .buttonStyle(GeoButtonStyle(variant: .tertiary, size: .large))
                }
                
                // Small Buttons
                HStack(spacing: 16) {
                    Button("Add") {}
                        .buttonStyle(GeoButtonStyle(variant: .primary, size: .small))
                    
                    Button("Cancel") {}
                        .buttonStyle(GeoButtonStyle(variant: .secondary, size: .small))
                }
                
                // Disabled State Example (Using opacity modifier)
                Button("Disabled Primary") {}
                    .buttonStyle(GeoButtonStyle(variant: .primary, size: .medium))
                    .disabled(true)
                    .opacity(0.5) // Standard SwiftUI disable handling
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Theme/GeoTheme.swift`

```swift
import SwiftUI

// MARK: - Design Tokens
// Centralized source of truth for the premium minimalist theme.
// Maps semantic names to existing RacingColors or system colors.

struct GeoLayout {
    static let radius: CGFloat = 14
    static let buttonHeightLarge: CGFloat = 56
    static let buttonHeightMedium: CGFloat = 48
    static let buttonHeightSmall: CGFloat = 36
    static let borderWidth: CGFloat = 1
}

struct GeoToken {
    // Colors mapped from RacingColors
    static let primary = RacingColors.red
    static let background = RacingColors.darkBackground
    static let surface = RacingColors.cardBackground
    static let textOnPrimary = RacingColors.white
    static let textPrimary = RacingColors.white
    static let textSecondary = RacingColors.silver
    
    // Derived tokens for specific UI needs (using opacity on existing colors as requested)
    static let borderSubtle = RacingColors.silver.opacity(0.2)
    static let surfaceHighlight = RacingColors.silver.opacity(0.1) // For pressed states on secondary/tertiary
}

```

---

## `iOS_App/GeoRacing/Presentation/Theme/TeamThemeService.swift`

```swift
import SwiftUI
import Combine

/// Service that provides team-based theming across the app
/// Uses the favorite team from UserPreferences to determine colors
@MainActor
class TeamThemeService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = TeamThemeService()
    
    // MARK: - Published Properties
    
    @Published private(set) var primaryColor: Color = .red
    @Published private(set) var secondaryColor: Color = .white
    @Published private(set) var accentColor: Color = .orange
    @Published private(set) var teamName: String = "Ferrari"
    @Published private(set) var teamIcon: String = "car.fill"
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadTeamTheme()
        
        // Listen for preference changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadTeamTheme()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Reload theme from preferences
    func refresh() {
        loadTeamTheme()
    }
    
    /// Get gradient for backgrounds
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor.opacity(0.3), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Get subtle gradient for cards
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor.opacity(0.15), Color(white: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Get border color for widgets
    var borderColor: Color {
        primaryColor.opacity(0.4)
    }
    
    // MARK: - Private Methods
    
    private func loadTeamTheme() {
        // Try to load from TeamCatalogService first (new system)
        let teamId = UserPreferences.shared.favoriteTeamId
        if !teamId.isEmpty, let team = TeamCatalogService.shared.team(byId: teamId) {
            teamName = team.name
            primaryColor = team.primarySwiftColor
            secondaryColor = team.secondarySwiftColor
            accentColor = team.secondarySwiftColor
            teamIcon = team.fallbackIcon
            Logger.debug("[TeamTheme] Loaded from catalog: \(team.name)")
            return
        }
        
        // Legacy fallback: match by name
        let team = UserPreferences.shared.favoriteTeam
        if let catalogTeam = TeamCatalogService.shared.teams.first(where: { $0.name == team }) {
            teamName = catalogTeam.name
            primaryColor = catalogTeam.primarySwiftColor
            secondaryColor = catalogTeam.secondarySwiftColor
            accentColor = catalogTeam.secondarySwiftColor
            teamIcon = catalogTeam.fallbackIcon
            // Migrate to new ID system
            UserPreferences.shared.favoriteTeamId = catalogTeam.id
            Logger.debug("[TeamTheme] Migrated from legacy name: \(team) → \(catalogTeam.id)")
            return
        }
        
        // Hardcoded fallback for teams not in catalog
        teamName = team
        
        switch team {
        // F1 Teams
        case "Ferrari":
            primaryColor = Color(red: 0.86, green: 0.0, blue: 0.0)
            secondaryColor = .yellow
            accentColor = .yellow
            teamIcon = "car.fill"
            
        case "Red Bull":
            primaryColor = Color(red: 0.07, green: 0.16, blue: 0.38)
            secondaryColor = Color(red: 1.0, green: 0.84, blue: 0.0)
            accentColor = Color(red: 1.0, green: 0.84, blue: 0.0)
            teamIcon = "bolt.fill"
            
        case "Mercedes":
            primaryColor = Color(red: 0.0, green: 0.82, blue: 0.77)
            secondaryColor = .black
            accentColor = .white
            teamIcon = "star.fill"
            
        case "McLaren":
            primaryColor = Color(red: 1.0, green: 0.53, blue: 0.0)
            secondaryColor = .blue
            accentColor = .white
            teamIcon = "flame.fill"
            
        case "Aston Martin":
            primaryColor = Color(red: 0.0, green: 0.45, blue: 0.35)
            secondaryColor = .yellow
            accentColor = .yellow
            teamIcon = "leaf.fill"
            
        case "Alpine":
            primaryColor = Color(red: 0.0, green: 0.53, blue: 0.87)
            secondaryColor = .pink
            accentColor = .pink
            teamIcon = "mountain.2.fill"
            
        case "Williams":
            primaryColor = Color(red: 0.0, green: 0.26, blue: 0.58)
            secondaryColor = .cyan
            accentColor = .cyan
            teamIcon = "shield.fill"
            
        case "Haas":
            primaryColor = Color(red: 0.72, green: 0.72, blue: 0.72)
            secondaryColor = .red
            accentColor = .red
            teamIcon = "wrench.fill"
            
        case "Sauber", "Kick Sauber":
            primaryColor = Color(red: 0.32, green: 0.69, blue: 0.29)
            secondaryColor = .black
            accentColor = .white
            teamIcon = "cross.fill"
            
        case "RB", "Racing Bulls":
            primaryColor = Color(red: 0.14, green: 0.23, blue: 0.42)
            secondaryColor = .white
            accentColor = .red
            teamIcon = "hare.fill"
            
        // MotoGP Teams
        case "Ducati":
            primaryColor = Color(red: 0.8, green: 0.0, blue: 0.0)
            secondaryColor = .white
            accentColor = .white
            teamIcon = "bolt.circle.fill"
            
        case "Yamaha":
            primaryColor = Color(red: 0.0, green: 0.13, blue: 0.53)
            secondaryColor = .white
            accentColor = .black
            teamIcon = "tuningfork"
            
        case "Honda":
            primaryColor = Color(red: 0.8, green: 0.0, blue: 0.0)
            secondaryColor = .blue
            accentColor = .white
            teamIcon = "circle.circle.fill"
            
        case "KTM":
            primaryColor = Color(red: 1.0, green: 0.4, blue: 0.0)
            secondaryColor = .black
            accentColor = .white
            teamIcon = "flame.circle.fill"
            
        case "Aprilia":
            primaryColor = Color(red: 0.0, green: 0.0, blue: 0.0)
            secondaryColor = .red
            accentColor = .red
            teamIcon = "a.circle.fill"
            
        default:
            primaryColor = .orange
            secondaryColor = .white
            accentColor = .orange
            teamIcon = "flag.checkered"
        }
        
        Logger.debug("[TeamTheme] Loaded theme for \(team): \(teamIcon)")
    }
}

// MARK: - SwiftUI Environment Key

@MainActor
struct TeamThemeKey: EnvironmentKey {
    static let defaultValue = TeamThemeService.shared
}

extension EnvironmentValues {
    @MainActor
    var teamTheme: TeamThemeService {
        get { self[TeamThemeKey.self] }
        set { self[TeamThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

struct TeamThemedBackground: ViewModifier {
    @ObservedObject var theme = TeamThemeService.shared
    
    func body(content: Content) -> some View {
        content
            .background(theme.backgroundGradient)
    }
}

extension View {
    func teamThemedBackground() -> some View {
        modifier(TeamThemedBackground())
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/AlertsViewModel.swift`

```swift
import Foundation
import Combine

enum AlertPriority: String, Codable {
    case high, medium, low
}

struct AppAlert: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let priority: AlertPriority
    let timestamp: Date
}

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [AppAlert] = []
    
    func fetchAlerts() {
        Task {
            do {
                let records = try await DatabaseClient.shared.read(table: "alerts")
                let fetchedAlerts = records.compactMap { dict -> AppAlert? in
                    guard let id = dict["id"] as? String ?? dict["_id"] as? String,
                          let title = dict["title"] as? String,
                          let message = dict["message"] as? String else { return nil }
                    
                    // Priority mapping
                    let priorityString = dict["priority"] as? String ?? "medium"
                    let priority = AlertPriority(rawValue: priorityString.lowercased()) ?? .medium
                    
                    // Timestamp
                    let ts = dict["timestamp"] as? Double ?? Date().timeIntervalSince1970 * 1000
                    let date = Date(timeIntervalSince1970: ts / 1000)
                    
                    return AppAlert(id: id, title: title, message: message, priority: priority, timestamp: date)
                }
                
                await MainActor.run {
                    self.alerts = fetchedAlerts
                    // If empty, keep mock for demo if needed, or show empty state
                    if self.alerts.isEmpty {
                        self.alerts = [
                            AppAlert(id: "mock1", title: "System Check", message: "Alert system is active. No current warnings.", priority: .low, timestamp: Date())
                        ]
                    }
                }
            } catch {
                Logger.error("[Alerts][ERROR] Failed to fetch alerts: \(error)")
                await MainActor.run {
                    // Fallback Mock
                    self.alerts = [
                       AppAlert(id: "err1", title: "Connection Error", message: "Could not fetch live alerts.", priority: .medium, timestamp: Date())
                    ]
                }
            }
        }
    }
    
    func timeAgo(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LocalizationUtils.locale
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/FanZoneViewModel.swift`

```swift
import Combine
import SwiftUI

// MARK: - Fan Zone ViewModel

/// Global state coordinator for Fan Zone.
/// Owns references to all Fan Zone services and propagates the selected team
/// across the entire app via TeamThemeService + UserPreferences.
@MainActor
final class FanZoneViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Currently selected championship
    @Published var selectedChampionship: Championship {
        didSet {
            guard oldValue != selectedChampionship else { return }
            UserPreferences.shared.favoriteSeries = selectedChampionship.rawValue
            // Auto-select first team in new championship if current team doesn't match
            if selectedTeam?.championship != selectedChampionship {
                let teams = catalog.teams(for: selectedChampionship)
                selectTeam(teams.first)
            }
        }
    }
    
    /// Currently selected team (full model)
    @Published private(set) var selectedTeam: RacingTeam?
    
    /// Team lists for current championship
    var availableTeams: [RacingTeam] {
        catalog.teams(for: selectedChampionship)
    }
    
    /// Convenience: team color
    var teamColor: Color {
        selectedTeam?.primarySwiftColor ?? RacingColors.red
    }
    
    /// Convenience: team secondary color
    var teamSecondaryColor: Color {
        selectedTeam?.secondarySwiftColor ?? .white
    }
    
    /// Active widgets for layout customization
    @Published var activeWidgets: Set<String> = ["news", "trivia", "collectibles"]
    
    /// Whether the full module has loaded
    @Published private(set) var isLoaded = false
    
    // MARK: - Services
    
    let catalog = TeamCatalogService.shared
    let questionService = QuestionService.shared
    let newsService = FanNewsService.shared
    let rewardService = RewardService.shared
    let assetManager = TeamAssetManager.shared
    
    // MARK: - Init
    
    init() {
        let series = UserPreferences.shared.favoriteSeries
        self.selectedChampionship = Championship(rawValue: series) ?? .f1
        
        // Restore selected team from preferences
        let teamId = UserPreferences.shared.favoriteTeamId
        if !teamId.isEmpty, let team = catalog.team(byId: teamId) {
            self.selectedTeam = team
        } else {
            // Fallback: match by name from old preference
            let teamName = UserPreferences.shared.favoriteTeam
            self.selectedTeam = catalog.teams.first { $0.name == teamName }
                ?? catalog.teams(for: selectedChampionship).first
        }
    }
    
    // MARK: - Load All Data
    
    /// Bootstrap all Fan Zone data (call from .task on FanZoneView)
    func loadAll() async {
        guard !isLoaded else { return }
        
        async let teamsTask: () = catalog.loadCatalog()
        async let questionsTask: () = questionService.loadQuestions()
        async let newsTask: () = newsService.refreshNews()
        async let rewardsTask: () = rewardService.loadCatalog()
        
        _ = await (teamsTask, questionsTask, newsTask, rewardsTask)
        
        // Re-resolve selected team after catalog reload
        if let id = selectedTeam?.id, let refreshed = catalog.team(byId: id) {
            selectedTeam = refreshed
        }
        
        // Record visit for rewards
        rewardService.recordFanZoneVisit()
        
        // Preload logos for current championship
        await assetManager.preloadLogos(for: availableTeams)
        
        isLoaded = true
        Logger.info("[FanZoneVM] All data loaded")
    }
    
    // MARK: - Team Selection
    
    /// Select a new team and propagate globally
    func selectTeam(_ team: RacingTeam?) {
        guard let team else { return }
        
        selectedTeam = team
        selectedChampionship = team.championship
        
        // Persist
        UserPreferences.shared.favoriteTeamId = team.id
        UserPreferences.shared.favoriteTeam = team.name
        UserPreferences.shared.favoriteSeries = team.championship.rawValue
        
        // Update global theme
        TeamThemeService.shared.refresh()
        
        Logger.info("[FanZoneVM] Team selected: \(team.name) (\(team.id))")
    }
    
    // MARK: - Widget Management
    
    func toggleWidget(_ id: String) {
        if activeWidgets.contains(id) {
            activeWidgets.remove(id)
        } else {
            activeWidgets.insert(id)
        }
    }
    
    func isWidgetActive(_ id: String) -> Bool {
        activeWidgets.contains(id)
    }
    
    // MARK: - Quick Access Helpers
    
    /// Get a quick trivia question for the current team
    func quickTrivia() -> QuizQuestion? {
        questionService.nextQuestion(
            championship: selectedChampionship,
            teamId: selectedTeam?.id
        )
    }
    
    /// Latest news count for badge
    var newsCount: Int {
        newsService.articles(for: selectedChampionship).count
    }
    
    /// Unlocked cards count
    var unlockedCardsCount: Int {
        rewardService.unlockedCards.count
    }
    
    /// Total cards
    var totalCardsCount: Int {
        rewardService.cardDefinitions.count
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/GroupViewModel.swift`

```swift
import Foundation
import Combine
import SwiftUI

class GroupViewModel: ObservableObject {
    @Published var isInGroup: Bool = false
    @Published var currentGroup: Group?
    @Published var members: [GroupMember] = []
    @Published var errorMsg: String?
    @Published var isLoading: Bool = false
    
    // Join Input
    @Published var joinCode: String = ""
    
    private var repository = GroupRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to Repository changes
        repository.$currentGroup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                self?.currentGroup = group
                self?.isInGroup = (group != nil)
            }
            .store(in: &cancellables)
            
        repository.$groupMembers
            .receive(on: DispatchQueue.main)
            .assign(to: \.members, on: self)
            .store(in: &cancellables)
    }
    
    @MainActor
    func createGroup() async {
        isLoading = true
        errorMsg = nil
        do {
            _ = try await repository.createGroup()
        } catch {
            errorMsg = "Error creating group: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func joinGroup() async {
        guard !joinCode.isEmpty else { return }
        isLoading = true
        errorMsg = nil
        do {
            try await repository.joinGroup(groupId: joinCode)
        } catch {
            errorMsg = "Error joining group: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func leaveGroup() {
        repository.leaveGroup()
        joinCode = ""
    }
    
    func getInviteLink() -> String {
        return repository.generateInviteLink()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/GuidanceViewModel.swift`

```swift
import Foundation
import CoreLocation
import Combine

@MainActor
class GuidanceViewModel: ObservableObject {
    let itinerary: Itinerary
    
    @Published var currentStepIndex: Int = 0
    @Published var currentLeg: Leg?
    @Published var distanceToNextStop: Double = 0
    @Published var estimatedTimeRemaining: TimeInterval = 0
    @Published var feedbackMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let speechService = SpeechService.shared
    private let locationManager = LocationManager.shared
    
    init(itinerary: Itinerary) {
        self.itinerary = itinerary
        if let first = itinerary.legs.first {
            self.currentLeg = first
            self.distanceToNextStop = first.distance ?? 0
            speakCurrentLeg(first)
        }
        
        startMonitoring()
    }
    
    private func startMonitoring() {
        locationManager.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.checkProgress(userLoc: location)
            }
            .store(in: &cancellables)
    }
    
    private func checkProgress(userLoc: CLLocationCoordinate2D) {
        guard let leg = currentLeg else { return }
        
        let destLoc = CLLocation(latitude: leg.to.lat, longitude: leg.to.lon)
        let userCLLoc = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        
        let dist = userCLLoc.distance(from: destLoc)
        self.distanceToNextStop = dist
        
        // Thresholds: Walk (20m), Bus/Train (300m - stations are big/GPS in tunnel)
        let threshold = (leg.mode == "WALK") ? 20.0 : 300.0
        
        if dist < threshold {
            advanceStep()
        }
    }
    
    func advanceStep() {
        if currentStepIndex < itinerary.legs.count - 1 {
            currentStepIndex += 1
            currentLeg = itinerary.legs[currentStepIndex]
            if let leg = currentLeg {
                speakCurrentLeg(leg)
            }
        } else {
            // Finished
            speechService.speak("Has llegado a tu destino. Disfruta de la carrera.")
            // Could trigger a finished state
            feedbackMessage = "¡Ruta Completada!"
        }
    }
    
    func prevStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            currentLeg = itinerary.legs[currentStepIndex]
        }
    }
    
    private func speakCurrentLeg(_ leg: Leg) {
        // Construct natural language instruction
        var text = ""
        switch leg.mode {
        case "WALK":
            text = String(format: LocalizationUtils.string("Walk to %@. You are %d meters away."), leg.to.name, Int(leg.distance ?? 0))
        case "BUS":
            text = String(format: LocalizationUtils.string("Board bus %@ towards %@."), leg.routeShortName ?? "", leg.to.name)
        case "RAIL", "SUBWAY":
            text = String(format: LocalizationUtils.string("Take train %@ direction %@."), leg.routeShortName ?? "", leg.routeLongName ?? leg.to.name)
        default:
            text = String(format: LocalizationUtils.string("Head to %@"), leg.to.name)
        }
        
        speechService.speak(text)
    }
    
    func skipInstruction() {
        advanceStep()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/HomeViewModel.swift`

```swift
import Foundation
import SwiftUI
import Combine

struct WeatherInfo {
    let tempC: Double
    let condition: String // "Sun", "Cloud", "Rain"
    let iconName: String
}

struct NewsItem: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let imageUrl: String // Asset name or URL
    let isEvent: Bool
}

// ... TrackStatus is now in Domain/Models/TrackStatus.swift ...

@MainActor
class HomeViewModel: ObservableObject {

    @Published var weather: WeatherInfo?
    @Published var currentTrackStatus: TrackStatus = .green // Default
    @Published var greeting: String = ""
    
    // We keep NewsItem for other cards if needed, but Hero is now Status
    @Published var newsItems: [NewsItem] = []
    
    init() {
        updateGreeting()
        loadWidgets()
        fetchData()
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { greeting = LocalizationUtils.string("Good Morning") }
        else if hour < 18 { greeting = LocalizationUtils.string("Good Afternoon") }
        else { greeting = LocalizationUtils.string("Good Evening") }
    }
    
    func fetchData() {
        // Mock Weather (No API found yet)
        self.weather = WeatherInfo(tempC: 22.5, condition: "Sunny", iconName: "sun.max.fill")
            
        // Fetch News
        Task {
            do {
                let articles = try await NewsRepository.shared.fetchNews()
                let items = articles.map { article in
                    NewsItem(
                        id: article.id,
                        title: article.title,
                        subtitle: article.subtitle,
                        imageUrl: article.imageUrl ?? "circuit_hero",
                        isEvent: false // Default to false unless flagged
                    )
                }
                await MainActor.run {
                    self.newsItems = items
                }
            } catch {
                Logger.error("[Home][ERROR] Failed to fetch news: \(error)")
                // Keep Mock if fail? Or empty?
                // Let's keep one mock item if empty so UI isn't broken
                if self.newsItems.isEmpty {
                     await MainActor.run {
                         self.newsItems = [
                            NewsItem(id: "mock1", title: "Welcome to GeoRacing", subtitle: "Live updates from the circuit", imageUrl: "circuit_hero", isEvent: true)
                         ]
                     }
                }
            }
        }
    }
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationUtils.locale
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // MARK: - Dashboard Customization
    
    @Published var activeWidgetIds: [String] = []
    
    static let allAvailableWidgets: [DashboardWidget] = [
        DashboardWidget(id: "map", icon: "map.fill", titleKey: "Map", color: .blue),
        DashboardWidget(id: "shop", icon: "cart.fill", titleKey: "Shop", color: .green),
        DashboardWidget(id: "food", icon: "fork.knife", titleKey: "Food", color: .orange),
        DashboardWidget(id: "wc", icon: "toilet.fill", titleKey: "WC", color: .purple),
        DashboardWidget(id: "parking", icon: "parkingsign.circle.fill", titleKey: "Parking", color: .gray),
        DashboardWidget(id: "schedule", icon: "calendar", titleKey: "Schedule", color: .pink),
        DashboardWidget(id: "social", icon: "person.2.fill", titleKey: "Social", color: .indigo),
        DashboardWidget(id: "incidents", icon: "exclamationmark.shield.fill", titleKey: "Incidents", color: RacingColors.red),
        // NEW WIDGETS
        DashboardWidget(id: "tickets", icon: "ticket.fill", titleKey: "Billetes", color: .teal),
        DashboardWidget(id: "video", icon: "play.tv.fill", titleKey: "Live TV", color: .pink),
        DashboardWidget(id: "weather", icon: "cloud.sun.fill", titleKey: "El Tiempo", color: .cyan),
        DashboardWidget(id: "profile", icon: "person.crop.circle", titleKey: "Perfil", color: .gray),
        DashboardWidget(id: "fanzone", icon: "flag.2.crossed.fill", titleKey: "Fan Zone", color: .orange) // NEW
    ]
    
    func loadWidgets() {
        self.activeWidgetIds = UserPreferences.shared.dashboardWidgets
    }
    
    func updateWidgets(_ newOrder: [String]) {
        self.activeWidgetIds = newOrder
        UserPreferences.shared.dashboardWidgets = newOrder
    }
}

struct DashboardWidget: Identifiable, Equatable {
    let id: String
    let icon: String
    let titleKey: String
    let color: Color
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/IncidentViewModel.swift`

```swift
import Foundation
import Combine
// Apps usually share module, so APIService should be available.
// But we used IncidentReportDto which is defined in APIService file. 
// Ideally DTOs should be in Domain or Data/Models. 
// For now, if APIService.swift is target member, it's fine.


@MainActor
class IncidentViewModel: ObservableObject {
    
    @Published var description: String = ""
    @Published var selectedCategory: IncidentCategory = .medical
    @Published var isSubmitting = false
    @Published var submissionError: String?
    @Published var submissionSuccess = false
    
    private let beaconScanner: BeaconScanner
    
    init(beaconScanner: BeaconScanner? = nil) {
        self.beaconScanner = beaconScanner ?? BeaconScanner.shared
    }
    
    func submit() {
        guard !description.isEmpty else {
            submissionError = LocalizationUtils.string("Description cannot be empty.")
            return
        }
        
        guard let _ = AuthService.shared.currentUser else {
             submissionError = LocalizationUtils.string("You must be logged in to report.")
             return
        }
        
        isSubmitting = true
        submissionError = nil
        
        // Use current beacon if available
        let beaconId = beaconScanner.currentBeacon?.id
        
        let report = IncidentReportDto(
            category: selectedCategory.rawValue,
            description: description,
            beacon_id: beaconId,
            zone: nil,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        Task {
            do {
                try await APIService.shared.sendIncident(report)
                self.isSubmitting = false
                self.submissionSuccess = true
                self.description = ""
            } catch {
                self.isSubmitting = false
                self.submissionError = LocalizationUtils.string("Failed to submit: \(error.localizedDescription)")
            }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/MapViewModel.swift`

```swift
import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

@MainActor
class MapViewModel: ObservableObject {

    @Published var circuit: Circuit?
    @Published var pois: [Poi] = []
    @Published var beacons: [BeaconConfig] = []
    @Published var filteredPOIs: [Poi] = []
    @Published var selectedCategory: PoiType? = nil
    @Published var isLoading = false
    
    // Map State
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.570, longitude: 2.260),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // user & friends location
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var friends: [GroupMember] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let groupRepository = GroupRepository.shared
    private let navigationService = NavigationService.shared
    private let speechService = SpeechService.shared
    
    // ... (Navigation State fields remain same)

    // ... (init remains same)

    // ...


    
    // Navigation State
    @Published var activeRoute: NavigationRoute?
    @Published var routePolyline: MKPolyline?
    @Published var transportMode: TransportMode = .automobile
    @Published var isCalculatingRoute = false
    @Published var showNavigationOverlay = false
    @Published var navigationError: String?
    
    // Web Navigation (for Transit) -- Deprecated/Removed in favor of Native Sheet
    @Published var activeWebUrl: URL?
    @Published var showWebNavigation = false
    
    // Native OpenTripPlanner Sheet
    @Published var showTransportSheet = false
    
    // Turn-by-Turn State
    @Published var currentStepIndex: Int = 0
    @Published var userTrackingMode: MapUserTrackingMode = .follow
    

    

    // Annotations for Map
    @Published var allAnnotations: [MapAnnotationItem] = []
    
    // Thermal Navigation (Shadow Zones)
    @Published var shadowPolygons: [MKPolygon] = []

    init() {
        // Load dummy data or fetch
        // For MVP, we setup a dummy circuit (Barcelona style for coords match Repository mocks)
        let montmelo = Circuit(
            name: "Circuit de Barcelona-Catalunya",
            bounds: MapBounds(minLat: 41.560, maxLat: 41.580, minLon: 2.250, maxLon: 2.270),
            imageAssetName: "circuit_map_base"
        )
        self.circuit = montmelo
        
        // Init region based on circuit
        self.region = MKCoordinateRegion(
            center: montmelo.bounds.center,
            span: MKCoordinateSpan(latitudeDelta: (montmelo.bounds.maxLat - montmelo.bounds.minLat) * 1.2,
                                   longitudeDelta: (montmelo.bounds.maxLon - montmelo.bounds.minLon) * 1.2)
        )
        
        // Load Thermal Routing Polygons
        self.shadowPolygons = ThermalRoutingService.shared.getShadowPolygons()
        
        setupPipelines()
        
        // Call loadPOIs when the view model is initialized
        loadPOIs()
        loadBeacons()
        setupGroupSubscription()
        setupLocationSubscription()
    }
    
    private func setupPipelines() {
        // Combine filteredPOIs, friends, and beacons into one annotation list
        Publishers.CombineLatest3($filteredPOIs, $friends, $beacons)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main) // Debounce to avoid rapid updates
            .map { [weak self] (pois, friends, beacons) -> [MapAnnotationItem] in
                guard let self = self else { return [] }
                var items: [MapAnnotationItem] = []
                
                // POIs
                for poi in pois {
                    let coord = self.coordinate(forX: poi.mapX, y: poi.mapY)
                    items.append(MapAnnotationItem(id: "poi_\(poi.id)", coordinate: coord, type: .poi(poi)))
                }
                
                // Friends
                for friend in friends {
                    if let coord = friend.coordinate {
                        items.append(MapAnnotationItem(id: "friend_\(friend.id)", coordinate: coord, type: .friend(friend)))
                    }
                }
                
                // Beacons
                for beacon in beacons {
                    let coord = self.coordinate(forX: beacon.mapX, y: beacon.mapY)
                    items.append(MapAnnotationItem(id: "beacon_\(beacon.id)", coordinate: coord, type: .beacon(beacon)))
                }
                return items
            }
            .assign(to: \.allAnnotations, on: self)
            .store(in: &cancellables)
    }

    private func setupLocationSubscription() {
        LocationManager.shared.$location
            .receive(on: DispatchQueue.main)
            .assign(to: \.userLocation, on: self)
            .store(in: &cancellables)
            
        // Monitor Navigation Progress
        LocationManager.shared.$location
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.monitorRouteProgress(location: location)
            }
            .store(in: &cancellables)
    }
    
    /// Checks distance to next step and advances if close
    private func monitorRouteProgress(location: CLLocationCoordinate2D) {
        guard let route = activeRoute, showNavigationOverlay else { return }
        guard currentStepIndex < route.steps.count else { return }
        
        let step = route.steps[currentStepIndex]
        let stepLoc = CLLocation(latitude: step.polyline.coordinate.latitude, longitude: step.polyline.coordinate.longitude)
        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        // Thresholds: 30m for driving, 10m for walking
        let threshold = transportMode == .walking ? 15.0 : 30.0
        
        if userLoc.distance(from: stepLoc) < threshold {
            // We reached the step point (approx), advance to next instruction
            if currentStepIndex < route.steps.count - 1 {
                currentStepIndex += 1
                speakCurrentStep()
            } else {
                // Arrived at destination
                speechService.speak("\(LocalizationUtils.string("You have arrived at your destination.")) \(route.destinationName)")
                endNavigation()
            }
        }
    }

    private func setupGroupSubscription() {
        groupRepository.$groupMembers
            .receive(on: DispatchQueue.main)
            .assign(to: \.friends, on: self)
            .store(in: &cancellables)
    }

    func loadPOIs() {
        isLoading = true
        Task {
            do {
                let fetchedDtos = try await APIService.shared.fetchPois()
                let mapped = fetchedDtos.map { Poi(from: $0) }
                self.pois = mapped
                self.filterPOIs(by: self.selectedCategory)
                self.isLoading = false
            } catch {
                Logger.error("[MapViewModel] Failed to fetch POIs: \(error)")
                // Fallback to mock or empty
                let fallbackDtos = [
                    PoiDto(id: "1", name: "Food Court", type: "FOOD", description: "Comida rapida", zone: "A", map_x: 0.55, map_y: 0.52),
                    PoiDto(id: "2", name: "WC Zone A", type: "WC", description: "Servicios", zone: "A", map_x: 0.42, map_y: 0.60)
                ]
                self.pois = fallbackDtos.map { Poi(from: $0) }
                self.filterPOIs(by: self.selectedCategory)
                self.isLoading = false
            }
        }
    }

    func loadBeacons() {
        Task {
            do {
                let fetched = try await APIService.shared.fetchBeacons()
                let mapped = fetched.map { BeaconConfig(from: $0) }
                self.beacons = mapped
            } catch {
                Logger.error("[MapViewModel] Failed to fetch beacons: \(error)")
            }
        }
    }
    
    func filterPOIs(by category: PoiType?) {
        self.selectedCategory = category
        if let category = category {
            filteredPOIs = pois.filter { $0.type == category }
        } else {
            filteredPOIs = pois
        }
    }
    
    // MARK: - Coordinate Mapping
    
    func coordinate(forX mapX: Float, y mapY: Float) -> CLLocationCoordinate2D {
        guard let bounds = circuit?.bounds else { return CLLocationCoordinate2D(latitude: 0, longitude: 0) }
        
        // Lat: Lower Lat is "Bottom". Upper Lat is "Top".
        // In screen coords/Map coords (0-1), Top is 0, Bottom is 1.
        // normalizedY = 1 - (lat - min) / range  ->  lat - min = (1 - normY) * range -> lat = min + (1-normY)*range
        // Wait, previously: normalizedY = 1.0 - ((lat - min) / range)
        // So: (lat - min)/range = 1.0 - normalizedY
        // lat - min = range * (1.0 - normalizedY)
        // lat = min + range * (1.0 - mapY)
        
        let latRange = bounds.maxLat - bounds.minLat
        let lonRange = bounds.maxLon - bounds.minLon
        
        let latitude = bounds.minLat + (latRange * Double(1.0 - mapY))
        let longitude = bounds.minLon + (lonRange * Double(mapX))
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Converts a GPS coordinate to a normalized (0-1) point relative to the circuit bounds.
    func normalizeCoordinate(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        guard let bounds = circuit?.bounds else { return .zero }
        
        let latRange = bounds.maxLat - bounds.minLat
        let lonRange = bounds.maxLon - bounds.minLon
        
        // Safety check dev/zero
        if latRange == 0 || lonRange == 0 { return .zero }
        
        let normalizedX = (coordinate.longitude - bounds.minLon) / lonRange
        let normalizedY = 1.0 - ((coordinate.latitude - bounds.minLat) / latRange)
        
        return CGPoint(x: normalizedX, y: normalizedY)
    }
    
    // MARK: - Navigation
    
    @Published var transportDestination: CLLocationCoordinate2D?
    @Published var transportDestinationName: String?

    /// Calculate route to the circuit
    /// Calculate route to the circuit (Smart Routing to nearest Gate/Parking)
    func calculateRouteToCircuit() {
        guard let origin = userLocation else {
            navigationError = LocalizationUtils.string("Could not get your location")
            return
        }
        var bestDestination: CLLocationCoordinate2D?
        var bestName: String = "Circuit de Barcelona-Catalunya"
        
        let gates = pois.filter { $0.type == .gate }
        if !gates.isEmpty {
            // Find nearest to user
            let userLoc = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            
            let sorted = gates.sorted { p1, p2 in
                let c1 = coordinate(forX: p1.mapX, y: p1.mapY)
                let c2 = coordinate(forX: p2.mapX, y: p2.mapY)
                let d1 = userLoc.distance(from: CLLocation(latitude: c1.latitude, longitude: c1.longitude))
                let d2 = userLoc.distance(from: CLLocation(latitude: c2.latitude, longitude: c2.longitude))
                return d1 < d2
            }
            
            if let best = sorted.first {
                bestDestination = coordinate(forX: best.mapX, y: best.mapY)
                bestName = best.name
            }
        }
        
        self.transportDestination = bestDestination
        self.transportDestinationName = bestName
        
        // Transit Check - Use Native Public Transport Sheet
        if transportMode == .transit {
            Task { @MainActor in
                self.showTransportSheet = true
                self.isCalculatingRoute = false
            }
            return
        }
        
        let destination = bestDestination
        let name = bestName
        
        Task {
            do {
                let route: NavigationRoute
                if let dest = destination {
                    route = try await navigationService.calculateRoute(
                        from: origin,
                        to: dest,
                        destinationName: name,
                        transportMode: transportMode
                    )
                } else {
                     route = try await navigationService.calculateRouteToCircuit(
                        from: origin,
                        transportMode: transportMode
                    )
                }
                
                await MainActor.run {
                    self.activeRoute = route
                    self.routePolyline = route.route.polyline
                    self.showNavigationOverlay = true
                    self.isCalculatingRoute = false
                    self.currentStepIndex = 0 // Start at first step
                    self.userTrackingMode = .followWithHeading // Waze-style tracking
                    self.zoomToRoute(route.route)
                    self.speakCurrentStep()
                }
            } catch {
                await MainActor.run {
                    // Start navigation error handling
                    self.navigationError = String(format: LocalizationUtils.string("Route calculation error"), error.localizedDescription)
                    self.isCalculatingRoute = false
                }
            }
        }
    }
    
    /// Advance to next step
    func nextStep() {
        guard let route = activeRoute, currentStepIndex < route.steps.count - 1 else { return }
        currentStepIndex += 1
        speakCurrentStep()
    }
    
    /// Go back to previous step
    func prevStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        speakCurrentStep()
    }
    
    private func speakCurrentStep() {
        guard let route = activeRoute, currentStepIndex < route.steps.count else { return }
        let step = route.steps[currentStepIndex]
        if !step.instructions.isEmpty {
            speechService.speak(step.instructions)
        }
    }
    
    /// Calculate route to a specific POI
    func calculateRouteToPOI(_ poi: Poi) {
        guard let origin = userLocation else {
            navigationError = LocalizationUtils.string("Could not get your location")
            return
        }
        
        let destination = coordinate(forX: poi.mapX, y: poi.mapY)
        
        // Transit Check - Use Native Public Transport Sheet
        if transportMode == .transit {
            Task {
                await MainActor.run {
                    self.showTransportSheet = true
                    self.isCalculatingRoute = false
                }
            }
            return
        }
        
        isCalculatingRoute = true
        navigationError = nil
        
        Task {
            do {
                let route = try await navigationService.calculateRoute(
                    from: origin,
                    to: destination,
                    destinationName: poi.name,
                    transportMode: transportMode
                )
                
                await MainActor.run {
                    self.activeRoute = route
                    self.routePolyline = route.route.polyline
                    self.showNavigationOverlay = true
                    self.isCalculatingRoute = false
                    self.currentStepIndex = 0
                    self.userTrackingMode = .followWithHeading
                    self.zoomToRoute(route.route)
                    self.speakCurrentStep()
                }
            } catch {
                await MainActor.run {
                    self.navigationError = error.localizedDescription
                    self.isCalculatingRoute = false
                }
            }
        }
    }
    
    /// Change transport mode and recalculate route
    func setTransportMode(_ mode: TransportMode) {
        transportMode = mode
        if activeRoute != nil {
            calculateRouteToCircuit()
        }
    }
    
    /// Clear active navigation
    func endNavigation() {
        activeRoute = nil
        routePolyline = nil
        showNavigationOverlay = false
        activeWebUrl = nil
        showWebNavigation = false
    }
    
    /// Open current route in Apple Maps
    func openInAppleMaps() {
        guard let route = activeRoute else { return }
        navigationService.openInAppleMaps(
            destination: route.destination,
            destinationName: route.destinationName,
            transportMode: route.transportMode
        )
    }
    
    /// Zoom map to show the entire route
    private func zoomToRoute(_ route: MKRoute) {
        let rect = route.polyline.boundingMapRect
        
        withAnimation {
            region = MKCoordinateRegion(rect.insetBy(dx: -rect.width * 0.1, dy: -rect.height * 0.1))
        }
    }
}

// MARK: - Map Items Unified
enum MapItemType {
    case poi(Poi)
    case friend(GroupMember)
    case beacon(BeaconConfig)
}

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: MapItemType
}

enum MapUserTrackingMode {
    case none
    case follow
    case followWithHeading
}



```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/NavigationViewModel.swift`

```swift
import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

// MARK: - Default Destination

/// Central constant for the circuit destination used throughout the app.
enum DefaultDestination {
    static let name = "Circuit de Barcelona-Catalunya"
    static let coordinate = CLLocationCoordinate2D(latitude: 41.5700, longitude: 2.2610)
}

// MARK: - Navigation State

enum NavigationState: Equatable {
    case idle              // Waiting to start
    case calculatingRoute  // Computing route via MKDirections
    case navigating        // Active turn-by-turn
    case arrived           // User reached destination
    case error(String)     // Something failed
}

// MARK: - NavigationViewModel

/// Real GPS navigation view model with turn-by-turn, rerouting, and live tracking.
@MainActor
class NavigationViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current navigation state
    @Published var state: NavigationState = .idle
    
    /// Destination
    @Published var destinationName: String = DefaultDestination.name
    @Published var destinationCoordinate: CLLocationCoordinate2D = DefaultDestination.coordinate
    
    /// Computed route
    @Published var route: MKRoute?
    @Published var polyline: MKPolyline?
    
    /// Turn-by-turn steps
    @Published var steps: [MKRoute.Step] = []
    @Published var currentStepIndex: Int = 0
    
    /// Live metrics
    @Published var remainingDistance: CLLocationDistance = 0  // meters
    @Published var remainingTime: TimeInterval = 0           // seconds
    @Published var eta: Date?
    @Published var nextInstruction: String = ""
    @Published var nextStepDistance: CLLocationDistance = 0
    
    /// Transport mode
    @Published var transportMode: TransportMode = .automobile {
        didSet {
            guard oldValue != transportMode else { return }
            if transportMode == .transit && state == .navigating {
                // Stop in-app nav, user will use Apple Maps for transit
                stopNavigation()
            } else if state == .navigating {
                recalculateRoute(reason: "mode_change")
            }
        }
    }
    
    /// Transit: flag to open Apple Maps with transit directions
    @Published var showTransitAction: Bool = false
    
    /// Map control
    @Published var mapRegion = MKCoordinateRegion(
        center: DefaultDestination.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @Published var isFollowingUser: Bool = true
    
    /// Reroute indicator
    @Published var isRerouting: Bool = false
    
    // MARK: - Private
    
    private let locationManager = LocationManager.shared
    private let speechService = SpeechService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Reroute throttle: minimum seconds between reroutes
    private let rerouteThrottleInterval: TimeInterval = 15
    private var lastRerouteTime: Date = .distantPast
    
    /// Off-route detection: how many consecutive off-route samples before trigger
    private var offRouteCounter: Int = 0
    private let offRouteThreshold: Int = 3          // 3 consecutive samples
    private let offRouteDistanceMeters: Double = 50 // 50m from route
    
    /// Arrival radius
    private let arrivalRadius: Double = 30 // meters
    
    // MARK: - Init
    
    init() {
        setupLocationSubscription()
    }
    
    // MARK: - Location Pipeline
    
    private func setupLocationSubscription() {
        locationManager.$clLocation
            .compactMap { $0 }
            .removeDuplicates { old, new in
                old.coordinate.latitude == new.coordinate.latitude &&
                old.coordinate.longitude == new.coordinate.longitude
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        guard state == .navigating, route != nil else { return }
        
        updateLiveMetrics(from: location)
        checkStepAdvance(from: location)
        checkArrival(from: location)
        checkOffRoute(from: location)
    }
    
    // MARK: - Public Actions
    
    /// Start navigation to the default circuit destination.
    func startNavigation() {
        destinationName = DefaultDestination.name
        destinationCoordinate = DefaultDestination.coordinate
        
        if transportMode == .transit {
            openTransitInAppleMaps()
            return
        }
        calculateAndBeginRoute()
    }
    
    /// Start navigation to a custom destination.
    func startNavigation(to coordinate: CLLocationCoordinate2D, name: String) {
        destinationName = name
        destinationCoordinate = coordinate
        
        if transportMode == .transit {
            openTransitInAppleMaps()
            return
        }
        calculateAndBeginRoute()
    }
    
    /// Open Apple Maps with transit directions to the destination.
    func openTransitInAppleMaps() {
        let destinationItem = MKMapItem.fromCoordinate(destinationCoordinate)
        destinationItem.name = destinationName
        destinationItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit
        ])
    }
    
    /// Stop navigation and reset.
    func stopNavigation() {
        speechService.stop()
        state = .idle
        route = nil
        polyline = nil
        steps = []
        currentStepIndex = 0
        remainingDistance = 0
        remainingTime = 0
        eta = nil
        nextInstruction = ""
        nextStepDistance = 0
        isRerouting = false
        offRouteCounter = 0
    }
    
    /// Recenter map on user.
    func recenterOnUser() {
        guard let loc = locationManager.location else { return }
        isFollowingUser = true
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    }
    
    /// Zoom to show the entire route.
    func zoomToRoute() {
        guard let route else { return }
        let rect = route.polyline.boundingMapRect
        let padded = rect.insetBy(dx: -rect.width * 0.15, dy: -rect.height * 0.15)
        withAnimation {
            mapRegion = MKCoordinateRegion(padded)
        }
    }
    
    // MARK: - Route Calculation
    
    private func calculateAndBeginRoute() {
        guard let origin = locationManager.location else {
            state = .error(LocalizationUtils.string("Could not get your location"))
            return
        }
        
        state = .calculatingRoute
        
        Task {
            do {
                let mkRoute = try await calculateRoute(
                    from: origin,
                    to: destinationCoordinate,
                    mode: transportMode
                )
                
                self.route = mkRoute
                self.polyline = mkRoute.polyline
                self.steps = mkRoute.steps.filter { !$0.instructions.isEmpty }
                self.currentStepIndex = 0
                self.remainingDistance = mkRoute.distance
                self.remainingTime = mkRoute.expectedTravelTime
                self.eta = Date().addingTimeInterval(mkRoute.expectedTravelTime)
                self.offRouteCounter = 0
                self.state = .navigating
                
                updateNextInstruction()
                speakCurrentStep()
                zoomToRoute()
                
                // Auto-follow after brief overview
                try? await Task.sleep(for: .seconds(2))
                recenterOnUser()
                
            } catch {
                Logger.error("[NavigationVM] Route error: \(error)")
                self.state = .error(error.localizedDescription)
            }
        }
    }
    
    private func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TransportMode
    ) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem.fromCoordinate(origin)
        request.destination = MKMapItem.fromCoordinate(destination)
        request.transportType = mode.mkDirectionsTransportType
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw NavigationError.noRouteFound
        }
        return route
    }
    
    // MARK: - Live Metrics
    
    private func updateLiveMetrics(from location: CLLocation) {
        // Remaining distance = sum of remaining step distances
        var remaining: CLLocationDistance = 0
        for i in currentStepIndex..<steps.count {
            remaining += steps[i].distance
        }
        // Add distance from current position to current step endpoint
        if currentStepIndex < steps.count {
            let stepCoord = steps[currentStepIndex].polyline.coordinate
            let stepLoc = CLLocation(latitude: stepCoord.latitude, longitude: stepCoord.longitude)
            let toStep = location.distance(from: stepLoc)
            // Replace step's full distance with actual distance-to-step
            remaining = remaining - steps[currentStepIndex].distance + toStep
        }
        
        remainingDistance = max(remaining, 0)
        
        // ETA based on current speed or route expected time
        if location.speed > 1 {
            remainingTime = remainingDistance / location.speed
        } else if let route {
            // Estimate proportionally
            let fraction = remainingDistance / max(route.distance, 1)
            remainingTime = route.expectedTravelTime * fraction
        }
        eta = Date().addingTimeInterval(remainingTime)
    }
    
    // MARK: - Step Advance
    
    private func checkStepAdvance(from location: CLLocation) {
        guard currentStepIndex < steps.count else { return }
        
        let step = steps[currentStepIndex]
        let stepCoord = step.polyline.coordinate
        let stepLoc = CLLocation(latitude: stepCoord.latitude, longitude: stepCoord.longitude)
        let dist = location.distance(from: stepLoc)
        
        // Threshold depends on transport mode and speed
        let threshold: Double = transportMode == .walking ? 15 : 35
        
        if dist < threshold && currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            updateNextInstruction()
            speakCurrentStep()
            offRouteCounter = 0 // Reset off-route when advancing
        }
        
        // Update distance to next step
        nextStepDistance = dist
    }
    
    // MARK: - Arrival Detection
    
    private func checkArrival(from location: CLLocation) {
        let destLoc = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        let dist = location.distance(from: destLoc)
        
        if dist < arrivalRadius {
            speechService.speak(LocalizationUtils.string("You have arrived at your destination."))
            state = .arrived
        }
    }
    
    // MARK: - Off-Route / Reroute
    
    private func checkOffRoute(from location: CLLocation) {
        guard let route else { return }
        
        // Find minimum distance from user to any point on the route polyline
        let distToRoute = minimumDistance(from: location, to: route.polyline)
        
        if distToRoute > offRouteDistanceMeters {
            offRouteCounter += 1
            if offRouteCounter >= offRouteThreshold {
                recalculateRoute(reason: "off_route")
            }
        } else {
            offRouteCounter = 0
        }
    }
    
    /// Recalculate route from current position (throttled).
    private func recalculateRoute(reason: String) {
        let now = Date()
        guard now.timeIntervalSince(lastRerouteTime) > rerouteThrottleInterval else { return }
        guard !isRerouting else { return }
        
        Logger.info("[NavigationVM] Rerouting: \(reason)")
        lastRerouteTime = now
        isRerouting = true
        offRouteCounter = 0
        
        speechService.speak(LocalizationUtils.string("Recalculating route"))
        
        Task {
            guard let origin = locationManager.location else {
                isRerouting = false
                return
            }
            
            do {
                let mkRoute = try await calculateRoute(
                    from: origin,
                    to: destinationCoordinate,
                    mode: transportMode
                )
                
                self.route = mkRoute
                self.polyline = mkRoute.polyline
                self.steps = mkRoute.steps.filter { !$0.instructions.isEmpty }
                self.currentStepIndex = 0
                self.remainingDistance = mkRoute.distance
                self.remainingTime = mkRoute.expectedTravelTime
                self.eta = Date().addingTimeInterval(mkRoute.expectedTravelTime)
                self.isRerouting = false
                
                updateNextInstruction()
                speakCurrentStep()
                
            } catch {
                Logger.error("[NavigationVM] Reroute failed: \(error)")
                isRerouting = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private func updateNextInstruction() {
        if currentStepIndex < steps.count {
            nextInstruction = steps[currentStepIndex].instructions
        } else {
            nextInstruction = LocalizationUtils.string("You have arrived at your destination.")
        }
    }
    
    private func speakCurrentStep() {
        guard currentStepIndex < steps.count else { return }
        let step = steps[currentStepIndex]
        if !step.instructions.isEmpty {
            speechService.speak(step.instructions)
        }
    }
    
    /// Find minimum distance from a point to any coordinate along an MKPolyline.
    private func minimumDistance(from location: CLLocation, to polyline: MKPolyline) -> CLLocationDistance {
        let points = polyline.points()
        let count = polyline.pointCount
        
        var minDist: CLLocationDistance = .greatestFiniteMagnitude
        
        // Sample every few points for performance (full polyline can be thousands of points)
        let stride = max(1, count / 200)
        for i in Swift.stride(from: 0, to: count, by: stride) {
            let mapPoint = points[i]
            let coord = mapPoint.coordinate
            let pointLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let dist = location.distance(from: pointLoc)
            if dist < minDist {
                minDist = dist
            }
        }
        
        return minDist
    }
    
    // MARK: - Formatted Strings
    
    var formattedDistance: String {
        if remainingDistance >= 1000 {
            return String(format: "%.1f km", remainingDistance / 1000)
        } else {
            return String(format: "%.0f m", remainingDistance)
        }
    }
    
    var formattedETA: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
    
    var formattedETATime: String {
        guard let eta else { return "--:--" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: eta)
    }
    
    var formattedNextStepDistance: String {
        if nextStepDistance >= 1000 {
            return String(format: "%.1f km", nextStepDistance / 1000)
        } else {
            return String(format: "%.0f m", nextStepDistance)
        }
    }
    
    /// Icon for the current maneuver based on step instructions.
    var maneuverIcon: String {
        let inst = nextInstruction.lowercased()
        if inst.contains("left") || inst.contains("izquierda") || inst.contains("esquerra") {
            return "arrow.turn.up.left"
        } else if inst.contains("right") || inst.contains("derecha") || inst.contains("dreta") {
            return "arrow.turn.up.right"
        } else if inst.contains("u-turn") || inst.contains("media vuelta") || inst.contains("mitja volta") {
            return "arrow.uturn.down"
        } else if inst.contains("roundabout") || inst.contains("rotonda") || inst.contains("rotonda") {
            return "arrow.triangle.turn.up.right.circle"
        } else if inst.contains("merge") || inst.contains("incorpor") {
            return "arrow.merge"
        } else if inst.contains("exit") || inst.contains("salida") || inst.contains("sortida") {
            return "arrow.up.right"
        } else if inst.contains("destination") || inst.contains("destino") || inst.contains("destinació") {
            return "flag.checkered"
        } else {
            return "arrow.up"
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/OrdersViewModel.swift`

```swift
import Foundation
import Combine

@MainActor
final class OrdersViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var cart: [String: CartItem] = [:]
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var showSuccessDialog = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String?
    
    // MARK: - Computed Properties
    
    var cartItems: [CartItem] {
        Array(cart.values).sorted { $0.product.name < $1.product.name }
    }
    
    var cartTotal: Double {
        cart.values.reduce(0) { $0 + $1.subtotal }
    }
    
    var cartItemCount: Int {
        cart.values.reduce(0) { $0 + $1.quantity }
    }
    
    var filteredProducts: [Product] {
        guard let category = selectedCategory else {
            return products.filter { $0.isActive }
        }
        return products.filter { $0.isActive && $0.category.lowercased() == category.lowercased() }
    }
    
    var isCartEmpty: Bool {
        cart.isEmpty
    }
    
    var categories: [String] {
        let cats = Set(products.map { $0.category.lowercased() })
        return Array(cats).sorted()
    }
    
    // MARK: - Dependencies
    
    private let repository: OrdersRepositoryProtocol
    private let authService: AuthService
    
    // MARK: - Initialization
    
    init(repository: OrdersRepositoryProtocol = OrdersRepository(),
         authService: AuthService = .shared) {
        self.repository = repository
        self.authService = authService
    }
    
    // MARK: - Actions
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await repository.fetchProducts()
        } catch {
            errorMessage = "Error cargando productos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadOrders() async {
        guard let userId = authService.currentUser?.uid else {
            errorMessage = "Debes iniciar sesión para ver tus pedidos"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            orders = try await repository.fetchOrders(userId: userId)
        } catch {
            errorMessage = "Error cargando pedidos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addToCart(_ product: Product) {
        if var existing = cart[product.id] {
            existing.quantity += 1
            cart[product.id] = existing
        } else {
            cart[product.id] = CartItem(productId: product.id, product: product, quantity: 1)
        }
    }
    
    func removeFromCart(_ product: Product) {
        guard var existing = cart[product.id] else { return }
        
        if existing.quantity > 1 {
            existing.quantity -= 1
            cart[product.id] = existing
        } else {
            cart.removeValue(forKey: product.id)
        }
    }
    
    func clearCart() {
        cart.removeAll()
    }
    
    func checkout() async {
        guard let userId = authService.currentUser?.uid else {
            errorMessage = LocalizationUtils.string("You must be logged in to place an order")
            return
        }
        
        guard !cart.isEmpty else {
            errorMessage = LocalizationUtils.string("Cart is empty")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let order = try await repository.createOrder(userId: userId, items: cartItems)
            orders.insert(order, at: 0)
            clearCart()
            showSuccessDialog = true
        } catch {
            errorMessage = String(format: LocalizationUtils.string("Order processing error"), error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func dismissSuccessDialog() {
        showSuccessDialog = false
    }
    
    func setFilter(_ category: String?) {
        selectedCategory = category
    }
    
    func quantity(for product: Product) -> Int {
        cart[product.id]?.quantity ?? 0
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/PublicTransportViewModel.swift`

```swift
import Foundation
import CoreLocation
import Combine

@MainActor
class PublicTransportViewModel: ObservableObject {
    @Published var itineraries: [Itinerary] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var showFallback = false
    
    private let apiClient = TransportAPIClient.shared
    
    @Published var selectedModeFilter: String = "ALL" // ALL, BUS, RAIL
    
    // Circuit Coordinates (Default fallback)
    private let defaultCircuitLocation = CLLocationCoordinate2D(latitude: 41.570, longitude: 2.260)
    
    private var allItineraries: [Itinerary] = []
    
    func loadRoutes(from userLocation: CLLocationCoordinate2D?, to destination: CLLocationCoordinate2D? = nil) {
        guard let from = userLocation else {
            self.error = "Ubicación desconocida"
            return
        }
        
        let toLocation = destination ?? defaultCircuitLocation
        
        Task { @MainActor in
            isLoading = true
            error = nil
            showFallback = false
        }
        
        Task {
            do {
                // First check health (optional, but good for UX to fail fast)
                let isHealthy = await apiClient.checkHealth()
                if !isHealthy {
                    Logger.warning("[PublicTransportVM] Backend not reachable, using mock.")
                    await MainActor.run {
                        self.allItineraries = self.mockItineraries(userLocation: from, destination: toLocation)
                        self.filterItineraries()
                        self.isLoading = false
                    }
                    return
                }
                
                let response = try await apiClient.planTrip(from: from, to: toLocation)
                await MainActor.run {
                    self.allItineraries = response.itineraries
                    self.filterItineraries()
                    self.isLoading = false
                    if self.itineraries.isEmpty {
                        self.error = LocalizationUtils.string("No routes found.")
                        self.showFallback = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = String(format: LocalizationUtils.string("Connection error"), error.localizedDescription)
                    self.isLoading = false
                    self.showFallback = true
                    
                    // Fallback to Intelligent Local Route
                    self.allItineraries = self.mockItineraries(userLocation: from, destination: toLocation)
                    self.filterItineraries()
                }
            }
        }
    }
    
    func setFilter(_ mode: String) {
        selectedModeFilter = mode
        filterItineraries()
    }
    
    private func filterItineraries() {
        if selectedModeFilter == "ALL" {
            itineraries = allItineraries
        } else {
            itineraries = allItineraries.filter { itinerary in
                itinerary.legs.contains { $0.mode == selectedModeFilter }
            }
        }
    }
    
    // Mock/Fallback Data using Intelligent Routing
    private func mockItineraries(userLocation: CLLocationCoordinate2D? = nil, destination: CLLocationCoordinate2D? = nil) -> [Itinerary] {
        guard let userLoc = userLocation, let dest = destination else {
            // Default static if no coords (shouldn't happen in flow)
            return []
        }
        
        // 1. Calculate Intelligent Route via R2N (Standard F1 Route)
        let route = TransportLocalFallback.shared.generateFallbackItinerary(from: userLoc, to: dest)
        
        // 2. Add an alternative (e.g. Bus or just Walk if close? For now just one good one)
        // Check if user is very close (Walk only)
        let distance = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
            .distance(from: CLLocation(latitude: dest.latitude, longitude: dest.longitude))
            
        if distance < 3000 {
            // If < 3km, suggest walking direct
            let walkTime = Int(distance / 1.2)
            let now = Int(Date().timeIntervalSince1970 * 1000)
            let walkLeg = Leg(mode: "WALK", route: nil, routeColor: nil, routeShortName: nil, routeLongName: nil,
                              from: Place(name: "Tu Ubicación", lat: userLoc.latitude, lon: userLoc.longitude, departureTime: nil, arrivalTime: nil),
                              to: Place(name: "Circuit", lat: dest.latitude, lon: dest.longitude, departureTime: nil, arrivalTime: nil),
                              realTime: false, distance: distance, legGeometry: nil)
                              
            let walkItinerary = Itinerary(duration: walkTime, startTime: now, endTime: now + walkTime*1000, walkTime: walkTime, transitTime: 0, legs: [walkLeg])
            return [walkItinerary]
        }
        
        return [route]
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/ViewModels/SocialViewModel.swift`

```swift
import Foundation
import SwiftUI
import Combine
import CoreImage.CIFilterBuiltins

class SocialViewModel: ObservableObject {
    
    @Published var inviteLink: String = ""
    @Published var qrCodeImage: UIImage?
    @Published var alertMessage: String?
    @Published var isShowingQR = false
    @Published var isJoined = false
    
    private let groupRepo = GroupRepository.shared
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    func createGroup() {
        Task {
            do {
                _ = try await groupRepo.createGroup()
                await MainActor.run {
                    self.inviteLink = groupRepo.generateInviteLink()
                    self.generateQRCode(from: self.inviteLink)
                    self.isShowingQR = true
                    self.isJoined = true
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to create group"
                }
            }
        }
    }
    
    func joinGroup(url: String) {
        // url format georacing://join?groupId=XYZ
        guard let components = URLComponents(string: url),
              let queryItems = components.queryItems,
              let groupId = queryItems.first(where: { $0.name == "groupId" })?.value else {
            self.alertMessage = "Invalid QR Code"
            return
        }
        
        Task {
            do {
                try await groupRepo.joinGroup(groupId: groupId)
                await MainActor.run {
                    self.alertMessage = "Joined Group successfully!"
                    self.isJoined = true
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to join group"
                }
            }
        }
    }
    
    func leaveGroup() {
        groupRepo.leaveGroup()
        self.isJoined = false
        self.inviteLink = ""
        self.qrCodeImage = nil
    }
    
    private func generateQRCode(from string: String) {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            // Scale up
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                self.qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/CardCollectionView.swift`

```swift
import SwiftUI

// MARK: - Card Collection View

/// "My Collection" screen with filters by rarity, team, and unlock status.
struct CardCollectionView: View {
    @ObservedObject var viewModel: FanZoneViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: CollectionFilter = .all
    @State private var selectedCard: RewardCardDefinition?
    @State private var showCardDetail = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]
    
    enum CollectionFilter: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Collection Summary
                    collectionHeader
                    
                    // Filters
                    filterBar
                    
                    // Cards Grid
                    if filteredCards.isEmpty {
                        emptyState
                    } else {
                        cardsGrid
                    }
                }
            }
            .navigationTitle(LocalizationUtils.string("My Collection"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RacingColors.silver)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCardDetail) {
                if let card = selectedCard {
                    CardDetailSheet(
                        card: card,
                        team: viewModel.selectedTeam,
                        isUnlocked: viewModel.rewardService.progress[card.id]?.isUnlocked ?? false,
                        progress: viewModel.rewardService.progressRatio(for: card.id)
                    )
                }
            }
        }
    }
    
    // MARK: - Collection Header
    
    private var collectionHeader: some View {
        HStack(spacing: 20) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: collectionProgress)
                    .stroke(viewModel.teamColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(viewModel.rewardService.collectionSummary)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizationUtils.string("Collection Progress"))
                    .font(RacingFont.subheader(15))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    rarityCount(.common)
                    rarityCount(.rare)
                    rarityCount(.epic)
                    rarityCount(.legendary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(RacingColors.cardBackground)
    }
    
    private func rarityCount(_ rarity: CardRarity) -> some View {
        let total = viewModel.rewardService.cards(rarity: rarity).count
        let unlocked = viewModel.rewardService.cards(rarity: rarity)
            .filter { viewModel.rewardService.progress[$0.id]?.isUnlocked ?? false }.count
        
        return HStack(spacing: 2) {
            Circle()
                .fill(rarity.color)
                .frame(width: 8, height: 8)
            Text("\(unlocked)/\(total)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(RacingColors.silver)
        }
    }
    
    private var collectionProgress: CGFloat {
        let total = viewModel.rewardService.cardDefinitions.count
        guard total > 0 else { return 0 }
        return CGFloat(viewModel.rewardService.unlockedCards.count) / CGFloat(total)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CollectionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filterLabel(filter))
                            .font(.system(size: 13, weight: selectedFilter == filter ? .bold : .medium))
                            .foregroundColor(selectedFilter == filter ? .white : RacingColors.silver)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter
                                          ? filterColor(filter)
                                          : Color.gray.opacity(0.15))
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    
    private func filterLabel(_ filter: CollectionFilter) -> String {
        switch filter {
        case .all: return LocalizationUtils.string("All")
        case .unlocked: return LocalizationUtils.string("Unlocked")
        case .locked: return LocalizationUtils.string("Locked")
        default: return LocalizationUtils.string(filter.rawValue)
        }
    }
    
    private func filterColor(_ filter: CollectionFilter) -> Color {
        switch filter {
        case .all: return viewModel.teamColor
        case .unlocked: return .green
        case .locked: return .gray
        case .common: return CardRarity.common.color
        case .rare: return CardRarity.rare.color
        case .epic: return CardRarity.epic.color
        case .legendary: return CardRarity.legendary.color
        }
    }
    
    // MARK: - Filtered Cards
    
    private var filteredCards: [RewardCardDefinition] {
        let cards = viewModel.rewardService.cardDefinitions
        switch selectedFilter {
        case .all:
            return cards
        case .unlocked:
            return cards.filter { viewModel.rewardService.progress[$0.id]?.isUnlocked ?? false }
        case .locked:
            return cards.filter { !(viewModel.rewardService.progress[$0.id]?.isUnlocked ?? false) }
        case .common:
            return cards.filter { $0.rarity == .common }
        case .rare:
            return cards.filter { $0.rarity == .rare }
        case .epic:
            return cards.filter { $0.rarity == .epic }
        case .legendary:
            return cards.filter { $0.rarity == .legendary }
        }
    }
    
    // MARK: - Cards Grid
    
    private var cardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredCards) { card in
                    let isUnlocked = viewModel.rewardService.progress[card.id]?.isUnlocked ?? false
                    let cardProgress = viewModel.rewardService.progressRatio(for: card.id)
                    
                    CardView(
                        card: card,
                        team: viewModel.selectedTeam,
                        isUnlocked: isUnlocked,
                        progress: cardProgress
                    )
                    .onTapGesture {
                        selectedCard = card
                        showCardDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundColor(RacingColors.silver.opacity(0.4))
            Text(LocalizationUtils.string("No cards in this filter"))
                .font(RacingFont.body())
                .foregroundColor(RacingColors.silver)
            Spacer()
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/CardView.swift`

```swift
import SwiftUI

// MARK: - Card View

/// Visual component for a collectible reward card.
/// Renders with team gradients, rarity frame, and numbered badge.
/// Supports export to PNG for sharing.
struct CardView: View {
    let card: RewardCardDefinition
    let team: RacingTeam?
    let isUnlocked: Bool
    let progress: Double // 0.0 - 1.0
    
    var body: some View {
        ZStack {
            // Card Base
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(card.rarity.frameGradient, lineWidth: rarityBorderWidth)
                )
            
            if isUnlocked {
                unlockedContent
            } else {
                lockedContent
            }
        }
        .frame(width: 180, height: 260)
        .shadow(color: isUnlocked ? card.rarity.color.opacity(0.4) : .black.opacity(0.3), radius: 8, y: 4)
    }
    
    // MARK: - Unlocked Card
    
    private var unlockedContent: some View {
        VStack(spacing: 8) {
            // Rarity Badge
            HStack {
                Text(card.rarity.displayName.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(card.rarity.color))
                
                Spacer()
                
                // Number
                Text(String(format: "%02d/%02d", card.number, card.totalInSet))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Spacer()
            
            // Team Logo or Badge Icon
            if let team {
                TeamLogoView(team: team, size: 56)
            } else if let icon = card.badgeIcon {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
            }
            
            // Title
            Text(card.title)
                .font(RacingFont.subheader(15))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
            
            // Description
            Text(card.description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
            
            // Season badge
            Text("2026")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 10)
        }
    }
    
    // MARK: - Locked Card
    
    private var lockedContent: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(card.rarity.color.opacity(0.6))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 24)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Condition hint
            Text(card.unlockCondition.description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 12)
            
            // Rarity indicator
            Text(card.rarity.displayName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(card.rarity.color.opacity(0.5))
            
            Spacer()
        }
    }
    
    // MARK: - Styling
    
    private var cardBackground: LinearGradient {
        if isUnlocked, let team {
            return LinearGradient(
                colors: [team.primarySwiftColor.opacity(0.6), team.primarySwiftColor.opacity(0.15), Color.black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(white: 0.15), Color(white: 0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var rarityBorderWidth: CGFloat {
        switch card.rarity {
        case .common: return 1.5
        case .rare: return 2
        case .epic: return 2.5
        case .legendary: return 3
        }
    }
}

// MARK: - Card Share Extension

extension CardView {
    /// Render the card to a UIImage for sharing
    @MainActor
    func renderToImage() -> UIImage {
        let renderer = ImageRenderer(content: self.frame(width: 360, height: 520))
        renderer.scale = UITraitCollection.current.displayScale
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Card Detail Sheet

struct CardDetailSheet: View {
    let card: RewardCardDefinition
    let team: RacingTeam?
    let isUnlocked: Bool
    let progress: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Large Card
                CardView(card: card, team: team, isUnlocked: isUnlocked, progress: progress)
                    .scaleEffect(1.5)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                
                Spacer()
                
                // Card Info
                VStack(spacing: 8) {
                    Text(card.title)
                        .font(RacingFont.header(24))
                        .foregroundColor(.white)
                    
                    Text(card.description)
                        .font(RacingFont.body(15))
                        .foregroundColor(RacingColors.silver)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Label(card.rarity.displayName, systemImage: "sparkles")
                            .foregroundColor(card.rarity.color)
                        
                        Label("\(card.number)/\(card.totalInSet)", systemImage: "number")
                            .foregroundColor(RacingColors.silver)
                    }
                    .font(RacingFont.body(14))
                    .padding(.top, 4)
                    
                    if !isUnlocked {
                        // Progress detail
                        VStack(spacing: 4) {
                            Text(card.unlockCondition.description)
                                .font(RacingFont.body(13))
                                .foregroundColor(RacingColors.silver.opacity(0.8))
                            
                            ProgressView(value: progress)
                                .tint(card.rarity.color)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Actions
                HStack(spacing: 16) {
                    if isUnlocked {
                        Button(action: {
                            let cardView = CardView(card: card, team: team, isUnlocked: true, progress: 1.0)
                            shareImage = cardView.renderToImage()
                            showShareSheet = true
                        }) {
                            Label(LocalizationUtils.string("Share"), systemImage: "square.and.arrow.up")
                                .font(RacingFont.subheader(15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(card.rarity.color)
                                )
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text(LocalizationUtils.string("Close"))
                            .font(RacingFont.body(15))
                            .foregroundColor(RacingColors.silver)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RacingColors.silver.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/CircuitControlView.swift`

```swift
import SwiftUI

struct CircuitControlView: View {
    @State private var selectedStatus: TrackStatus = .green
    @State private var customMessage: String = ""
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    // Environment object to observe current state
    @ObservedObject var repository = CircuitStatusRepository.shared
    
    var body: some View {
        Form {
            Section(header: Text("Current Status")) {
                HStack {
                    Label(repository.currentStatus.titleKey, systemImage: repository.currentStatus.iconName)
                        .foregroundColor(repository.currentStatus.color)
                    Spacer()
                    if repository.currentStatus == .evacuation {
                        Text("EVACUATION")
                            .font(.caption)
                            .padding(4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                Text("Message: \(repository.statusMessage)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Update Status")) {
                Picker("Flag Color", selection: $selectedStatus) {
                    ForEach(TrackStatus.allCases, id: \.self) { status in
                        Label(status.rawValue.uppercased(), systemImage: status.iconName)
                            .foregroundColor(status.color)
                            .tag(status)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading) {
                    Text("Custom Message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter message for drivers...", text: $customMessage, axis: .vertical)
                        .lineLimit(3...5)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            Section {
                Button(action: updateStatus) {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Text("Update Circuit State")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.blue)
                .disabled(isUpdating)
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Circuit Control")
        .onAppear {
            // Pre-fill with current values
            self.selectedStatus = repository.currentStatus
            self.customMessage = repository.statusMessage
        }
    }
    
    private func updateStatus() {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        
        Task {
            do {
                try await repository.updateStatus(mode: selectedStatus, message: customMessage)
                // Success feedback handled by repo updating observed properties
            } catch {
                errorMessage = "Failed to update: \(error.localizedDescription)"
            }
            isUpdating = false
        }
    }
}

#Preview {
    NavigationView {
        CircuitControlView()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/CircuitMapView.swift`

```swift
import SwiftUI
import Combine
import CoreLocation
import MapKit

struct CircuitMapView: View {
    
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var energyService = EnergyManagementService.shared
    
    // UI State
    @State private var selectedPOI: Poi? = nil
    @State private var showPoiDetail: Bool = false
    @State private var showTransportSheet: Bool = false
    @State private var showGPSNavigation: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            
            MapViewRepresentable(
                region: $viewModel.region,
                annotations: viewModel.allAnnotations,
                routePolyline: viewModel.routePolyline,
                shadowPolygons: viewModel.shadowPolygons,
                userTrackingMode: viewModel.userTrackingMode,
                selectedPOI: $selectedPOI,
                showPoiDetail: $showPoiDetail
            )
            .edgesIgnoringSafeArea(.all)
            
            // 2. Navigation Top Banner (Turn-by-Turn)
            if viewModel.showNavigationOverlay, let route = viewModel.activeRoute, viewModel.activeWebUrl == nil {
                TopNavigationBanner(
                    route: route,
                    currentStepIndex: viewModel.currentStepIndex,
                    onNext: { viewModel.nextStep() },
                    onPrev: { viewModel.prevStep() },
                    onClose: { viewModel.endNavigation() }
                )
                .transition(.move(edge: .top))
            }
            
            // 3. UI Overlay: Filter Bar (Hidden when navigating)
            if !viewModel.showNavigationOverlay {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.filterPOIs(by: nil)
                            }
                            ForEach(PoiType.allCases, id: \.self) { type in
                                FilterChip(title: type.rawValue.capitalized, isSelected: viewModel.selectedCategory == type) {
                                    viewModel.filterPOIs(by: type)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.0)]), startPoint: .top, endPoint: .bottom)
                    )
                    
                    Spacer()
                }
            }
            
            // 4. Bottom Controls (Navigation or Standard)
            VStack {
                Spacer()
                
                if viewModel.showNavigationOverlay {
                    // Navigation Bottom Info
                    if let route = viewModel.activeRoute {
                        NavigationBottomPanel(
                            route: route,
                            transportMode: viewModel.transportMode,
                            onModeChange: { viewModel.setTransportMode($0) },
                            onEndNavigation: { viewModel.endNavigation() }
                        )
                        .transition(.move(edge: .bottom))
                    }
                } else {
                    // Standard Bottom Buttons
                    HStack(spacing: 12) {
                        // Navigate to Circuit Button — opens full GPS navigation
                        Button(action: {
                            showGPSNavigation = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                Text(LocalizationUtils.string("Go to Circuit"))
                                    .font(RacingFont.body(14).bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(RacingColors.red)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                        
                        Spacer()
                        
                        // Recenter Button
                        Button(action: {
                            if let userLoc = viewModel.userLocation {
                                withAnimation {
                                    viewModel.region.center = userLoc
                                    viewModel.region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                }
                            } else if let circuit = viewModel.circuit {
                                withAnimation {
                                    viewModel.region.center = circuit.bounds.center
                                    viewModel.region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                }
                            }
                        }) {
                            Image(systemName: "location.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(RacingColors.red)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
            }
            
            // Error Toast
            if let error = viewModel.navigationError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(RacingFont.body(14))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        viewModel.navigationError = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showPoiDetail) {
            if let poi = selectedPOI {
                PoiDetailSheet(poi: poi, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showTransportSheet) {
            PublicTransportSheetView(mapViewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showGPSNavigation) {
            NavigationScreen()
        }
        .animation(.spring(response: 0.3), value: viewModel.showNavigationOverlay)
        .preferredColorScheme(energyService.isSurvivalMode ? .dark : nil)
    }
}

// MARK: - Banner & Overlay

struct TopNavigationBanner: View {
    let route: NavigationRoute
    let currentStepIndex: Int
    let onNext: () -> Void
    let onPrev: () -> Void
    let onClose: () -> Void
    
    var currentStep: MKRoute.Step? {
        if currentStepIndex < route.steps.count {
            return route.steps[currentStepIndex]
        }
        return nil
    }
    
    var nextStep: MKRoute.Step? {
        if currentStepIndex + 1 < route.steps.count {
            return route.steps[currentStepIndex + 1]
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Instruction Bar
            HStack(alignment: .top, spacing: 16) {
                // Direction Icon (Big)
                Image(systemName: "arrow.turn.up.right") // Placeholder, ideally dynamic
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentStep?.instructions ?? LocalizationUtils.string("Follow the route"))
                        .font(RacingFont.header(20))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let dist = currentStep?.distance {
                        Text("\(Int(dist)) m")
                            .font(RacingFont.header(24))
                            .foregroundColor(RacingColors.silver)
                    }
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 12) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(RacingColors.silver)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    HStack(spacing: 2) {
                        Button(action: onPrev) {
                            Image(systemName: "chevron.left")
                                .padding(8)
                        }
                        .disabled(currentStepIndex == 0)
                        
                        Divider().frame(height: 20).background(Color.white.opacity(0.2))
                        
                        Button(action: onNext) {
                            Image(systemName: "chevron.right")
                                .padding(8)
                        }
                        .disabled(currentStepIndex >= route.steps.count - 1)
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .foregroundColor(.white)
            }
            .padding()
            .background(RacingColors.cardBackground)
            .padding(.top, 44) // Safe area
            
            // Next Step Preview
            if let next = nextStep {
                HStack {
                    Text("Después: \(next.instructions)")
                        .font(RacingFont.body(14))
                        .foregroundColor(RacingColors.silver)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(RacingColors.darkBackground.opacity(0.9))
            }
        }
        .cornerRadius(0)
        .shadow(radius: 10)
    }
}

struct NavigationBottomPanel: View {
    let route: NavigationRoute
    let transportMode: TransportMode
    let onModeChange: (TransportMode) -> Void
    let onEndNavigation: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(route.destinationName)
                        .font(RacingFont.header(16))
                        .foregroundColor(.white)
                    HStack {
                        Label(route.formattedETA, systemImage: "clock.fill")
                            .foregroundColor(RacingColors.red)
                        Text("•")
                        Text(route.formattedDistance)
                    }
                    .font(RacingFont.body(14))
                    .foregroundColor(RacingColors.silver)
                }
                Spacer()
                
                Button(action: onEndNavigation) {
                    Text(LocalizationUtils.string("Exit"))
                        .font(RacingFont.body(14).bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(20)
                }
            }
            .padding(.bottom, 4)
            
            // Mode Selector
            HStack(spacing: 8) {
                ForEach(TransportMode.allCases, id: \.self) { mode in
                    Button(action: { onModeChange(mode) }) {
                        Image(systemName: mode.icon)
                            .font(.body)
                            .foregroundColor(transportMode == mode ? .white : RacingColors.silver)
                            .padding(10)
                            .background(transportMode == mode ? RacingColors.red : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RacingColors.cardBackground)
                .shadow(radius: 5)
        )
        .padding()
    }
}

// MARK: - Map View Representable (UIKit wrapper)

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MapAnnotationItem]
    let routePolyline: MKPolyline?
    let shadowPolygons: [MKPolygon]
    let userTrackingMode: MapUserTrackingMode
    @Binding var selectedPOI: Poi?
    @Binding var showPoiDetail: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update User Tracking
        switch userTrackingMode {
        case .none:
            mapView.userTrackingMode = .none
        case .follow:
            if mapView.userTrackingMode != .follow {
                mapView.setUserTrackingMode(.follow, animated: true)
            }
        case .followWithHeading:
            if mapView.userTrackingMode != .followWithHeading {
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
            }
        }
        
        // Update region if NOT tracking (otherwise tracking handles it)
        if userTrackingMode == .none && !context.coordinator.isUserInteracting {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        let existingAnnotations = mapView.annotations.compactMap { $0 as? MapPinAnnotation }
        let newIds = Set(annotations.map { $0.id })
        let existingIds = Set(existingAnnotations.map { $0.id })
        
        // Remove old
        let toRemove = existingAnnotations.filter { !newIds.contains($0.id) }
        mapView.removeAnnotations(toRemove)
        
        // Add new
        let toAdd = annotations.filter { !existingIds.contains($0.id) }
        for item in toAdd {
            let annotation = MapPinAnnotation(item: item)
            mapView.addAnnotation(annotation)
        }
        
        // Update route overlay
        if let existingOverlay = mapView.overlays.first(where: { $0 is MKPolyline }) as? MKPolyline {
            if routePolyline == nil || existingOverlay !== routePolyline {
                mapView.removeOverlay(existingOverlay)
            }
        }
        
        if let polyline = routePolyline, !mapView.overlays.contains(where: { $0 === polyline }) {
            mapView.addOverlay(polyline, level: .aboveRoads)
        }
        
        // Update Thermal Overlays
        let existingPolygons = mapView.overlays.compactMap { $0 as? MKPolygon }
        let newPolygons = shadowPolygons.filter { newPoly in
            !existingPolygons.contains(where: { $0.title == newPoly.title })
        }
        if !newPolygons.isEmpty {
            mapView.addOverlays(newPolygons, level: .aboveLabels)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var isUserInteracting = false
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isUserInteracting = true
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isUserInteracting = false
            // Don't update parent region if tracking, creates loop
            if parent.userTrackingMode == .none {
                parent.region = mapView.region
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pinAnnotation = annotation as? MapPinAnnotation else { return nil }
            
            let identifier = "MapPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            }
            
            switch pinAnnotation.item.type {
            case .poi(let poi):
                let hostingView = UIHostingController(rootView: POIMarker(poi: poi))
                hostingView.view.backgroundColor = .clear
                hostingView.view.frame = CGRect(x: 0, y: 0, width: 50, height: 60)
                annotationView?.addSubview(hostingView.view)
                annotationView?.frame = hostingView.view.frame
                
            case .friend(let friend):
                let hostingView = UIHostingController(rootView: FriendMarker(friend: friend))
                hostingView.view.backgroundColor = .clear
                hostingView.view.frame = CGRect(x: 0, y: 0, width: 50, height: 60)
                annotationView?.addSubview(hostingView.view)
                annotationView?.frame = hostingView.view.frame
                
            case .beacon(let beacon):
                let hostingView = UIHostingController(rootView: BeaconMarker(beacon: beacon))
                hostingView.view.backgroundColor = .clear
                hostingView.view.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
                annotationView?.addSubview(hostingView.view)
                annotationView?.frame = hostingView.view.frame
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            guard let pinAnnotation = annotation as? MapPinAnnotation else { return }
            
            if case .poi(let poi) = pinAnnotation.item.type {
                parent.selectedPOI = poi
                parent.showPoiDetail = true
            }
            
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(RacingColors.red)
                renderer.lineWidth = 5
                renderer.lineCap = .round
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                // Thermal Navigation: renders shadows as semi-transparent blue.
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Map Annotation Wrapper

class MapPinAnnotation: NSObject, MKAnnotation {
    let id: String
    let item: MapAnnotationItem
    
    var coordinate: CLLocationCoordinate2D {
        item.coordinate
    }
    
    init(item: MapAnnotationItem) {
        self.id = item.id
        self.item = item
    }
}

// MARK: - Subviews (Keep Existing)
// (FilterChip, POIDetailSheet, Markers - assuming they are reused/available or need to be redefined if overwrite is full)

// Since overwrite is full, I need to include FilterChip etc.
// I will include them concisely.

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RacingFont.body(12))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? RacingColors.red : RacingColors.cardBackground)
                .foregroundColor(.white)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RacingColors.silver.opacity(0.3), lineWidth: isSelected ? 0 : 1))
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PoiDetailSheet: View {
    let poi: Poi
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(poi.name)
                            .font(RacingFont.header(24))
                            .foregroundColor(.white)
                        Text(poi.type.rawValue.capitalized)
                            .font(RacingFont.body())
                            .foregroundColor(RacingColors.silver)
                    }
                    Spacer()
                    Image(systemName: POIIconHelper.iconName(for: poi.type))
                        .font(.largeTitle)
                        .foregroundColor(RacingColors.red)
                }
                
                if let description = poi.description {
                    Text(description)
                        .font(RacingFont.body())
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Navigate to POI Button
                Button(action: {
                    dismiss()
                    viewModel.calculateRouteToPOI(poi)
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        Text("Cómo llegar")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RacingColors.red)
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }
}

// Helper for Icons
struct POIIconHelper {
    static func iconName(for category: PoiType) -> String {
        switch category {
            case .wc: return "toilet.fill"
            case .food: return "fork.knife"
            case .medical: return "cross.case.fill"
            case .parking: return "p.circle.fill"
            case .grandstand: return "person.3.fill"
            case .merch: return "bag.fill"
            case .access: return "arrow.right.circle.fill"
            case .exit: return "arrow.left.circle.fill"
            case .gate: return "rectangle.compress.vertical"
            case .fanzone: return "sportscourt"
            case .service: return "wrench.adjustable"
            case .other: return "mappin"
        }
    }
}

struct POIMarker: View {
    let poi: Poi
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: POIIconHelper.iconName(for: poi.type))
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(.white)
                .padding(8)
                .background(RacingColors.red)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            Text(poi.name)
                .font(.caption2)
                .padding(2)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(4)
                .offset(y: 2)
        }
    }
}

struct FriendMarker: View {
    let friend: GroupMember
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            Text(friend.displayName)
                .font(.caption2)
                .padding(2)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(4)
        }
    }
}

struct BeaconMarker: View {
    let beacon: BeaconConfig
    
    var body: some View {
        Circle()
            .fill(Color.purple.opacity(0.3))
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .stroke(Color.purple, lineWidth: 2)
            )
            .overlay(
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundColor(.purple)
            )
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/EmergencySetupView.swift`

```swift
import SwiftUI
import Photos

struct EmergencySetupView: View {
    @State private var bloodType: String = ""
    @State private var emergencyContact: String = ""
    @State private var gateInfo: String = "Tribuna N, Puerta 3" // Example context
    @State private var healthConditions: String = ""
    
    @State private var isSaved: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        Text("Configura tu Fondo de Bloqueo")
                            .font(RacingFont.header(24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top)
                        
                        Text("En caso de desmayo o emergencia y sin conexión a internet, el personal médico podrá ver esta información en tu pantalla.")
                            .font(RacingFont.body(14))
                            .foregroundColor(RacingColors.silver)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Form Input
                        VStack(spacing: 16) {
                            inputField(title: "Grupo Sanguíneo", text: $bloodType, placeholder: "Ej. O+, A-")
                            inputField(title: "Contacto Emergencia", text: $emergencyContact, placeholder: "Nombre y Teléfono")
                            inputField(title: "Condiciones Médicas", text: $healthConditions, placeholder: "Ej. Diabético, Alergia Penicilina")
                            inputField(title: "Alojamiento / Puerta", text: $gateInfo, placeholder: "Dónde estás ubicado")
                        }
                        .padding()
                        .background(RacingColors.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Previsualización de Emergencia:")
                                .font(RacingFont.subheader(16))
                                .foregroundColor(RacingColors.red)
                                .padding(.horizontal)
                            
                            lockScreenPreview
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(RacingColors.silver.opacity(0.3), lineWidth: 2)
                                )
                                .padding(.horizontal, 40)
                        }
                        
                        // Action Button
                        Button(action: saveWallpaper) {
                            HStack {
                                Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                Text(isSaved ? "Guardado en Fotos" : "Guardar Fondo")
                            }
                            .font(RacingFont.header(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSaved ? Color.green : RacingColors.red)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                        }
                        .disabled(isSaved)
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        Text("Una vez guardada, ve a Ajustes > Fondo de Pantalla y configúrala como Pantalla de Bloqueo.")
                            .font(.caption)
                            .foregroundColor(RacingColors.silver.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Medical Lock Screen")
                        .font(RacingFont.subheader(18))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func inputField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(RacingFont.body(12).bold())
                .foregroundColor(RacingColors.silver)
            
            TextField(placeholder, text: text)
                .font(RacingFont.body(16))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RacingColors.silver.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    /// The exact view that will be rendered to the image
    private var lockScreenPreview: some View {
        ZStack {
            // Simulated Lock Screen background (Black/Dark)
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer() // Push to the bottom half as the clock takes the top
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("INFO MÉDICA DE EMERGENCIA")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        previewRow(title: "Sangre:", value: bloodType.isEmpty ? "N/A" : bloodType)
                        previewRow(title: "Alerta:", value: healthConditions.isEmpty ? "Ninguna declarada" : healthConditions)
                        previewRow(title: "Llamar:", value: emergencyContact.isEmpty ? "No especificado" : emergencyContact)
                        previewRow(title: "Ticket:", value: gateInfo)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(20)
                .background(Color.red.opacity(0.2)) // Red hue for emergency feel
                .cornerRadius(16)
                .padding([.horizontal, .bottom], 20)
            }
        }
        // Assuming a standard screen aspect ratio for preview
        .aspectRatio(9/19.5, contentMode: .fit) 
    }
    
    private func previewRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func saveWallpaper() {
        errorMessage = nil
        
        // 1. Check Permissions
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized {
                    Task { @MainActor in self.renderAndSave() }
                } else {
                    Task { @MainActor in self.errorMessage = "Se requiere permiso para guardar fotos." }
                }
            }
        } else if status == .authorized || status == .limited {
            renderAndSave()
        } else {
            errorMessage = "Permiso de fotos denegado. Ve a Ajustes."
        }
    }
    
    private func renderAndSave() {
        do {
            // Render the lockScreenPreview View
            let size = UIScreen.main.bounds.size
            let image = try EmergencyImageGenerator.render(view: lockScreenPreview, size: size)
            
            // Save to photos
            EmergencyImageGenerator.saveToPhotos(image)
            
            withAnimation {
                isSaved = true
            }
            
            // Log telemetry event!
            TelemetryLogger.shared.logEvent("saved_emergency_lockscreen")
            
        } catch {
            errorMessage = "Hubo un error al generar la imagen."
            Logger.error("[EmergencySetup] Render Error: \(error)")
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/EvacuationView.swift`

```swift
import SwiftUI

struct EvacuationView: View {
    @State private var isFlashing = false
    
    var body: some View {
        ZStack {
            RacingColors.red
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text(LocalizationUtils.string("EMERGENCY"))
                    .font(RacingFont.header(40))
                    .foregroundColor(.white)
                
                Text(LocalizationUtils.string("EVACUATION ORDER"))
                    .font(RacingFont.header(32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isFlashing ? 1.0 : 0.3)
                    .onAppear {
                        withAnimation(.linear(duration: 0.5).repeatForever()) {
                            isFlashing = true
                        }
                    }
                
                Text("Please follow staff instructions and proceed to the nearest exit immediately.")
                    .font(RacingFont.body())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
    }
}

#Preview {
    EvacuationView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/FanNewsView.swift`

```swift
import SwiftUI

// MARK: - Fan News View

/// Aggregated news screen with F1/MotoGP tabs, pull-to-refresh, and offline cache.
struct FanNewsView: View {
    @ObservedObject var viewModel: FanZoneViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Championship = .f1
    @State private var selectedArticle: FeedArticle?
    @State private var showWebView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Championship Tabs
                    championshipTabs
                    
                    // Last updated indicator
                    lastUpdatedBar
                    
                    // Articles List
                    if viewModel.newsService.isLoading && filteredArticles.isEmpty {
                        loadingView
                    } else if filteredArticles.isEmpty {
                        emptyView
                    } else {
                        articlesList
                    }
                }
            }
            .navigationTitle(LocalizationUtils.string("News"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RacingColors.silver)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task { await viewModel.newsService.forceRefresh() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(viewModel.teamColor)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showWebView) {
                if let article = selectedArticle, let url = URL(string: article.url) {
                    SafariWebView(url: url)
                }
            }
        }
        .task {
            selectedTab = viewModel.selectedChampionship
            await viewModel.newsService.refreshNews()
        }
    }
    
    // MARK: - Tabs
    
    private var championshipTabs: some View {
        HStack(spacing: 0) {
            ForEach(Championship.allCases) { champ in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = champ }
                }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: champ.icon)
                            Text(champ.rawValue)
                                .font(RacingFont.subheader(15))
                        }
                        
                        // Count badge
                        Text("\(viewModel.newsService.articles(for: champ).count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(selectedTab == champ ? viewModel.teamColor : Color.gray.opacity(0.3)))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == champ
                        ? viewModel.teamColor.opacity(0.15)
                        : Color.clear
                    )
                    .foregroundColor(selectedTab == champ ? viewModel.teamColor : RacingColors.silver)
                }
            }
        }
        .background(RacingColors.cardBackground)
    }
    
    // MARK: - Last Updated
    
    private var lastUpdatedBar: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption2)
            Text("\(LocalizationUtils.string("Updated")) \(viewModel.newsService.lastRefreshedText)")
                .font(.caption)
            
            Spacer()
            
            if viewModel.newsService.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(viewModel.teamColor)
            }
        }
        .foregroundColor(RacingColors.silver.opacity(0.7))
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    // MARK: - Articles List
    
    private var filteredArticles: [FeedArticle] {
        viewModel.newsService.articles(for: selectedTab)
    }
    
    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredArticles) { article in
                    NewsArticleRow(
                        article: article,
                        teamColor: viewModel.teamColor,
                        onTap: {
                            viewModel.newsService.markAsRead(article.id)
                            selectedArticle = article
                            showWebView = true
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.newsService.forceRefresh()
        }
    }
    
    // MARK: - Empty / Loading
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(viewModel.teamColor)
            Text(LocalizationUtils.string("Loading news..."))
                .foregroundColor(RacingColors.silver)
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundColor(RacingColors.silver.opacity(0.5))
            Text(LocalizationUtils.string("No news available"))
                .font(RacingFont.subheader())
                .foregroundColor(RacingColors.silver)
            Button(action: {
                Task { await viewModel.newsService.forceRefresh() }
            }) {
                Label(LocalizationUtils.string("Refresh"), systemImage: "arrow.clockwise")
                    .racingButton(color: viewModel.teamColor)
            }
            Spacer()
        }
    }
}

// MARK: - News Article Row

struct NewsArticleRow: View {
    let article: FeedArticle
    let teamColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            imagePlaceholder
                        default:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    imagePlaceholder
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(RacingFont.body(15).bold())
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if !article.summary.isEmpty {
                        Text(article.summary)
                            .font(RacingFont.body(13))
                            .foregroundColor(RacingColors.silver)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        Text(article.source)
                            .font(.caption.bold())
                            .foregroundColor(teamColor)
                        
                        Text(article.publishedAt.relativeFormatted)
                            .font(.caption)
                            .foregroundColor(RacingColors.silver.opacity(0.7))
                    }
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(RacingColors.silver.opacity(0.5))
                    .padding(.top, 8)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(RacingColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(teamColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(teamColor.opacity(0.1))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "newspaper.fill")
                    .foregroundColor(teamColor.opacity(0.3))
            )
    }
}

// MARK: - Safari Web View

import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let vc = SFSafariViewController(url: url, configuration: config)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Date Extension

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/FanZoneView.swift`

```swift
import SwiftUI

// MARK: - Fan Zone View (Main Hub)

struct FanZoneView: View {
    @StateObject private var viewModel = FanZoneViewModel()
    @StateObject private var energyService = EnergyManagementService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Sheet state
    @State private var showTeamSelector = false
    @State private var showQuiz = false
    @State private var showNews = false
    @State private var showCollection = false
    
    // Quick trivia state
    @State private var quickTrivia: QuizQuestion?
    @State private var quickAnswer: Int?
    @State private var showQuickResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Team-themed background
                LinearGradient(
                    colors: [viewModel.teamColor.opacity(0.25), RacingColors.darkBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Team Header
                        teamHeader
                        
                        if energyService.isSurvivalMode {
                            survivalBanner
                        }
                        
                        // Quick Actions
                        quickActions
                        
                        // News Preview
                        newsPreview
                        
                        // Quick Trivia Widget
                        triviaWidget
                        
                        // Collection Preview
                        collectionPreview
                        
                        // Unlock notification
                        if let unlocked = viewModel.rewardService.recentlyUnlocked {
                            unlockBanner(for: unlocked)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RacingColors.silver)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Fan Zone")
                        .font(RacingFont.subheader(18))
                        .foregroundColor(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await viewModel.loadAll() }
        .sheet(isPresented: $showTeamSelector) {
            TeamSelectorView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showNews) {
            FanNewsView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showCollection) {
            CardCollectionView(viewModel: viewModel)
        }
    }
    
    // MARK: - Survival Banner
    private var survivalBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "battery.25")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationUtils.string("Survival Mode Active"))
                    .font(RacingFont.subheader(14))
                    .foregroundColor(.white)
                Text(LocalizationUtils.string("Playful features disabled to ensure your return home."))
                    .font(RacingFont.body(12))
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.8))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Team Header
    
    private var teamHeader: some View {
        HStack(spacing: 16) {
            // Team Logo
            if let team = viewModel.selectedTeam {
                TeamLogoView(team: team, size: 56)
                    .onTapGesture { showTeamSelector = true }
            }
            
            // Team Info
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selectedTeam?.name ?? "Select Team")
                    .font(RacingFont.header(22))
                    .foregroundColor(.white)
                
                Button(action: { showTeamSelector = true }) {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedChampionship.displayName)
                            .font(RacingFont.body(14))
                            .foregroundColor(viewModel.teamColor)
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(viewModel.teamColor)
                    }
                }
            }
            
            Spacer()
            
            // Team color badge
            if let team = viewModel.selectedTeam {
                Text(team.shortName)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.teamColor)
                    )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            actionButton(
                icon: "brain.fill",
                title: LocalizationUtils.string("Trivia"),
                subtitle: "\(viewModel.questionService.totalAnswered) \(LocalizationUtils.string("played"))",
                color: .purple
            ) { showQuiz = true }
            
            actionButton(
                icon: "newspaper.fill",
                title: LocalizationUtils.string("News"),
                subtitle: "\(viewModel.newsCount) \(LocalizationUtils.string("articles"))",
                color: .blue
            ) { showNews = true }
            
            actionButton(
                icon: "rectangle.stack.fill",
                title: LocalizationUtils.string("Cards"),
                subtitle: viewModel.rewardService.collectionSummary,
                color: .orange
            ) { showCollection = true }
        }
        .padding(.horizontal)
        .disabled(energyService.isSurvivalMode)
        .opacity(energyService.isSurvivalMode ? 0.5 : 1.0)
    }
    
    private func actionButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(RacingFont.body(13).bold())
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(RacingColors.silver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(RacingColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - News Preview
    
    private var newsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(LocalizationUtils.string("Latest News"), systemImage: "newspaper")
                    .font(RacingFont.subheader(16))
                    .foregroundColor(viewModel.teamColor)
                Spacer()
                Button(action: { showNews = true }) {
                    HStack(spacing: 4) {
                        Text(LocalizationUtils.string("See all"))
                            .font(.caption.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(viewModel.teamColor)
                }
            }
            
            let latestNews = Array(viewModel.newsService.articles(for: viewModel.selectedChampionship).prefix(3))
            
            if latestNews.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "newspaper")
                            .foregroundColor(RacingColors.silver.opacity(0.4))
                        Text(LocalizationUtils.string("Loading news..."))
                            .font(.caption)
                            .foregroundColor(RacingColors.silver)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(RacingColors.cardBackground))
            } else {
                ForEach(latestNews) { article in
                    newsRow(article)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func newsRow(_ article: FeedArticle) -> some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.teamColor.opacity(0.1))
                            .overlay(Image(systemName: "photo").foregroundColor(viewModel.teamColor.opacity(0.3)))
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.teamColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "newspaper.fill").foregroundColor(viewModel.teamColor.opacity(0.3)))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(article.title)
                    .font(RacingFont.body(13).bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(article.source)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(viewModel.teamColor)
                    Text(article.publishedAt.relativeFormatted)
                        .font(.system(size: 10))
                        .foregroundColor(RacingColors.silver.opacity(0.6))
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(RacingColors.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.teamColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Trivia Widget
    
    private var triviaWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(LocalizationUtils.string("Quick Trivia"), systemImage: "brain")
                    .font(RacingFont.subheader(16))
                    .foregroundColor(.purple)
                Spacer()
                if showQuickResult {
                    Button(action: { loadNewTrivia() }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            
            if let trivia = quickTrivia {
                Text(trivia.prompt)
                    .font(RacingFont.body(14))
                    .foregroundColor(.white)
                
                // 2x2 Grid
                VStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<2, id: \.self) { col in
                                let index = row * 2 + col
                                if index < trivia.options.count {
                                    Button(action: {
                                        guard !showQuickResult else { return }
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            quickAnswer = index
                                            showQuickResult = true
                                            
                                            let correct = index == trivia.correctAnswer
                                            viewModel.questionService.recordAnswer(questionId: trivia.id, wasCorrect: correct)
                                            viewModel.questionService.updateStreak(correct: correct)
                                            
                                            if correct {
                                                Task { await viewModel.rewardService.recordEvent(.quizCorrect) }
                                            }
                                        }
                                    }) {
                                        Text(trivia.options[index])
                                            .font(RacingFont.body(12))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                quickAnswerBg(index: index, correctIndex: trivia.correctAnswer)
                                            )
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(quickAnswerBorder(index: index, correctIndex: trivia.correctAnswer), lineWidth: 1.5)
                                            )
                                    }
                                    .disabled(showQuickResult)
                                }
                            }
                        }
                    }
                }
                
                // Feedback
                if showQuickResult {
                    HStack(spacing: 6) {
                        Image(systemName: quickAnswer == trivia.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(quickAnswer == trivia.correctAnswer
                             ? LocalizationUtils.string("Correct!")
                             : "\(LocalizationUtils.string("Incorrect")): \(trivia.options[trivia.correctAnswer])")
                            .font(RacingFont.body(13))
                    }
                    .foregroundColor(quickAnswer == trivia.correctAnswer ? .green : .orange)
                    
                    if !trivia.explanation.isEmpty {
                        Text(trivia.explanation)
                            .font(.caption)
                            .foregroundColor(RacingColors.silver.opacity(0.8))
                    }
                }
            } else {
                ProgressView()
                    .tint(.purple)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(RacingColors.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .onAppear { loadNewTrivia() }
    }
    
    private func loadNewTrivia() {
        quickTrivia = viewModel.quickTrivia()
        quickAnswer = nil
        showQuickResult = false
    }
    
    private func quickAnswerBg(index: Int, correctIndex: Int) -> Color {
        guard showQuickResult else { return Color.purple.opacity(0.15) }
        if index == correctIndex { return Color.green.opacity(0.25) }
        if index == quickAnswer { return Color.red.opacity(0.25) }
        return Color.purple.opacity(0.08)
    }
    
    private func quickAnswerBorder(index: Int, correctIndex: Int) -> Color {
        guard showQuickResult else { return Color.purple.opacity(0.4) }
        if index == correctIndex { return .green }
        if index == quickAnswer { return .red }
        return Color.purple.opacity(0.2)
    }
    
    // MARK: - Collection Preview
    
    private var collectionPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(LocalizationUtils.string("My Collection"), systemImage: "rectangle.stack")
                    .font(RacingFont.subheader(16))
                    .foregroundColor(.orange)
                Spacer()
                Button(action: { showCollection = true }) {
                    HStack(spacing: 4) {
                        Text(viewModel.rewardService.collectionSummary)
                            .font(.caption.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Show first 5 cards (mix of unlocked + locked)
                    let previewCards = Array(viewModel.rewardService.cardDefinitions.prefix(5))
                    ForEach(previewCards) { card in
                        let isUnlocked = viewModel.rewardService.progress[card.id]?.isUnlocked ?? false
                        let cardProgress = viewModel.rewardService.progressRatio(for: card.id)
                        
                        CardView(
                            card: card,
                            team: viewModel.selectedTeam,
                            isUnlocked: isUnlocked,
                            progress: cardProgress
                        )
                        .scaleEffect(0.7)
                        .frame(width: 130, height: 185)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Unlock Banner
    
    private func unlockBanner(for card: RewardCardDefinition) -> some View {
        HStack(spacing: 12) {
            Image(systemName: card.badgeIcon ?? "star.fill")
                .font(.title2)
                .foregroundColor(card.rarity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationUtils.string("Card Unlocked!"))
                    .font(RacingFont.subheader(14))
                    .foregroundColor(.white)
                Text(card.title)
                    .font(RacingFont.body(13))
                    .foregroundColor(card.rarity.color)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.rewardService.dismissUnlockNotification()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(RacingColors.silver)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(card.rarity.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(card.rarity.color.opacity(0.5), lineWidth: 1.5)
                )
        )
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/FeaturesOverviewView.swift`

```swift
import SwiftUI

struct FeaturesOverviewView: View {
    @State private var searchText = ""
    @State private var selectedCategory: FeatureCategory? = nil
    
    var filteredFeatures: [FeatureCategory: [Feature]] {
        var result = [FeatureCategory: [Feature]]()
        
        let all = FeatureRegistry.shared.visibleFeatures.filter { feature in
            let matchesSearch = searchText.isEmpty || 
                feature.title.localizedCaseInsensitiveContains(searchText) ||
                feature.subtitle.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || feature.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
        
        // Group by category but maintain order
        for category in FeatureCategory.allCases {
            let inCat = all.filter { $0.category == category }
            if !inCat.isEmpty {
                result[category] = inCat
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(LocalizationUtils.string("Search function..."), text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(RacingColors.cardBackground)
                    .cornerRadius(8)
                    .padding()
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            CategoryFilterChip(title: "Todas", isSelected: selectedCategory == nil, color: Color.gray) {
                                selectedCategory = nil
                            }
                            
                            ForEach(FeatureCategory.allCases) { cat in
                                CategoryFilterChip(title: cat.rawValue, isSelected: selectedCategory == cat, color: cat.color) {
                                    selectedCategory = cat
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    // List
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(FeatureCategory.allCases) { category in
                                if let features = filteredFeatures[category], !features.isEmpty {
                                    Section(header: CategoryHeader(category: category)) {
                                        ForEach(features) { feature in
                                            NavigationLink(destination: FeatureViewFactory.view(for: feature)) {
                                                FeatureListRow(feature: feature)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Funciones GeoRacing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews

struct CategoryHeader: View {
    let category: FeatureCategory
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
            Text(category.rawValue.uppercased())
                .font(.caption.bold())
                .foregroundColor(category.color)
            Spacer()
        }
        .padding(.top, 8)
    }
}

struct FeatureListRow: View {
    let feature: Feature
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(feature.category.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: feature.icon)
                    .foregroundColor(feature.category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(RacingFont.body().bold())
                    .foregroundColor(.white)
                Text(feature.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if feature.status != .complete {
                Badge(text: feature.status == .placeholder ? "WIP" : "MVP", 
                      color: feature.status == .placeholder ? .gray : .orange)
            } else {
                 Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(RacingColors.cardBackground)
        .cornerRadius(12)
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/GroupView.swift`

```swift
import SwiftUI

struct GroupView: View {
    @StateObject private var viewModel = GroupViewModel()
    @Environment(\.dismiss) var dismiss
    
    // Optional: Pass navigation capability to Map if integrated differently
    // For now we assume "View on Map" just dismisses this sheet if opened from Map,
    // OR we might need to navigate to Map.
    // The user requirement says "Boton Ver en Mapa (abre CircuitMapView con layer de grupo activa)".
    // If we are in features overview, we present this as a sheet. "Ver en Mapa" should probably open Map View.
    @State private var showMap = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.isInGroup {
                    activeGroupView
                } else {
                    noGroupView
                }
            }
            .navigationTitle("Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationUtils.string("Close")) {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showMap) {
                CircuitMapView()
            }
        }
        .onAppear {
            // Check if already in group via repository
        }
    }
    
    var noGroupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(RacingColors.red)
            
            Text(LocalizationUtils.string("Connect with your group"))
                .font(RacingFont.header(24))
                .foregroundColor(.white)
            
            Text(LocalizationUtils.string("Create a group to share location in real time at the circuit."))
                .font(RacingFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider().background(Color.gray)
            
            // Create
            Button(action: {
                Task {
                    await viewModel.createGroup()
                }
            }) {
                Text(LocalizationUtils.string("Create New Group"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RacingColors.red)
                    .cornerRadius(12)
            }
            
            Text(LocalizationUtils.string("Or"))
                .foregroundColor(.gray)
            
            // Join
            VStack {
                TextField(LocalizationUtils.string("Group Code"), text: $viewModel.joinCode)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                Button(action: {
                    Task {
                        await viewModel.joinGroup()
                    }
                }) {
                    Text(LocalizationUtils.string("Join"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.joinCode.isEmpty ? Color.gray : RacingColors.silver)
                        .cornerRadius(12)
                }
                .disabled(viewModel.joinCode.isEmpty)
            }
            
            if let error = viewModel.errorMsg {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
    
    var activeGroupView: some View {
        VStack(spacing: 20) {
            // Header Info
            VStack(spacing: 8) {
                Text(viewModel.currentGroup?.name ?? "Grupo")
                    .font(RacingFont.header(22))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Código:")
                        .foregroundColor(.gray)
                    Text(viewModel.currentGroup?.id ?? "---")
                        .font(.monospacedDigit(.system(size: 18, weight: .bold))())
                        .foregroundColor(RacingColors.silver)
                    
                    Button(action: {
                        UIPasteboard.general.string = viewModel.currentGroup?.id
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(RacingColors.red)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(.top)
            
            // Map Button
            Button(action: {
                showMap = true
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text(LocalizationUtils.string("View on Map"))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [RacingColors.red, Color.orange]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .padding(.horizontal)
            
            // Members List
            List {
                Section(header: Text("Miembros (\(viewModel.members.count))").foregroundColor(.gray)) {
                    ForEach(viewModel.members) { member in
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(member.isSharing ? .green : .gray)
                            
                            VStack(alignment: .leading) {
                                Text(member.displayName)
                                    .font(RacingFont.body())
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            if member.isSharing {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            
            // Footer: Leave
            Button(action: {
                viewModel.leaveGroup()
            }) {
                Text(LocalizationUtils.string("Leave Group"))
                    .foregroundColor(.red)
            }
            .padding(.bottom)
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/GuidanceView.swift`

```swift
import SwiftUI
import MapKit

struct GuidanceView: View {
    @StateObject private var viewModel: GuidanceViewModel
    @Environment(\.dismiss) var dismiss
    
    init(itinerary: Itinerary) {
        _viewModel = StateObject(wrappedValue: GuidanceViewModel(itinerary: itinerary))
    }
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(LocalizationUtils.string("Route Guidance"))
                        .font(RacingFont.header(20))
                        .foregroundColor(.white)
                    Spacer()
                    // Hidden balance for centering
                    Image(systemName: "xmark.circle.fill").font(.title).opacity(0)
                }
                .padding()
                
                // Progress Bar
                ProgressView(value: Double(viewModel.currentStepIndex + 1), total: Double(viewModel.itinerary.legs.count))
                    .tint(RacingColors.red)
                    .padding(.horizontal)
                
                // Content Carousel (Driven by VM)
                TabView(selection: $viewModel.currentStepIndex) {
                    ForEach(Array(viewModel.itinerary.legs.enumerated()), id: \.offset) { index, leg in
                        GuidanceStepCard(
                            leg: leg,
                            stepNumber: index + 1,
                            totalSteps: viewModel.itinerary.legs.count,
                            liveDistance: (index == viewModel.currentStepIndex) ? viewModel.distanceToNextStop : nil
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStepIndex)
                
                // Controls
                HStack(spacing: 20) {
                    if viewModel.currentStepIndex > 0 {
                        Button(action: { 
                            withAnimation { viewModel.prevStep() }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    } else {
                        Spacer().frame(width: 50)
                    }
                    
                    if viewModel.currentStepIndex < viewModel.itinerary.legs.count - 1 {
                        Button(action: { 
                            withAnimation { viewModel.advanceStep() }
                        }) {
                            VStack(spacing: 2) {
                                Text("Siguiente Paso")
                                    .font(RacingFont.header(18))
                                if viewModel.distanceToNextStop > 0 {
                                    Text("\(Int(viewModel.distanceToNextStop)) m restantes")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RacingColors.red)
                            .cornerRadius(25)
                        }
                    } else {
                        Button(action: { dismiss() }) {
                            Text("Finalizar Viaje")
                                .font(RacingFont.header(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
            
            // Toast for Completion
            if let msg = viewModel.feedbackMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(RacingFont.header(24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                        .padding(.bottom, 100)
                }
                .transition(.scale)
            }
        }
    }
}

struct GuidanceStepCard: View {
    let leg: Leg
    let stepNumber: Int
    let totalSteps: Int
    let liveDistance: Double? // New: Show live GPS distance if active leg
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon & Mode
            VStack(spacing: 8) {
                Image(systemName: iconForMode(leg.mode))
                    .font(.system(size: 60))
                    .foregroundColor(colorForMode(leg.mode))
                    .symbolEffect(.bounce, value: liveDistance) // Animate if tracking
                
                Text(modeTitle(leg))
                    .font(RacingFont.header(24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Divider().background(Color.white.opacity(0.2))
            
            // Instruction
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(RacingColors.red)
                    VStack(alignment: .leading) {
                        Text("SALIDA")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(leg.from.name)
                            .font(.title3)
                            .foregroundColor(.white)
                        if let dep = leg.from.departureTime {
                            Text("Hora: " + formatTime(dep))
                                .font(.caption)
                                .foregroundColor(RacingColors.red)
                        }
                    }
                }
                
                // Connecting line (dashed idea)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 30)
                    .padding(.leading, 9)
                
                HStack(alignment: .top) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(RacingColors.red)
                    VStack(alignment: .leading) {
                        Text("DESTINO")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(leg.to.name)
                            .font(.title3)
                            .foregroundColor(.white)
                        if let arr = leg.to.arrivalTime {
                            Text("Llegada: " + formatTime(arr))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            
            // Live Stats vs Static Stats
            HStack(spacing: 40) {
                VStack {
                    Image(systemName: "ruler")
                    if let live = liveDistance {
                        Text("\(Int(live)) m")
                            .foregroundColor(RacingColors.red)
                            .fontWeight(.bold)
                    } else {
                        Text("\(Int(leg.distance ?? 0)) m")
                    }
                }
                
                VStack {
                    Image(systemName: "clock")
                    if let live = liveDistance {
                        // Estimate walking time
                        Text("~\(Int(live / 1.2 / 60)) min")
                            .foregroundColor(RacingColors.red)
                            .fontWeight(.bold)
                    } else {
                         Text(formatDuration(leg.duration))
                    }
                }
            }
            .font(.headline)
            .foregroundColor(.gray)
            
            Spacer()
            
            Text("Paso \(stepNumber) de \(totalSteps)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(RacingColors.cardBackground)
        .cornerRadius(24)
        .padding()
        .shadow(radius: 20)
    }
    
    // Helpers (Reused from other views, good candidate for shared helper file)
    func modeTitle(_ leg: Leg) -> String {
        switch leg.mode {
        case "WALK": return "Camina hacia \(leg.to.name)"
        case "BUS": return "Autobús \(leg.routeShortName ?? "") -> \(leg.to.name)"
        case "RAIL": return "Tren \(leg.routeShortName ?? "") -> \(leg.to.name)"
        case "SUBWAY": return "Metro \(leg.routeShortName ?? "")"
        default: return leg.mode.capitalized
        }
    }
    
    func iconForMode(_ mode: String) -> String {
        switch mode {
        case "WALK": return "figure.walk"
        case "BUS": return "bus.fill"
        case "RAIL": return "tram.fill"
        case "SUBWAY": return "train.side.front.car"
        default: return "arrow.triangle.swap"
        }
    }
    
    func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "WALK": return .gray
        case "BUS": return .red
        case "RAIL": return .orange
        case "SUBWAY": return .blue
        default: return .white
        }
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let min = seconds / 60
        if min > 60 {
            return "\(min / 60) h \(min % 60) m"
        }
        return "\(min) min"
    }
    
    func formatTime(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/HomeCustomizeView.swift`

```swift
import SwiftUI

struct HomeCustomizeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Local state for editing
    @State private var activeIds: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                
                List {
                    Section(header: Text("Widgets Activos").foregroundColor(.gray)) {
                        ForEach(activeIds, id: \.self) { id in
                            if let widget = getWidget(id) {
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                    
                                    Image(systemName: widget.icon)
                                        .foregroundColor(widget.color)
                                        .frame(width: 24)
                                    
                                    Text(LocalizationUtils.string(widget.titleKey))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            activeIds.removeAll { $0 == id }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .listRowBackground(RacingColors.cardBackground)
                            }
                        }
                        .onMove(perform: move)
                    }
                    
                    Section(header: Text("Disponibles").foregroundColor(.gray)) {
                        ForEach(availableIds, id: \.self) { id in
                            if let widget = getWidget(id) {
                                HStack {
                                    Image(systemName: widget.icon)
                                        .foregroundColor(widget.color)
                                        .frame(width: 24)
                                    
                                    Text(LocalizationUtils.string(widget.titleKey))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            activeIds.append(id)
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .listRowBackground(RacingColors.cardBackground)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                // Ensure list background is clear to show dark theme
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
            }
            .navigationTitle(LocalizationUtils.string("Customize Home"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationUtils.string("Cancel")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationUtils.string("Save")) {
                        viewModel.updateWidgets(activeIds)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            self.activeIds = viewModel.activeWidgetIds
        }
    }
    
    // Helpers
    
    private var availableIds: [String] {
        let all = HomeViewModel.allAvailableWidgets.map { $0.id }
        return all.filter { !activeIds.contains($0) }
    }
    
    private func getWidget(_ id: String) -> DashboardWidget? {
        HomeViewModel.allAvailableWidgets.first { $0.id == id }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        activeIds.move(fromOffsets: source, toOffset: destination)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/HomeView.swift`

```swift
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var teamTheme = TeamThemeService.shared
    @EnvironmentObject private var circuitState: HybridCircuitStateRepository
    @Binding var selectedTab: TabIdentifier
    @Binding var showMenu: Bool
    @Binding var showParkingSheet: Bool
    @State private var showReportSheet = false
    @State private var showSocialSheet = false
    @State private var showFanZoneSheet = false // NEW
    
    // Edit Mode State
    @State private var isEditing = false
    @State private var draggedItem: String?
    @State private var showAddWidgetSheet = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Team-themed gradient background
                teamTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        trackStatusCard
                        widgetsGrid
                        newsSection
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: viewModel.activeWidgetIds) { _, newValue in
                viewModel.updateWidgets(newValue)
            }
            .onAppear {
                teamTheme.refresh()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button(action: { withAnimation { showMenu = true } }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Menu")
            
            VStack(alignment: .leading) {
                Text(viewModel.greeting)
                    .font(RacingFont.body())
                    .foregroundColor(RacingColors.silver)
                Text(viewModel.currentDateString)
                    .font(RacingFont.header(20))
                    .foregroundColor(RacingColors.white)
            }
            
            // Team Badge
            Button(action: { showFanZoneSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: teamTheme.teamIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                    Text(teamTheme.teamName)
                        .font(RacingFont.body(12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(teamTheme.primaryColor.opacity(0.3))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(teamTheme.primaryColor.opacity(0.6), lineWidth: 1)
                )
            }
            .accessibilityLabel("Fan Zone: \(teamTheme.teamName)")
            .accessibilityHint("Opens Fan Zone settings")
            
            
            Spacer()
            
            // Edit Button (Toggle Mode)
            Button(action: {
                withAnimation { isEditing.toggle() }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                    if isEditing { Text("Done").font(.caption).bold() }
                }
                .foregroundColor(isEditing ? .green : RacingColors.silver)
                .padding(6)
                .background(isEditing ? Color.black.opacity(0.3) : Color.clear)
                .cornerRadius(16)
            }
            .padding(.trailing, 8)
            
            // Weather Widget (Mini)
            if let weather = viewModel.weather {
                HStack {
                    Image(systemName: weather.iconName)
                        .renderingMode(.original)
                    Text("\(Int(weather.tempC))°")
                        .font(RacingFont.subheader())
                        .foregroundColor(RacingColors.white)
                }
                .padding(8)
                .background(RacingColors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RacingColors.silver.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var trackStatusCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(liveTrackStatus.color.opacity(0.1))
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(liveTrackStatus.color.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: liveTrackStatus.iconName)
                            .font(.title)
                            .foregroundColor(liveTrackStatus == .yellow || liveTrackStatus == .sc ? .black : .white)
                            .padding(12)
                            .background(Circle().fill(liveTrackStatus.color))
                        
                        Text(LocalizationUtils.string(liveTrackStatus.titleKey))
                            .font(RacingFont.header(28))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(circuitState.message.isEmpty ? LocalizationUtils.string(liveTrackStatus.messageKey) : circuitState.message)
                            .font(RacingFont.subheader())
                            .foregroundColor(RacingColors.silver)
                            .multilineTextAlignment(.leading)
                        if !circuitState.updatedAt.isEmpty {
                            Text(circuitState.updatedAt)
                                .font(RacingFont.body(12))
                                .foregroundColor(RacingColors.silver.opacity(0.8))
                        }
                    }
                }
                .padding(24)
                Spacer()
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Track Status: \(LocalizationUtils.string(liveTrackStatus.titleKey)). \(circuitState.message.isEmpty ? LocalizationUtils.string(liveTrackStatus.messageKey) : circuitState.message)")
    }
    
    private var widgetsGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(Array(viewModel.activeWidgetIds.enumerated()), id: \.element) { index, id in
                if let widget = getWidget(id) {
                    widgetItem(widget: widget, id: id, index: index)
                }
            }
            
            // "Add Widget" Button (Only in Edit Mode)
            if isEditing {
                Button(action: { showAddWidgetSheet = true }) {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        Text(LocalizationUtils.string("Add Widget"))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showAddWidgetSheet) {
            HomeAddWidgetSheet(viewModel: viewModel, showSheet: $showAddWidgetSheet)
        }
        .sheet(isPresented: $showReportSheet) {
            IncidentReportView()
        }
        .sheet(isPresented: $showSocialSheet) {
            SocialView()
        }
        .sheet(isPresented: $showFanZoneSheet) {
            FanZoneView()
        }
    }
    
    // MARK: - Widget Item
    
    private func widgetItem(widget: DashboardWidget, id: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            DashboardButton(icon: widget.icon, title: LocalizationUtils.string(widget.titleKey), color: widget.color) {
                if !isEditing {
                    handleWidgetAction(id)
                }
            }
            .if(isEditing) { view in
                view.onDrag {
                    self.draggedItem = id
                    return NSItemProvider(object: id as NSString)
                }
            }
            .onDrop(of: [UTType.text], delegate: WidgetDropDelegate(item: id, items: $viewModel.activeWidgetIds, draggedItem: $draggedItem))
            .opacity(draggedItem == id ? 0.5 : 1.0)
            .modifier(JiggleModifier(isJiggling: isEditing))
            
            if isEditing {
                Button {
                    withAnimation { viewModel.activeWidgetIds.removeAll { $0 == id } }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                }
                .offset(x: 8, y: -8)
            }
        }
    }
    
    // MARK: - News Section
    
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationUtils.string("Latest News"))
                .font(RacingFont.header(24))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.newsItems) { item in
                    NewsItemView(item: item)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helpers
    
    private var liveTrackStatus: TrackStatus {
        circuitState.resolvedTrackStatus(fallback: viewModel.currentTrackStatus)
    }
    
    private func getWidget(_ id: String) -> DashboardWidget? {
        HomeViewModel.allAvailableWidgets.first { $0.id == id }
    }
    
    private func handleWidgetAction(_ id: String) {
        switch id {
        case "map": selectedTab = .map
        case "shop": selectedTab = .shop
        case "food": selectedTab = .shop
        case "wc": selectedTab = .map
        case "parking": showParkingSheet = true
        case "schedule": break
        case "social": showSocialSheet = true
        case "incidents": showReportSheet = true
        case "tickets": selectedTab = .shop
        case "video": break
        case "weather": break
        case "profile": break
        case "fanzone": showFanZoneSheet = true
        default: break
        }
    }
}

// MARK: - Jiggle Modifier (iOS Style)

struct JiggleModifier: ViewModifier {
    let isJiggling: Bool
    
    @State private var animating = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isJiggling && animating ? 2 : (isJiggling ? -2 : 0)))
            .animation(
                isJiggling 
                    ? .easeInOut(duration: 0.1).repeatForever(autoreverses: true)
                    : .easeOut(duration: 0.1),
                value: animating
            )
            .animation(.easeOut(duration: 0.1), value: isJiggling)
            .onChange(of: isJiggling) { _, jiggling in
                animating = jiggling
            }
            .onAppear {
                if isJiggling { animating = true }
            }
    }
}

// MARK: - Drop Delegate
struct WidgetDropDelegate: DropDelegate {
    let item: String
    @Binding var items: [String]
    @Binding var draggedItem: String?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem else { return }
        
        if draggedItem != item {
            if let from = items.firstIndex(of: draggedItem),
               let to = items.firstIndex(of: item) {
                withAnimation {
                    items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                }
            }
        }
    }
}

// MARK: - Add Widget Sheet
struct HomeAddWidgetSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showSheet: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                List {
                    ForEach(availableIds, id: \.self) { id in
                        if let widget = getWidget(id) {
                            HStack {
                                Image(systemName: widget.icon)
                                    .foregroundColor(widget.color)
                                Text(LocalizationUtils.string(widget.titleKey))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(LocalizationUtils.string("Add")) {
                                    withAnimation {
                                        viewModel.activeWidgetIds.append(id)
                                    }
                                    showSheet = false
                                }
                                .foregroundColor(.green)
                            }
                            .listRowBackground(RacingColors.cardBackground)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .onAppear { UITableView.appearance().backgroundColor = .clear }
            }
            .navigationTitle(LocalizationUtils.string("Add Widget"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationUtils.string("Close")) { showSheet = false }
                }
            }
        }
    }
    
    private var availableIds: [String] {
        HomeViewModel.allAvailableWidgets.map { $0.id }.filter { !viewModel.activeWidgetIds.contains($0) }
    }
    
    private func getWidget(_ id: String) -> DashboardWidget? {
        HomeViewModel.allAvailableWidgets.first { $0.id == id }
    }
}

// MARK: - Edit Mode Wiggle Modifier

struct EditModeWiggle: ViewModifier {
    let isEditing: Bool
    let angle: Double
    let bounceOffset: CGFloat
    let phaseOffset: Double
    
    @State private var phase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isEditing ? angle * sin(phase * Double.pi * 2) : 0))
            .offset(y: isEditing ? CGFloat(bounceOffset * sin((phase + 0.25) * Double.pi * 2)) : 0)
            .scaleEffect(isEditing ? 0.95 + 0.03 * sin((phase + 0.5) * Double.pi * 2) : 1.0)
            .onChange(of: isEditing) { _, newValue in
                if newValue {
                    startWiggling()
                } else {
                    phase = 0
                }
            }
            .onAppear {
                if isEditing {
                    startWiggling()
                }
            }
    }
    
    private func startWiggling() {
        phase = phaseOffset
        withAnimation(
            .linear(duration: 0.4)
            .repeatForever(autoreverses: false)
        ) {
            phase = 1 + phaseOffset
        }
    }
}

// MARK: - Pulse Effect for Delete Button

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.15 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.8)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/IncidentReportView.swift`

```swift
import SwiftUI

struct IncidentReportView: View {
    @StateObject private var viewModel = IncidentViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    
                    // Header
                    Text(LocalizationUtils.string("Report Incident"))
                        .font(RacingFont.header(24))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // Category Selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(IncidentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.rawValue.capitalized,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Description Input
                    VStack(alignment: .leading) {
                        Text(LocalizationUtils.string("Description"))
                            .font(RacingFont.subheader())
                            .foregroundColor(RacingColors.silver)
                        
                        TextEditor(text: $viewModel.description)
                            .frame(height: 120)
                            .padding(8)
                            .background(RacingColors.cardBackground)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    if let error = viewModel.submissionError {
                        Text(error)
                            .foregroundColor(RacingColors.red)
                            .font(RacingFont.body())
                    }
                    
                    if viewModel.submissionSuccess {
                        Text(LocalizationUtils.string("Report submitted successfully!"))
                            .foregroundColor(.green)
                            .font(RacingFont.header(18))
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                    }
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: viewModel.submit) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text(LocalizationUtils.string("Submit Report"))
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [RacingColors.red, Color.red.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .navigationBarItems(trailing: Button(LocalizationUtils.string("Close")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RacingFont.body())
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? RacingColors.red : RacingColors.cardBackground)
                .foregroundColor(.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : RacingColors.silver.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/ItineraryDetailSheet.swift`

```swift
import SwiftUI
import MapKit

struct ItineraryDetailSheet: View {
    let itinerary: Itinerary
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header Summary
                    headerSummary
                    
                    Divider().background(Color.white.opacity(0.2))
                    
                    // Steps List
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
                                LegDetailRow(leg: leg, isLast: index == itinerary.legs.count - 1)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(LocalizationUtils.string("Trip Detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationUtils.string("Close")) { dismiss() }
                }
            }
        }
    }
    
    var headerSummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Duración Total")
                        .font(RacingFont.body(14))
                        .foregroundColor(RacingColors.silver)
                    Text(formatDuration(itinerary.duration))
                        .font(RacingFont.header(24))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Llegada Estimada")
                        .font(RacingFont.body(14))
                        .foregroundColor(RacingColors.silver)
                    Text(formatTime(itinerary.endTime))
                        .font(RacingFont.header(24))
                        .foregroundColor(RacingColors.red)
                }
            }
            .padding()
            
            // "Go" Button
            Button(action: {
                showGuidance = true
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Iniciar Guiado")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RacingColors.red)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .fullScreenCover(isPresented: $showGuidance) {
                GuidanceView(itinerary: itinerary)
            }
        }
        .background(RacingColors.cardBackground)
    }
    
    @State private var showGuidance = false
    
    // Helpers (Duplicate of Row logic, could be shared)
    func formatTime(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let min = seconds / 60
        if min > 60 {
            return "\(min / 60) h \(min % 60) min"
        }
        return "\(min) min"
    }
}

struct LegDetailRow: View {
    let leg: Leg
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline Line
            VStack(spacing: 0) {
                Circle()
                    .fill(colorForMode(leg.mode))
                    .frame(width: 16, height: 16)
                
                // Line connecting to next
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Mode Header
                HStack {
                    Image(systemName: iconForMode(leg.mode))
                        .foregroundColor(colorForMode(leg.mode))
                    Text(modeTitle(leg))
                        .font(RacingFont.header(16))
                        .foregroundColor(.white)
                    Spacer()
                    if let dist = leg.distance {
                        Text("\(Int(dist)) m")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // From / To Info
                VStack(alignment: .leading, spacing: 4) {
                    if leg.mode == "WALK" {
                        Text("Camina hacia \(leg.to.name)")
                            .font(RacingFont.body())
                            .foregroundColor(.white)
                    } else {
                        Text("Sube en: \(leg.from.name)")
                            .font(RacingFont.body())
                            .foregroundColor(.white)
                        Text("Baja en: \(leg.to.name)")
                            .font(RacingFont.body())
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                
                Spacer().frame(height: 16)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    func modeTitle(_ leg: Leg) -> String {
        switch leg.mode {
        case "WALK": return "Caminar"
        case "BUS": return "Bus \(leg.routeShortName ?? "")"
        case "RAIL": return "Tren \(leg.routeShortName ?? "")"
        case "SUBWAY": return "Metro \(leg.routeShortName ?? "")"
        default: return leg.mode.capitalized
        }
    }
    
    func iconForMode(_ mode: String) -> String {
        switch mode {
        case "WALK": return "figure.walk"
        case "BUS": return "bus.fill"
        case "RAIL": return "tram.fill"
        case "SUBWAY": return "train.side.front.car"
        default: return "arrow.triangle.swap"
        }
    }
    
    func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "WALK": return .gray
        case "BUS": return .red
        case "RAIL": return .orange
        case "SUBWAY": return .blue
        default: return .white
        }
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/LoginView.swift`

```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background
            RacingColors.darkBackground
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Logo / Title
                VStack(spacing: 10) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 80))
                        .foregroundColor(RacingColors.red)
                        .padding(.bottom, 20)
                    
                    Text("GeoRacing")
                        .font(RacingFont.header(40))
                        .foregroundColor(.white)
                    
                    Text(LocalizationUtils.string("OFFICIAL APP"))
                        .font(RacingFont.subheader())
                        .foregroundColor(RacingColors.silver)
                        .tracking(2)
                }
                
                Spacer()
                
                // Login Button
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Button(action: handleLogin) {
                            HStack {
                                Image(systemName: "g.circle.fill") // Placeholder for Google Logo
                                    .font(.title2)
                                Text("Sign in with Google")
                                    .font(RacingFont.subheader())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(RacingColors.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/MyOrdersView.swift`

```swift
import SwiftUI

struct MyOrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.orders.isEmpty {
                    emptyView
                } else {
                    ordersList
                }
            }
        }
        .task {
            await viewModel.loadOrders()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Mis Pedidos")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 24)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Orders List
    
    private var ordersList: some View {
        List {
            ForEach(viewModel.orders) { order in
                OrderRowView(order: order)
                    .listRowBackground(Color(white: 0.1))
                    .listRowSeparatorTint(.gray.opacity(0.3))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Loading & Empty
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.5)
            Text(LocalizationUtils.string("Loading orders..."))
                .foregroundColor(.gray)
                .padding(.top)
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bag")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No tienes pedidos")
                .font(.title3)
                .foregroundColor(.gray)
            Text("Tus pedidos aparecerán aquí")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
            Spacer()
        }
    }
}

// MARK: - Order Row

struct OrderRowView: View {
    let order: Order
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pedido #\(order.orderId ?? order.id.prefix(8).description)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(formatDate(order.createdAt))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.2f €", order.totalAmount))
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        StatusBadge(status: order.status)
                    }
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            // Expanded Details
            if isExpanded {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(order.items, id: \.productId) { item in
                        HStack {
                            Text("\(item.quantity)x")
                                .foregroundColor(.orange)
                                .frame(width: 30, alignment: .leading)
                            
                            Text("Producto #\(item.productId.prefix(6))")
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f €", item.unitPrice * Double(item.quantity)))
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "es")
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(displayName)
            .font(.caption2.weight(.semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }
    
    private var displayName: String {
        switch status {
        case .pending: return "Pendiente"
        case .delivered: return "Entregado"
        case .cancelled: return "Cancelado"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return Color.yellow.opacity(0.2)
        case .delivered: return Color.green.opacity(0.2)
        case .cancelled: return Color.red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .yellow
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

#Preview {
    MyOrdersView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/NavigationScreen.swift`

```swift
import SwiftUI
import MapKit
import CoreLocation

/// Full-screen GPS navigation view with turn-by-turn guidance.
/// Default destination: Circuit de Barcelona-Catalunya.
struct NavigationScreen: View {
    
    @StateObject private var viewModel = NavigationViewModel()
    @ObservedObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    /// Optional custom destination (if nil, uses default circuit)
    var customDestination: CLLocationCoordinate2D?
    var customDestinationName: String?
    
    var body: some View {
        ZStack {
            // 1. Map (always visible)
            GPSMapView(
                region: $viewModel.mapRegion,
                polyline: viewModel.polyline,
                destinationCoordinate: viewModel.destinationCoordinate,
                destinationName: viewModel.destinationName,
                isFollowingUser: viewModel.isFollowingUser,
                onUserInteraction: { viewModel.isFollowingUser = false }
            )
            .ignoresSafeArea()
            
            // 2. Overlays based on state
            VStack(spacing: 0) {
                switch viewModel.state {
                case .idle:
                    idleTopBar
                    Spacer()
                    idleBottomPanel
                    
                case .calculatingRoute:
                    Spacer()
                    calculatingOverlay
                    
                case .navigating:
                    turnByTurnBanner
                    Spacer()
                    navigationBottomPanel
                    
                case .arrived:
                    Spacer()
                    arrivedPanel
                    
                case .error(let message):
                    Spacer()
                    errorPanel(message)
                }
            }
            
            // 3. Recenter button (visible during navigation when map was dragged)
            if viewModel.state == .navigating && !viewModel.isFollowingUser {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { viewModel.recenterOnUser() }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 180)
                    }
                }
            }
            
            // 4. GPS status badge
            if locationManager.gpsState != .active && viewModel.state != .idle {
                VStack {
                    gpsStatusBadge
                        .padding(.top, 60)
                    Spacer()
                }
            }
            
            // 5. Rerouting indicator
            if viewModel.isRerouting {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text(LocalizationUtils.string("Recalculating route"))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.orange))
                    .padding(.bottom, 200)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        .onAppear {
            if let dest = customDestination, let name = customDestinationName {
                viewModel.destinationCoordinate = dest
                viewModel.destinationName = name
            }
        }
    }
    
    // MARK: - Idle State (Before navigation starts)
    
    private var idleTopBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 55)
    }
    
    private var idleBottomPanel: some View {
        VStack(spacing: 16) {
            // Destination info
            HStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizationUtils.string("Destination"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.destinationName)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
            }
            
            // Transport mode picker (Car / Walk / Transit)
            Picker("", selection: $viewModel.transportMode) {
                ForEach([TransportMode.automobile, .walking, .transit], id: \.self) { mode in
                    Label(mode.localizedTitle, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Transit info banner
            if viewModel.transportMode == .transit {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text(LocalizationUtils.string("Transit opens in Apple Maps"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
            }
            
            // GPS status
            if locationManager.gpsState == .unauthorized {
                HStack {
                    Image(systemName: "location.slash.fill")
                        .foregroundColor(.red)
                    Text(LocalizationUtils.string("Location permission required"))
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            // Start button
            Button(action: { viewModel.startNavigation() }) {
                HStack {
                    Image(systemName: viewModel.transportMode == .transit
                          ? "arrow.up.right.square.fill"
                          : "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                    Text(viewModel.transportMode == .transit
                         ? LocalizationUtils.string("Open in Apple Maps")
                         : LocalizationUtils.string("Start Navigation"))
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(locationManager.location != nil ? Color.blue : Color.gray)
                )
            }
            .disabled(locationManager.location == nil)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
    
    // MARK: - Calculating Route
    
    private var calculatingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            Text(LocalizationUtils.string("Calculating route..."))
                .font(.headline)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
        )
    }
    
    // MARK: - Turn-by-Turn Banner
    
    private var turnByTurnBanner: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                // Maneuver icon
                Image(systemName: viewModel.maneuverIcon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Distance to next step
                    Text(viewModel.formattedNextStepDistance)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Instruction
                    Text(viewModel.nextInstruction)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Close navigation
                Button(action: { viewModel.stopNavigation() }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
            }
            .padding()
            .background(Color.blue.gradient)
            .padding(.top, 44) // Safe area offset
            
            // Step progress indicator
            if !viewModel.steps.isEmpty {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            let progress = viewModel.steps.isEmpty
                                ? 0
                                : CGFloat(viewModel.currentStepIndex) / CGFloat(viewModel.steps.count)
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                }
                .frame(height: 3)
            }
        }
    }
    
    // MARK: - Navigation Bottom Panel
    
    private var navigationBottomPanel: some View {
        VStack(spacing: 12) {
            HStack {
                // ETA
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizationUtils.string("Arrival"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedETATime)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Remaining time
                VStack(spacing: 2) {
                    Text(viewModel.formattedETA)
                        .font(.title3.bold())
                    Text(LocalizationUtils.string("remaining"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Remaining distance
                VStack(spacing: 2) {
                    Text(viewModel.formattedDistance)
                        .font(.title3.bold())
                    Text(LocalizationUtils.string("distance"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                // Mode toggle
                ForEach([TransportMode.automobile, .walking, .transit], id: \.self) { mode in
                    Button(action: { viewModel.transportMode = mode }) {
                        Image(systemName: mode.icon)
                            .font(.title3)
                            .foregroundColor(viewModel.transportMode == mode ? .white : .secondary)
                            .padding(10)
                            .background(
                                Circle().fill(viewModel.transportMode == mode ? Color.blue : Color.gray.opacity(0.2))
                            )
                    }
                }
                
                Spacer()
                
                // End navigation
                Button(action: { viewModel.stopNavigation() }) {
                    Text(LocalizationUtils.string("End Navigation"))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.red))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
    
    // MARK: - Arrived
    
    private var arrivedPanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text(LocalizationUtils.string("You have arrived!"))
                .font(.title2.bold())
            
            Text(viewModel.destinationName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.stopNavigation()
                dismiss()
            }) {
                Text(LocalizationUtils.string("Close"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
    
    // MARK: - Error
    
    private func errorPanel(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: { viewModel.startNavigation() }) {
                    Text(LocalizationUtils.string("Retry"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                }
                
                Button(action: { dismiss() }) {
                    Text(LocalizationUtils.string("Close"))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
    
    // MARK: - GPS Status Badge
    
    private var gpsStatusBadge: some View {
        HStack(spacing: 6) {
            switch locationManager.gpsState {
            case .unauthorized:
                Image(systemName: "location.slash.fill")
                Text(LocalizationUtils.string("No GPS permission"))
            case .searching:
                ProgressView().tint(.white)
                Text(LocalizationUtils.string("Searching GPS..."))
            case .lowAccuracy:
                Image(systemName: "location.circle")
                Text(LocalizationUtils.string("Low GPS accuracy"))
            case .error(let msg):
                Image(systemName: "exclamationmark.triangle")
                Text(msg)
            case .active:
                EmptyView()
            }
        }
        .font(.caption.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.7)))
    }
}

#Preview {
    NavigationScreen()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/NewsItemView.swift`

```swift
import SwiftUI

struct NewsItemView: View {
    let item: NewsItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            // In a real app we would use AsyncImage, here we use Image with fallback or AsyncImage if URL
            if item.imageUrl.starts(with: "http") {
                AsyncImage(url: URL(string: item.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo").foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .clipped()
            } else {
                Image(item.imageUrl) // Asset
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if item.isEvent {
                    Text("EVENT")
                        .font(RacingFont.body(10).bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RacingColors.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text(item.title)
                    .font(RacingFont.subheader(16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(RacingFont.body(14))
                        .foregroundColor(RacingColors.silver)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding()
        .background(RacingColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RacingColors.silver.opacity(0.1), lineWidth: 1)
        )
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/OnboardingView.swift`

```swift
import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.ignoresSafeArea()
            
            VStack {
                // TabView for slides
                TabView(selection: $currentPage) {
                    OnboardingSlide(
                        image: "flag.checkered.2.crossed",
                        title: "Bienvenido a GeoRacing",
                        description: LocalizationUtils.string("The ultimate circuit experience. Follow the race, track status and locate services."),
                        color: RacingColors.silver
                    ).tag(0)
                    
                    OnboardingSlide(
                        image: "map.fill",
                        title: "Mapa y Servicios",
                        description: LocalizationUtils.string("Find food, WC, parking and your friends on the interactive circuit map."),
                        color: .blue
                    ).tag(1)
                    
                    OnboardingPermissionsSlide(
                        action: {
                            // Request Logic happens here or user does it manually
                            LocalNotificationManager.shared.requestPermission()
                            // Location permission is handled by Map logic usually, but we can trigger it
                        },
                        finishAction: {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    ).tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Bottom Controls
                HStack {
                    if currentPage < 2 {
                        Button("Saltar") {
                            withAnimation { isPresented = false }
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button("Siguiente") {
                            withAnimation { currentPage += 1 }
                        }
                        .font(.headline)
                        .foregroundColor(RacingColors.silver)
                    } else {
                        Spacer()
                    }
                }
                .padding()
            }
        }
    }
}

struct OnboardingSlide: View {
    let image: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(color)
            
            Text(title)
                .font(RacingFont.header(28))
                .foregroundColor(.white)
            
            Text(description)
                .font(RacingFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct OnboardingPermissionsSlide: View {
    var action: () -> Void
    var finishAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "bell.badge.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow)
            
            Text("Permisos")
                .font(RacingFont.header(28))
                .foregroundColor(.white)
            
            Text(LocalizationUtils.string("To alert you about Safety Cars and emergencies, we need to send you notifications."))
                .font(RacingFont.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: action) {
                Text(LocalizationUtils.string("Enable Notifications"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: finishAction) {
                Text("Comenzar")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RacingColors.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/OrdersView.swift`

```swift
import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCart = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                categoryFilterView
                
                if viewModel.isLoading && viewModel.products.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    productsGrid
                }
            }
            
            if !viewModel.isCartEmpty {
                VStack {
                    Spacer()
                    cartFloatingButton
                }
            }
        }
        .sheet(isPresented: $showCart) {
            CartSheetView(viewModel: viewModel)
        }
        .alert(LocalizationUtils.string("Success"), isPresented: $viewModel.showSuccessDialog) {
            Button("OK") { viewModel.dismissSuccessDialog() }
        } message: {
            Text(LocalizationUtils.string("Order processed successfully"))
        }
        .task {
            await viewModel.loadProducts()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Text("Tienda")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                showCart = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if viewModel.cartItemCount > 0 {
                        Text("\(viewModel.cartItemCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Category Filter
    
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryChip(nil, title: LocalizationUtils.string("All"), icon: "square.grid.2x2")
                
                ForEach(viewModel.categories, id: \.self) { category in
                    categoryChip(category, title: displayName(for: category), icon: icon(for: category))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(white: 0.1))
    }
    
    private func categoryChip(_ category: String?, title: String, icon: String) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.setFilter(category)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(white: 0.2))
            .cornerRadius(20)
        }
    }
    
    private func displayName(for category: String) -> String {
        switch category.lowercased() {
        case "comida", "food": return "Comida"
        case "bebidas", "drinks": return "Bebidas"
        case "merchandise", "merch": return "Merch"
        case "tickets": return "Tickets"
        default: return category.capitalized
        }
    }
    
    private func icon(for category: String) -> String {
        switch category.lowercased() {
        case "comida", "food": return "fork.knife"
        case "bebidas", "drinks": return "cup.and.saucer.fill"
        case "merchandise", "merch": return "tshirt.fill"
        case "tickets": return "ticket.fill"
        default: return "tag.fill"
        }
    }
    
    // MARK: - Products Grid
    
    private var productsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.filteredProducts) { product in
                    ProductCardView(
                        product: product,
                        quantity: viewModel.quantity(for: product),
                        onAdd: { viewModel.addToCart(product) },
                        onRemove: { viewModel.removeFromCart(product) }
                    )
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Loading & Error
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.5)
            Text(LocalizationUtils.string("Loading products..."))
                .foregroundColor(.gray)
                .padding(.top)
            Spacer()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            Button("Reintentar") {
                Task { await viewModel.loadProducts() }
            }
            .foregroundColor(.orange)
            Spacer()
        }
    }
    
    // MARK: - Floating Cart Button
    
    private var cartFloatingButton: some View {
        Button {
            showCart = true
        } label: {
            HStack {
                Image(systemName: "cart.fill")
                Text("Ver Carrito")
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "%.2f €", viewModel.cartTotal))
                    .fontWeight(.bold)
            }
            .foregroundColor(.black)
            .padding()
            .background(Color.orange)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Product Card

struct ProductCardView: View {
    let product: Product
    let quantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image/Emoji
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .aspectRatio(1, contentMode: .fit)
                
                if let emoji = product.emoji {
                    Image(systemName: emoji)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: iconForCategory(product.category))
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
            
            Text(product.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(String(format: "%.2f €", product.price))
                .font(.headline.weight(.bold))
                .foregroundColor(.orange)
            
            // Quantity Controls
            HStack {
                if quantity > 0 {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(white: 0.2))
                            .cornerRadius(8)
                    }
                    
                    Text("\(quantity)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 28)
                }
                
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.black)
                        .frame(width: 28, height: 28)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(white: 0.12))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name), \(String(format: "%.2f", product.price)) euros, quantity: \(quantity)")
        .accessibilityHint("Double tap to add to cart")
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "comida", "food": return "fork.knife"
        case "bebidas", "drinks": return "cup.and.saucer.fill"
        case "merchandise", "merch": return "tshirt.fill"
        case "tickets": return "ticket.fill"
        default: return "tag.fill"
        }
    }
}

// MARK: - Cart Sheet

struct CartSheetView: View {
    @ObservedObject var viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isCartEmpty {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
            .navigationTitle("Carrito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationUtils.string("Close")) { dismiss() }
                        .foregroundColor(.orange)
                }
                if !viewModel.isCartEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Vaciar") { viewModel.clearCart() }
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Tu carrito está vacío")
                .font(.title3)
                .foregroundColor(.gray)
        }
    }
    
    private var cartContentView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.cartItems) { item in
                    CartItemRow(
                        item: item,
                        onAdd: { viewModel.addToCart(item.product) },
                        onRemove: { viewModel.removeFromCart(item.product) }
                    )
                    .listRowBackground(Color(white: 0.1))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Checkout Section
            VStack(spacing: 12) {
                HStack {
                    Text("Total")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.2f €", viewModel.cartTotal))
                        .font(.title2.bold())
                        .foregroundColor(.orange)
                }
                
                Button {
                    Task { await viewModel.checkout() }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Confirmar Pedido")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            .background(Color(white: 0.1))
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.product.name)
                    .foregroundColor(.white)
                Text(String(format: "%.2f € c/u", item.product.price))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.orange)
                }
                
                Text("\(item.quantity)")
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            Text(String(format: "%.2f €", item.subtotal))
                .foregroundColor(.white)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .trailing)
        }
    }
}

#Preview {
    OrdersView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/PoiListView.swift`

```swift
import SwiftUI
import Combine

struct PoiListView: View {
    @StateObject private var viewModel = PoiListViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar
                searchBar
                
                // Filter Chips
                filterChips
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredPois.isEmpty {
                    emptyView
                } else {
                    poiList
                }
            }
        }
        .task {
            await viewModel.loadPois()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(LocalizationUtils.string("Points of Interest"))
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 24)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(LocalizationUtils.string("Search..."), text: $viewModel.searchText)
                .foregroundColor(.white)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, title: LocalizationUtils.string("All"), icon: "square.grid.2x2")
                filterChip("WC", title: "WC", icon: "toilet")
                filterChip("FOOD", title: LocalizationUtils.string("Food"), icon: "fork.knife")
                filterChip("PARKING", title: LocalizationUtils.string("Parking"), icon: "car.fill")
                filterChip("ENTRANCE", title: LocalizationUtils.string("Entries"), icon: "door.left.hand.open")
                filterChip("MEDICAL", title: "Medical", icon: "cross.fill")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func filterChip(_ type: String?, title: String, icon: String) -> some View {
        let isSelected = viewModel.selectedType == type
        return Button {
            viewModel.selectedType = type
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(white: 0.15))
            .cornerRadius(16)
        }
    }
    
    // MARK: - POI List
    
    private var poiList: some View {
        List {
            ForEach(viewModel.filteredPois) { poi in
                PoiRowView(poi: poi)
                    .listRowBackground(Color(white: 0.1))
                    .listRowSeparatorTint(.gray.opacity(0.3))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Loading & Empty
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.5)
            Text(LocalizationUtils.string("Loading..."))
                .foregroundColor(.gray)
                .padding(.top)
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(LocalizationUtils.string("No results found"))
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// MARK: - POI Row

struct PoiRowView: View {
    let poi: PoiItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(poi.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: poi.type.icon)
                    .foregroundColor(poi.type.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(poi.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let zone = poi.zone {
                    Text(zone)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Navigate button
            Button {
                // Navigate to POI
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models

struct PoiItem: Identifiable {
    let id: String
    let name: String
    let type: PoiItemType
    let zone: String?
    let latitude: Double
    let longitude: Double
}

enum PoiItemType: String {
    case wc = "WC"
    case food = "FOOD"
    case parking = "PARKING"
    case entrance = "ENTRANCE"
    case medical = "MEDICAL"
    case shop = "SHOP"
    case info = "INFO"
    case other = "OTHER"
    
    var icon: String {
        switch self {
        case .wc: return "toilet"
        case .food: return "fork.knife"
        case .parking: return "car.fill"
        case .entrance: return "door.left.hand.open"
        case .medical: return "cross.fill"
        case .shop: return "bag.fill"
        case .info: return "info.circle.fill"
        case .other: return "mappin"
        }
    }
    
    var color: Color {
        switch self {
        case .wc: return .blue
        case .food: return .orange
        case .parking: return .purple
        case .entrance: return .green
        case .medical: return .red
        case .shop: return .pink
        case .info: return .cyan
        case .other: return .gray
        }
    }
}

// MARK: - ViewModel

@MainActor
final class PoiListViewModel: ObservableObject {
    
    @Published var pois: [PoiItem] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedType: String?
    
    var filteredPois: [PoiItem] {
        var result = pois
        
        // Filter by type
        if let type = selectedType {
            result = result.filter { $0.type.rawValue == type }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.zone?.lowercased().contains(query) ?? false)
            }
        }
        
        return result
    }
    
    func loadPois() async {
        isLoading = true
        
        // Simulate loading - in real app, fetch from API/repository
        try? await Task.sleep(for: .milliseconds(500))
        
        pois = [
            PoiItem(id: "1", name: "WC Principal", type: .wc, zone: "Tribuna Principal", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "2", name: "WC Paddock", type: .wc, zone: "Paddock", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "3", name: "Restaurante Circuit", type: .food, zone: "Tribuna Principal", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "4", name: "Food Truck", type: .food, zone: "Zona Fan", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "5", name: "Parking A", type: .parking, zone: "Entrada Norte", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "6", name: "Parking B", type: .parking, zone: "Entrada Sur", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "7", name: "Entrada Principal", type: .entrance, zone: nil, latitude: 41.57, longitude: 2.26),
            PoiItem(id: "8", name: "Entrada VIP", type: .entrance, zone: nil, latitude: 41.57, longitude: 2.26),
            PoiItem(id: "9", name: "Centro Médico", type: .medical, zone: "Tribuna Central", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "10", name: "Tienda Oficial", type: .shop, zone: "Entrada Principal", latitude: 41.57, longitude: 2.26),
            PoiItem(id: "11", name: "Info Point", type: .info, zone: "Tribuna Principal", latitude: 41.57, longitude: 2.26),
        ]
        
        isLoading = false
    }
}

#Preview {
    PoiListView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/PublicTransportSheetView.swift`

```swift
import SwiftUI
import MapKit

struct PublicTransportSheetView: View {
    @StateObject private var viewModel = PublicTransportViewModel()
    @ObservedObject var mapViewModel: MapViewModel // To get user location
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: LocalizationUtils.string("All"), isSelected: viewModel.selectedModeFilter == "ALL") {
                                viewModel.setFilter("ALL")
                            }
                            FilterChip(title: "Bus", isSelected: viewModel.selectedModeFilter == "BUS") {
                                viewModel.setFilter("BUS")
                            }
                            FilterChip(title: "Tren", isSelected: viewModel.selectedModeFilter == "RAIL") {
                                viewModel.setFilter("RAIL")
                            }
                        }
                        .padding()
                    }
                    .background(Color.black.opacity(0.2))
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Buscando mejores rutas...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                        Spacer()
                    } else if let error = viewModel.error, viewModel.itineraries.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                            Text(error)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Button(LocalizationUtils.string("Open in Apple Maps")) {
                                mapViewModel.openInAppleMaps() // Fallback
                            }
                            .padding()
                            .background(RacingColors.red)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.itineraries) { itinerary in
                                ZStack {
                                    ItineraryRow(itinerary: itinerary)
                                    // Hidden Navigation Link for cleaner UI interaction
                                    NavigationLink(destination: ItineraryDetailSheet(itinerary: itinerary)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .listRowBackground(RacingColors.cardBackground)
                                .listRowSeparator(.hidden)
                                .padding(.bottom, 8)
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            viewModel.loadRoutes(from: mapViewModel.userLocation, to: mapViewModel.transportDestination)
                        }
                    }
                }
            }
            .navigationTitle(LocalizationUtils.string("Public Transport"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationUtils.string("Close")) { dismiss() }
                }
            }
            .onAppear {
                viewModel.loadRoutes(from: mapViewModel.userLocation, to: mapViewModel.transportDestination)
            }
        }
    }
}

struct ItineraryRow: View {
    let itinerary: Itinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Times and Duration
            HStack {
                VStack(alignment: .leading) {
                    Text("\(formatTime(itinerary.startTime)) - \(formatTime(itinerary.endTime))")
                        .font(RacingFont.header(18))
                        .foregroundColor(.white)
                    Text(formatDuration(itinerary.duration))
                        .font(RacingFont.body(14))
                        .foregroundColor(RacingColors.silver)
                }
                Spacer()
                
                if hasRealTime(itinerary) {
                    HStack(spacing: 4) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .symbolEffect(.variableColor.iterative.reversing)
                        Text("En vivo")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // Legs Visualization
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
                        HStack(spacing: 0) {
                            // Icon based on mode
                            Image(systemName: iconForMode(leg.mode))
                                .font(.system(size: 14))
                                .foregroundColor(colorForMode(leg.mode))
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                            
                            if let shortName = leg.routeShortName {
                                Text(shortName)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colorForRoute(leg.routeColor))
                                    .cornerRadius(4)
                                    .padding(.leading, 4)
                            }
                            
                            if index < itinerary.legs.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(RacingColors.silver)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1C1C1E")) // Slightly lighter than dark background
        )
    }
    
    // Helpers
    func formatTime(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let min = seconds / 60
        if min > 60 {
            return "\(min / 60) h \(min % 60) min"
        }
        return "\(min) min"
    }
    
    func hasRealTime(_ it: Itinerary) -> Bool {
        return it.legs.contains { $0.realTime == true }
    }
    
    func iconForMode(_ mode: String) -> String {
        switch mode {
        case "WALK": return "figure.walk"
        case "BUS": return "bus.fill"
        case "RAIL": return "tram.fill"
        case "SUBWAY": return "train.side.front.car"
        default: return "arrow.triangle.swap"
        }
    }
    
    func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "WALK": return .gray
        case "BUS": return .red
        case "RAIL": return .orange
        case "SUBWAY": return .blue
        default: return .white
        }
    }
    
    func colorForRoute(_ hex: String?) -> Color {
        guard let hex = hex else { return .gray }
        return Color(hex: hex)
    }
}

// Color Hex Extension (Simplified)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



```

---

## `iOS_App/GeoRacing/Presentation/Views/QRScannerView.swift`

```swift
import SwiftUI
@preconcurrency import AVFoundation
import Combine

struct QRScannerView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onCodeScanned: (String) -> Void
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            // Overlay
            scannerOverlay
            
            // Header
            VStack {
                headerView
                Spacer()
            }
            
            // Status Messages
            VStack {
                Spacer()
                statusView
            }
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onChange(of: viewModel.scannedCode) { _, newValue in
            if let code = newValue {
                onCodeScanned(code)
                dismiss()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(LocalizationUtils.string("Scan QR"))
                .font(.title2.bold())
                .foregroundColor(.white)
                .shadow(radius: 4)
            
            Spacer()
            
            // Toggle flash
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding()
        .padding(.top, 40)
    }
    
    // MARK: - Scanner Overlay
    
    private var scannerOverlay: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) * 0.7
            let _ = CGRect(
                x: (geometry.size.width - size) / 2,
                y: (geometry.size.height - size) / 2,
                width: size,
                height: size
            )
            
            ZStack {
                // Dimmed background
                Color.black.opacity(0.6)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: size, height: size)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Scanner frame
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange, lineWidth: 3)
                    .frame(width: size, height: size)
                
                // Corner accents
                scannerCorners(size: size)
                
                // Scanning line animation
                if viewModel.isScanning {
                    scanningLine(size: size)
                }
            }
        }
    }
    
    private func scannerCorners(size: CGFloat) -> some View {
        let cornerLength: CGFloat = 40
        let lineWidth: CGFloat = 4
        
        return ZStack {
            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
            }
            .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .offset(x: -size/2 + 10, y: -size/2 + 10)
            
            // Top-right
            Path { path in
                path.move(to: CGPoint(x: -cornerLength, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: cornerLength))
            }
            .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .offset(x: size/2 - 10, y: -size/2 + 10)
            
            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: -cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
            }
            .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .offset(x: -size/2 + 10, y: size/2 - 10)
            
            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: -cornerLength, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -cornerLength))
            }
            .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .offset(x: size/2 - 10, y: size/2 - 10)
        }
    }
    
    @State private var scanLineOffset: CGFloat = -1
    
    private func scanningLine(size: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .orange, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size - 40, height: 2)
            .offset(y: scanLineOffset * (size / 2 - 20))
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    scanLineOffset = 1
                }
            }
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: 16) {
            if viewModel.isScanning {
                Text(LocalizationUtils.string("Point at QR code"))
                    .font(.headline)
                    .foregroundColor(.white)
            } else if !viewModel.hasCameraPermission {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(LocalizationUtils.string("Camera access needed"))
                        .font(.headline)
                        .foregroundColor(.white)
                    Button(LocalizationUtils.string("Open Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .padding(.bottom, 60)
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

class VideoPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // Safe: layerClass is set to AVCaptureVideoPreviewLayer
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - QR Scanner ViewModel

@MainActor
final class QRScannerViewModel: NSObject, ObservableObject {
    
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var isFlashOn = false
    @Published var hasCameraPermission = false
    @Published var error: String?
    
    var captureSession: AVCaptureSession?
    private let metadataOutput = AVCaptureMetadataOutput()
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.hasCameraPermission = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            hasCameraPermission = false
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            error = LocalizationUtils.string("Could not access camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        self.captureSession = session
    }
    
    func startScanning() {
        guard let session = captureSession, !session.isRunning else { return }
        let capturedSession = session
        Task.detached {
            capturedSession.startRunning()
            await MainActor.run { [weak self] in
                self?.isScanning = true
            }
        }
    }
    
    func stopScanning() {
        guard let session = captureSession, session.isRunning else { return }
        let capturedSession = session
        Task.detached {
            capturedSession.stopRunning()
        }
        isScanning = false
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            isFlashOn.toggle()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            self.error = LocalizationUtils.string("Could not activate flash")
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, 
                         didOutput metadataObjects: [AVMetadataObject], 
                         from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let code = object.stringValue else { return }
        
        // Vibrate on success
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        Task { @MainActor in
            self.stopScanning()
            self.scannedCode = code
        }
    }
}

#Preview {
    QRScannerView { code in
        Logger.debug("[QRScanner] Scanned: \(code)")
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/QuizView.swift`

```swift
import SwiftUI

// MARK: - Quiz View

/// Full quiz session screen with progress, scoring, and card reward triggers.
struct QuizView: View {
    @ObservedObject var viewModel: FanZoneViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    @State private var correctCount = 0
    @State private var streak = 0
    @State private var isFinished = false
    @State private var animateCorrect = false
    @State private var animateWrong = false
    
    private let sessionSize = 10
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.ignoresSafeArea()
                
                if isFinished {
                    resultsSummary
                } else if questions.isEmpty {
                    loadingView
                } else {
                    questionView
                }
            }
            .navigationTitle(LocalizationUtils.string("Trivia"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RacingColors.silver)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            questions = viewModel.questionService.quizSession(
                count: sessionSize,
                championship: viewModel.selectedChampionship,
                teamId: viewModel.selectedTeam?.id
            )
        }
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        let question = questions[currentIndex]
        
        return ScrollView {
            VStack(spacing: 24) {
                // Progress Bar
                progressBar
                
                // Stats Row
                HStack {
                    Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Label(
                        "\(LocalizationUtils.string("Streak")): \(streak)",
                        systemImage: "flame.fill"
                    )
                    .foregroundColor(streak >= 3 ? .orange : RacingColors.silver)
                    Spacer()
                    Text("\(currentIndex + 1)/\(questions.count)")
                        .foregroundColor(RacingColors.silver)
                }
                .font(RacingFont.body(14))
                .padding(.horizontal)
                
                // Difficulty
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= question.difficulty ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(level <= question.difficulty ? .yellow : .gray)
                    }
                    Spacer()
                    if let tag = question.tags.first {
                        Text(tag.capitalized)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(viewModel.teamColor.opacity(0.2)))
                            .foregroundColor(viewModel.teamColor)
                    }
                }
                .padding(.horizontal)
                
                // Question
                Text(question.prompt)
                    .font(RacingFont.subheader(20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Options
                VStack(spacing: 12) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        optionButton(index: index, text: option, question: question)
                    }
                }
                .padding(.horizontal)
                
                // Explanation
                if showResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedAnswer == question.correctAnswer
                                  ? "checkmark.circle.fill" : "info.circle.fill")
                            Text(selectedAnswer == question.correctAnswer
                                 ? LocalizationUtils.string("Correct!")
                                 : LocalizationUtils.string("Incorrect"))
                                .font(RacingFont.subheader(16))
                        }
                        .foregroundColor(selectedAnswer == question.correctAnswer ? .green : .orange)
                        
                        Text(question.explanation)
                            .font(RacingFont.body(14))
                            .foregroundColor(RacingColors.silver)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RacingColors.cardBackground)
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // Next Button
                    Button(action: advanceQuestion) {
                        Text(currentIndex < questions.count - 1
                             ? LocalizationUtils.string("Next")
                             : LocalizationUtils.string("See Results"))
                            .font(RacingFont.subheader(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.teamColor)
                            )
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Option Button
    
    private func optionButton(index: Int, text: String, question: QuizQuestion) -> some View {
        Button(action: {
            guard !showResult else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedAnswer = index
                showResult = true
                
                let isCorrect = index == question.correctAnswer
                if isCorrect {
                    correctCount += 1
                    streak += 1
                    animateCorrect = true
                } else {
                    streak = 0
                    animateWrong = true
                }
                
                // Record in service
                viewModel.questionService.recordAnswer(questionId: question.id, wasCorrect: isCorrect)
                viewModel.questionService.updateStreak(correct: isCorrect)
                
                // Trigger reward events
                if isCorrect {
                    Task {
                        await viewModel.rewardService.recordEvent(.quizCorrect)
                        let currentStreak = viewModel.questionService.currentStreak
                        if currentStreak >= 5 {
                            await viewModel.rewardService.recordEvent(.quizStreak(currentStreak))
                        }
                    }
                }
            }
        }) {
            HStack {
                Text(optionLetter(index))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(optionLetterColor(index: index, question: question))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(optionLetterBgColor(index: index, question: question))
                    )
                
                Text(text)
                    .font(RacingFont.body(15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResult && index == question.correctAnswer {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if showResult && index == selectedAnswer {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(optionBackground(index: index, question: question))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(optionBorder(index: index, question: question), lineWidth: 1.5)
            )
        }
        .disabled(showResult)
    }
    
    // MARK: - Styling Helpers
    
    private func optionLetter(_ index: Int) -> String {
        ["A", "B", "C", "D", "E", "F"][safe: index] ?? "\(index)"
    }
    
    private func optionLetterColor(index: Int, question: QuizQuestion) -> Color {
        if showResult && index == question.correctAnswer { return .white }
        if showResult && index == selectedAnswer { return .white }
        return viewModel.teamColor
    }
    
    private func optionLetterBgColor(index: Int, question: QuizQuestion) -> Color {
        if showResult && index == question.correctAnswer { return .green }
        if showResult && index == selectedAnswer { return .red }
        return viewModel.teamColor.opacity(0.2)
    }
    
    private func optionBackground(index: Int, question: QuizQuestion) -> Color {
        if showResult && index == question.correctAnswer { return Color.green.opacity(0.15) }
        if showResult && index == selectedAnswer { return Color.red.opacity(0.15) }
        return RacingColors.cardBackground
    }
    
    private func optionBorder(index: Int, question: QuizQuestion) -> Color {
        if showResult && index == question.correctAnswer { return .green }
        if showResult && index == selectedAnswer { return .red }
        return viewModel.teamColor.opacity(0.3)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(viewModel.teamColor)
                    .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count), height: 6)
                    .animation(.easeInOut, value: currentIndex)
            }
        }
        .frame(height: 6)
        .padding(.horizontal)
    }
    
    // MARK: - Advance
    
    private func advanceQuestion() {
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
                selectedAnswer = nil
                showResult = false
            }
        } else {
            withAnimation {
                isFinished = true
                
                // Check perfect quiz
                if correctCount == questions.count {
                    Task {
                        await viewModel.rewardService.recordEvent(.quizPerfect)
                    }
                }
                
                // First quiz
                if viewModel.questionService.totalAnswered <= questions.count {
                    Task {
                        await viewModel.rewardService.recordEvent(.firstQuiz)
                    }
                }
            }
        }
    }
    
    // MARK: - Results Summary
    
    private var resultsSummary: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(correctCount) / CGFloat(questions.count))
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(correctCount)/\(questions.count)")
                            .font(RacingFont.header(32))
                            .foregroundColor(.white)
                        Text(scoreLabel)
                            .font(RacingFont.body(14))
                            .foregroundColor(scoreColor)
                    }
                }
                .padding(.top, 32)
                
                // Stats
                HStack(spacing: 32) {
                    statItem(
                        icon: "percent",
                        value: "\(Int(Double(correctCount) / Double(max(1, questions.count)) * 100))%",
                        label: LocalizationUtils.string("Accuracy")
                    )
                    statItem(
                        icon: "flame.fill",
                        value: "\(viewModel.questionService.bestStreak)",
                        label: LocalizationUtils.string("Best Streak")
                    )
                    statItem(
                        icon: "number",
                        value: "\(viewModel.questionService.totalAnswered)",
                        label: LocalizationUtils.string("Total")
                    )
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(RacingColors.cardBackground))
                .padding(.horizontal)
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        // New session
                        questions = viewModel.questionService.quizSession(
                            count: sessionSize,
                            championship: viewModel.selectedChampionship,
                            teamId: viewModel.selectedTeam?.id
                        )
                        currentIndex = 0
                        selectedAnswer = nil
                        showResult = false
                        correctCount = 0
                        streak = 0
                        isFinished = false
                    }) {
                        Label(LocalizationUtils.string("Play Again"), systemImage: "arrow.counterclockwise")
                            .font(RacingFont.subheader(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.teamColor))
                    }
                    
                    Button(action: { dismiss() }) {
                        Text(LocalizationUtils.string("Back to Fan Zone"))
                            .font(RacingFont.body(16))
                            .foregroundColor(viewModel.teamColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.teamColor, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
    
    private var scoreColor: Color {
        let ratio = Double(correctCount) / Double(max(1, questions.count))
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .yellow }
        return .red
    }
    
    private var scoreLabel: String {
        let ratio = Double(correctCount) / Double(max(1, questions.count))
        if ratio == 1.0 { return LocalizationUtils.string("Perfect!") }
        if ratio >= 0.8 { return LocalizationUtils.string("Excellent!") }
        if ratio >= 0.5 { return LocalizationUtils.string("Good job!") }
        return LocalizationUtils.string("Keep trying!")
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(viewModel.teamColor)
            Text(value)
                .font(RacingFont.subheader(18))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(RacingColors.silver)
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(viewModel.teamColor)
            Text(LocalizationUtils.string("Loading questions..."))
                .foregroundColor(RacingColors.silver)
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/RoadmapView.swift`

```swift
import SwiftUI
import Combine

struct RoadmapView: View {
    @StateObject private var viewModel = RoadmapViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.categories) { category in
                            CategorySection(
                                category: category,
                                isExpanded: viewModel.expandedCategories.contains(category.id),
                                onToggle: { viewModel.toggleCategory(category.id) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Roadmap")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 24)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: RoadmapCat
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 32)
                    
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Progress indicator
                    Text("\(category.completedCount)/\(category.features.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(Color(white: 0.12))
            }
            
            // Features List
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(category.features) { feature in
                        RoadmapFeatureRow(feature: feature)
                        
                        if feature.id != category.features.last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                }
                .background(Color(white: 0.08))
            }
        }
        .cornerRadius(12)
        .animation(.spring(response: 0.3), value: isExpanded)
    }
}

// MARK: - Feature Row

struct RoadmapFeatureRow: View {
    let feature: RoadmapFeature
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Indicator
            FeatureStatusBadge(status: feature.status)
            
            // Feature Info
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                if let description = feature.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Status Badge

struct FeatureStatusBadge: View {
    let status: RoadmapFeature.Status
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.localizedDisplayName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .orange
        case .planned: return .blue
        case .stub: return .gray
        }
    }
}

// MARK: - Models

struct RoadmapCat: Identifiable {
    let id: String
    let name: String
    let icon: String
    let features: [RoadmapFeature]
    
    var completedCount: Int {
        features.filter { $0.status == .completed }.count
    }
}

struct RoadmapFeature: Identifiable {
    let id: String
    let name: String
    let description: String?
    let status: Status
    
    enum Status {
        case completed
        case inProgress
        case planned
        case stub
        
        var displayName: String {
            switch self {
            case .completed: return "Completed"
            case .inProgress: return "In Progress"
            case .planned: return "Planned"
            case .stub: return "Future"
            }
        }
        
        @MainActor
        var localizedDisplayName: String {
            LocalizationUtils.string(displayName)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class RoadmapViewModel: ObservableObject {
    
    @Published var categories: [RoadmapCat] = []
    @Published var expandedCategories: Set<String> = []
    
    init() {
        loadFeatures()
    }
    
    func toggleCategory(_ id: String) {
        if expandedCategories.contains(id) {
            expandedCategories.remove(id)
        } else {
            expandedCategories.insert(id)
        }
    }
    
    private func loadFeatures() {
        categories = [
            RoadmapCat(
                id: "core",
                name: "Core",
                icon: "cpu",
                features: [
                    RoadmapFeature(id: "core.circuit_state", name: "Estado del Circuito", description: "Polling del estado en tiempo real", status: .completed),
                    RoadmapFeature(id: "core.context_card", name: "Card Contextual", description: "Tarjeta de información dinámica", status: .completed),
                    RoadmapFeature(id: "core.offline_map", name: "Mapa Vivo Offline", description: "Visualización sin conexión", status: .inProgress),
                    RoadmapFeature(id: "core.pois", name: "Puntos de Interés", description: "API real de POIs", status: .completed),
                    RoadmapFeature(id: "core.ble", name: "Balizas Inteligentes", description: "Escaneo BLE en background", status: .completed),
                    RoadmapFeature(id: "core.notifications", name: "Notificaciones", description: "Push notifications locales", status: .completed),
                ]
            ),
            RoadmapCat(
                id: "nav",
                name: "Navegación",
                icon: "location.fill",
                features: [
                    RoadmapFeature(id: "nav.ar_guide", name: "Guía AR", description: "Navegación en realidad aumentada", status: .stub),
                    RoadmapFeature(id: "nav.anticalas", name: "Rutas Anti-colas", description: "Rutas alternativas evitando aglomeraciones", status: .planned),
                    RoadmapFeature(id: "nav.services", name: "Rutas a Servicios", description: "Navegación a WC, comida, etc.", status: .planned),
                    RoadmapFeature(id: "nav.evacuation", name: "Evacuación Dinámica", description: "Rutas de evacuación de emergencia", status: .completed),
                ]
            ),
            RoadmapCat(
                id: "social",
                name: "Social",
                icon: "person.2.fill",
                features: [
                    RoadmapFeature(id: "social.follow_group", name: "Seguir al Grupo", description: "Ver ubicación de amigos", status: .completed),
                    RoadmapFeature(id: "social.qr_share", name: "Compartir QR", description: "Invitar amigos con código QR", status: .completed),
                    RoadmapFeature(id: "social.meetup", name: "Punto de Encuentro", description: "Definir punto de reunión", status: .planned),
                ]
            ),
            RoadmapCat(
                id: "commerce",
                name: "Tienda",
                icon: "cart.fill",
                features: [
                    RoadmapFeature(id: "commerce.products", name: "Catálogo de Productos", description: "Ver productos disponibles", status: .completed),
                    RoadmapFeature(id: "commerce.cart", name: "Carrito de Compras", description: "Añadir/eliminar productos", status: .completed),
                    RoadmapFeature(id: "commerce.checkout", name: "Checkout", description: "Procesar pedidos", status: .completed),
                    RoadmapFeature(id: "commerce.history", name: "Historial de Pedidos", description: "Ver pedidos anteriores", status: .completed),
                ]
            ),
            RoadmapCat(
                id: "fan",
                name: "Fan Experience",
                icon: "star.fill",
                features: [
                    RoadmapFeature(id: "fan.immersive", name: "Fan Immersive", description: "Experiencia inmersiva de carrera", status: .stub),
                    RoadmapFeature(id: "fan.360", name: "Momento 360", description: "Fotos y vídeos 360°", status: .stub),
                    RoadmapFeature(id: "fan.moments", name: "Momentos", description: "Capturar y compartir momentos", status: .stub),
                ]
            ),
            RoadmapCat(
                id: "staff",
                name: "Staff & Ops",
                icon: "person.badge.key.fill",
                features: [
                    RoadmapFeature(id: "staff.panel", name: "Panel Interno", description: "Control para operadores", status: .completed),
                    RoadmapFeature(id: "staff.beacon_remote", name: "Control Remoto", description: "Gestionar beacons remotamente", status: .planned),
                ]
            ),
        ]
        
        // Expand first category by default
        if let first = categories.first {
            expandedCategories.insert(first.id)
        }
    }
}

#Preview {
    RoadmapView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/SeatSetupView.swift`

```swift
import SwiftUI
import Combine

struct SeatSetupView: View {
    @StateObject private var viewModel = SeatSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Info Card
                    infoCard
                    
                    // Form Fields
                    formFields
                    
                    // Save Button
                    saveButton
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .alert(LocalizationUtils.string("Seat saved"), isPresented: $showSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(LocalizationUtils.string("Your seat has been saved. You can use it to navigate directly to your seat."))
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(LocalizationUtils.string("My Seat"))
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 24)
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "ticket.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizationUtils.string("Configure your seat"))
                    .font(.headline)
                    .foregroundColor(.white)
                Text(LocalizationUtils.string("Save your seat to navigate directly to it from anywhere in the circuit."))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Form Fields
    
    private var formFields: some View {
        VStack(spacing: 16) {
            // Tribuna
            formField(
                icon: "building.2",
                title: LocalizationUtils.string("Grandstand"),
                text: $viewModel.tribuna,
                placeholder: LocalizationUtils.string("e.g. Main Grandstand")
            )
            
            // Zona
            formField(
                icon: "square.grid.2x2",
                title: LocalizationUtils.string("Zone"),
                text: $viewModel.zona,
                placeholder: LocalizationUtils.string("e.g. Zone A")
            )
            
            // Fila
            formField(
                icon: "line.3.horizontal",
                title: LocalizationUtils.string("Row"),
                text: $viewModel.fila,
                placeholder: LocalizationUtils.string("e.g. Row 12")
            )
            
            // Asiento
            formField(
                icon: "chair",
                title: LocalizationUtils.string("Seat"),
                text: $viewModel.asiento,
                placeholder: LocalizationUtils.string("e.g. 24")
            )
        }
    }
    
    private func formField(icon: String, title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.gray)
            
            TextField(placeholder, text: text)
                .textFieldStyle(RacingTextFieldStyle())
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            viewModel.save()
            showSaveConfirmation = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(LocalizationUtils.string("Save Seat"))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1 : 0.5)
    }
}

// MARK: - Custom Text Field Style

struct RacingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(white: 0.12))
            .cornerRadius(12)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Seat Setup ViewModel

@MainActor
final class SeatSetupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var tribuna: String
    @Published var zona: String
    @Published var fila: String
    @Published var asiento: String
    
    // MARK: - Computed
    
    var isValid: Bool {
        !tribuna.trimmingCharacters(in: .whitespaces).isEmpty ||
        !zona.trimmingCharacters(in: .whitespaces).isEmpty ||
        !fila.trimmingCharacters(in: .whitespaces).isEmpty ||
        !asiento.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var seatDescription: String {
        [tribuna, zona, fila, asiento]
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }
    
    // MARK: - Private
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let tribuna = "seat.tribuna"
        static let zona = "seat.zona"
        static let fila = "seat.fila"
        static let asiento = "seat.asiento"
    }
    
    // MARK: - Initialization
    
    init() {
        self.tribuna = defaults.string(forKey: Keys.tribuna) ?? ""
        self.zona = defaults.string(forKey: Keys.zona) ?? ""
        self.fila = defaults.string(forKey: Keys.fila) ?? ""
        self.asiento = defaults.string(forKey: Keys.asiento) ?? ""
    }
    
    // MARK: - Actions
    
    func save() {
        defaults.set(tribuna, forKey: Keys.tribuna)
        defaults.set(zona, forKey: Keys.zona)
        defaults.set(fila, forKey: Keys.fila)
        defaults.set(asiento, forKey: Keys.asiento)
    }
    
    func clear() {
        tribuna = ""
        zona = ""
        fila = ""
        asiento = ""
        defaults.removeObject(forKey: Keys.tribuna)
        defaults.removeObject(forKey: Keys.zona)
        defaults.removeObject(forKey: Keys.fila)
        defaults.removeObject(forKey: Keys.asiento)
    }
}

#Preview {
    SeatSetupView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/ServiceViews.swift`

```swift
import SwiftUI

// MARK: - Orders / Ecommerce

struct LegacyOrdersView: View {
    @StateObject private var cartManager = CartManager()
    
    // Mock Products
    // Products loaded via CartManager
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                Text(LocalizationUtils.string("Fan Shop"))
                    .font(RacingFont.header(30))
                    .foregroundColor(.white)
                    .padding(.top)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if cartManager.products.isEmpty {
                             ProgressView().foregroundColor(.white).padding()
                        } else {
                            ForEach(cartManager.products) { product in
                                HStack {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            // Product Image (Web Parity)
                                            if let urlString = product.imageUrl, let url = URL(string: urlString) {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        ProgressView().frame(width: 40, height: 40)
                                                    case .success(let image):
                                                        image.resizable()
                                                             .aspectRatio(contentMode: .fit)
                                                             .frame(width: 40, height: 40)
                                                             .cornerRadius(4)
                                                    case .failure:
                                                        Image(systemName: product.emoji ?? "shippingbox.fill").font(.title).foregroundColor(.white)
                                                    @unknown default:
                                                        Image(systemName: product.emoji ?? "shippingbox.fill").font(.title).foregroundColor(.white)
                                                    }
                                                }
                                            } else {
                                                Image(systemName: product.emoji ?? "shippingbox.fill").font(.title).foregroundColor(.white)
                                            }
                                            
                                            Text(product.name)
                                                .font(RacingFont.subheader())
                                                .foregroundColor(.white)
                                        }
                                        Text("$\(product.price, specifier: "%.2f")")
                                            .font(RacingFont.body())
                                            .foregroundColor(RacingColors.silver)
                                    }
                                    Spacer()
                                    Button(LocalizationUtils.string("Add")) {
                                        cartManager.add(product: product)
                                    }
                                    .font(RacingFont.body().bold())
                                    .padding(8)
                                    .background(RacingColors.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding()
                                .background(RacingColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RacingColors.silver.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    cartManager.loadProducts()
                }
                
                if !cartManager.items.isEmpty {
                    VStack {
                        HStack {
                            Text(LocalizationUtils.string("Cart Total: $"))
                                .font(RacingFont.body())
                                .foregroundColor(RacingColors.silver)
                            Text("\(cartManager.total, specifier: "%.2f")")
                                .font(RacingFont.subheader())
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { Task { try? await cartManager.checkout() } }) {
                            Text(LocalizationUtils.string("Checkout"))
                        }
                        .racingButton(color: RacingColors.red)
                    }
                    .padding()
                    .background(RacingColors.cardBackground)
                    .cornerRadius(16)
                    .padding()
                }
            }
        }
        .alert("Checkout Success", isPresented: $cartManager.checkoutSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your order has been placed!")
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { cartManager.errorMessage != nil },
            set: { _ in cartManager.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cartManager.errorMessage ?? "Unknown error")
        }
    }
}

// MARK: - Alerts

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @EnvironmentObject private var circuitState: HybridCircuitStateRepository
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text(LocalizationUtils.string("Alerts Title"))
                    .font(RacingFont.header(30))
                    .foregroundColor(.white)
                    .padding(.top)

                // Live circuit status banner
                HStack {
                    Circle()
                        .fill(liveTrackStatus.color)
                        .frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizationUtils.string(liveTrackStatus.titleKey))
                            .font(RacingFont.subheader())
                            .foregroundColor(.white)
                        Text(circuitState.message.isEmpty ? LocalizationUtils.string(liveTrackStatus.messageKey) : circuitState.message)
                            .font(RacingFont.body(12))
                            .foregroundColor(RacingColors.silver)
                        if !circuitState.updatedAt.isEmpty {
                            Text(circuitState.updatedAt)
                                .font(RacingFont.body(11))
                                .foregroundColor(RacingColors.silver.opacity(0.8))
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(
                    (liveTrackStatus == .sc || liveTrackStatus == .vsc) ? Color.orange.opacity(0.3) : RacingColors.cardBackground
                )
                .cornerRadius(12)
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.alerts) { alert in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(color(for: alert.priority))
                                    Text(alert.title)
                                        .font(RacingFont.subheader())
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(viewModel.timeAgo(for: alert.timestamp))
                                        .font(RacingFont.body(12))
                                        .foregroundColor(RacingColors.silver)
                                }
                                Text(alert.message)
                                    .font(RacingFont.body())
                                    .foregroundColor(RacingColors.silver)
                            }
                            .padding()
                            .background(RacingColors.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(color(for: alert.priority), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                viewModel.fetchAlerts()
            }
        }
    }
    
    func color(for priority: AlertPriority) -> Color {
        switch priority {
        case .high: return RacingColors.red
        case .medium: return .orange
        case .low: return .green
        }
    }

    private var liveTrackStatus: TrackStatus {
        circuitState.resolvedTrackStatus()
    }
}

// MARK: - Seat Setup

// MARK: - Settings

struct LegacySettingsView: View {
    @State private var grandstand: String = UserPreferences.shared.grandstand ?? ""
    @State private var zone: String = UserPreferences.shared.zone ?? ""
    @State private var row: String = UserPreferences.shared.row ?? ""
    @State private var seat: String = UserPreferences.shared.seatNumber ?? ""
    
    @State private var selectedLanguage: String = UserPreferences.shared.languageCode
    @State private var selectedTheme: UserPreferences.AppTheme = UserPreferences.shared.theme
    
    let languages = [("English", "en"), ("Español", "es"), ("Català", "ca")]
    
    // For Settings, Form is very convenient. We can try to keep it but apply dark theme?
    // SwiftUI Forms can be stubborn. Let's wrap in ZStack and use .scrollContentBackground(.hidden) if iOS 16, else just standard form.
    // For now, let's stick to standard navigation view for Settings as it's a utility screen, but ensure colors are okay.
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizationUtils.string("General"))) {
                    Picker(LocalizationUtils.string("Language"), selection: $selectedLanguage) {
                        ForEach(languages, id: \.1) { language in
                            Text(language.0).tag(language.1)
                        }
                    }
                    .onChange(of: selectedLanguage) {
                        UserPreferences.shared.languageCode = selectedLanguage
                    }
                    
                    Picker(LocalizationUtils.string("Appearance"), selection: $selectedTheme) {
                        Text("System").tag(UserPreferences.AppTheme.system)
                        Text("Light").tag(UserPreferences.AppTheme.light)
                        Text("Dark").tag(UserPreferences.AppTheme.dark)
                    }
                    .onChange(of: selectedTheme) {
                        UserPreferences.shared.theme = selectedTheme
                    }
                }
                
                Section(header: Text(LocalizationUtils.string("My Seat Location"))) {
                    TextField(LocalizationUtils.string("Grandstand"), text: $grandstand)
                    TextField(LocalizationUtils.string("Zone"), text: $zone)
                }
                
                Section(header: Text(LocalizationUtils.string("Seat Details"))) {
                    TextField(LocalizationUtils.string("Row"), text: $row)
                    TextField(LocalizationUtils.string("Seat Number"), text: $seat)
                }
                
                Button(action: {
                    UserPreferences.shared.grandstand = grandstand
                    UserPreferences.shared.zone = zone
                    UserPreferences.shared.row = row
                    UserPreferences.shared.seatNumber = seat
                }) {
                    Text(LocalizationUtils.string("Save Seat Config"))
                        .foregroundColor(RacingColors.red)
                }
                
                Section(header: Text("Race Control (Admin)")) {
                    NavigationLink(destination: CircuitControlView()) {
                         Text("Circuit Status & Messaging")
                    }
                }
            }
            .navigationTitle(LocalizationUtils.string("Settings"))
        }
        // Force simple dark style if preferred scheme is dark, handled by ContentView
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/SettingsView.swift`

```swift
import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Language Section
                    settingsSection(title: LocalizationUtils.string("Language")) {
                        languagePicker
                    }
                    
                    // Appearance Section
                    settingsSection(title: LocalizationUtils.string("Appearance")) {
                        themePicker
                    }
                    
                    // Accessibility Section
                    settingsSection(title: "Accessibility") {
                        accessibilityToggles
                    }
                    
                    // Notifications Section
                    settingsSection(title: LocalizationUtils.string("Notifications")) {
                        notificationsToggle
                    }
                    
                    // Account Section
                    settingsSection(title: "Account") {
                        accountButtons
                    }
                    
                    // App Info
                    appInfoSection
                }
                .padding()
            }
        }
        .confirmationDialog(LocalizationUtils.string("Sign Out?"), isPresented: $showLogoutConfirmation) {
            Button(LocalizationUtils.string("Sign Out"), role: .destructive) {
                viewModel.logout()
                dismiss()
            }
            Button(LocalizationUtils.string("Cancel"), role: .cancel) {}
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(LocalizationUtils.string("Settings"))
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 24)
        }
    }
    
    // MARK: - Section Builder
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.orange)
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Language Picker
    
    private var languagePicker: some View {
        VStack(spacing: 0) {
            ForEach(SettingsViewModel.Language.allCases, id: \.self) { language in
                Button {
                    viewModel.setLanguage(language)
                } label: {
                    HStack {
                        Image(systemName: language.flag)
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(language.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.language == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.12))
                }
                
                if language != SettingsViewModel.Language.allCases.last {
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
        }
        .cornerRadius(12)
    }
    
    // MARK: - Theme Picker
    
    private var themePicker: some View {
        VStack(spacing: 0) {
            ForEach(SettingsViewModel.Theme.allCases, id: \.self) { theme in
                Button {
                    viewModel.setTheme(theme)
                } label: {
                    HStack {
                        Image(systemName: theme.icon)
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        Text(theme.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.theme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.12))
                }
                
                if theme != SettingsViewModel.Theme.allCases.last {
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
        }
        .cornerRadius(12)
    }
    
    // MARK: - Accessibility Toggles
    
    private var accessibilityToggles: some View {
        VStack(spacing: 0) {
            settingsToggle(
                icon: "textformat.size",
                title: "Texto grande",
                isOn: $viewModel.largeText
            )
            
            Divider().background(Color.gray.opacity(0.3))
            
            settingsToggle(
                icon: "circle.lefthalf.filled",
                title: "Alto contraste",
                isOn: $viewModel.highContrast
            )
        }
        .cornerRadius(12)
    }
    
    // MARK: - Notifications Toggle
    
    private var notificationsToggle: some View {
        settingsToggle(
            icon: "bell.fill",
            title: LocalizationUtils.string("Push Notifications"),
            isOn: $viewModel.notificationsEnabled
        )
        .cornerRadius(12)
    }
    
    private func settingsToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.orange)
        }
        .padding()
        .background(Color(white: 0.12))
    }
    
    // MARK: - Account Buttons
    
    private var accountButtons: some View {
        VStack(spacing: 0) {
            Button {
                // Navigate to seat setup
            } label: {
                HStack {
                    Image(systemName: "ticket")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text(LocalizationUtils.string("Configure my seat"))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(white: 0.12))
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            Button {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    Text(LocalizationUtils.string("Sign Out"))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color(white: 0.12))
            }
        }
        .cornerRadius(12)
    }
    
    // MARK: - App Info
    
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("GeoRacing")
                .font(.headline)
                .foregroundColor(.white)
            Text("Versión \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundColor(.gray)
            Text("© 2026 GeoRacing")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.top, 24)
    }
}

// MARK: - Settings ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Types
    
    enum Language: String, CaseIterable {
        case spanish = "es"
        case english = "en"
        case catalan = "ca"
        
        var displayName: String {
            switch self {
            case .spanish: return "Español"
            case .english: return "English"
            case .catalan: return "Català"
            }
        }
        
        var flag: String {
            switch self {
            case .spanish: return "s.circle.fill"
            case .english: return "e.circle.fill"
            case .catalan: return "c.circle.fill"
            }
        }
    }
    
    enum Theme: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var displayName: String {
            switch self {
            case .system: return "Automático"
            case .light: return "Claro"
            case .dark: return "Oscuro"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published var language: Language
    @Published var theme: Theme
    @Published var largeText: Bool
    @Published var highContrast: Bool
    @Published var notificationsEnabled: Bool
    
    // MARK: - Private
    
    private let defaults = UserDefaults.standard
    private let authService = AuthService.shared
    
    // MARK: - Keys
    
    private enum Keys {
        static let language = "settings.language"
        static let theme = "settings.theme"
        static let largeText = "settings.largeText"
        static let highContrast = "settings.highContrast"
        static let notifications = "settings.notifications"
    }
    
    // MARK: - Initialization
    
    init() {
        self.language = Language(rawValue: defaults.string(forKey: Keys.language) ?? "es") ?? .spanish
        self.theme = Theme(rawValue: defaults.string(forKey: Keys.theme) ?? "system") ?? .system
        self.largeText = defaults.bool(forKey: Keys.largeText)
        self.highContrast = defaults.bool(forKey: Keys.highContrast)
        self.notificationsEnabled = defaults.bool(forKey: Keys.notifications)
    }
    
    // MARK: - Actions
    
    func setLanguage(_ language: Language) {
        self.language = language
        defaults.set(language.rawValue, forKey: Keys.language)
    }
    
    func setTheme(_ theme: Theme) {
        self.theme = theme
        defaults.set(theme.rawValue, forKey: Keys.theme)
    }
    
    func logout() {
        authService.signOut()
    }
}

#Preview {
    SettingsView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/Shared/FeaturePlaceholderView.swift`

```swift
import SwiftUI

struct FeaturePlaceholderView: View {
    let feature: Feature
    
    @State private var isSimulating = false
    @State private var demoLevel = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: feature.icon)
                            .font(.system(size: 40))
                            .foregroundColor(feature.category.color)
                        Spacer()
                        Badge(text: feature.status.rawValue, color: feature.status.color)
                    }
                    
                    Text(feature.title)
                        .font(RacingFont.header(32))
                        .foregroundColor(.white)
                    
                    Text(feature.subtitle)
                        .font(RacingFont.subheader())
                        .foregroundColor(.gray)
                }
                .padding()
                .background(RacingColors.cardBackground)
                .cornerRadius(16)
                
                // What it does
                VStack(alignment: .leading, spacing: 12) {
                    Text("Funcionalidad")
                        .font(RacingFont.header(20))
                        .foregroundColor(.white)
                    
                    Text("Esta función permite \(feature.subtitle.lowercased()) interactuando con los servicios de GeoRacing.")
                        .font(RacingFont.body())
                        .foregroundColor(RacingColors.silver)
                }
                .padding(.horizontal)
                
                // Next Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("Próximos Pasos (WIP)")
                        .font(RacingFont.header(20))
                        .foregroundColor(.white)
                    
                    ForEach(feature.nextSteps, id: \.self) { step in
                        HStack(alignment: .top) {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                            Text(step)
                                .font(RacingFont.body())
                                .foregroundColor(RacingColors.silver)
                        }
                    }
                    
                    if feature.nextSteps.isEmpty {
                        Text("• Implementación pendiente de especificación.")
                            .font(RacingFont.body())
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Simulation Control
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(LocalizationUtils.string("Simulation Environment"))
                            .font(RacingFont.header(20))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "testtube.2")
                            .foregroundColor(.orange)
                    }
                    
                    Toggle("Simular Activo", isOn: $isSimulating)
                        .toggleStyle(SwitchToggleStyle(tint: feature.category.color))
                        .foregroundColor(.white)
                    
                    if isSimulating {
                        Picker("Nivel Demo", selection: $demoLevel) {
                            Text("Mock Básico").tag(0)
                            Text("Interacción Real").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Button(action: runDemo) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Ejecutar Demo Local")
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(feature.category.color.opacity(0.8))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Tech Data
                VStack(alignment: .leading, spacing: 4) {
                    Text("ID: \(feature.id)")
                    Text("Categoria: \(feature.category.rawValue)")
                    Text("Prioridad: \(feature.priority)")
                    Text("Última actualización: Ahora")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
            }
            .padding(.bottom, 40)
        }
        .background(RacingColors.darkBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Actions
    func runDemo() {
        Logger.debug("[Feature] Running demo for \(feature.id) at level \(demoLevel)")
        // Haptic feedback could go here
    }
}

// Helper Badge
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color, lineWidth: 1)
            )
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/SideMenuView.swift`

```swift
import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: TabIdentifier
    
    // Callbacks for non-tab actions
    var onOverview: () -> Void
    var onSelectFeature: (Feature) -> Void
    
    // Legacy callbacks kept for compatibility / if redirected
    var onSocial: () -> Void
    var onReport: () -> Void
    var onCircuitControl: () -> Void
    
    var body: some View {
        ZStack {
            if isShowing {
                // Dimmed background
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isShowing = false }
                    }
                
                // Menu Content
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading) {
                            Image(systemName: "flag.checkered")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                            Text("GeoRacing")
                                .font(RacingFont.header(24))
                                .foregroundColor(.white)
                            Text("Driver Menu")
                                .font(RacingFont.body())
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 50)
                        .padding(.horizontal)
                        
                        Divider().background(Color.gray)
                        
                        // Menu Items
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                
                                // Navigation Items (Tabs)
                                MenuRow(icon: "house.fill", text: "Home", action: { selectTab(.home) })
                                MenuRow(icon: "map.fill", text: "Circuit Map", action: { selectTab(.map) })
                                MenuRow(icon: "bell.fill", text: "Alerts", action: { selectTab(.alerts) })
                                MenuRow(icon: "cart.fill", text: "Shop", action: { selectTab(.shop) })
                                MenuRow(icon: "gear", text: "Settings", action: { selectTab(.seat) })
                                
                                Divider().background(Color.gray).padding(.vertical, 10)
                                
                                // Quick Access Items
                                Text(LocalizationUtils.string("Quick Access"))
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                
                                MenuRow(icon: "bag.fill", text: LocalizationUtils.string("My Orders"), action: {
                                    closeAndRun { onSelectFeature(Feature(id: "commerce.my_orders", title: LocalizationUtils.string("My Orders"), subtitle: LocalizationUtils.string("Purchase History"), category: .fan, priority: 1, status: .complete, icon: "bag.fill", nextSteps: [])) }
                                })
                                MenuRow(icon: "mappin.and.ellipse", text: LocalizationUtils.string("POI List"), action: {
                                    closeAndRun { onSelectFeature(Feature(id: "core.poi_list", title: LocalizationUtils.string("POI List"), subtitle: LocalizationUtils.string("Points of Interest"), category: .core, priority: 1, status: .complete, icon: "mappin.and.ellipse", nextSteps: [])) }
                                })
                                MenuRow(icon: "ticket.fill", text: LocalizationUtils.string("My Seat"), action: {
                                    closeAndRun { onSelectFeature(Feature(id: "seat.setup", title: LocalizationUtils.string("My Seat"), subtitle: LocalizationUtils.string("Seat Setup"), category: .fan, priority: 1, status: .complete, icon: "ticket.fill", nextSteps: [])) }
                                })
                                MenuRow(icon: "chart.bar.fill", text: "Roadmap", action: {
                                    closeAndRun { onSelectFeature(Feature(id: "app.roadmap", title: "Roadmap", subtitle: LocalizationUtils.string("Project Progress"), category: .advanced, priority: 1, status: .complete, icon: "chart.bar.fill", nextSteps: [])) }
                                })
                                MenuRow(icon: "person.badge.key.fill", text: LocalizationUtils.string("Staff Mode"), action: {
                                    closeAndRun { onSelectFeature(Feature(id: "staff.mode", title: LocalizationUtils.string("Staff Mode"), subtitle: LocalizationUtils.string("Control Panel"), category: .staff, priority: 1, status: .complete, icon: "person.badge.key.fill", audience: .staffOnly, nextSteps: [])) }
                                })
                                
                                Divider().background(Color.gray).padding(.vertical, 10)
                                
                                 Divider().background(Color.gray).padding(.vertical, 10)
                                
                                 // -- FUNCIONES GEORACING --
                                 Text(LocalizationUtils.string("GeoRacing Features"))
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                 
                                 // Quick Access: Overview
                                 MenuRow(icon: "square.grid.2x2.fill", text: LocalizationUtils.string("Overview"), action: {
                                    closeAndRun(onOverview)
                                 })
                                 
                                 // Categories
                                 ForEach(FeatureCategory.allCases) { category in
                                     let features = FeatureRegistry.shared.features(for: category)
                                     if !features.isEmpty {
                                         DisclosureGroup(
                                             content: {
                                                 ForEach(features) { feature in
                                                     Button(action: { closeAndRun { onSelectFeature(feature) } }) {
                                                         HStack {
                                                             Image(systemName: feature.icon)
                                                                 .frame(width: 20)
                                                             Text(feature.title)
                                                                 .font(RacingFont.body(14))
                                                             Spacer()
                                                             if feature.status != .complete {
                                                                 Circle()
                                                                     .fill(feature.status.color)
                                                                     .frame(width: 6, height: 6)
                                                             }
                                                         }
                                                         .foregroundColor(.white)
                                                         .padding(.vertical, 8)
                                                         .padding(.leading, 20)
                                                     }
                                                 }
                                             },
                                             label: {
                                                 HStack {
                                                     Image(systemName: category.icon)
                                                         .foregroundColor(category.color)
                                                         .frame(width: 20)
                                                     Text(category.rawValue)
                                                         .font(RacingFont.subheader())
                                                         .foregroundColor(.white)
                                                     Spacer()
                                                     Text("\(FeatureRegistry.shared.completedCount(for: category))/\(features.count)")
                                                         .font(.caption)
                                                         .foregroundColor(.gray)
                                                 }
                                                 .padding(.vertical, 4)
                                             }
                                         )
                                         .accentColor(.gray)
                                         .padding(.horizontal)
                                     }
                                 }
                                 
                                 Divider().background(Color.gray).padding(.vertical, 10)
                                 
                                 // -- LEGACY ACTIONS (Kept for compatibility if needed, but redundant now usually) --
                                 /*
                                 MenuRow(icon: "person.3.fill", text: "Social / Group", action: {
                                     closeAndRun(onSocial)
                                 })
                                 */
                            }
                        }
                        
                        Spacer()
                        
                        // Footer
                        Text("v1.0.0 (Parity Build)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                    }
                    .frame(width: 280)
                    .background(RacingColors.darkBackground)
                    .offset(x: isShowing ? 0 : -280) // Slide animation logic handled by parent usually, but here helps
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        // No animation modifier here, handled by parent ZStack insertion or state change
    }
    
    private func selectTab(_ tab: TabIdentifier) {
        selectedTab = tab
        withAnimation { isShowing = false }
    }
    
    private func closeAndRun(_ action: @escaping () -> Void) {
        withAnimation { isShowing = false }
        // Delay slightly to allow menu to close?
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
        }
    }
}

struct MenuRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(RacingColors.silver)
                Text(text)
                    .font(RacingFont.subheader())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .accessibilityLabel(text)
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/SocialView.swift`

```swift
import SwiftUI

struct SocialView: View {
    @StateObject private var viewModel = SocialViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            RacingColors.darkBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text(LocalizationUtils.string("Social Group"))
                        .font(RacingFont.header(28))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(RacingColors.silver)
                    }
                }
                .padding()
                
                if viewModel.isJoined {
                    // Group Dashboard
                    VStack(spacing: 20) {
                        Text("You are in a group!")
                            .font(RacingFont.subheader())
                            .foregroundColor(.green)
                        
                        if let qr = viewModel.qrCodeImage {
                            Image(uiImage: qr)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            Text("Share this QR code with friends")
                                .font(RacingFont.body())
                                .foregroundColor(RacingColors.silver)
                        } else {
                            // If joined but no QR (joined via scan), show info
                            Text("Group Active")
                                .font(RacingFont.header(20))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: viewModel.leaveGroup) {
                            Text("Leave Group")
                        }
                        .racingButton(color: RacingColors.red)
                    }
                } else {
                    // Join / Create Options
                    VStack(spacing: 30) {
                        Button(action: viewModel.createGroup) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                Text("Create Group")
                            }
                        }
                        .racingButton(color: .blue)
                        
                        Divider().background(Color.white)
                        
                        Text("OR")
                            .font(RacingFont.subheader())
                            .foregroundColor(RacingColors.silver)
                        
                        Button(action: {
                            // Simulate Scan for Dev
                            // In real app: Open Camera View
                            viewModel.joinGroup(url: "georacing://join?groupId=simulated_scan")
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Scan QR Code (Sim)")
                            }
                        }
                        .racingButton(color: .green)
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .alert("Alert",
               isPresented: Binding<Bool>(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
               ),
               actions: {
                Button("OK", role: .cancel) { viewModel.alertMessage = nil }
               },
               message: {
                Text(viewModel.alertMessage ?? "")
               })
    }
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/StaffModeView.swift`

```swift
import SwiftUI

struct StaffModeView: View {
    @State private var pinCode = ""
    @State private var showError = false
    @State private var isAuthenticated = false
    @Environment(\.dismiss) private var dismiss
    
    private let correctPin = "1234" // In production, this should be from secure storage
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isAuthenticated {
                StaffControlView()
            } else {
                pinEntryView
            }
        }
    }
    
    // MARK: - PIN Entry View
    
    private var pinEntryView: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding()
            
            Spacer()
            
            // Lock Icon
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(LocalizationUtils.string("Staff Mode"))
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text(LocalizationUtils.string("Enter access PIN"))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // PIN Display
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pinCode.count ? Color.orange : Color(white: 0.2))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.vertical)
            .shake(showError)
            
            // Keypad
            VStack(spacing: 12) {
                ForEach(0..<3) { row in
                    HStack(spacing: 12) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            keypadButton(String(number))
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    // Empty space
                    Color.clear
                        .frame(width: 80, height: 80)
                    
                    keypadButton("0")
                    
                    // Delete
                    Button {
                        if !pinCode.isEmpty {
                            pinCode.removeLast()
                        }
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color(white: 0.15))
                            .cornerRadius(40)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func keypadButton(_ number: String) -> some View {
        Button {
            if pinCode.count < 4 {
                pinCode += number
                
                if pinCode.count == 4 {
                    verifyPin()
                }
            }
        } label: {
            Text(number)
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color(white: 0.15))
                .cornerRadius(40)
        }
    }
    
    private func verifyPin() {
        if pinCode == correctPin {
            withAnimation {
                isAuthenticated = true
            }
        } else {
            showError = true
            pinCode = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showError = false
            }
        }
    }
}

// MARK: - Staff Control View

struct StaffControlView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Segmented Control
            Picker(LocalizationUtils.string("Section"), selection: $selectedSection) {
                Text(LocalizationUtils.string("Alerts")).tag(0)
                Text("Beacons").tag(1)
                Text(LocalizationUtils.string("Status")).tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedSection) {
                alertsSection.tag(0)
                beaconsSection.tag(1)
                statusSection.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack {
                Text(LocalizationUtils.string("Control Panel"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("STAFF MODE")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Color.clear.frame(width: 24)
        }
        .padding()
        .background(Color(white: 0.08))
    }
    
    // MARK: - Alerts Section
    
    private var alertsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(LocalizationUtils.string("Send Alert"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                alertButton(
                    icon: "exclamationmark.triangle.fill",
                    title: LocalizationUtils.string("General Alert"),
                    description: LocalizationUtils.string("Send message to all users"),
                    color: .yellow
                )
                
                alertButton(
                    icon: "flame.fill",
                    title: LocalizationUtils.string("Emergency"),
                    description: LocalizationUtils.string("Activate emergency protocol"),
                    color: .red
                )
                
                alertButton(
                    icon: "megaphone.fill",
                    title: LocalizationUtils.string("Announcement"),
                    description: LocalizationUtils.string("Send general information"),
                    color: .blue
                )
            }
            .padding()
        }
    }
    
    private func alertButton(icon: String, title: String, description: String, color: Color) -> some View {
        Button {
            // Send alert action
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 50)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(white: 0.12))
            .cornerRadius(12)
        }
        .accessibilityLabel("\(title): \(description)")
    }
    
    private var beaconsSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(LocalizationUtils.string("Beacon Control"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach([LocalizationUtils.string("Main Entrance"), LocalizationUtils.string("Grandstand A"), LocalizationUtils.string("Grandstand B"), "Paddock", "Pit Lane"], id: \.self) { beacon in
                    beaconRow(name: beacon)
                }
            }
            .padding()
        }
    }
    
    private func beaconRow(name: String) -> some View {
        HStack {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
            
            Text(name)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: .constant(true))
                .tint(.orange)
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(LocalizationUtils.string("Circuit Status"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                statusCard(
                    title: LocalizationUtils.string("Current Status"),
                    value: LocalizationUtils.string("GREEN FLAG"),
                    icon: "flag.fill",
                    color: .green
                )
                
                statusCard(
                    title: LocalizationUtils.string("Active Users"),
                    value: "1,234",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                statusCard(
                    title: LocalizationUtils.string("Pending Alerts"),
                    value: "3",
                    icon: "bell.badge.fill",
                    color: .orange
                )
                
                statusCard(
                    title: LocalizationUtils.string("Active Beacons"),
                    value: "12/15",
                    icon: "antenna.radiowaves.left.and.right",
                    color: .purple
                )
            }
            .padding()
        }
    }
    
    private func statusCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Shake Effect

extension View {
    func shake(_ trigger: Bool) -> some View {
        modifier(ShakeEffect(trigger: trigger))
    }
}

struct ShakeEffect: ViewModifier {
    let trigger: Bool
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.default.repeatCount(4, autoreverses: true).speed(4)) {
                        offset = 10
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = 0
                    }
                }
            }
    }
}

#Preview {
    StaffModeView()
}

```

---

## `iOS_App/GeoRacing/Presentation/Views/TeamSelectorView.swift`

```swift
import SwiftUI

// MARK: - Team Selector View

/// Full-screen team picker with logos, organized by championship.
struct TeamSelectorView: View {
    @ObservedObject var viewModel: FanZoneViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                RacingColors.darkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Championship Picker
                        championshipPicker
                        
                        // Teams Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.availableTeams) { team in
                                TeamCard(
                                    team: team,
                                    isSelected: viewModel.selectedTeam?.id == team.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            viewModel.selectTeam(team)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(LocalizationUtils.string("Choose Your Team"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationUtils.string("Done")) {
                        dismiss()
                    }
                    .foregroundColor(viewModel.teamColor)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Championship Picker
    
    private var championshipPicker: some View {
        HStack(spacing: 0) {
            ForEach(Championship.allCases) { champ in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedChampionship = champ
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: champ.icon)
                            .font(.title2)
                        Text(champ.displayName)
                            .font(RacingFont.subheader(14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedChampionship == champ
                                  ? viewModel.teamColor.opacity(0.3)
                                  : Color.clear)
                    )
                    .foregroundColor(viewModel.selectedChampionship == champ
                                     ? viewModel.teamColor
                                     : RacingColors.silver)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(RacingColors.cardBackground)
        )
        .padding(.horizontal)
    }
}

// MARK: - Team Card

struct TeamCard: View {
    let team: RacingTeam
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Team Logo
                TeamLogoView(team: team, size: 60)
                
                // Team Name
                Text(team.name)
                    .font(RacingFont.body(14).bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                // Short Name Badge
                Text(team.shortName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(team.primarySwiftColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(team.primarySwiftColor.opacity(0.15))
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(RacingColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? team.primarySwiftColor : team.primarySwiftColor.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(color: isSelected ? team.primarySwiftColor.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(team.name), \(isSelected ? "selected" : "not selected")")
    }
}

```

---

## `iOS_App/Podfile`

```
platform :ios, '16.0'
use_frameworks!

target 'GeoRacing' do
  # Pods for GeoRacing
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'GoogleSignIn'
end

```

