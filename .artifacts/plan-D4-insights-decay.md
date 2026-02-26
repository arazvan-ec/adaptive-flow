# Plan D4: Mecanismo Real de Insights Decay

> Fecha: 2026-02-26
> Debilidad: El decay check es teorico — no hay mecanismo que cuente features completadas
> Impacto: Bajo-Medio
> Archivos afectados: 3

---

## Problema

El `compound-capture.md` dice:

```
Si last_validated tiene mas de 5 features de antiguedad:
  Marcar como stale
```

Pero **no existe un contador global de features completadas**. No hay forma de saber cuantas features han pasado desde que un insight fue validado. El decay nunca ocurre.

## Solucion Propuesta

Agregar un **feature counter** en `memory/meta.yaml` y un mecanismo de validacion real en compound-capture.

### Nuevo archivo: `memory/meta.yaml`

```yaml
# Meta-informacion del framework
# Se actualiza automaticamente al completar features

features_completed: 0
last_feature_slug: null
last_feature_date: null
```

---

## Tareas de Implementacion

### T1: Crear `memory/meta.yaml`
**Complejidad**: Low

Crear archivo con schema basico:

```yaml
features_completed: 0
last_feature_slug: null
last_feature_date: null
gravity_history: []  # [{ slug, gravity, date }] — ultimas 10
```

### T2: Modificar `skills/compound-capture.md` — incrementar counter + decay real
**Complejidad**: Medium

Al final del proceso de compound-capture:

```
Paso adicional post-capture:

1. Leer memory/meta.yaml
2. Incrementar features_completed += 1
3. Actualizar last_feature_slug y last_feature_date
4. Agregar a gravity_history (mantener ultimas 10)
5. Escribir memory/meta.yaml

6. DECAY CHECK REAL:
   Para cada insight en user-insights.yaml con status: active:
     features_since_validated = features_completed - insight.last_validated_at_feature
     Si features_since_validated > 5:
       Informar al usuario:
         "Insight '{id}' no se ha validado en {N} features.
          ¿Sigue siendo relevante? (Opciones: validar, pausar, retirar)"
```

### T3: Modificar schema de `memory/user-insights.yaml` — agregar `last_validated_at_feature`
**Complejidad**: Low

Agregar campo numerico a cada insight:

```yaml
- id: tdd-produces-better-code
  # ... campos existentes ...
  last_validated: 2026-02-26        # fecha (existente)
  last_validated_at_feature: 0      # NUEVO: feature count cuando se valido
```

Cuando un insight se aplica durante una feature (y el usuario confirma que fue util):
- Actualizar `last_validated` a la fecha actual
- Actualizar `last_validated_at_feature` al valor actual de `features_completed`

---

## Flujo de Decay

```
Feature 1: insight "tdd" se aplica → last_validated_at_feature = 1
Feature 2: insight "tdd" se aplica → last_validated_at_feature = 2
Feature 3-7: insight "tdd" NO se aplica
Feature 8: compound-capture detecta:
  features_since = 8 - 2 = 6 > 5
  → "Insight 'tdd-produces-better-code' no se ha validado en 6 features"
  → Usuario decide: validar (reset counter) | pausar | retirar
```

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| G1 tasks no ejecutan compound-capture | Considerar un lightweight counter en G1 direct.md tambien |
| Usuario ignora decay warnings | Maxing out a 1 warning por compound-capture (no spam) |
| Counter se desincroniza | meta.yaml es la unica fuente de verdad |

## Metricas de Exito

- `features_completed` se incrementa correctamente en cada compound-capture
- Insights sin validar en 5+ features generan un warning al usuario
- El usuario puede actuar sobre el warning (validar/pausar/retirar)
