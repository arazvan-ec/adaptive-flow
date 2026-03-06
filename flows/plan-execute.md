# Flow: Plan-Execute (Gravedad 2)

Plan ligero seguido de ejecucion. Para tareas de scope claro que requieren planificar.

## Cuando

- 4-8 archivos afectados
- Requiere planificar el approach
- Scope claro, sin incertidumbre tecnica

## Proceso

> **Tier 2**: Al activar este flow, cargar insights completos (todas las influencias), `memory/learnings.yaml`, `memory/patterns.yaml` y `memory/next-briefing.md` si existen. Estos archivos no se cargan en session-init (Tier 1) para mantener el contexto minimo.

```
0. Escribir meta.yaml en memory/current-task/ con:
   name, gravity: 2, flow: "plan-execute", started: fecha actual, status: "in_progress"
1. Cargar Tier 2: insights completos + learnings.yaml + patterns.yaml + briefing
2. → Skill: planner (modo ligero)
   Produce: plan-and-tasks.md (un solo archivo combinado)
3. HITL: "Este plan captura tu intencion?"
4. → Skill: implementer (TDD)
   Recibe: plan-and-tasks.md + insights de implementation
5. Verificar: tests + lint
6. Actualizar meta.yaml → status: "completed"
7. Commit
```

## Artefactos

Directorio `memory/current-task/`:

- `meta.yaml` — Metadata de la tarea (gravity, flow, status)
- `plan-and-tasks.md` — Plan y tareas combinados

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

## Skills

| Skill | Modo | Contexto |
|-------|------|----------|
| planner | ligero | Flow + insights de planning + learnings |
| implementer | standard | plan-and-tasks.md + insights de implementation |

## Plan Mode Integration

Cuando Claude Code esta en **Plan Mode** (permission_mode: plan):
- El planner skill NO es necesario para gravedad 2 — Claude Code ya planifica nativamente
- En este caso, el flow se simplifica: el usuario planifica directamente y luego pasa a implementar
- Si plan mode no esta activo, se usa el planner skill normalmente

Deteccion: `session-init.sh` inyecta `plan_mode: true/false` en el contexto de sesion.

## HITL Checkpoint

Un unico checkpoint despues del plan, antes de implementar.
Si el usuario ha hecho tareas similares antes y tiene insight de autonomia, puede omitirse.

## Quality Gate

- Plan tiene acceptance criteria (hook: post-plan)
- Tests pasan (hook: pre-commit)
- Lint limpio (hook: pre-commit)

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
