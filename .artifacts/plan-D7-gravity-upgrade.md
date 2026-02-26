# Plan D7: Recovery de Misclassification — Gravity Upgrade Mid-Flight

> Fecha: 2026-02-26
> Debilidad: Si se clasifica G1 y resulta ser G3, no hay mecanismo de upgrade
> Impacto: Medio
> Archivos afectados: 3-4

---

## Problema

Escenario real:
1. Usuario pide "agregar campo a UserDTO"
2. Router clasifica G1 (1 archivo, cambio claro)
3. Durante implementacion se descubre que:
   - El campo necesita migracion de DB
   - Hay 3 servicios que consumen el DTO
   - Hay validacion en 2 controllers
   - Tests en 4 archivos
4. El cambio termina tocando 10+ archivos
5. Se ejecuto sin plan, sin review, sin compound — como si fuera trivial

**El framework no tiene mecanismo para "subir" la gravedad mid-flight.**

## Solucion Propuesta

Agregar **checkpoints de re-evaluacion** durante la ejecucion que detecten cuando la gravedad real supera la clasificada.

### Mecanismo: Gravity Checkpoint

```
Durante ejecucion (cualquier gravedad):
  Cada vez que se modifica un archivo:
    archivos_modificados += 1

  Si archivos_modificados > threshold[gravedad_actual]:
    PAUSA
    "⚠ Se han modificado {N} archivos, mas de lo esperado para gravedad {G}.
     Sugerencia: upgrade a gravedad {G+1}.
     ¿Deseas continuar con G{G} o upgrade a G{G+1}?"

  Si el usuario acepta upgrade:
    - Guardar progreso actual
    - Re-ejecutar con el flow de la nueva gravedad
    - Los archivos ya modificados se mantienen
```

---

## Tareas de Implementacion

### T1: Definir thresholds por gravedad
**Complejidad**: Low

Crear seccion en `core/routing-analysis.md` (o el archivo del plan D6):

```yaml
gravity_thresholds:
  1:
    max_files: 3
    upgrade_to: 2
    trigger: "Se detectaron mas de 3 archivos modificados"
  2:
    max_files: 8
    upgrade_to: 3
    trigger: "Se detectaron mas de 8 archivos modificados"
  3:
    max_files: null  # G3 ya es full-cycle, no necesita upgrade
    upgrade_to: null
```

### T2: Modificar `flows/direct.md` (G1) — agregar checkpoint
**Complejidad**: Medium

Despues del paso "Ejecutar el cambio directamente", agregar:

```
2b. GRAVITY CHECKPOINT:
    Si durante la ejecucion se modifican > 3 archivos:
      PAUSA — preguntar al usuario:
      "Este cambio esta afectando {N} archivos (mas de los 3 esperados para G1).
       Opciones:
       a) Upgrade a G2: crear plan ligero y continuar con estructura
       b) Continuar como G1: si estas seguro de que el scope es correcto
       c) Abort: parar y re-evaluar"

    Si upgrade a G2:
      - Crear .artifacts/plan-and-tasks.md con lo ya hecho + lo pendiente
      - Continuar con flow plan-execute.md desde el paso de implementation
```

### T3: Modificar `flows/plan-execute.md` (G2) — agregar checkpoint
**Complejidad**: Medium

Despues de la implementacion, verificar:

```
5b. GRAVITY CHECKPOINT:
    Si archivos modificados > 8 o se detectan capas no previstas en el plan:
      PAUSA — preguntar al usuario:
      "La implementacion esta superando el scope de G2 ({N} archivos, capas no previstas).
       Opciones:
       a) Upgrade a G3: crear spec/design formales y pasar a full-cycle con review
       b) Continuar como G2: si el scope adicional es manejable
       c) Abort: parar y re-evaluar"

    Si upgrade a G3:
      - Crear .artifacts/spec.md + design.md basados en lo ya implementado
      - Continuar con full-cycle.md desde el paso de review
```

### T4: Documentar el mecanismo en `CLAUDE.md`
**Complejidad**: Low

Agregar una linea al routing:

```
## Gravity Upgrade

Si durante la ejecucion el scope real supera el esperado, el framework
sugiere upgrade de gravedad. El usuario decide si aceptar.
Ver thresholds en core/routing-analysis.md.
```

---

## Flujo Visual

```
G1 (direct) ──── checkpoint (>3 files?) ──── ¿upgrade? ──► G2 (plan-execute)
                       │ no                        │
                       ▼                           │
                    continuar                      │
                                                   │
G2 (plan-execute) ── checkpoint (>8 files?) ── ¿upgrade? ──► G3 (full-cycle)
                       │ no                        │
                       ▼                           │
                    continuar                      │
                                                   │
G3 (full-cycle) ── no checkpoint (ya es full)      │
```

## Que pasa con el progreso ya hecho

| Upgrade | Se preserva | Se agrega |
|---------|------------|-----------|
| G1 → G2 | Archivos ya modificados | Plan retrospectivo + tasks pendientes |
| G2 → G3 | Archivos + plan existente | Spec formal + design + review |
| G1 → G3 | Archivos ya modificados | Todo el ciclo formal |

**Nunca se pierde trabajo.** El upgrade agrega estructura, no borra progreso.

## Riesgos

| Riesgo | Mitigacion |
|--------|-----------|
| Interrumpir al usuario con upgrades frecuentes | Solo 1 checkpoint por ejecucion; threshold es conservador |
| El upgrade mid-flight es disruptivo | El usuario siempre decide; opcion "continuar como esta" disponible |
| Contar archivos es simplista | Es un proxy. Complementar con deteccion de capas si D6 esta implementado |

## Metricas de Exito

- Misclassifications se detectan y se ofrecen upgrades
- El usuario nunca termina con un cambio de G3 ejecutado como G1
- Zero trabajo perdido durante upgrades
