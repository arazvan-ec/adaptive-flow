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
