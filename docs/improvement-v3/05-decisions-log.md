# Fase 5: Registro de Decisiones

> Cada decision tomada con el usuario se documenta aqui.
> Formato: pregunta → respuesta → impacto en el plan

---

## Decisiones Pendientes

(Se iran resolviendo una por una)

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
