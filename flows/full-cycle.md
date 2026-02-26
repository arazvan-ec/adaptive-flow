# Flow: Full Cycle (Gravedad 3)

Ciclo completo: plan → TDD → review → compound. Para tareas complejas o de alto riesgo.

## Cuando

- >8 archivos afectados
- Multi-capa (API + DB + UI)
- Seguridad, pagos, o infraestructura critica
- Cambios arquitecturales significativos

## Proceso

```
1. Cargar compound data (learnings + briefing anterior si existe)
2. Cargar insights (planning + design + implementation + review)

PLANNING
3. → Worker: planner (modo completo)
   Produce: spec.md, design.md, tasks.md
4. HITL: "Specs correctas?" → "Diseno correcto?"

IMPLEMENTATION
5. → Worker: implementer (TDD + BCP)
   Recibe: tasks.md + design.md + insights de implementation
   Produce: codigo + tests

REVIEW
6. → Worker: reviewer (multi-dimensional)
   Recibe: diff + spec.md + design.md + insights de review
   Produce: QA report (APPROVED/REJECTED)

7a. Si REJECTED → volver a paso 5 con feedback del reviewer
7b. Si APPROVED → continuar

COMPOUND
8. → Compound capture (skill)
   Extraer: patterns, learnings, discovered insights, briefing
9. Commit
```

## Artefactos

Directorio `openspec/changes/{slug}/`:

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

- spec.md tiene acceptance criteria (hook: post-plan)
- design.md tiene SOLID verdicts (hook: post-plan)
- tasks.md existe antes de work (hook: pre-work)
- Tests pasan (hook: pre-commit)
- Review criteria verificados con evidencia (hook: post-review)

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
