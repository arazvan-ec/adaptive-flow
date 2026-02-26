# Flow: Full Cycle (Gravedad 3)

Ciclo completo: plan → TDD → review → compound. Para tareas complejas o de alto riesgo.

## Cuando

- >8 archivos afectados
- Multi-capa (API + DB + UI)
- Seguridad, pagos, o infraestructura critica
- Cambios arquitecturales significativos

## Proceso

```
0. Crear .artifacts/ y escribir .artifacts/meta.yaml:
   slug: {feature-slug}
   gravity: 3
   started: {fecha}

1. Cargar compound data (memory/learnings.yaml + memory/next-briefing.md si existe)
2. Cargar insights de memory/user-insights.yaml (planning + design + implementation + review)

PLANNING
3. ACCION REQUERIDA — Spawneear subagente (Task tool, subagent_type: Plan):
   - Instrucciones: contenido completo de workers/planner.md
   - Modo: completo
   - Contexto a pasar: este flow + insights filtrados + learnings + compound briefing
   - Output esperado: escribir .artifacts/spec.md + .artifacts/design.md + .artifacts/tasks.md
   - Retorno: resumen + paths de artifacts + SOLID warnings

4. HITL: "Specs correctas?" → "Diseno correcto?"

IMPLEMENTATION
5. ACCION REQUERIDA — Spawneear subagente (Task tool):
   - Instrucciones: contenido completo de workers/implementer.md
   - Contexto a pasar: .artifacts/tasks.md + .artifacts/design.md + insights de implementation + learnings
   - Cargar tambien: core/testing-guide.md (referencia TDD)
   - Output esperado: codigo + tests implementados
   - Retorno: resumen + tasks completadas + tests passing + BCP escalations

REVIEW
6. ACCION REQUERIDA — Spawneear subagente (Task tool):
   - Instrucciones: contenido completo de workers/reviewer.md
   - Contexto a pasar: git diff + .artifacts/spec.md + .artifacts/design.md + insights de review
   - Cargar tambien: core/solid-reference.md + core/security-guide.md
   - Output esperado: QA report con veredicto APPROVED/REJECTED
   - Retorno: veredicto + resumen + issues blocking/warning/suggestion

7a. Si REJECTED → volver a paso 5 con feedback del reviewer
7b. Si APPROVED → continuar

COMPOUND
8. Ejecutar /adaptive-flow:compound-capture
   Extraer: patterns, learnings, discovered insights, briefing
9. Commit
```

## Artefactos

Directorio `.artifacts/`:

```
spec.md          # QUE debe hacer el sistema (acceptance criteria)
design.md        # COMO implementarlo (decisiones SOLID)
tasks.md         # Lista de tareas ordenada
retrospective.md # Que fue bien, que mejorar (post-compound)
```

## Workers

| Worker | Modo | Contexto |
|--------|------|----------|
| planner | completo | Flow + insights (planning, design) + learnings + compound briefing |
| implementer | TDD+BCP | tasks.md + design.md + insights (implementation) + learnings |
| reviewer | multi-dim | diff + spec.md + design.md + insights (review) |

## Carga condicional de referencias (core/)

- Si la tarea involucra API endpoints → cargar `core/api-patterns.md`
- Si la tarea involucra auth, pagos, o datos sensibles → cargar `core/security-guide.md`
- El implementer SIEMPRE carga `core/testing-guide.md` (referencia TDD)
- El reviewer SIEMPRE carga `core/solid-reference.md` + `core/security-guide.md`

## SOLID Enforcement

En la fase de design, el planner DEBE:
1. Analizar el diseno contra principios SOLID
2. Documentar decisiones SOLID en design.md
3. Incluir SOLID verdicts por componente

Referencia: `core/solid-reference.md`

## BCP (Bounded Correction Protocol)

El implementer usa BCP cuando encuentra problemas durante la implementacion:
- Maximo 3 intentos de correccion automatica
- Si falla despues de 3 intentos → escalar al usuario con diagnostico
- Cada correccion se documenta en el commit

## HITL Checkpoints

1. Post-plan: confirmar spec + design antes de implementar
2. Post-review (si REJECTED): confirmar approach de correccion

## Quality Gates

- spec.md tiene acceptance criteria (hook: post-artifact-check valida al escribir)
- design.md tiene SOLID verdicts (hook: post-artifact-check valida al escribir)
- tasks.md existe antes de implementar
- Tests pasan antes de commit (hook: pre-commit-guard)
- Review criteria verificados con evidencia
- Compound capture ejecutado antes de finalizar (hook: on-stop verifica en gravedad 3+)

## Ejemplo

```
Usuario: "Anade autenticacion OAuth con Google y GitHub"
→ Gravedad 3 (>8 archivos, seguridad, multi-capa)
→ Planner: spec.md + design.md + tasks.md
→ HITL: confirmar specs y diseno
→ Implementer: TDD por task, BCP si hay problemas
→ Reviewer: QA multi-dimensional
→ Compound: extraer learnings para proxima feature
→ Commit
```
