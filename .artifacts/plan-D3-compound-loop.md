# Plan D3: Cerrar el Compound Loop — Learnings Matcher

> Fecha: 2026-02-26
> Debilidad: Learnings se acumulan pero no se recuperan inteligentemente por contexto
> Impacto: Medio-Alto
> Archivos afectados: 4-5

---

## Problema

Actualmente el compound loop esta **abierto**:

```
Feature N completada
    → compound-capture extrae learnings → memory/learnings.yaml
    → next-briefing.md se genera

Feature N+1 comienza
    → planner carga learnings.yaml completo (bulk load)
    → NO hay busqueda por relevancia
    → Un learning sobre "N+1 queries en Prisma" no se conecta
      cuando el planner diseña una nueva query
```

El planner recibe **todos** los learnings sin filtrar. Con pocas features esto funciona, pero a medida que learnings crecen, se vuelve ruido.

## Solucion Propuesta

Crear un **learnings-matcher** que filtre learnings relevantes antes de pasarlos al planner/implementer.

### Flujo Propuesto

```
Feature N+1: "Agregar endpoint de busqueda de productos"

1. Extraer tags del request: [api, search, query, products, database]
2. learnings-matcher busca en learnings.yaml por:
   - Tags que matchean
   - Context que es similar (keyword matching)
   - Type (anti-patterns tienen prioridad)
3. Retorna top 5 learnings relevantes (no todos)
4. Planner/Implementer reciben solo los relevantes
```

---

## Tareas de Implementacion

### T1: Definir seccion "Learnings Matching" en un nuevo archivo `core/learnings-matcher.md`
**Complejidad**: Medium

Crear una guia de matching que el flow usa como instruccion:

```markdown
# Learnings Matcher

## Algoritmo de Relevancia

Para una tarea con tags [tag1, tag2, ...] y descripcion:

1. **Tag match** (peso 3): learning.tags intersecta con task.tags
2. **Context match** (peso 2): keywords de learning.context aparecen en task description
3. **Type priority** (peso 1):
   - anti-pattern: +2 (evitar errores es mas importante)
   - boundary: +1 (complejidad inesperada es util)
   - pattern: +0 (buenas practicas son nice-to-have)
4. **Recency** (peso 0.5): learnings mas recientes tienen ligera prioridad

Score = (tag_match * 3) + (context_match * 2) + type_bonus + recency_bonus

Retornar top 5 learnings con score > 0.
Si no hay learnings con score > 0, retornar vacio.
```

### T2: Modificar schema de `memory/learnings.yaml`
**Complejidad**: Low

Asegurar que cada learning tenga tags suficientes para matching:

```yaml
- id: prisma-n-plus-one
  type: anti-pattern
  description: "N+1 queries en Prisma cuando se usan relaciones sin include"
  context: "Feature de listado de usuarios con roles"
  impact: "Performance degradation en listas grandes"
  tags: [prisma, database, query, performance, orm]  # ← tags ricos
  captured: 2026-02-20
```

El compound-capture ya genera tags. Reforzar la instruccion de que genere tags abundantes (5-8 por learning).

### T3: Modificar `flows/full-cycle.md` — integrar matching antes de planning
**Complejidad**: Medium

Agregar paso entre "cargar compound data" y "spawneear planner":

```
1. Cargar compound data
1b. NUEVO: Filtrar learnings relevantes:
    - Extraer tags/keywords de la solicitud del usuario
    - Aplicar algoritmo de learnings-matcher.md
    - Pasar solo top 5 learnings relevantes al planner (no todos)
2. Cargar insights...
3. Spawneear planner con learnings filtrados
```

### T4: Modificar `flows/plan-execute.md` — misma logica para G2
**Complejidad**: Low

Aplicar el mismo filtrado de learnings en G2, pero simplificado:
- Solo tag match (sin scoring complejo)
- Top 3 learnings

### T5: Modificar `skills/compound-capture.md` — reforzar generacion de tags
**Complejidad**: Low

En la seccion de learnings extraction:
- Instruccion explicita: "Generar 5-8 tags por learning, incluyendo: tecnologia, dominio, tipo de operacion, capa de arquitectura"
- Ejemplo: `tags: [prisma, database, query, performance, orm, data-access, pagination]`

---

## Ejemplo de Flujo Completo

```
Feature anterior: "Listado de usuarios con roles"
  → Learning capturado:
    id: prisma-eager-loading
    type: anti-pattern
    description: "Prisma carga relaciones lazy por defecto, causa N+1"
    tags: [prisma, database, query, performance, relations, eager-loading]

Feature nueva: "Busqueda de productos con categorias"
  → Tags extraidos: [products, search, database, categories, relations]
  → Learnings matcher:
    - prisma-eager-loading: tag match [database, relations] = score 8
  → Planner recibe: "LEARNING RELEVANTE: Prisma carga relaciones lazy..."
  → Planner incluye `include: { categories: true }` en el design
```

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| Tags insuficientes → matching pobre | Reforzar compound-capture para generar 5-8 tags |
| False positives (learnings irrelevantes) | Top 5 limita el ruido; score > 0 filtra |
| Overhead de matching | Matching es textual, no semantico — es rapido |

## Metricas de Exito

- Planner recibe learnings relevantes (no bulk dump)
- Anti-patterns previos se evitan en features nuevas
- Learnings con 0 matches en 10+ features se marcan para review
