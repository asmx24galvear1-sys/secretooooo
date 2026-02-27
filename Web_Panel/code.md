# Web_Panel — Todo el Código Fuente

Este archivo contiene todos los archivos de código fuente de la carpeta `Web_Panel/` concatenados.

---

## `Web_Panel/src/App.tsx`

```tsx
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { ToastProvider } from "./context/ToastContext";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { Login } from "./pages/Login";
import { ZonesMap } from "./pages/ZonesMap";
import { Routes as RoutesPage } from "./pages/Routes";
import { Dashboard } from "./pages/Dashboard";
import { Beacons } from "./pages/Beacons";
import { Statistics } from "./pages/Statistics";
import { BeaconDetail } from "./pages/BeaconDetail";
import { Emergencies } from "./pages/Emergencies";
import { Incidents } from "./pages/Incidents";
import { CircuitState } from "./pages/CircuitState";
import { Logs } from "./pages/Logs";
import { Config } from "./pages/Config";
import OrdersPage from "./pages/OrdersPage";
import ProductsPage from "./pages/ProductsPage";
import FoodStandsPage from "./pages/FoodStandsPage";
import NewsPage from "./pages/NewsPage";
import UsersPage from "./pages/UsersPage";
import "./index.css";

function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />
            <Route
              path="/users"
              element={
                <ProtectedRoute>
                  <UsersPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/beacons"
              element={
                <ProtectedRoute>
                  <Beacons />
                </ProtectedRoute>
              }
            />
            <Route
              path="/beacons/:beaconId"
              element={
                <ProtectedRoute>
                  <BeaconDetail />
                </ProtectedRoute>
              }
            />
            <Route
              path="/incidents"
              element={
                <ProtectedRoute>
                  <Incidents />
                </ProtectedRoute>
              }
            />
            <Route
              path="/circuit-state"
              element={
                <ProtectedRoute>
                  <CircuitState />
                </ProtectedRoute>
              }
            />
            <Route
              path="/logs"
              element={
                <ProtectedRoute>
                  <Logs />
                </ProtectedRoute>
              }
            />
            <Route
              path="/zones"
              element={
                <ProtectedRoute>
                  <ZonesMap />
                </ProtectedRoute>
              }
            />
            <Route
              path="/routes"
              element={
                <ProtectedRoute>
                  <RoutesPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/statistics"
              element={
                <ProtectedRoute>
                  <Statistics />
                </ProtectedRoute>
              }
            />
            <Route
              path="/emergencies"
              element={
                <ProtectedRoute>
                  <Emergencies />
                </ProtectedRoute>
              }
            />
            <Route
              path="/config"
              element={
                <ProtectedRoute>
                  <Config />
                </ProtectedRoute>
              }
            />
            <Route
              path="/orders"
              element={
                <ProtectedRoute>
                  <OrdersPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/products"
              element={
                <ProtectedRoute>
                  <ProductsPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/food-stands"
              element={
                <ProtectedRoute>
                  <FoodStandsPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/news"
              element={
                <ProtectedRoute>
                  <NewsPage />
                </ProtectedRoute>
              }
            />
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}

export default App;

```

---

## `Web_Panel/src/beacon_renderer/LayoutEngine.ts`

```typescript

import { ArrowDirection, BeaconState, BeaconMode } from './types';

export class LayoutEngine {

    /**
     * Determines if the arrow should be visible based on state.
     */
    public shouldShowArrow(state: BeaconState): boolean {
        // Regla: Mostrar flecha siempre que haya una dirección definida, en CUALQUIER modo
        return state.arrowDirection !== ArrowDirection.NONE;
    }

    /**
     * Calculates the final rotation in degrees.
     * Rule: finalDirection = arrowDirection + orientation
     */
    public calculateArrowRotation(direction: ArrowDirection, physicalOrientation: number): number {
        const baseAngle = this.directionToDegrees(direction);

        // Sumamos la orientación física
        // (Asumiendo que orientation es rotación horaria en grados)
        let finalAngle = baseAngle + physicalOrientation;

        // Normalizar a 0-360
        finalAngle = finalAngle % 360;
        if (finalAngle < 0) finalAngle += 360;

        return finalAngle;
    }

    private directionToDegrees(direction: ArrowDirection): number {
        switch (direction) {
            case ArrowDirection.FORWARD:
            case ArrowDirection.UP: // Compat
                return 0;
            case ArrowDirection.FORWARD_RIGHT:
            case ArrowDirection.UP_RIGHT: // Compat
                return 45;
            case ArrowDirection.RIGHT:
                return 90;
            case ArrowDirection.BACKWARD_RIGHT:
            case ArrowDirection.DOWN_RIGHT: // Compat
                return 135;
            case ArrowDirection.BACKWARD:
            case ArrowDirection.DOWN: // Compat
                return 180;
            case ArrowDirection.BACKWARD_LEFT:
            case ArrowDirection.DOWN_LEFT: // Compat
                return 225;
            case ArrowDirection.LEFT:
                return 270;
            case ArrowDirection.FORWARD_LEFT:
            case ArrowDirection.UP_LEFT: // Compat
                return 315;
            default: return 0;
        }
    }

    public getArrowStyle(state: BeaconState, physicalOrientation: number) {
        if (!this.shouldShowArrow(state)) {
            return { display: 'none' };
        }

        const rotation = this.calculateArrowRotation(state.arrowDirection, physicalOrientation);

        return {
            display: 'block',
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: `translate(-50%, -50%) rotate(${rotation}deg)`,
            zIndex: 10, // Layering correcto
            width: '40vmin', // Responsivo
            height: '40vmin'
        };
    }
}

```

---

## `Web_Panel/src/beacon_renderer/RenderEngine.ts`

```typescript

import { LayoutEngine } from './LayoutEngine';
import { ArrowComponent } from './components/ArrowComponent';
import { BeaconState } from './types';

export class RenderEngine {
    private container: HTMLElement;
    private layoutEngine: LayoutEngine;
    private arrowComponent: ArrowComponent;
    private physicalOrientation: number = 0; // Configurable

    constructor(containerId: string, orientation: number = 0) {
        const el = document.getElementById(containerId);
        if (!el) throw new Error(`Container ${containerId} not found`);
        this.container = el;
        this.physicalOrientation = orientation;

        this.layoutEngine = new LayoutEngine();
        this.arrowComponent = new ArrowComponent();

        // Mount arrow
        this.container.appendChild(this.arrowComponent.getElement());
    }

    public render(state: BeaconState) {
        // 1. Calcular estilos/layout
        const arrowStyle = this.layoutEngine.getArrowStyle(state, this.physicalOrientation);
        const arrowEl = this.arrowComponent.getElement();

        // 2. Aplicar estilos
        Object.assign(arrowEl.style, arrowStyle);

        // 3. (Opcional) Debugging visual si no se ve
        if (state.mode === 'NORMAL' && arrowStyle.display === 'none') {
            console.warn('[RenderEngine] Arrow hidden in NORMAL mode. Check ArrowDirection.');
        }

        // 4. Otros elementos (texto, fondo) se manejarían aquí...
    }

    public setOrientation(deg: number) {
        this.physicalOrientation = deg;
    }
}

```

---

## `Web_Panel/src/beacon_renderer/components/ArrowComponent.ts`

```typescript

export class ArrowComponent {
    private element: HTMLElement;

    constructor() {
        this.element = document.createElement('div');
        this.element.className = 'beacon-arrow';
        // SVG de una flecha estándar
        this.element.innerHTML = `
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="12" y1="19" x2="12" y2="5"></line>
                <polyline points="5 12 12 5 19 12"></polyline>
            </svg>
        `;

        // Estilos base para asegurar visibilidad
        this.element.style.color = 'white'; // O el color que se pase
        this.element.style.position = 'absolute';
        this.element.style.transformOrigin = 'center center';
    }

    public getElement(): HTMLElement {
        return this.element;
    }

    public updateColor(color: string) {
        this.element.style.color = color;
    }
}

```

---

## `Web_Panel/src/beacon_renderer/types.ts`

```typescript

export enum BeaconMode {
    UNCONFIGURED = 'UNCONFIGURED',
    NORMAL = 'NORMAL',
    CONGESTION = 'CONGESTION',
    EMERGENCY = 'EMERGENCY',
    EVACUATION = 'EVACUATION',
    MAINTENANCE = 'MAINTENANCE'
}

export enum ArrowDirection {
    NONE = 'NONE',
    FORWARD = 'FORWARD',
    BACKWARD = 'BACKWARD',
    LEFT = 'LEFT',
    RIGHT = 'RIGHT',
    FORWARD_LEFT = 'FORWARD_LEFT',
    FORWARD_RIGHT = 'FORWARD_RIGHT',
    BACKWARD_LEFT = 'BACKWARD_LEFT',
    BACKWARD_RIGHT = 'BACKWARD_RIGHT',
    // Aliases for compatibility if needed, but UI will use FORWARD/BACKWARD
    UP = 'FORWARD',
    DOWN = 'BACKWARD',
    UP_LEFT = 'FORWARD_LEFT',
    UP_RIGHT = 'FORWARD_RIGHT',
    DOWN_LEFT = 'BACKWARD_LEFT',
    DOWN_RIGHT = 'BACKWARD_RIGHT'
}

export interface BeaconState {
    mode: BeaconMode;
    arrowDirection: ArrowDirection;
    message: string;
    // ...other props
}

export interface RenderConfig {
    orientation: number; // 0, 90, 180, 270
    width: number;
    height: number;
}

```

---

## `Web_Panel/src/components/BeaconConfigForm.tsx`

```tsx
import React, { useState, useEffect } from "react";
import { Save, X } from "lucide-react";
import { Beacon, BeaconMode, ArrowDirection, Language } from "../types";
import { beaconsService } from "../services/beaconService";
import { BeaconPreview } from "./BeaconPreview";

interface BeaconConfigFormProps {
  beacon: Beacon;
  onSave?: () => void;
  onCancel?: () => void;
}

export const BeaconConfigForm: React.FC<BeaconConfigFormProps> = ({ beacon, onSave, onCancel }) => {
  const [mode, setMode] = useState<BeaconMode>(beacon.mode || "UNCONFIGURED");
  const [arrow, setArrow] = useState<ArrowDirection>(beacon.arrow || "NONE");
  const [message, setMessage] = useState(beacon.message || "");
  const [color, setColor] = useState(beacon.color || "#00FFAA");
  const [brightness, setBrightness] = useState(beacon.brightness ?? 90);
  const [language, setLanguage] = useState<Language>(beacon.language || "ES");
  const [evacuationExit, setEvacuationExit] = useState(beacon.evacuationExit || "");
  const [zone, setZone] = useState(beacon.zone || "");
  const [tags, setTags] = useState<string[]>(beacon.tags || []);
  const [tagInput, setTagInput] = useState("");
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    // Actualizar valores si cambia el beacon
    setMode(beacon.mode || "UNCONFIGURED");
    setArrow(beacon.arrow || "NONE");
    setMessage(beacon.message || "");
    setColor(beacon.color || "#00FFAA");
    setBrightness(beacon.brightness ?? 90);
    setLanguage(beacon.language || "ES");
    setEvacuationExit(beacon.evacuationExit || "");
    setZone(beacon.zone || "");
    setTags(beacon.tags || []);
  }, [beacon]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    // Validar zona
    if (!zone || !zone.trim()) {
      newErrors.zone = "La zona es obligatoria";
    }

    // Validar mensaje (máximo 255 caracteres)
    if (message && message.length > 255) {
      newErrors.message = "El mensaje no puede exceder 255 caracteres";
    }

    // Validar color hexadecimal
    const hexColorRegex = /^#[0-9A-Fa-f]{6}$/;
    if (color && !hexColorRegex.test(color)) {
      newErrors.color = "Color debe ser un valor hexadecimal válido (#RRGGBB)";
    }

    // Validar brillo (0-100)
    if (brightness < 0 || brightness > 100) {
      newErrors.brightness = "El brillo debe estar entre 0 y 100";
    }

    // Validar salida de evacuación si está en modo evacuación
    if (mode === "EVACUATION" && (!evacuationExit || !evacuationExit.trim())) {
      newErrors.evacuationExit = "Debe especificar una salida de evacuación en modo EVACUATION";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setSaving(true);
    try {
      await beaconsService.configureBeacon(beacon.beaconId, {
        mode,
        arrow,
        message: message.trim() || undefined,
        color,
        brightness,
        language,
        evacuationExit: evacuationExit.trim() || undefined,
        zone: zone.trim(),
        tags: tags.length > 0 ? tags : undefined
      });

      if (onSave) onSave();
    } catch (error) {
      console.error("Error guardando configuración:", error);
      alert("Error al guardar la configuración");
    } finally {
      setSaving(false);
    }
  };

  const handleAddTag = () => {
    if (tagInput.trim() && !tags.includes(tagInput.trim())) {
      setTags([...tags, tagInput.trim()]);
      setTagInput("");
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setTags(tags.filter(t => t !== tagToRemove));
  };

  return (
    <div className="space-y-6">
      {/* Vista previa */}
      <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-white mb-4">Vista Previa</h3>
        <BeaconPreview
          mode={mode}
          arrow={arrow}
          message={message}
          color={color}
          language={language}
          evacuationExit={evacuationExit}
        />
      </div>

      {/* Formulario */}
      <form onSubmit={handleSubmit} className="bg-dark-800 border border-dark-700 rounded-lg p-6 space-y-4">
        <h3 className="text-lg font-semibold text-white mb-4">Configuración</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Zona <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={zone}
              onChange={(e) => setZone(e.target.value)}
              className={`w-full px-4 py-2 bg-dark-700 border ${errors.zone ? 'border-red-500' : 'border-dark-600'} rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500`}
              placeholder="Ej: GRADA-G, PADDOCK, VIP"
            />
            {errors.zone && <p className="text-red-500 text-xs mt-1">{errors.zone}</p>}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Modo</label>
            <select
              value={mode}
              onChange={(e) => setMode(e.target.value as BeaconMode)}
              className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              title="Modo de la baliza"
            >
              <option value="UNCONFIGURED">Sin configurar</option>
              <option value="NORMAL">Normal</option>
              <option value="CONGESTION">Congestión</option>
              <option value="EMERGENCY">Emergencia</option>
              <option value="EVACUATION">Evacuación</option>
              <option value="MAINTENANCE">Mantenimiento</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Flecha</label>
            <select
              value={arrow}
              onChange={(e) => setArrow(e.target.value as ArrowDirection)}
              className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              title="Dirección de la flecha"
            >
              <option value="NONE">Sin flecha</option>
              <option value="FORWARD">↑ Adelante (Arriba)</option>
              <option value="BACKWARD">↓ Atrás (Abajo)</option>
              <option value="LEFT">← Izquierda</option>
              <option value="RIGHT">→ Derecha</option>
              <option value="FORWARD_LEFT">↖ Diagonal Izq-Adelante</option>
              <option value="FORWARD_RIGHT">↗ Diagonal Der-Adelante</option>
              <option value="BACKWARD_LEFT">↙ Diagonal Izq-Atrás</option>
              <option value="BACKWARD_RIGHT">↘ Diagonal Der-Atrás</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Idioma</label>
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value as Language)}
              className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              title="Idioma de los mensajes"
            >
              <option value="ES">Español</option>
              <option value="CA">Catalán</option>
              <option value="EN">Inglés</option>
              <option value="FR">Francés</option>
              <option value="DE">Alemán</option>
              <option value="IT">Italiano</option>
              <option value="PT">Portugués</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Mensaje {message.length > 0 && <span className="text-xs text-gray-400">({message.length}/255)</span>}
          </label>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={2}
            maxLength={255}
            className={`w-full px-4 py-2 bg-dark-700 border ${errors.message ? 'border-red-500' : 'border-dark-600'} rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500`}
            placeholder="Mensaje a mostrar en la baliza (opcional, máx. 255 caracteres)"
          />
          {errors.message && <p className="text-red-500 text-xs mt-1">{errors.message}</p>}
          <p className="text-xs text-gray-400 mt-1">Si no especifica mensaje, se usará uno predeterminado según el modo</p>
        </div>

        {mode === "EVACUATION" && (
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Salida de Evacuación <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={evacuationExit}
              onChange={(e) => setEvacuationExit(e.target.value)}
              maxLength={100}
              className={`w-full px-4 py-2 bg-dark-700 border ${errors.evacuationExit ? 'border-red-500' : 'border-dark-600'} rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500`}
              placeholder="Ej: SALIDA NORTE, EXIT A"
            />
            {errors.evacuationExit && <p className="text-red-500 text-xs mt-1">{errors.evacuationExit}</p>}
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Color</label>
            <div className="flex gap-2">
              <input
                type="color"
                value={color}
                onChange={(e) => setColor(e.target.value.toUpperCase())}
                className="h-10 w-20 bg-dark-700 border border-dark-600 rounded cursor-pointer"
                title="Selector de color"
              />
              <input
                type="text"
                value={color}
                onChange={(e) => setColor(e.target.value.toUpperCase())}
                maxLength={7}
                className={`flex-1 px-4 py-2 bg-dark-700 border ${errors.color ? 'border-red-500' : 'border-dark-600'} rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500`}
                placeholder="#RRGGBB"
                title="Color en hexadecimal"
              />
            </div>
            {errors.color && <p className="text-red-500 text-xs mt-1">{errors.color}</p>}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Brillo: {brightness}%
            </label>
            <input
              type="range"
              min="0"
              max="100"
              value={brightness}
              onChange={(e) => setBrightness(parseInt(e.target.value))}
              className="w-full"
              title="Control de brillo"
            />
            {errors.brightness && <p className="text-red-500 text-xs mt-1">{errors.brightness}</p>}
          </div>
        </div>

        {/* Sistema de Tags */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Etiquetas (Tags)
          </label>
          <div className="flex gap-2 mb-2">
            <input
              type="text"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
              className="flex-1 px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Agregar etiqueta (presione Enter)"
            />
            <button
              type="button"
              onClick={handleAddTag}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded transition-colors"
            >
              Agregar
            </button>
          </div>
          {tags.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {tags.map((tag, index) => (
                <span
                  key={index}
                  className="inline-flex items-center gap-2 px-3 py-1 bg-blue-600/20 text-blue-400 rounded-full text-sm"
                >
                  {tag}
                  <button
                    type="button"
                    onClick={() => handleRemoveTag(tag)}
                    className="hover:text-blue-300"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          )}
          <p className="text-xs text-gray-400 mt-1">Las etiquetas ayudan a categorizar y filtrar balizas</p>
        </div>

        <div className="flex gap-3 pt-4">
          {onCancel && (
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 flex items-center justify-center gap-2 py-3 bg-dark-700 hover:bg-dark-600 text-white font-semibold rounded-lg transition-colors"
            >
              <X className="w-5 h-5" />
              Cancelar
            </button>
          )}
          <button
            type="submit"
            disabled={saving || !zone.trim()}
            className="flex-1 flex items-center justify-center gap-2 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors"
          >
            <Save className="w-5 h-5" />
            {saving ? "Guardando..." : "Guardar Configuración"}
          </button>
        </div>
      </form>
    </div>
  );
};

```

---

## `Web_Panel/src/components/BeaconEditModal.tsx`

```tsx
import React, { useState, useEffect } from "react";
import { X, Save, RotateCcw, Power, LogOut } from "lucide-react";
import { Beacon, BeaconMode, ArrowDirection, Language } from "../types";
import { beaconsService } from "../services/beaconService";
import { BeaconPreview } from "./BeaconPreview";
import { CommandPanel } from "./CommandPanel";
import { getDefaultBeaconMessage } from "../utils/beaconMessages";
import { useToast } from "../context/ToastContext";

interface BeaconEditModalProps {
  beacon: Beacon;
  onClose: () => void;
  onSaved?: () => void;
}

export const BeaconEditModal: React.FC<BeaconEditModalProps> = ({ beacon, onClose, onSaved }) => {
  const { showToast } = useToast();
  const [mode, setMode] = useState<BeaconMode>((beacon.mode as BeaconMode) || "UNCONFIGURED");
  const [arrow, setArrow] = useState<ArrowDirection>(beacon.arrow || "NONE");
  const [message, setMessage] = useState(beacon.message || "");
  const [color, setColor] = useState(beacon.color || "#00FFAA");
  const [brightness, setBrightness] = useState(beacon.brightness || 90);
  const [language, setLanguage] = useState<Language>(beacon.language || "ES");
  const [evacuationExit, setEvacuationExit] = useState(beacon.evacuationExit || "");
  const [zone, setZone] = useState(beacon.zone || "");
  const [saving, setSaving] = useState(false);
  const [restarting, setRestarting] = useState(false);

  // ✨ NUEVO: Trackear si el usuario ha escrito un mensaje personalizado
  const [hasCustomMessage, setHasCustomMessage] = useState(false);

  useEffect(() => {
    setMode((beacon.mode as BeaconMode) || "UNCONFIGURED");
    setArrow(beacon.arrow || "NONE");
    setMessage(beacon.message || "");
    setColor(beacon.color || "#00FFAA");
    setBrightness(beacon.brightness || 90);
    setLanguage(beacon.language || "ES");
    setEvacuationExit(beacon.evacuationExit || "");
    setZone(beacon.zone || "");
    setHasCustomMessage(false); // Resetear al abrir el modal
  }, [beacon.beaconId, beacon.mode, beacon.arrow, beacon.message, beacon.color, beacon.brightness, beacon.language, beacon.evacuationExit, beacon.zone]);

  // ✨ Actualizar automáticamente el mensaje cuando cambias modo/idioma/flecha
  // SOLO si el usuario NO ha escrito un mensaje personalizado
  useEffect(() => {
    if (!hasCustomMessage) {
      setMessage(getDefaultBeaconMessage(mode, language, arrow));
    }
  }, [mode, language, arrow, hasCustomMessage]);

  // ✨ Detectar cuando el usuario escribe en el campo de mensaje
  const handleMessageChange = (newMessage: string) => {
    setMessage(newMessage);
    // Si el usuario borra todo el texto, volver a modo automático
    if (newMessage.trim() === "") {
      setHasCustomMessage(false);
    } else {
      // Si escribe algo, marcar como personalizado
      setHasCustomMessage(true);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      showToast("Enviando configuración a la baliza...", "info");

      await beaconsService.updateBeacon(beacon.beaconId, {
        mode,
        arrow,
        message, // Ya siempre tiene contenido (automático o personalizado)
        color,
        brightness,
        language,
        evacuationExit,
        zone: zone.trim() || undefined
      });

      showToast("✅ Configuración enviada correctamente", "success");

      if (onSaved) onSaved();
      onClose();
    } catch (error) {
      console.error("Error guardando baliza:", error);
      showToast("❌ Error al contactar con la baliza", "error");
    } finally {
      setSaving(false);
    }
  };

  const handleRestart = async () => {
    if (!confirm(`⚠️⚠️⚠️ ¿Seguro que quieres REINICIAR EL SISTEMA WINDOWS de ${beacon.beaconId}?\n\n🔴 ESTO REINICIARÁ EL ORDENADOR COMPLETO, NO SOLO LA APLICACIÓN.\n\nEl sistema se apagará y volverá a encender.`)) {
      return;
    }

    setRestarting(true);
    try {
      await beaconsService.restartBeacon(beacon.beaconId);
      alert(`✅ Comando de reinicio enviado a ${beacon.beaconId}`);
    } catch (error) {
      console.error("Error reiniciando baliza:", error);
      alert("❌ Error al enviar comando de reinicio");
    } finally {
      setRestarting(false);
    }
  };

  const handleShutdown = async () => {
    if (!confirm(`⛔⛔⛔ ¿Seguro que quieres APAGAR EL SISTEMA WINDOWS de ${beacon.beaconId}?\n\n🔴 EL ORDENADOR SE APAGARÁ COMPLETAMENTE Y NO PODRÁS VOLVER A ENCENDERLO REMOTAMENTE.\n\n¿Continuar?`)) {
      return;
    }

    setRestarting(true); // Reusamos estado para bloquear botones
    try {
      await beaconsService.shutdownBeacon(beacon.beaconId);
      alert(`✅ Comando de APAGADO enviado a ${beacon.beaconId}`);
    } catch (error) {
      console.error("Error apagando baliza:", error);
      alert("❌ Error al enviar comando de apagado");
    } finally {
      setRestarting(false);
    }
  };

  const handleCloseApp = async () => {
    if (!confirm(`¿Seguro que quieres CERRAR LA APLICACIÓN en ${beacon.beaconId}?\n\nLa aplicación se cerrará y volverá al escritorio de Windows.`)) {
      return;
    }

    setRestarting(true);
    try {
      await beaconsService.closeAppBeacon(beacon.beaconId);
      alert(`✅ Comando de cerrar aplicación enviado a ${beacon.beaconId}`);
    } catch (error) {
      console.error("Error cerrando app:", error);
      alert("❌ Error al enviar comando");
    } finally {
      setRestarting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4">
      <div className="bg-dark-800 rounded-lg max-w-5xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-dark-800 border-b border-dark-700 px-6 py-4 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-white">Editar Baliza</h2>
            <p className="text-sm text-gray-400">{beacon.beaconId} - {beacon.zone}</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-dark-700 rounded-lg transition-colors"
            title="Cerrar"
          >
            <X className="w-5 h-5 text-gray-400" />
          </button>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Formulario */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white mb-4">Configuración</h3>

              {/* Zona */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Zona <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={zone}
                  onChange={(e) => setZone(e.target.value)}
                  maxLength={50}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Ej: GRADA-G, PADDOCK, VIP"
                />
                <p className="text-xs text-gray-400 mt-1">Ubicación física de la baliza (máx. 50 caracteres)</p>
              </div>

              {/* Modo */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Modo</label>
                <select
                  value={mode}
                  onChange={(e) => setMode(e.target.value as BeaconMode)}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  title="Modo de operación"
                >
                  <option value="UNCONFIGURED">Sin configurar</option>
                  <option value="NORMAL">Normal</option>
                  <option value="CONGESTION">Congestión</option>
                  <option value="EMERGENCY">Emergencia</option>
                  <option value="EVACUATION">Evacuación</option>
                  <option value="MAINTENANCE">Mantenimiento</option>
                </select>
              </div>

              {/* Flecha */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Flecha</label>
                <select
                  value={arrow}
                  onChange={(e) => setArrow(e.target.value as ArrowDirection)}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  title="Dirección de la flecha"
                >
                  <option value="NONE">Sin flecha</option>
                  <option value="UP">↑ Arriba</option>
                  <option value="DOWN">↓ Abajo</option>
                  <option value="LEFT">← Izquierda</option>
                  <option value="RIGHT">→ Derecha</option>
                  <option value="UP_LEFT">↖ Arriba-Izquierda</option>
                  <option value="UP_RIGHT">↗ Arriba-Derecha</option>
                  <option value="DOWN_LEFT">↙ Abajo-Izquierda</option>
                  <option value="DOWN_RIGHT">↘ Abajo-Derecha</option>
                </select>
              </div>

              {/* Mensaje */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Mensaje Personalizado (opcional)
                </label>
                <div className="space-y-2">
                  <div className="px-3 py-2 bg-blue-900/30 border border-blue-700/50 rounded text-sm">
                    <div className="flex items-start gap-2">
                      <span className="text-blue-400 font-semibold shrink-0">💡 Predefinido:</span>
                      <span className="text-blue-200 italic">"{getDefaultBeaconMessage(mode, language, arrow)}"</span>
                    </div>
                    <p className="text-xs text-blue-300/70 mt-1 ml-6">
                      Este texto se mostrará si dejas el campo vacío
                    </p>
                  </div>
                  <textarea
                    value={message}
                    onChange={(e) => handleMessageChange(e.target.value)}
                    rows={3}
                    className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Escribe aquí tu mensaje personalizado (déjalo vacío para usar el predefinido)"
                  />
                  {hasCustomMessage && (
                    <p className="text-xs text-green-400 flex items-center gap-1">
                      <span>✓</span> Se usará tu mensaje personalizado
                    </p>
                  )}
                  {!hasCustomMessage && (
                    <p className="text-xs text-blue-400 flex items-center gap-1">
                      <span>🔄</span> Actualizándose automáticamente
                    </p>
                  )}
                </div>
              </div>

              {/* Salida de evacuación (solo si modo es EVACUATION) */}
              {mode === "EVACUATION" && (
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Salida de Evacuación</label>
                  <input
                    type="text"
                    value={evacuationExit}
                    onChange={(e) => setEvacuationExit(e.target.value)}
                    className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Ej: SALIDA NORTE, EXIT A"
                  />
                </div>
              )}

              {/* Color y Brillo */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Color</label>
                  <div className="flex gap-2">
                    <input
                      type="color"
                      value={color}
                      onChange={(e) => setColor(e.target.value)}
                      className="h-10 w-20 bg-dark-700 border border-dark-600 rounded cursor-pointer"
                      title="Selector de color"
                    />
                    <input
                      type="text"
                      value={color}
                      onChange={(e) => setColor(e.target.value)}
                      className="flex-1 px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="#RRGGBB"
                      title="Color en hexadecimal"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Brillo: {brightness}%
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={brightness}
                    onChange={(e) => setBrightness(parseInt(e.target.value))}
                    className="w-full"
                    title="Control de brillo"
                  />
                </div>
              </div>

              {/* Idioma */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Idioma</label>
                <select
                  value={language}
                  onChange={(e) => setLanguage(e.target.value as Language)}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  title="Idioma de los mensajes"
                >
                  <option value="ES">Español</option>
                  <option value="CA">Catalán</option>
                  <option value="EN">Inglés</option>
                  <option value="FR">Francés</option>
                  <option value="DE">Alemán</option>
                  <option value="IT">Italiano</option>
                  <option value="PT">Portugués</option>
                </select>
              </div>
            </div>

            {/* Vista Previa */}
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold text-white mb-4">Vista Previa</h3>
                <BeaconPreview
                  mode={mode}
                  arrow={arrow}
                  message={message}
                  color={color}
                  language={language}
                  evacuationExit={evacuationExit}
                />
              </div>

              <CommandPanel beaconId={beacon.beaconId} />
            </div>
          </div>
        </div>

        {/* Footer con botones */}
        <div className="sticky bottom-0 bg-dark-800 border-t border-dark-700 px-6 py-4 flex gap-3">
          <button
            onClick={onClose}
            className="px-4 py-3 bg-dark-700 hover:bg-dark-600 text-white font-semibold rounded-lg transition-colors"
          >
            Cancelar
          </button>

          <div className="flex-1 flex gap-2">
            <button
              onClick={handleCloseApp}
              disabled={restarting || saving}
              className="flex-1 flex items-center justify-center gap-2 py-3 bg-gray-600 hover:bg-gray-700 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
              title="Cerrar Aplicación"
            >
              <LogOut className="w-5 h-5" />
              Cerrar App
            </button>

            <button
              onClick={handleRestart}
              disabled={restarting || saving}
              className="flex-1 flex items-center justify-center gap-2 py-3 bg-orange-600 hover:bg-orange-700 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
              title="Reiniciar Windows"
            >
              <RotateCcw className="w-5 h-5" />
              Reiniciar
            </button>

            <button
              onClick={handleShutdown}
              disabled={restarting || saving}
              className="flex-1 flex items-center justify-center gap-2 py-3 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
              title="Apagar Windows"
            >
              <Power className="w-5 h-5" />
              Apagar
            </button>
          </div>

          <button
            onClick={handleSave}
            disabled={saving || restarting}
            className="px-8 flex items-center justify-center gap-2 py-3 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
          >
            <Save className="w-5 h-5" />
            {saving ? "Guardando..." : "Guardar"}
          </button>
        </div>
      </div>
    </div>
  );
};


```

---

## `Web_Panel/src/components/BeaconMetricsCard.tsx`

```tsx

import type { Beacon } from "../types";
import { getModeColor, BeaconModeStrict } from "../utils/beaconHelpers";

interface BeaconMetricsCardProps {
  beacon: Beacon;
  onClick?: () => void;
  selected?: boolean;
  onSelect?: () => void;
}

export function BeaconMetricsCard({ beacon, onClick, selected, onSelect }: BeaconMetricsCardProps) {
  const {
    beaconId,
    name,
    battery,
    brightness,
    mode,
    online,
    lastSeen,
    lastUpdate,
    zone,
    arrow,
    message,
    configured,
    tags,
  } = beacon;

  const displayName = name || beaconId;
  const modeClass = getModeColor(mode as BeaconModeStrict | null);

  return (
    <section
      className="rounded-2xl border border-slate-800 bg-slate-900/60 p-4 shadow-sm"
      aria-label={`Métricas de la baliza ${displayName}`}
      tabIndex={0}
      role="button"
      onClick={onClick}
      onKeyDown={e => {
        if (e.key === "Enter" || e.key === " ") onClick?.();
      }}
    >
      <div className="absolute top-4 right-4 z-10">
        {onSelect && (
          <input
            type="checkbox"
            checked={selected}
            onChange={(e) => {
              e.stopPropagation();
              onSelect();
            }}
            className="w-5 h-5 rounded border-gray-600 bg-dark-700 text-blue-600 focus:ring-blue-500 focus:ring-offset-dark-800"
          />
        )}
      </div>
      <header className="mb-3 flex items-center justify-between gap-2 pr-8">
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-sm font-semibold text-slate-100">{displayName}</h2>
          <p className="truncate text-xs text-slate-400">{beaconId}</p>
          {zone && <p className="truncate text-xs text-blue-400 mt-0.5">📍 {zone}</p>}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <span
            className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${online
              ? "bg-emerald-500/10 text-emerald-400 ring-1 ring-emerald-500/30"
              : "bg-red-500/10 text-red-400 ring-1 ring-red-500/30"
              }`}
            role="status"
            aria-label={online ? "Baliza en línea" : "Baliza desconectada"}
          >
            <span
              className={`h-1.5 w-1.5 rounded-full ${online ? "bg-emerald-400" : "bg-red-400"
                }`}
              aria-hidden="true"
            />
            {online ? "Online" : "Offline"}
          </span>
          {!configured && (
            <span
              className="inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium bg-yellow-500/10 text-yellow-400 ring-1 ring-yellow-500/30"
              title="Baliza sin configurar"
            >
              ⚠️ Sin configurar
            </span>
          )}
          <span
            className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ring-1 ${modeClass}`}
            title={mode ?? "Modo desconocido"}
          >
            {mode ?? "Modo desconocido"}
          </span>
        </div>
      </header>
      <div className="grid gap-3 text-xs text-slate-300 sm:grid-cols-2">
        <div>
          <p className="mb-1 text-slate-400">Batería</p>
          <p className="font-medium">
            {battery != null ? `${battery}%` : "Desconocida"}
          </p>
        </div>
        <div>
          <p className="mb-1 text-slate-400">Brillo</p>
          <p className="font-medium">
            {brightness != null ? `${brightness}%` : "Desconocido"}
          </p>
        </div>
        {arrow && arrow !== "NONE" && (
          <div>
            <p className="mb-1 text-slate-400">Flecha</p>
            <p className="font-medium">
              {arrow === "UP" && "↑ Arriba"}
              {arrow === "DOWN" && "↓ Abajo"}
              {arrow === "LEFT" && "← Izquierda"}
              {arrow === "RIGHT" && "→ Derecha"}
              {arrow === "UP_LEFT" && "↖ Arriba-Izq"}
              {arrow === "UP_RIGHT" && "↗ Arriba-Der"}
              {arrow === "DOWN_LEFT" && "↙ Abajo-Izq"}
              {arrow === "DOWN_RIGHT" && "↘ Abajo-Der"}
            </p>
          </div>
        )}
        {message && (
          <div className="col-span-2">
            <p className="mb-1 text-slate-400">Mensaje</p>
            <p className="font-medium truncate" title={message}>
              {message}
            </p>
          </div>
        )}
        <div>
          <p className="mb-1 text-slate-400">Última señal</p>
          <p className="font-medium">
            {lastSeen ? new Date(lastSeen).toLocaleString() : "Sin datos"}
          </p>
        </div>
        <div>
          <p className="mb-1 text-slate-400">Última actualización</p>
          <p className="font-medium">
            {lastUpdate ? new Date(lastUpdate).toLocaleString() : "Sin datos"}
          </p>
        </div>
      </div>

      {/* Tags */}
      {tags && tags.length > 0 && (
        <div className="mt-3 pt-3 border-t border-slate-800">
          <div className="flex flex-wrap gap-1">
            {tags.map((tag, index) => (
              <span
                key={index}
                className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-blue-500/10 text-blue-400 ring-1 ring-blue-500/30"
              >
                {tag}
              </span>
            ))}
          </div>
        </div>
      )}
    </section>
  );
}

```

---

## `Web_Panel/src/components/BeaconPreview.tsx`

```tsx
import React from "react";
import { BeaconMode, ArrowDirection, Language } from "../types";
import { ArrowLeft, ArrowRight, ArrowUp, ArrowDown, ArrowUpLeft, ArrowUpRight, ArrowDownLeft, ArrowDownRight } from "lucide-react";
import { getDefaultBeaconMessage } from "../utils/beaconMessages";

export interface BeaconPreviewProps {
  mode: BeaconMode;
  arrow: ArrowDirection;
  message?: string; // Opcional porque puede no existir en Firestore
  color: string;
  language: Language;
  evacuationExit?: string;
}

export const BeaconPreview: React.FC<BeaconPreviewProps> = ({
  mode,
  arrow,
  message,
  color,
  language,
  evacuationExit
}) => {
  const getBackgroundColor = () => {
    switch (mode) {
      case "UNCONFIGURED":
        return "#333333";
      case "NORMAL":
        return color;
      case "CONGESTION":
        return "#FFA500";
      case "EMERGENCY":
        return "#FF6600";
      case "EVACUATION":
        return "#FF0000";
      case "MAINTENANCE":
        return "#808080";
      default:
        return color;
    }
  };

  // Obtener mensaje a mostrar: personalizado o predefinido según modo/idioma/flecha
  const getDisplayMessage = (): string => {
    // Si hay mensaje personalizado (no vacío), usarlo
    if (message && message.trim()) {
      return message;
    }

    // Si no hay mensaje o está vacío, usar texto predefinido según modo, idioma y dirección
    return getDefaultBeaconMessage(mode, language, arrow);
  };

  const renderArrow = () => {
    const arrowClass = "w-32 h-32 text-white";

    switch (arrow) {
      case "LEFT":
        return <ArrowLeft className={arrowClass} />;
      case "RIGHT":
        return <ArrowRight className={arrowClass} />;
      case "FORWARD":
      case "UP": // Backwards compatibility
        return <ArrowUp className={arrowClass} />;
      case "BACKWARD":
      case "DOWN": // Backwards compatibility
        return <ArrowDown className={arrowClass} />;
      case "FORWARD_LEFT":
      case "UP_LEFT":
        return <ArrowUpLeft className={arrowClass} />;
      case "FORWARD_RIGHT":
      case "UP_RIGHT":
        return <ArrowUpRight className={arrowClass} />;
      case "BACKWARD_LEFT":
      case "DOWN_LEFT":
        return <ArrowDownLeft className={arrowClass} />;
      case "BACKWARD_RIGHT":
      case "DOWN_RIGHT":
        return <ArrowDownRight className={arrowClass} />;
      default:
        return null;
    }
  };

  const displayMessage = getDisplayMessage();

  if (mode === "UNCONFIGURED") {
    return (
      <div
        className="w-full aspect-video rounded-lg flex items-center justify-center bg-gray-800"
      >
        <div className="text-center text-gray-400">
          <div className="text-4xl font-bold mb-2">⚠️</div>
          <div className="text-2xl font-semibold">
            BALIZA SIN CONFIGURAR
          </div>
          <div className="text-sm mt-2">
            Configure esta baliza desde el panel de control
          </div>
        </div>
      </div>
    );
  }

  if (mode === "MAINTENANCE") {
    return (
      <div
        className="w-full aspect-video rounded-lg flex items-center justify-center"
        style={{ backgroundColor: getBackgroundColor() }}
      >
        <div className="text-center text-white">
          <div className="text-6xl font-bold mb-4">
            {new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })}
          </div>
          <div className="text-2xl">
            MANTENIMIENTO
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className="w-full aspect-video rounded-lg flex flex-col items-center justify-center p-8"
      style={{ backgroundColor: getBackgroundColor() }}
    >
      {arrow !== "NONE" && (
        <div className="mb-6">
          {renderArrow()}
        </div>
      )}

      <div className="text-center text-white">
        <div className="text-3xl font-bold mb-4 whitespace-pre-line">
          {displayMessage}
        </div>

        {mode === "EVACUATION" && evacuationExit && (
          <div className="text-2xl font-semibold mt-4 px-6 py-3 bg-black/30 rounded-lg">
            {evacuationExit}
          </div>
        )}
      </div>
    </div>
  );
};

```

---

## `Web_Panel/src/components/CommandPanel.tsx`

```tsx
import React, { useState } from "react";
import { Terminal, Send } from "lucide-react";
import { beaconsService } from "../services/beaconService";

interface CommandPanelProps {
  beaconId?: string;
  onCommandSent?: () => void;
}

export const CommandPanel: React.FC<CommandPanelProps> = ({ beaconId, onCommandSent }) => {
  const [command, setCommand] = useState("");
  const [sending, setSending] = useState(false);

  const handleSendCommand = async () => {
    if (!command.trim() || !beaconId) return;

    setSending(true);
    try {
      await beaconsService.sendCommand(beaconId, command.trim());
      alert(`✅ Comando "${command}" enviado a ${beaconId}`);
      setCommand("");
      if (onCommandSent) onCommandSent();
    } catch (error) {
      console.error("Error enviando comando:", error);
      alert("❌ Error al enviar comando");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="bg-dark-700 rounded-lg p-4 border border-dark-600">
      <div className="flex items-center gap-2 mb-3">
        <Terminal className="w-5 h-5 text-blue-400" />
        <h3 className="text-lg font-semibold text-white">Ejecutar Comando</h3>
      </div>
      
      <div className="flex gap-2">
        <input
          type="text"
          value={command}
          onChange={(e) => setCommand(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !sending) {
              handleSendCommand();
            }
          }}
          placeholder="RESTART, STATUS, CONFIG..."
          className="flex-1 px-4 py-2 bg-dark-800 border border-dark-600 rounded text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
          disabled={!beaconId || sending}
        />
        <button
          onClick={handleSendCommand}
          disabled={!command.trim() || !beaconId || sending}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded transition-colors"
          title="Enviar comando"
        >
          <Send className="w-4 h-4" />
          {sending ? "Enviando..." : "Enviar"}
        </button>
      </div>
      
      {!beaconId && (
        <p className="text-sm text-gray-500 mt-2">
          Selecciona una baliza para enviar comandos
        </p>
      )}
    </div>
  );
};

```

---

## `Web_Panel/src/components/EvacuationModal.tsx`

```tsx
import React, { useState } from 'react';
import { AlertTriangle, ShieldAlert, X } from 'lucide-react';
import { api } from '../services/apiClient';

interface EvacuationModalProps {
    isOpen: boolean;
    onClose: () => void;
    isEvacuationActive: boolean;
}

export const EvacuationModal: React.FC<EvacuationModalProps> = ({ isOpen, onClose, isEvacuationActive }) => {
    const [loading, setLoading] = useState(false);
    const [confirmText, setConfirmText] = useState('');

    if (!isOpen) return null;

    const handleToggle = async () => {
        setLoading(true);
        try {
            const newMode = isEvacuationActive ? "NORMAL" : "EVACUATION";
            const message = isEvacuationActive ? "System Normal" : "EVACUATION ORDER - PLEASE EXIT";

            await api.setCircuitState(newMode, message);

            // Also send command to beacons? Ideally API handles this or beacons poll. 
            // For immediate effect we could iterate beacons, but let's rely on polling/db first as per plan.

            onClose();
        } catch (err) {
            console.error(err);
            alert("Error changing state");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
            <div className={`w-full max-w-lg rounded-2xl border-2 p-6 shadow-2xl ${isEvacuationActive ? 'bg-green-900/20 border-green-500' : 'bg-red-900/20 border-red-500'}`}>

                <div className="flex justify-between items-start mb-6">
                    <div className="flex items-center gap-3">
                        <div className={`p-3 rounded-full ${isEvacuationActive ? 'bg-green-500/20 text-green-500' : 'bg-red-500/20 text-red-500'}`}>
                            {isEvacuationActive ? <ShieldAlert className="w-8 h-8" /> : <AlertTriangle className="w-8 h-8" />}
                        </div>
                        <div>
                            <h2 className="text-2xl font-bold text-white">
                                {isEvacuationActive ? "DESACTIVAR EVACUACIÓN" : "ACTIVAR MODO EVACUACIÓN"}
                            </h2>
                            <p className="text-gray-400">Control de Emergencia Global</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 text-gray-400 hover:text-white rounded-lg hover:bg-white/10">
                        <X className="w-6 h-6" />
                    </button>
                </div>

                <div className="space-y-4 mb-8">
                    {isEvacuationActive ? (
                        <p className="text-gray-300">
                            ¿Confirmas que la situación de emergencia ha pasado? Esto devolverá todas las balizas y apps al modo <strong>NORMAL</strong>.
                        </p>
                    ) : (
                        <div className="bg-red-500/10 p-4 rounded-lg border border-red-500/30">
                            <p className="text-red-200 font-medium mb-2">⚠️ ESTA ES UNA ACCIÓN CRÍTICA</p>
                            <ul className="list-disc list-inside text-sm text-red-300 space-y-1">
                                <li>Todas las balizas mostrarán flechas de salida.</li>
                                <li>Los usuarios recibirán alertas en sus móviles.</li>
                                <li>Se activarán los protocolos de seguridad.</li>
                            </ul>
                        </div>
                    )}

                    {!isEvacuationActive && (
                        <div>
                            <label className="text-xs uppercase tracking-wider text-gray-500 font-semibold">Confirmación</label>
                            <input
                                type="text"
                                placeholder="Escribe 'EVACUAR' para confirmar"
                                value={confirmText}
                                onChange={(e) => setConfirmText(e.target.value)}
                                className="w-full mt-2 bg-dark-800 border-dark-600 text-white p-3 rounded-lg focus:ring-red-500 focus:border-red-500"
                            />
                        </div>
                    )}
                </div>

                <div className="flex gap-3">
                    <button onClick={onClose} className="flex-1 py-3 bg-dark-700 hover:bg-dark-600 text-white rounded-xl font-medium transition-colors">
                        Cancelar
                    </button>
                    <button
                        onClick={handleToggle}
                        disabled={loading || (!isEvacuationActive && confirmText !== 'EVACUAR')}
                        className={`flex-1 py-3 rounded-xl font-bold text-white transition-all transform active:scale-95 flex items-center justify-center gap-2
              ${loading ? 'opacity-50 cursor-not-allowed' : ''}
              ${isEvacuationActive
                                ? 'bg-green-600 hover:bg-green-500 shadow-lg shadow-green-900/20'
                                : 'bg-red-600 hover:bg-red-500 shadow-lg shadow-red-900/20 disabled:bg-gray-700 disabled:text-gray-500'
                            }
            `}
                    >
                        {loading ? "Procesando..." : (isEvacuationActive ? "RESTAURAR NORMALIDAD" : "INICIAR EVACUACIÓN")}
                    </button>
                </div>
            </div>
        </div>
    );
};

```

---

## `Web_Panel/src/components/Layout.tsx`

```tsx
import React from "react";
import { Link, useLocation } from "react-router-dom";
import { LogOut, Radio, Bell, MapPin, AlertTriangle, Settings, Activity, Flag, Terminal, ShoppingBag, Package, UtensilsCrossed, Newspaper, Users } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { useNewBeaconDetection } from "../hooks/useNewBeaconDetection";

import { useCircuitState } from "../hooks/useCircuitState"; // Assuming hook created
import { EvacuationModal } from "./EvacuationModal"; // Assuming component created
import { ShieldAlert } from "lucide-react";

interface LayoutProps {
  children: React.ReactNode;
  onNewBeaconClick?: () => void;
}

export const Layout: React.FC<LayoutProps> = ({ children, onNewBeaconClick }) => {
  const { user, logout } = useAuth();
  const { hasNewBeacons, newBeacons } = useNewBeaconDetection();
  const { state: circuitState } = useCircuitState(); // Poll global state
  const location = useLocation();
  const [showEvacModal, setShowEvacModal] = React.useState(false);

  const isEvacuation = circuitState?.global_mode === 'EVACUATION';

  const navItems = [
    { path: "/dashboard", label: "Dashboard", icon: Activity },
    { path: "/users", label: "Usuarios", icon: Users },
    { path: "/orders", label: "Pedidos", icon: ShoppingBag },
    { path: "/products", label: "Productos", icon: Package },
    { path: "/food-stands", label: "Food Stands", icon: UtensilsCrossed },
    { path: "/news", label: "Noticias", icon: Newspaper },
    { path: "/beacons", label: "Balizas", icon: Radio },
    { path: "/zones", label: "Mapa", icon: MapPin },
    { path: "/circuit-state", label: "Estado Circuito", icon: Flag },
    { path: "/incidents", label: "Incidencias", icon: AlertTriangle, badge: true },
    { path: "/logs", label: "Logs", icon: Terminal },
    { path: "/config", label: "Configuración", icon: Settings }
  ];

  const isActive = (path: string) => {
    return location.pathname === path || location.pathname.startsWith(path + "/");
  };

  return (
    <div className={`min-h-screen flex flex-col transition-colors duration-500 ${isEvacuation ? 'bg-red-950' : 'bg-dark-900'}`}>

      {/* Evacuation Modal */}
      <EvacuationModal
        isOpen={showEvacModal}
        onClose={() => setShowEvacModal(false)}
        isEvacuationActive={isEvacuation}
      />

      {/* GLOBAL EMERGENCY ALERT BANNER */}
      {isEvacuation && (
        <div className="bg-red-600 animate-pulse px-6 py-2 flex items-center justify-center gap-3 shadow-lg z-50">
          <ShieldAlert className="text-white w-6 h-6" />
          <span className="text-white font-black tracking-widest uppercase">⚠️ MODO EVACUACIÓN ACTIVO - PROTOCOLO DE EMERGENCIA EN CURSO ⚠️</span>
        </div>
      )}

      {/* Header */}
      <header className={`border-b transition-colors ${isEvacuation ? 'bg-red-900/50 border-red-700' : 'bg-dark-800 border-dark-700'}`}>
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            {/* Logo y Título */}
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2">
                <Radio className={`w-8 h-8 ${isEvacuation ? 'text-white' : 'text-blue-500'}`} />
                <div>
                  <h1 className="text-xl font-bold text-white">PANEL DE CONTROL</h1>
                  <p className={`text-xs ${isEvacuation ? 'text-red-200' : 'text-gray-400'}`}>Sistema de Gestión Inteligente METROPOLIS</p>
                </div>
              </div>
            </div>

            {/* Indicadores de Estado y Usuario */}
            <div className="flex items-center gap-4">

              {/* EMERGENCY BUTTON */}
              <button
                onClick={() => setShowEvacModal(true)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg font-bold transition-all shadow-lg hover:scale-105 ${isEvacuation
                  ? 'bg-white text-red-600 hover:bg-gray-100 ring-4 ring-red-500/30'
                  : 'bg-red-500/10 text-red-500 border border-red-500/50 hover:bg-red-500 hover:text-white'
                  }`}
              >
                <AlertTriangle className="w-5 h-5" />
                {isEvacuation ? "GESTIONAR EMERGENCIA" : "EMERGENCIA"}
              </button>

              <div className="h-6 w-px bg-gray-700 mx-2"></div>

              {/* Indicadores de Estado */}
              <div className="flex items-center gap-3 text-xs hidden md:flex">
                <div className="flex items-center gap-1.5 px-3 py-1.5 bg-green-500/10 text-green-400 border border-green-500/30 rounded">
                  <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                  <span className="font-medium">Soleado</span>
                </div>
                <div className="flex items-center gap-1.5 px-3 py-1.5 bg-green-500/10 text-green-400 border border-green-500/30 rounded">
                  <span className="font-medium">⚡ ELECTRICIDAD ON</span>
                </div>
                <div className="flex items-center gap-1.5 px-3 py-1.5 bg-green-500/10 text-green-400 border border-green-500/30 rounded">
                  <span className="font-medium">📡 IA ACTIVA</span>
                </div>
              </div>

              {hasNewBeacons && (
                <button
                  onClick={onNewBeaconClick}
                  className="relative flex items-center gap-2 px-4 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg transition-colors animate-pulse"
                >
                  <Bell className="w-4 h-4" />
                  <span className="font-semibold">
                    {newBeacons.length} {newBeacons.length === 1 ? 'Baliza Nueva' : 'Balizas Nuevas'}
                  </span>
                  <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full"></span>
                </button>
              )}

              <span className="text-sm text-gray-400">{user?.email}</span>
              <button
                onClick={logout}
                className="flex items-center gap-2 px-4 py-2 bg-dark-700 hover:bg-dark-600 text-white rounded-lg transition-colors"
              >
                <LogOut className="w-4 h-4" />
                Cerrar sesión
              </button>
            </div>
          </div>
        </div>

        {/* Navegación con tabs */}
        <div className="px-6">
          <nav className="flex items-center gap-1 -mb-px">
            {navItems.map(({ path, label, icon: Icon, badge }) => (
              <Link
                key={path}
                to={path}
                className={`
                  flex items-center gap-2 px-4 py-3 text-sm font-medium transition-all relative
                  ${isActive(path)
                    ? "text-white border-b-2 border-white"
                    : "text-gray-400 hover:text-gray-300"
                  }
                `}
              >
                <Icon className="w-4 h-4" />
                <span>{label}</span>
                {badge && path === "/emergencies" && (
                  <span className="ml-1 px-2 py-0.5 bg-red-500 text-white text-xs rounded-full">
                    6
                  </span>
                )}
              </Link>
            ))}
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto p-6">
        {children}
      </main>
    </div>
  );
};

```

---

## `Web_Panel/src/components/NewBeaconModal.tsx`

```tsx
import React, { useState } from "react";
import { NewBeaconDetected } from "../services/beaconDetectionService";
import { BeaconMode, ArrowDirection, Language } from "../types";
import { X, Save, AlertCircle } from "lucide-react";
import { beaconsService } from "../services/beaconService";
import { useToast } from "../context/ToastContext";

interface NewBeaconModalProps {
  beacon: NewBeaconDetected;
  onClose: () => void;
  onConfigured: () => void;
}

export const NewBeaconModal: React.FC<NewBeaconModalProps> = ({ beacon, onClose, onConfigured }) => {
  const { showToast } = useToast();
  const [zone, setZone] = useState("");
  const [mode, setMode] = useState<BeaconMode>("NORMAL");
  const [arrow, setArrow] = useState<ArrowDirection>("NONE");
  const [message, setMessage] = useState("Acceso Principal");
  const [color, setColor] = useState("#00FFAA");
  const [brightness, setBrightness] = useState(90);
  const [language, setLanguage] = useState<Language>("ES");
  const [tags, setTags] = useState("");
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!zone.trim()) {
      showToast("La zona es obligatoria", "warning");
      return;
    }

    setSaving(true);
    try {
      showToast("Configurando baliza...", "info");
      
      await beaconsService.configureBeacon(beacon.beaconId, {
        mode,
        arrow,
        message,
        color,
        brightness,
        language,
        evacuationExit: ""
      });
      
      showToast("✅ Baliza configurada correctamente", "success");
      onConfigured();
      onClose();
    } catch (error) {
      console.error("Error configurando baliza:", error);
      showToast("❌ Error al configurar la baliza", "error");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4">
      <div className="bg-dark-800 rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-dark-800 border-b border-dark-700 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertCircle className="w-6 h-6 text-yellow-500" />
            <div>
              <h2 className="text-xl font-bold text-white">Nueva Baliza Detectada</h2>
              <p className="text-sm text-gray-400">Configura los parámetros iniciales</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-dark-700 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-400" />
          </button>
        </div>

        <div className="p-6 space-y-4">
          <div className="bg-blue-500/10 border border-blue-500 rounded-lg p-4">
            <div className="flex items-center gap-2 text-blue-400 mb-2">
              <span className="font-semibold">Baliza ID:</span>
              <span className="font-mono">{beacon.beaconId}</span>
            </div>
            <div className="text-sm text-gray-400">
              Primera conexión: {beacon.firstSeen ? new Date(beacon.firstSeen as any).toLocaleString('es-ES') : 'Desconocida'}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Zona <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                value={zone}
                onChange={(e) => setZone(e.target.value)}
                className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Ej: GRADA-G, PADDOCK, VIP"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Modo</label>
              <select
                value={mode}
                onChange={(e) => setMode(e.target.value as BeaconMode)}
                className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="UNCONFIGURED">Sin configurar</option>
                <option value="NORMAL">Normal</option>
                <option value="CONGESTION">Congestión</option>
                <option value="EMERGENCY">Emergencia</option>
                <option value="EVACUATION">Evacuación</option>
                <option value="MAINTENANCE">Mantenimiento</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Flecha</label>
              <select
                value={arrow}
                onChange={(e) => setArrow(e.target.value as ArrowDirection)}
                className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="NONE">Ninguna</option>
                <option value="UP">↑ Arriba</option>
                <option value="DOWN">↓ Abajo</option>
                <option value="LEFT">← Izquierda</option>
                <option value="RIGHT">→ Derecha</option>
                <option value="UP_LEFT">↖ Arriba-Izquierda</option>
                <option value="UP_RIGHT">↗ Arriba-Derecha</option>
                <option value="DOWN_LEFT">↙ Abajo-Izquierda</option>
                <option value="DOWN_RIGHT">↘ Abajo-Derecha</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Idioma</label>
              <select
                value={language}
                onChange={(e) => setLanguage(e.target.value as Language)}
                className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="ES">Español</option>
                <option value="CA">Catalán</option>
                <option value="EN">Inglés</option>
                <option value="FR">Francés</option>
                <option value="DE">Alemán</option>
                <option value="IT">Italiano</option>
                <option value="PT">Portugués</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Mensaje</label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={2}
              className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Mensaje a mostrar en la baliza"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Color</label>
              <div className="flex gap-2">
                <input
                  type="color"
                  value={color}
                  onChange={(e) => setColor(e.target.value)}
                  className="h-10 w-20 bg-dark-700 border border-dark-600 rounded cursor-pointer"
                />
                <input
                  type="text"
                  value={color}
                  onChange={(e) => setColor(e.target.value)}
                  className="flex-1 px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Brillo: {brightness}%
              </label>
              <input
                type="range"
                min="0"
                max="100"
                value={brightness}
                onChange={(e) => setBrightness(parseInt(e.target.value))}
                className="w-full"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Etiquetas (separadas por comas)
            </label>
            <input
              type="text"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="entrada, grada, principal"
            />
          </div>
        </div>

        <div className="sticky bottom-0 bg-dark-800 border-t border-dark-700 px-6 py-4 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 py-3 bg-dark-700 hover:bg-dark-600 text-white font-semibold rounded-lg transition-colors"
          >
            Cancelar
          </button>
          <button
            onClick={handleSave}
            disabled={saving || !zone.trim()}
            className="flex-1 flex items-center justify-center gap-2 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors"
          >
            <Save className="w-5 h-5" />
            {saving ? "Guardando..." : "Guardar Configuración"}
          </button>
        </div>
      </div>
    </div>
  );
};

```

---

## `Web_Panel/src/components/ProtectedRoute.tsx`

```tsx
import React from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-900 flex items-center justify-center">
        <div className="text-white text-xl">Cargando...</div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

```

---

## `Web_Panel/src/components/Toast.tsx`

```tsx
import React, { useEffect } from "react";
import { CheckCircle, XCircle, Info, AlertCircle } from "lucide-react";

export type ToastType = "success" | "error" | "info" | "warning";

interface ToastProps {
  id?: string; // Opcional, usado solo para key en el parent
  message: string;
  type: ToastType;
  onClose: () => void;
  duration?: number;
}

export const Toast: React.FC<ToastProps> = ({ message, type, onClose, duration = 3000 }) => {
  useEffect(() => {
    const timer = setTimeout(onClose, duration);
    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const getIcon = () => {
    switch (type) {
      case "success":
        return <CheckCircle className="w-5 h-5 text-green-400" />;
      case "error":
        return <XCircle className="w-5 h-5 text-red-400" />;
      case "warning":
        return <AlertCircle className="w-5 h-5 text-orange-400" />;
      case "info":
        return <Info className="w-5 h-5 text-blue-400" />;
    }
  };

  const getBgColor = () => {
    switch (type) {
      case "success":
        return "bg-black/90 border-neon-green/50 shadow-[0_0_10px_rgba(57,255,20,0.3)]";
      case "error":
        return "bg-black/90 border-neon-red/50 shadow-[0_0_10px_rgba(255,0,0,0.3)]";
      case "warning":
        return "bg-black/90 border-neon-yellow/50 shadow-[0_0_10px_rgba(255,255,0,0.3)]";
      case "info":
        return "bg-black/90 border-neon-blue/50 shadow-[0_0_10px_rgba(0,255,255,0.3)]";
    }
  };

  return (
    <div className={`relative flex items-center gap-3 px-4 py-3 rounded-sm border-l-4 ${getBgColor()} backdrop-blur-sm animate-slide-up font-mono`}>
      {getIcon()}
      <span className="text-white text-sm font-bold tracking-wide">{message}</span>
      <button
        onClick={onClose}
        className="ml-2 text-gray-500 hover:text-white transition-colors font-bold"
        aria-label="Cerrar notificación"
      >
        ×
      </button>
    </div>
  );
};

```

---

## `Web_Panel/src/context/AuthContext.tsx`

```tsx
import React, { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { 
  User, 
  signOut,
  onAuthStateChanged
} from "firebase/auth";
import { auth } from "../firebase/firebaseApp";

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const login = async (email: string) => {
    // Login simplificado sin contraseña
    const mockUser = { email } as User;
    setUser(mockUser);
  };

  const logout = async () => {
    await signOut(auth);
  };

  const value = {
    user,
    loading,
    login,
    logout
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

```

---

## `Web_Panel/src/context/ToastContext.tsx`

```tsx
import React, { createContext, useContext, useState, useCallback, ReactNode } from "react";
import { Toast, ToastType } from "../components/Toast";

interface ToastContextType {
  showToast: (message: string, type: ToastType) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast must be used within ToastProvider");
  }
  return context;
};

interface ToastItem {
  id: string;
  message: string;
  type: ToastType;
}

// Función para generar ID único y robusto
const generateUniqueId = (): string => {
  // Preferir crypto.randomUUID() si está disponible
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback: timestamp + random para garantizar unicidad
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
};

export const ToastProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const showToast = useCallback((message: string, type: ToastType) => {
    const id = generateUniqueId();
    setToasts(prev => [...prev, { id, message, type }]);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2">
        {toasts.map(toast => (
          <Toast
            key={toast.id}
            id={toast.id}
            message={toast.message}
            type={toast.type}
            onClose={() => removeToast(toast.id)}
          />
        ))}
      </div>
    </ToastContext.Provider>
  );
};

```

---

## `Web_Panel/src/examples/beaconConfigExamples.ts`

```typescript
/**
 * GUÍA DE USO - Sistema de Configuración de Balizas
 * 
 * Este archivo contiene ejemplos de código para usar todas las funcionalidades
 * del sistema de configuración de balizas.
 */

import { beaconsService } from "../services/beaconService";
import { BeaconUpdate, Language } from "../types";
import { validateBeaconConfig, parseTags, stringifyTags } from "../utils/beaconValidation";

// ========================================
// EJEMPLO 1: Configurar una baliza nueva
// ========================================
export const ejemploConfigurarBaliza = async (beaconId: string) => {
  const config: BeaconUpdate = {
    mode: "NORMAL",
    arrow: "RIGHT",
    message: "Acceso Principal",
    color: "#00FFAA",
    brightness: 90,
    language: "ES",
    zone: "GRADA-G",
    tags: ["acceso", "principal"]
  };

  try {
    // Validar antes de enviar
    const errors = validateBeaconConfig(config);
    if (errors.length > 0) {
      console.error("Errores de validación:", errors);
      return;
    }

    // Enviar configuración
    await beaconsService.configureBeacon(beaconId, config);
    console.log("✅ Baliza configurada correctamente");
  } catch (error) {
    console.error("❌ Error al configurar baliza:", error);
  }
};

// ========================================
// EJEMPLO 2: Actualizar una baliza existente
// ========================================
export const ejemploActualizarBaliza = async (beaconId: string) => {
  const updates: BeaconUpdate = {
    message: "Nuevo mensaje",
    brightness: 75,
    color: "#FF6600"
  };

  try {
    await beaconsService.updateBeacon(beaconId, updates);
    console.log("✅ Baliza actualizada");
  } catch (error) {
    console.error("❌ Error al actualizar:", error);
  }
};

// ========================================
// EJEMPLO 3: Activar modo evacuación en una zona
// ========================================
export const ejemploEvacuacionZonal = async (zona: string) => {
  const config: BeaconUpdate = {
    mode: "EVACUATION",
    message: "EVACUACIÓN - Siga las flechas",
    evacuationExit: "SALIDA NORTE",
    arrow: "UP",
    color: "#FF0000",
    brightness: 100,
    language: "ES"
  };

  try {
    // Obtener todas las balizas de la zona
    // (En tu código real, filtra las balizas por zona)
    const beaconIds = ["beacon1", "beacon2"]; // IDs de ejemplo
    
    await beaconsService.updateMultipleBeacons(beaconIds, config);
    console.log(`✅ Evacuación activada en zona ${zona}`);
  } catch (error) {
    console.error("❌ Error en evacuación:", error);
  }
};

// ========================================
// EJEMPLO 4: Configurar mensaje multiidioma
// ========================================
export const ejemploMensajeMultiidioma = async () => {
  const mensajes: Record<Language, string> = {
    ES: "Bienvenido al circuito",
    CA: "Benvingut al circuit",
    EN: "Welcome to the circuit",
    FR: "Bienvenue au circuit",
    DE: "Willkommen auf der Rennstrecke",
    IT: "Benvenuto al circuito",
    PT: "Bem-vindo ao circuito"
  };

  // Configurar diferentes balizas con diferentes idiomas
  // Ejemplo comentado de uso:
  // for (const [language, message] of Object.entries(mensajes)) {
  //   await beaconsService.updateBeacon(`beacon-${language}`, {
  //     mode: "NORMAL",
  //     message,
  //     language: language as Language,
  //     color: "#00FFAA",
  //     brightness: 90
  //   });
  // }
  console.log("Mensajes multilenguaje preparados:", mensajes);
};

// ========================================
// EJEMPLO 5: Sistema de tags
// ========================================
export const ejemploGestionTags = () => {
  // Parsear tags desde JSON (desde base de datos)
  const tagsJson = '["vip", "acceso", "principal"]';
  const tags = parseTags(tagsJson);
  console.log("Tags parseados:", tags); // ["vip", "acceso", "principal"]

  // Agregar nuevo tag
  tags.push("prioritario");

  // Convertir a JSON para guardar
  const tagsToSave = stringifyTags(tags);
  console.log("Tags para guardar:", tagsToSave); // '["vip", "acceso", "principal", "prioritario"]'
};

// ========================================
// EJEMPLO 6: Configuración según hora del día
// ========================================
export const ejemploConfiguracionDinamica = async (beaconId: string) => {
  const hora = new Date().getHours();
  
  let config: BeaconUpdate;
  
  if (hora >= 6 && hora < 12) {
    // Mañana: modo normal, mensaje de bienvenida
    config = {
      mode: "NORMAL",
      message: "Buenos días - Acceso Abierto",
      color: "#00FFAA",
      brightness: 80
    };
  } else if (hora >= 12 && hora < 20) {
    // Tarde: modo normal, alta visibilidad
    config = {
      mode: "NORMAL",
      message: "Acceso Principal",
      color: "#00FFAA",
      brightness: 100
    };
  } else {
    // Noche: modo mantenimiento o baja intensidad
    config = {
      mode: "MAINTENANCE",
      message: "Cerrado - Fuera de Horario",
      color: "#808080",
      brightness: 30
    };
  }
  
  await beaconsService.updateBeacon(beaconId, config);
};

// ========================================
// EJEMPLO 7: Configuración según capacidad
// ========================================
export const ejemploConfiguracionPorCapacidad = async (
  beaconId: string,
  ocupacionPorcentaje: number
) => {
  let config: BeaconUpdate;
  
  if (ocupacionPorcentaje < 50) {
    // Baja ocupación: verde, acceso normal
    config = {
      mode: "NORMAL",
      message: "Acceso Libre",
      color: "#00FF00",
      arrow: "RIGHT",
      brightness: 90
    };
  } else if (ocupacionPorcentaje < 80) {
    // Media ocupación: amarillo, precaución
    config = {
      mode: "CONGESTION",
      message: "Afluencia Media - Precaución",
      color: "#FFA500",
      arrow: "DOWN",
      brightness: 100
    };
  } else {
    // Alta ocupación: rojo, acceso cerrado
    config = {
      mode: "EMERGENCY",
      message: "Aforo Completo - Acceso Cerrado",
      color: "#FF0000",
      arrow: "NONE",
      brightness: 100
    };
  }
  
  await beaconsService.updateBeacon(beaconId, config);
};

// ========================================
// EJEMPLO 8: Configuración masiva por lotes
// ========================================
export const ejemploConfiguracionMasiva = async (zonas: string[]) => {
  const configPorZona: Record<string, BeaconUpdate> = {
    "PADDOCK": {
      mode: "NORMAL",
      message: "Zona Paddock - Solo Personal Autorizado",
      color: "#0066FF",
      brightness: 85,
      zone: "PADDOCK",
      tags: ["paddock", "restringido"]
    },
    "GRADA-A": {
      mode: "NORMAL",
      message: "Grada A - Sección Premium",
      color: "#FFD700",
      brightness: 90,
      zone: "GRADA-A",
      tags: ["grada", "premium"]
    },
    "PARKING": {
      mode: "NORMAL",
      message: "Parking - Siga las flechas",
      color: "#00FFAA",
      arrow: "LEFT",
      brightness: 80,
      zone: "PARKING",
      tags: ["parking", "acceso"]
    }
  };

  for (const zona of zonas) {
    const config = configPorZona[zona];
    if (config) {
      // En tu código real, obtener IDs de balizas por zona
      const beaconIds = [`beacon-${zona}-1`, `beacon-${zona}-2`];
      await beaconsService.updateMultipleBeacons(beaconIds, config);
      console.log(`✅ Configurada zona ${zona}`);
    }
  }
};

// ========================================
// EJEMPLO 9: Monitoreo y actualización automática
// ========================================
export const ejemploMonitoreoAutomatico = () => {
  // Suscribirse a cambios de balizas
  const unsubscribe = beaconsService.subscribeToBeacons((beacons) => {
    console.log("📡 Balizas actualizadas:", beacons.length);
    
    // Detectar balizas con batería baja
    const bateriasBajas = beacons.filter(b => b.battery && b.battery < 20);
    if (bateriasBajas.length > 0) {
      console.warn("⚠️ Balizas con batería baja:", bateriasBajas.map(b => b.beaconId));
    }
    
    // Detectar balizas offline
    const offline = beacons.filter(b => !b.online);
    if (offline.length > 0) {
      console.warn("🔴 Balizas offline:", offline.map(b => b.beaconId));
    }
    
    // Detectar balizas sin configurar
    const sinConfigurar = beacons.filter(b => !b.configured);
    if (sinConfigurar.length > 0) {
      console.warn("⚙️ Balizas sin configurar:", sinConfigurar.map(b => b.beaconId));
    }
  }, 5000); // Poll cada 5 segundos
  
  // Limpiar al desmontar
  return unsubscribe;
};

// ========================================
// EJEMPLO 10: Validación completa antes de guardar
// ========================================
export const ejemploValidacionCompleta = (config: BeaconUpdate) => {
  // Validar toda la configuración
  const errors = validateBeaconConfig(config);
  
  if (errors.length > 0) {
    console.error("❌ Errores de validación encontrados:");
    errors.forEach(error => {
      console.error(`  - ${error.field}: ${error.message}`);
    });
    return false;
  }
  
  console.log("✅ Configuración válida");
  return true;
};

// ========================================
// EJEMPLO 11: Resetear baliza a valores por defecto
// ========================================
export const ejemploResetBaliza = async (beaconId: string) => {
  const defaultConfig: BeaconUpdate = {
    mode: "NORMAL",
    arrow: "NONE",
    message: "Sistema Operativo",
    color: "#00FFAA",
    brightness: 90,
    language: "ES",
    evacuationExit: undefined,
    zone: "GENERAL",
    tags: []
  };
  
  await beaconsService.updateBeacon(beaconId, defaultConfig);
  console.log("✅ Baliza reseteada a valores por defecto");
};

// ========================================
// EJEMPLO 12: Configuración por evento especial
// ========================================
export const ejemploEventoEspecial = async (nombreEvento: string) => {
  const configsEvento: Record<string, BeaconUpdate> = {
    "CARRERA_F1": {
      mode: "NORMAL",
      message: "Gran Premio F1 - Siga las indicaciones",
      color: "#FF0000",
      brightness: 100,
      tags: ["evento", "f1", "carrera"]
    },
    "CONCIERTO": {
      mode: "NORMAL",
      message: "Concierto en Vivo - Zona de Espectadores",
      color: "#9B59B6",
      brightness: 95,
      tags: ["evento", "concierto", "entretenimiento"]
    },
    "TOUR_GUIADO": {
      mode: "NORMAL",
      message: "Tour del Circuito - Punto de Encuentro",
      color: "#3498DB",
      brightness: 85,
      tags: ["evento", "tour", "visita"]
    }
  };
  
  const config = configsEvento[nombreEvento];
  if (config) {
    // Aplicar a todas las balizas relevantes
    console.log(`🎉 Configurando evento: ${nombreEvento}`);
  }
};

/**
 * NOTAS IMPORTANTES:
 * 
 * 1. Siempre valida la configuración antes de enviarla
 * 2. El campo 'configured' se marca automáticamente como true al guardar
 * 3. Tags se almacenan como JSON en la base de datos
 * 4. Usa evacuationExit solo en modo EVACUATION
 * 5. El mensaje puede estar vacío (usará predeterminado según modo/idioma)
 * 6. El brillo debe estar entre 0-100
 * 7. Color debe ser hexadecimal válido (#RRGGBB)
 * 8. Zone es importante para evacuaciones zonales
 * 9. Los cambios se envían tanto a la baliza como a la base de datos
 * 10. Polling automático cada 4 segundos por defecto
 */

export default {
  ejemploConfigurarBaliza,
  ejemploActualizarBaliza,
  ejemploEvacuacionZonal,
  ejemploMensajeMultiidioma,
  ejemploGestionTags,
  ejemploConfiguracionDinamica,
  ejemploConfiguracionPorCapacidad,
  ejemploConfiguracionMasiva,
  ejemploMonitoreoAutomatico,
  ejemploValidacionCompleta,
  ejemploResetBaliza,
  ejemploEventoEspecial
};

```

---

## `Web_Panel/src/firebase/config.ts`

```typescript
export const firebaseConfig = {
  apiKey: "AIzaSyACSJmNU5y01YaTBneqHlDannKatrSs1XA",
  authDomain: "panel-de-control-georacing.firebaseapp.com",
  projectId: "panel-de-control-georacing",
  storageBucket: "panel-de-control-georacing.firebasestorage.app",
  messagingSenderId: "839966103516",
  appId: "1:839966103516:web:da41a4a9120806840ee119"
};

```

---

## `Web_Panel/src/firebase/firebaseApp.ts`

```typescript
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { firebaseConfig } from "./config";

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

```

---

## `Web_Panel/src/hooks/useBeacons.ts`

```typescript
import { useState, useEffect } from "react";
import { Beacon } from "../types";
import { beaconsService } from "../services/beaconService";
import { api } from "../services/apiClient";

export const useBeacons = () => {
  const [beacons, setBeacons] = useState<Beacon[]>([]);
  const [loading, setLoading] = useState(true);

  const refresh = async () => {
    try {
      const data = await api.getBeacons();
      setBeacons(data);
    } catch (e) {
      // opcional: manejar error
    }
  };

  useEffect(() => {
    setLoading(true);
    const unsubscribe = beaconsService.subscribeToBeacons((beaconsData) => {
      setBeacons(beaconsData);
      setLoading(false);
    }, 3000); // Adjusted interval slightly
    return () => unsubscribe();
  }, []);

  return { beacons, loading, refresh };
};

```

---

## `Web_Panel/src/hooks/useCircuitState.ts`

```typescript
import { useState, useEffect } from 'react';
import { api } from '../services/apiClient';

export function useCircuitState(intervalMs = 3000) {
    const [state, setState] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let mounted = true;

        const fetchState = async () => {
            try {
                const data = await api.getCircuitState();
                if (mounted && data) setState(data);
            } catch (err) {
                console.error("Error polling circuit state:", err);
            } finally {
                if (mounted) setLoading(false);
            }
        };

        fetchState(); // Initial call
        const interval = setInterval(fetchState, intervalMs);

        return () => {
            mounted = false;
            clearInterval(interval);
        };
    }, [intervalMs]);

    return { state, loading };
}

```

---

## `Web_Panel/src/hooks/useNewBeaconDetection.ts`

```typescript
import { useState, useEffect } from "react";
import { beaconDetectionService, NewBeaconDetected } from "../services/beaconDetectionService";

export const useNewBeaconDetection = () => {
  const [newBeacons, setNewBeacons] = useState<NewBeaconDetected[]>([]);
  const [hasNewBeacons, setHasNewBeacons] = useState(false);

  useEffect(() => {
    const unsubscribe = beaconDetectionService.subscribeToNewBeacons((detected) => {
      setNewBeacons(detected);
      setHasNewBeacons(detected.length > 0);
    });

    return () => unsubscribe();
  }, []);

  const clearNewBeacons = () => {
    setNewBeacons([]);
    setHasNewBeacons(false);
  };

  return { newBeacons, hasNewBeacons, clearNewBeacons };
};

```

---

## `Web_Panel/src/hooks/useZones.ts`

```typescript
import { useMemo } from "react";
import { Beacon, ZoneInfo } from "../types";

export const useZones = (beacons: Beacon[]): ZoneInfo[] => {
  return useMemo(() => {
    const zoneMap = new Map<string, ZoneInfo>();

    beacons.forEach((beacon) => {
      if (!beacon.zone) return;
      const existing = zoneMap.get(beacon.zone);
      
      if (existing) {
        existing.totalBeacons++;
        if (beacon.mode === "EVACUATION") {
          existing.evacuationCount++;
        }
      } else {
        zoneMap.set(beacon.zone, {
          zone: beacon.zone,
          totalBeacons: 1,
          evacuationCount: beacon.mode === "EVACUATION" ? 1 : 0
        });
      }
    });

    return Array.from(zoneMap.values()).sort((a, b) => a.zone.localeCompare(b.zone));
  }, [beacons]);
};

```

---

## `Web_Panel/src/index.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}

* {
  box-sizing: border-box;
}

::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #1a1a1a;
}

::-webkit-scrollbar-thumb {
  background: #3a3a3a;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #4a4a4a;
}

@keyframes slide-up {
  from {
    transform: translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.animate-slide-up {
  animation: slide-up 0.3s ease-out;
}

```

---

## `Web_Panel/src/main.tsx`

```tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)

```

---

## `Web_Panel/src/pages/BeaconDetail.tsx`

```tsx
import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Layout } from "../components/Layout";
import { BeaconPreview } from "../components/BeaconPreview";
import { BeaconMetricsCard } from "../components/BeaconMetricsCard";
import { CommandPanel } from "../components/CommandPanel";
import { useBeacons } from "../hooks/useBeacons";
import { beaconsService } from "../services/beaconService";
import { BeaconMode, ArrowDirection, Language } from "../types";
import { ArrowLeft, Save, Wrench, RotateCcw } from "lucide-react";

export const BeaconDetail: React.FC = () => {
  const { beaconId } = useParams<{ beaconId: string }>();
  const navigate = useNavigate();
  const { beacons } = useBeacons();
  
  const beacon = beacons.find(b => b.beaconId === beaconId);

  const [mode, setMode] = useState<BeaconMode>("NORMAL");
  const [arrow, setArrow] = useState<ArrowDirection>("NONE");
  const [message, setMessage] = useState("");
  const [color, setColor] = useState("#00FFAA");
  const [brightness, setBrightness] = useState(90);
  const [language, setLanguage] = useState<Language>("ES");
  const [evacuationExit, setEvacuationExit] = useState("");
  const [zone, setZone] = useState("");
  const [tags, setTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (beacon) {
      setMode(beacon.mode || "NORMAL");
      setArrow(beacon.arrow || "NONE");
      setMessage(beacon.message || "");
      setColor(beacon.color || "#00FFAA");
      setBrightness(beacon.brightness ?? 90);
      setLanguage(beacon.language || "ES");
      setEvacuationExit(beacon.evacuationExit || "");
      setZone(beacon.zone || "");
      setTags(beacon.tags || []);
    }
  }, [beacon]);

  if (!beacon) {
    return (
      <Layout>
        <div className="text-white">Baliza no encontrada</div>
      </Layout>
    );
  }

  const handleSave = async () => {
    setSaving(true);
    try {
      await beaconsService.updateBeacon(beacon.beaconId, {
        mode,
        arrow,
        message: message.trim() || undefined,
        color,
        brightness,
        language,
        evacuationExit: evacuationExit.trim() || undefined,
        zone: zone.trim() || undefined,
        tags: tags.length > 0 ? tags : undefined
      });
      alert("✅ Baliza actualizada correctamente");
      // No navegar automáticamente, permitir seguir editando
    } catch (error) {
      console.error("Error al guardar:", error);
      alert("❌ Error al guardar la baliza");
    } finally {
      setSaving(false);
    }
  };

  const handleAddTag = () => {
    if (tagInput.trim() && !tags.includes(tagInput.trim())) {
      setTags([...tags, tagInput.trim()]);
      setTagInput("");
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setTags(tags.filter(t => t !== tagToRemove));
  };

  const handleSetMaintenance = async () => {
    setSaving(true);
    try {
      await beaconsService.updateBeacon(beacon.beaconId, {
        mode: "MAINTENANCE"
      });
      setMode("MAINTENANCE");
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setSaving(false);
    }
  };

  const handleResetToNormal = async () => {
    setSaving(true);
    try {
      await beaconsService.updateBeacon(beacon.beaconId, {
        mode: "NORMAL",
        message: "Acceso Principal",
        color: "#00FFAA",
        brightness: 90,
        arrow: "RIGHT"
      });
      setMode("NORMAL");
      setMessage("Acceso Principal");
      setColor("#00FFAA");
      setBrightness(90);
      setArrow("RIGHT");
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Layout>
      <div className="max-w-6xl mx-auto space-y-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate("/dashboard")}
            className="p-2 hover:bg-dark-700 rounded-lg transition-colors"
            title="Volver al dashboard"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h1 className="text-2xl font-bold text-white">Editar Baliza: {beacon.beaconId}</h1>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="space-y-6">
            <BeaconMetricsCard beacon={beacon} />

            <div className="bg-dark-800 p-6 rounded-lg space-y-4">
              <h2 className="text-lg font-semibold text-white mb-4">Configuración Editable</h2>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Modo</label>
                <select
                  value={mode}
                  onChange={(e) => setMode(e.target.value as BeaconMode)}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  title="Modo de operación"
                >
                  <option value="UNCONFIGURED">Sin configurar</option>
                  <option value="NORMAL">Normal</option>
                  <option value="CONGESTION">Congestión</option>
                  <option value="EMERGENCY">Emergencia</option>
                  <option value="EVACUATION">Evacuación</option>
                  <option value="MAINTENANCE">Mantenimiento</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Flecha</label>
                <select
                  value={arrow}
                  onChange={(e) => setArrow(e.target.value as ArrowDirection)}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  title="Dirección de la flecha"
                >
                  <option value="NONE">Sin flecha</option>
                  <option value="UP">↑ Arriba</option>
                  <option value="DOWN">↓ Abajo</option>
                  <option value="LEFT">← Izquierda</option>
                  <option value="RIGHT">→ Derecha</option>
                  <option value="UP_LEFT">↖ Arriba-Izquierda</option>
                  <option value="UP_RIGHT">↗ Arriba-Derecha</option>
                  <option value="DOWN_LEFT">↙ Abajo-Izquierda</option>
                  <option value="DOWN_RIGHT">↘ Abajo-Derecha</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Mensaje</label>
                <textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  rows={3}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Mensaje a mostrar..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Color</label>
                <div className="flex gap-2">
                  <input
                    type="color"
                    value={color}
                    onChange={(e) => setColor(e.target.value)}
                    className="h-10 w-20 bg-dark-700 border border-dark-600 rounded cursor-pointer"
                    title="Selector de color"
                  />
                  <input
                    type="text"
                    value={color}
                    onChange={(e) => setColor(e.target.value)}
                    className="flex-1 px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="#RRGGBB"
                    title="Color en hexadecimal"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Brillo: {brightness}%
                </label>
                <input
                  type="range"
                  min="0"
                  max="100"
                  value={brightness}
                  onChange={(e) => setBrightness(parseInt(e.target.value))}
                  className="w-full"
                  title="Control de brillo"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Idioma</label>
                <select
                  value={language}
                  onChange={(e) => setLanguage(e.target.value as Language)}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  title="Idioma de los mensajes"
                >
                  <option value="ES">Español</option>
                  <option value="CA">Catalán</option>
                  <option value="EN">Inglés</option>
                  <option value="FR">Francés</option>
                  <option value="DE">Alemán</option>
                  <option value="IT">Italiano</option>
                  <option value="PT">Portugués</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Salida de Evacuación</label>
                <input
                  type="text"
                  value={evacuationExit}
                  onChange={(e) => setEvacuationExit(e.target.value)}
                  maxLength={100}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Ej: SALIDA 3"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Zona</label>
                <input
                  type="text"
                  value={zone}
                  onChange={(e) => setZone(e.target.value)}
                  maxLength={50}
                  className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Ej: GRADA-G, PADDOCK"
                />
              </div>

              {/* Sistema de Tags */}
              <div className="col-span-2">
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Etiquetas (Tags)
                </label>
                <div className="flex gap-2 mb-2">
                  <input
                    type="text"
                    value={tagInput}
                    onChange={(e) => setTagInput(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                    className="flex-1 px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Agregar etiqueta (presione Enter)"
                  />
                  <button
                    type="button"
                    onClick={handleAddTag}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded transition-colors"
                  >
                    Agregar
                  </button>
                </div>
                {tags.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {tags.map((tag, index) => (
                      <span
                        key={index}
                        className="inline-flex items-center gap-2 px-3 py-1 bg-blue-600/20 text-blue-400 rounded-full text-sm"
                      >
                        {tag}
                        <button
                          type="button"
                          onClick={() => handleRemoveTag(tag)}
                          className="hover:text-blue-300"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => navigate("/dashboard")}
                className="flex-1 flex items-center justify-center gap-2 py-3 bg-dark-700 hover:bg-dark-600 text-white font-semibold rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5" />
                Volver al Dashboard
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="flex-1 flex items-center justify-center gap-2 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-800 text-white font-semibold rounded-lg transition-colors"
              >
                <Save className="w-5 h-5" />
                {saving ? "Guardando..." : "Guardar Cambios"}
              </button>
            </div>

            <div className="flex gap-3">
              <button
                onClick={handleSetMaintenance}
                disabled={saving}
                className="flex-1 flex items-center justify-center gap-2 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors"
              >
                <Wrench className="w-4 h-4" />
                Poner en Mantenimiento
              </button>
              <button
                onClick={handleResetToNormal}
                disabled={saving}
                className="flex-1 flex items-center justify-center gap-2 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors"
              >
                <RotateCcw className="w-4 h-4" />
                Reset a Normal
              </button>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-dark-800 p-6 rounded-lg">
              <h2 className="text-lg font-semibold text-white mb-4">Vista Previa</h2>
              <BeaconPreview
                mode={mode}
                arrow={arrow}
                message={message}
                color={color}
                language={language}
                evacuationExit={evacuationExit}
              />
            </div>

            <CommandPanel beaconId={beacon.beaconId} />
          </div>
        </div>
      </div>
    </Layout>
  );
};

```

---

## `Web_Panel/src/pages/Beacons.tsx`

```tsx
import React, { useState, useMemo } from "react";
import { Link } from "react-router-dom";
import { Layout } from "../components/Layout";
import { NewBeaconModal } from "../components/NewBeaconModal";
import { BeaconEditModal } from "../components/BeaconEditModal";
import { BeaconMetricsCard } from "../components/BeaconMetricsCard";
import { useBeacons } from "../hooks/useBeacons";
import { useNewBeaconDetection } from "../hooks/useNewBeaconDetection";
import { beaconsService } from "../services/beaconService";
import { BeaconUpdate, BeaconMode, ArrowDirection, Language, Beacon } from "../types";
import { getModeColor, BeaconModeStrict } from "../utils/beaconHelpers";
import { Search, Circle, Edit, LayoutGrid, List, RotateCcw } from "lucide-react";
import { useToast } from "../context/ToastContext";

export const Beacons: React.FC = () => {
    const { beacons, loading, refresh } = useBeacons();
    const { newBeacons, clearNewBeacons } = useNewBeaconDetection();
    const { showToast } = useToast();
    const [showNewBeaconModal, setShowNewBeaconModal] = useState(false);
    const [showEditModal, setShowEditModal] = useState(false);
    const [selectedBeaconForEdit, setSelectedBeaconForEdit] = useState<Beacon | null>(null);
    const [selectedNewBeacon, setSelectedNewBeacon] = useState<number>(0);
    const [selectedBeacons, setSelectedBeacons] = useState<Set<string>>(new Set());
    const [searchTerm, setSearchTerm] = useState<string>("");
    const [filterZone, setFilterZone] = useState<string>("");
    const [filterMode, setFilterMode] = useState<BeaconModeStrict | "all">("all");
    const [onlineOnly, setOnlineOnly] = useState(false);
    const [viewMode, setViewMode] = useState<'table' | 'cards'>('cards');

    const [bulkMode, setBulkMode] = useState<BeaconMode>("NORMAL");
    const [bulkArrow, setBulkArrow] = useState<ArrowDirection>("NONE");
    const [bulkMessage, setBulkMessage] = useState("");
    const [bulkColor, setBulkColor] = useState("#00FFAA");
    const [bulkBrightness, setBulkBrightness] = useState(90);
    const [bulkLanguage, setBulkLanguage] = useState<Language>("ES");
    const [bulkEvacuationExit, setBulkEvacuationExit] = useState("");

    const zones = useMemo(() => {
        return Array.from(new Set(beacons.map(b => b.zone))).sort();
    }, [beacons]);

    const filteredBeacons = useMemo(() => {
        return beacons.filter(beacon => {
            // Búsqueda por beaconId o name
            if (searchTerm) {
                const searchLower = searchTerm.toLowerCase();
                const matchesId = beacon.beaconId.toLowerCase().includes(searchLower);
                const matchesName = beacon.name?.toLowerCase().includes(searchLower);
                if (!matchesId && !matchesName) {
                    return false;
                }
            }
            // Filtro por zona
            if (filterZone && beacon.zone !== filterZone) {
                return false;
            }
            // Filtro por modo (solo si no es "all" y el modo no es null)
            if (filterMode && filterMode !== "all") {
                if (!beacon.mode || beacon.mode !== (filterMode as BeaconMode)) {
                    return false;
                }
            }
            // Filtro solo online
            if (onlineOnly && !beacon.online) {
                return false;
            }
            return true;
        });
    }, [beacons, searchTerm, filterZone, filterMode, onlineOnly]);

    const toggleBeaconSelection = (beaconId: string) => {
        const newSelected = new Set(selectedBeacons);
        if (newSelected.has(beaconId)) {
            newSelected.delete(beaconId);
        } else {
            newSelected.add(beaconId);
        }
        setSelectedBeacons(newSelected);
    };

    const toggleSelectAll = () => {
        if (selectedBeacons.size === filteredBeacons.length) {
            setSelectedBeacons(new Set());
        } else {
            setSelectedBeacons(new Set(filteredBeacons.map(b => b.beaconId)));
        }
    };

    const handleApplyBulkUpdate = async () => {
        if (selectedBeacons.size === 0) return;

        const updates: BeaconUpdate = {
            mode: bulkMode,
            arrow: bulkArrow,
            message: bulkMessage || undefined,
            color: bulkColor,
            brightness: bulkBrightness,
            language: bulkLanguage,
            evacuationExit: bulkEvacuationExit || undefined
        };

        try {
            showToast(`Enviando configuración a ${selectedBeacons.size} balizas...`, "info");
            await beaconsService.updateMultipleBeacons(Array.from(selectedBeacons), updates);
            showToast(`✅ Configuración aplicada a ${selectedBeacons.size} balizas`, "success");
            setSelectedBeacons(new Set());
            await refresh();
        } catch (error) {
            console.error("Error aplicando configuración masiva:", error);
            showToast("❌ Error al enviar la configuración", "error");
        }
    };

    const handleRestartAll = async () => {
        if (!confirm(`⚠️⚠️⚠️ ¿Seguro que quieres REINICIAR TODOS LOS SISTEMAS WINDOWS?\n\n🔴 ESTO REINICIARÁ ${beacons.length} ORDENADORES COMPLETOS.\n\nTodos los sistemas se apagarán y volverán a encender.\n\n¿CONTINUAR?`)) {
            return;
        }

        try {
            showToast(`Enviando comandos de reinicio a ${beacons.length} balizas...`, "warning");
            const count = await beaconsService.restartAllBeacons();
            showToast(`✅ Comando de reinicio enviado a ${count} balizas`, "success");
        } catch (error) {
            console.error("Error reiniciando balizas:", error);
            showToast("❌ Error al enviar comandos de reinicio", "error");
        }
    };

    const handleNewBeaconClick = () => {
        if (newBeacons.length > 0) {
            setSelectedNewBeacon(0);
            setShowNewBeaconModal(true);
        }
    };

    const handleConfigured = () => {
        if (selectedNewBeacon < newBeacons.length - 1) {
            setSelectedNewBeacon(selectedNewBeacon + 1);
        } else {
            setShowNewBeaconModal(false);
            clearNewBeacons();
        }
    };

    if (loading) {
        return (
            <Layout>
                <div className="text-white text-center">Cargando balizas...</div>
            </Layout>
        );
    }

    return (
        <Layout onNewBeaconClick={handleNewBeaconClick}>
            {showNewBeaconModal && newBeacons[selectedNewBeacon] && (
                <NewBeaconModal
                    beacon={newBeacons[selectedNewBeacon]}
                    onClose={() => {
                        setShowNewBeaconModal(false);
                        clearNewBeacons();
                    }}
                    onConfigured={handleConfigured}
                />
            )}
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <h1 className="text-2xl font-bold text-white">Gestión de Balizas</h1>
                    <div className="flex items-center gap-4">
                        <button
                            onClick={handleRestartAll}
                            className="flex items-center gap-2 px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white font-semibold rounded-lg transition-colors"
                            title="Reiniciar todos los sistemas Windows de las balizas"
                        >
                            <RotateCcw className="w-5 h-5" />
                            Reiniciar Todos (Windows)
                        </button>
                        <div className="text-sm text-gray-400">
                            Total: {beacons.length} | Online: {beacons.filter(b => b.online).length}
                        </div>
                        <div className="flex bg-dark-700 rounded-lg p-1">
                            <button
                                onClick={() => setViewMode('cards')}
                                className={`p-2 rounded transition-colors ${viewMode === 'cards' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'
                                    }`}
                                title="Vista de tarjetas"
                            >
                                <LayoutGrid className="w-5 h-5" />
                            </button>
                            <button
                                onClick={() => setViewMode('table')}
                                className={`p-2 rounded transition-colors ${viewMode === 'table' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'
                                    }`}
                                title="Vista de tabla"
                            >
                                <List className="w-5 h-5" />
                            </button>
                        </div>
                    </div>
                </div>

                <div className="bg-dark-800 p-4 rounded-lg space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div className="relative">
                            <Search className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
                            <input
                                type="text"
                                value={searchTerm}
                                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
                                placeholder="Buscar baliza por nombre o ID"
                                className="w-full pl-10 pr-4 py-2 bg-dark-700 border border-dark-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <select
                            value={filterZone}
                            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFilterZone(e.target.value)}
                            className="px-4 py-2 bg-dark-700 border border-dark-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">Todas las zonas</option>
                            {zones.map(zone => (
                                <option key={zone ?? ""} value={zone ?? ""}>{zone ?? "Sin zona"}</option>
                            ))}
                        </select>

                        <select
                            value={filterMode}
                            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFilterMode(e.target.value as BeaconModeStrict | "all")}
                            className="px-4 py-2 bg-dark-700 border border-dark-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="all">Todos los modos</option>
                            <option value="NORMAL">Normal</option>
                            <option value="EMERGENCY">Emergencia</option>
                            <option value="EVACUATION">Evacuación</option>
                            <option value="MAINTENANCE">Mantenimiento</option>
                            <option value="CONGESTION">Congestión</option>
                            <option value="UNCONFIGURED">Sin configurar</option>
                        </select>

                        <label className="flex items-center gap-2 px-4 py-2 bg-dark-700 border border-dark-600 rounded-lg text-white cursor-pointer">
                            <input
                                type="checkbox"
                                checked={onlineOnly}
                                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setOnlineOnly(e.target.checked)}
                                className="w-4 h-4"
                            />
                            <span>Solo online</span>
                        </label>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <div className="lg:col-span-2">
                        {viewMode === 'cards' ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                                {Array.isArray(filteredBeacons) ? filteredBeacons.map(beacon => (
                                    <div key={beacon.beaconId} className="relative">
                                        <BeaconMetricsCard
                                            beacon={beacon}
                                            selected={selectedBeacons.has(beacon.beaconId)}
                                            onSelect={() => toggleBeaconSelection(beacon.beaconId)}
                                            onClick={() => {
                                                setSelectedBeaconForEdit(beacon);
                                                setShowEditModal(true);
                                            }}
                                        />
                                    </div>
                                )) : null}
                            </div>
                        ) : (
                            <div className="bg-dark-800 rounded-lg overflow-hidden">
                                <div className="overflow-x-auto">
                                    <table className="w-full">
                                        <thead className="bg-dark-700">
                                            <tr>
                                                <th className="px-4 py-3 text-left">
                                                    <input
                                                        type="checkbox"
                                                        checked={selectedBeacons.size === filteredBeacons.length && filteredBeacons.length > 0}
                                                        onChange={toggleSelectAll}
                                                        className="w-4 h-4 rounded border-gray-600 bg-dark-700 text-blue-600 focus:ring-blue-500 focus:ring-offset-dark-800"
                                                    />
                                                </th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Estado</th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Baliza ID</th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Zona</th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Modo</th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Flecha</th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Mensaje</th>
                                                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-300">Acciones</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-dark-700">
                                            {filteredBeacons.map(beacon => (
                                                <tr key={beacon.beaconId} className="hover:bg-dark-700/50">
                                                    <td className="px-4 py-3">
                                                        <input
                                                            type="checkbox"
                                                            checked={selectedBeacons.has(beacon.beaconId)}
                                                            onChange={() => toggleBeaconSelection(beacon.beaconId)}
                                                            className="w-4 h-4 rounded border-gray-600 bg-dark-700 text-blue-600 focus:ring-blue-500 focus:ring-offset-dark-800"
                                                        />
                                                    </td>
                                                    <td className="px-4 py-3">
                                                        <Circle
                                                            className={`w-3 h-3 ${beacon.online ? 'text-green-500 fill-green-500' : 'text-red-500 fill-red-500'}`}
                                                        />
                                                    </td>
                                                    <td className="px-4 py-3 text-sm text-white font-mono">{beacon.beaconId}</td>
                                                    <td className="px-4 py-3 text-sm text-gray-300">{beacon.zone}</td>
                                                    <td className="px-4 py-3">
                                                        <span className={`px-2 py-1 text-xs rounded-full ${beacon.mode ? getModeColor(beacon.mode as BeaconModeStrict) : "bg-gray-500/20 text-gray-400"}`}>
                                                            {beacon.mode ?? "Modo desconocido"}
                                                        </span>
                                                    </td>
                                                    <td className="px-4 py-3 text-sm text-gray-300">
                                                        {beacon.arrow === "UP" && "↑ Arriba"}
                                                        {beacon.arrow === "DOWN" && "↓ Abajo"}
                                                        {beacon.arrow === "LEFT" && "← Izquierda"}
                                                        {beacon.arrow === "RIGHT" && "→ Derecha"}
                                                        {beacon.arrow === "UP_LEFT" && "↖ Arriba-Izq"}
                                                        {beacon.arrow === "UP_RIGHT" && "↗ Arriba-Der"}
                                                        {beacon.arrow === "DOWN_LEFT" && "↙ Abajo-Izq"}
                                                        {beacon.arrow === "DOWN_RIGHT" && "↘ Abajo-Der"}
                                                        {(!beacon.arrow || beacon.arrow === "NONE") && "-"}
                                                    </td>
                                                    <td className="px-4 py-3 text-sm text-gray-300 max-w-xs truncate">{beacon.message}</td>
                                                    <td className="px-4 py-3">
                                                        <Link
                                                            to={`/beacons/${beacon.beaconId}`}
                                                            className="inline-flex items-center gap-1 px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded transition-colors"
                                                        >
                                                            <Edit className="w-3 h-3" />
                                                            Editar
                                                        </Link>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        )}
                    </div>

                    <div className="bg-dark-800 p-4 rounded-lg h-fit space-y-4 sticky top-4">
                        <div className="flex items-center justify-between">
                            <h3 className="text-lg font-semibold text-white">
                                Acciones Masivas
                            </h3>
                            {selectedBeacons.size > 0 && (
                                <span className="px-2 py-1 bg-blue-600 text-white text-xs rounded-full">
                                    {selectedBeacons.size} seleccionadas
                                </span>
                            )}
                        </div>

                        {selectedBeacons.size > 0 ? (
                            <div className="space-y-3">
                                {viewMode === 'cards' && (
                                    <button
                                        onClick={() => setSelectedBeacons(new Set())}
                                        className="w-full py-1 text-sm text-gray-400 hover:text-white border border-gray-600 rounded mb-2"
                                    >
                                        Deseleccionar todas
                                    </button>
                                )}

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Modo</label>
                                    <select
                                        value={bulkMode}
                                        onChange={(e) => setBulkMode(e.target.value as BeaconMode)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <option value="NORMAL">Normal</option>
                                        <option value="CONGESTION">Congestión</option>
                                        <option value="EMERGENCY">Emergencia</option>
                                        <option value="EVACUATION">Evacuación</option>
                                        <option value="MAINTENANCE">Mantenimiento</option>
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Flecha</label>
                                    <select
                                        value={bulkArrow}
                                        onChange={(e) => setBulkArrow(e.target.value as ArrowDirection)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <option value="NONE">Ninguna</option>
                                        <option value="LEFT">Izquierda</option>
                                        <option value="RIGHT">Derecha</option>
                                        <option value="UP">Arriba</option>
                                        <option value="DOWN">Abajo</option>
                                        <option value="UP_LEFT">Arriba Izquierda</option>
                                        <option value="UP_RIGHT">Arriba Derecha</option>
                                        <option value="DOWN_LEFT">Abajo Izquierda</option>
                                        <option value="DOWN_RIGHT">Abajo Derecha</option>
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Mensaje</label>
                                    <input
                                        type="text"
                                        value={bulkMessage}
                                        onChange={(e) => setBulkMessage(e.target.value)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                        placeholder="Mensaje..."
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Color</label>
                                    <input
                                        type="color"
                                        value={bulkColor}
                                        onChange={(e) => setBulkColor(e.target.value)}
                                        className="w-full h-10 bg-dark-700 border border-dark-600 rounded cursor-pointer"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">
                                        Brillo: {bulkBrightness}%
                                    </label>
                                    <input
                                        type="range"
                                        min="0"
                                        max="100"
                                        value={bulkBrightness}
                                        onChange={(e) => setBulkBrightness(parseInt(e.target.value))}
                                        className="w-full"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Idioma</label>
                                    <select
                                        value={bulkLanguage}
                                        onChange={(e) => setBulkLanguage(e.target.value as Language)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <option value="ES">Español</option>
                                        <option value="CAT">Catalán</option>
                                        <option value="EN">Inglés</option>
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Salida Evacuación</label>
                                    <input
                                        type="text"
                                        value={bulkEvacuationExit}
                                        onChange={(e) => setBulkEvacuationExit(e.target.value)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                        placeholder="Ej: SALIDA 3"
                                    />
                                </div>

                                <button
                                    onClick={handleApplyBulkUpdate}
                                    className="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded transition-colors"
                                >
                                    Aplicar a seleccionadas
                                </button>
                            </div>
                        ) : (
                            <div className="text-center py-8">
                                <p className="text-gray-400 text-sm mb-4">
                                    Selecciona balizas para aplicar cambios masivos
                                </p>
                                {viewMode === 'cards' && (
                                    <button
                                        onClick={toggleSelectAll}
                                        className="text-blue-400 hover:text-blue-300 text-sm underline"
                                    >
                                        {selectedBeacons.size === filteredBeacons.length ? "Deseleccionar todas" : "Seleccionar todas"}
                                    </button>
                                )}
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Modal de edición de baliza */}
            {showEditModal && selectedBeaconForEdit && (
                <BeaconEditModal
                    beacon={selectedBeaconForEdit}
                    onClose={() => {
                        setShowEditModal(false);
                        setSelectedBeaconForEdit(null);
                    }}
                    onSaved={async () => {
                        await refresh();
                    }}
                />
            )}
        </Layout>
    );
};

```

---

## `Web_Panel/src/pages/CircuitState.tsx`

```tsx
import React, { useEffect, useState } from "react";
import { Layout } from "../components/Layout";
import { api } from "../services/apiClient";
import { Activity, ShieldAlert, Flag, Zap } from "lucide-react";
import { useToast } from "../context/ToastContext";

export const CircuitState: React.FC = () => {
    const [state, setState] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const { showToast } = useToast();

    const fetchState = async () => {
        try {
            const data = await api.getCircuitState();
            setState(data);
        } catch (error) {
            console.error("Error fetching circuit state:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchState();
        const interval = setInterval(fetchState, 5000);
        return () => clearInterval(interval);
    }, []);

    const handleModeChange = async (newMode: string) => {
        try {
            await api.setCircuitState(newMode);
            showToast(`Estado del circuito cambiado a ${newMode}`, "success");
            fetchState();
        } catch (error) {
            console.error("Error updating circuit state:", error);
            showToast("Error al actualizar estado", "error");
        }
    };

    if (loading) {
        return (
            <Layout>
                <div className="text-white text-center">Cargando estado del circuito...</div>
            </Layout>
        );
    }

    return (
        <Layout>
            <div className="space-y-8">
                <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                    <Activity className="w-6 h-6 text-green-500" />
                    Estado del Circuito
                </h1>

                {/* Current State Card */}
                <div className="bg-dark-800 p-8 rounded-lg border border-dark-700 text-center">
                    <h2 className="text-gray-400 text-lg mb-4">ESTADO ACTUAL</h2>
                    <div className="text-6xl font-black text-white tracking-wider mb-4">
                        {state?.global_mode || state?.mode || "NORMAL"}
                    </div>
                    <p className="text-gray-500">
                        Última actualización: {state?.updated_at ? new Date(state.updated_at).toLocaleString() : "Desconocido"}
                    </p>
                </div>

                {/* Controls */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <button
                        onClick={() => handleModeChange("NORMAL")}
                        className={`p-6 rounded-lg border-2 transition-all flex flex-col items-center gap-4 ${state?.global_mode === "NORMAL"
                            ? "bg-green-500/20 border-green-500 text-green-400"
                            : "bg-dark-800 border-dark-700 text-gray-400 hover:border-green-500/50"
                            }`}
                    >
                        <Flag className="w-12 h-12" />
                        <span className="text-xl font-bold">NORMAL</span>
                        <span className="text-sm opacity-70">Carrera en curso</span>
                    </button>

                    <button
                        onClick={() => handleModeChange("SAFETY_CAR")}
                        className={`p-6 rounded-lg border-2 transition-all flex flex-col items-center gap-4 ${state?.global_mode === "SAFETY_CAR"
                            ? "bg-yellow-500/20 border-yellow-500 text-yellow-400"
                            : "bg-dark-800 border-dark-700 text-gray-400 hover:border-yellow-500/50"
                            }`}
                    >
                        <ShieldAlert className="w-12 h-12" />
                        <span className="text-xl font-bold">SAFETY CAR</span>
                        <span className="text-sm opacity-70">Pista neutralizada</span>
                    </button>

                    <button
                        onClick={() => handleModeChange("RED_FLAG")}
                        className={`p-6 rounded-lg border-2 transition-all flex flex-col items-center gap-4 ${state?.global_mode === "RED_FLAG"
                            ? "bg-red-500/20 border-red-500 text-red-400"
                            : "bg-dark-800 border-dark-700 text-gray-400 hover:border-red-500/50"
                            }`}
                    >
                        <Zap className="w-12 h-12" />
                        <span className="text-xl font-bold">RED FLAG</span>
                        <span className="text-sm opacity-70">Carrera detenida</span>
                    </button>
                </div>

                <div className="bg-dark-800 p-6 rounded-lg border border-dark-700">
                    <h3 className="text-lg font-bold text-white mb-4">Información Adicional (En Vivo)</h3>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                        <div className="flex justify-between p-3 bg-dark-700 rounded">
                            <span className="text-gray-400">Temperatura Pista</span>
                            <span className="text-white font-mono text-yellow-400">{state?.temperature || "--"}</span>
                        </div>
                        <div className="flex justify-between p-3 bg-dark-700 rounded">
                            <span className="text-gray-400">Humedad</span>
                            <span className="text-white font-mono text-blue-400">{state?.humidity || "--"}</span>
                        </div>
                        <div className="flex justify-between p-3 bg-dark-700 rounded">
                            <span className="text-gray-400">Viento</span>
                            <span className="text-white font-mono">{state?.wind || "--"}</span>
                        </div>
                        <div className="flex justify-between p-3 bg-dark-700 rounded">
                            <span className="text-gray-400">Previsión</span>
                            <span className="text-white font-mono">{state?.forecast || "--"}</span>
                        </div>
                    </div>
                </div>
            </div>
        </Layout>
    );
};

```

---

## `Web_Panel/src/pages/Config.tsx`

```tsx
import { Layout } from "../components/Layout";
import { Settings, User, Bell, Shield, Database } from "lucide-react";

export function Config() {
  return (
    <Layout>
      <div className="space-y-6">
        <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
          <div className="flex items-center gap-3 mb-6">
            <Settings className="w-6 h-6 text-blue-400" />
            <h2 className="text-2xl font-semibold text-white">Configuración del Sistema</h2>
          </div>

          <div className="space-y-4">
            {/* Cuenta */}
            <div className="p-4 bg-dark-700 rounded-lg border border-dark-600">
              <div className="flex items-center gap-3 mb-2">
                <User className="w-5 h-5 text-gray-400" />
                <h3 className="text-lg font-medium text-white">Cuenta de Usuario</h3>
              </div>
              <p className="text-sm text-gray-400 ml-8">
                Gestiona tu perfil y preferencias de usuario
              </p>
            </div>

            {/* Notificaciones */}
            <div className="p-4 bg-dark-700 rounded-lg border border-dark-600">
              <div className="flex items-center gap-3 mb-2">
                <Bell className="w-5 h-5 text-gray-400" />
                <h3 className="text-lg font-medium text-white">Notificaciones</h3>
              </div>
              <p className="text-sm text-gray-400 ml-8">
                Configura alertas y notificaciones del sistema
              </p>
            </div>

            {/* Seguridad */}
            <div className="p-4 bg-dark-700 rounded-lg border border-dark-600">
              <div className="flex items-center gap-3 mb-2">
                <Shield className="w-5 h-5 text-gray-400" />
                <h3 className="text-lg font-medium text-white">Seguridad</h3>
              </div>
              <p className="text-sm text-gray-400 ml-8">
                Administra permisos y accesos del sistema
              </p>
            </div>

            {/* Base de Datos */}
            <div className="p-4 bg-dark-700 rounded-lg border border-dark-600">
              <div className="flex items-center gap-3 mb-2">
                <Database className="w-5 h-5 text-gray-400" />
                <h3 className="text-lg font-medium text-white">Base de Datos</h3>
              </div>
              <p className="text-sm text-gray-400 ml-8">
                Configuración de Firebase y almacenamiento
              </p>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}

```

---

## `Web_Panel/src/pages/ConfigAdvanced.tsx`

```tsx
import { Layout } from "../components/Layout";
import { Settings, Radio, Activity, AlertTriangle, CheckCircle } from "lucide-react";
import { useBeacons } from "../hooks/useBeacons";
import { getBeaconStats, getBeaconStatus } from "../utils/beaconUtils";
import { useState } from "react";
import { useAuth } from "../context/AuthContext";
import { emergencyService } from "../services/beaconService";

export function ConfigAdvanced() {
  const { beacons, loading } = useBeacons();
  const { user } = useAuth();
  const [activatingEmergency, setActivatingEmergency] = useState(false);
  
  const stats = getBeaconStats(beacons);
  
  const handleGlobalEmergency = async () => {
    if (!user) {
      alert("Debes estar autenticado para activar emergencias");
      return;
    }
    
    const confirmed = window.confirm(
      `¿Activar EMERGENCIA GLOBAL en ${stats.total} balizas?\n\nEsta acción afectará a todo el sistema.`
    );
    
    if (!confirmed) return;
    
    setActivatingEmergency(true);
    try {
      await emergencyService.activateGlobalEvacuation(
        beacons,
        user.uid,
        "¡EMERGENCIA! Siga las instrucciones del personal",
        "SALIDA PRINCIPAL"
      );
      alert(`Emergencia activada en ${stats.total} balizas`);
    } catch (error) {
      console.error("Error activando emergencia:", error);
      alert("Error al activar emergencia global");
    } finally {
      setActivatingEmergency(false);
    }
  };
  
  const handleDeactivateEmergency = async () => {
    if (!user) return;
    
    const confirmed = window.confirm(
      `¿Desactivar emergencias en ${stats.total} balizas?`
    );
    
    if (!confirmed) return;
    
    setActivatingEmergency(true);
    try {
      await emergencyService.deactivateGlobalEvacuation(beacons, user.uid);
      alert("Emergencias desactivadas");
    } catch (error) {
      console.error("Error:", error);
      alert("Error al desactivar emergencias");
    } finally {
      setActivatingEmergency(false);
    }
  };

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-400">Cargando configuración...</div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
          <div className="flex items-center gap-3">
            <Settings className="w-6 h-6 text-blue-400" />
            <h2 className="text-2xl font-semibold text-white">Configuración del Sistema</h2>
          </div>
        </div>

        {/* Estadísticas Globales */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-2">
              <Radio className="w-8 h-8 text-blue-400" />
              <span className="text-3xl font-bold text-white">{stats.total}</span>
            </div>
            <div className="text-sm text-gray-400">Balizas Totales</div>
          </div>

          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-2">
              <Activity className="w-8 h-8 text-green-400" />
              <span className="text-3xl font-bold text-green-400">{stats.online}</span>
            </div>
            <div className="text-sm text-gray-400">
              Online ({stats.uptime}% uptime)
            </div>
          </div>

          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-2">
              <AlertTriangle className="w-8 h-8 text-yellow-400" />
              <span className="text-3xl font-bold text-yellow-400">{stats.unconfigured}</span>
            </div>
            <div className="text-sm text-gray-400">Sin Configurar</div>
          </div>

          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-2">
              <AlertTriangle className="w-8 h-8 text-red-400" />
              <span className="text-3xl font-bold text-red-400">{stats.emergency}</span>
            </div>
            <div className="text-sm text-gray-400">En Emergencia</div>
          </div>
        </div>

        {/* Control de Emergencias */}
        <div className="bg-dark-800 border border-red-700 rounded-lg p-6">
          <div className="flex items-center gap-3 mb-4">
            <AlertTriangle className="w-6 h-6 text-red-400" />
            <h3 className="text-xl font-semibold text-white">Control de Emergencias</h3>
          </div>
          
          <div className="space-y-4">
            <p className="text-gray-400 text-sm">
              Activa o desactiva el modo emergencia en todas las balizas del sistema simultáneamente.
            </p>
            
            <div className="flex gap-4">
              <button
                onClick={handleGlobalEmergency}
                disabled={activatingEmergency || stats.total === 0}
                className="flex-1 py-3 px-6 bg-red-600 hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-bold rounded-lg transition-colors"
              >
                {activatingEmergency ? "Activando..." : "🚨 ACTIVAR EMERGENCIA GLOBAL"}
              </button>
              
              <button
                onClick={handleDeactivateEmergency}
                disabled={activatingEmergency || stats.emergency === 0}
                className="flex-1 py-3 px-6 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-bold rounded-lg transition-colors"
              >
                {activatingEmergency ? "Desactivando..." : "✅ DESACTIVAR EMERGENCIAS"}
              </button>
            </div>
            
            {stats.emergency > 0 && (
              <div className="bg-red-500/10 border border-red-500 rounded-lg p-4">
                <p className="text-red-400 font-semibold">
                  ⚠️ Hay {stats.emergency} baliza(s) en modo emergencia actualmente
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Lista de Balizas */}
        <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
          <h3 className="text-xl font-semibold text-white mb-4">Estado de Balizas</h3>
          
          {beacons.length === 0 ? (
            <div className="text-center py-8 text-gray-400">
              No hay balizas registradas en el sistema
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-dark-700">
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">Estado</th>
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">ID</th>
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">Zona</th>
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">Modo</th>
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">Mensaje</th>
                  </tr>
                </thead>
                <tbody>
                  {beacons.map((beacon) => {
                    const status = getBeaconStatus(beacon);
                    
                    return (
                      <tr key={beacon.beaconId} className="border-b border-dark-700 hover:bg-dark-700/50">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <span className="text-xl">{status.emoji}</span>
                            <span className={`text-sm font-medium ${status.color}`}>
                              {status.text}
                            </span>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <span className="font-mono text-sm text-white">{beacon.beaconId}</span>
                        </td>
                        <td className="py-3 px-4">
                          <span className="text-sm text-gray-300">{beacon.zone || "-"}</span>
                        </td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-1 rounded text-xs font-semibold ${
                            beacon.mode === "EMERGENCY" || beacon.mode === "EVACUATION" ? "bg-red-500/20 text-red-400" :
                            beacon.mode === "MAINTENANCE" ? "bg-blue-500/20 text-blue-400" :
                            beacon.mode === "CONGESTION" ? "bg-orange-500/20 text-orange-400" :
                            beacon.mode === "UNCONFIGURED" ? "bg-gray-500/20 text-gray-400" :
                            "bg-green-500/20 text-green-400"
                          }`}>
                            {beacon.mode}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <span className="text-sm text-gray-300 truncate max-w-xs block">
                            {beacon.message}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Balizas Sin Configurar */}
        {stats.unconfigured > 0 && (
          <div className="bg-yellow-500/10 border border-yellow-500 rounded-lg p-6">
            <div className="flex items-center gap-3 mb-2">
              <AlertTriangle className="w-5 h-5 text-yellow-500" />
              <h3 className="text-lg font-semibold text-yellow-500">Atención Requerida</h3>
            </div>
            <p className="text-yellow-400">
              Hay {stats.unconfigured} baliza(s) sin configurar. 
              Configúralas desde el panel de balizas para que estén operativas.
            </p>
          </div>
        )}

        {/* Balizas Offline */}
        {stats.offline > 0 && (
          <div className="bg-red-500/10 border border-red-500 rounded-lg p-6">
            <div className="flex items-center gap-3 mb-2">
              <AlertTriangle className="w-5 h-5 text-red-500" />
              <h3 className="text-lg font-semibold text-red-500">Balizas Desconectadas</h3>
            </div>
            <p className="text-red-400">
              Hay {stats.offline} baliza(s) offline. Verifica la conexión de red.
            </p>
          </div>
        )}

        {/* Sistema Operativo */}
        {stats.online === stats.total && stats.total > 0 && stats.unconfigured === 0 && (
          <div className="bg-green-500/10 border border-green-500 rounded-lg p-6">
            <div className="flex items-center gap-3">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <p className="text-green-400 font-semibold">
                ✅ Sistema completamente operativo - Todas las balizas online y configuradas
              </p>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}

```

---

## `Web_Panel/src/pages/Dashboard.tsx`

```tsx
import React, { useEffect, useState } from "react";
import { Layout } from "../components/Layout";
import { api } from "../services/apiClient";
import { Beacon, Command } from "../types";
import { Activity, Radio, AlertTriangle, Terminal, CheckCircle, XCircle, Clock } from "lucide-react";
import { Link } from "react-router-dom";

export const Dashboard: React.FC = () => {
  const [beacons, setBeacons] = useState<Beacon[]>([]);
  const [incidents, setIncidents] = useState<any[]>([]);
  const [commands, setCommands] = useState<Command[]>([]);
  const [circuitState, setCircuitState] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    try {
      const [beaconsData, incidentsData, commandsData, stateData] = await Promise.all([
        api.getBeacons(),
        api.getIncidents(),
        api.getCommands(),
        api.getCircuitState().catch(() => null) // Handle if state endpoint fails initially
      ]);

      setBeacons(beaconsData);
      setIncidents(incidentsData);
      setCommands(commandsData.slice(0, 5)); // Show only last 5
      setCircuitState(stateData);
    } catch (error) {
      console.error("Error fetching dashboard data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 5000);
    return () => clearInterval(interval);
  }, []);

  const onlineCount = beacons.filter(b => b.online).length;
  const offlineCount = beacons.length - onlineCount;
  const activeIncidents = incidents.filter(i => i.status !== 'RESOLVED').length;

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-full text-white">
          <Activity className="w-8 h-8 animate-spin text-blue-500" />
          <span className="ml-2">Cargando Race Control...</span>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-white flex items-center gap-2">
          <Activity className="w-6 h-6 text-blue-500" />
          RACE CONTROL DASHBOARD
        </h1>

        {/* Top Metrics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {/* Circuit Status */}
          <div className="bg-dark-800 p-4 rounded-lg border border-dark-700">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-gray-400 text-sm font-medium">ESTADO CIRCUITO</h3>
              <Activity className="w-4 h-4 text-green-500" />
            </div>
            <div className="text-2xl font-bold text-white">
              {circuitState?.mode || "NORMAL"}
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Última act: {circuitState?.updated_at ? new Date(circuitState.updated_at).toLocaleTimeString() : "-"}
            </p>
          </div>

          {/* Beacons Status */}
          <div className="bg-dark-800 p-4 rounded-lg border border-dark-700">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-gray-400 text-sm font-medium">BALIZAS</h3>
              <Radio className="w-4 h-4 text-blue-500" />
            </div>
            <div className="flex items-end gap-2">
              <span className="text-2xl font-bold text-white">{beacons.length}</span>
              <span className="text-sm text-gray-400 mb-1">Total</span>
            </div>
            <div className="flex gap-2 mt-2 text-xs">
              <span className="text-green-400 flex items-center gap-1">
                <CheckCircle className="w-3 h-3" /> {onlineCount} Online
              </span>
              <span className="text-red-400 flex items-center gap-1">
                <XCircle className="w-3 h-3" /> {offlineCount} Offline
              </span>
            </div>
          </div>

          {/* Active Incidents */}
          <div className="bg-dark-800 p-4 rounded-lg border border-dark-700">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-gray-400 text-sm font-medium">INCIDENCIAS</h3>
              <AlertTriangle className="w-4 h-4 text-yellow-500" />
            </div>
            <div className="text-2xl font-bold text-white">
              {activeIncidents}
            </div>
            <p className="text-xs text-gray-500 mt-1">Activas ahora</p>
          </div>

          {/* System Health */}
          <div className="bg-dark-800 p-4 rounded-lg border border-dark-700">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-gray-400 text-sm font-medium">SISTEMA</h3>
              <Clock className="w-4 h-4 text-purple-500" />
            </div>
            <div className="text-2xl font-bold text-white">ONLINE</div>
            <p className="text-xs text-gray-500 mt-1">API Conectada</p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Recent Commands */}
          <div className="bg-dark-800 rounded-lg border border-dark-700 overflow-hidden">
            <div className="p-4 border-b border-dark-700 flex justify-between items-center">
              <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                <Terminal className="w-5 h-5 text-gray-400" />
                Últimos Comandos
              </h3>
              <Link to="/logs" className="text-xs text-blue-400 hover:text-blue-300">Ver todo</Link>
            </div>
            <div className="divide-y divide-dark-700">
              {commands.length === 0 ? (
                <div className="p-4 text-gray-500 text-center text-sm">No hay comandos recientes</div>
              ) : (
                commands.map(cmd => (
                  <div key={cmd.id} className="p-3 hover:bg-dark-700/50 transition-colors">
                    <div className="flex justify-between items-start">
                      <div>
                        <span className="text-xs font-mono text-blue-400 bg-blue-400/10 px-1.5 py-0.5 rounded">
                          {cmd.command}
                        </span>
                        <p className="text-sm text-gray-300 mt-1">
                          Baliza: <span className="text-white">{cmd.beacon_uid}</span>
                        </p>
                      </div>
                      <div className="text-right">
                        <span className={`text-xs px-2 py-0.5 rounded-full ${cmd.status === 'EXECUTED' ? 'bg-green-500/20 text-green-400' :
                          cmd.status === 'PENDING' ? 'bg-yellow-500/20 text-yellow-400' :
                            'bg-red-500/20 text-red-400'
                          }`}>
                          {cmd.status}
                        </span>
                        <p className="text-xs text-gray-500 mt-1">
                          {new Date(cmd.created_at).toLocaleTimeString()}
                        </p>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Recent Incidents / Activity */}
          <div className="bg-dark-800 rounded-lg border border-dark-700 overflow-hidden">
            <div className="p-4 border-b border-dark-700 flex justify-between items-center">
              <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-gray-400" />
                Últimas Incidencias
              </h3>
              <Link to="/incidents" className="text-xs text-blue-400 hover:text-blue-300">Ver todo</Link>
            </div>
            <div className="divide-y divide-dark-700">
              {incidents.length === 0 ? (
                <div className="p-4 text-gray-500 text-center text-sm">No hay incidencias recientes</div>
              ) : (
                incidents.slice(0, 5).map((inc, idx) => (
                  <div key={idx} className="p-3 hover:bg-dark-700/50 transition-colors">
                    <div className="flex justify-between items-start">
                      <div>
                        <h4 className="text-sm font-medium text-white">{inc.title}</h4>
                        <p className="text-xs text-gray-400 mt-0.5">{inc.description}</p>
                      </div>
                      <span className={`text-xs px-2 py-0.5 rounded-full ${inc.level === 'CRITICAL' ? 'bg-red-500/20 text-red-400' :
                        inc.level === 'WARNING' ? 'bg-yellow-500/20 text-yellow-400' :
                          'bg-blue-500/20 text-blue-400'
                        }`}>
                        {inc.level}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

```

---

## `Web_Panel/src/pages/Emergencies.tsx`

```tsx
import React, { useState } from "react";
import { Layout } from "../components/Layout";
import { useBeacons } from "../hooks/useBeacons";
import { useZones } from "../hooks/useZones";
import { useAuth } from "../context/AuthContext";
import { emergencyService } from "../services/beaconService";
import { AlertTriangle, Power, Shield } from "lucide-react";

export const Emergencies: React.FC = () => {
  const { beacons } = useBeacons();
  const zones = useZones(beacons);
  const { user } = useAuth();

  const [globalMessage, setGlobalMessage] = useState("");
  const [globalExit, setGlobalExit] = useState("");
  const [selectedZone, setSelectedZone] = useState("");
  const [processing, setProcessing] = useState(false);

  const isGlobalEvacuationActive = beacons.every(b => b.mode === "EVACUATION");

  const handleGlobalEvacuation = async () => {
    if (!user) return;
    setProcessing(true);

    try {
      if (isGlobalEvacuationActive) {
        await emergencyService.deactivateGlobalEvacuation(beacons, user.uid);
      } else {
        const message = globalMessage || "EVACUACIÓN EN CURSO. SIGA LAS FLECHAS.";
        const exit = globalExit || "EVACUATION_EXIT_DEFAULT";
        await emergencyService.activateGlobalEvacuation(beacons, user.uid, message, exit);
      }
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setProcessing(false);
    }
  };

  const handleZoneEvacuation = async (zone: string, activate: boolean) => {
    if (!user) return;
    setProcessing(true);

    try {
      if (activate) {
        const message = globalMessage || "EVACUACIÓN EN CURSO. SIGA LAS FLECHAS.";
        const exit = globalExit || "EVACUATION_EXIT_DEFAULT";
        await emergencyService.activateZoneEvacuation(zone, beacons, user.uid, message, exit);
      } else {
        await emergencyService.deactivateZoneEvacuation(zone, beacons, user.uid);
      }
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setProcessing(false);
    }
  };

  const handleFilteredEvacuation = async () => {
    if (!user || !selectedZone) return;
    setProcessing(true);

    try {
      const message = globalMessage || "EVACUACIÓN EN CURSO. SIGA LAS FLECHAS.";
      const exit = globalExit || "EVACUATION_EXIT_DEFAULT";
      await emergencyService.activateZoneEvacuation(selectedZone, beacons, user.uid, message, exit);
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setProcessing(false);
    }
  };

  return (
    <Layout>
      <div className="max-w-6xl mx-auto space-y-6">
        <div className="flex items-center gap-3">
          <AlertTriangle className="w-8 h-8 text-red-500" />
          <h1 className="text-2xl font-bold text-white">Emergencias & Evacuación</h1>
        </div>

        <div className="bg-red-900/20 border border-red-500 rounded-lg p-6">
          <div className="flex items-start gap-4">
            <Shield className="w-12 h-12 text-red-500 flex-shrink-0" />
            <div className="flex-1">
              <h2 className="text-xl font-bold text-white mb-2">Control Global de Evacuación</h2>
              <p className="text-gray-300 mb-4">
                Activar modo evacuación afectará a todas las balizas del sistema o solo a las de una zona específica.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Mensaje de Evacuación (opcional)
                  </label>
                  <input
                    type="text"
                    value={globalMessage}
                    onChange={(e) => setGlobalMessage(e.target.value)}
                    className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-red-500"
                    placeholder="Por defecto: EVACUACIÓN EN CURSO. SIGA LAS FLECHAS."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Salida de Evacuación (opcional)
                  </label>
                  <input
                    type="text"
                    value={globalExit}
                    onChange={(e) => setGlobalExit(e.target.value)}
                    className="w-full px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-red-500"
                    placeholder="Ej: SALIDA 3"
                  />
                </div>
              </div>

              <div className="flex gap-4">
                <button
                  onClick={handleGlobalEvacuation}
                  disabled={processing}
                  className={`flex-1 flex items-center justify-center gap-2 py-4 font-bold rounded-lg transition-colors ${
                    isGlobalEvacuationActive
                      ? 'bg-green-600 hover:bg-green-700 text-white'
                      : 'bg-red-600 hover:bg-red-700 text-white'
                  } disabled:opacity-50`}
                >
                  <Power className="w-6 h-6" />
                  {isGlobalEvacuationActive ? 'Desactivar Evacuación Global' : 'Activar Evacuación Global'}
                </button>
              </div>

              {isGlobalEvacuationActive && (
                <div className="mt-4 p-4 bg-red-500/20 border border-red-500 rounded text-red-400 font-semibold text-center">
                  ⚠️ MODO EVACUACIÓN GLOBAL ACTIVO
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="bg-dark-800 rounded-lg p-6">
          <h2 className="text-xl font-bold text-white mb-4">Evacuación por Zona Seleccionada</h2>
          
          <div className="flex gap-4 mb-6">
            <select
              value={selectedZone}
              onChange={(e) => setSelectedZone(e.target.value)}
              className="flex-1 px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Seleccionar zona...</option>
              {zones.map(z => (
                <option key={z.zone} value={z.zone}>{z.zone}</option>
              ))}
            </select>

            <button
              onClick={handleFilteredEvacuation}
              disabled={!selectedZone || processing}
              className="px-6 py-2 bg-orange-600 hover:bg-orange-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded transition-colors"
            >
              Activar en Zona
            </button>
          </div>
        </div>

        <div className="bg-dark-800 rounded-lg p-6">
          <h2 className="text-xl font-bold text-white mb-4">Control por Zonas</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {zones.map(zone => {
              const isZoneEvacuating = zone.evacuationCount > 0;
              
              return (
                <div
                  key={zone.zone}
                  className={`p-4 rounded-lg border-2 ${
                    isZoneEvacuating
                      ? 'bg-red-900/20 border-red-500'
                      : 'bg-dark-700 border-dark-600'
                  }`}
                >
                  <h3 className="text-lg font-semibold text-white mb-2">{zone.zone}</h3>
                  
                  <div className="space-y-2 mb-4">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-400">Total balizas:</span>
                      <span className="text-white font-semibold">{zone.totalBeacons}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-400">En evacuación:</span>
                      <span className={`font-semibold ${isZoneEvacuating ? 'text-red-400' : 'text-green-400'}`}>
                        {zone.evacuationCount}
                      </span>
                    </div>
                  </div>

                  <div className="flex gap-2">
                    {isZoneEvacuating ? (
                      <button
                        onClick={() => handleZoneEvacuation(zone.zone, false)}
                        disabled={processing}
                        className="flex-1 py-2 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 text-white text-sm font-semibold rounded transition-colors"
                      >
                        Volver a Normal
                      </button>
                    ) : (
                      <button
                        onClick={() => handleZoneEvacuation(zone.zone, true)}
                        disabled={processing}
                        className="flex-1 py-2 bg-red-600 hover:bg-red-700 disabled:bg-gray-600 text-white text-sm font-semibold rounded transition-colors"
                      >
                        Poner en Evacuación
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div className="bg-dark-800 rounded-lg p-6">
          <h2 className="text-xl font-bold text-white mb-4">Mensajes por Idioma (Referencia)</h2>
          
          <div className="space-y-3">
            <div className="p-3 bg-dark-700 rounded">
              <span className="font-semibold text-blue-400">ES:</span>
              <span className="text-white ml-3">EVACUACIÓN EN CURSO. SIGA LAS FLECHAS.</span>
            </div>
            <div className="p-3 bg-dark-700 rounded">
              <span className="font-semibold text-blue-400">CAT:</span>
              <span className="text-white ml-3">EVACUACIÓ EN CURS. SEGUEIX LES FLETXES.</span>
            </div>
            <div className="p-3 bg-dark-700 rounded">
              <span className="font-semibold text-blue-400">EN:</span>
              <span className="text-white ml-3">EVACUATION IN PROGRESS. FOLLOW THE ARROWS.</span>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

```

---

## `Web_Panel/src/pages/FoodStandsPage.tsx`

```tsx
import { useEffect, useState } from 'react';
import { api } from '../services/apiClient';
import { Layout } from '../components/Layout';
import { Plus, Edit2, Trash2, Save, X, MapPin } from 'lucide-react';

interface FoodStand {
    id: string;
    name: string;
    description: string;
    latitude: number;
    longitude: number;
    zone: string;
    waitMinutes: number;
    rating: number;
    isOpen: boolean;
}

const INITIAL_STANDS: Omit<FoodStand, 'id'>[] = [
    { name: "🍔 Burger Pit", description: "Hamburguesas y patatas", latitude: 41.570, longitude: 2.261, zone: "Tribuna Principal", waitMinutes: 8, rating: 4.5, isOpen: true },
    { name: "🍕 Pizza Box", description: "Pizzas artesanales al horno", latitude: 41.571, longitude: 2.262, zone: "Paddock", waitMinutes: 12, rating: 4.2, isOpen: true },
    { name: "🌮 Taco Stand", description: "Tacos y burritos mexicanos", latitude: 41.569, longitude: 2.260, zone: "Zona Fan", waitMinutes: 5, rating: 4.7, isOpen: true },
    { name: "🍺 Bar Central", description: "Bebidas frías y snacks", latitude: 41.570, longitude: 2.263, zone: "Grada Norte", waitMinutes: 3, rating: 4.0, isOpen: true },
];

const FoodStandsPage = () => {
    const [stands, setStands] = useState<FoodStand[]>([]);
    const [editMode, setEditMode] = useState<string | null>(null);
    const [editedStand, setEditedStand] = useState<Partial<FoodStand>>({});
    const [loading, setLoading] = useState(true);

    useEffect(() => { fetchStands(); }, []);

    const fetchStands = async () => {
        setLoading(true);
        try {
            const data = await api.get<FoodStand>('food_stands');
            if (data.length === 0) {
                await seedStands();
            } else {
                setStands(data);
            }
        } catch (e) {
            console.error(e);
        }
        setLoading(false);
    };

    const seedStands = async () => {
        for (const s of INITIAL_STANDS) {
            await api.upsert('food_stands', { ...s, id: crypto.randomUUID(), isOpen: s.isOpen ? 1 : 0 });
        }
        const data = await api.get<FoodStand>('food_stands');
        setStands(data);
    };

    const handleSave = async () => {
        if (!editedStand.name) return;
        try {
            const id = editMode === 'new' ? crypto.randomUUID() : editMode;
            await api.upsert('food_stands', {
                id,
                ...editedStand,
                latitude: Number(editedStand.latitude || 0),
                longitude: Number(editedStand.longitude || 0),
                waitMinutes: Number(editedStand.waitMinutes || 10),
                rating: Number(editedStand.rating || 4.0),
                isOpen: editedStand.isOpen ? 1 : 0,
            });
            setEditMode(null);
            setEditedStand({});
            fetchStands();
        } catch (e) {
            console.error(e);
            alert('Error al guardar');
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('¿Eliminar punto de venta?')) return;
        try {
            await api.delete('food_stands', { id });
            fetchStands();
        } catch (e) {
            console.error(e);
        }
    };

    const toggleOpen = async (stand: FoodStand) => {
        await api.upsert('food_stands', { ...stand, isOpen: stand.isOpen ? 0 : 1 });
        fetchStands();
    };

    return (
        <Layout>
            <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                    <div>
                        <h1 className="text-2xl font-bold text-white">🍽️ Puntos de Venta (Food Stands)</h1>
                        <p className="text-gray-400 text-sm mt-1">Gestiona los puestos de comida del circuito</p>
                    </div>
                    <button
                        onClick={() => { setEditMode('new'); setEditedStand({ isOpen: true, waitMinutes: 10, rating: 4.0 }); }}
                        className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
                    >
                        <Plus size={16} /> Nuevo Stand
                    </button>
                </div>

                {/* Editor */}
                {editMode && (
                    <div className="bg-gray-800 rounded-xl p-4 mb-6 border border-gray-700">
                        <h3 className="text-white font-bold mb-3">{editMode === 'new' ? 'Nuevo Stand' : 'Editar Stand'}</h3>
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                            <input placeholder="Nombre" value={editedStand.name || ''} onChange={e => setEditedStand({ ...editedStand, name: e.target.value })} className="bg-gray-700 text-white p-2 rounded" />
                            <input placeholder="Descripción" value={editedStand.description || ''} onChange={e => setEditedStand({ ...editedStand, description: e.target.value })} className="bg-gray-700 text-white p-2 rounded" />
                            <input placeholder="Zona" value={editedStand.zone || ''} onChange={e => setEditedStand({ ...editedStand, zone: e.target.value })} className="bg-gray-700 text-white p-2 rounded" />
                            <input type="number" placeholder="Espera (min)" value={editedStand.waitMinutes || ''} onChange={e => setEditedStand({ ...editedStand, waitMinutes: Number(e.target.value) })} className="bg-gray-700 text-white p-2 rounded" />
                            <input type="number" step="0.001" placeholder="Latitud" value={editedStand.latitude || ''} onChange={e => setEditedStand({ ...editedStand, latitude: Number(e.target.value) })} className="bg-gray-700 text-white p-2 rounded" />
                            <input type="number" step="0.001" placeholder="Longitud" value={editedStand.longitude || ''} onChange={e => setEditedStand({ ...editedStand, longitude: Number(e.target.value) })} className="bg-gray-700 text-white p-2 rounded" />
                            <input type="number" step="0.1" placeholder="Rating" value={editedStand.rating || ''} onChange={e => setEditedStand({ ...editedStand, rating: Number(e.target.value) })} className="bg-gray-700 text-white p-2 rounded" />
                            <label className="flex items-center gap-2 text-white">
                                <input type="checkbox" checked={!!editedStand.isOpen} onChange={e => setEditedStand({ ...editedStand, isOpen: e.target.checked })} />
                                Abierto
                            </label>
                        </div>
                        <div className="flex gap-2 mt-3">
                            <button onClick={handleSave} className="flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white rounded hover:bg-green-700"><Save size={14} /> Guardar</button>
                            <button onClick={() => { setEditMode(null); setEditedStand({}); }} className="flex items-center gap-1 px-3 py-1.5 bg-gray-600 text-white rounded hover:bg-gray-500"><X size={14} /> Cancelar</button>
                        </div>
                    </div>
                )}

                {/* Table */}
                <div className="bg-gray-800 rounded-xl overflow-hidden">
                    <table className="w-full text-sm text-left text-gray-300">
                        <thead className="bg-gray-700 text-gray-400">
                            <tr>
                                <th className="px-4 py-3">Nombre</th>
                                <th className="px-4 py-3">Zona</th>
                                <th className="px-4 py-3">Espera</th>
                                <th className="px-4 py-3">Rating</th>
                                <th className="px-4 py-3">Estado</th>
                                <th className="px-4 py-3 text-right">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            {stands.map(s => (
                                <tr key={s.id} className="border-b border-gray-700 hover:bg-gray-750">
                                    <td className="px-4 py-3 font-medium text-white">{s.name}</td>
                                    <td className="px-4 py-3"><span className="flex items-center gap-1"><MapPin size={12} />{s.zone}</span></td>
                                    <td className="px-4 py-3">{s.waitMinutes} min</td>
                                    <td className="px-4 py-3">⭐ {s.rating}</td>
                                    <td className="px-4 py-3">
                                        <button onClick={() => toggleOpen(s)} className={`px-2 py-0.5 rounded text-xs font-bold ${s.isOpen ? 'bg-green-900 text-green-300' : 'bg-red-900 text-red-300'}`}>
                                            {s.isOpen ? 'ABIERTO' : 'CERRADO'}
                                        </button>
                                    </td>
                                    <td className="px-4 py-3 text-right">
                                        <button onClick={() => { setEditMode(s.id); setEditedStand(s); }} className="text-blue-400 hover:text-blue-300 mr-2"><Edit2 size={14} /></button>
                                        <button onClick={() => handleDelete(s.id)} className="text-red-400 hover:text-red-300"><Trash2 size={14} /></button>
                                    </td>
                                </tr>
                            ))}
                            {stands.length === 0 && !loading && (
                                <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-500">No hay stands. Pulsa "Nuevo Stand" para crear uno.</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </Layout>
    );
};

export default FoodStandsPage;

```

---

## `Web_Panel/src/pages/Incidents.tsx`

```tsx
import React, { useEffect, useState } from "react";
import { Layout } from "../components/Layout";
import { api } from "../services/apiClient";
import { AlertTriangle, Plus, Filter } from "lucide-react";
import { useToast } from "../context/ToastContext";

export const Incidents: React.FC = () => {
    const [incidents, setIncidents] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const { showToast } = useToast();

    // Form state
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [level, setLevel] = useState("INFO");
    const [zone, setZone] = useState("");

    const fetchIncidents = async () => {
        try {
            const data = await api.getIncidents();
            setIncidents(data);
        } catch (error) {
            console.error("Error fetching incidents:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchIncidents();
    }, []);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await api.upsert("incidents", {
                category: title,
                description,
                level,
                zone: zone ? zone.toString() : null,
                status: "ACTIVE",
                created_at: new Date().toISOString().slice(0, 19).replace("T", " ")
            });
            showToast("Incidencia creada correctamente", "success");
            setShowModal(false);
            setTitle("");
            setDescription("");
            setLevel("INFO");
            setZone("");
            fetchIncidents();
        } catch (error) {
            console.error("Error creating incident:", error);
            showToast("Error al crear incidencia", "error");
        }
    };

    return (
        <Layout>
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                        <AlertTriangle className="w-6 h-6 text-yellow-500" />
                        Gestión de Incidencias
                    </h1>
                    <button
                        onClick={() => setShowModal(true)}
                        className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors"
                    >
                        <Plus className="w-4 h-4" />
                        Nueva Incidencia
                    </button>
                </div>

                {/* Filters (Visual only for now) */}
                <div className="bg-dark-800 p-4 rounded-lg border border-dark-700 flex gap-4">
                    <div className="relative flex-1">
                        <Filter className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Filtrar por título..."
                            className="w-full pl-10 pr-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                    </div>
                    <select className="px-4 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="ALL">Todos los niveles</option>
                        <option value="CRITICAL">Crítica</option>
                        <option value="WARNING">Advertencia</option>
                        <option value="INFO">Info</option>
                    </select>
                </div>

                {/* List */}
                <div className="bg-dark-800 rounded-lg border border-dark-700 overflow-hidden">
                    <table className="w-full">
                        <thead className="bg-dark-700">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Nivel</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Título</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Zona</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Estado</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Fecha</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-dark-700">
                            {loading ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-4 text-center text-gray-400">Cargando incidencias...</td>
                                </tr>
                            ) : incidents.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-4 text-center text-gray-400">No hay incidencias registradas</td>
                                </tr>
                            ) : (
                                incidents.map((inc, idx) => (
                                    <tr key={idx} className="hover:bg-dark-700/50 transition-colors">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className={`px-2 py-1 text-xs rounded-full ${inc.level === 'CRITICAL' ? 'bg-red-500/20 text-red-400' :
                                                inc.level === 'WARNING' ? 'bg-yellow-500/20 text-yellow-400' :
                                                    'bg-blue-500/20 text-blue-400'
                                                }`}>
                                                {inc.level || 'INFO'}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="text-sm font-medium text-white">{inc.category}</div>
                                            <div className="text-sm text-gray-400">{inc.description}</div>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-300">
                                            {inc.zone ? `Zona ${inc.zone}` : '-'}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className={`text-xs font-medium ${inc.status === 'ACTIVE' ? 'text-green-400' : 'text-gray-500'
                                                }`}>
                                                {inc.status || 'ACTIVE'}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-400">
                                            {inc.created_at ? new Date(inc.created_at).toLocaleString() : '-'}
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-dark-800 rounded-lg border border-dark-700 w-full max-w-md p-6">
                        <h2 className="text-xl font-bold text-white mb-4">Nueva Incidencia</h2>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-1">Título</label>
                                <input
                                    type="text"
                                    required
                                    value={title}
                                    onChange={e => setTitle(e.target.value)}
                                    className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-1">Descripción</label>
                                <textarea
                                    required
                                    value={description}
                                    onChange={e => setDescription(e.target.value)}
                                    className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    rows={3}
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Nivel</label>
                                    <select
                                        value={level}
                                        onChange={e => setLevel(e.target.value)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <option value="INFO">Info</option>
                                        <option value="WARNING">Advertencia</option>
                                        <option value="CRITICAL">Crítica</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-300 mb-1">Zona ID (Opcional)</label>
                                    <input
                                        type="number"
                                        value={zone}
                                        onChange={e => setZone(e.target.value)}
                                        className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    />
                                </div>
                            </div>
                            <div className="flex justify-end gap-3 mt-6">
                                <button
                                    type="button"
                                    onClick={() => setShowModal(false)}
                                    className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
                                >
                                    Cancelar
                                </button>
                                <button
                                    type="submit"
                                    className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors"
                                >
                                    Crear Incidencia
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </Layout>
    );
};

```

---

## `Web_Panel/src/pages/Login.tsx`

```tsx
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export const Login: React.FC = () => {
  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await login(email);
      navigate("/dashboard");
    } catch (err) {
      setError("Error al iniciar sesión. Verifica tu email.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-dark-900 flex items-center justify-center px-4">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h1 className="text-4xl font-bold text-white text-center mb-2">GeoRacing</h1>
          <h2 className="text-xl text-gray-400 text-center">Panel de Control</h2>
        </div>

        <form onSubmit={handleSubmit} className="mt-8 space-y-6 bg-dark-800 p-8 rounded-lg">
          <div className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
                Email
              </label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 bg-dark-700 border border-dark-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="usuario@georacing.com"
              />
            </div>
          </div>

          {error && (
            <div className="bg-red-500/10 border border-red-500 text-red-500 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-800 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors duration-200"
          >
            {loading ? "Iniciando sesión..." : "Iniciar sesión"}
          </button>
        </form>
      </div>
    </div>
  );
};

```

---

## `Web_Panel/src/pages/Logs.tsx`

```tsx
import React, { useEffect, useState } from "react";
import { Layout } from "../components/Layout";
import { api } from "../services/apiClient";
import { Command } from "../types";
import { Terminal, RefreshCw, Play } from "lucide-react";
import { useToast } from "../context/ToastContext";

export const Logs: React.FC = () => {
    const [commands, setCommands] = useState<Command[]>([]);
    const [loading, setLoading] = useState(true);
    const { showToast } = useToast();

    const fetchCommands = async () => {
        setLoading(true);
        try {
            const data = await api.getCommands();
            setCommands(data);
        } catch (error) {
            console.error("Error fetching commands:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchCommands();
    }, []);

    const handleExecute = async (id: number) => {
        try {
            await api.upsert("commands", {
                id,
                status: "EXECUTED",
                executed_at: new Date().toISOString().slice(0, 19).replace("T", " ")
            });
            showToast("Comando ejecutado forzosamente", "success");
            fetchCommands();
        } catch (error) {
            console.error("Error executing command:", error);
            showToast("Error al ejecutar comando", "error");
        }
    };

    return (
        <Layout>
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Terminal className="w-6 h-6 text-blue-500" />
                        Logs de Comandos
                    </h1>
                    <button
                        onClick={fetchCommands}
                        className="p-2 bg-dark-700 hover:bg-dark-600 text-white rounded-lg transition-colors"
                        title="Recargar"
                    >
                        <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
                    </button>
                </div>

                <div className="bg-dark-800 rounded-lg border border-dark-700 overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-dark-700">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">ID</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Baliza</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Tipo</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Payload</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Estado</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Creado</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Acciones</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-dark-700">
                                {commands.length === 0 ? (
                                    <tr>
                                        <td colSpan={7} className="px-6 py-4 text-center text-gray-400">No hay comandos registrados</td>
                                    </tr>
                                ) : (
                                    commands.map((cmd) => (
                                        <tr key={cmd.id} className="hover:bg-dark-700/50 transition-colors">
                                            <td className="px-6 py-4 text-sm text-gray-500 font-mono">#{cmd.id}</td>
                                            <td className="px-6 py-4 text-sm text-white font-mono">{cmd.beacon_uid}</td>
                                            <td className="px-6 py-4">
                                                <span className="text-xs font-mono text-blue-400 bg-blue-400/10 px-1.5 py-0.5 rounded">
                                                    {cmd.command}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-xs text-gray-400 font-mono max-w-xs truncate">
                                                {typeof cmd.value === 'string' ? cmd.value : JSON.stringify(cmd.value)}
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`text-xs px-2 py-0.5 rounded-full ${cmd.status === 'EXECUTED' ? 'bg-green-500/20 text-green-400' :
                                                    cmd.status === 'PENDING' ? 'bg-yellow-500/20 text-yellow-400' :
                                                        'bg-red-500/20 text-red-400'
                                                    }`}>
                                                    {cmd.status}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-400">
                                                {new Date(cmd.created_at).toLocaleString()}
                                            </td>
                                            <td className="px-6 py-4">
                                                {cmd.status === 'PENDING' && (
                                                    <button
                                                        onClick={() => handleExecute(cmd.id)}
                                                        className="text-blue-400 hover:text-blue-300 transition-colors"
                                                        title="Forzar ejecución"
                                                    >
                                                        <Play className="w-4 h-4" />
                                                    </button>
                                                )}
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </Layout>
    );
};

```

---

## `Web_Panel/src/pages/NewsPage.tsx`

```tsx
import { useEffect, useState } from 'react';
import { api } from '../services/apiClient';
import { Layout } from '../components/Layout';
import { Plus, Edit2, Trash2, Save, X, Bell } from 'lucide-react';

interface NewsItem {
    id: string;
    title: string;
    content: string;
    timestamp: number;
    category: string;
    priority: string;
}

const CATEGORIES = ['RACE_UPDATE', 'SCHEDULE_CHANGE', 'WEATHER', 'TRAFFIC', 'DRIVER_NEWS', 'SAFETY', 'EVENT', 'GENERAL'];
const PRIORITIES = ['HIGH', 'MEDIUM', 'LOW'];

const PRIORITY_COLORS: Record<string, string> = {
    HIGH: 'bg-red-900 text-red-300',
    MEDIUM: 'bg-yellow-900 text-yellow-300',
    LOW: 'bg-green-900 text-green-300',
};

const CATEGORY_LABELS: Record<string, string> = {
    RACE_UPDATE: '🏁 Carrera',
    SCHEDULE_CHANGE: '📅 Horario',
    WEATHER: '🌤️ Meteorología',
    TRAFFIC: '🚗 Tráfico',
    DRIVER_NEWS: '🏎️ Pilotos',
    SAFETY: '⚠️ Seguridad',
    EVENT: '🎉 Evento',
    GENERAL: '📢 General',
};

const NewsPage = () => {
    const [news, setNews] = useState<NewsItem[]>([]);
    const [editMode, setEditMode] = useState<string | null>(null);
    const [editedNews, setEditedNews] = useState<Partial<NewsItem>>({});
    const [loading, setLoading] = useState(true);

    useEffect(() => { fetchNews(); }, []);

    const fetchNews = async () => {
        setLoading(true);
        try {
            const data = await api.get<NewsItem>('news');
            setNews(data.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0)));
        } catch (e) {
            console.error(e);
        }
        setLoading(false);
    };

    const handleSave = async () => {
        if (!editedNews.title || !editedNews.content) return;
        try {
            const id = editMode === 'new' ? crypto.randomUUID() : editMode;
            const timestamp = editMode === 'new' ? Math.floor(Date.now() / 1000) : (editedNews.timestamp || Math.floor(Date.now() / 1000));
            await api.upsert('news', {
                id,
                title: editedNews.title,
                content: editedNews.content,
                timestamp,
                category: editedNews.category || 'GENERAL',
                priority: editedNews.priority || 'LOW',
            });
            setEditMode(null);
            setEditedNews({});
            fetchNews();
        } catch (e) {
            console.error(e);
            alert('Error al guardar');
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('¿Eliminar noticia?')) return;
        try {
            await api.delete('news', { id });
            fetchNews();
        } catch (e) {
            console.error(e);
        }
    };

    const formatTime = (ts: number) => {
        if (!ts) return '—';
        // timestamps stored as Unix seconds; convert to ms for Date
        const d = new Date(ts < 1e12 ? ts * 1000 : ts);
        return d.toLocaleString('es-ES', { day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit' });
    };

    return (
        <Layout>
            <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                    <div>
                        <h1 className="text-2xl font-bold text-white">📰 Noticias &amp; Alertas</h1>
                        <p className="text-gray-400 text-sm mt-1">Publica noticias que verán los usuarios en la app</p>
                    </div>
                    <button
                        onClick={() => { setEditMode('new'); setEditedNews({ category: 'GENERAL', priority: 'LOW' }); }}
                        className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
                    >
                        <Plus size={16} /> Nueva Noticia
                    </button>
                </div>

                {/* Editor */}
                {editMode && (
                    <div className="bg-gray-800 rounded-xl p-4 mb-6 border border-gray-700">
                        <h3 className="text-white font-bold mb-3">{editMode === 'new' ? 'Nueva Noticia' : 'Editar Noticia'}</h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <input placeholder="Título" value={editedNews.title || ''} onChange={e => setEditedNews({ ...editedNews, title: e.target.value })} className="bg-gray-700 text-white p-2 rounded col-span-2" />
                            <textarea placeholder="Contenido" rows={3} value={editedNews.content || ''} onChange={e => setEditedNews({ ...editedNews, content: e.target.value })} className="bg-gray-700 text-white p-2 rounded col-span-2" />
                            <select value={editedNews.category || 'GENERAL'} onChange={e => setEditedNews({ ...editedNews, category: e.target.value })} className="bg-gray-700 text-white p-2 rounded">
                                {CATEGORIES.map(c => <option key={c} value={c}>{CATEGORY_LABELS[c] || c}</option>)}
                            </select>
                            <select value={editedNews.priority || 'LOW'} onChange={e => setEditedNews({ ...editedNews, priority: e.target.value })} className="bg-gray-700 text-white p-2 rounded">
                                {PRIORITIES.map(p => <option key={p} value={p}>{p === 'HIGH' ? '🔴 Alta' : p === 'MEDIUM' ? '🟡 Media' : '🟢 Baja'}</option>)}
                            </select>
                        </div>
                        <div className="flex gap-2 mt-3">
                            <button onClick={handleSave} className="flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white rounded hover:bg-green-700"><Save size={14} /> Publicar</button>
                            <button onClick={() => { setEditMode(null); setEditedNews({}); }} className="flex items-center gap-1 px-3 py-1.5 bg-gray-600 text-white rounded hover:bg-gray-500"><X size={14} /> Cancelar</button>
                        </div>
                    </div>
                )}

                {/* Lista */}
                <div className="space-y-3">
                    {news.map(n => (
                        <div key={n.id} className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex justify-between items-start">
                            <div className="flex-1">
                                <div className="flex items-center gap-2 mb-1">
                                    <span className={`px-2 py-0.5 rounded text-xs font-bold ${PRIORITY_COLORS[n.priority] || PRIORITY_COLORS.LOW}`}>{n.priority}</span>
                                    <span className="text-gray-500 text-xs">{CATEGORY_LABELS[n.category] || n.category}</span>
                                    <span className="text-gray-600 text-xs ml-auto">{formatTime(n.timestamp)}</span>
                                </div>
                                <h3 className="text-white font-semibold">{n.title}</h3>
                                <p className="text-gray-400 text-sm mt-1">{n.content}</p>
                            </div>
                            <div className="flex gap-1 ml-4">
                                <button onClick={() => { setEditMode(n.id); setEditedNews(n); }} className="text-blue-400 hover:text-blue-300 p-1"><Edit2 size={14} /></button>
                                <button onClick={() => handleDelete(n.id)} className="text-red-400 hover:text-red-300 p-1"><Trash2 size={14} /></button>
                            </div>
                        </div>
                    ))}
                    {news.length === 0 && !loading && (
                        <div className="text-center py-12 text-gray-500">
                            <Bell size={48} className="mx-auto mb-3 opacity-30" />
                            <p>No hay noticias publicadas</p>
                        </div>
                    )}
                </div>
            </div>
        </Layout>
    );
};

export default NewsPage;

```

---

## `Web_Panel/src/pages/OrdersPage.tsx`

```tsx
import { useEffect, useState } from 'react';
import { api } from '../services/apiClient';
import { Layout } from '../components/Layout';
import { CheckCircle, Clock, ShoppingBag, Trash2, ChefHat, Flame } from 'lucide-react';

interface OrderLine {
    id?: string;
    product_id?: string;
    name?: string;
    price?: number;
    unit_price?: number;
    quantity?: number;
}

interface Order {
    id: string; // Generic DB ID
    order_id: string;
    user_uid: string;
    status: 'PAID' | 'PREPARING' | 'READY' | 'DELIVERED';
    items_json: string; // JSON string
    total_amount: number;
    created_at: string;
}


const OrdersPage = () => {
    const [orders, setOrders] = useState<Order[]>([]);
    const [productsMap, setProductsMap] = useState<Record<string, any>>({});
    const [showHistory, setShowHistory] = useState(false);
    const [loading, setLoading] = useState(true);

    const fetchOrders = async () => {
        try {
            const data = await api.get<Order>('orders');
            const sorted = data.sort((a, b) =>
                new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
            );
            setOrders(sorted);
        } catch (error) {
            console.error("Error fetching orders:", error);
        } finally {
            setLoading(false);
        }
    };

    const fetchProducts = async () => {
        try {
            const list = await api.get<any>('products');
            const map: Record<string, any> = {};
            if (Array.isArray(list)) {
                list.forEach((p: any) => map[p.id] = p);
            }
            setProductsMap(map);
        } catch (e) { console.error(e); }
    };

    useEffect(() => {
        fetchOrders();
        fetchProducts();
        const interval = setInterval(fetchOrders, 5000);
        return () => clearInterval(interval);
    }, []);

    const deleteOrder = async (id: string) => {
        if (!confirm('¿Eliminar pedido?')) return;
        try {
            await api.delete('orders', { id });
            setOrders(prev => prev.filter(o => o.id !== id));
        } catch (e) { console.error(e); }
    };

    const toggleStatus = async (orderId: string, currentStatus: string) => {
        let nextStatus = 'DELIVERED';
        if (currentStatus === 'PAID') nextStatus = 'PREPARING';
        else if (currentStatus === 'PREPARING') nextStatus = 'READY';

        try {
            const order = orders.find(o => o.order_id === orderId);
            if (!order) return;

            await api.upsert('orders', {
                id: order.id,
                order_id: orderId,
                status: nextStatus as any,
                updated_at: new Date().toISOString().slice(0, 19).replace('T', ' ')
            });
            setOrders(prev => prev.map(o =>
                o.order_id === orderId ? { ...o, status: nextStatus as any } : o
            ));
        } catch (error) {
            console.error("Error updating order:", error);
            alert("No se pudo actualizar el estado. Inténtalo de nuevo.");
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'PAID': return 'text-yellow-400 border-yellow-400';
            case 'PREPARING': return 'text-orange-400 border-orange-400';
            case 'READY': return 'text-green-400 border-green-400';
            case 'DELIVERED': return 'text-gray-400 border-gray-400';
            default: return 'text-white border-white';
        }
    };

    const displayedOrders = orders.filter(o =>
        showHistory ? o.status === 'DELIVERED' : o.status !== 'DELIVERED'
    );

    return (
        <Layout>
            <div className="text-white">
                <div className="flex justify-between items-center mb-8">
                    <h1 className="text-3xl font-black italic tracking-wider flex items-center gap-3">
                        <ShoppingBag className="text-red-500" />
                        {showHistory ? "HISTORIAL DE PEDIDOS" : "GESTIÓN DE PEDIDOS"}
                    </h1>
                    <button
                        onClick={() => setShowHistory(!showHistory)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl font-bold transition-all ${showHistory ? 'bg-red-600 hover:bg-red-500' : 'bg-gray-800 hover:bg-gray-700'}`}
                    >
                        <Clock size={18} />
                        {showHistory ? "VER ACTIVOS" : "VER HISTORIAL"}
                    </button>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {displayedOrders.map((order) => {
                        let items: OrderLine[] = [];
                        try {
                            const parsed = JSON.parse(order.items_json);
                            items = Array.isArray(parsed) ? parsed : [];
                        } catch (e) {
                            items = [];
                        }

                        return (
                            <div key={order.order_id} className={`bg-[#171717] rounded-2xl p-6 border-l-4 ${order.status === 'READY' ? 'border-green-500' : (order.status === 'PREPARING' ? 'border-orange-500' : (order.status === 'DELIVERED' ? 'border-gray-600' : 'border-yellow-500'))} shadow-lg`}>
                                <div className="flex justify-between items-start mb-4">
                                    <div>
                                        <h3 className="text-xl font-bold">#{order.order_id.slice(-8).toUpperCase()}</h3>
                                        <p className="text-gray-400 text-sm">{order.created_at}</p>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <div className={`px-3 py-1 rounded-full text-xs font-bold ${getStatusColor(order.status)} border border-current`}>
                                            {order.status === 'PAID' ? 'RECIBIDO' : (order.status === 'PREPARING' ? 'COCINANDO' : (order.status === 'DELIVERED' ? 'ENTREGADO' : order.status))}
                                        </div>
                                        <button
                                            onClick={() => deleteOrder(order.id)}
                                            className="text-gray-600 hover:text-red-500 transition-colors p-1"
                                            title="Eliminar Pedido"
                                        >
                                            <Trash2 size={18} />
                                        </button>
                                    </div>
                                </div>

                                <div className="space-y-2 mb-6">
                                    {items.map((item, idx) => {
                                        const pid = item.product_id || item.id || "";
                                        const catalogItem = productsMap[pid];
                                        const name = item.name || catalogItem?.name || "Producto Desconocido";
                                        const price = item.unit_price ?? item.price ?? Number(catalogItem?.price) ?? 0;
                                        const quantity = item.quantity ?? 1;

                                        return (
                                            <div key={idx} className="flex justify-between border-b border-gray-800 pb-2">
                                                <span>
                                                    <span className="font-bold text-gray-400 mr-2">{quantity}x</span>
                                                    {name}
                                                </span>
                                                <span className="font-mono">€{(price * quantity).toFixed(2)}</span>
                                            </div>
                                        );
                                    })}
                                </div>

                                <div className="flex justify-between items-center mt-4">
                                    <div className="text-2xl font-black">€{(order.total_amount || 0).toFixed(2)}</div>

                                    {order.status === 'PAID' && (
                                        <button
                                            onClick={() => toggleStatus(order.order_id, order.status)}
                                            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white px-6 py-3 rounded-xl font-bold transition-colors"
                                        >
                                            <ChefHat size={20} />
                                            A COCINA
                                        </button>
                                    )}

                                    {order.status === 'PREPARING' && (
                                        <button
                                            onClick={() => toggleStatus(order.order_id, order.status)}
                                            className="flex items-center gap-2 bg-orange-600 hover:bg-orange-500 text-white px-6 py-3 rounded-xl font-bold transition-colors"
                                        >
                                            <Flame size={20} />
                                            TERMINAR
                                        </button>
                                    )}

                                    {order.status === 'READY' && (
                                        <button
                                            onClick={() => toggleStatus(order.order_id, order.status)}
                                            className="flex items-center gap-2 bg-green-600 hover:bg-green-500 text-white px-6 py-3 rounded-xl font-bold transition-colors"
                                        >
                                            <CheckCircle size={20} />
                                            ENTREGADO
                                        </button>
                                    )}

                                    {order.status === 'DELIVERED' && (
                                        <span className="text-gray-500 font-bold italic">COMPLETADO</span>
                                    )}
                                </div>
                            </div>
                        );
                    })}
                </div>

                {displayedOrders.length === 0 && !loading && (
                    <div className="text-center text-gray-500 mt-20">
                        <Clock size={48} className="mx-auto mb-4" />
                        <p>{showHistory ? "No hay pedidos en el historial" : "No hay pedidos activos"}</p>
                    </div>
                )}
            </div>
        </Layout>
    );
};

export default OrdersPage;

```

---

## `Web_Panel/src/pages/ProductsPage.tsx`

```tsx
import { useEffect, useState } from 'react';
import { api } from '../services/apiClient';
import { Layout } from '../components/Layout';
import { Plus, Edit2, Trash2, Save, X } from 'lucide-react';

interface Product {
    id: string;
    name: string;
    price: number;
    category: string;
    emoji: string;
    in_stock: boolean; // boolean stored as 1/0
}

const INITIAL_PRODUCTS = [
    { name: "Bocadillo Jamón", price: 6.50, category: "Comida", emoji: "🥪", in_stock: true },
    { name: "Cerveza Estrella", price: 5.00, category: "Bebidas", emoji: "🍺", in_stock: true },
    { name: "Hot Dog", price: 5.50, category: "Comida", emoji: "🌭", in_stock: true },
    { name: "Agua 500ml", price: 2.50, category: "Bebidas", emoji: "💧", in_stock: true },
    { name: "Nachos con Queso", price: 7.00, category: "Comida", emoji: "🧀", in_stock: true },
    { name: "Coca-Cola", price: 3.50, category: "Bebidas", emoji: "🥤", in_stock: true },
    { name: "Gorra Oficial", price: 35.00, category: "Merch", emoji: "🧢", in_stock: true },
    { name: "Camiseta Equipo", price: 45.00, category: "Merch", emoji: "👕", in_stock: true }
];

const ProductsPage = () => {
    const [products, setProducts] = useState<Product[]>([]);
    const [editMode, setEditMode] = useState<string | null>(null);
    const [editedProduct, setEditedProduct] = useState<Partial<Product>>({});

    useEffect(() => {
        fetchProducts();
    }, []);

    const fetchProducts = async () => {
        try {
            const data = await api.get<Product>('products');
            if (data.length === 0) {
                // Auto-seed for first run
                await seedProducts();
            } else {
                setProducts(data);
            }
        } catch (e) {
            console.error(e);
        }
    };

    const seedProducts = async () => {
        for (const p of INITIAL_PRODUCTS) {
            await api.upsert('products', { ...p, id: crypto.randomUUID() });
        }
        const data = await api.get<Product>('products');
        setProducts(data);
    };

    const handleSave = async () => {
        if (!editedProduct.name || !editedProduct.price) return;

        try {
            const id = editMode === 'new' ? crypto.randomUUID() : editMode;
            await api.upsert('products', {
                id,
                ...editedProduct,
                price: Number(editedProduct.price),
                in_stock: editedProduct.in_stock ? 1 : 0
            });

            setEditMode(null);
            setEditedProduct({});
            fetchProducts();
        } catch (e) {
            console.error(e);
            alert('Error al guardar');
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('¿Eliminar producto?')) return;
        try {
            await api.delete('products', { id });
            setProducts(prev => prev.filter(p => p.id !== id));
        } catch (e) {
            console.error(e);
        }
    };

    return (
        <Layout>
            <div className="p-8 max-w-7xl mx-auto">
                <div className="flex justify-between items-center mb-8">
                    <div>
                        <h1 className="text-4xl font-black text-white italic tracking-tighter">GESTIÓN MENU</h1>
                        <p className="text-gray-400 mt-2">Controla el stock y precios en tiempo real</p>
                    </div>
                    <button
                        onClick={() => {
                            setEditMode('new');
                            setEditedProduct({ in_stock: true, category: 'Comida', emoji: '🍔' });
                        }}
                        className="bg-red-600 hover:bg-red-500 text-white px-6 py-3 rounded-xl font-bold flex items-center gap-2"
                    >
                        <Plus size={20} />
                        NUEVO PRODUCTO
                    </button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {/* Editor Card (New) */}
                    {editMode === 'new' && (
                        <ProductEditor
                            product={editedProduct}
                            onChange={setEditedProduct}
                            onSave={handleSave}
                            onCancel={() => setEditMode(null)}
                        />
                    )}

                    {products.map(product => (
                        editMode === product.id ? (
                            <ProductEditor
                                key={product.id}
                                product={editedProduct}
                                onChange={setEditedProduct}
                                onSave={handleSave}
                                onCancel={() => setEditMode(null)}
                            />
                        ) : (
                            <div key={product.id} className={`p-6 rounded-2xl border ${product.in_stock ? 'bg-gray-900/50 border-gray-800' : 'bg-red-900/20 border-red-900/50'} backdrop-blur-sm relative group`}>
                                <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                    <button
                                        onClick={() => {
                                            setEditMode(product.id);
                                            setEditedProduct({ ...product, in_stock: Boolean(product.in_stock) });
                                        }}
                                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700"
                                    >
                                        <Edit2 size={16} />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(product.id)}
                                        className="p-2 bg-gray-800 rounded-lg hover:bg-red-900/50 text-red-500"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>

                                <div className="flex justify-between items-start mb-4">
                                    <div className="w-16 h-16 rounded-xl bg-gray-800 flex items-center justify-center text-4xl">
                                        {product.emoji}
                                    </div>
                                    <div className={`px-3 py-1 rounded-full text-xs font-bold ${product.in_stock ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}`}>
                                        {product.in_stock ? 'EN STOCK' : 'AGOTADO'}
                                    </div>
                                </div>

                                <h3 className="text-xl font-bold text-white mb-1">{product.name}</h3>
                                <p className="text-gray-500 text-sm mb-4">{product.category}</p>
                                <div className="text-2xl font-black text-red-500">€{Number(product.price).toFixed(2)}</div>
                            </div>
                        )
                    ))}
                </div>
            </div>
        </Layout>
    );
};

const ProductEditor = ({ product, onChange, onSave, onCancel }: any) => (
    <div className="p-6 rounded-2xl bg-gray-800 border border-gray-700">
        <div className="flex justify-between mb-4">
            <h3 className="font-bold text-white">Editar Producto</h3>
            <button onClick={onCancel}><X size={20} className="text-gray-400" /></button>
        </div>
        <div className="space-y-4">
            <div>
                <label className="text-xs text-gray-500 block mb-1">Nombre</label>
                <input
                    className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2 text-white"
                    value={product.name || ''}
                    onChange={e => onChange({ ...product, name: e.target.value })}
                />
            </div>
            <div className="flex gap-4">
                <div className="flex-1">
                    <label className="text-xs text-gray-500 block mb-1">Precio (€)</label>
                    <input
                        type="number"
                        className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2 text-white"
                        value={product.price || ''}
                        onChange={e => onChange({ ...product, price: e.target.value })}
                    />
                </div>
                <div className="w-20">
                    <label className="text-xs text-gray-500 block mb-1">Emoji</label>
                    <input
                        className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2 text-white text-center"
                        value={product.emoji || ''}
                        onChange={e => onChange({ ...product, emoji: e.target.value })}
                    />
                </div>
            </div>
            <div className="flex items-center gap-2">
                <input
                    type="checkbox"
                    checked={product.in_stock}
                    onChange={e => onChange({ ...product, in_stock: e.target.checked })}
                    className="w-5 h-5 rounded bg-gray-900 border-gray-700"
                />
                <span className="text-white">Disponible en Stock</span>
            </div>
            <button
                onClick={onSave}
                className="w-full bg-green-600 hover:bg-green-500 text-white py-3 rounded-xl font-bold flex justify-center items-center gap-2 mt-2"
            >
                <Save size={18} />
                GUARDAR
            </button>
        </div>
    </div>
);

export default ProductsPage;

```

---

## `Web_Panel/src/pages/Routes.tsx`

```tsx
import { useState, useEffect, useCallback } from "react";
import { Layout } from "../components/Layout";
import { Route, RouteStatus } from "../types";
import { api } from "../services/apiClient";
import { Navigation, Gauge, Radio, Clock, ArrowRight, Target, Lock, RefreshCw } from "lucide-react";

const SEED_ROUTES: Route[] = [
  { id: "parking-norte-grada-t1", name: "Parking Norte → Grada T1", origin: "Parking Norte", destination: "Grada T1", status: "OPERATIVA", activeUsers: 0, capacity: 600, capacityPercentage: 0, averageSpeed: 1.1, distance: 800, signalQuality: 95, estimatedTime: 12, velocity: 1.1 },
  { id: "parking-sur-grada-t2", name: "Parking Sur → Grada T2", origin: "Parking Sur", destination: "Grada T2", status: "OPERATIVA", activeUsers: 0, capacity: 800, capacityPercentage: 0, averageSpeed: 0.6, distance: 650, signalQuality: 88, estimatedTime: 18, velocity: 0.6 },
  { id: "fan-zone-paddock", name: "Fan Zone → Paddock VIP", origin: "Fan Zone Principal", destination: "Paddock VIP", status: "OPERATIVA", activeUsers: 0, capacity: 450, capacityPercentage: 0, averageSpeed: 1.5, distance: 420, signalQuality: 97, estimatedTime: 5, velocity: 1.5 },
  { id: "grada-t1-fan-zone", name: "Grada T1 → Fan Zone", origin: "Grada T1", destination: "Fan Zone", status: "OPERATIVA", activeUsers: 0, capacity: 350, capacityPercentage: 0, averageSpeed: 1.3, distance: 580, signalQuality: 91, estimatedTime: 7, velocity: 1.3 },
  { id: "parking-este-grada-t3", name: "Parking Este → Grada T3", origin: "Parking Este", destination: "Grada T3", status: "OPERATIVA", activeUsers: 0, capacity: 500, capacityPercentage: 0, averageSpeed: 0, distance: 720, signalQuality: 0, estimatedTime: 0, velocity: 0 },
  { id: "metro-fan-zone-tech", name: "Metro → Fan Zone Tech", origin: "Estación Metro", destination: "Fan Zone Tecnológica", status: "OPERATIVA", activeUsers: 0, capacity: 550, capacityPercentage: 0, averageSpeed: 1.0, distance: 900, signalQuality: 82, estimatedTime: 15, velocity: 1.0 },
  { id: "paddock-grada-t2", name: "Paddock → Grada T2", origin: "Paddock VIP", destination: "Grada T2", status: "OPERATIVA", activeUsers: 0, capacity: 250, capacityPercentage: 0, averageSpeed: 1.4, distance: 550, signalQuality: 92, estimatedTime: 9, velocity: 1.4 },
];

export function Routes() {
  const [routes, setRoutes] = useState<Route[]>([]);
  const [loading, setLoading] = useState(true);

  const loadRoutes = useCallback(async () => {
    try {
      setLoading(true);
      let data = await api.get<any>("routes");
      if (!data || data.length === 0) {
        for (const r of SEED_ROUTES) {
          await api.upsert("routes", {
            ...r,
            active_users: r.activeUsers,
            capacity_percentage: r.capacityPercentage,
            average_speed: r.averageSpeed,
            signal_quality: r.signalQuality,
            estimated_time: r.estimatedTime,
            updated_at: new Date().toISOString(),
          });
        }
        data = await api.get<any>("routes");
      }
      const mapped: Route[] = data.map((r: any) => ({
        id: r.id || r.route_id,
        name: r.name || `${r.origin} → ${r.destination}`,
        origin: r.origin || "",
        destination: r.destination || "",
        status: r.status || "OPERATIVA",
        activeUsers: r.active_users ?? r.activeUsers ?? 0,
        capacity: r.capacity ?? 0,
        capacityPercentage: r.capacity_percentage ?? r.capacityPercentage ?? (r.capacity > 0 ? Math.round(((r.active_users ?? r.activeUsers ?? 0) / r.capacity) * 100) : 0),
        averageSpeed: r.average_speed ?? r.averageSpeed ?? 0,
        distance: r.distance ?? 0,
        signalQuality: r.signal_quality ?? r.signalQuality ?? 0,
        estimatedTime: r.estimated_time ?? r.estimatedTime ?? 0,
        velocity: r.velocity ?? 0,
      }));
      setRoutes(mapped);
    } catch (err) {
      console.error("Error loading routes:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadRoutes();
    const interval = setInterval(loadRoutes, 15000);
    return () => clearInterval(interval);
  }, [loadRoutes]);

  const updateRouteStatus = async (routeId: string, newStatus: RouteStatus) => {
    try {
      const route = routes.find((r) => r.id === routeId);
      if (!route) return;
      const updatedUsers = newStatus === "CERRADA" ? 0 : route.activeUsers;
      const updatedPct = newStatus === "CERRADA" ? 0 : route.capacityPercentage;
      await api.upsert("routes", {
        id: routeId,
        status: newStatus,
        active_users: updatedUsers,
        capacity_percentage: updatedPct,
        updated_at: new Date().toISOString(),
      });
      await loadRoutes();
    } catch (err) {
      console.error("Error updating route status:", err);
    }
  };

  const getStatusColor = (status: RouteStatus) => {
    switch (status) {
      case "OPERATIVA":
        return "bg-green-500/20 text-green-400 border-green-500/30";
      case "SATURADA":
        return "bg-yellow-500/20 text-yellow-400 border-yellow-500/30";
      case "CERRADA":
        return "bg-red-500/20 text-red-400 border-red-500/30";
      case "MANTENIMIENTO":
        return "bg-purple-500/20 text-purple-400 border-purple-500/30";
      default:
        return "bg-gray-500/20 text-gray-400 border-gray-500/30";
    }
  };

  const getCapacityColor = (percentage: number) => {
    if (percentage >= 90) return "bg-red-500";
    if (percentage >= 70) return "bg-yellow-500";
    return "bg-green-500";
  };

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-white">Rutas del Circuito</h2>
          <button
            onClick={loadRoutes}
            disabled={loading}
            className="flex items-center space-x-2 px-3 py-2 bg-dark-700 text-white rounded hover:bg-dark-600 transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            <span className="text-sm">Actualizar</span>
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {routes.map((route) => (
            <div
              key={route.id}
              className="bg-dark-800 border border-dark-700 rounded-lg p-4 hover:border-blue-500/50 transition-all"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <h3 className="text-white font-medium mb-2">{route.name}</h3>
                  <div className="flex items-center text-xs text-gray-400 space-x-1">
                    <span>{route.origin}</span>
                    <ArrowRight className="w-3 h-3" />
                    <span>{route.destination}</span>
                  </div>
                </div>
                <span
                  className={`px-2 py-1 text-xs font-medium rounded border ${getStatusColor(route.status)}`}
                >
                  {route.status}
                </span>
              </div>

              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-400">Usuarios Activos</span>
                  <span className="text-2xl font-bold text-red-400">{route.activeUsers}</span>
                </div>
                <div className="flex items-center justify-between text-xs text-gray-400 mb-1">
                  <span>Tiempo Estimado</span>
                  <span>{route.estimatedTime > 0 ? `${route.estimatedTime} min` : "–"}</span>
                </div>
              </div>

              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-400">Capacidad</span>
                  <span className="text-sm text-white">{route.capacityPercentage}%</span>
                </div>
                <div className="h-2 bg-dark-700 rounded-full overflow-hidden">
                  <div
                    className={`h-full transition-all ${getCapacityColor(route.capacityPercentage)}`}
                    style={{ width: `${Math.min(route.capacityPercentage, 100)}%` }}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 mb-4">
                <div className="flex items-center space-x-2">
                  <Gauge className="w-4 h-4 text-gray-400" />
                  <div>
                    <div className="text-xs text-gray-400">Velocidad</div>
                    <div className="text-sm text-white font-medium">
                      {route.velocity > 0 ? `${route.velocity} m/s` : "0.0 m/s"}
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <Navigation className="w-4 h-4 text-gray-400" />
                  <div>
                    <div className="text-xs text-gray-400">Distancia</div>
                    <div className="text-sm text-white font-medium">{route.distance}m</div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <Radio className="w-4 h-4 text-gray-400" />
                  <div>
                    <div className="text-xs text-gray-400">Señal</div>
                    <div
                      className={`text-sm font-medium ${
                        route.signalQuality >= 90
                          ? "text-green-400"
                          : route.signalQuality >= 70
                          ? "text-yellow-400"
                          : "text-red-400"
                      }`}
                    >
                      {route.signalQuality > 0 ? `${route.signalQuality}%` : "0%"}
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <Clock className="w-4 h-4 text-gray-400" />
                  <div>
                    <div className="text-xs text-gray-400">Estimado</div>
                    <div className="text-sm text-white font-medium">
                      {route.estimatedTime > 0 ? `${route.estimatedTime} min` : "–"}
                    </div>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 pt-3 border-t border-dark-700">
                {route.status !== "SATURADA" && route.status !== "CERRADA" && (
                  <button
                    onClick={() => updateRouteStatus(route.id, "SATURADA")}
                    className="flex items-center justify-center space-x-2 px-3 py-2 bg-gradient-to-r from-pink-500 to-blue-500 text-white rounded hover:opacity-90 transition-opacity"
                  >
                    <Target className="w-4 h-4" />
                    <span className="text-sm">Saturar</span>
                  </button>
                )}
                {route.status !== "CERRADA" && (
                  <button
                    onClick={() => updateRouteStatus(route.id, "CERRADA")}
                    className="flex items-center justify-center space-x-2 px-3 py-2 bg-dark-700 text-white rounded hover:bg-dark-600 transition-colors"
                  >
                    <Lock className="w-4 h-4" />
                    <span className="text-sm">Cerrar</span>
                  </button>
                )}
              </div>

              {(route.status === "CERRADA" || route.status === "SATURADA") && (
                <div className="pt-3">
                  <button
                    onClick={() => updateRouteStatus(route.id, "OPERATIVA")}
                    className="w-full flex items-center justify-center space-x-2 px-3 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
                  >
                    <Navigation className="w-4 h-4" />
                    <span className="text-sm">Abrir Ruta</span>
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </Layout>
  );
}

```

---

## `Web_Panel/src/pages/Statistics.tsx`

```tsx
import { useState, useEffect } from "react";
import { Layout } from "../components/Layout";
import { SystemStats, TrafficPeak } from "../types";
import { Users, TrendingUp, Percent } from "lucide-react";

export function Statistics() {
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [trafficPeaks, setTrafficPeaks] = useState<TrafficPeak[]>([]);

  useEffect(() => {
    // Datos de ejemplo - en producción vendría de Firestore
    const mockStats: SystemStats = {
      activeVisitors: 30336,
      dailyTotal: 47523,
      satisfaction: 92.5,
      activeZones: 8,
      totalZones: 8,
      operationalRoutes: 6,
      totalRoutes: 8,
      activeBeacons: 10,
      totalBeacons: 12,
      activeAlerts: 6,
      avgVisitTime: 187,
      dailyRevenue: 12847
    };

    const mockTrafficPeaks: TrafficPeak[] = [
      { time: "10:00", count: 5200 },
      { time: "12:00", count: 8900 },
      { time: "14:00", count: 12300 },
      { time: "16:00", count: 9100 }
    ];

    setStats(mockStats);
    setTrafficPeaks(mockTrafficPeaks);
  }, []);

  if (!stats) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-gray-400">Cargando estadísticas...</div>
        </div>
      </Layout>
    );
  }

  const maxPeak = Math.max(...trafficPeaks.map(p => p.count));

  return (
    <Layout>
      <div className="space-y-6">
        {/* Métricas Principales */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Visitantes Activos */}
          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-blue-500/10 rounded-lg">
                <Users className="w-6 h-6 text-blue-400" />
              </div>
            </div>
            <div className="text-5xl font-bold text-white mb-2">
              {stats.activeVisitors.toLocaleString()}
            </div>
            <div className="text-sm text-gray-400 uppercase tracking-wide">
              VISITANTES ACTIVOS
            </div>
          </div>

          {/* Total del Día */}
          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-green-500/10 rounded-lg">
                <TrendingUp className="w-6 h-6 text-green-400" />
              </div>
            </div>
            <div className="text-5xl font-bold text-white mb-2">
              {stats.dailyTotal.toLocaleString()}
            </div>
            <div className="text-sm text-gray-400 uppercase tracking-wide">
              TOTAL DEL DÍA
            </div>
          </div>

          {/* Satisfacción */}
          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-yellow-500/10 rounded-lg">
                <Percent className="w-6 h-6 text-yellow-400" />
              </div>
            </div>
            <div className="text-5xl font-bold text-yellow-400 mb-2">
              {stats.satisfaction}%
            </div>
            <div className="text-sm text-gray-400 uppercase tracking-wide">
              SATISFACCIÓN
            </div>
          </div>
        </div>

        {/* Estadísticas del Sistema y Picos de Afluencia */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Estadísticas del Sistema */}
          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <h2 className="text-xl font-semibold text-white mb-6">
              Estadísticas del Sistema
            </h2>
            <div className="space-y-4">
              {/* Zonas Activas */}
              <div className="flex items-center justify-between py-3 border-b border-dark-700">
                <span className="text-gray-400">Zonas Activas</span>
                <span className="text-lg font-semibold text-green-400">
                  {stats.activeZones} / {stats.totalZones}
                </span>
              </div>

              {/* Rutas Operativas */}
              <div className="flex items-center justify-between py-3 border-b border-dark-700">
                <span className="text-gray-400">Rutas Operativas</span>
                <span className="text-lg font-semibold text-green-400">
                  {stats.operationalRoutes} / {stats.totalRoutes}
                </span>
              </div>

              {/* Balizas Activas */}
              <div className="flex items-center justify-between py-3 border-b border-dark-700">
                <span className="text-gray-400">Balizas Activas</span>
                <span className="text-lg font-semibold text-green-400">
                  {stats.activeBeacons} / {stats.totalBeacons}
                </span>
              </div>

              {/* Alertas Activas */}
              <div className="flex items-center justify-between py-3 border-b border-dark-700">
                <span className="text-gray-400">Alertas Activas</span>
                <span className="text-lg font-semibold text-red-400">
                  {stats.activeAlerts}
                </span>
              </div>

              {/* Tiempo Promedio de Visita */}
              <div className="flex items-center justify-between py-3 border-b border-dark-700">
                <span className="text-gray-400">Tiempo Promedio de Visita</span>
                <span className="text-lg font-semibold text-white">
                  {stats.avgVisitTime} min
                </span>
              </div>

              {/* Ingresos del Día */}
              <div className="flex items-center justify-between py-3">
                <span className="text-gray-400">Ingresos del Día</span>
                <span className="text-lg font-semibold text-green-400">
                  {stats.dailyRevenue.toLocaleString()}
                </span>
              </div>
            </div>
          </div>

          {/* Picos de Afluencia */}
          <div className="bg-dark-800 border border-dark-700 rounded-lg p-6">
            <h2 className="text-xl font-semibold text-white mb-6">
              Picos de Afluencia
            </h2>
            <div className="space-y-6">
              {trafficPeaks.map((peak, index) => {
                const percentage = (peak.count / maxPeak) * 100;
                
                return (
                  <div key={index}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-gray-400 font-medium">{peak.time}</span>
                      <span className="text-xl font-bold text-white">
                        {peak.count.toLocaleString()}
                      </span>
                    </div>
                    <div className="h-8 bg-dark-700 rounded-lg overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all flex items-center justify-end px-3"
                        style={{ width: `${percentage}%` }}
                      >
                        {percentage > 30 && (
                          <span className="text-xs font-semibold text-white">
                            {Math.round(percentage)}%
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}

```

---

## `Web_Panel/src/pages/UsersPage.tsx`

```tsx
import React, { useState, useEffect } from "react";
import { api } from "../services/apiClient";
import { Users, Award, Search, Loader2 } from "lucide-react";
import { useToast } from "../context/ToastContext";
import { Layout } from "../components/Layout";

interface UserDB {
  id: string;
  uid: string;
  email: string;
  display_name: string;
  photo_url?: string;
}

interface FanProfile {
  id: string; // from gamification_profile
  totalXP: number;
  level: number;
  circuitsVisited: number;
  kmWalked: number;
}

const COLLECTIBLES_MAP: Record<string, string> = {
  "c01": "Fernando Alonso", "c02": "Lewis Hamilton", "c03": "Max Verstappen", "c04": "Marc Márquez", "c05": "Pecco Bagnaia",
  "c06": "Marchador", "c07": "Corredor", "c25": "Maratonista",
  "c08": "Primera Foto", "c09": "Fotógrafo", "c10": "Paparazzi",
  "c11": "Primer Pedido", "c12": "Gourmet", "c13": "Master Chef",
  "c14": "VIP Access", "c15": "Pit Lane",
  "c16": "Eco Warrior", "c17": "Planeta Verde",
  "c18": "Nocturno", "c19": "Madrugador", "c20": "Bajo la Lluvia",
  "c21": "Leyenda GeoRacing", "c22": "Fiel al Circuito", "c23": "El Primero", "c24": "Grupo Legendario"
};

export const UsersPage: React.FC = () => {
  const [realUsers, setRealUsers] = useState<UserDB[]>([]);
  const [profiles, setProfiles] = useState<Record<string, FanProfile>>({});
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedUser, setSelectedUser] = useState<UserDB | null>(null);
  const [givingCollectible, setGivingCollectible] = useState<string | null>(null);
  const { showToast } = useToast();

  const fetchUsers = async () => {
    try {
      setLoading(true);
      // Fetch both real users and the gamification profiles
      const usersRes = await api.get<UserDB>("users") || [];
      const profilesRes = await api.get<FanProfile>("gamification_profile") || [];

      // Usualmente mapearíamos por el uid real. Pero como la app asume current_user a veces, mapearemos
      // tanto el current_user como cualquier profile asociado por id.
      const profileMap: Record<string, FanProfile> = {};
      profilesRes.forEach(p => {
        profileMap[p.id] = p; // id podría ser current_user, o el uid de firebase.
      });
      setProfiles(profileMap);

      // Desduplicar usuarios de la tabla DB (en caso de que la API devuelva múltiples filas por el mismo UID)
      const uniqueUsersMap = new Map<string, UserDB>();
      usersRes.forEach(u => {
        if (!uniqueUsersMap.has(u.uid)) uniqueUsersMap.set(u.uid, u);
      });
      const deduplicatedUsers = Array.from(uniqueUsersMap.values());

      const mergedUsers: UserDB[] = [...deduplicatedUsers];

      // Añadir perfiles que no estén en la tabla de usuarios
      profilesRes.forEach(p => {
        // Ignorar el perfil genérico "current_user" que se crea cuando la app se usa sin loguearse
        if (p.id.toLowerCase() === "current_user") return;

        const existsInUsers = usersRes.find(u => u.uid === p.id || u.id === p.id);
        if (!existsInUsers) {
          mergedUsers.push({
            id: p.id,
            uid: p.id,
            email: "Simulado en App (gamification_profile)",
            display_name: p.id
          });
        }
      });

      setRealUsers(mergedUsers);

    } catch (error) {
      console.error("Error fetching users:", error);
      showToast("Error al cargar usuarios", "error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleGiveCollectible = async (uid: string, collectibleId: string) => {
    try {
      setGivingCollectible(collectibleId);

      // Upsert a user_collectibles para desbloquearlo permanentemente
      await api.upsert("user_collectibles", {
        id: `${uid}_${collectibleId}`,
        user_id: uid,
        collectible_id: collectibleId,
        unlocked: true,
        unlocked_at: Math.floor(Date.now() / 1000)
      });

      showToast(`Cromo ${COLLECTIBLES_MAP[collectibleId] || collectibleId} otorgado a ${uid}`, "success");
    } catch (error) {
      console.error("Error giving collectible:", error);
      showToast("Error al otorgar cromo", "error");
    } finally {
      setGivingCollectible(null);
    }
  };

  const filteredUsers = realUsers.filter((u) =>
    (u.display_name?.toLowerCase() || "").includes(searchTerm.toLowerCase()) ||
    (u.email?.toLowerCase() || "").includes(searchTerm.toLowerCase())
  );

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold flex items-center gap-2">
              <Users className="text-blue-500" />
              Usuarios Registrados
            </h2>
            <p className="text-gray-400">Ver fans de la app y otorgar cromos especiales</p>
          </div>
          <button
            onClick={fetchUsers}
            className="px-4 py-2 bg-dark-700 hover:bg-dark-600 rounded-lg flex items-center gap-2 text-sm"
          >
            <Loader2 className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            Refrescar
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Lista de Usuarios (Con Tabla Real) */}
          <div className="lg:col-span-1 space-y-4">
            <div className="relative">
              <Search className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Buscar por Nombre / Email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-dark-800 border border-dark-700 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div className="bg-dark-800 rounded-xl overflow-hidden border border-dark-700">
              {loading && realUsers.length === 0 ? (
                <div className="p-8 text-center text-gray-400">Cargando usuarios reales...</div>
              ) : filteredUsers.length === 0 ? (
                <div className="p-8 text-center text-gray-400">No hay usuarios con este criterio</div>
              ) : (
                <div className="divide-y divide-dark-700 max-h-[600px] overflow-y-auto">
                  {filteredUsers.map((user) => {
                    // Mapeo solo al perfil real del usuario, evitando heredar el genérico "current_user"
                    const profile = profiles[user.uid] || null;
                    return (
                      <button
                        key={user.id}
                        onClick={() => setSelectedUser(user)}
                        className={`w-full text-left p-4 transition-all flex items-center gap-4 border-l-4 ${selectedUser?.id === user.id
                          ? "bg-dark-700/80 border-blue-500 shadow-md"
                          : "bg-transparent border-transparent hover:bg-dark-700/50 hover:border-dark-600"
                          }`}
                      >
                        {user.photo_url ? (
                          <img src={user.photo_url} alt="Profile" className="w-12 h-12 rounded-full bg-dark-900 border-2 border-dark-700 object-cover shadow-sm" />
                        ) : (
                          <div className="w-12 h-12 rounded-full bg-dark-900 border-2 border-dark-700 flex items-center justify-center shadow-sm">
                            <Users className="w-5 h-5 text-gray-500" />
                          </div>
                        )}

                        <div className="flex-1">
                          <div className="font-semibold text-sm line-clamp-1">{user.display_name || "Sin nombre"}</div>
                          <div className="text-xs text-gray-400 line-clamp-1">{user.email}</div>
                          {profile && (
                            <div className="flex items-center gap-3 mt-1 text-[10px] text-gray-500 font-medium">
                              <span className="flex items-center gap-1">
                                <Award className="w-3 h-3 text-purple-400" />
                                Nvl {Math.floor((profile.totalXP || 0) / 250) + 1}
                              </span>
                              <span>{profile.totalXP || 0} XP</span>
                            </div>
                          )}
                        </div>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Detalles y Cromos */}
          <div className="lg:col-span-2">
            {selectedUser ? (
              <div className="space-y-6">
                {/* Info de Perfil */}
                <div className="bg-dark-800 rounded-xl p-6 border border-dark-700 flex flex-col sm:flex-row items-center sm:items-start gap-6 shadow-sm">
                  {selectedUser.photo_url ? (
                    <img src={selectedUser.photo_url} alt="Profile" className="w-24 h-24 rounded-full bg-dark-900 shadow-xl border-4 border-dark-700 object-cover" />
                  ) : (
                    <div className="w-24 h-24 rounded-full bg-dark-900 border-4 border-dark-700 flex items-center justify-center shadow-xl">
                      <Users className="w-10 h-10 text-gray-600" />
                    </div>
                  )}
                  <div className="flex-1 text-center sm:text-left mt-2 sm:mt-0">
                    <h3 className="text-3xl font-bold text-white mb-1">
                      {selectedUser.display_name || "Sin nombre"}
                    </h3>
                    <div className="text-blue-400 font-medium mb-3">{selectedUser.email || "Sin email"}</div>
                    <div className="inline-block bg-dark-900 px-3 py-1.5 rounded-lg border border-dark-700">
                      <p className="text-xs text-gray-400 uppercase font-mono tracking-wider">
                        UID: <span className="text-gray-200">{selectedUser.uid}</span>
                      </p>
                    </div>
                  </div>
                </div>

                {/* Estadísticas del usuario */}
                {(() => {
                  const profile = profiles[selectedUser.uid];
                  if (!profile) return (
                    <div className="bg-dark-800 rounded-xl p-6 border border-dark-700 text-center text-gray-500 shadow-sm text-sm">
                      No hay datos de gamificación disponibles para este usuario.
                    </div>
                  );
                  return (
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                      <div className="bg-dark-800 border border-dark-700 p-5 rounded-xl text-center shadow-sm">
                        <div className="text-xs text-gray-400 uppercase tracking-widest mb-1 font-semibold">Nivel</div>
                        <div className="text-3xl font-extrabold text-blue-500">
                          {Math.floor((profile.totalXP || 0) / 250) + 1}
                        </div>
                      </div>
                      <div className="bg-dark-800 border border-dark-700 p-5 rounded-xl text-center shadow-sm">
                        <div className="text-xs text-gray-400 uppercase tracking-widest mb-1 font-semibold">Total XP</div>
                        <div className="text-3xl font-extrabold text-white">{profile.totalXP || 0}</div>
                      </div>
                      <div className="bg-dark-800 border border-dark-700 p-5 rounded-xl text-center shadow-sm">
                        <div className="text-xs text-gray-400 uppercase tracking-widest mb-1 font-semibold">Km Recorridos</div>
                        <div className="text-3xl font-extrabold text-green-400">{profile.kmWalked || 0}</div>
                      </div>
                      <div className="bg-dark-800 border border-dark-700 p-5 rounded-xl text-center shadow-sm">
                        <div className="text-xs text-gray-400 uppercase tracking-widest mb-1 font-semibold">Circuitos</div>
                        <div className="text-3xl font-extrabold text-yellow-500">{profile.circuitsVisited || 0}</div>
                      </div>
                    </div>
                  );
                })()}

                {/* Botonera de Cromos */}
                <div className="bg-dark-800 rounded-xl overflow-hidden border border-dark-700 shadow-sm">
                  <div className="p-5 border-b border-dark-700 bg-dark-800/50">
                    <h3 className="text-lg font-bold flex items-center gap-2 text-white">
                      <Award className="w-5 h-5 text-yellow-500" />
                      Otorgar Cromos Digitales
                    </h3>
                    <p className="text-xs text-gray-400 mt-1">Haz clic en un cromo para adjuntarlo directamente a la cuenta del usuario seleccionado.</p>
                  </div>

                  <div className="p-5 grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-5 gap-4">
                    {Object.entries(COLLECTIBLES_MAP).map(([id, name]) => (
                      <button
                        key={id}
                        onClick={() => handleGiveCollectible(selectedUser.uid, id)}
                        disabled={givingCollectible === id}
                        className="group flex flex-col items-center justify-center p-4 rounded-xl border border-dark-700 bg-dark-900/40 hover:bg-dark-700 hover:border-yellow-500/40 transition-all disabled:opacity-50"
                      >
                        {givingCollectible === id ? (
                          <Loader2 className="w-10 h-10 animate-spin text-yellow-500 mb-3" />
                        ) : (
                          <div className="relative w-12 h-16 bg-gradient-to-br from-yellow-800/80 to-yellow-900/80 rounded-sm mb-3 flex items-center justify-center shadow-md border border-yellow-500/20 group-hover:from-yellow-600 group-hover:to-orange-500 transition-all duration-300 transform group-hover:-translate-y-1">
                            <div className="absolute inset-0 bg-gradient-to-tr from-white/0 via-white/10 to-white/0 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                            <span className="text-sm font-bold text-yellow-200/80 group-hover:text-white drop-shadow-sm">{id}</span>
                          </div>
                        )}
                        <span className="text-[11px] leading-tight text-center font-medium text-gray-400 group-hover:text-white transition-colors">{name}</span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="h-full bg-dark-800 rounded-xl border border-dark-700 flex flex-col items-center justify-center p-12 text-gray-500 min-h-[500px] shadow-sm">
                <Users className="w-16 h-16 mb-4 opacity-50 text-gray-600" />
                <p className="text-lg font-medium text-gray-400">Selecciona un usuario</p>
                <p className="text-sm mt-2 opacity-70">Haz clic en un fan de la lista izquierda para ver sus estadísticas o regalarle cromos.</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default UsersPage;

```

---

## `Web_Panel/src/pages/ZonesMap.tsx`

```tsx
import { useState, useEffect, useCallback } from "react";
import { Layout } from "../components/Layout";
import { Zone, ZoneStatus } from "../types";
import { api } from "../services/apiClient";
import { Thermometer, Timer, TrendingUp, TrendingDown, Lock, AlertTriangle, RefreshCw, Unlock } from "lucide-react";

const SEED_ZONES: Zone[] = [
  { id: "grada-t1-recta-principal", name: "Grada T1 - Recta Principal", type: "GRADA", status: "ABIERTA", capacity: 15000, currentOccupancy: 0, temperature: 24.0, waitTime: 0, entryRate: 0, exitRate: 0 },
  { id: "grada-t2-curva-ascari", name: "Grada T2 - Curva Ascari", type: "GRADA", status: "ABIERTA", capacity: 12000, currentOccupancy: 0, temperature: 26.0, waitTime: 0, entryRate: 0, exitRate: 0 },
  { id: "fan-zone-principal", name: "Fan Zone Principal", type: "FANZONE", status: "ABIERTA", capacity: 7600, currentOccupancy: 0, temperature: 25.0, waitTime: 0, entryRate: 0, exitRate: 0 },
  { id: "paddock-vip-boxes", name: "Paddock VIP - Boxes", type: "PADDOCK", status: "ABIERTA", capacity: 3500, currentOccupancy: 0, temperature: 22.0, waitTime: 0, entryRate: 0, exitRate: 0 },
  { id: "vial-acceso-a-norte", name: "Vial Acceso A - Norte", type: "VIAL", status: "ABIERTA", capacity: 5000, currentOccupancy: 0, temperature: 23.0, waitTime: 0, entryRate: 0, exitRate: 0 },
  { id: "grada-t3-chicane", name: "Grada T3 - Chicane", type: "GRADA", status: "ABIERTA", capacity: 18000, currentOccupancy: 0, temperature: 24.0, waitTime: 0, entryRate: 0, exitRate: 0 },
  { id: "fan-zone-tecnologica", name: "Fan Zone Tecnológica", type: "FANZONE", status: "ABIERTA", capacity: 4500, currentOccupancy: 0, temperature: 25.0, waitTime: 0, entryRate: 0, exitRate: 0 },
];

export function ZonesMap() {
  const [zones, setZones] = useState<Zone[]>([]);
  const [loading, setLoading] = useState(true);

  const loadZones = useCallback(async () => {
    try {
      setLoading(true);
      let data = await api.get<any>("zone_traffic");
      if (!data || data.length === 0) {
        for (const z of SEED_ZONES) {
          await api.upsert("zone_traffic", {
            ...z,
            current_occupancy: z.currentOccupancy,
            wait_time: z.waitTime,
            entry_rate: z.entryRate,
            exit_rate: z.exitRate,
            updated_at: new Date().toISOString(),
          });
        }
        data = await api.get<any>("zone_traffic");
      }
      const mapped: Zone[] = data.map((z: any) => ({
        id: z.id || z.zone_id,
        name: z.name || "",
        type: z.type || "GRADA",
        status: z.status || "ABIERTA",
        capacity: z.capacity ?? 0,
        currentOccupancy: z.current_occupancy ?? z.currentOccupancy ?? 0,
        temperature: z.temperature ?? 0,
        waitTime: z.wait_time ?? z.waitTime ?? 0,
        entryRate: z.entry_rate ?? z.entryRate ?? 0,
        exitRate: z.exit_rate ?? z.exitRate ?? 0,
        alerts: z.alerts ?? 0,
        color: z.color,
      }));
      setZones(mapped);
    } catch (err) {
      console.error("Error loading zones:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadZones();
    const interval = setInterval(loadZones, 15000);
    return () => clearInterval(interval);
  }, [loadZones]);

  const updateZoneStatus = async (zoneId: string, newStatus: ZoneStatus) => {
    try {
      await api.upsert("zone_traffic", {
        id: zoneId,
        status: newStatus,
        updated_at: new Date().toISOString(),
      });
      await loadZones();
    } catch (err) {
      console.error("Error updating zone:", err);
    }
  };

  const getStatusColor = (status: ZoneStatus) => {
    switch (status) {
      case "ABIERTA":
      case "OPERATIVA":
        return "bg-green-500/20 text-green-400 border-green-500/30";
      case "SATURADA":
        return "bg-yellow-500/20 text-yellow-400 border-yellow-500/30";
      case "CERRADA":
        return "bg-red-500/20 text-red-400 border-red-500/30";
      case "MANTENIMIENTO":
        return "bg-purple-500/20 text-purple-400 border-purple-500/30";
      default:
        return "bg-gray-500/20 text-gray-400 border-gray-500/30";
    }
  };

  const getOccupancyColor = (percentage: number) => {
    if (percentage >= 85) return "bg-red-500";
    if (percentage >= 60) return "bg-yellow-500";
    return "bg-green-500";
  };

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-white">Zonas del Circuito</h2>
          <button
            onClick={loadZones}
            disabled={loading}
            className="flex items-center space-x-2 px-3 py-2 bg-dark-700 text-white rounded hover:bg-dark-600 transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            <span className="text-sm">Actualizar</span>
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {zones.map((zone) => {
            const occupancyPercentage = zone.capacity > 0 ? Math.round((zone.currentOccupancy / zone.capacity) * 100) : 0;

            return (
              <div
                key={zone.id}
                className="bg-dark-800 border border-dark-700 rounded-lg p-4 hover:border-blue-500/50 transition-all"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-white font-medium mb-1">{zone.name}</h3>
                    <p className="text-xs text-gray-400">Tipo: {zone.type}</p>
                  </div>
                  <span
                    className={`px-2 py-1 text-xs font-medium rounded border ${getStatusColor(zone.status)}`}
                  >
                    {zone.status}
                  </span>
                </div>

                <div className="mb-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-gray-400">Ocupación</span>
                    <span className="text-sm text-white">
                      {zone.currentOccupancy.toLocaleString()} / {zone.capacity.toLocaleString()}
                    </span>
                  </div>
                  <div className="h-2 bg-dark-700 rounded-full overflow-hidden">
                    <div
                      className={`h-full ${getOccupancyColor(occupancyPercentage)}`}
                      style={{ width: `${Math.min(occupancyPercentage, 100)}%` }}
                    />
                  </div>
                  <div className="text-right text-xs text-gray-400 mt-1">{occupancyPercentage}%</div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="flex items-center space-x-2">
                    <Thermometer className="w-4 h-4 text-gray-400" />
                    <div>
                      <div className="text-xs text-gray-400">Temperatura</div>
                      <div className="text-sm text-white font-medium">{zone.temperature}°C</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Timer className="w-4 h-4 text-gray-400" />
                    <div>
                      <div className="text-xs text-gray-400">Espera</div>
                      <div className="text-sm text-white font-medium">{zone.waitTime} min</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <TrendingUp className="w-4 h-4 text-green-400" />
                    <div>
                      <div className="text-xs text-gray-400">Entrada</div>
                      <div className="text-sm text-green-400 font-medium">{zone.entryRate}/min</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <TrendingDown className="w-4 h-4 text-red-400" />
                    <div>
                      <div className="text-xs text-gray-400">Salida</div>
                      <div className="text-sm text-red-400 font-medium">{zone.exitRate}/min</div>
                    </div>
                  </div>
                </div>

                {zone.alerts && zone.alerts > 0 && (
                  <div className="mt-3 pt-3 border-t border-dark-700">
                    <button className="w-full flex items-center justify-center space-x-2 px-3 py-2 bg-yellow-500/10 text-yellow-400 rounded border border-yellow-500/30 hover:bg-yellow-500/20 transition-colors">
                      <AlertTriangle className="w-4 h-4" />
                      <span className="text-sm font-medium">{zone.alerts} ALERTAS ACTIVAS</span>
                    </button>
                  </div>
                )}

                <div className="mt-3 pt-3 border-t border-dark-700 grid grid-cols-2 gap-2">
                  {zone.status !== "CERRADA" ? (
                    <button
                      onClick={() => updateZoneStatus(zone.id, "CERRADA")}
                      className="flex items-center justify-center space-x-2 px-3 py-2 bg-dark-700 text-white rounded hover:bg-dark-600 transition-colors"
                    >
                      <Lock className="w-4 h-4" />
                      <span className="text-sm">Cerrar</span>
                    </button>
                  ) : (
                    <button
                      onClick={() => updateZoneStatus(zone.id, "ABIERTA")}
                      className="flex items-center justify-center space-x-2 px-3 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
                    >
                      <Unlock className="w-4 h-4" />
                      <span className="text-sm">Abrir</span>
                    </button>
                  )}
                  {zone.status !== "SATURADA" && zone.status !== "CERRADA" && (
                    <button
                      onClick={() => updateZoneStatus(zone.id, "SATURADA")}
                      className="flex items-center justify-center space-x-2 px-3 py-2 bg-yellow-500/20 text-yellow-400 rounded border border-yellow-500/30 hover:bg-yellow-500/30 transition-colors"
                    >
                      <AlertTriangle className="w-4 h-4" />
                      <span className="text-sm">Saturar</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </Layout>
  );
}

```

---

## `Web_Panel/src/services/apiClient.ts`

```typescript
import type { Beacon, ZoneDB, Command, BeaconLog } from "../types";

const API_BASE_URL = "http://alpo.myqnapcloud.com:4010/api";

interface RequestOptions extends RequestInit {
  timeout?: number;
  retries?: number;
}

async function request<T>(url: string, options: RequestOptions = {}): Promise<T> {
  const { timeout = 5000, retries = 3, ...fetchOptions } = options;
  const fullUrl = url.startsWith("http") ? url : `${API_BASE_URL}${url}`;

  // Ensure HTTPS
  const secureUrl = fullUrl.replace(/^http:\/\//, "https://");

  let lastError: any;

  for (let i = 0; i <= retries; i++) {
    try {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), timeout);

      const res = await fetch(secureUrl, {
        ...fetchOptions,
        signal: controller.signal,
        headers: {
          "Content-Type": "application/json",
          ...(fetchOptions.headers || {})
        }
      });
      clearTimeout(id);

      if (!res.ok) {
        const errorText = await res.text();
        console.error(`API Error [${secureUrl}]: ${res.status} ${res.statusText} - ${errorText}`);
        throw new Error(errorText || `HTTP ${res.status}`);
      }
      return await res.json();
    } catch (err: any) {
      lastError = err;
      console.warn(`Attempt ${i + 1}/${retries + 1} failed for ${secureUrl}:`, err);
      if (i < retries) {
        await new Promise(resolve => setTimeout(resolve, 500 * Math.pow(2, i)));
      }
    }
  }
  throw lastError;
}

// --- Generic Firestore-like API ---

export const api = {
  /**
   * Generic GET (reads a table, optionally filtered)
   * POST /api/_get { table: "...", where: { ... } }
   */
  get: async <T = any>(table: string, where?: Record<string, any>): Promise<T[]> => {
    return request<T[]>("/_get", {
      method: "POST",
      body: JSON.stringify({ table, where })
    });
  },

  /**
   * Generic UPSERT (creates or updates a record)
   * POST /api/_upsert { table: "...", data: { ... } }
   */
  upsert: async (table: string, data: any): Promise<void> => {
    await request<void>("/_upsert", {
      method: "POST",
      body: JSON.stringify({ table, data })
    });
  },

  /**
   * Generic DELETE
   * POST /api/_delete { table: "...", where: { ... } }
   */
  delete: async (table: string, where: Record<string, any>): Promise<void> => {
    await request<void>("/_delete", {
      method: "POST",
      body: JSON.stringify({ table, where })
    });
  },

  // --- Helpers (wrapping generics) ---

  // Beacons
  getBeacons: async (): Promise<Beacon[]> => {
    const beacons = await api.get<any>("beacons");
    const now = Date.now();
    return beacons.map(b => {
      const lastSeenTime = b.last_heartbeat ? new Date(b.last_heartbeat).getTime() : 0;
      // Consider online if seen in the last 2 minutes (120000ms)
      const isOnline = (now - lastSeenTime) < 120000;

      return {
        ...b,
        beaconId: b.beacon_uid || b.beaconId, // Ensure beaconId is populated
        lastSeen: b.last_heartbeat,
        lastUpdate: b.last_status_change || b.updated_at,
        battery: b.battery_level,
        online: isOnline
      };
    });
  },

  // Zones
  getZones: async (): Promise<ZoneDB[]> => {
    return api.get<ZoneDB>("zones");
  },

  // Commands
  getCommands: async (): Promise<Command[]> => {
    return api.get<Command>("commands");
  },

  getPendingCommands: async (beaconUid: string): Promise<Command[]> => {
    return api.get<Command>("commands", { beacon_uid: beaconUid, executed: false });
  },

  // Circuit State
  getCircuitState: async (): Promise<any> => {
    const states = await api.get<any>("circuit_state", { id: 1 });
    return states[0] || null;
  },

  setCircuitState: async (mode: string, message: string = ""): Promise<void> => {
    await api.upsert("circuit_state", {
      id: "1",
      global_mode: mode,
      message: message,
      last_updated: new Date().toISOString().slice(0, 19).replace('T', ' ')
    });
  },

  // Incidents
  getIncidents: async (): Promise<any[]> => {
    return api.get<any>("incidents");
  },

  // Logs
  getBeaconLogs: async (): Promise<BeaconLog[]> => {
    return api.get<BeaconLog>("beacon_logs");
  }
};

```

---

## `Web_Panel/src/services/beaconDetectionService.ts`

```typescript
import { Beacon } from "../types";
import { api } from "./apiClient";

export interface NewBeaconDetected {
  beaconId: string;
  firstSeen?: string;
  lastSeen?: string;
  online?: boolean;
}

export const beaconDetectionService = {
  subscribeToNewBeacons(callback: (newBeacons: NewBeaconDetected[]) => void) {
    let lastIds = new Set<string>();
    const interval = setInterval(async () => {
      try {
        const beacons = await api.get<Beacon>("beacons", { mode: "UNCONFIGURED" });
        const newBeacons: NewBeaconDetected[] = beacons.filter(b => !lastIds.has(b.beaconId)).map(b => ({
          beaconId: b.beaconId,
          firstSeen: b.lastSeen || ("createdAt" in b ? (b as any).createdAt : undefined),
          lastSeen: b.lastSeen || undefined,
          online: b.online ?? undefined
        }));
        if (newBeacons.length > 0) {
          newBeacons.forEach(b => lastIds.add(b.beaconId));
          callback(newBeacons);
        }
      } catch { }
    }, 4000);
    return () => clearInterval(interval);
  },
  subscribeAndDetectNew(existingBeaconIds: Set<string>, onNewBeacon: (beaconId: string, beacon: Partial<Beacon>) => void) {
    let notified = new Set(existingBeaconIds);
    const interval = setInterval(async () => {
      try {
        const beacons = await api.get<Beacon>("beacons", { mode: "UNCONFIGURED" });
        beacons.forEach(b => {
          if (!notified.has(b.beaconId)) {
            notified.add(b.beaconId);
            onNewBeacon(b.beaconId, b);
          }
        });
      } catch { }
    }, 4000);
    return () => clearInterval(interval);
  }
};

```

---

## `Web_Panel/src/services/beaconService.ts`

```typescript
import { Beacon, BeaconUpdate, EmergencyLog } from "../types";
import { api } from "./apiClient";

/**
 * Converts frontend beacon fields to database column names.
 * Main mapping: 'arrow' -> 'arrow_direction'
 */
function toDbBeacon(data: Record<string, any>): Record<string, any> {
  const { arrow, ...rest } = data;
  return {
    ...rest,
    ...(arrow !== undefined && { arrow: arrow, arrow_direction: arrow })
  };
}

export const beaconsService = {
  subscribeToBeacons(callback: (beacons: Beacon[]) => void, intervalMs: number = 4000) {
    let lastBeacons: string = "";
    const interval = setInterval(async () => {
      try {
        const beacons = await api.getBeacons();
        const hash = JSON.stringify(beacons);
        if (hash !== lastBeacons) {
          lastBeacons = hash;
          callback(beacons);
        }
      } catch (e) {
        // Opcional: manejar error
      }
    }, intervalMs);
    return () => clearInterval(interval);
  },

  /**
   * Configura una baliza individual enviando comando UPDATE_CONFIG
   * Marca automáticamente configured = true al guardar
   */
  configureBeacon: async (beaconId: string, config: BeaconUpdate) => {
    // Preparar la configuración completa con configured = true
    const fullConfig = { ...config, configured: true };

    // Buscar ID numérico de la baliza para asegurar compatibilidad
    let numericId: number | undefined;
    try {
      const beacons = await api.get<any>("beacons", { beacon_uid: beaconId });
      if (beacons.length > 0) numericId = beacons[0].id;
    } catch (e) {
      console.warn("Could not resolve beacon numeric ID", e);
    }

    // Enviar comando UPDATE_CONFIG a la baliza (comunicación en tiempo real)
    await api.upsert("commands", {
      beacon_uid: beaconId,
      beacon_id: numericId, // Añadimos ID numérico
      command: "UPDATE_CONFIG",
      value: JSON.stringify(fullConfig),
      status: "PENDING",
      executed: 0,
      created_at: new Date().toISOString().slice(0, 19).replace("T", " ")
    });

    // Actualizar en la base de datos para persistencia
    await api.upsert("beacons", toDbBeacon({
      beacon_uid: beaconId,
      ...fullConfig
    }));
  },

  /**
   * Actualiza una baliza enviando comando UPDATE_CONFIG
   * Si incluye cambios significativos, marca configured = true
   */
  updateBeacon: async (beaconId: string, updates: BeaconUpdate) => {
    // Si se actualizan campos importantes, marcar como configurada
    const hasSignificantChanges = updates.mode || updates.arrow || updates.message || updates.zone;
    const fullUpdates = hasSignificantChanges ? { ...updates, configured: true } : updates;

    // Buscar ID numérico de la baliza
    let numericId: number | undefined;
    try {
      const beacons = await api.get<any>("beacons", { beacon_uid: beaconId });
      if (beacons.length > 0) numericId = beacons[0].id;
    } catch (e) { }

    // Enviar comando UPDATE_CONFIG a la baliza (comunicación en tiempo real)
    await api.upsert("commands", {
      beacon_uid: beaconId,
      beacon_id: numericId,
      command: "UPDATE_CONFIG",
      value: JSON.stringify(fullUpdates),
      status: "PENDING",
      executed: 0,
      created_at: new Date().toISOString().slice(0, 19).replace("T", " ")
    });

    // También actualizar en la base de datos para reflejar el cambio
    await api.upsert("beacons", toDbBeacon({
      beacon_uid: beaconId,
      ...fullUpdates
    }));
  },

  /**
   * Actualiza múltiples balizas
   */
  updateMultipleBeacons: async (beaconIds: string[], updates: BeaconUpdate) => {
    await Promise.all(beaconIds.map(id => beaconsService.updateBeacon(id, updates)));
  },
  /**
   * Cambia el modo de una baliza
   */
  setBeaconMode: async (beaconId: string, mode: BeaconUpdate["mode"]) => {
    await api.upsert("beacons", {
      beacon_uid: beaconId,
      mode
    });
  },

  /**
   * Activa modo emergencia en todas las balizas
   */
  activateEmergencyAll: async (message: string, arrow: BeaconUpdate["arrow"] = "NONE") => {
    const beacons = await api.getBeacons();
    await Promise.all(beacons.map(b => api.upsert("beacons", toDbBeacon({
      beacon_uid: b.beaconId,
      mode: "EMERGENCY",
      arrow,
      message,
      color: "#FF0000",
      brightness: 100,
      configured: true
    }))));
    return beacons.length;
  },

  /**
   * Crea una baliza de prueba manualmente
   */
  createTestBeacon: async (beaconId: string) => {
    await api.upsert("beacons", toDbBeacon({
      beacon_uid: beaconId,
      configured: true,
      mode: "NORMAL",
      arrow: "NONE",
      message: "Baliza de prueba",
      color: "#00FF00",
      brightness: 50,
      language: "ES",
      online: false,
      zone: "Zona Test",
      evacuationExit: "",
      tags: ["test"]
    }));
  },

  /**
   * Envía un comando a una baliza específica
   * El comando se auto-limpia después de 7 segundos
   */
  sendCommand: async (beaconId: string, command: string) => {
    // Buscar ID numérico de la baliza
    let numericId: number | undefined;
    try {
      const beacons = await api.get<any>("beacons", { beacon_uid: beaconId });
      if (beacons.length > 0) numericId = beacons[0].id;
    } catch (e) { }

    // Crear el comando
    await api.upsert("commands", {
      beacon_uid: beaconId,
      beacon_id: numericId,
      command: command,
      value: "{}",
      status: "PENDING",
      executed: 0,
      created_at: new Date().toISOString().slice(0, 19).replace("T", " ")
    });
  },

  /**
   * Reinicia una baliza específica (reinicia el sistema Windows completo)
   * El comando se auto-limpia después de 7 segundos
   */
  restartBeacon: async (beaconId: string) => {
    await beaconsService.sendCommand(beaconId, "RESTART");
  },

  /**
   * Reinicia todas las balizas (reinicia todos los sistemas Windows)
   * Los comandos se auto-limpian después de 7 segundos
   */
  restartAllBeacons: async () => {
    const beacons = await api.getBeacons();
    await Promise.all(beacons.map(b => beaconsService.sendCommand(b.beaconId, "RESTART")));
    return beacons.length;
  },

  /**
   * Apaga una baliza específica (apaga el sistema Windows completo)
   */
  shutdownBeacon: async (beaconId: string) => {
    await beaconsService.sendCommand(beaconId, "SHUTDOWN");
  },

  /**
   * Cierra la aplicación de la baliza (vuelve al escritorio)
   */
  closeAppBeacon: async (beaconId: string) => {
    await beaconsService.sendCommand(beaconId, "CLOSE_APP");
  }
};

export const emergencyService = {
  logEmergencyAction: async (log: Omit<EmergencyLog, "id" | "triggeredAt">) => {
    await api.upsert("emergency_logs", {
      ...log,
      created_at: new Date().toISOString().slice(0, 19).replace("T", " ")
    });
  },
  activateGlobalEvacuation: async (beacons: Beacon[], userId: string, message: string, evacuationExit: string) => {
    await Promise.all(beacons.map(beacon => api.upsert("beacons", {
      beacon_uid: beacon.beaconId,
      mode: "EVACUATION",
      message,
      evacuationExit,
      color: "#FF0000",
      brightness: 100
    })));
    await emergencyService.logEmergencyAction({
      type: "GLOBAL_EVACUATION_ON",
      triggeredByUid: userId,
      payload: { message, evacuationExit, beaconCount: beacons.length }
    });
  },
  deactivateGlobalEvacuation: async (beacons: Beacon[], userId: string) => {
    await Promise.all(beacons.map(beacon => api.upsert("beacons", {
      beacon_uid: beacon.beaconId,
      mode: "NORMAL",
      message: "Acceso Principal",
      evacuationExit: "",
      color: "#00FFAA",
      brightness: 90
    })));
    await emergencyService.logEmergencyAction({
      type: "GLOBAL_EVACUATION_OFF",
      triggeredByUid: userId,
      payload: { beaconCount: beacons.length }
    });
  },
  activateZoneEvacuation: async (zone: string, beacons: Beacon[], userId: string, message: string, evacuationExit: string) => {
    const zoneBeacons = beacons.filter(b => b.zone === zone);
    await Promise.all(zoneBeacons.map(beacon => api.upsert("beacons", {
      beacon_uid: beacon.beaconId,
      mode: "EVACUATION",
      message,
      evacuationExit,
      color: "#FF0000",
      brightness: 100
    })));
    await emergencyService.logEmergencyAction({
      type: "ZONE_EVACUATION_ON",
      zone,
      triggeredByUid: userId,
      payload: { message, evacuationExit, beaconCount: zoneBeacons.length }
    });
  },
  deactivateZoneEvacuation: async (zone: string, beacons: Beacon[], userId: string) => {
    const zoneBeacons = beacons.filter(b => b.zone === zone);
    await Promise.all(zoneBeacons.map(beacon => api.upsert("beacons", {
      beacon_uid: beacon.beaconId,
      mode: "NORMAL",
      message: "Acceso Principal",
      evacuationExit: "",
      color: "#00FFAA",
      brightness: 90
    })));
    await emergencyService.logEmergencyAction({
      type: "ZONE_EVACUATION_OFF",
      zone,
      triggeredByUid: userId,
      payload: { beaconCount: zoneBeacons.length }
    });
  }
};

```

---

## `Web_Panel/src/types/index.ts`

```typescript




export type BeaconMode = "UNCONFIGURED" | "NORMAL" | "CONGESTION" | "EMERGENCY" | "EVACUATION" | "MAINTENANCE";
export type ArrowDirection = "NONE" | "LEFT" | "RIGHT" | "UP" | "DOWN" | "UP_LEFT" | "UP_RIGHT" | "DOWN_LEFT" | "DOWN_RIGHT" | "FORWARD" | "BACKWARD" | "FORWARD_LEFT" | "FORWARD_RIGHT" | "BACKWARD_LEFT" | "BACKWARD_RIGHT";
export type Language = "ES" | "EN" | "FR" | "DE" | "IT" | "PT" | "CA";
export type CommandType = "SET_MODE" | "SET_MESSAGE" | "SET_BRIGHTNESS" | "SET_ARROW" | "SET_CONFIG" | "REBOOT" | "PING" | "CUSTOM";
export type CommandStatus = "PENDING" | "SENT" | "EXECUTED" | "FAILED" | "CANCELLED";
export type EmergencyLevel = "INFO" | "ADVISORY" | "WARNING" | "CRITICAL";
export type EmergencyStatus = "ACTIVE" | "RESOLVED";
export type EmergencyAction = "EVACUATION_PATH" | "BLOCKED_ZONE" | "ALERT_ONLY";

export interface Beacon {
  // Campos principales - mapeo con DB
  id?: number;                         // id: int auto
  beaconId: string;                    // beacon_uid: varchar
  beacon_uid?: string;                 // Alias for beaconId to match DB
  name: string | null;                 // name: varchar
  description?: string | null;         // description: text
  zoneId?: number | null;              // zone_id: int
  latitude?: number | null;            // latitude: double
  longitude?: number | null;           // longitude: double
  hasScreen?: boolean;                 // has_screen: boolean
  mode: BeaconMode | null;             // mode: varchar
  arrow: ArrowDirection | null;        // arrow_direction: varchar
  message: string | null;              // message: text
  color: string | null;                // color: varchar
  brightness: number | null;           // brightness: int
  battery: number | null;              // battery_level: int
  online: boolean | null;              // is_online: boolean
  configured: boolean;                 // configured: boolean
  lastHeartbeat?: string | null;       // last_heartbeat: datetime
  lastStatusChange?: string | null;    // last_status_change: datetime
  createdAt?: string;                  // created_at: datetime
  updatedAt?: string;                  // updated_at: datetime

  // Legacy/Frontend specific fields (keeping for compatibility if needed)
  lastUpdate?: string | null;
  lastSeen?: string | null;
  zone?: string | null; // Nombre de la zona si viene populado
  evacuationExit?: string | null;
  tags?: string[] | null;
  language?: Language | null;
}

export interface ZoneDB {
  id: number;
  name: string;
  description?: string;
  createdAt: string;
}

export interface Command {
  id: number;
  beacon_uid?: string;
  beacon_id?: number;
  command: string;
  value: any;
  status: string;
  created_at: string;
  executed_at?: string;

  // Legacy mappings for UI compatibility (optional)
  beaconId?: number;
  commandType?: CommandType;
  createdAt?: string;
}

export interface BeaconLog {
  id: number;
  beacon_id?: number;
  beaconId?: number;
  message: string;
  created_at: string;

  // Legacy
  eventType?: "HEARTBEAT" | "STATUS_CHANGE" | "COMMAND_SENT" | "COMMAND_EXECUTED" | "COMMAND_FAILED" | "ERROR" | "INFO";
  data?: any;
  createdAt?: string;
}

export interface Emergency {
  id: number;
  title: string;
  description?: string;
  level: EmergencyLevel;
  status: EmergencyStatus;
  triggeredBy?: string;
  zoneId?: number;
  startedAt?: string;
  resolvedAt?: string;
}

export interface EmergencyBeacon {
  id: number;
  emergencyId: number;
  beaconId: number;
  action: EmergencyAction;
  createdAt: string;
}

export interface StaffGroup {
  id: number;
  name: string;
  description?: string;
  createdAt: string;
}

export interface StaffPosition {
  id: number;
  groupId: number;
  displayName: string;
  phone?: string;
  notes?: string;
  createdAt: string;
}

export interface GroupLocation {
  id: number;
  groupId: number;
  userIdentifier: string;
  latitude: number;
  longitude: number;
  accuracyMeters?: number;
  source?: string;
  recordedAt: string;
}

// --- Legacy / UI Types ---

export interface EmergencyLog {
  id?: string;
  type: "GLOBAL_EVACUATION_ON" | "GLOBAL_EVACUATION_OFF" | "ZONE_EVACUATION_ON" | "ZONE_EVACUATION_OFF";
  zone?: string | null;
  triggeredByUid: string;
  triggeredAt?: string | null;
  created_at?: string;
  payload: Record<string, unknown>;
}

export interface BeaconUpdate {
  mode?: BeaconMode;
  arrow?: ArrowDirection;
  message?: string;
  color?: string;
  brightness?: number;
  language?: Language;
  evacuationExit?: string;
  zone?: string;
  tags?: string[];
  configured?: boolean;
  name?: string;
}

export interface ZoneInfo {
  zone: string;
  totalBeacons: number;
  evacuationCount: number;
}

export type ZoneStatus = "ABIERTA" | "SATURADA" | "CERRADA" | "MANTENIMIENTO" | "OPERATIVA";

export interface Zone {
  id: string;
  name: string;
  type: string; // "GRADA", "PADDOCK", "FANZONE", "VIAL", "PARKING"
  status: ZoneStatus;
  capacity: number;
  currentOccupancy: number;
  temperature: number;
  waitTime: number; // minutos
  entryRate: number; // personas/min
  exitRate: number; // personas/min
  alerts?: number;
  color?: string; // Color del estado
}

export type RouteStatus = "OPERATIVA" | "SATURADA" | "CERRADA" | "MANTENIMIENTO";

export interface Route {
  id: string;
  name: string;
  origin: string;
  destination: string;
  status: RouteStatus;
  activeUsers: number;
  capacity: number;
  capacityPercentage: number;
  averageSpeed: number; // m/s
  distance: number; // metros
  signalQuality: number; // porcentaje
  estimatedTime: number; // minutos
  velocity: number; // m/s
  color?: string;
}

export interface SystemStats {
  activeVisitors: number;
  dailyTotal: number;
  satisfaction: number; // porcentaje
  activeZones: number;
  totalZones: number;
  operationalRoutes: number;
  totalRoutes: number;
  activeBeacons: number;
  totalBeacons: number;
  activeAlerts: number;
  avgVisitTime: number; // minutos
  dailyRevenue: number;
}

export interface TrafficPeak {
  time: string;
  count: number;
}


```

---

## `Web_Panel/src/utils/beaconHelpers.ts`

```typescript
export type BeaconModeStrict = "normal" | "emergency" | "evacuation" | "maintenance";

export function getModeColor(mode: BeaconModeStrict | null): string {
  switch (mode) {
    case "normal":
      return "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30";
    case "emergency":
      return "bg-red-500/10 text-red-400 ring-red-500/30";
    case "evacuation":
      return "bg-amber-500/10 text-amber-400 ring-amber-500/30";
    case "maintenance":
      return "bg-sky-500/10 text-sky-400 ring-sky-500/30";
    default:
      return "bg-slate-500/10 text-slate-400 ring-slate-500/30";
  }
}

```

---

## `Web_Panel/src/utils/beaconMessages.ts`

```typescript
import { BeaconMode, ArrowDirection, Language } from "../types";

/**
 * Obtiene el mensaje predefinido según modo, idioma y dirección de flecha
 */
export const getDefaultBeaconMessage = (
  mode: BeaconMode,
  language: Language,
  arrow: ArrowDirection = "NONE"
): string => {
  // MODO NORMAL: Texto varía según la dirección de la flecha
  if (mode === "NORMAL") {
    return getNormalModeMessage(arrow, language);
  }

  // Otros modos: Mensajes estándar
  const messages: Record<BeaconMode, Record<Language, string>> = {
    UNCONFIGURED: {
      ES: "Sistema en Configuración",
      CA: "Sistema en Configuració",
      EN: "System in Configuration",
      FR: "Système en Configuration",
      DE: "System in Konfiguration",
      IT: "Sistema in Configurazione",
      PT: "Sistema em Configuração"
    },
    NORMAL: {
      ES: "Circulación Normal",
      CA: "Circulació Normal",
      EN: "Normal Traffic",
      FR: "Circulation Normale",
      DE: "Normaler Verkehr",
      IT: "Traffico Normale",
      PT: "Tráfego Normal"
    },
    CONGESTION: {
      ES: "⚠️ Congestión\nReduzca Velocidad",
      CA: "⚠️ Congestió\nRedueixi Velocitat",
      EN: "⚠️ Congestion\nReduce Speed",
      FR: "⚠️ Congestion\nRalentir",
      DE: "⚠️ Stau\nGeschwindigkeit Reduzieren",
      IT: "⚠️ Congestione\nRidurre Velocità",
      PT: "⚠️ Congestionamento\nReduza Velocidade"
    },
    EMERGENCY: {
      ES: "⚠️ EMERGENCIA\nPRECAUCIÓN",
      CA: "⚠️ EMERGÈNCIA\nPRECAUCIÓ",
      EN: "⚠️ EMERGENCY\nCAUTION",
      FR: "⚠️ URGENCE\nPRUDENCE",
      DE: "⚠️ NOTFALL\nVORSICHT",
      IT: "⚠️ EMERGENZA\nATTENZIONE",
      PT: "⚠️ EMERGÊNCIA\nCUIDADO"
    },
    EVACUATION: {
      ES: "🚨 EVACUACIÓN\nSiga las Flechas",
      CA: "🚨 EVACUACIÓ\nSegueixi les Fletxes",
      EN: "🚨 EVACUATION\nFollow the Arrows",
      FR: "🚨 ÉVACUATION\nSuivez les Flèches",
      DE: "🚨 EVAKUIERUNG\nFolgen Sie den Pfeilen",
      IT: "🚨 EVACUAZIONE\nSegui le Frecce",
      PT: "🚨 EVACUAÇÃO\nSiga as Setas"
    },
    MAINTENANCE: {
      ES: "🔧 Mantenimiento\nFuera de Servicio",
      CA: "🔧 Manteniment\nFora de Servei",
      EN: "🔧 Maintenance\nOut of Service",
      FR: "🔧 Maintenance\nHors Service",
      DE: "🔧 Wartung\nAußer Betrieb",
      IT: "🔧 Manutenzione\nFuori Servizio",
      PT: "🔧 Manutenção\nFora de Serviço"
    }
  };

  return messages[mode]?.[language] || messages[mode]?.["ES"] || "Sistema Activo";
};

/**
 * Mensajes específicos para modo NORMAL según dirección de flecha
 */
const getNormalModeMessage = (arrow: ArrowDirection, language: Language): string => {
  const normalMessages: Record<ArrowDirection, Record<Language, string>> = {
    NONE: {
      ES: "Circulación Normal",
      CA: "Circulació Normal",
      EN: "Normal Traffic",
      FR: "Circulation Normale",
      DE: "Normaler Verkehr",
      IT: "Traffico Normale",
      PT: "Tráfego Normal"
    },
    UP: {
      ES: "Continúe Recto",
      CA: "Continuï Recte",
      EN: "Continue Straight",
      FR: "Continuez Tout Droit",
      DE: "Geradeaus Weiter",
      IT: "Proseguire Dritto",
      PT: "Continue em Frente"
    },
    DOWN: {
      ES: "Retroceda",
      CA: "Retrocedeixi",
      EN: "Go Back",
      FR: "Reculez",
      DE: "Zurück",
      IT: "Tornare Indietro",
      PT: "Volte"
    },
    LEFT: {
      ES: "Gire a la Izquierda",
      CA: "Giri a l'Esquerra",
      EN: "Turn Left",
      FR: "Tournez à Gauche",
      DE: "Links Abbiegen",
      IT: "Svoltare a Sinistra",
      PT: "Vire à Esquerda"
    },
    RIGHT: {
      ES: "Gire a la Derecha",
      CA: "Giri a la Dreta",
      EN: "Turn Right",
      FR: "Tournez à Droite",
      DE: "Rechts Abbiegen",
      IT: "Svoltare a Destra",
      PT: "Vire à Direita"
    },
    UP_LEFT: {
      ES: "Diagonal Izquierda",
      CA: "Diagonal Esquerra",
      EN: "Diagonal Left",
      FR: "Diagonale Gauche",
      DE: "Diagonal Links",
      IT: "Diagonale Sinistra",
      PT: "Diagonal Esquerda"
    },
    UP_RIGHT: {
      ES: "Diagonal Derecha",
      CA: "Diagonal Dreta",
      EN: "Diagonal Right",
      FR: "Diagonale Droite",
      DE: "Diagonal Rechts",
      IT: "Diagonale Destra",
      PT: "Diagonal Direita"
    },
    DOWN_LEFT: {
      ES: "Retroceda Izquierda",
      CA: "Retrocedeixi Esquerra",
      EN: "Back Left",
      FR: "Reculez à Gauche",
      DE: "Zurück Links",
      IT: "Indietro Sinistra",
      PT: "Volte Esquerda"
    },
    DOWN_RIGHT: {
      ES: "Retroceda Derecha",
      CA: "Retrocedeixi Dreta",
      EN: "Back Right",
      FR: "Reculez à Droite",
      DE: "Zurück Rechts",
      IT: "Indietro Destra",
      PT: "Volte Direita"
    }
  };

  return normalMessages[arrow]?.[language] || normalMessages["NONE"]?.[language] || "Circulación Normal";
};

```

---

## `Web_Panel/src/utils/beaconUtils.ts`

```typescript
import { Beacon } from "../types";

/**
 * Verifica si una baliza está online basándose en su último heartbeat
 * @param beacon - La baliza a verificar
 * @returns true si la baliza está online (heartbeat < 15 segundos)
 */
export const isBeaconOnline = (beacon: Beacon): boolean => {
  if (!beacon.online) return false;
  
  const lastSeen = beacon.lastSeen ? new Date(beacon.lastSeen) : undefined;
  if (!lastSeen) return false;
  
  const now = new Date();
  const secondsAgo = (now.getTime() - lastSeen.getTime()) / 1000;
  
  // Considerar online si heartbeat < 15 segundos
  return secondsAgo < 15;
};

/**
 * Formatea el tiempo desde la última conexión
 * @param beacon - La baliza
 * @returns String con el tiempo formateado
 */
export const formatLastSeen = (beacon: Beacon): string => {
  const lastSeen = beacon.lastSeen ? new Date(beacon.lastSeen) : undefined;
  if (!lastSeen) return "Nunca";
  
  const now = new Date();
  const secondsAgo = Math.floor((now.getTime() - lastSeen.getTime()) / 1000);
  
  if (secondsAgo < 60) return `Hace ${secondsAgo}s`;
  if (secondsAgo < 3600) return `Hace ${Math.floor(secondsAgo / 60)}m`;
  if (secondsAgo < 86400) return `Hace ${Math.floor(secondsAgo / 3600)}h`;
  return `Hace ${Math.floor(secondsAgo / 86400)}d`;
};

/**
 * Obtiene el estado visual de una baliza
 * @param beacon - La baliza
 * @returns Emoji y texto del estado
 */
export const getBeaconStatus = (beacon: Beacon): { emoji: string; text: string; color: string } => {
  const online = isBeaconOnline(beacon);
  
  if (!online) {
    return { emoji: "🔴", text: "Offline", color: "text-red-500" };
  }
  
  if (!beacon.configured) {
    return { emoji: "⚠️", text: "Sin configurar", color: "text-yellow-500" };
  }
  
  switch (beacon.mode) {
    case "EMERGENCY":
    case "EVACUATION":
      return { emoji: "🚨", text: "Emergencia", color: "text-red-500" };
    case "MAINTENANCE":
      return { emoji: "🔧", text: "Mantenimiento", color: "text-blue-500" };
    case "CONGESTION":
      return { emoji: "⚠️", text: "Congestión", color: "text-orange-500" };
    case "NORMAL":
      return { emoji: "🟢", text: "Normal", color: "text-green-500" };
    default:
      return { emoji: "🟢", text: "Online", color: "text-green-500" };
  }
};

/**
 * Obtiene el color de fondo según el modo
 * @param mode - El modo de la baliza
 * @returns Color hexadecimal
 */
export const getModeColor = (mode: Beacon["mode"]): string => {
  switch (mode) {
    case "UNCONFIGURED":
      return "#333333";
    case "NORMAL":
      return "#00FF00";
    case "CONGESTION":
      return "#FFA500";
    case "EMERGENCY":
      return "#FF6600";
    case "EVACUATION":
      return "#FF0000";
    case "MAINTENANCE":
      return "#808080";
    default:
      return "#00FF00";
  }
};

/**
 * Obtiene el nombre traducido del modo
 * @param mode - El modo de la baliza
 * @returns Nombre del modo
 */
export const getModeName = (mode: Beacon["mode"]): string => {
  switch (mode) {
    case "UNCONFIGURED":
      return "Sin configurar";
    case "NORMAL":
      return "Normal";
    case "CONGESTION":
      return "Congestión";
    case "EMERGENCY":
      return "Emergencia";
    case "EVACUATION":
      return "Evacuación";
    case "MAINTENANCE":
      return "Mantenimiento";
    default:
      return mode || "Sin configurar";
  }
};

/**
 * Obtiene el nombre traducido de la dirección de flecha
 * @param arrow - La dirección de la flecha
 * @returns Nombre de la dirección
 */
export const getArrowName = (arrow: Beacon["arrow"]): string => {
  switch (arrow) {
    case "NONE":
      return "Sin flecha";
    case "UP":
      return "↑ Arriba";
    case "DOWN":
      return "↓ Abajo";
    case "LEFT":
      return "← Izquierda";
    case "RIGHT":
      return "→ Derecha";
    case "UP_LEFT":
      return "↖ Arriba-Izquierda";
    case "UP_RIGHT":
      return "↗ Arriba-Derecha";
    case "DOWN_LEFT":
      return "↙ Abajo-Izquierda";
    case "DOWN_RIGHT":
      return "↘ Abajo-Derecha";
    default:
      return arrow || "Sin flecha";
  }
};

/**
 * Filtra balizas por zona
 * @param beacons - Array de balizas
 * @param zone - Zona a filtrar
 * @returns Array de balizas filtradas
 */
export const filterBeaconsByZone = (beacons: Beacon[], zone: string): Beacon[] => {
  return beacons.filter(b => b.zone === zone);
};

/**
 * Filtra balizas por estado online/offline
 * @param beacons - Array de balizas
 * @param online - true para online, false para offline
 * @returns Array de balizas filtradas
 */
export const filterBeaconsByOnlineStatus = (beacons: Beacon[], online: boolean): Beacon[] => {
  return beacons.filter(b => isBeaconOnline(b) === online);
};

/**
 * Obtiene estadísticas de las balizas
 * @param beacons - Array de balizas
 * @returns Estadísticas
 */
export const getBeaconStats = (beacons: Beacon[]) => {
  const total = beacons.length;
  const online = beacons.filter(isBeaconOnline).length;
  const configured = beacons.filter(b => b.configured).length;
  const emergency = beacons.filter(b => b.mode === "EMERGENCY" || b.mode === "EVACUATION").length;
  
  return {
    total,
    online,
    offline: total - online,
    configured,
    unconfigured: total - configured,
    emergency,
    uptime: total > 0 ? Math.round((online / total) * 100) : 0
  };
};

```

---

## `Web_Panel/src/utils/beaconValidation.ts`

```typescript
import { BeaconMode, ArrowDirection, Language } from "../types";

/**
 * Utilidades de validación para configuración de balizas
 */

export const VALID_MODES: BeaconMode[] = [
  "UNCONFIGURED",
  "NORMAL",
  "CONGESTION",
  "EMERGENCY",
  "EVACUATION",
  "MAINTENANCE"
];

export const VALID_ARROWS: ArrowDirection[] = [
  "NONE",
  "UP",
  "DOWN",
  "LEFT",
  "RIGHT",
  "UP_LEFT",
  "UP_RIGHT",
  "DOWN_LEFT",
  "DOWN_RIGHT"
];

export const VALID_LANGUAGES: Language[] = [
  "ES",
  "CA",
  "EN",
  "FR",
  "DE",
  "IT",
  "PT"
];

export interface ValidationError {
  field: string;
  message: string;
}

/**
 * Valida que un color esté en formato hexadecimal válido
 */
export const isValidHexColor = (color: string): boolean => {
  return /^#[0-9A-Fa-f]{6}$/.test(color);
};

/**
 * Valida que el brillo esté en el rango válido (0-100)
 */
export const isValidBrightness = (brightness: number): boolean => {
  return brightness >= 0 && brightness <= 100;
};

/**
 * Valida que un mensaje no exceda el límite de caracteres
 */
export const isValidMessage = (message: string): boolean => {
  return message.length <= 255;
};

/**
 * Valida que una zona sea válida (no vacía, máx 50 caracteres)
 */
export const isValidZone = (zone: string): boolean => {
  return zone.trim().length > 0 && zone.length <= 50;
};

/**
 * Valida que la salida de evacuación sea válida (máx 100 caracteres)
 */
export const isValidEvacuationExit = (exit: string): boolean => {
  return exit.length <= 100;
};

/**
 * Valida una configuración completa de baliza
 */
export const validateBeaconConfig = (config: {
  mode?: BeaconMode;
  arrow?: ArrowDirection;
  message?: string;
  color?: string;
  brightness?: number;
  language?: Language;
  evacuationExit?: string;
  zone?: string;
}): ValidationError[] => {
  const errors: ValidationError[] = [];

  // Validar modo
  if (config.mode && !VALID_MODES.includes(config.mode)) {
    errors.push({ field: "mode", message: "Modo no válido" });
  }

  // Validar flecha
  if (config.arrow && !VALID_ARROWS.includes(config.arrow)) {
    errors.push({ field: "arrow", message: "Dirección de flecha no válida" });
  }

  // Validar idioma
  if (config.language && !VALID_LANGUAGES.includes(config.language)) {
    errors.push({ field: "language", message: "Idioma no válido" });
  }

  // Validar mensaje
  if (config.message && !isValidMessage(config.message)) {
    errors.push({ field: "message", message: "El mensaje no puede exceder 255 caracteres" });
  }

  // Validar color
  if (config.color && !isValidHexColor(config.color)) {
    errors.push({ field: "color", message: "Color debe ser un valor hexadecimal válido (#RRGGBB)" });
  }

  // Validar brillo
  if (config.brightness !== undefined && !isValidBrightness(config.brightness)) {
    errors.push({ field: "brightness", message: "El brillo debe estar entre 0 y 100" });
  }

  // Validar zona
  if (config.zone && !isValidZone(config.zone)) {
    errors.push({ field: "zone", message: "La zona es obligatoria y no puede exceder 50 caracteres" });
  }

  // Validar salida de evacuación
  if (config.evacuationExit && !isValidEvacuationExit(config.evacuationExit)) {
    errors.push({ field: "evacuationExit", message: "La salida de evacuación no puede exceder 100 caracteres" });
  }

  // Validación especial: si el modo es EVACUATION, la salida de evacuación es obligatoria
  if (config.mode === "EVACUATION" && (!config.evacuationExit || !config.evacuationExit.trim())) {
    errors.push({ field: "evacuationExit", message: "La salida de evacuación es obligatoria en modo EVACUATION" });
  }

  return errors;
};

/**
 * Normaliza un color para asegurar que esté en mayúsculas
 */
export const normalizeColor = (color: string): string => {
  return color.toUpperCase();
};

/**
 * Limpia y normaliza un mensaje eliminando espacios extra
 */
export const normalizeMessage = (message: string): string => {
  return message.trim().replace(/\s+/g, ' ');
};

/**
 * Parsea tags desde un string JSON o devuelve array vacío si falla
 */
export const parseTags = (tagsJson: string | null): string[] => {
  if (!tagsJson) return [];
  try {
    const parsed = JSON.parse(tagsJson);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
};

/**
 * Convierte tags a string JSON para almacenar en la base de datos
 */
export const stringifyTags = (tags: string[]): string => {
  return JSON.stringify(tags);
};

```

---

## `Web_Panel/src/vite-env.d.ts`

```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string
  readonly VITE_COMMAND_API_URL?: string
  readonly VITE_FIREBASE_API_KEY?: string
  readonly VITE_FIREBASE_AUTH_DOMAIN?: string
  readonly VITE_FIREBASE_PROJECT_ID?: string
  readonly VITE_FIREBASE_STORAGE_BUCKET?: string
  readonly VITE_FIREBASE_MESSAGING_SENDER_ID?: string
  readonly VITE_FIREBASE_APP_ID?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

```

---

## `Web_Panel/package.json`

```json
{
  "name": "georacing-control-panel",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "create-beacons": "node scripts/create-beacons.js",
    "create-admin": "tsx scripts/create-admin-user.ts",
    "deploy": "npm run build && firebase deploy",
    "deploy:firestore": "firebase deploy --only firestore"
  },
  "dependencies": {
    "firebase": "^10.14.1",
    "lucide-react": "^0.294.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@typescript-eslint/eslint-plugin": "^6.14.0",
    "@typescript-eslint/parser": "^6.14.0",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.3.6",
    "tsx": "^4.20.6",
    "typescript": "^5.2.2",
    "vite": "^5.0.8"
  }
}

```

---

## `Web_Panel/tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}

```

---

## `Web_Panel/tsconfig.node.json`

```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}

```

---

## `Web_Panel/vite.config.ts`

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    https: false
  }
})

```

---

## `Web_Panel/tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          900: '#0a0a0a',
          800: '#121212',
          700: '#1a1a1a',
          600: '#2a2a2a',
          500: '#3a3a3a',
        }
      }
    },
  },
  plugins: [],
}

```

---

## `Web_Panel/postcss.config.js`

```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}

```

---

## `Web_Panel/index.html`

```html
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>GeoRacing Control Panel</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>

```

---

## `Web_Panel/firebase.json`

```json
{
  "firestore": {
    "database": "(default)",
    "location": "eur3",
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "target": "app",
    "public": "dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## `Web_Panel/firestore.rules`

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Colección de balizas - Las balizas pueden auto-registrarse y leer/actualizar
    match /beacons/{beaconId} {
      // Las balizas pueden leer su configuración
      allow read: if true;
      
      // Las balizas pueden crear su propio documento al conectarse por primera vez
      // con campos mínimos (beaconId, lastSeen, online)
      allow create: if request.resource.data.beaconId == beaconId
        && request.resource.data.keys().hasAll(['beaconId', 'lastSeen', 'online']);
      
      // Las balizas pueden actualizar solo campos de heartbeat
      // El panel puede actualizar todo
      allow update: if request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['lastSeen', 'online']) || request.auth != null;
      
      // Solo usuarios autenticados pueden eliminar
      allow delete: if request.auth != null;
      
      // Usuarios autenticados tienen acceso completo
      allow write: if request.auth != null;
    }
    
    // Colección de logs de emergencia - Solo usuarios autenticados
    match /emergency_logs/{logId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if false; // Los logs no se modifican
    }
    
    // Cualquier otra colección requiere autenticación
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## `Web_Panel/firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "beacons",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "zone",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "mode",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "online",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "beacons",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "online",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lastSeen",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "emergency_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "triggeredAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

