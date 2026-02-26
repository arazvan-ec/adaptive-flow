# Flow: Plan-Execute (Gravedad 2)

Plan ligero seguido de ejecucion. Para tareas de scope claro que requieren planificar.

## Cuando

- 4-8 archivos afectados
- Requiere planificar el approach
- Scope claro, sin incertidumbre tecnica

## Proceso

```
0. Crear .artifacts/ y escribir .artifacts/meta.yaml:
   slug: {feature-slug}
   gravity: 2
   started: {fecha}

1. Cargar insights (planning + implementation) de memory/user-insights.yaml
2. Cargar memory/learnings.yaml (si existe)

PLANNING
3. ACCION REQUERIDA — Spawneear subagente (Task tool, subagent_type: Plan):
   - Instrucciones: contenido completo de workers/planner.md
   - Modo: ligero
   - Contexto a pasar: este flow + insights filtrados + learnings
   - Output esperado: escribir .artifacts/plan-and-tasks.md
   - Retorno: resumen de 3 lineas + path del artifact creado

4. HITL: "Este plan captura tu intencion?"

IMPLEMENTATION
5. ACCION REQUERIDA — Spawneear subagente (Task tool):
   - Instrucciones: contenido completo de workers/implementer.md
   - Contexto a pasar: .artifacts/plan-and-tasks.md + insights de implementation
   - Output esperado: codigo + tests implementados
   - Retorno: resumen + tasks completadas + tests passing

6. Verificar: tests + lint
7. Commit
```

## Artefactos

Un solo archivo combinado en `.artifacts/plan-and-tasks.md`:

```markdown
# {Feature Name}

## Plan
- Approach description
- Key decisions

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Acceptance Criteria
- Criterion 1
- Criterion 2
```

## Workers

| Worker | Modo | Contexto |
|--------|------|----------|
| planner | ligero | Flow + insights de planning + learnings |
| implementer | standard | plan-and-tasks.md + insights de implementation |

## HITL Checkpoint

Un unico checkpoint despues del plan, antes de implementar.
Si el usuario ha hecho tareas similares antes y tiene insight de autonomia, puede omitirse.

## Quality Gate

- Plan tiene acceptance criteria (hook: post-artifact-check valida al escribir)
- Tests pasan antes de commit
- Lint limpio antes de commit

## Alternativa: Plan Mode nativo de Claude Code

Para gravedad 2 con scope muy claro y pocas decisiones de diseno, considerar
usar el Plan Mode nativo de Claude Code en vez de spawneear un planner worker.
El plan se escribe como plan file y el usuario lo aprueba nativamente.
Esto reduce un nivel de indirección y ahorra tokens de contexto.

## Ejemplo

```
Usuario: "Implementa paginacion en la API de productos"
→ Gravedad 2 (5-6 archivos, scope claro)
→ Planner: plan-and-tasks.md
→ HITL: confirmar plan
→ Implementer: TDD por cada task
→ Verificar tests
→ Commit
```
