# Adaptive Flow

Framework de ingenieria compuesta para Claude Code.
Adapta el proceso a la gravedad de la tarea.

## Getting Started

First time? The framework works automatically — just ask for what you need.
It comes with 8 starter insights in `memory/user-insights.yaml` that you can
adjust, pause, or retire. To add your own: `/adaptive-flow:insights-manager --add`.
To analyze your stack and bootstrap project-specific memory: `/adaptive-flow:discover --seed`.

## Routing: Determinar Gravedad

Antes de actuar, clasifica la solicitud:

| Gravedad | Criterio | Flow | Ejemplo |
|----------|----------|------|---------|
| 1 | ≤3 archivos, cambio claro, sin ambiguedad | `flows/direct.md` | "Anade campo email a User" |
| 2 | 4-8 archivos, requiere planificar, scope claro | `flows/plan-execute.md` | "Implementa paginacion en API" |
| 3 | >8 archivos o multi-capa o seguridad/pagos | `flows/full-cycle.md` | "Anade autenticacion OAuth" |
| 4 | Scope ambiguo, requiere investigacion/shaping | `flows/shape-first.md` | "Reestructura el modulo de billing" |

Si la confianza en la clasificacion es < 60%, preguntar al usuario.

## En cada decision, consultar:

1. `memory/user-insights.yaml` — Heuristicas del usuario (influence: high → aplicar, medium → considerar)
2. `memory/learnings.yaml` — Patrones del proyecto (si existen)
3. El flow correspondiente a la gravedad

## Workers (subagentes con contexto fresco)

| Worker | Cuando | Contexto que recibe |
|--------|--------|---------------------|
| planner | Gravedad 2-4 | Flow + specs existentes + insights de planning |
| implementer | Gravedad 2-4 | Plan + insights de implementation |
| reviewer | Gravedad 3-4 | Codigo + specs + insights de review |
| researcher | Cuando se necesita analisis | Pregunta especifica |

Workers corren en `context: fork` — contexto fresco, retornan solo resumen.

## Hooks (quality gates automaticos)

Los hooks en `hooks/` se ejecutan automaticamente via Claude Code hooks API.
No dependen de que el agente "recuerde" ejecutarlos.

## Skills

- `/adaptive-flow:insights-manager` — Gestionar insights del usuario
- `/adaptive-flow:solid-analyzer` — Analisis SOLID contextual
- `/adaptive-flow:compound-capture` — Capturar learnings post-feature
- `/adaptive-flow:discover` — Analizar stack y bootstrap de memoria

## Compound: Cada tarea mejora la siguiente

Despues de completar una tarea de gravedad 3+, ejecutar compound-capture para:
- Extraer patrones y anti-patrones → `memory/learnings.yaml`
- Proponer discovered insights → `memory/discovered-insights.yaml`
- Generar briefing para la siguiente tarea

## Principios

1. **Gravedad proporcional**: El proceso pesa lo mismo que la tarea
2. **Contexto minimo viable**: Cargar solo lo necesario para la decision actual
3. **Insights sobre reglas**: Heuristicas graduadas sobre reglas binarias
4. **Workers efimeros**: Subagentes con contexto fresco, no acumulado
5. **Hooks deterministicos**: Validaciones automatizadas, no probabilisticas
6. **Compound por defecto**: Cada tarea alimenta la siguiente
7. **El usuario tiene la ultima palabra**: Sus insights siempre tienen prioridad

## Estructura

```
adaptive-flow/
├── CLAUDE.md              ← Estas aqui
├── flows/                 # Procesos por nivel de gravedad
├── workers/               # Subagentes con contexto fresco
├── hooks/                 # Quality gates deterministicos
├── memory/                # Persistencia entre sesiones
├── templates/             # Templates para artefactos
├── core/                  # Referencia tecnica (carga bajo demanda)
└── skills/                # Skills invocables
```
