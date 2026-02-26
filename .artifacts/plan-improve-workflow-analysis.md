# Plan: Improve Workflow Analysis

**Branch:** `claude/improve-workflow-analysis-yzaLn`
**Gravedad:** 3 (>8 archivos, multi-capa)
**Estado:** EN PROGRESO

---

## Contexto

Analisis completo del framework adaptive-flow para identificar mejoras,
aprovechamiento de Claude Code features, y cuestionamiento de cada componente.

## Analisis del framework (Exploration Report)

### Overview

Adaptive Flow es un framework de ingenieria compuesta para Claude Code que adapta
el proceso de desarrollo a la complejidad de la tarea. En vez de un enfoque unico,
rutea el trabajo a traves de 4 niveles de gravedad, cada uno con su propio workflow.

Filosofia clave: "El peso del proceso debe coincidir con la complejidad de la tarea"

### Estructura completa analizada

| Tipo | Cantidad | Archivos | Proposito |
|------|----------|----------|-----------|
| Entry | 1 | CLAUDE.md | Routing logic, principios, mapa |
| Flows | 4 | direct, plan-execute, full-cycle, shape-first | Procesos por gravedad |
| Workers | 4 | planner, implementer, reviewer, researcher | Subagentes fresh-context |
| Skills | 4 | insights-manager, solid-analyzer, compound-capture, discover | Tools invocables |
| Hooks | 4 | pre-commit, pre-work, post-plan, post-review | Quality gates |
| Memory | 4 | user-insights, learnings, discovered-insights, patterns | Capa de persistencia |
| Templates | 4 | spec, design, tasks, retrospective | Scaffolds de artefactos |
| Core | 4 | solid-reference, security-guide, api-patterns, testing-guide | Docs de referencia |
| Config | 1 | .claude-plugin/plugin.json | Registro de plugin |
| Docs | 1 | README.md | Quick start |
| **TOTAL** | **31** | | |

### Problemas criticos encontrados

1. **Hooks nunca registrados**: Los 4 bash scripts en hooks/ no estan en ningun
   hooks.json ni .claude/settings.json. Las "quality gates deterministicas" son
   completamente falsas — nunca se ejecutan.

2. **Directorio inexistente**: Todas las referencias a `openspec/changes/{slug}/`
   apuntan a un directorio que nunca se creo. Rompe todos los quality gates.

3. **CLAUDE.md sobrecargado**: ~80 lineas con informacion que deberia estar en
   README.md (Getting Started, tabla de workers, estructura).

4. **Workers sin instrucciones mecanicas**: Los flows dicen "invocar worker" pero
   no especifican exactamente como (que tool, que params, que contexto pasar).

5. **Insights suboptimos**: Insights clave como TDD y validate-at-boundaries estaban
   en `medium` influence cuando deberian ser `high`.

6. **Sin tracking de gravedad**: No hay mecanismo para saber que gravedad tiene la
   tarea actual ni si se completo el compound-capture.

---

## Plan de mejoras

### P0 — Fixes criticos (lo que esta roto)

1. **Crear `.claude/settings.json` con hooks reales de la API de Claude Code**
   - Registrar eventos: PreToolUse, PostToolUse, Stop
   - Los hooks de Claude Code se registran en `.claude/settings.json`, no en un
     `hooks.json` separado

2. **Reemplazar 4 hooks rotos por 3 nuevos funcionales**
   - Eliminar: pre-commit.sh, pre-work.sh, post-plan.sh, post-review.sh
     (nunca fueron registrados, referenciaban dirs inexistentes)
   - Crear:
     - `pre-commit-guard.sh` — PreToolUse(Bash): bloquea commits con archivos sensibles
     - `post-artifact-check.sh` — PostToolUse(Write|Edit): valida spec.md y design.md
     - `on-stop.sh` — Stop: recuerda ejecutar compound-capture en gravedad 3+

3. **Reemplazar todas las referencias a `openspec/changes/{slug}/` por `.artifacts/`**
   - El directorio openspec nunca existio, rompiendo todos los quality gates
   - `.artifacts/` es mas simple y directo

4. **Simplificar CLAUDE.md de ~80 a ~35 lineas**
   - Mantener solo: routing table, memory pointers, skills list, principios
   - Mover Getting Started, Workers table, estructura del proyecto a README.md

5. **Agregar creacion de `.artifacts/meta.yaml` en todos los flows**
   - Contiene: slug, gravity, started date
   - Permite a los hooks saber la gravedad de la tarea actual

### P1 — Mejoras importantes

6. **Agregar instrucciones mecanicas de invocacion de workers en todos los flows**
   - Bloques `ACCION REQUERIDA` con parametros exactos:
     - Que tool usar (Task tool)
     - Que subagent_type
     - Que contexto pasar (archivos exactos)
     - Que output esperar
   - Elimina ambiguedad de "invocar worker"

7. **Agregar Stop hook (on-stop.sh)**
   - Verifica si hay un `.artifacts/meta.yaml` con gravedad 3+
   - Verifica si existe `.artifacts/retrospective.md` (indica que compound-capture corrio)
   - Si no existe, recuerda al usuario ejecutar `/adaptive-flow:compound-capture`

8. **Mover contenido informativo a README.md**
   - Getting Started guide
   - Tabla de Workers con descripcion
   - Estructura del proyecto
   - CLAUDE.md queda lean: solo routing + pointers

### P2 — Mejor aprovechamiento de Claude Code

9. **Promover 3 insights a high influence**
   - `tdd-produces-better-code`: medium → high (es el core del implementer)
   - `validate-at-boundaries`: medium → high (es critico para seguridad)
   - `plan-before-complex-changes`: medium → high (es la base del routing)

10. **Agregar carga explicita de guias core/ en flows y workers**
    - full-cycle flow: triggers de carga condicional (API, security, testing)
    - implementer: SIEMPRE cargar `core/testing-guide.md`
    - reviewer: SIEMPRE cargar `core/solid-reference.md` + `core/security-guide.md`

11. **Agregar integracion TodoWrite en implementer**
    - Al iniciar implementacion, crear lista de tareas desde tasks.md
    - Marcar cada task como in_progress/completed en tiempo real
    - Da visibilidad al usuario del progreso

12. **Agregar nota de Plan Mode nativo en plan-execute flow**
    - Para gravedad 2 con scope muy claro, sugerir Plan Mode nativo de Claude Code
    - Reduce un nivel de indirreccion y ahorra tokens

---

## Analisis: Por que este plan tiene 3 fases (P0/P1/P2)?

Este plan deberia haber sido **maximo 2 fases**, no 3. Razones:

### El problema
Se mezclaron **fixes de bugs** con **mejoras de calidad** y **optimizaciones nice-to-have**
en un solo plan. Esto viola el principio del framework:
> "Gravedad proporcional: El proceso pesa lo mismo que la tarea"

### Que debio ser
- **Fase 1 (P0):** Fix de hooks rotos + referencias inexistentes (items 1-5)
  → Esto es lo que realmente estaba roto y bloqueaba el uso del framework
- **Fase 2 (P1+P2 fusionados):** Mejoras de workflow (items 6-12)
  → Todo lo demas son mejoras incrementales, no fixes criticos

### Por que ocurrio
1. **Scope creep disfrazado de priorizacion:** Usar P0/P1/P2 da la ilusion de
   control, pero en realidad se estan metiendo 3 alcances distintos en un solo
   cambio. Un commit con 19 archivos tocados es senal de que se debio partir.
2. **Falta de corte:** P2 completo (insights, carga de guias, TodoWrite, Plan Mode)
   podria haber sido un commit separado sin riesgo.
3. **No se aplico el propio framework:** Una gravedad 3 con full-cycle deberia
   haber tenido review intermedio antes de fusionar P1 y P2.

### Leccion
Para futuras iteraciones: **maximo 2 fases por plan**. Si hay una P2, es un
plan separado o se fusiona con P1 si el scope es pequeno.
