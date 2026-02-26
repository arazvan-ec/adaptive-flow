# Tasklist: Improve Workflow Analysis

**Branch:** `claude/improve-workflow-analysis-yzaLn`
**Ultima actualizacion:** 2026-02-26

## Leyenda

- [x] DONE — Implementado y commiteado
- [ ] PENDING — Pendiente de implementar
- [~] PARCIAL — Implementado pero requiere revision

---

## P0 — Fixes criticos

- [x] **P0-1**: Crear `.claude/settings.json` con hooks reales (PreToolUse, PostToolUse, Stop)
  - Commit: 9973c35
  - Archivos: `.claude/settings.json`

- [x] **P0-2**: Reemplazar 4 hooks rotos por 3 nuevos funcionales
  - Commit: 9973c35
  - Eliminados: `hooks/pre-commit.sh`, `hooks/pre-work.sh`, `hooks/post-plan.sh`, `hooks/post-review.sh`
  - Creados: `hooks/pre-commit-guard.sh`, `hooks/post-artifact-check.sh`, `hooks/on-stop.sh`

- [x] **P0-3**: Reemplazar referencias `openspec/changes/{slug}/` → `.artifacts/`
  - Commit: 9973c35
  - Archivos: todos los flows, compound-capture skill

- [x] **P0-4**: Simplificar CLAUDE.md (~80 → ~35 lineas) + mover contenido a README.md
  - Commit: 9973c35
  - Archivos: `CLAUDE.md`, `README.md`

- [x] **P0-5**: Agregar `.artifacts/meta.yaml` en flows para tracking de gravedad
  - Commit: 9973c35
  - Archivos: `flows/direct.md`, `flows/plan-execute.md`, `flows/full-cycle.md`, `flows/shape-first.md`

## P1 — Mejoras importantes

- [x] **P1-1**: Agregar instrucciones mecanicas de invocacion de workers (ACCION REQUERIDA)
  - Commit: 9973c35
  - Archivos: `flows/plan-execute.md`, `flows/full-cycle.md`, `flows/shape-first.md`

- [x] **P1-2**: Agregar Stop hook para compound-capture en gravedad 3+
  - Commit: 9973c35
  - Archivos: `hooks/on-stop.sh`, `.claude/settings.json`

- [x] **P1-3**: Mover contenido informativo a README.md
  - Commit: 9973c35
  - Archivos: `CLAUDE.md`, `README.md`

## P2 — Mejor aprovechamiento de Claude Code

- [x] **P2-1**: Promover 3 insights a high influence
  - Commit: 9973c35
  - Archivos: `memory/user-insights.yaml`
  - Insights: tdd-produces-better-code, validate-at-boundaries, plan-before-complex-changes

- [x] **P2-2**: Agregar carga explicita de guias core/ en flows y workers
  - Commit: 9973c35
  - Archivos: `flows/full-cycle.md`, `workers/implementer.md`, `workers/reviewer.md`

- [x] **P2-3**: Agregar integracion TodoWrite en implementer
  - Commit: 9973c35
  - Archivos: `workers/implementer.md`

- [x] **P2-4**: Agregar nota de Plan Mode nativo en plan-execute
  - Commit: 9973c35
  - Archivos: `flows/plan-execute.md`

---

## Resumen

| Fase | Total | Done | Pending |
|------|-------|------|---------|
| P0   | 5     | 5    | 0       |
| P1   | 3     | 3    | 0       |
| P2   | 4     | 4    | 0       |
| **Total** | **12** | **12** | **0** |

## Nota

Todas las tareas fueron implementadas en un unico commit (9973c35). En retrospectiva,
debio haberse partido en al menos 2 commits: P0 (fixes) y P1+P2 (mejoras).
Ver analisis completo en `plan-improve-workflow-analysis.md`.

---

## Plan siguiente: Separacion Compound como Provider

**Plan:** `.artifacts/plan-compound-provider-separation.md`
**Estado:** PENDIENTE DE DECISION DEL USUARIO

### Opciones propuestas

| Opcion | Descripcion | Esfuerzo | Riesgo |
|--------|-------------|----------|--------|
| A | Plan completo: interface + mover archivos + refactorizar flows | 17 tareas, ~25 archivos | Alto |
| B | **Recomendada**: Solo documentar contrato (interface) + marcadores en flows | ~5 tareas, ~8 archivos | Bajo |
| C | Reorganizar directorios sin interface | ~10 tareas, ~20 archivos | Medio |
| D | No hacer nada | 0 tareas | Cero |

### Tareas (pendientes de decision)

**Si se elige A (plan completo):**

Fase 1: Interface y restructurar
- [ ] 1.1: Crear `providers/compound-interface.md`
- [ ] 1.2: Crear `providers/compound-local/provider.md`
- [ ] 1.3: Mover `skills/compound-capture.md` → provider
- [ ] 1.4: Mover `skills/insights-manager.md` → provider
- [ ] 1.5: Separar `skills/discover.md` (stack-detection vs insight-suggest)
- [ ] 1.6: Mover `memory/` → provider
- [ ] 1.7: Actualizar `.claude-plugin/plugin.json`
- [ ] 1.8: Actualizar `CLAUDE.md`

Fase 2: Desacoplar flows y workers
- [ ] 2.1: Refactor `flows/direct.md`
- [ ] 2.2: Refactor `flows/plan-execute.md`
- [ ] 2.3: Refactor `flows/full-cycle.md`
- [ ] 2.4: Refactor `flows/shape-first.md`
- [ ] 2.5: Refactor workers (planner, implementer, reviewer)
- [ ] 2.6: Refactor `hooks/on-stop.sh`

Fase 3: Documentacion
- [ ] 3.1: Actualizar `README.md`
- [ ] 3.2: Crear `providers/README.md`
- [ ] 3.3: Actualizar templates

**Si se elige B (recomendada):**
- [ ] B.1: Crear `providers/compound-interface.md` con contrato
- [ ] B.2: Agregar marcadores `## Compound Provider` en flows
- [ ] B.3: Agregar marcadores en workers
- [ ] B.4: Agregar nota en CLAUDE.md sobre arquitectura provider
- [ ] B.5: Actualizar README.md con seccion de providers
