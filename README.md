# 🎱 Bingo Arcade Académico

Un videojuego casual y arcade de Bingo móvil/escritorio desarrollado en **Godot Engine 4 (4.2+)**, enfocado en estándares modernos de interfaz (Glassmorphism, feedback háptico visual y *juice* táctil), dinámicas interactivas de trivia educativa y personalización estética en tiempo real.

---

## ✨ Características Principales

* **Mecánica Clásica de Bingo Americano (75 Balotas):**
  * Matriz balanceada de 5×5 (Columnas B, I, N, G, O) con casilla central dorada libre.
  * Verificación de patrones ganadores: líneas horizontales, verticales, diagonales y cuatro esquinas.
* **Tómbola Automática con Cadencia Dinámica:**
  * Extracción continua de balotas cada 7 segundos con temporizador visual regresivo.
  * Control manual para pausar y reanudar el sorteo en tiempo real.
  * Bandeja de historial con las últimas balotas extraídas organizadas cronológicamente.
* **Desafíos de Trivia Integrados (Minijuego):**
  * Activación probabilística durante las extracciones de la tómbola.
  * Modal emergente con temporizador, preguntas de lógica/cultura y recompensa de monedas/estrellas.
* **Motor de Ambientes Dinámicos (Dual Theme):**
  * Alternancia fluida entre temáticas visuales:
	* **Resort Costero:** Paleta esmeralda con iluminación tropical.
	* **Villa de Bloques:** Paleta ámbar cálida al atardecer.
  * Filtro de desenfoque en tiempo real (*Screen Blur Shader*) para garantizar legibilidad y alto contraste sobre el tablero.
* **Diseño UI/UX (Estándar 2026):**
  * Acabados acrílicos flotantes y estilo *Glassmorphism* mediante `StyleBoxFlat` y shaders CanvasItem.
  * HUD superior segmentado en cápsulas independientes (Vidas, Monedas y Estrellas).
  * Animaciones procedimentales elásticas (*Tween Bounce/Scale*) al marcar casillas y extraer balotas.
  * Respuesta visual a errores (*Shake effect*) al pulsar números incorrectos.
* **Diseño Sonoro Híbrido:**
  * SFX analógico de marcado con lápiz recortado dinámicamente con desvanecimiento (*fade-out* suave).
  * Alertas sonoras de extracción de balota, aciertos de trivia, penalizaciones de vida y fanfarrias finales de victoria y derrota.

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
		└── TriviaManager.gd         # Banco de preguntas y validación
