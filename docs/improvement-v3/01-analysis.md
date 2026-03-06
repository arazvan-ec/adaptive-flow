# Fase 1: Analisis Detallado del Plugin Adaptive Flow v2.0.0

> Fecha: 2026-03-05 | Version analizada: v2.0.0 | 74/74 tareas completadas en plan anterior

---

## 1. Vision General

Adaptive Flow es un plugin para Claude Code que implementa un framework de **ingenieria compuesta**. Su principio central: **el peso del proceso es proporcional al peso de la tarea**. Clasifica cada solicitud del usuario en una "gravedad" (1-4) y ejecuta un workflow acorde.

### Diagrama de Arquitectura

```
                    ┌─────────────────────┐
                    │    Usuario pide      │
                    │    algo a Claude     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │     CLAUDE.md        │  ← Siempre cargado (34 lineas)
                    │  Tabla de routing    │     Clasifica gravedad 1-4
                    │  + 7 principios      │     Apunta a memory/
                    └──────────┬──────────┘
                               │
              ┌────────┬───────┼───────┬────────┐
              │        │       │       │        │
         ┌────▼───┐ ┌──▼──┐ ┌─▼──┐ ┌──▼──┐    │
         │G1:     │ │G2:  │ │G3: │ │G4:  │    │
         │direct  │ │plan-│ │full│ │shape│    │
         │        │ │exec │ │cyc │ │first│    │
         └────┬───┘ └──┬──┘ └─┬──┘ └──┬──┘    │
              │        │      │       │        │
              │     ┌──▼──────▼───────▼──┐     │
              │     │      SKILLS        │     │
              │     │ (contexto fork)    │     │
              │     │ planner            │     │
              │     │ implementer        │     │
              │     │ reviewer           │     │
              │     │ researcher         │     │
              │     └──────────┬─────────┘     │
              │                │               │
              └────────┬───────┘               │
                       │                       │
              ┌────────▼───────┐    ┌──────────▼──────────┐
              │     HOOKS      │    │      MEMORY          │
              │ (deterministicos)│  │ (persiste entre      │
              │ session-init    │    │  sesiones)           │
              │ post-compact    │    │ user-insights.yaml   │
              │ pre-write-guard │    │ learnings.yaml       │
              │ post-write-check│    │ patterns.yaml        │
              │ stop-check      │    │ discovered-insights  │
              └────────────────┘    │ current-task/        │
                                    └─────────────────────┘
              ┌──────────────────┐   ┌──────────────────────┐
              │   CORE GUIDES    │   │     TEMPLATES         │
              │ (carga Tier 3)   │   │ (artefactos de flow) │
              │ solid-reference  │   │ spec.md               │
              │ api-patterns     │   │ design.md             │
              │ testing-guide    │   │ tasks.md              │
              │ security-guide   │   │ retrospective.md      │
              └──────────────────┘   └──────────────────────┘
```

---

## 2. Punto de Entrada: CLAUDE.md (34 lineas)

**Archivo**: `CLAUDE.md`
**Cargado**: Siempre, automaticamente por Claude Code

### Contenido

1. **Tabla de routing** — Clasifica solicitudes por gravedad:
   - G1 (≤3 archivos, claro) → `flows/direct.md`
   - G2 (4-8 archivos, scope claro) → `flows/plan-execute.md`
   - G3 (>8 archivos o multi-capa/seguridad) → `flows/full-cycle.md`
   - G4 (scope ambiguo, necesita investigacion) → `flows/shape-first.md`

2. **Regla de incertidumbre**: Si confianza < 60%, preguntar al usuario.

3. **Punteros a memoria**: Instruye consultar `user-insights.yaml` y `learnings.yaml` en cada decision.

4. **7 principios**: Gravedad proporcional, contexto minimo viable, insights sobre reglas, workers efimeros, hooks deterministicos, compound por defecto, usuario tiene ultima palabra.

### Observacion

CLAUDE.md es deliberadamente minimo (~34 lineas). No contiene logica, solo routing y punteros. Esto es un resultado del plan v2.0 (P0-3: "Adelgazar CLAUDE.md").

---

## 3. Flows (4 workflows)

### 3.1 Direct Flow (Gravedad 1)

**Archivo**: `flows/direct.md` (51 lineas)
**Cuando**: ≤3 archivos, cambio trivial (typo, campo, rename)

**Proceso**:
1. Cargar solo insights `influence: high` + `when_to_apply: implementation`
2. Ejecutar el cambio directamente
3. Verificar tests + lint
4. Commit

**Restricciones**: No crea spec, no usa planner, no pide confirmacion (salvo archivos de riesgo: auth, pagos, config).

**Skills usados**: Ninguno (ejecucion directa por Claude).

### 3.2 Plan-Execute Flow (Gravedad 2)

**Archivo**: `flows/plan-execute.md` (91 lineas)
**Cuando**: 4-8 archivos, requiere planificar, scope claro

**Proceso**:
1. Escribir `meta.yaml` en `memory/current-task/` (gravity: 2, status: in_progress)
2. Cargar Tier 2: insights completos + learnings + briefing
3. Skill: **planner** (modo ligero) → produce `plan-and-tasks.md`
4. HITL: "Este plan captura tu intencion?"
5. Skill: **implementer** (TDD) → implementa segun plan
6. Verificar tests + lint
7. Actualizar meta.yaml → status: completed
8. Commit

**Integracion Plan Mode**: Si Claude Code esta en plan mode, el planner skill es redundante para G2.

**Artefactos**: `meta.yaml`, `plan-and-tasks.md`

### 3.3 Full-Cycle Flow (Gravedad 3)

**Archivo**: `flows/full-cycle.md` (107 lineas)
**Cuando**: >8 archivos, multi-capa, seguridad/pagos, cambios arquitecturales

**Proceso**:
1. Escribir `meta.yaml` (gravity: 3)
2. Cargar Tier 2
3. Skill: **planner** (modo completo) → `spec.md` + `design.md` + `tasks.md`
4. HITL: "Specs correctas?" + "Diseno correcto?"
5. Skill: **implementer** (TDD + BCP) → codigo + tests
6. Skill: **reviewer** (multi-dimensional) → QA report (APPROVED/REJECTED)
7. Si REJECTED → volver a paso 5 con feedback
8. Si APPROVED → Skill: **compound-capture** → patterns + learnings + briefing
9. Actualizar meta.yaml → status: completed
10. Commit

**Diferenciadores**: SOLID enforcement en design, BCP (3 intentos max), review loop, compound capture obligatorio.

**Artefactos**: `meta.yaml`, `spec.md`, `design.md`, `tasks.md`, `retrospective.md`

### 3.4 Shape-First Flow (Gravedad 4)

**Archivo**: `flows/shape-first.md` (105 lineas)
**Cuando**: Scope ambiguo, multiples approaches, reestructuracion

**Proceso**:
1. Escribir `meta.yaml` (gravity: 4)
2. Cargar Tier 2
3. Skill: **researcher** → analisis de scope real, dependencies, surface area
4. Escribir `shaped-brief.md` (Frame + Shape + Slices)
5. HITL: "El scope es correcto?"
6. Ejecutar **full-cycle** completo con shaped brief como input adicional

**Diferenciador clave**: Invierte tiempo en **descubrir** el scope antes de planificar. Evita planificar sobre supuestos incorrectos.

**Artefactos**: Todos los de full-cycle + `shaped-brief.md`

---

## 4. Skills (8 subagentes)

Todos corren con `context: fork` (contexto fresco, sin historial de conversacion).

### 4.1 Skills Worker (4 — invocados por flows)

#### Planner
**Archivo**: `skills/planner/SKILL.md` (123 lineas)
**Tools**: Read, Glob, Grep, Task, WebSearch, WebFetch
**Modos**:
- Ligero (G2): produce `plan-and-tasks.md` (plan + tasks + acceptance criteria en 1 archivo)
- Completo (G3-4): produce `spec.md` + `design.md` + `tasks.md` (3 archivos separados)
**SOLID**: En modo completo, DEBE incluir tabla de SOLID verdicts por componente
**Output**: summary, artifacts_created, solid_warnings, insights_applied, confidence

#### Implementer
**Archivo**: `skills/implementer/SKILL.md` (296 lineas) — el skill mas largo
**Tools**: Read, Glob, Grep, Edit, Write, Bash, Task, TodoWrite
**Ciclo core**: TDD por task (RED → GREEN → REFACTOR)
**BCP**: 3 intentos de correccion; si falla, escala con diagnostico detallado
**TodoWrite**: Expone progreso en tiempo real al usuario (el unico mecanismo de visibilidad durante ejecucion)
**Re-work**: Si reviewer rechaza, recibe feedback y crea sub-tasks de correccion
**Output**: summary, tasks_completed/total, tests_added, tests_passing, bcp_escalations, commits

#### Reviewer
**Archivo**: `skills/reviewer/SKILL.md` (136 lineas)
**Tools**: Read, Glob, Grep, Bash, Task
**4 dimensiones**: Correctness (vs spec), SOLID Compliance (vs design), Code Quality, Security
**Output**: QA Report con verdict APPROVED/REJECTED, blocking_issues, warnings, suggestions

#### Researcher
**Archivo**: `skills/researcher/SKILL.md` (147 lineas)
**Tools**: Read, Glob, Grep, Bash, Task, WebSearch, WebFetch
**3 modos**:
- Routing: respuesta rapida para determinar gravedad (<30s)
- Shaping: analisis profundo para G4
- Codebase: explorar estructura del proyecto
**Principio**: Objetividad — NO recibe insights (para no sesgarse)
**Output**: summary, mode, report, files_explored, time_taken

### 4.2 Skills Invocables (4 — invocados por el usuario via slash command)

#### Compound Capture (`/adaptive-flow:compound-capture`)
**Archivo**: `skills/compound-capture/SKILL.md` (131 lineas)
**Tools**: Read, Glob, Grep, Edit, Write, Bash
**Funcion**: Extrae conocimiento post-feature en 4 dimensiones:
1. PATTERNS → `patterns.yaml` (codigo reutilizable)
2. LEARNINGS → `learnings.yaml` (pattern/anti-pattern/boundary)
3. DISCOVERED INSIGHTS → `discovered-insights.yaml` (status: proposed)
4. RETROSPECTIVE → `retrospective.md`
**Genera**: `next-briefing.md` (top 3 learnings + patterns + warnings para proxima tarea)
**Insight Decay**: Detecta insights no validados en 5+ features

#### Insights Manager (`/adaptive-flow:insights-manager`)
**Archivo**: `skills/insights-manager/SKILL.md` (121 lineas)
**Tools**: Read, Glob, Grep, Edit, Write
**Operaciones**: list, add (guia interactiva), review (discovered → accepted/rejected), pause, retire, promote (discovered → user-insights)
**Mapping confidence→influence**: ≥0.8 → high, ≥0.6 → medium, <0.6 → low

#### Discover (`/adaptive-flow:discover`)
**Archivo**: `skills/discover/SKILL.md` (160 lineas)
**Tools**: Read, Glob, Grep, Bash, Write, Task
**Modos**:
- `--seed`: Onboarding completo (analyze stack + generate profile + suggest insights)
- `--profile`: Solo architecture profile
- `--status`: Estado actual de la memoria
**Output**: architecture-profile.yaml + discovered-insights.yaml con propuestas especificas al stack

#### SOLID Analyzer (`/adaptive-flow:solid-analyzer`)
**Archivo**: `skills/solid-analyzer/SKILL.md` (99 lineas)
**Tools**: Read, Glob, Grep, Task
**Modos**:
- `baseline`: Scorecard SOLID del codigo existente
- `design`: Validar un diseno propuesto contra SOLID
- `verify`: Comparar diseñado vs implementado

---

## 5. Sistema de Hooks (5 scripts + hooks.json)

Los hooks son **deterministicos** — ejecutan scripts bash automaticamente en eventos especificos.

### 5.1 hooks.json (registro de eventos)

**Archivo**: `hooks/hooks.json` (57 lineas)
**Eventos registrados**:
| Evento | Matcher | Script |
|--------|---------|--------|
| SessionStart | (any) | session-init.sh |
| SessionStart | compact | post-compact.sh |
| PreToolUse | Write\|Edit | pre-write-guard.sh |
| PostToolUse | Write\|Edit | post-write-check.sh |
| Stop | (any) | stop-check.sh |

### 5.2 session-init.sh (130 lineas)

**Trigger**: Inicio/resume de sesion
**Funcion**: Carga de memoria **Tier 1** (minima, siempre):
- Insights de alta influencia (`influence: high`, `status: active`)
- Architecture profile (si existe)
- Current task meta.yaml (si existe)
- Detecta plan mode (`CLAUDE_PERMISSION_MODE`)
**Implementacion**: Python3 para parsear YAML, fallback a grep.
**Output**: JSON con `additionalContext`

### 5.3 post-compact.sh (68 lineas)

**Trigger**: Despues de compactacion de contexto
**Funcion**: Re-inyecta informacion critica perdida:
- Tabla de routing completa
- Punteros a memoria
- Insights de alta influencia
- Meta de tarea actual
**Implementacion**: Misma logica que session-init pero incluye tabla de routing hardcoded

### 5.4 pre-write-guard.sh (73 lineas)

**Trigger**: Antes de Write/Edit
**Funcion dual**:
1. **Sensibilidad**: Detecta archivos sensibles (.env, credentials, secrets, .key, .pem, token, password) → warning
2. **Tier 3**: Sugiere guias core segun patron de archivo:
   - auth/security files → `core/security-guide.md`
   - controller/route/API files → `core/api-patterns.md`
   - test files → `core/testing-guide.md`
**Output**: JSON con `additionalContext` (sugerencias)

### 5.5 post-write-check.sh (85 lineas)

**Trigger**: Despues de Write/Edit
**Funcion**: Valida estructura de artefactos en `memory/current-task/`:
- `spec.md`: Debe tener "Acceptance Criteria" (warning si falta "Out of Scope")
- `design.md`: Debe tener seccion SOLID
- `tasks.md`: Debe tener checkbox items
- `plan-and-tasks.md`: Debe tener Plan + Tasks + Acceptance Criteria
**Output**: JSON con warnings

### 5.6 stop-check.sh (70 lineas)

**Trigger**: Antes de terminar sesion
**Funcion**: Enforce compound-capture para G3+:
- Lee gravity de `meta.yaml`
- Si gravity ≥ 3 Y no existe `retrospective.md` → bloquea stop
- Anti-loop: contador de bloqueos (max 2 bloqueos antes de permitir)
- Si gravity no es parseable → default a 3 (strict)
**Output**: `{"decision": "block", "reason": "..."}` o `{}`

---

## 6. Sistema de Memoria (4 YAML + 1 directorio)

### Carga por Tiers

| Tier | Cuando | Que carga | Quien lo carga |
|------|--------|-----------|----------------|
| 1 | Siempre (session start) | High-influence insights, arch profile, task meta | `session-init.sh` |
| 2 | Al activar flow (G2+) | Todos los insights, learnings, briefing | Flows (instruccion en cada flow) |
| 3 | Al escribir archivos | Guias core relevantes | `pre-write-guard.sh` |

### 6.1 user-insights.yaml

**8 insights iniciales**, 3 estados (`active`, `paused`, `retired`), 3 niveles de influencia:

| ID | Influence | Fase |
|----|-----------|------|
| tdd-produces-better-code | **high** | implementation |
| plan-before-complex-changes | **high** | routing, planning |
| validate-at-boundaries | **high** | implementation, design |
| solid-in-design-phase | medium | design, planning |
| small-focused-functions | medium | implementation, review |
| no-premature-abstraction | medium | implementation, review |
| atomic-commits | medium | implementation |
| explain-why-not-what | low | implementation, review |

### 6.2 learnings.yaml — VACIO

Schema definido (id, type, description, context, impact, tags, source_feature, captured) pero sin datos.
Tipos: `pattern`, `anti-pattern`, `boundary`.
Se llena via compound-capture.

### 6.3 patterns.yaml — VACIO

Schema definido (id, name, description, example_file, usage_count, tags, captured) pero sin datos.
Se llena via compound-capture.

### 6.4 discovered-insights.yaml — VACIO

Schema definido (id, observation, evidence, confidence, when_to_apply, status, tags, discovered, source_feature) pero sin datos.
Ciclo: `proposed` → `accepted` → `promoted` (a user-insights).
Se llena via compound-capture o discover --seed.

### 6.5 memory/current-task/ — Directorio de trabajo

Workspace temporal para la tarea activa. Contiene:
- `meta.yaml` — Metadata (name, gravity, flow, started, status)
- Artefactos del flow activo (spec.md, design.md, tasks.md, etc.)
- `retrospective.md` — Post-mortem (generado por compound-capture)

---

## 7. Guias Core (4 documentos de referencia)

| Guia | Archivo | Lineas | Contenido |
|------|---------|--------|-----------|
| SOLID Reference | `core/solid-reference.md` | 95 | 5 principios con patrones, red flags, y preguntas clave |
| API Patterns | `core/api-patterns.md` | 138 | REST conventions, error handling, pagination, versioning |
| Testing Guide | `core/testing-guide.md` | 86 | Ciclo TDD, piramide de tests, patron AAA, mocking |
| Security Guide | `core/security-guide.md` | 82 | OWASP top 10, auth/authz, secrets, input validation |

**Total**: 401 lineas de referencia. Se cargan bajo demanda (Tier 3) via `pre-write-guard.sh`.

---

## 8. Templates (4 plantillas de artefactos)

| Template | Para | Secciones clave |
|----------|------|----------------|
| `spec.md` | Especificacion | Problem Statement, Scope (In/Out), Acceptance Criteria, Edge Cases, Dependencies |
| `design.md` | Diseno | Architecture Overview, Key Decisions, Component Design, SOLID Analysis, Data Flow |
| `tasks.md` | Tareas | Prerequisites, Task List (por fases), Execution Order, Completion Criteria |
| `retrospective.md` | Retro | What Went Well, What Could Improve, Surprises (70% Boundary), Patterns, Learnings, Metrics |

---

## 9. Plugin Metadata

**Archivo**: `.claude-plugin/plugin.json`
```json
{
  "name": "adaptive-flow",
  "version": "2.0.0",
  "description": "Compound engineering framework for Claude Code. Adapts process gravity to task complexity. Skills are auto-discovered from skills/*/SKILL.md."
}
```

Skills se auto-descubren via convencion `skills/*/SKILL.md` (no hay lista explicita en plugin.json).

---

## 10. Estadisticas del Plugin

| Metrica | Valor |
|---------|-------|
| Archivos totales | ~30 |
| Lineas de codigo (hooks bash) | ~426 |
| Lineas de documentacion (markdown) | ~2,100+ |
| Skills | 8 (4 worker + 4 invocables) |
| Flows | 4 |
| Hooks | 5 |
| Templates | 4 |
| Guias core | 4 |
| Archivos de memoria | 4 YAML + 1 directorio |
| Insights precargados | 8 |
| Learnings precargados | 0 |
| Patterns precargados | 0 |

---

## 11. Flujo de Datos Completo (Ejemplo: Gravedad 3)

```
1. Usuario pide feature compleja
   │
2. CLAUDE.md clasifica → Gravedad 3 → flows/full-cycle.md
   │
3. session-init.sh (Tier 1)
   │ Carga: high-influence insights + arch profile + task meta
   │
4. Flow activa Tier 2
   │ Carga: todos los insights + learnings + briefing
   │
5. Escribe meta.yaml → memory/current-task/meta.yaml
   │ {name, gravity: 3, flow: full-cycle, status: in_progress}
   │
6. Skill: planner (fork, modo completo)
   │ Input: flow + insights (planning, design) + learnings + briefing
   │ Output: spec.md + design.md + tasks.md
   │ post-write-check.sh valida cada artefacto
   │
7. HITL: Usuario confirma spec + design
   │
8. Skill: implementer (fork, TDD + BCP)
   │ Input: tasks.md + design.md + insights (implementation) + learnings
   │ pre-write-guard.sh sugiere guias en cada Write/Edit
   │ TodoWrite actualiza progreso en tiempo real
   │ Commits atomicos por task
   │
9. Skill: reviewer (fork, multi-dimensional)
   │ Input: diff + spec.md + design.md + insights (review)
   │ Output: QA Report (APPROVED/REJECTED)
   │
10a. Si REJECTED → implementer recibe feedback → re-work → reviewer de nuevo
10b. Si APPROVED → continua
   │
11. Skill: compound-capture (fork)
    │ Input: spec.md + design.md + tasks.md + diff + QA report
    │ Output: patterns.yaml + learnings.yaml + discovered-insights.yaml
    │         retrospective.md + next-briefing.md
    │
12. stop-check.sh verifica retrospective.md existe antes de permitir stop
    │
13. FIN — Conocimiento capturado para proxima feature
```

---

## 12. Documentacion Existente Previa

**`memory/framework-analysis.md`**: Analisis anterior (fechado 2026-02-26, v1.0.0) que documenta la estructura cuando el plan v2.0 estaba al 50%. Ya obsoleto — describe workers/ (migrados a skills/) y hooks antiguos. Conserva valor historico pero no refleja el estado actual.

**`PLAN.md`**: Plan v2.0 con P0 (critico), P1 (importante), P2 (mejoras). Completado al 100%.

**`TASKLIST.md`**: 74/74 tareas completadas. Unica pendiente: P2-3 (guide triggers para archivos especificos en pre-write-guard.sh — marcada como no en vivo).

---

## 13. Archivo de la Sesion Anterior (README.md)

El `README.md` (122 lineas) documenta:
- Quick Start (instalacion, primer uso, personalizacion)
- Diagrama ASCII del flujo general
- Tabla de skills disponibles
- Estructura de directorios
- Key Concepts (Gravity, Insights, Skills, Hooks, Compound)
