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
