# Plan D8: Context Summary para Workers

> Fecha: 2026-02-26
> Debilidad: Fresh-context workers pierden informacion de la conversacion del usuario
> Impacto: Bajo-Medio
> Archivos afectados: 4-5

---

## Problema

Los workers corren con `context: fork` (contexto fresco). Esto ahorra tokens y evita contaminacion, pero tiene un costo:

**Decisiones del usuario en la conversacion se pierden.**

Ejemplo:
1. Usuario dice: "Quiero que sea backwards-compatible con la v1 del API"
2. Flow spawneea al planner
3. Planner no sabe de backwards-compatibility (no es un insight formal)
4. Planner diseña breaking changes
5. Review pasa (no hay spec de backwards-compat)
6. Usuario recibe codigo que rompe la v1

El unico mecanismo actual para pasar informacion del usuario es a traves de **insights formales**, pero no toda decision de sesion merece ser un insight permanente.

## Solucion Propuesta

Generar un **context summary** (5-10 lineas) antes de spawneear cada worker, que capture decisiones clave de la sesion actual.

### Formato del Context Summary

```markdown
## Session Context

- User requested: "{resumen de 1 linea del request original}"
- Key decisions:
  - Must be backwards-compatible with v1 API
  - Prefer PostgreSQL over MySQL for this feature
  - No new dependencies allowed
- Constraints mentioned:
  - Deadline is Friday
  - Must work with Node 18+
- Tone/preferences this session:
  - User wants minimal changes
  - User asked to avoid over-engineering
```

---

## Tareas de Implementacion

### T1: Crear seccion "Context Summary Generation" en los flows
**Complejidad**: Medium

Agregar instruccion en `flows/full-cycle.md` y `flows/plan-execute.md`:

```
ANTES de spawneear cualquier worker:

Generar context_summary de la sesion actual:
  1. Revisar los mensajes del usuario en la conversacion
  2. Extraer:
     - Request original (1 linea)
     - Decisiones explicitas del usuario (backwards-compat, tecnologia, constraints)
     - Restricciones mencionadas (deadlines, versiones, dependencias)
     - Preferencias de sesion (minimalismo, agresividad, etc.)
  3. Formato: markdown, 5-10 lineas max
  4. NO incluir: historial completo, opiniones del agente, detalles tecnicos

Pasar context_summary como input adicional a cada worker.
```

### T2: Modificar `workers/planner.md` — aceptar context_summary
**Complejidad**: Low

Agregar a la seccion de inputs:

```yaml
inputs:
  - flow: string
  - insights: ...
  - learnings: string
  - context_summary: string   # NUEVO — decisiones clave de la sesion
  - compound_briefing: string
  - existing_specs: list
  - shaped_brief: string
```

Instruccion al planner:
```
Si context_summary contiene decisiones explicitas del usuario,
estas tienen PRIORIDAD sobre insights generales.
Ejemplo: si el usuario dijo "no nuevas dependencias" en la sesion,
no proponer nueva libreria aunque un insight lo sugiera.
```

### T3: Modificar `workers/implementer.md` — aceptar context_summary
**Complejidad**: Low

Agregar context_summary a inputs:

```yaml
inputs:
  - tasks: string
  - design: string
  - insights: ...
  - learnings: string
  - context_summary: string   # NUEVO
```

### T4: Modificar `workers/reviewer.md` — aceptar context_summary
**Complejidad**: Low

Agregar context_summary a inputs para que el reviewer verifique que las decisiones del usuario se respetaron:

```yaml
inputs:
  - diff: string
  - spec: string
  - design: string
  - insights: ...
  - context_summary: string   # NUEVO
```

Instruccion adicional al reviewer:
```
En la dimension de Correctness, verificar ademas que las decisiones
del context_summary se cumplieron. Ejemplo: si el usuario pidio
backwards-compatibility, verificar que no hay breaking changes.
```

### T5: Documentar el mecanismo
**Complejidad**: Low

En `CLAUDE.md`, agregar nota:
```
## Workers

Los workers reciben un context_summary de la sesion actual
que captura decisiones y restricciones del usuario.
Ver cada flow para detalles.
```

---

## Que NO es el Context Summary

- **No es** un historial de conversacion (demasiados tokens)
- **No es** un insight formal (es efimero, solo para esta sesion)
- **No es** obligatorio — si la conversacion no tiene decisiones notables, el summary es vacio
- **No persiste** entre sesiones

## Ejemplo

```
Conversacion:
  User: "Quiero agregar notificaciones push al app"
  User: "Usa Firebase, no OneSignal"
  User: "Tiene que funcionar offline tambien"
  User: "No toques el modulo de auth existente"

Context summary generado:
  ## Session Context
  - User requested: "Agregar notificaciones push al app"
  - Key decisions:
    - Usar Firebase Cloud Messaging (no OneSignal)
    - Debe funcionar en modo offline
  - Constraints:
    - No modificar modulo de auth existente

→ Planner recibe esto y diseña con FCM + offline queue
→ Reviewer verifica que auth no fue tocado
```

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| Summary mal generado (omite algo importante) | Es complementario, no reemplaza insights. Decisiones criticas deben estar en spec |
| Agrega tokens a cada worker | 5-10 lineas = ~100-200 tokens. Minimo comparado con el contexto total |
| El agente principal malinterpreta al usuario | El summary se genera desde mensajes textuales directos del usuario, no inferencias |

## Metricas de Exito

- Decisiones de sesion del usuario se reflejan en el output del planner
- El reviewer detecta si una decision de sesion fue violada
- Zero overhead significativo de tokens (<200 tokens por worker)
