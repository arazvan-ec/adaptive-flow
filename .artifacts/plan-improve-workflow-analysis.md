# Plan: Improve Workflow Analysis

**Branch:** `claude/improve-workflow-analysis-yzaLn`
**Gravedad:** 3 (>8 archivos, multi-capa)
**Estado:** COMPLETADO

---

## P0 — Fixes criticos (lo que esta roto)

1. **Crear `.claude/settings.json` con hooks reales de la API de Claude Code**
   - Registrar eventos: PreToolUse, PostToolUse, Stop
   - Estado: DONE

2. **Reemplazar 4 hooks rotos por 3 nuevos funcionales**
   - Eliminar: pre-commit.sh, pre-work.sh, post-plan.sh, post-review.sh (nunca registrados, referenciaban dirs inexistentes)
   - Crear: pre-commit-guard.sh, post-artifact-check.sh, on-stop.sh
   - Estado: DONE

3. **Reemplazar referencias a `openspec/changes/{slug}/` por `.artifacts/`**
   - El directorio openspec nunca existio, rompiendo todos los quality gates
   - Estado: DONE

4. **Simplificar CLAUDE.md de ~80 a ~35 lineas**
   - Mantener solo: routing table, memory pointers, skills list, principios
   - Mover Getting Started, Workers table, estructura a README.md
   - Estado: DONE

5. **Agregar creacion de `.artifacts/meta.yaml` en flows**
   - Para tracking de tareas
   - Estado: DONE

## P1 — Mejoras importantes

6. **Agregar instrucciones mecanicas de invocacion de workers en todos los flows**
   - Bloques ACCION REQUERIDA con params exactos de subagent
   - Estado: DONE

7. **Agregar Stop hook (on-stop.sh)**
   - Enforcar compound-capture para gravedad 3+
   - Estado: DONE

8. **Mover contenido informativo a README.md**
   - Getting Started, tabla de Workers, estructura del proyecto
   - Estado: DONE

## P2 — Mejor aprovechamiento de Claude Code

9. **Promover 3 insights a high influence**
   - tdd-produces-better-code, validate-at-boundaries, plan-before-complex-changes
   - Estado: DONE

10. **Agregar carga explicita de guias core/ en flows y workers**
    - full-cycle: cargar guias relevantes
    - implementer: siempre cargar testing-guide
    - reviewer: siempre cargar solid-reference + security-guide
    - Estado: DONE

11. **Agregar integracion TodoWrite en implementer**
    - Para progreso en tiempo real
    - Estado: DONE

12. **Agregar nota de Plan Mode nativo en plan-execute flow**
    - Como alternativa nativa de Claude Code
    - Estado: DONE

---

## Analisis: Por que este plan tiene 3 fases (P0/P1/P2)?

Este plan deberia haber sido **maximo 2 fases**, no 3. Razones del exceso:

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

### Leccion para capturar
Para futuras iteraciones: **maximo 2 fases por plan**. Si hay una P2, es un
plan separado o se fusiona con P1 si el scope es pequeno.
