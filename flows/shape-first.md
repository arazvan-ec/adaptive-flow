# Flow: Shape First (Gravedad 4)

Descubrimiento antes de planificar. Para tareas con scope ambiguo o incertidumbre tecnica.

## Cuando

- Scope no esta claro
- Requiere investigacion tecnica
- Multiples approaches posibles
- Reestructuracion o migracion significativa

## Proceso

```
SHAPING
1. Cargar insights (planning + design)
2. → Worker: researcher (analisis)
   Pregunta: "Cual es el scope real? Cuantos archivos? Que dependencies?"
   Produce: analysis report

3. Shaped brief:
   - Frame: problema a resolver + constraints
   - Shape: approach seleccionado + justificacion
   - Slices: division en incrementos entregables

4. HITL: "El scope es correcto? El approach tiene sentido?"

FULL CYCLE
5. → Ejecutar flow full-cycle.md con shaped brief como input adicional
   El planner recibe el shaped brief ademas de sus inputs normales
```

## Artefactos

Directorio `openspec/changes/{slug}/`:

```
shaped-brief.md  # Frame + shape + slices (PRE-planificacion)
spec.md          # Del full-cycle flow
design.md        # Del full-cycle flow
tasks.md         # Del full-cycle flow
retrospective.md # Del full-cycle flow
```

### Formato del Shaped Brief

```markdown
# Shaped Brief: {Feature Name}

## Frame
- **Problema**: {Que problema resolvemos}
- **Constraints**: {Limites de tiempo, tecnologia, compatibilidad}
- **No-gos**: {Que explicitamente NO vamos a hacer}

## Shape
- **Approach**: {Approach seleccionado}
- **Alternativas descartadas**: {Y por que}
- **Riesgos identificados**: {Y mitigaciones}

## Slices
1. {Slice 1}: {Descripcion} — {Estimacion de archivos}
2. {Slice 2}: {Descripcion} — {Estimacion de archivos}
3. {Slice 3}: {Descripcion} — {Estimacion de archivos}
```

## Workers

| Worker | Modo | Contexto |
|--------|------|----------|
| researcher | analisis profundo | Pregunta especifica + file paths relevantes |
| planner | completo | shaped-brief.md + todo lo de full-cycle |
| implementer | TDD+BCP | Todo lo de full-cycle |
| reviewer | multi-dim | Todo lo de full-cycle |

## HITL Checkpoints

1. Post-shaping: confirmar scope y approach antes de planificar
2. Post-plan: confirmar specs y diseno (heredado de full-cycle)
3. Post-review si REJECTED (heredado de full-cycle)

## Diferencia clave con Gravedad 3

Gravedad 3 asume que el scope es claro. Gravedad 4 invierte tiempo en
**descubrir** el scope correcto antes de planificar. Esto evita planificar
sobre supuestos incorrectos.

## Ejemplo

```
Usuario: "Reestructura el modulo de billing para soportar multiples providers"
→ Gravedad 4 (scope ambiguo, multiples approaches)
→ Researcher: analizar billing actual, dependencies, surface area
→ Shaped brief: frame (problema) + shape (adapter pattern) + slices (3 incrementos)
→ HITL: confirmar scope
→ Full cycle: spec → design → tasks → implement → review → compound
→ Commit
```
