// Ejemplo de código para BeaconDisplay (Windows - C# / JavaScript / Python)
// Este código debe ejecutarse en cada baliza física

// OPCIÓN 1: JavaScript/TypeScript (Electron o Node.js)
import { initializeApp } from "firebase/app";
import { getFirestore, doc, onSnapshot, setDoc, updateDoc, serverTimestamp } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyACSJmNU5y01YaTBneqHlDannKatrSs1XA",
  authDomain: "panel-de-control-georacing.firebaseapp.com",
  projectId: "panel-de-control-georacing",
  storageBucket: "panel-de-control-georacing.firebasestorage.app",
  messagingSenderId: "839966103516",
  appId: "1:839966103516:web:da41a4a9120806840ee119"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// ID único de esta baliza (puede ser MAC address, hostname, etc.)
const BEACON_ID = "BALIZA-" + getMachineId(); // Implementar getMachineId()

class BeaconDisplay {
  constructor(beaconId) {
    this.beaconId = beaconId;
    this.beaconRef = doc(db, "beacons", beaconId);
    this.heartbeatInterval = null;
  }

  async initialize() {
    // 1. Auto-registrar la baliza si no existe
    await this.registerBeacon();

    // 2. Iniciar heartbeat
    this.startHeartbeat();

    // 3. Suscribirse a cambios de configuración
    this.subscribeToConfig();
  }

  async registerBeacon() {
    try {
      // Intentar crear el documento con datos mínimos
      await setDoc(this.beaconRef, {
        beaconId: this.beaconId,
        lastSeen: serverTimestamp(),
        online: true,
        configured: false,
        firstSeen: serverTimestamp()
      }, { merge: true });
      
      console.log(`✅ Baliza ${this.beaconId} registrada`);
    } catch (error) {
      console.error("Error registrando baliza:", error);
    }
  }

  startHeartbeat() {
    // Enviar heartbeat cada 30 segundos
    this.heartbeatInterval = setInterval(async () => {
      try {
        await updateDoc(this.beaconRef, {
          lastSeen: serverTimestamp(),
          online: true
        });
        console.log("💓 Heartbeat enviado");
      } catch (error) {
        console.error("Error en heartbeat:", error);
      }
    }, 30000);

    // Enviar heartbeat inmediato
    updateDoc(this.beaconRef, {
      lastSeen: serverTimestamp(),
      online: true
    });
  }

  subscribeToConfig() {
    // Escuchar cambios en tiempo real
    onSnapshot(this.beaconRef, (doc) => {
      if (doc.exists()) {
        const config = doc.data();
        console.log("📡 Configuración actualizada:", config);
        
        // Actualizar UI según configuración
        this.updateDisplay(config);
      }
    });
  }

  updateDisplay(config) {
    // Aquí va la lógica para actualizar la pantalla
    if (!config.configured) {
      this.showWaitingScreen();
      return;
    }

    switch (config.mode) {
      case "NORMAL":
        this.showNormalMode(config);
        break;
      case "CONGESTION":
        this.showCongestionMode(config);
        break;
      case "EMERGENCY":
        this.showEmergencyMode(config);
        break;
      case "EVACUATION":
        this.showEvacuationMode(config);
        break;
      case "MAINTENANCE":
        this.showMaintenanceMode();
        break;
    }
  }

  showWaitingScreen() {
    // Mostrar pantalla de espera mientras se configura desde el panel
    console.log("⏳ Esperando configuración desde el panel...");
    // Actualizar UI: mostrar "EN CONFIGURACIÓN" o similar
  }

  showNormalMode(config) {
    // Mostrar mensaje normal con flecha
    console.log(`📺 Modo NORMAL: ${config.message}`);
    // Actualizar UI con:
    // - Fondo: config.color
    // - Mensaje: config.message
    // - Flecha: config.arrow
    // - Brillo: config.brightness
  }

  showCongestionMode(config) {
    console.log("🚫 Modo CONGESTIÓN");
    // Fondo naranja, mensaje "AFORO COMPLETO"
  }

  showEmergencyMode(config) {
    console.log("⚠️ Modo EMERGENCIA");
    // Fondo naranja fuerte, mensaje urgente
  }

  showEvacuationMode(config) {
    console.log("🚨 Modo EVACUACIÓN");
    // Fondo rojo, mensaje según idioma
    const messages = {
      ES: "EVACUACIÓN EN CURSO. SIGA LAS FLECHAS.",
      CAT: "EVACUACIÓ EN CURS. SEGUEIX LES FLETXES.",
      EN: "EVACUATION IN PROGRESS. FOLLOW THE ARROWS."
    };
    // Mostrar mensaje y config.evacuationExit
  }

  showMaintenanceMode() {
    console.log("🔧 Modo MANTENIMIENTO");
    // Mostrar solo la hora
  }

  shutdown() {
    // Limpiar al cerrar
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }
    
    // Marcar como offline
    updateDoc(this.beaconRef, {
      online: false
    });
  }
}

// Uso
const beacon = new BeaconDisplay(BEACON_ID);
beacon.initialize();

// Al cerrar la aplicación
window.addEventListener('beforeunload', () => {
  beacon.shutdown();
});


// OPCIÓN 2: Python (para Raspberry Pi o similar)
/*
import firebase_admin
from firebase_admin import credentials, firestore
import time
import threading
import socket

# Inicializar Firebase
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# ID único de la baliza
BEACON_ID = f"BALIZA-{socket.gethostname()}"

class BeaconDisplay:
    def __init__(self, beacon_id):
        self.beacon_id = beacon_id
        self.beacon_ref = db.collection('beacons').document(beacon_id)
        self.heartbeat_thread = None
        
    def register_beacon(self):
        self.beacon_ref.set({
            'beaconId': self.beacon_id,
            'lastSeen': firestore.SERVER_TIMESTAMP,
            'online': True,
            'configured': False,
            'firstSeen': firestore.SERVER_TIMESTAMP
        }, merge=True)
        
    def heartbeat(self):
        while True:
            self.beacon_ref.update({
                'lastSeen': firestore.SERVER_TIMESTAMP,
                'online': True
            })
            time.sleep(30)
            
    def start_heartbeat(self):
        self.heartbeat_thread = threading.Thread(target=self.heartbeat, daemon=True)
        self.heartbeat_thread.start()
        
    def listen_config(self):
        def on_snapshot(doc_snapshot, changes, read_time):
            for doc in doc_snapshot:
                config = doc.to_dict()
                self.update_display(config)
                
        self.beacon_ref.on_snapshot(on_snapshot)
        
    def update_display(self, config):
        # Actualizar pantalla según configuración
        pass
        
beacon = BeaconDisplay(BEACON_ID)
beacon.register_beacon()
beacon.start_heartbeat()
beacon.listen_config()
*/
