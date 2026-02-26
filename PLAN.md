# Adaptive Flow - Plan de Mejoras v2.0

## Resumen Ejecutivo

El framework adaptive-flow tiene una arquitectura conceptual bien disenada pero sufre de un **gap de implementacion fundamental**: los mecanismos que dice usar (Claude Code hooks API, invocacion automatica de workers, quality gates deterministicos) **no estan conectados**. Los scripts bash en `hooks/` nunca se registran. Los workers son templates de prompt sin trigger mecanico. El directorio `openspec/changes/` se referencia en todos lados pero nunca se crea.

Este plan corrige estos problemas en orden de prioridad.

---

## P0: Critico -- El Framework No Funciona Sin Esto

### P0-1: Crear Plugin Hooks via `hooks/hooks.json`

**Problema:** El framework dice que los hooks "se ejecutan automaticamente via Claude Code hooks API" pero no existe `hooks/hooks.json` en el plugin. Los cuatro scripts bash en `hooks/` son archivos sueltos que nada invoca. La promesa de "quality gates deterministicos" es falsa.

**Solucion:** Crear `/home/user/adaptive-flow/hooks/hooks.json` usando el formato de plugin hooks de Claude Code.

**Hooks a registrar:**
- `SessionStart` (startup/resume) → `session-init.sh` - Carga memoria al contexto
- `SessionStart` (compact) → `post-compact.sh` - Re-inyecta contexto tras compactacion
- `PreToolUse` (Write|Edit) → `pre-write-guard.sh` - Validacion de archivos sensibles + triggers de guias
- `PostToolUse` (Write|Edit) → `post-write-check.sh` - Validacion de artefactos
- `Stop` → `stop-check.sh` - Enforcement de compound-capture

**Scripts nuevos a crear:**
| Script | Funcion |
|--------|---------|
| `session-init.sh` | Lee `user-insights.yaml` (high influence), `architecture-profile.yaml`, `learnings.yaml`. Retorna JSON con `additionalContext`. |
| `post-compact.sh` | Re-inyecta routing table + insights activos tras compactacion de contexto. |
| `pre-write-guard.sh` | Detecta archivos sensibles (.env, credentials). Inyecta recordatorios de guias core/ segun tipo de archivo. |
| `post-write-check.sh` | Valida estructura de spec/design/tasks cuando se escriben. Reemplaza logica de `post-plan.sh`. |
| `stop-check.sh` | Verifica si compound-capture se ejecuto para tareas gravity 3+. Bloquea si no. Chequea `stop_hook_active` para evitar loops infinitos. |

**Scripts a eliminar:** `pre-commit.sh`, `post-plan.sh`, `pre-work.sh`, `post-review.sh` (no estan registrados, referencian `openspec/` que no existe).

---

### P0-2: Corregir la Convencion `openspec/changes/{slug}/`

**Problema:** Los 4 flows referencian `openspec/changes/{slug}/`. Los 4 hook scripts verifican archivos ahi. Pero este directorio nunca existe, nada lo crea, y `pre-work.sh` BLOQUEA (exit 1) si no existe.

**Solucion (Recomendada - Opcion A):** Reemplazar `openspec/changes/{slug}/` por `memory/current-task/` dentro del directorio del plugin.

**Archivos a modificar:**
- `flows/direct.md` → Eliminar referencias a `openspec/`
- `flows/plan-execute.md` → Cambiar a `memory/current-task/plan-and-tasks.md`
- `flows/full-cycle.md` → Cambiar a `memory/current-task/` para spec.md, design.md, tasks.md, retrospective.md
- `flows/shape-first.md` → Mismo cambio para shaped-brief.md + artefactos heredados
- `workers/planner.md` → Actualizar referencias de paths
- `skills/compound-capture.md` → Actualizar todas las referencias

**Beneficio:** El plugin se mantiene autocontenido sin contaminar el proyecto host.

---

### P0-3: Adelgazar `CLAUDE.md`

**Problema:** CLAUDE.md tiene 84 lineas cargadas en cada ventana de contexto. Mucha de esta informacion es documentacion de referencia que deberia estar en archivos separados.

**Solucion:** Reducir a ~35 lineas manteniendo solo:
- Tabla de routing (clasificacion de gravedad) - esencial para cada request
- Instruccion de consultar archivos de memoria - punteros breves
- Principios - lista compacta

**Contenido a mover fuera:**
- Tabla de workers → ya documentada en cada worker y cada flow
- Seccion de hooks → ahora auto-registrados
- Lista de skills → ya en plugin.json, descubrible via /help
- Seccion de compound → ya en skills/compound-capture.md
- Getting Started → mover a README.md
- Seccion de estructura → ya en README.md

---

## P1: Importante -- Gaps Mayores de Funcionalidad

### P1-1: Hook SessionStart para Inicializacion de Memoria

**Problema:** Cada sesion arranca fria. Claude debe leer CLAUDE.md, luego el flow, luego los archivos de memoria. Esta cadena es probabilistica.

**Solucion:** Cubierto en P0-1 con `session-init.sh`. El hook retorna JSON con `additionalContext` que inyecta automaticamente insights, learnings y perfil de arquitectura al contexto de Claude.

---

### P1-2: Automatizar Compound Capture

**Problema:** El skill compound-capture dice ejecutarse "automaticamente despues de gravedad 3+" pero nada lo dispara.

**Solucion:** Usar el hook Stop (`stop-check.sh` de P0-1) para detectar tareas gravity 3+ completadas y bloquear hasta que se ejecute compound-capture.

**Archivo nuevo:** `memory/current-task/meta.yaml` - escrito por el flow al inicio de cada tarea:
```yaml
slug: feature-name
gravity: 3
started: 2026-02-26
status: in-progress
```

Los flows deben actualizarse para escribir este archivo meta al inicio de cada tarea.

---

### P1-3: Convertir Workers en Skills con Frontmatter

**Problema:** Workers describen `context: fork` pero no hay trigger mecanico. El agente principal debe leer el flow, luego decidir crear un Task subagent. Esta cadena es probabilistica.

**Solucion:** Convertir workers en skills con frontmatter de Claude Code.

**Reestructuracion:**
```
# Antes:
workers/planner.md
workers/implementer.md
workers/reviewer.md
workers/researcher.md

# Despues:
skills/planner/SKILL.md        (context: fork, allowed-tools: Read, Grep, Glob, Write)
skills/implementer/SKILL.md    (context: fork, allowed-tools: Read, Grep, Glob, Write, Edit, Bash)
skills/reviewer/SKILL.md       (context: fork, allowed-tools: Read, Grep, Glob)
skills/researcher/SKILL.md     (context: fork, allowed-tools: Read, Grep, Glob)
```

**Skills existentes tambien migran a formato directorio:**
```
skills/compound-capture.md     → skills/compound-capture/SKILL.md
skills/insights-manager.md     → skills/insights-manager/SKILL.md
skills/discover.md             → skills/discover/SKILL.md
skills/solid-analyzer.md       → skills/solid-analyzer/SKILL.md
```

**Actualizar `plugin.json`:** Eliminar array de skills, bumpar a v2.0.0, confiar en auto-discovery.

---

### P1-4: Promover Insights Criticos a Influencia Alta

**Problema:** Los 8 starter insights tienen `influence: medium`. Ninguno es `high` (aplicado proactivamente).

**Solucion:** Promover a `influence: high`:
- `tdd-produces-better-code` - TDD es comportamiento core del implementer
- `plan-before-complex-changes` - Es literalmente lo que hace el framework (gravity 2+ = planificar)
- `validate-at-boundaries` - Critico para seguridad

---

## P2: Mejoras -- Mejor Aprovechamiento de Claude Code

### P2-1: Carga de Memoria por Niveles

**Problema:** El framework carga todos los archivos de memoria para cada decision. Desperdicia tokens de contexto.

**Solucion:** Estrategia de carga por niveles:
- **Nivel 1** (Siempre - via SessionStart): Insights high-influence, perfil de arquitectura, meta de tarea actual
- **Nivel 2** (Al activar flow): Learnings relevantes, insights medium filtrados por fase
- **Nivel 3** (Bajo demanda): Guias core/, detalles completos de patrones, discovered insights

---

### P2-2: Integrar con TodoWrite de Claude Code

**Problema:** El framework tiene su propio tracking de tareas (tasks.md) pero no usa el TodoWrite built-in que da visibilidad en tiempo real al usuario.

**Solucion:** Actualizar el skill implementer para usar TodoWrite junto con tasks.md. Crear TodoWrite list desde tasks.md al iniciar implementacion, marcar progreso en tiempo real.

---

### P2-3: Triggers de Carga de Guias Core via PreToolUse

**Problema:** Las guias `core/` dicen cargarse "bajo demanda" pero no hay mecanismo que las dispare.

**Solucion:** Mejorar `pre-write-guard.sh` para detectar contexto y sugerir guias:
- Archivos auth/security/login → sugerir `core/security-guide.md`
- Archivos controller/route/api → sugerir `core/api-patterns.md`
- Archivos .test./.spec. → sugerir `core/testing-guide.md`

---

### P2-4: Integrar con Plan Mode de Claude Code

**Problema:** Claude Code tiene plan mode built-in, pero el framework reinventa planning via planner worker. Pueden conflictuar.

**Solucion:** Actualizar flows para reconocer plan mode:
- Si Claude esta en plan mode, el planner worker no es necesario para gravity 2
- Producir plan-and-tasks.md directamente
- El planner worker sigue siendo valioso en gravity 3-4 (contexto fresco)

---

## Secuencia de Implementacion

```
P0-3 (CLAUDE.md slim)
  ↓
P0-2 (Fix openspec/ → memory/current-task/)
  ↓
P0-1 (hooks/hooks.json + nuevos scripts)
  ↓                          ↓ (paralelo)
P1-4 (Promover insights)   P1-1 (SessionStart - cubierto en P0-1)
  ↓
P1-3 (Workers → Skills con SKILL.md)
  ↓
P1-2 (Compound capture automation via Stop hook)
  ↓
P2-1 (Memory tiers) ║ P2-3 (Guide triggers) ║ P2-2 (TodoWrite) ║ P2-4 (Plan mode)
```

---

## Resumen de Cambios en Archivos

### Archivos Nuevos (14)
| Archivo | Proposito |
|---------|-----------|
| `hooks/hooks.json` | Registro de hooks con Claude Code hooks API |
| `hooks/session-init.sh` | SessionStart: carga memoria al contexto |
| `hooks/post-compact.sh` | SessionStart(compact): re-inyecta contexto core |
| `hooks/pre-write-guard.sh` | PreToolUse: checks de sensibilidad + triggers de guias |
| `hooks/post-write-check.sh` | PostToolUse: validacion de artefactos |
| `hooks/stop-check.sh` | Stop: enforcement de compound-capture |
| `skills/planner/SKILL.md` | Planner como skill con context:fork |
| `skills/implementer/SKILL.md` | Implementer como skill con context:fork |
| `skills/reviewer/SKILL.md` | Reviewer como skill con context:fork |
| `skills/researcher/SKILL.md` | Researcher como skill con context:fork |
| `skills/compound-capture/SKILL.md` | Compound capture reformateado como SKILL.md |
| `skills/insights-manager/SKILL.md` | Insights manager reformateado como SKILL.md |
| `skills/discover/SKILL.md` | Discover reformateado como SKILL.md |
| `skills/solid-analyzer/SKILL.md` | SOLID analyzer reformateado como SKILL.md |

### Archivos a Modificar (8)
| Archivo | Cambios |
|---------|---------|
| `CLAUDE.md` | Reducir de 84 a ~35 lineas |
| `.claude-plugin/plugin.json` | Eliminar skills array, bumpar a v2.0.0 |
| `flows/direct.md` | Eliminar referencias openspec/ |
| `flows/plan-execute.md` | openspec/ → memory/current-task/, nota plan mode |
| `flows/full-cycle.md` | openspec/ → memory/current-task/, workers como skills |
| `flows/shape-first.md` | openspec/ → memory/current-task/, workers como skills |
| `memory/user-insights.yaml` | Promover 3 insights a high influence |
| `README.md` | Actualizar seccion de estructura |

### Archivos a Eliminar (12)
| Archivo | Razon |
|---------|-------|
| `hooks/pre-commit.sh` | Reemplazado por hooks registrados |
| `hooks/post-plan.sh` | Reemplazado por post-write-check.sh |
| `hooks/pre-work.sh` | Reemplazado por Stop hook |
| `hooks/post-review.sh` | Reemplazado por post-write-check.sh |
| `workers/planner.md` | Migrado a skills/planner/SKILL.md |
| `workers/implementer.md` | Migrado a skills/implementer/SKILL.md |
| `workers/reviewer.md` | Migrado a skills/reviewer/SKILL.md |
| `workers/researcher.md` | Migrado a skills/researcher/SKILL.md |
| `skills/compound-capture.md` | Migrado a skills/compound-capture/SKILL.md |
| `skills/insights-manager.md` | Migrado a skills/insights-manager/SKILL.md |
| `skills/discover.md` | Migrado a skills/discover/SKILL.md |
| `skills/solid-analyzer.md` | Migrado a skills/solid-analyzer/SKILL.md |

### Directorios a Crear
- `skills/planner/`, `skills/implementer/`, `skills/reviewer/`, `skills/researcher/`
- `skills/compound-capture/`, `skills/insights-manager/`, `skills/discover/`, `skills/solid-analyzer/`
- `memory/current-task/`

### Directorios a Eliminar
- `workers/` (contenido migrado a skills/)

---

## Riesgos y Mitigaciones

| Riesgo | Mitigacion |
|--------|------------|
| Rendimiento de SessionStart hook (debe ser <2-3s) | Parsing YAML simplificado con grep/awk, no YAML completo |
| Loops infinitos en Stop hook | Chequear `stop_hook_active` como primera linea |
| Conflicto entre plugin hooks y project hooks | Ambos corren independientemente, propositos diferentes |
| Breaking change en plugin format (v1→v2) | Version bump a 2.0.0, documentar migracion |
| Parsing YAML en bash es fragil | Usar Python como fallback si esta disponible |
