# Fase 5: Registro de Decisiones

> Cada decision tomada con el usuario se documenta aqui.
> Formato: pregunta → respuesta → impacto en el plan

---

## Decisiones Tomadas

### D1: Dependencia de jq para hooks
**Pregunta**: El plan asume jq para reemplazar el escape JSON manual. ¿Requerir jq, usar Python, bash puro, o jq con fallback?
**Respuesta**: **Requerir jq** como dependencia.
**Impacto**: Track A simplificado. jq es la unica herramienta para JSON en hooks. Documentar como requisito en README y plugin.json. Eliminar fallback a grep para JSON parsing.

### D2: Agent Teams en v3 — solo evaluacion
**Pregunta**: Track D propone integrar Agent Teams para G3+. ¿Implementar, solo evaluar, o diferir a v4?
**Respuesta**: **Incluir en v3 como tarea de evaluacion** (solo disenar y documentar, no implementar).
**Impacto**: Track D tarea D4 cambia de "Disenar integracion" a "Evaluar y documentar viabilidad". Se reduce el esfuerzo de L a M. Se mantiene D5 (review multi-perspectiva con subagentes, no Agent Teams).

### D3: Cold start de memoria con datos reales del plugin
**Pregunta**: Como llenar la memoria vacia (learnings, patterns). ¿Datos reales del plugin, ficticios, auto-seed en primer uso, o ambos?
**Respuesta**: **Datos reales del plugin** — extraer learnings y patterns del desarrollo v1→v2.
**Impacto**: Track B tarea B1 se enfoca en analizar el historial git y las decisiones tomadas en PLAN.md/TASKLIST.md para extraer learnings concretos (ej: "hooks.json centralizado > hooks individuales", "CLAUDE.md slim mejora routing").

### D4: Testing de hooks con bats-core + shellcheck
**Pregunta**: Como testear los 5 hooks bash del plugin (quality gates automaticos).
**Respuesta**: **bats-core + shellcheck** — tests funcionales que verifican outputs JSON + analisis estatico.
**Impacto**: Track F usa bats-core como framework. Dependencia de desarrollo (no runtime). Cada hook tendra tests que verifican JSON output con inputs mock. shellcheck como lint obligatorio.

### D5: Analisis de diseno pluggable completo (no solo SOLID)
**Pregunta**: SOLID es el unico framework de analisis de diseno. ¿Mantener, agregar hints, hacerlo pluggable, o eliminar?
**Respuesta**: **Pluggable completo** — detectar paradigma y aplicar framework diferente.
**Impacto**: Track E tarea E3 crece en alcance. Necesita: (1) detectar paradigma del proyecto via discover/architect profile, (2) crear guias core alternativas (ej: core/fp-principles.md, core/component-architecture.md), (3) modificar planner y reviewer para usar el framework detectado, (4) renombrar solid-analyzer a design-analyzer con modo por paradigma. Esfuerzo sube de M a L.

### D6: Review multi-perspectiva configurable por gravedad
**Pregunta**: Cuantas perspectivas de review paralelo. EveryInc usa 12 (costoso).
**Respuesta**: **Configurable por gravedad** — G3: 4 perspectivas basicas (correctness, design compliance, code quality, security). G4: 6 perspectivas (+performance, +over-engineering).
**Impacto**: Track D tarea D5 se implementa con configuracion por gravedad. El reviewer skill recibe un parametro de perspectivas segun gravity de meta.yaml. Cada perspectiva es un subagente paralelo que produce un sub-report, luego se sintetizan en un QA report unificado.

### D7: Alcance de v3 — Todos los tracks, validar entre tracks
**Pregunta**: Implementar las 31 tareas en v3 o seleccionar subset.
**Respuesta inicial**: Tracks A+B+F primero, resto para v4.
**Respuesta actualizada**: **Todos los 6 tracks planificados en v3** (45 tareas atomicas). Antes de pasar de un track al siguiente, validar con el usuario.
**Impacto**: v3 incluye los 6 tracks completos (F:9 + A:10 + B:8 + C:6 + D:6 + E:6 = 45 tareas). Orden recomendado: F primero → A+B+C+E en paralelo → D al final. El usuario decide cuando avanzar entre tracks.

---

## Decisiones Pendientes

(Ninguna — todas las dudas criticas resueltas)
