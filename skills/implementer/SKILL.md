---
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - Bash
  - Task
  - TodoWrite
---

# Skill: Implementer

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

## TodoWrite Integration

El implementer DEBE usar TodoWrite para exponer progreso en tiempo real al usuario.
TodoWrite es la unica forma que tiene el usuario de ver el estado de ejecucion
mientras el implementer corre como subagente con contexto fresco.

### Paso 1: Parsear tasks.md al iniciar

Al recibir el contexto, el implementer lee tasks.md (o la seccion `## Tasks` de
plan-and-tasks.md) y extrae cada task con su ID y descripcion. Luego crea un
TodoWrite con TODAS las tasks como `pending`.

**Ejemplo**: dado un tasks.md con:

```markdown
- [ ] **T-1**: Crear modelo User con validaciones
- [ ] **T-2**: Implementar endpoint POST /users
- [ ] **T-3**: Agregar middleware de autenticacion
- [ ] **T-4**: Integrar User con servicio de email
```

El implementer invoca TodoWrite con:

```json
{
  "todos": [
    {
      "content": "T-1: Crear modelo User con validaciones",
      "status": "pending",
      "activeForm": "Creando modelo User con validaciones"
    },
    {
      "content": "T-2: Implementar endpoint POST /users",
      "status": "pending",
      "activeForm": "Implementando endpoint POST /users"
    },
    {
      "content": "T-3: Agregar middleware de autenticacion",
      "status": "pending",
      "activeForm": "Agregando middleware de autenticacion"
    },
    {
      "content": "T-4: Integrar User con servicio de email",
      "status": "pending",
      "activeForm": "Integrando User con servicio de email"
    }
  ]
}
```

### Paso 2: Marcar progreso en cada ciclo TDD

**Regla clave**: Solo UNA task puede estar `in_progress` a la vez.

Antes de iniciar el ciclo TDD de una task, el implementer actualiza TodoWrite
marcando esa task como `in_progress`. Al completar el ciclo TDD (test green +
refactor + commit), la marca como `completed`.

Flujo por task:

```
1. TodoWrite → marcar T-N como in_progress (resto sin cambio)
2. Escribir test (red)
3. Implementar codigo (green)
4. Refactorizar si necesario
5. Verificar todos los tests pasan
6. Commit atomico
7. TodoWrite → marcar T-N como completed
```

**Ejemplo**: al iniciar T-2 (con T-1 ya completada):

```json
{
  "todos": [
    {
      "content": "T-1: Crear modelo User con validaciones",
      "status": "completed",
      "activeForm": "Creando modelo User con validaciones"
    },
    {
      "content": "T-2: Implementar endpoint POST /users",
      "status": "in_progress",
      "activeForm": "Implementando endpoint POST /users"
    },
    {
      "content": "T-3: Agregar middleware de autenticacion",
      "status": "pending",
      "activeForm": "Agregando middleware de autenticacion"
    },
    {
      "content": "T-4: Integrar User con servicio de email",
      "status": "pending",
      "activeForm": "Integrando User con servicio de email"
    }
  ]
}
```

### Paso 3: Manejo de BCP escalation en TodoWrite

Cuando el BCP se activa y los 3 intentos fallan, el implementer NO marca la task
como `completed`. En su lugar:

1. Mantiene la task actual como `in_progress`
2. Agrega una nueva task "Resolver escalacion BCP: {task ID}" justo despues
3. Escala al usuario con el diagnostico completo

**Ejemplo**: BCP escala en T-2:

```json
{
  "todos": [
    {
      "content": "T-1: Crear modelo User con validaciones",
      "status": "completed",
      "activeForm": "Creando modelo User con validaciones"
    },
    {
      "content": "T-2: Implementar endpoint POST /users",
      "status": "in_progress",
      "activeForm": "Implementando endpoint POST /users"
    },
    {
      "content": "Resolver escalacion BCP: T-2 (3 intentos fallidos)",
      "status": "pending",
      "activeForm": "Resolviendo escalacion BCP para T-2"
    },
    {
      "content": "T-3: Agregar middleware de autenticacion",
      "status": "pending",
      "activeForm": "Agregando middleware de autenticacion"
    },
    {
      "content": "T-4: Integrar User con servicio de email",
      "status": "pending",
      "activeForm": "Integrando User con servicio de email"
    }
  ]
}
```

Una vez el usuario resuelve la escalacion, el implementer:
1. Marca la task BCP como `completed`
2. Marca la task original (T-2) como `completed` si el fix resolvio el problema
3. Continua con la siguiente task pendiente

### Notas importantes

- **Siempre enviar la lista completa**: TodoWrite reemplaza la lista entera en
  cada invocacion. Incluir TODAS las tasks (completed, in_progress y pending)
  en cada llamada.
- **activeForm en gerundio**: Usar la forma continua en espanol o ingles segun
  el idioma del proyecto (ej: "Creando...", "Implementando...", "Creating...").
- **content con ID de task**: Incluir el ID (T-1, T-2...) para que el usuario
  pueda correlacionar con tasks.md facilmente.
- **No omitir tasks completadas**: Las tasks completadas deben seguir en la
  lista para que el usuario vea el progreso total.

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
