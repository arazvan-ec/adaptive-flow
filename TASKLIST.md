# Adaptive Flow v2.0 - Tasklist

> Estado: `IN_PROGRESS` | Ultima actualizacion: 2026-02-26
>
> Leyenda: `[ ]` Pendiente | `[~]` En progreso | `[x]` Completada | `[!]` Bloqueada

---

## P0: Critico (El framework no funciona sin esto)

### P0-3: Adelgazar CLAUDE.md
> **Paralelizable:** No (debe hacerse primero, otros tasks dependen de esto)
> **En vivo:** Si (commit 9dd06fe)

- [x] Leer CLAUDE.md actual y catalogar cada seccion
- [x] Mover contenido de Getting Started a README.md
- [x] Mover tabla de workers (ya documentada en workers/ y flows/)
- [x] Mover seccion de hooks (seran auto-registrados via hooks.json)
- [x] Mover lista de skills (ya en plugin.json)
- [x] Mover seccion de compound (ya en skills/compound-capture.md)
- [x] Mover seccion de estructura (ya en README.md)
- [x] Reescribir CLAUDE.md con solo: routing table + memory pointers + principios (~35 lineas)
- [x] Verificar que no se perdio informacion critica

### P0-2: Corregir convencion openspec/changes/{slug}/
> **Paralelizable:** No (depende de P0-3)
> **En vivo:** Si (commit 9dd06fe)

- [x] Crear directorio `memory/current-task/`
- [x] Modificar `flows/direct.md` - no tenia referencias (skip)
- [x] Modificar `flows/plan-execute.md` - cambiar openspec/ → memory/current-task/
- [x] Modificar `flows/full-cycle.md` - cambiar openspec/ → memory/current-task/
- [x] Modificar `flows/shape-first.md` - cambiar openspec/ → memory/current-task/
- [x] Modificar `workers/planner.md` - actualizar referencias de paths
- [x] Modificar `skills/compound-capture.md` - actualizar todas las referencias
- [x] Verificar que no quedan referencias a openspec/ en ningun archivo

### P0-1: Crear Plugin Hooks via hooks/hooks.json
> **Paralelizable:** No (depende de P0-2 para conocer paths de artefactos)
> **En vivo:** Si (commit 9dd06fe)

- [x] Crear `hooks/hooks.json` con registro de todos los hooks
- [x] Crear `hooks/session-init.sh` (SessionStart: startup/resume)
- [x] Crear `hooks/post-compact.sh` (SessionStart: compact)
- [x] Crear `hooks/pre-write-guard.sh` (PreToolUse: Write|Edit)
- [x] Crear `hooks/post-write-check.sh` (PostToolUse: Write|Edit)
- [x] Crear `hooks/stop-check.sh` (Stop)
- [x] Hacer todos los scripts ejecutables (chmod +x)
- [x] Eliminar `hooks/pre-commit.sh` (reemplazado)
- [x] Eliminar `hooks/post-plan.sh` (reemplazado)
- [x] Eliminar `hooks/pre-work.sh` (reemplazado)
- [x] Eliminar `hooks/post-review.sh` (reemplazado)
- [x] Verificar que hooks.json es JSON valido

---

## P1: Importante (Gaps mayores de funcionalidad)

### P1-4: Promover Insights Criticos a Influencia Alta
> **Paralelizable:** Si (independiente de P0)
> **En vivo:** Si (commit 9dd06fe)

- [x] Modificar `memory/user-insights.yaml`: `tdd-produces-better-code` → influence: high
- [x] Modificar `memory/user-insights.yaml`: `plan-before-complex-changes` → influence: high
- [x] Modificar `memory/user-insights.yaml`: `validate-at-boundaries` → influence: high
- [x] Verificar que el formato YAML sigue siendo valido

### P1-1: Hook SessionStart para Inicializacion de Memoria
> **Paralelizable:** No (cubierto por P0-1)
> **En vivo:** Si (commit 9dd06fe)

- [x] (Cubierto por P0-1: session-init.sh ya implementa esta funcionalidad)
- [x] Verificar que el hook retorna JSON valido con additionalContext
- [x] Verificar que parsea correctamente user-insights.yaml
- [x] Verificar que maneja archivos inexistentes gracefully

### P1-3: Convertir Workers en Skills con SKILL.md
> **Paralelizable:** No (depende de P0-2 para paths correctos)
> **En vivo:** No

- [ ] Crear directorio `skills/planner/`
- [ ] Crear `skills/planner/SKILL.md` con frontmatter (context: fork, allowed-tools)
- [ ] Crear directorio `skills/implementer/`
- [ ] Crear `skills/implementer/SKILL.md` con frontmatter
- [ ] Crear directorio `skills/reviewer/`
- [ ] Crear `skills/reviewer/SKILL.md` con frontmatter
- [ ] Crear directorio `skills/researcher/`
- [ ] Crear `skills/researcher/SKILL.md` con frontmatter
- [ ] Migrar `skills/compound-capture.md` → `skills/compound-capture/SKILL.md`
- [ ] Migrar `skills/insights-manager.md` → `skills/insights-manager/SKILL.md`
- [ ] Migrar `skills/discover.md` → `skills/discover/SKILL.md`
- [ ] Migrar `skills/solid-analyzer.md` → `skills/solid-analyzer/SKILL.md`
- [ ] Eliminar archivos originales de skills/ (4 archivos .md)
- [ ] Eliminar archivos originales de workers/ (4 archivos .md)
- [ ] Eliminar directorio `workers/`
- [ ] Actualizar `.claude-plugin/plugin.json` - eliminar skills array, bumpar a v2.0.0
- [ ] Actualizar `flows/plan-execute.md` - referenciar workers como skill invocations
- [ ] Actualizar `flows/full-cycle.md` - referenciar workers como skill invocations
- [ ] Actualizar `flows/shape-first.md` - referenciar workers como skill invocations
- [ ] Verificar que todos los skills son descubribles

### P1-2: Automatizar Compound Capture
> **Paralelizable:** No (depende de P1-3 y P0-1 para stop hook)
> **En vivo:** No

- [ ] Definir schema de `memory/current-task/meta.yaml`
- [ ] Actualizar `flows/plan-execute.md` para escribir meta.yaml al inicio
- [ ] Actualizar `flows/full-cycle.md` para escribir meta.yaml al inicio
- [ ] Actualizar `flows/shape-first.md` para escribir meta.yaml al inicio
- [ ] Verificar que `stop-check.sh` lee meta.yaml correctamente
- [ ] Verificar que bloquea cuando gravity >= 3 y no hay retrospective.md
- [ ] Verificar que no bloquea cuando gravity < 3

---

## P2: Mejoras (Mejor aprovechamiento de Claude Code)

### P2-1: Carga de Memoria por Niveles
> **Paralelizable:** Si (independiente de otras P2)
> **En vivo:** No

- [ ] Definir que va en cada nivel (1: siempre, 2: al activar flow, 3: bajo demanda)
- [ ] Actualizar `hooks/session-init.sh` para cargar solo Nivel 1
- [ ] Actualizar `flows/plan-execute.md` con instrucciones de carga Nivel 2
- [ ] Actualizar `flows/full-cycle.md` con instrucciones de carga Nivel 2
- [ ] Actualizar `flows/shape-first.md` con instrucciones de carga Nivel 2
- [ ] Actualizar `hooks/pre-write-guard.sh` para manejar carga Nivel 3

### P2-2: Integrar con TodoWrite de Claude Code
> **Paralelizable:** Si (independiente de otras P2)
> **En vivo:** No

- [ ] Actualizar `skills/implementer/SKILL.md` con instrucciones de TodoWrite
- [ ] Documentar como el implementer debe crear TodoWrite desde tasks.md
- [ ] Documentar como marcar progreso en tiempo real

### P2-3: Triggers de Carga de Guias Core via PreToolUse
> **Paralelizable:** Si (independiente de otras P2)
> **En vivo:** No

- [ ] Agregar deteccion de archivos auth/security en `pre-write-guard.sh`
- [ ] Agregar deteccion de archivos controller/route/api en `pre-write-guard.sh`
- [ ] Agregar deteccion de archivos .test./.spec. en `pre-write-guard.sh`
- [ ] Verificar que las sugerencias se inyectan como additionalContext

### P2-4: Integrar con Plan Mode de Claude Code
> **Paralelizable:** Si (independiente de otras P2)
> **En vivo:** No

- [ ] Agregar nota en `flows/plan-execute.md` sobre integracion con plan mode
- [ ] Actualizar `hooks/session-init.sh` para detectar permission_mode
- [ ] Documentar cuando el planner worker no es necesario (plan mode activo + gravity 2)

---

## Grafo de Dependencias

```
P0-3 (CLAUDE.md slim)
  └──→ P0-2 (Fix openspec/)
        └──→ P0-1 (hooks/hooks.json)
              ├──→ P1-1 (SessionStart - cubierto)
              └──→ P1-2 (Compound automation)

P1-4 (Promover insights) ← independiente, puede ir en paralelo con P0

P0-2 ──→ P1-3 (Workers → Skills)
           └──→ P1-2 (Compound automation)

P1-3 ──→ P2-1 (Memory tiers)
P0-1 ──→ P2-3 (Guide triggers)
P1-3 ──→ P2-2 (TodoWrite)
P0-2 ──→ P2-4 (Plan mode)
```

---

## Resumen de Estado

| Tarea | Prioridad | Estado | Dependencias | Paralelizable |
|-------|-----------|--------|--------------|---------------|
| P0-3: Adelgazar CLAUDE.md | Critico | `[x] En vivo` | Ninguna | No (primera) |
| P0-2: Fix openspec/ | Critico | `[x] En vivo` | P0-3 | No |
| P0-1: hooks/hooks.json | Critico | `[x] En vivo` | P0-2 | No |
| P1-4: Promover insights | Importante | `[x] En vivo` | Ninguna | **Si** |
| P1-1: SessionStart hook | Importante | `[x] En vivo` | P0-1 | No (cubierto) |
| P1-3: Workers → Skills | Importante | `[ ] Pendiente` | P0-2 | No |
| P1-2: Compound automation | Importante | `[ ] Pendiente` | P1-3, P0-1 | No |
| P2-1: Memory tiers | Mejora | `[ ] Pendiente` | P1-3 | **Si** |
| P2-2: TodoWrite | Mejora | `[ ] Pendiente` | P1-3 | **Si** |
| P2-3: Guide triggers | Mejora | `[x] En vivo` | P0-1 | **Si** |
| P2-4: Plan mode | Mejora | `[ ] Pendiente` | P0-2 | **Si** |

**Total tareas atomicas:** 74
**Completadas:** 37 / 74 (50%)
