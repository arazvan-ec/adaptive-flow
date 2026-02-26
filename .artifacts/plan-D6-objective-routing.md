# Plan D6: Router de Gravedad Objetivo

> Fecha: 2026-02-26
> Debilidad: El router de gravedad es subjetivo — "≤3 archivos" requiere adivinar antes de analizar
> Impacto: Medio
> Archivos afectados: 3-4

---

## Problema

El routing actual en `CLAUDE.md`:

```
| Gravedad | Criterio |
| 1 | ≤3 archivos, cambio claro, sin ambiguedad |
| 2 | 4-8 archivos, requiere planificar, scope claro |
| 3 | >8 archivos o multi-capa o seguridad/pagos |
| 4 | Scope ambiguo, requiere investigacion |
```

Problemas:
1. **"¿Cuantos archivos?"** — No se puede saber antes de analizar el codebase
2. **"Multi-capa"** — Subjetivo sin contexto del proyecto
3. **Misclassification frecuente**: Un cambio "de 3 archivos" que afecta 10
4. El researcher se invoca solo si "confianza < 60%", pero ¿como se mide esa confianza?

## Solucion Propuesta

Agregar un **quick routing analysis** (<30 segundos) que sea objetivo, ejecutado **antes** de clasificar.

### Quick Routing Analysis

```
Antes de clasificar gravedad:

1. Grep/search rapido por keywords del request en el codebase
2. Identificar archivos potencialmente afectados (paths)
3. Contar archivos y capas involucradas
4. Aplicar criterios objetivos basados en datos reales
```

---

## Tareas de Implementacion

### T1: Crear `core/routing-analysis.md` — guia del quick analysis
**Complejidad**: Medium

```markdown
# Quick Routing Analysis

Ejecutar ANTES de clasificar gravedad. Max 30 segundos.

## Pasos

1. **Keyword extraction**: Extraer entidades del request del usuario
   - Ej: "Agregar auth con OAuth" → [auth, OAuth, login, session, token]

2. **Impact scan**: Buscar keywords en el codebase
   - Grep por cada keyword
   - Listar archivos que matchean
   - Contar archivos unicos

3. **Layer detection**: Clasificar archivos por capa
   - API/routes (controllers, routes, endpoints)
   - Business logic (services, use-cases, domain)
   - Data access (models, repositories, migrations)
   - UI (components, pages, templates)
   - Config (env, settings, middleware)
   - Tests

4. **Clasificacion objetiva**:

   | Archivos | Capas | Señales extras | → Gravedad |
   |----------|-------|---------------|-----------|
   | 1-3 | 1 | Ninguna | 1 |
   | 1-3 | 2+ | Ninguna | 2 |
   | 4-8 | 1-2 | Ninguna | 2 |
   | 4-8 | 3+ | Ninguna | 3 |
   | 9+ | cualquier | Ninguna | 3 |
   | cualquier | cualquier | auth/pagos/security | min 3 |
   | scope ambiguo | N/A | No se puede determinar | 4 |

5. **Confidence check**:
   - Si el scan encontro archivos claros → confidence alta
   - Si keywords no matchearon nada → posible feature nueva → gravedad 2+ (requiere crear archivos)
   - Si el scope es ambiguo → gravedad 4
```

### T2: Modificar `CLAUDE.md` — integrar quick analysis en el routing
**Complejidad**: Low

Cambiar la seccion de routing de:
```
Antes de actuar, clasifica la solicitud:
```
A:
```
Antes de actuar:
1. Ejecutar quick routing analysis (core/routing-analysis.md)
   - Max 30 segundos
   - Resultado: archivos afectados, capas, gravedad sugerida
2. Clasificar gravedad basandose en datos objetivos del analysis
3. Si confidence < 60% → gravedad 4 (shape-first)
```

### T3: Modificar `workers/researcher.md` — modo quick-route
**Complejidad**: Medium

Agregar un modo ultraligero al researcher que solo haga el impact scan:

```yaml
modes:
  - quick-route:     # NUEVO — solo para routing, <30s
      input: user_request
      output: { files_affected: [], layers: [], suggested_gravity: int, confidence: float }
  - deep-analysis:   # existente
  - shaping:         # existente
```

El modo `quick-route`:
- NO lee contenido de archivos (solo paths)
- NO analiza arquitectura
- Solo grep + count + classify
- Retorna en <30 segundos

### T4: Ajustar tabla en `CLAUDE.md`
**Complejidad**: Low

Reemplazar criterios subjetivos por criterios basados en el analysis:

```
| Gravedad | Criterio (post-analysis) |
|----------|--------------------------|
| 1 | 1-3 archivos, 1 capa, sin señales de riesgo |
| 2 | 4-8 archivos o 2+ capas, scope claro post-analysis |
| 3 | 9+ archivos o 3+ capas o señales de riesgo (auth/pagos/security) |
| 4 | Scope no determinable por analysis o confidence < 60% |
```

---

## Ejemplo

```
Usuario: "Agregar validacion de email al registro de usuarios"

Quick routing analysis (20s):
  Keywords: [email, validation, registro, users, register]
  Impact scan:
    - src/controllers/auth.controller.ts (match: register)
    - src/services/user.service.ts (match: users, register)
    - src/models/user.ts (match: users)
    - tests/auth.test.ts (match: register)
  Files: 4, Layers: 3 (controller, service, model)
  Risk signals: none

→ Gravedad 2 (4 archivos, 3 capas, scope claro)
→ Confidence: 85%
```

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| 30 segundos extra en cada request | Solo para G2+ candidates; G1 obvios (typos, renames) skip analysis |
| Grep no encuentra todo | Es una estimacion, no exactitud. Errar hacia gravedad mayor es seguro |
| Over-engineering el routing | Mantener el analysis simple: grep + count + classify |

## Metricas de Exito

- Routing basado en datos reales del codebase, no en estimacion subjetiva
- Misclassification rate se reduce (medible via retrospectives)
- Quick analysis completa en <30 segundos
