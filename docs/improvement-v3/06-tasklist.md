# Tasklist: Mejora del Plugin Adaptive Flow v3.0

> Estado: `COMPLETADA` | Ultima actualizacion: 2026-03-06
>
> Leyenda: `[ ]` Pendiente | `[~]` En progreso | `[x]` Completada | `[!]` Bloqueada

---

## Fase 1: Analisis Detallado del Plugin

- [x] 1.1 Leer y documentar CLAUDE.md (router)
- [x] 1.2 Leer y documentar los 4 flows
- [x] 1.3 Leer y documentar los 8 skills
- [x] 1.4 Leer y documentar los 5 hooks
- [x] 1.5 Leer y documentar el sistema de memoria (4 YAML)
- [x] 1.6 Leer y documentar las 4 guias core
- [x] 1.7 Leer y documentar los 4 templates
- [x] 1.8 Documentar flujo de datos completo
- [x] 1.9 Documentar estadisticas del plugin
- [x] 1.10 Commit y push de 01-analysis.md

**Resultado**: `docs/improvement-v3/01-analysis.md` (489 lineas)

---

## Fase 2: Identificacion de Mejoras

- [x] 2.1 Identificar gaps funcionales (A1-A3)
- [x] 2.2 Identificar problemas de robustez en hooks (B1-B5)
- [x] 2.3 Identificar mejoras de UX (C1-C4)
- [x] 2.4 Identificar mejoras del sistema de memoria (D1-D4)
- [x] 2.5 Identificar mejoras de integracion con Claude Code (E1-E4)
- [x] 2.6 Identificar mejoras de calidad de contenido (F1-F3)
- [x] 2.7 Identificar mejoras de arquitectura (G1-G4)
- [x] 2.8 Crear matriz de priorizacion
- [x] 2.9 Commit y push de 02-improvements.md

**Resultado**: `docs/improvement-v3/02-improvements.md` (300 lineas, 28 mejoras en 7 categorias)

---

## Fase 3: Investigacion de Mejores Practicas

- [x] 3.1 Investigar EveryInc/compound-engineering-plugin
- [x] 3.2 Investigar otros plugins populares (Superpowers, Context Engineering Kit, etc.)
- [x] 3.3 Investigar mejores practicas de hooks (14 lifecycle events, 3 handler types)
- [x] 3.4 Investigar Agent Teams y coordinacion multi-agente
- [x] 3.5 Investigar sistemas de memoria para agentes IA (Mem0, Zep, Letta)
- [x] 3.6 Investigar Cursor Rules vs CLAUDE.md y context engineering
- [x] 3.7 Documentar cada practica con fuente (URL) y aplicabilidad
- [x] 3.8 Commit y push de 03-best-practices.md

**Resultado**: `docs/improvement-v3/03-best-practices.md` — 7 areas, 14 practicas priorizadas, 20+ fuentes

---

## Fase 4: Plan de Implementacion por Fases Paralelas

- [x] 4.1 Agrupar mejoras en tracks paralelos
- [x] 4.2 Incorporar best practices de fase 3
- [x] 4.3 Definir Track A: Robustez de Hooks (6 tareas)
- [x] 4.4 Definir Track B: Sistema de Memoria (5 tareas)
- [x] 4.5 Definir Track C: UX y Onboarding (5 tareas)
- [x] 4.6 Definir Track D: Integracion Claude Code (5 tareas)
- [x] 4.7 Definir Track E: Contenido y Guias (5 tareas)
- [x] 4.8 Definir Track F: Testing y CI/CD (5 tareas)
- [x] 4.9 Definir dependencias entre tracks
- [x] 4.10 Commit y push de 04-implementation-plan.md

**Resultado**: `docs/improvement-v3/04-implementation-plan.md` — 6 tracks, 31 tareas, dependencias definidas

---

## Fase 5: Cuestionamiento y Validacion

- [x] 5.1 D1: Requerir jq como dependencia para hooks
- [x] 5.2 D2: Agent Teams solo evaluacion en v3
- [x] 5.3 D3: Cold start con datos reales del plugin
- [x] 5.4 D4: bats-core + shellcheck para testing
- [x] 5.5 D5: Analisis de diseno pluggable completo
- [x] 5.6 D6: Review multi-perspectiva configurable por gravedad
- [x] 5.7 D7: Alcance v3 = 6 tracks completos, validar entre tracks

**Resultado**: `docs/improvement-v3/05-decisions-log.md` — 7 decisiones tomadas

---

---

# IMPLEMENTACION v3.0 — Tareas Atomicas

> Alcance v3: 6 Tracks completos (A + B + C + D + E + F)
> Orden recomendado: F primero → A + B + C + E en paralelo → D al final
> Antes de pasar de un track al siguiente, validar con el usuario
> Prioridad dentro de cada track: tareas S (small) primero

---

## Track F: Testing y CI/CD (ejecutar primero o en paralelo)

> Objetivo: asegurar que cambios de A y B no rompan nada

- [x] **F1** [S] Correr shellcheck en los 5 hooks y corregir warnings
  - Archivos: `hooks/*.sh`
  - Commit: fix por hook o batch si son pocos

- [x] **F2** [S] Crear directorio `tests/` con estructura basica
  - Archivos: `tests/README.md`, estructura de directorios

- [x] **F3** [M] Crear tests bats para session-init.sh
  - Archivos: `tests/hooks/session-init.bats`
  - Mocks: YAML de insights, arch profile, meta.yaml

- [x] **F4** [M] Crear tests bats para stop-check.sh
  - Archivos: `tests/hooks/stop-check.bats`
  - Mocks: meta.yaml con diferentes gravities

- [x] **F5** [M] Crear tests bats para pre-write-guard.sh y post-write-check.sh
  - Archivos: `tests/hooks/pre-write-guard.bats`, `tests/hooks/post-write-check.bats`
  - Mocks: JSON input con file_path

- [x] **F6** [M] Crear tests bats para post-compact.sh
  - Archivos: `tests/hooks/post-compact.bats`

- [x] **F7** [S] Crear script validate-skills.sh
  - Archivos: `tests/validate-skills.sh`
  - Verifica: frontmatter, context: fork, allowed-tools

- [x] **F8** [S] Crear script validate-memory.sh
  - Archivos: `tests/validate-memory.sh`
  - Verifica: YAML valido, campos requeridos

- ~~**F9** [M] Crear GitHub Actions CI~~ *(descartada por el usuario)*

---

## Track A: Robustez de Hooks

> Objetivo: hooks confiables, mantenibles, sin bugs silenciosos
> Dependencia: D1 (jq requerido)

- [x] **A1** [S] Crear `hooks/lib.sh` con funcion `json_context()`
  - Archivos: `hooks/lib.sh` (nuevo)
  - Funcion: recibe string, produce JSON con jq: `jq -n --arg ctx "$1" '{additionalContext: $ctx}'`

- [x] **A2** [S] Agregar funcion `parse_json_field()` a lib.sh
  - Archivos: `hooks/lib.sh`
  - Funcion: extrae campo de JSON stdin con jq

- [x] **A3** [S] Agregar funcion `parse_yaml_insights()` a lib.sh
  - Archivos: `hooks/lib.sh`
  - Funcion: python3+yaml → fallback a grep. Centralizada, no duplicada.

- [x] **A4** [S] Refactorizar session-init.sh para usar lib.sh
  - Archivos: `hooks/session-init.sh`
  - Reemplazar: escape manual → json_context(), parseo duplicado → parse_yaml_insights()

- [x] **A5** [S] Refactorizar post-compact.sh para usar lib.sh
  - Archivos: `hooks/post-compact.sh`
  - Reemplazar: escape manual → json_context(), parseo duplicado → parse_yaml_insights()

- [x] **A6** [S] Refactorizar pre-write-guard.sh para usar lib.sh
  - Archivos: `hooks/pre-write-guard.sh`
  - Reemplazar: grep de file_path → parse_json_field(), escape manual → json_context()

- [x] **A7** [S] Refactorizar post-write-check.sh para usar lib.sh
  - Archivos: `hooks/post-write-check.sh`
  - Reemplazar: grep de file_path → parse_json_field(), escape manual → json_context()

- [x] **A8** [S] Arreglar stop-check.sh: counter con session awareness
  - Archivos: `hooks/stop-check.sh`
  - Cambio: incluir timestamp en counter file para distinguir sesiones

- [x] **A9** [S] Actualizar README.md con requisito de jq
  - Archivos: `README.md`
  - Agregar: jq como requisito en seccion de instalacion

- [x] **A10** [S] Actualizar plugin.json con requirements
  - Archivos: `.claude-plugin/plugin.json`
  - Agregar: campo requirements con jq

---

## Track B: Sistema de Memoria

> Objetivo: memoria funcional con datos reales y cold start
> Dependencia: D3 (datos reales del plugin)

- [x] **B1** [M] Extraer learnings reales del desarrollo v1→v2
  - Archivos: `memory/learnings.yaml`
  - Fuente: analizar PLAN.md, TASKLIST.md, historial git
  - Minimo 5 learnings (pattern, anti-pattern, boundary)

- [x] **B2** [M] Extraer patterns reales del plugin
  - Archivos: `memory/patterns.yaml`
  - Fuente: patrones de codigo usados en hooks, skills, flows
  - Minimo 3 patterns con example_file

- [x] **B3** [S] Crear directorio memory/briefings/
  - Archivos: `memory/briefings/.gitkeep`

- [x] **B4** [S] Modificar compound-capture para guardar historial de briefings
  - Archivos: `skills/compound-capture/SKILL.md`
  - Cambio: antes de sobreescribir next-briefing.md, mover anterior a memory/briefings/{date}.md

- [x] **B5** [S] Marcar insights starter como influence: low por defecto
  - Archivos: `memory/user-insights.yaml`
  - Cambio: los 5 insights medium pasan a low. Solo los 3 high se mantienen.
  - Razon: son genericos, el usuario los valida con el tiempo

- [x] **B6** [S] Documentar taxonomia de memoria
  - Archivos: `memory/README.md` (nuevo)
  - Contenido: que tipo es cada archivo (episodic, semantic, entity), como se usa, decay policy

- [x] **B7** [S] Limpiar framework-analysis.md obsoleto
  - Archivos: `memory/framework-analysis.md`
  - Accion: eliminar o reemplazar con referencia a docs/improvement-v3/01-analysis.md

- [x] **B8** [S] Verificar closed compound loop
  - Archivos: `flows/plan-execute.md`, `flows/full-cycle.md`
  - Verificar: planner y reviewer leen learnings.yaml y patterns.yaml
  - Si no, agregar instrucciones explicitas

---

## Track C: UX y Onboarding

> Objetivo: mejorar experiencia de usuario y descubribilidad del plugin
> Dependencia: ninguna (independiente)

- [x] **C1** [S] Agregar feedback visible del routing en CLAUDE.md
  - Archivos: `CLAUDE.md`
  - Cambio: agregar instruccion "Al clasificar, comunicar al usuario: Gravedad N porque X"
  - Una linea antes de ejecutar el flow

- [x] **C2** [S] Agregar instruccion de feedback en cada flow
  - Archivos: `flows/direct.md`, `flows/plan-execute.md`, `flows/full-cycle.md`, `flows/shape-first.md`
  - Cambio: primera linea de cada flow confirma gravedad asignada

- [x] **C3** [S] Crear seccion de troubleshooting en README
  - Archivos: `README.md`
  - Contenido: requisitos (python3+yaml, jq), como verificar activacion, errores comunes

- [x] **C4** [S] Enriquecer plugin.json con metadatos
  - Archivos: `.claude-plugin/plugin.json`
  - Agregar: author, license, requirements, claude_code_version_min
  - Nota: coordinar con A10 si se ejecuta Track A primero

- [x] **C5** [M] Crear skill de diagnostico / dry-run
  - Archivos: `skills/diagnostics/SKILL.md` (nuevo)
  - Funcion: `/adaptive-flow:diagnostics` muestra gravedad estimada, flow, insights aplicables, estado memoria
  - Util para debug y verificacion sin ejecutar el flow

- [x] **C6** [S] Agregar --help a skills invocables
  - Archivos: `skills/compound-capture/SKILL.md`, `skills/insights-manager/SKILL.md`, `skills/discover/SKILL.md`, `skills/solid-analyzer/SKILL.md`
  - Cambio: primer parrafo de cada SKILL.md sirve como help inline

---

## Track D: Integracion con Claude Code Moderno

> Objetivo: aprovechar features nuevas de Claude Code (2026)
> Dependencia: parcial de Track A (hooks refactorizados facilitan nuevos hooks)

- [x] **D1** [S] Usar CLAUDE_ENV_FILE para persistir estado de sesion
  - Archivos: `hooks/session-init.sh`
  - Cambio: escribir gravity, flow activo, task name en CLAUDE_ENV_FILE
  - Reemplaza archivos temporales para estado de sesion

- [x] **D2** [M] Agregar hook SubagentStart para inyectar contexto
  - Archivos: `hooks/hooks.json`, `hooks/subagent-start.sh` (nuevo)
  - Funcion: inyectar insights y task meta relevantes a subagentes
  - Evento: SubagentStart

- [x] **D3** [M] Agregar hooks PostToolUseFailure y TaskCompleted
  - Archivos: `hooks/hooks.json`, `hooks/tool-failure.sh` (nuevo), `hooks/task-completed.sh` (nuevo)
  - PostToolUseFailure: logging de fallos, sugerencias de recovery
  - TaskCompleted: trigger para actualizar estado del task

- [x] **D4** [M] Evaluar Prompt hooks para pre-write-guard
  - Archivos: `hooks/pre-write-guard.sh` o nuevo prompt hook
  - Evaluacion: comparar pattern matching actual vs evaluacion semantica
  - Entregable: documento de decision con pros/cons y recomendacion

- [x] **D5** [M] Evaluar y documentar viabilidad de Agent Teams para G3+
  - Archivos: `docs/improvement-v3/agent-teams-evaluation.md` (nuevo)
  - Evaluar: planner + implementer + reviewer como teammates vs subagentes
  - Documentar: coste (5-7x tokens), beneficios, cuando tiene sentido
  - Decision D2: solo evaluacion, no implementacion en v3

- [x] **D6** [L] Implementar review multi-perspectiva configurable
  - Archivos: `skills/reviewer/SKILL.md`
  - G3: 4 perspectivas (correctness, design, quality, security)
  - G4: 6 perspectivas (+performance, +over-engineering)
  - Cada perspectiva es subagente paralelo, resultados sintetizados en QA report
  - Decision D6: configurable por gravedad

---

## Track E: Contenido y Guias

> Objetivo: hacer el contenido adaptativo y mas util
> Dependencia: ninguna (independiente)

- [x] **E1** [S] Completar guide triggers P2-3 en pre-write-guard
  - Archivos: `hooks/pre-write-guard.sh`
  - Completar detecciones: auth/security patterns, controller/route/api, test files
  - Verificar que additionalContext se inyecta correctamente

- [x] **E2** [S] Limpiar framework-analysis.md obsoleto
  - Archivos: `memory/framework-analysis.md`
  - Accion: eliminar contenido obsoleto, reemplazar con referencia a docs/improvement-v3/01-analysis.md
  - Nota: coordinar con B7 si se ejecuta Track B primero (misma tarea)

- [x] **E3** [M] Renombrar solid-analyzer a design-analyzer con modo pluggable
  - Archivos: `skills/solid-analyzer/SKILL.md` → `skills/design-analyzer/SKILL.md`
  - Mantener SOLID como default para OOP
  - Agregar: composicion (FP), bounded contexts (microservices), component architecture (frontend)
  - El analyzer detecta paradigma via discover/architect profile y aplica framework correcto
  - Decision D5: pluggable completo

- [x] **E4** [S] Crear guias core alternativas para paradigmas no-OOP
  - Archivos: `core/fp-principles.md` (nuevo), `core/component-architecture.md` (nuevo)
  - Contenido: principios equivalentes a SOLID para FP y frontend
  - Referenciados por design-analyzer segun paradigma detectado

- [x] **E5** [S] Hacer templates adaptativos por tipo de proyecto
  - Archivos: `templates/spec.md`, `templates/design.md`, `templates/tasks.md`, `templates/retrospective.md`
  - Agregar secciones condicionales: "Si frontend, incluir...", "Si API, incluir..."

- [x] **E6** [S] Verificar closed compound loop
  - Archivos: `flows/plan-execute.md`, `flows/full-cycle.md`
  - Verificar: planner y reviewer leen learnings.yaml y patterns.yaml
  - Si no, agregar instrucciones explicitas de lectura
  - Nota: coordinar con B8 si se ejecuta Track B primero (misma verificacion)

---

## Resumen de Estado

| Fase planificacion | Estado | Entregable | Completitud |
|--------------------|--------|------------|-------------|
| 1. Analisis | `[x] Completada` | 01-analysis.md | 10/10 |
| 2. Mejoras | `[x] Completada` | 02-improvements.md | 9/9 |
| 3. Best Practices | `[x] Completada` | 03-best-practices.md | 8/8 |
| 4. Plan | `[x] Completada` | 04-implementation-plan.md | 10/10 |
| 5. Validacion | `[x] Completada` | 05-decisions-log.md | 7/7 |
| 6. Tasklist | `[x] Completada` | 06-tasklist.md | — |

| Track implementacion | Tareas | Completadas | Estado |
|---------------------|--------|-------------|--------|
| F: Testing y CI/CD | 9 | 8 | `[x] Completada` |
| A: Robustez Hooks | 10 | 10 | `[x] Completada` |
| B: Sistema de Memoria | 8 | 8 | `[x] Completada` |
| C: UX y Onboarding | 6 | 6 | `[x] Completada` |
| D: Integracion Claude Code | 6 | 6 | `[x] Completada` |
| E: Contenido y Guias | 6 | 6 | `[x] Completada` |
| **Total v3** | **44** | **44** | **100%** |

### Notas de coordinacion entre tracks

- **B7 y E2** son la misma accion (limpiar framework-analysis.md) — ejecutar solo una vez
- **B8 y E6** son la misma verificacion (closed compound loop) — ejecutar solo una vez
- **A10 y C4** ambos tocan plugin.json — coordinar cambios
- **Track D** depende parcialmente de Track A (hooks refactorizados facilitan nuevos hooks)

---
---

# MEJORAS POST-v3 — Identificadas pero fuera del scope original

> Origen: 02-improvements.md (28 mejoras identificadas, v3 cubrio las prioritarias)
> Orden recomendado: G1 → G2 → G3 → G4 → G5

---

## Track G: Hardening y Extensiones

> Objetivo: mejoras de alto valor no cubiertas en v3
> Prioridad: por ratio impacto/esfuerzo

- [x] **G1** [S] Hook Bash guard para comandos peligrosos
  - Archivos: `hooks/bash-guard.sh` (nuevo), `hooks/hooks.json`
  - Interceptar: `rm -rf`, `DROP TABLE`, `git push --force`, `chmod 777`
  - Evento: PreToolUse(Bash)

- [x] **G2** [M] Búsqueda y filtrado en memoria
  - Archivos: `skills/insights-manager/SKILL.md`
  - Agregar: `--list --tag=X`, `--list --influence=high`, `--list --since=2026-01`
  - Aplicar también a learnings y patterns

- [x] **G3** [M] Schema validación para skills (inputs/outputs)
  - Archivos: `tests/validate-skills.sh` (extender), esquema JSON
  - Verificar: inputs/outputs documentados en cada SKILL.md coinciden con uso real

- [x] **G4** [L] MCP server para memoria
  - Archivos: `mcp/` (nuevo directorio), server en Python o Node
  - Exponer: insights, learnings, patterns como queries estructuradas
  - Permitir: búsqueda semántica, filtrado, estadísticas

- [x] **G5** [M] Guías core adaptativas al stack detectado
  - Archivos: `core/*.md`, `skills/discover/SKILL.md`
  - `discover --seed` genera secciones stack-specific en las guías
  - Ej: security-guide.md con ejemplos Express vs Django vs Go

---

## Resumen Post-v3

| Track | Tareas | Completadas | Estado |
|-------|--------|-------------|--------|
| G: Hardening | 5 | 5 | `[x] Completada` |
