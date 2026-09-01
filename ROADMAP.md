# Roadmap / Estado del proyecto

Estado del juego: **minigame top-down arcade roguelite (cowboy vs zombies)**.
Playable: menú → play (oleadas) → pausa → game over, con mejoras y high score.

## Qué ya funciona

- Escenas (menú, play, pausa, game over) vía `scene_manager.lua` (FSM).
- Jugador con FSM: `alive → hit → dead` + invulnerabilidad con parpadeo.
- 3 enemigos (chaser / runner / tank) con FSM de vida/muerte y animación de ataque.
- Oleadas progresivas (`waves.lua`) y armas con balas.
- Pickups de mejoras: daño, vida, cadencia, bala más grande (`upgrades.lua`).
- Juice: partículas, screen shake, muzzle flash, luz de linterna, sombras.
- **Pipeline de sprites profesional**: ASCII maps (data-as-code) → build tool →
  `sheet.png` + `atlas.lua` → `SpriteBatch` + shader de outline/flash (ADR-0008).
- Identidad visual: canvas virtual 480x270, paleta central, font Press Start 2P.
- High score con guardado (`save.lua` / `save_io.lua`).
- Tests headless (busted) + lint (luacheck) + CI local (Makefile) + 8 ADRs.
- **Windows**: toolchain instalable (`bootstrap.ps1`), `make run`/`make dev`
  resuelven la ruta de LÖVE sin depender del PATH de la sesión.
- **Pantalla de título con personalidad**: hero sprite grande (30x38) con
  animaciones idle/draw, logo "COWBOY vs ZOMBIES" animado, sunset + mesas +
  pueblo, siluetas zombies, tumbleweed, polvo, estrellas, disparo al entrar a
  PLAY, overlay "How to Play". Lógica pura en `title_scene.lua` (testeado).

## Qué falta (priorizado)

### P0 — Presentación (bloqueante para portfolio)
- [x] `README.md` actualizado con el juego real, pipeline de sprites y comandos Windows.
- [ ] Añadir **capturas de pantalla / GIF animado** al repo (el modo `love . --screenshot` ya existe).
- [ ] Escribir un "how to play" breve (controles: WASD + disparo automático).

### P1 — Toolchain / verificación
- [x] Toolchain Windows: LÖVE 11.5, Lua 5.4, LuaRocks, busted, luacheck.
- [x] Scripts: `bootstrap.ps1`, `test.ps1`, `run.ps1` + Makefile multiplataforma.
- [x] `test.ps1` → luacheck 0 warnings + busted 73/73; juego arranca y dibuja.
- [ ] Habilitar CI automático en push (hoy manual) u opcional.
- [ ] (Opcional) GitHub Actions job de Windows.

### P2 — Pulido visual / animación
- [x] Outline automático, paleta ampliada con sombreado, animaciones separadas
      (cowboy idle/walk/shoot, zombie walk/attack), sombreado real en sprites.
- [x] Render en SpriteBatch + shader (outline/flash en GPU, sin pre-hornear).
- [x] **Auto-shading en build**: rampas de 5 pasos con hue-shift por material +
      luz direccional top-left (`scripts/pixel.lua`, testeado con busted).
- [ ] Más frames / transiciones suaves entre estados.
- [ ] Paleta swap por shader para variantes de enemigos (colorido).
- [ ] Efectos adicionales (impacto, sangre, sombras dinámicas).

### P3 — Gameplay / contenido
- [ ] Definir condición de victoria o pulir el loop endless.
- [ ] Balance de oleadas y mejoras.
- [ ] Nuevas mejoras / armas / tipos de enemigo.
- [ ] Feedback de daño más claro (números, indicador de dirección del golpe).

### P4 — Distribución
- [ ] Generar y documentar el build `.love` jugable.
- [ ] (Opcional) exportar ejecutable de escritorio.

### P5 — Calidad / técnico
- [ ] Convertir el modo `--screenshot` en un script QA (`scripts/screenshot.ps1`).
- [ ] Documentar en README cómo regenerar sprites (`make sprites`) y verificar.
- [ ] Revisar la nota del overlay de oscuridad vs luz al renderizar sprites.