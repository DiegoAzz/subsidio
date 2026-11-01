# Mi Techo Heroico - Simulador VIS Cartagena 🏠🇨🇴

Videojuego didáctico y multijugador en tiempo real desarrollado en **Godot 4** para orientar y educar a los ciudadanos de Cartagena y Colombia en el proceso de compra de **Vivienda de Interés Social (VIS)**, simulación de cierre financiero y concurrencia de subsidios.

Inspirado en casos reales como el proyecto **Parque Galilea** (Cartagena).

---

## 🚀 Características Principales

1. **Mapa Interactivo de Mini-Cartagena:**
   - **Sala de Ventas: Parque Galilea:** Información del apartamento, cuota inicial ($50M aprox.) y plan de pagos mensual de $700.000 en preventa.
   - **Comfenalco Cartagena:** Requisitos y trámite de subsidio familiar de vivienda (hasta 30 SMMLV).
   - **Entidad Financiera (FNA y Bancos):** Carta de preaprobado, capacidad de endeudamiento y traslado de cesantías/AVC.
   - **Módulo Sisbén IV & Mi Casa Ya:** Verificación de grupo (A1 a C8) para el subsidio nacional de MinVivienda.
   - **Corvivienda (Alcaldía):** Subsidio complementario distrital *"Mi Casa Va"*.

2. **Simulador de Cierre Financiero en Vivo:**
   - Cálculos matemáticos precisos basados en el SMMLV colombiano.
   - **Concurrencia de Subsidios:** Simula la suma del subsidio de Caja (30 SMMLV) + Mi Casa Ya (20 SMMLV) = **¡50 SMMLV de subsidio!**
   - Ajuste dinámico de cuotas de preventa y evaluación de viabilidad bancaria.

3. **Multijugador en Tiempo Real (WebSocket):**
   - Arquitectura lista para navegadores web y despliegue en VPS.
   - Visualización de otros ciudadanos explorando la ciudad.
   - Chat comunitario en vivo para compartir consejos y responder preguntas.

---

## 📁 Estructura del Proyecto

```text
├── autoload/
│   ├── HousingCalculator.gd    # Motor financiero VIS y concurrencia
│   ├── GameManager.gd          # Estado del juego, misiones y documentos
│   └── NetworkManager.gd       # Conexiones WebSocket y sync multijugador
├── scenes/
│   ├── map/
│   │   ├── CityMap.tscn        # Escena principal (Mini-Cartagena)
│   │   └── CityMap.gd
│   ├── player/
│   │   ├── Player.tscn         # Personaje con cámara, badges y colisiones
│   │   └── Player.gd
│   ├── buildings/
│   │   ├── Building.tscn       # Edificios interactivos con asesores NPC
│   │   └── Building.gd
│   └── ui/
│       ├── HUD.tscn            # Barra superior, chat y modales
│       ├── CalculatorUI.tscn   # Simulador visual de subsidios y cuotas
│       ├── DialogueUI.tscn     # Ventana de diálogo y trámites
│       └── QuestUI.tscn        # Checklist de requisitos
├── deploy/
│   ├── Dockerfile.server       # Contenedor Godot 4 headless para Coolify
│   ├── Dockerfile.web          # Contenedor Nginx con COOP/COEP
│   └── nginx.conf              # Configuración optimizada para WASM
├── docker-compose.yml          # Despliegue 1-click en Coolify
└── project.godot               # Configuración del proyecto Godot 4
```

---

## 🎨 Cómo Añadir tus Propios Sprites y Arte Más Adelante

El proyecto está diseñado de forma modular para que cuando tengas tus sprites, solo tengas que asignarlos:
* **Personaje (`scenes/player/Player.tscn`):** Reemplaza el nodo `Visual` por un `Sprite2D` o `AnimatedSprite2D`.
* **Edificios (`scenes/buildings/Building.tscn`):** Reemplaza el nodo `Visuals` por el sprite o tileset de la fachada de cada entidad.
* **Terreno (`scenes/map/CityMap.tscn`):** Reemplaza los polígonos de `Ground` por un `TileMapLayer` con tu tileset de Cartagena (adoquines, palmeras, mar).

---

## 🐳 Despliegue en Coolify (VPS)

1. Sube este repositorio a tu cuenta de GitHub / GitLab.
2. En tu panel de **Coolify**, añade un nuevo recurso seleccionando **Docker Compose**.
3. Conecta el repositorio. Coolify detectará el archivo [docker-compose.yml](file:///d:/DiegoAz/ANTIGRAVITY/GAMES/docker-compose.yml).
4. Asigna tus dominios en Coolify:
   * Para la web: `https://vivienda.tudominio.com` (apunta al puerto 80 del contenedor web).
   * Para el WebSocket: `wss://vivienda.tudominio.com/ws` (apunta al puerto 9090 del servidor Godot).
5. ¡Listo! Coolify se encarga del certificado SSL automático y el balanceo.
