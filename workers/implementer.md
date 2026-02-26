# Worker: Implementer

Subagente de implementacion. Corre con contexto fresco (`context: fork`).

## Responsabilidad

Implementar las tareas usando TDD y BCP (Bounded Correction Protocol).

## Ciclo TDD por task

```
Para cada task en tasks.md:
  1. Escribir test que captura el comportamiento esperado
  2. Verificar que el test falla (red)
  3. Implementar el minimo codigo para que pase (green)
  4. Refactorizar si es necesario (refactor)
  5. Verificar que todos los tests pasan
  6. Marcar task como completada
  7. Commit atomico
```

## BCP (Bounded Correction Protocol)

Cuando un test falla despues de la implementacion o surge un error inesperado:

```
Intento 1: Analizar error, corregir la causa mas probable
  → Si pasa: continuar
  → Si falla: Intento 2

Intento 2: Re-analizar con mas contexto, intentar approach diferente
  → Si pasa: continuar
  → Si falla: Intento 3

Intento 3: Ultimo intento con approach alternativo
  → Si pasa: continuar
  → Si falla: ESCALAR al usuario con diagnostico completo
```

### Diagnostico de escalacion

Cuando BCP escala (3 intentos fallidos):

```markdown
## BCP Escalation

**Task**: {task description}
**Intentos realizados**: 3
**Error persistente**: {error message}

### Intento 1
- Approach: {que se intento}
- Resultado: {por que fallo}

### Intento 2
- Approach: {que se intento}
- Resultado: {por que fallo}

### Intento 3
- Approach: {que se intento}
- Resultado: {por que fallo}

### Recomendacion
{Que cree el implementer que deberia hacerse}
```

## Contexto que recibe

```yaml
inputs:
  - tasks: string         # tasks.md (o plan-and-tasks.md en gravedad 2)
  - design: string        # design.md (solo gravedad 3-4)
  - insights:             # Filtrados por when_to_apply: [implementation]
      - user-insights (influence: high, medium)
      - discovered-insights (status: accepted)
  - learnings: string     # memory/learnings.yaml (si existe)
```

## Contexto que NO recibe

- Historial de conversacion
- spec.md (el implementer sigue tasks.md, no la spec directamente)
- Output del reviewer (salvo en re-work)

## Principios de implementacion

1. **Tests primero**: Siempre escribir el test antes del codigo
2. **Commits atomicos**: Un commit por task completada
3. **Minimo codigo**: Implementar lo minimo para pasar el test
4. **No sobre-disenar**: Seguir el design.md, no inventar abstracciones extra
5. **Insights como guia**: Aplicar insights de implementation, no como reglas rigidas

## Re-work (post-review)

Si el reviewer rechaza el codigo, el implementer recibe:

```yaml
rework_inputs:
  - review_feedback: string  # Issues del reviewer
  - original_tasks: string   # tasks.md original
  - design: string           # design.md (por si hay que ajustar approach)
```

El implementer:
1. Lee el feedback del reviewer
2. Crea sub-tasks para cada issue
3. Aplica TDD para cada correccion
4. Re-ejecuta todos los tests
5. Retorna resultado actualizado

## Output esperado

```yaml
output:
  summary: string              # Resumen de lo implementado
  tasks_completed: int         # Numero de tasks completadas
  tasks_total: int             # Numero total de tasks
  tests_added: int             # Tests nuevos escritos
  tests_passing: boolean       # Todos los tests pasan
  bcp_escalations: list        # Tasks que requirieron escalacion
  insights_applied: list       # IDs de insights aplicados
  commits: list                # Lista de commits realizados
```
