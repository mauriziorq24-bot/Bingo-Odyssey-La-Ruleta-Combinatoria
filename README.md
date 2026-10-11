# 🎱 Bingo Arcade Académico

Un videojuego casual y arcade de Bingo móvil/escritorio desarrollado en **Godot Engine 4 (4.2+)**, enfocado en estándares modernos de interfaz (Glassmorphism, feedback háptico visual y *juice* táctil), dinámicas interactivas de trivia educativa y personalización estética en tiempo real.

---

## ✨ Características Principales

* **Mecánica Clásica de Bingo Americano (75 Balotas):**
  * Matriz balanceada de 5×5 (Columnas B, I, N, G, O) con casilla central dorada libre.
  * Verificación automática de patrones ganadores: líneas horizontales, verticales, diagonales y cuatro esquinas.
* **Tómbola Automática con Cadencia Dinámica:**
  * Extracción continua de balotas cada 7 segundos con temporizador visual regresivo.
  * Control interactivo para pausar y reanudar el sorteo en cualquier momento.
  * Bandeja de historial con las últimas balotas cantadas organizadas cronológicamente.
* **Desafíos de Trivia Integrados (Minijuego de Bonus):**
  * Activación probabilística durante las extracciones de la tómbola que pausa el ritmo de la partida.
  * Modal interactivo con preguntas de lógica y cultura general con bonificación de recursos.
* **Economía Dual y Persistencia de Datos:**
  * 🪙 **Monedas (Divisa de Partida):** Obtenidas marcando casillas y respondiendo trivias. Se reinician a 0 al comenzar una nueva partida.
  * ⭐ **Estrellas (Divisa Meta/Prestigio):** Obtenidas al completar patrones de Bingo. Se guardan permanentemente en disco (`user://save_data.json`).
  * 💖 **Sistema de Revivir (Segunda Oportunidad):** Si el jugador pierde sus 3 vidas, puede pagar 50 monedas en la pantalla de derrota para restaurar 1 vida y continuar su cartón actual sin perder el progreso.
* **Motor de Ambientes y Progresión por Estrellas:**
  * **Resort Costero:** Ambiente inicial accesible por defecto (paleta esmeralda relajante).
  * **Villa de Bloques:** Ambiente prémium desbloqueable al alcanzar **20 estrellas** acumuladas (paleta cálida/ámbar).
  * Validación reactiva con candados visuales (`🔒 VILLA: X/20 ⭐`) y animaciones de sacudida ante intentos de acceso bloqueados.
  * Filtro de desenfoque en tiempo real (*Screen Blur Shader*) para máxima legibilidad de la interfaz sobre cualquier fondo.
* **Diseño UI/UX (Estándar 2026):**
  * Acabados flotantes en estilo *Glassmorphism* mediante `StyleBoxFlat` procedurales.
  * Cabecera HUD simétrica con chips de Vidas, Monedas centradas y Estrellas, complementada con un botón táctil de regreso al menú principal (`⬅ MENÚ`).
  * Animaciones elásticas con *Tweens* al pulsar casillas, extraer balotas y transicionar modales.
  * Enlace dinámico y resiliente de nodos (`find_child`) para tolerancia a cambios de jerarquía visual.
* **Diseño Sonoro Inmersivo:**
  * **Marcado de Cartón:** Efecto analógico de trazado con lápiz recortado proceduralmente a 2.0 segundos con desvanecimiento (*fade-out*) suave.
  * **Extracción de Balota:** Campanilla nítida sincronizada con la animación de rebote.
  * **Trivia:** Sonidos diferenciados para acierto (recolección de puntos) y error (zumbido de fallo con realce de volumen en dB).
  * **Fin de Partida:** Ovación y aplausos triunfales en caso de victoria; fanfarria cómica de trompeta en caso de derrota.

---

## 🏗️ Arquitectura de Software

El proyecto sigue una adaptación modular del patrón **MVC (Modelo-Vista-Controlador)** desacoplado mediante señales:

### 1. Núcleo Lógico (Modelos)
* **`GameManager.gd` (Autoload / Singleton):** Centraliza el estado de la sesión (vidas, monedas, estrellas, estadísticas de trivia y ambiente seleccionado). Emite señales globales de sincronización.
* **`BingoTombola.gd`:** Gestiona el bombo de 75 balotas, el orden aleatorio y el registro de números extraídos.
* **`BingoCard.gd`:** Genera el cartón 5×5 respetando los rangos numéricos estándar de B-I-N-G-O y evalúa las condiciones de victoria.
* **`TriviaManager.gd`:** Banco de preguntas y lógica de validación de respuestas.

### 2. Controladores de Escena (Control / Vista)
* **`MainMenu.gd`:** Menú de inicio con selección previa de ambiente, microinteracciones táctiles y navegación hacia el juego.
* **`MainGame.gd`:** Controlador maestro de la partida. Orquesta el bucle de la tómbola, la actualización del HUD, los efectos sonoros y el renderizado del cartón.
* **`TriviaModal.gd`:** Controlador del modal emergente de preguntas y respuestas.
* **`EndGameModal.gd`:** Modal de finalización de partida; gestiona estadísticas, reinicio de sesión y reproducción de audio según la condición de victoria o derrota.

---

## 📁 Estructura del Proyecto

```text
├── project.godot
├── README.md
├── assets/
│   ├── audio/
│   │   ├── ball_draw.mp3            # Campanilla de extracción
│   │   ├── trivia_correct.mp3       # Acierto de trivia
│   │   ├── trivia_wrong.mp3         # Error en trivia
│   │   ├── pencil_mark.mp3          # Trazado de lápiz sobre casilla
│   │   ├── victory_cheer.mp3        # Ovación de victoria
│   │   └── game_over_fail.mp3       # Fanfarria de derrota
│   └── sprites/
│       ├── env_resort.png           # Fondo: Resort Costero
│       └── env_brick_town.png       # Fondo: Villa de Bloques
├── scenes/
│   ├── gameplay/
│   │   ├── MainGame.tscn
│   │   └── MainGame.gd
│   ├── menus/
│   │   ├── MainMenu.tscn
│   │   └── MainMenu.gd
│   └── ui/
│       ├── TriviaModal.tscn
│       ├── TriviaModal.gd
│       ├── EndGameModal.tscn
│       └── EndGameModal.gd
└── scripts/
	├── autoload/
	│   └── GameManager.gd           # Gestor global de sesión y estado
	└── gameplay/
		├── BingoCard.gd             # Generación de matriz 5x5 y reglas de victoria
		├── BingoTombola.gd          # Bombo y extracción de balotas (1-75)
		└── TriviaManager.gd         # Banco de preguntas y validación```


---

## 🪙 Economía y Ciclo de Juego (Game Loop)

```text
	   ┌─────────────────────────────────────────┐
	   │         Partida en Curso (Run)          │
	   │   - Vidas: 3/3                          │
	   │   - Monedas: 0 ──► Se ganan en juego    │
	   └────────────────────┬────────────────────┘
							│
			┌───────────────┴───────────────┐
			▼                               ▼
	[Pierde 3 Vidas]                  [Canta Bingo]
			│                               │
	├─► ¿Tiene ≥ 50 🪙?                     ├─► +5 ⭐ Estrellas (Permanentes)
	│    ├─ SÍ: Paga 50 🪙 y Revive (+1 ❤) │    +200 🪙 Monedas
	│    └─ NO: Fin de Partida               └─► Guarda progreso en JSON
	│           (Monedas se reinician a 0)      (Desbloqueo de Villa: 20 ⭐)
	└───────────────────────────────────────┘```
