# Adaptive Flow — Análisis Completo del Framework

**Fecha**: 2026-02-26
**Versión**: v1.0.0 (Plan v2.0 al 50%)

---

## 1. Estructura del Repositorio

```
adaptive-flow/
├── CLAUDE.md                          # Punto de entrada — Tabla de routing y principios
├── README.md                          # Getting started y overview
├── PLAN.md                            # Plan de mejoras v2.0
├── TASKLIST.md                        # Progreso de implementación (50% completado)
│
├── .claude-plugin/
│   └── plugin.json                    # Metadata del plugin (v1.0.0)
│
├── flows/                             # 4 workflows basados en gravedad
│   ├── direct.md                      # Gravedad 1: Ejecución directa (≤3 archivos)
│   ├── plan-execute.md                # Gravedad 2: Plan + ejecución (4-8 archivos)
│   ├── full-cycle.md                  # Gravedad 3: Ciclo completo (>8 archivos, alto riesgo)
│   └── shape-first.md                 # Gravedad 4: Investigación → plan → ejecución
│
├── workers/                           # 4 plantillas de subagentes
│   ├── planner.md                     # Planificación y diseño de arquitectura
│   ├── implementer.md                 # TDD y BCP (Bounded Correction Protocol)
│   ├── reviewer.md                    # QA multi-dimensional
│   └── researcher.md                  # Análisis basado en evidencia
│
├── hooks/                             # Quality gates determinísticos
│   ├── hooks.json                     # Registro de hooks para Claude Code API
│   ├── session-init.sh                # SessionStart: Cargar memoria al contexto
│   ├── post-compact.sh                # SessionStart(compact): Re-inyectar contexto
│   ├── pre-write-guard.sh             # PreToolUse: Verificaciones de sensibilidad
│   ├── post-write-check.sh            # PostToolUse: Validar estructura de artefactos
│   └── stop-check.sh                  # Stop: Forzar compound-capture para gravedad 3+
│
├── skills/                            # Skills invocables
│   ├── compound-capture.md            # Extraer learnings post-feature
│   ├── insights-manager.md            # Gestionar insights del usuario
│   ├── discover.md                    # Bootstrap de memoria desde análisis de codebase
│   └── solid-analyzer.md              # Análisis contextual de principios SOLID
│
├── templates/                         # Plantillas de artefactos
│   ├── spec.md                        # Qué debe hacer el sistema
│   ├── design.md                      # Cómo implementarlo (decisiones SOLID)
│   ├── tasks.md                       # Lista ordenada de tareas
│   └── retrospective.md              # Reflexión post-feature
│
├── core/                              # Guías de referencia (carga bajo demanda)
│   ├── solid-reference.md             # 5 principios SOLID con patrones y red flags
│   ├── api-patterns.md                # Convenciones REST, manejo de errores, paginación
│   ├── testing-guide.md               # Ciclo TDD, pirámide de tests, patrón AAA
│   └── security-guide.md              # OWASP, auth/authz, manejo de secretos
│
└── memory/                            # Conocimiento persistente entre sesiones
    ├── user-insights.yaml             # 8 insights iniciales (influence: high/medium)
    ├── learnings.yaml                 # Patrones técnicos extraídos (vacío)
    ├── patterns.yaml                  # Patrones de código de features (vacío)
    ├── discovered-insights.yaml       # Insights propuestos por IA (vacío)
    └── current-task/                  # Workspace de tarea activa (vacío)
```

---

## 2. Modelo Mental — Routing por Gravedad

| Gravedad | Criterio | Flow | Proceso |
|----------|----------|------|---------|
| **1** | ≤3 archivos, cambio claro | `direct.md` | Ejecución directa (sin planificación) |
| **2** | 4-8 archivos, scope claro | `plan-execute.md` | Plan ligero + TDD |
| **3** | >8 archivos o alto riesgo | `full-cycle.md` | Spec → Design → TDD → Review → Compound |
| **4** | Scope ambiguo | `shape-first.md` | Investigación → Brief moldeado → Ciclo completo |

**Filosofía**: El peso del proceso es proporcional al peso de la tarea.

---

## 3. Detalle de Flows

### Flow Direct (Gravedad 1)
- **Cuándo**: ≤3 archivos, cambio obvio, sin ambigüedad
- **Proceso**: Cargar insights de alta influencia → Ejecutar → Verificar tests → Commit
- **Sin**: Spec, design, planificación, worker planner
- **Ejemplo**: "Añade campo email a UserDTO"

### Flow Plan-Execute (Gravedad 2)
- **Cuándo**: 4-8 archivos, scope claro, beneficia de planificación
- **Artefacto**: `memory/current-task/plan-and-tasks.md`
- **Workers**: Planner (modo ligero) → Implementer (TDD)
- **HITL**: Un checkpoint post-plan, antes de implementación
- **Ejemplo**: "Implementa paginación en API de Productos"

### Flow Full-Cycle (Gravedad 3)
- **Cuándo**: >8 archivos, multi-capa, seguridad/pagos, cambios arquitectónicos
- **Artefactos**: `spec.md` + `design.md` + `tasks.md` + `retrospective.md`
- **Workers**: Planner (completo) → Implementer (TDD+BCP) → Reviewer (QA)
- **SOLID**: Planner produce tabla de análisis SOLID en design.md
- **BCP**: Implementer tiene 3 intentos de auto-corrección, luego escala
- **Loop**: Si reviewer rechaza → Implementer rehacer → Reviewer de nuevo
- **Compound**: Extraer patterns, learnings, discovered insights al completar

### Flow Shape-First (Gravedad 4)
- **Cuándo**: Scope ambiguo, múltiples enfoques, reestructuración mayor
- **Único**: Researcher primero para descubrir scope real
- **Artefacto**: `memory/current-task/shaped-brief.md` (Frame + Shape + Slices)
- **Luego**: Ejecutar full-cycle con shaped brief como input adicional

---

## 4. Workers (Subagentes con Contexto Fresco)

Cada uno ejecuta con `context: fork` (contexto aislado) para prevenir bloat de tokens.

### Planner
- **Modos**: Ligero (gravedad 2) o Completo (gravedad 3-4)
- **Output**: `plan-and-tasks.md` (G2) o `spec.md` + `design.md` + `tasks.md` (G3-4)
- **SOLID**: En modo completo, incluye tabla de veredictos SOLID por componente

### Implementer
- **Ciclo core**: TDD por tarea (RED → GREEN → REFACTOR)
- **BCP**: 3 intentos de corrección automática, luego escala con diagnóstico
- **Atomicidad**: Un commit por tarea completada

### Reviewer
- **4 Dimensiones**: Corrección, Cumplimiento SOLID, Calidad de código, Seguridad
- **Output**: QA Report con veredicto APPROVED o REJECTED

### Researcher
- **Modos**: Routing (verificación rápida de gravedad), Shaping (análisis profundo), Codebase (exploración)
- **Basado en evidencia**: Cada claim respaldado por paths reales de archivos

---

## 5. Sistema de Hooks (Quality Gates Determinísticos)

| Hook | Trigger | Script | Función |
|------|---------|--------|---------|
| SessionStart | Inicio/resume de sesión | `session-init.sh` | Cargar insights de alta influencia, perfil de arquitectura, learnings |
| SessionStart | Post-compact | `post-compact.sh` | Re-inyectar tabla de routing + insights core |
| PreToolUse | Antes de Write/Edit | `pre-write-guard.sh` | Verificar archivos sensibles, sugerir guías relevantes |
| PostToolUse | Después de Write/Edit | `post-write-check.sh` | Validar estructura de artefactos spec/design/tasks |
| Stop | Antes de terminar sesión | `stop-check.sh` | Para gravedad 3+, bloquear hasta que exista `retrospective.md` |

---

## 6. Sistema de Memoria Persistente

### user-insights.yaml (8 insights iniciales)
**Alta influencia** (se aplican automáticamente):
- `tdd-produces-better-code` — TDD primero
- `plan-before-complex-changes` — Planificar para gravedad 2+
- `validate-at-boundaries` — Validación de input en bordes de API

**Media influencia** (considerar):
- `solid-in-design-phase` — SOLID durante diseño, no después
- `small-focused-functions` — <20 líneas, responsabilidad única
- `no-premature-abstraction` — Esperar 3+ repeticiones antes de extraer
- `atomic-commits` — Un commit por cambio lógico

**Baja influencia**:
- `explain-why-not-what` — Comentarios explican intención, no código

### learnings.yaml (vacío, capturado post-feature)
- Tipos: pattern, anti-pattern, boundary
- Documenta el "Problema del 70%" — donde la complejidad excedió expectativas

### patterns.yaml (vacío, código de features exitosas)
- Nombre, descripción, archivo ejemplo, conteo de uso

### discovered-insights.yaml (vacío, insights propuestos por IA)
- Ciclo de vida: proposed → accepted → promoted a user-insights.yaml
- Requiere confidence ≥ 0.7 para promoción

---

## 7. Skills Invocables

| Skill | Función |
|-------|---------|
| `compound-capture` | Extraer learnings, patterns, discovered insights post-feature |
| `insights-manager` | Añadir, revisar, aceptar/rechazar, promover insights |
| `discover` | Bootstrap de memoria (`--seed`, `--profile`, `--status`) |
| `solid-analyzer` | Análisis SOLID (`baseline`, `design`, `verify`) |

---

## 8. Plantillas de Artefactos

- **spec.md**: Problem Statement, Scope (In/Out), Acceptance Criteria, Edge Cases, Dependencies
- **design.md**: Architecture Overview, Key Decisions, Component Design, SOLID Analysis, Data Flow
- **tasks.md**: Checkbox items con descripción, archivos afectados, complejidad
- **retrospective.md**: What Went Well, What Could Improve, Surprises, Patterns, Learnings

---

## 9. Estado del Proyecto

### Completado (P0 + P1-1, P1-4)
- Slimmed CLAUDE.md como router
- Migración openspec/ → memory/current-task/
- Creación hooks.json + 5 shell scripts
- Promoción de 3 insights a alta influencia
- Implementación de hook SessionStart

### Pendiente
- **P1-3**: Migrar workers a skills con formato SKILL.md y frontmatter
- **P1-2**: Automatizar compound-capture vía hook Stop (escribir meta.yaml al inicio del flow)
- **P2-1**: Tiering de memoria (Level 1: always, Level 2: per-flow, Level 3: on-demand)
- **P2-2**: Integrar TodoWrite para tracking de progreso del implementer
- **P2-3**: Triggers mejorados de guías en pre-write-guard.sh
- **P2-4**: Detectar e integrar con Claude Code plan mode

---

## 10. Decisiones de Arquitectura Clave

| Decisión | Razón |
|----------|-------|
| Workers con contexto fork | Prevenir bloat de historial de conversación |
| hooks.json | Ejecución determinística; no depender de memoria del agente |
| memory/current-task/ | Plugin autocontenido; no contamina root del proyecto |
| Tablas SOLID | Fuerzan documentar decisiones de diseño explícitamente |
| BCP de 3 intentos | Autonomía del implementer; escala a usuario en problemas difíciles |
| Influence high/medium/low | Heurísticas graduadas más realistas que reglas binarias |
| Gravedad 1-4 | Costo del proceso escala con costo de la tarea |

---

## 11. Historial Git

```
96165c6 fix: address PR review comments on hook enforcement vulnerabilities
66fc8ef docs: update TASKLIST.md with completed P0 and P1 tasks
9dd06fe feat: implement 5 critical workflow improvements (P0-3, P0-2, P0-1, P1-4, P1-1)
69040a9 docs: add improvement plan and tasklist for adaptive-flow v2.0
a5160ff feat: initial release — adaptive-flow plugin for Claude Code
```
