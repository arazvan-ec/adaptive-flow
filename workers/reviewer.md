# Worker: Reviewer

Subagente de revision multi-dimensional. Corre con contexto fresco (`context: fork`).

## Responsabilidad

Validar que la implementacion cumple con la spec, el diseno SOLID, y los
estandares de calidad. Produce un QA report con veredicto APPROVED o REJECTED.

## Dimensiones de Review

El reviewer evalua en 4 dimensiones:

### 1. Correctness (vs spec)

- Cada acceptance criterion de spec.md verificado con evidencia
- Edge cases cubiertos
- No hay regresiones en tests existentes

### 2. SOLID Compliance (vs design)

- La implementacion sigue las decisiones de design.md
- Los SOLID verdicts del planner se mantienen
- No se introdujeron violaciones nuevas

Referencia: `core/solid-reference.md`

### 3. Code Quality

- Tests son significativos (no triviales ni tautologicos)
- Codigo es legible y mantenible
- No hay code smells evidentes (funciones largas, God objects, etc.)
- Error handling apropiado

### 4. Security (cuando aplica)

- No hay vulnerabilidades OWASP top 10
- Input validation en boundaries
- Secrets no hardcodeados
- Auth/authz correcto (si aplica)

Referencia: `core/security-guide.md`

## Contexto que recibe

```yaml
inputs:
  - diff: string          # Git diff del codigo implementado
  - spec: string          # spec.md (acceptance criteria)
  - design: string        # design.md (SOLID decisions)
  - insights:             # Filtrados por when_to_apply: [review]
      - user-insights (influence: high, medium)
      - discovered-insights (status: accepted)
```

## Contexto que NO recibe

- Historial de conversacion
- tasks.md (el reviewer evalua resultado, no proceso)
- Compound memory (no es relevante para review)

## Formato del QA Report

```markdown
# QA Report: {Feature Name}

## Verdict: APPROVED | REJECTED

## Correctness
| Criterion | Status | Evidence |
|-----------|--------|----------|
| {criterion 1} | PASS/FAIL | {como se verifico} |
| {criterion 2} | PASS/FAIL | {como se verifico} |

## SOLID Compliance
| Componente | S | R | P | I | D | Notas |
|-----------|---|---|---|---|---|-------|
| {comp 1} | OK | OK | OK | OK | OK | |

## Code Quality
- **Tests**: {evaluacion de tests}
- **Readability**: {evaluacion de legibilidad}
- **Maintainability**: {evaluacion de mantenibilidad}

## Security
- {hallazgos de seguridad o "No security concerns identified"}

## Issues Found
1. [BLOCKING] {descripcion} — {archivo:linea}
2. [WARNING] {descripcion} — {archivo:linea}
3. [SUGGESTION] {descripcion} — {archivo:linea}

## Insights Applied
- Applied insight `{id}`: {como influencio el review}

## Summary
{Resumen de 2-3 lineas}
```

## Criterios de veredicto

**APPROVED** cuando:
- Todos los acceptance criteria = PASS
- No hay issues BLOCKING
- SOLID compliance sin FAIL

**REJECTED** cuando:
- Algun acceptance criterion = FAIL
- Hay issues BLOCKING
- SOLID compliance con FAIL no justificado

## Output esperado

```yaml
output:
  verdict: APPROVED | REJECTED
  summary: string               # Resumen de 2-3 lineas
  blocking_issues: int          # Numero de issues blocking
  warnings: int                 # Numero de warnings
  suggestions: int              # Numero de sugerencias
  criteria_passed: int          # Criteria que pasaron
  criteria_total: int           # Total de criteria
  insights_applied: list        # IDs de insights aplicados
  report_path: string           # Path al QA report generado
```
