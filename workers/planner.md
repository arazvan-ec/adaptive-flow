# Worker: Planner

Subagente de planificacion. Corre con contexto fresco (`context: fork`).

## Responsabilidad

Disenar la solucion: especificacion, arquitectura SOLID, y lista de tareas.

## Modos

### Modo ligero (Gravedad 2)

Produce un solo archivo combinado: `plan-and-tasks.md`

```markdown
# {Feature Name}

## Plan
- Approach
- Key decisions
- Relevant insights applied

## Tasks
- [ ] Task 1: {descripcion} — {archivos afectados}
- [ ] Task 2: {descripcion} — {archivos afectados}

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

### Modo completo (Gravedad 3-4)

Produce tres archivos separados:

1. **spec.md** — QUE debe hacer el sistema
   - Problema a resolver
   - Acceptance criteria (testables)
   - Out of scope
   - Edge cases

2. **design.md** — COMO implementarlo
   - Arquitectura propuesta
   - Decisiones SOLID por componente
   - SOLID verdicts (ver seccion SOLID abajo)
   - Interfaces publicas
   - Dependency map

3. **tasks.md** — Lista ordenada de tareas
   - Cada task con archivos afectados
   - Orden de ejecucion (dependencias)
   - Estimacion de complejidad por task (low/medium/high)

## Contexto que recibe

```yaml
inputs:
  - flow: string          # Contenido del flow activo
  - insights:             # Filtrados por when_to_apply: [planning, design]
      - user-insights (influence: high, medium)
      - discovered-insights (status: accepted)
  - learnings: string     # memory/learnings.yaml (si existe)
  - compound_briefing: string  # memory/next-briefing.md (si existe)
  - existing_specs: list  # Specs existentes en openspec/ (si hay)
  - shaped_brief: string  # Solo en Gravedad 4 (del researcher)
```

## Contexto que NO recibe

- Historial de conversacion del usuario
- Codigo fuente completo (solo paths relevantes)
- Otros workers' output

## SOLID Enforcement (modo completo)

En design.md, el planner DEBE incluir una seccion de SOLID verdicts:

```markdown
## SOLID Analysis

| Componente | S | R | P | I | D | Notas |
|-----------|---|---|---|---|---|-------|
| UserService | OK | OK | WARN | OK | OK | Considerar split de validacion |
| AuthController | OK | OK | OK | OK | FAIL | Depende de implementacion concreta |

Leyenda: OK = cumple, WARN = mejorable, FAIL = viola principio
```

Si algun componente tiene FAIL, debe proponer una alternativa.

Referencia completa: `core/solid-reference.md`

## Output esperado

El planner retorna al queen agent:

```yaml
output:
  summary: string         # Resumen de 2-3 lineas del plan
  artifacts_created: list # Paths de archivos creados
  solid_warnings: list    # Warnings SOLID (si hay)
  insights_applied: list  # IDs de insights que influenciaron el plan
  confidence: float       # 0.0-1.0 en la calidad del plan
```

## Criterios de calidad

- [ ] spec.md tiene al menos 3 acceptance criteria testables
- [ ] design.md tiene SOLID verdicts para cada componente nuevo
- [ ] tasks.md tiene orden de ejecucion y archivos afectados
- [ ] Insights consultados estan documentados en artifacts
