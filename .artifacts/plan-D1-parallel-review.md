# Plan D1: Review Paralelo Multi-Agente

> Fecha: 2026-02-26
> Debilidad: El reviewer es un bottleneck — 1 agente cubriendo 4 dimensiones
> Impacto: Medio-Alto
> Archivos afectados: 4-6

---

## Problema

El reviewer actual (`workers/reviewer.md`) intenta cubrir 4 dimensiones en un solo agente:
1. Correctness (vs spec)
2. SOLID Compliance (vs design)
3. Code Quality
4. Security

Un solo agente no puede ser experto en las 4 dimensiones simultaneamente. Ademas, se ejecuta secuencialmente, cuando las 4 dimensiones son **independientes entre si**.

## Solucion Propuesta

Descomponer el reviewer en sub-reviewers paralelos que corren como Task agents concurrentes, orquestados por el flow `full-cycle.md`.

### Arquitectura

```
full-cycle.md (paso 6)
  │
  ├─► Task(correctness-reviewer)  ──► partial-report
  ├─► Task(solid-reviewer)        ──► partial-report    ← en paralelo
  ├─► Task(quality-reviewer)      ──► partial-report
  └─► Task(security-reviewer)     ──► partial-report
  │
  └─► Merge reports → QA Report final → verdict
```

### Nuevo directorio: `workers/reviewers/`

```
workers/
├── reviewer.md                    # MANTENER como fallback para G2
└── reviewers/
    ├── correctness-reviewer.md    # NUEVO
    ├── solid-reviewer.md          # NUEVO
    ├── quality-reviewer.md        # NUEVO
    └── security-reviewer.md       # NUEVO
```

---

## Tareas de Implementacion

### T1: Crear `workers/reviewers/correctness-reviewer.md`
**Complejidad**: Low

Extraer la dimension "Correctness" del reviewer actual:
- Recibe: diff + spec.md
- Evalua: cada acceptance criterion con evidencia
- Verifica: edge cases cubiertos, no regresiones
- Output: tabla de criteria (PASS/FAIL) + issues encontrados

### T2: Crear `workers/reviewers/solid-reviewer.md`
**Complejidad**: Low

Extraer la dimension "SOLID Compliance":
- Recibe: diff + design.md
- Carga: `core/solid-reference.md`
- Evalua: implementacion sigue design, SOLID verdicts mantenidos
- Output: tabla SOLID por componente + issues encontrados

### T3: Crear `workers/reviewers/quality-reviewer.md`
**Complejidad**: Low

Extraer la dimension "Code Quality":
- Recibe: diff + insights (review)
- Evalua: tests significativos, legibilidad, mantenibilidad, code smells
- Output: evaluacion de quality + issues encontrados

### T4: Crear `workers/reviewers/security-reviewer.md`
**Complejidad**: Low

Extraer la dimension "Security":
- Recibe: diff
- Carga: `core/security-guide.md`
- Evalua: OWASP top 10, input validation, secrets, auth
- Condicional: solo se spawneea si la tarea involucra auth, pagos, datos sensibles, o API publica
- Output: hallazgos de seguridad + issues encontrados

### T5: Modificar `flows/full-cycle.md` paso 6
**Complejidad**: Medium

Cambiar el paso 6 de:
```
6. Spawneear subagente reviewer (1 agente, secuencial)
```
A:
```
6. Spawneear 3-4 sub-reviewers en paralelo (Task tool, multiples calls en un mensaje):
   - correctness-reviewer (siempre)
   - solid-reviewer (siempre en G3+)
   - quality-reviewer (siempre)
   - security-reviewer (solo si aplica: auth, pagos, datos sensibles, API publica)
7. Merge de reportes parciales en QA Report unificado
8. Verdict: APPROVED solo si TODOS los sub-reviewers aprueban
```

### T6: Mantener `workers/reviewer.md` como fallback para G2
**Complejidad**: Low

En `flows/plan-execute.md`, el reviewer single sigue siendo suficiente para G2.
Agregar nota en reviewer.md: "Para G3+, ver `workers/reviewers/`"

---

## Formato del Merge

El flow `full-cycle.md` recibe los 4 reportes parciales y los combina:

```markdown
# QA Report: {Feature Name}

## Verdict: APPROVED | REJECTED

## Correctness (from correctness-reviewer)
{tabla de criteria}

## SOLID Compliance (from solid-reviewer)
{tabla SOLID}

## Code Quality (from quality-reviewer)
{evaluacion}

## Security (from security-reviewer)
{hallazgos}

## Issues Found (merged, sorted by severity)
1. [BLOCKING] ...
2. [WARNING] ...
3. [SUGGESTION] ...
```

**Regla de verdict**: REJECTED si cualquier sub-reviewer reporta issues BLOCKING.

---

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| 4 agentes consumen mas tokens | Security-reviewer es condicional; G2 mantiene reviewer single |
| Reportes parciales pueden contradecirse | El merge en full-cycle.md resuelve conflictos (BLOCKING siempre gana) |
| Over-engineering para proyectos simples | Solo aplica a G3+; G1-G2 no cambian |

## Metricas de Exito

- Review de G3 ejecuta las 4 dimensiones en paralelo (no secuencial)
- Cada sub-reviewer produce un reporte enfocado y actionable
- El tiempo total de review se reduce (paralelo vs secuencial)
