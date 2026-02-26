# Plan D2: Ejecucion Paralela de Tareas Independientes

> Fecha: 2026-02-26
> Debilidad: El implementer trabaja secuencialmente — tareas independientes no se paralelizan
> Impacto: Medio
> Archivos afectados: 3-4

---

## Problema

El implementer actual (`workers/implementer.md`) ejecuta tareas secuencialmente:
```
task 1 → task 2 → task 3 → task 4 → task 5
```

Pero muchas tareas son independientes. Ejemplo:
- "Crear UserService" y "Crear ProductService" no dependen entre si
- "Agregar endpoint GET /users" y "Agregar endpoint GET /products" tampoco

Ejecutarlas en paralelo reduciria el tiempo linealmente.

## Solucion Propuesta

Agregar **deteccion de dependencias** en tasks.md y **ejecucion paralela por lotes** de tareas independientes.

### Cambio en el Formato de tasks.md

Agregar campo `depends_on` a cada task:

```markdown
## Tasks

- [ ] T1: Crear modelo User — src/models/user.ts
  - depends_on: none
  - complexity: low

- [ ] T2: Crear modelo Product — src/models/product.ts
  - depends_on: none
  - complexity: low

- [ ] T3: Crear UserService — src/services/user.service.ts
  - depends_on: T1
  - complexity: medium

- [ ] T4: Crear ProductService — src/services/product.service.ts
  - depends_on: T2
  - complexity: medium

- [ ] T5: Crear UserController — src/controllers/user.controller.ts
  - depends_on: T3
  - complexity: medium
```

### Ejecucion por Lotes (Batches)

```
Batch 1: [T1, T2]     ← independientes, paralelo
Batch 2: [T3, T4]     ← dependen de T1/T2 respectivamente, paralelo entre si
Batch 3: [T5]         ← depende de T3
```

---

## Tareas de Implementacion

### T1: Modificar `workers/planner.md` — agregar depends_on
**Complejidad**: Low

En la seccion de tasks.md output, agregar instruccion al planner:
- Cada task debe incluir `depends_on: none | [T_ids]`
- El planner analiza que tareas comparten archivos o interfaces
- Tareas que escriben al mismo archivo → dependencia
- Tareas que usan output de otra (ej: service usa model) → dependencia

### T2: Modificar `templates/tasks.md` — agregar depends_on al template
**Complejidad**: Low

Agregar el campo `depends_on` al template de tasks.

### T3: Modificar `flows/full-cycle.md` — orquestar batches paralelos
**Complejidad**: Medium

Cambiar el paso 5 (implementation) de spawneear 1 implementer a:

```
5a. Leer tasks.md y construir grafo de dependencias
5b. Identificar batches de tareas independientes
5c. Para cada batch:
    - Si batch tiene 1 task → spawneear 1 implementer
    - Si batch tiene 2+ tasks → spawneear N implementers en paralelo
      (Task tool, multiples calls en un mensaje)
    - Esperar a que todos terminen
    - Verificar que todos los tests pasan (integracion entre batches)
5d. Siguiente batch
```

### T4: Crear seccion "Parallel Execution" en `workers/implementer.md`
**Complejidad**: Low

Agregar nota de que el implementer puede correr en paralelo con otros implementers.
Restricciones cuando corre en paralelo:
- No modificar archivos que otro implementer esta tocando
- Commits atomicos por task (no por batch)
- Si un test de integracion falla post-batch, escalar al orquestador

---

## Restricciones

- **No paralelizar si**: tasks.md tiene <3 tareas (overhead > beneficio)
- **No paralelizar si**: todas las tareas son dependientes (cadena lineal)
- **Max agentes paralelos**: 3 (evitar token explosion)
- **G2 no cambia**: plan-execute sigue usando 1 implementer (scope es mas pequeno)

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| Conflictos de merge entre agentes paralelos | Planner asegura tareas paralelas tocan archivos diferentes |
| Tests de integracion fallan post-merge | Paso de verificacion obligatorio entre batches |
| Overhead de paralelizacion > beneficio | Solo paralelizar si batch tiene 2+ tareas |
| Commits desordenados | Cada implementer hace commits atomicos; el order dentro del batch no importa |

## Metricas de Exito

- Tareas independientes se ejecutan en paralelo
- Tiempo de implementacion se reduce proporcionalmente al paralelismo
- No hay regresiones por conflictos entre agentes paralelos
