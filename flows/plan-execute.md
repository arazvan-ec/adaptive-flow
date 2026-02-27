# Flow: Plan-Execute (Gravedad 2)

Plan ligero seguido de ejecucion. Para tareas de scope claro que requieren planificar.

## Cuando

- 4-8 archivos afectados
- Requiere planificar el approach
- Scope claro, sin incertidumbre tecnica

## Proceso

```
1. Cargar insights (planning + implementation)
2. Cargar memory/learnings.yaml (si existe)
3. → Skill: planner (modo ligero)
   Produce: plan-and-tasks.md (un solo archivo combinado)
4. HITL: "Este plan captura tu intencion?"
5. → Skill: implementer (TDD)
   Recibe: plan-and-tasks.md + insights de implementation
6. Verificar: tests + lint
7. Commit
```

## Artefactos

Un solo archivo combinado en `memory/current-task/plan-and-tasks.md`:

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
