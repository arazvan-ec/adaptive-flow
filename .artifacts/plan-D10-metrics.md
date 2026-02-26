# Plan D10: Sistema de Metricas de Efectividad

> Fecha: 2026-02-26
> Debilidad: No se trackea nada — no se puede medir si el framework mejora la productividad
> Impacto: Medio
> Archivos afectados: 4-5

---

## Problema

Actualmente no se mide:
- Tiempo por gravedad
- Accuracy del routing (¿se clasifico bien?)
- Tasa de BCP escalation (¿los implementers se atascan mucho?)
- Review pass rate (¿cuantos reviews son APPROVED al primer intento?)
- Insights utilization (¿que insights se aplican realmente?)

Sin metricas, no se puede responder: **"¿El framework esta ayudando?"**

## Solucion Propuesta

Agregar un sistema ligero de metricas que capture datos en cada feature completada, almacenados en `memory/metrics.yaml`.

### Principio: Metricas Pasivas

Las metricas se capturan **automaticamente** durante el flujo normal. No requieren accion extra del usuario. Se agregan a `memory/metrics.yaml` al final de cada feature (en compound-capture o al commit).

---

## Tareas de Implementacion

### T1: Crear `memory/metrics.yaml` con schema
**Complejidad**: Low

```yaml
# Metricas de efectividad del framework
# Se actualiza automaticamente al completar features

summary:
  total_features: 0
  avg_review_pass_rate: null
  avg_bcp_escalations: null
  gravity_distribution: { 1: 0, 2: 0, 3: 0, 4: 0 }
  routing_accuracy: null  # % de features donde gravedad no cambio mid-flight

features: []
# Cada feature:
# - slug: string
#   date: YYYY-MM-DD
#   gravity_initial: int        # gravedad clasificada
#   gravity_final: int          # gravedad real (si hubo upgrade via D7)
#   routing_accurate: boolean   # initial == final
#   files_modified: int
#   layers_touched: [string]
#   tasks_total: int
#   tasks_completed: int
#   bcp_escalations: int
#   review_verdict: APPROVED | REJECTED | null (G1-2 sin review)
#   review_attempts: int        # cuantos review cycles antes de APPROVED
#   insights_applied: [string]  # IDs de insights usados
#   compound_extracted:
#     patterns: int
#     learnings: int
#     insights_proposed: int
```

### T2: Modificar `skills/compound-capture.md` — capturar metricas
**Complejidad**: Medium

Al final del compound-capture, agregar paso:

```
METRICAS:

1. Recopilar datos de la feature completada:
   - De .artifacts/meta.yaml: slug, gravity, started
   - De git: archivos modificados (git diff --name-only)
   - De tasks.md: tasks total/completed
   - Del implementer output: BCP escalations
   - Del reviewer output: verdict, attempts
   - De los artifacts: insights applied

2. Crear entry en memory/metrics.yaml.features[]

3. Recalcular summary:
   - total_features += 1
   - Actualizar avg_review_pass_rate
   - Actualizar gravity_distribution
   - Actualizar routing_accuracy (si D7 implementado)
```

### T3: Modificar `flows/direct.md` — metricas lightweight para G1
**Complejidad**: Low

G1 no ejecuta compound-capture, pero deberia capturar metricas minimas:

```
Post-commit en G1:
  Agregar a memory/metrics.yaml.features[]:
    slug: auto-generated
    date: today
    gravity_initial: 1
    gravity_final: 1
    files_modified: count
    review_verdict: null
    bcp_escalations: 0
```

### T4: Crear seccion "Metrics Dashboard" en `skills/compound-capture.md`
**Complejidad**: Low

Al final del compound-capture, mostrar un mini-dashboard:

```
📊 Framework Metrics (last 10 features):
  - Routing accuracy: 80% (8/10 correct)
  - Review pass rate: 70% (7/10 first-attempt APPROVED)
  - BCP escalation rate: 10% (1/10 features needed escalation)
  - Gravity distribution: G1: 4, G2: 3, G3: 2, G4: 1
  - Most applied insights: tdd-produces-better-code (8), validate-at-boundaries (6)
```

### T5: Agregar `--metrics` flag a compound-capture
**Complejidad**: Low

Permitir ver metricas sin ejecutar compound-capture:

```
/adaptive-flow:compound-capture --metrics
```

Muestra el dashboard de metricas acumuladas.

---

## Que Metricas y Por Que

| Metrica | Por que importa |
|---------|-----------------|
| `routing_accuracy` | ¿El router clasifica bien? Si <70%, necesita mejora (D6) |
| `review_pass_rate` | ¿La calidad del codigo es buena al primer intento? |
| `bcp_escalations` | ¿Los implementers se atascan? Puede indicar tasks mal definidas |
| `gravity_distribution` | ¿El proyecto es mayormente trivial o complejo? |
| `insights_applied` | ¿Que insights son realmente utiles? Informa decay (D4) |
| `files_modified` | ¿Las estimaciones de scope son correctas? |

## Que NO Medir

- **Tiempo**: No medimos duracion porque depende del hardware, network, y tokens disponibles. No es una metrica actionable.
- **Tokens usados**: Fuera de nuestro control y no comparable entre sesiones.
- **"Productividad"**: Demasiado subjetivo. Mejor medir proxies concretos.

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| metrics.yaml crece indefinidamente | Mantener solo ultimas 50 features; summary es acumulativo |
| Metricas dan falsa sensacion de precision | Son proxies, no verdades absolutas. Documentar limitaciones |
| G1 no captura metricas (no ejecuta compound) | T3 agrega captura lightweight en G1 |

## Metricas de Exito (meta)

- Cada feature completada genera una entry en metrics.yaml
- El dashboard muestra tendencias utiles
- El usuario puede tomar decisiones informadas sobre el framework
