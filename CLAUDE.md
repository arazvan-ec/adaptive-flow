# Adaptive Flow

Framework de ingenieria compuesta para Claude Code.
Adapta el proceso a la gravedad de la tarea.

## Routing: Determinar Gravedad

Antes de actuar, clasifica la solicitud:

| Gravedad | Criterio | Flow |
|----------|----------|------|
| 1 | ≤3 archivos, cambio claro, sin ambiguedad | `flows/direct.md` |
| 2 | 4-8 archivos, requiere planificar, scope claro | `flows/plan-execute.md` |
| 3 | >8 archivos o multi-capa o seguridad/pagos | `flows/full-cycle.md` |
| 4 | Scope ambiguo, requiere investigacion/shaping | `flows/shape-first.md` |

Si la confianza en la clasificacion es < 60%, preguntar al usuario.

## En cada decision, consultar:

1. `memory/user-insights.yaml` — Heuristicas del usuario (influence: high → aplicar, medium → considerar)
2. `memory/learnings.yaml` — Patrones del proyecto (si existen)
3. El flow correspondiente a la gravedad

## Skills

- `/adaptive-flow:insights-manager` — Gestionar insights del usuario
- `/adaptive-flow:solid-analyzer` — Analisis SOLID contextual
- `/adaptive-flow:compound-capture` — Capturar learnings post-feature (ejecutar despues de gravedad 3+)
- `/adaptive-flow:discover` — Analizar stack y bootstrap de memoria

## Principios

1. **Gravedad proporcional**: El proceso pesa lo mismo que la tarea
2. **Contexto minimo viable**: Cargar solo lo necesario para la decision actual
3. **Insights sobre reglas**: Heuristicas graduadas sobre reglas binarias
4. **El usuario tiene la ultima palabra**: Sus insights siempre tienen prioridad
