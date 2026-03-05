# Fase 2: Mejoras Identificadas

> Fecha: 2026-03-05 | Basado en analisis de 01-analysis.md

---

## Resumen Ejecutivo

Se identifican **28 mejoras** agrupadas en 7 categorias. Se priorizan por impacto (alto/medio/bajo) y esfuerzo (S/M/L).

---

## A. Gaps Funcionales

### A1. P2-3 nunca se completo: Guide triggers incompletos
**Impacto**: Medio | **Esfuerzo**: S

`pre-write-guard.sh` detecta patrones de archivos (auth, API, test) y sugiere guias core, pero el TASKLIST.md marca P2-3 como "No en vivo". Las detecciones estan implementadas pero no probadas en produccion. Faltan:
- Deteccion de archivos de auth/security mas granular
- Deteccion de archivos controller/route/api
- Deteccion de archivos .test./.spec.

**Mejora**: Completar y probar los triggers de Tier 3 que ya estan parcialmente codificados.

### A2. Memoria siempre vacia (compound nunca ejecutado en proyecto real)
**Impacto**: Alto | **Esfuerzo**: M

`learnings.yaml`, `patterns.yaml` y `discovered-insights.yaml` estan vacios. El sistema compound nunca se ha ejecutado en un proyecto real. Esto significa que:
- El briefing para proxima tarea no existe
- Los learnings no informan decisions de planning
- Los patterns no se reutilizan
- El decay check de insights nunca se activa

**Mejora**: Crear un mecanismo de "cold start" que genere learnings iniciales basados en el propio desarrollo del plugin, o incluir datos de ejemplo reales.

### A3. Framework analysis desactualizado
**Impacto**: Bajo | **Esfuerzo**: S

`memory/framework-analysis.md` refleja v1.0.0 con el plan al 50%. Ahora estamos en v2.0.0 con 100% completado. Deberia eliminarse o actualizarse.

**Mejora**: Eliminar o reemplazar con una referencia a `docs/improvement-v3/01-analysis.md`.

---

## B. Robustez de Hooks

### B1. Parsing YAML con bash es fragil
**Impacto**: Alto | **Esfuerzo**: M

Los hooks usan `python3 -c "import yaml..."` con fallback a `grep`. Problemas:
- Depende de que `python3` Y el modulo `yaml` esten instalados
- El fallback grep no maneja YAML multilinea, strings con comillas, ni caracteres especiales
- El escape JSON manual con `sed` y `tr` es propenso a errores con contenido inesperado
- Hay codigo duplicado: session-init.sh y post-compact.sh tienen la misma logica de parseo

**Mejora**: Usar un parser robusto (jq para JSON, yq para YAML) o empaquetar un script Python standalone con manejo de errores. Alternativamente, pre-compilar el YAML a JSON al inicio.

### B2. Escape JSON manual propenso a errores
**Impacto**: Medio | **Esfuerzo**: S

Todos los hooks que producen `additionalContext` hacen escape manual:
```bash
ESCAPED=$(echo "$COMBINED" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
```
Esto puede fallar con: tabs, caracteres unicode, nulls, newlines embebidos en valores YAML.

**Mejora**: Usar `jq -n --arg ctx "$COMBINED" '{additionalContext: $ctx}'` para generar JSON seguro.

### B3. pre-write-guard.sh extrae file_path con grep fragil
**Impacto**: Medio | **Esfuerzo**: S

```bash
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' ...)
```
Esto falla si el JSON tiene newlines, si file_path tiene caracteres escapados, o si el campo esta anidado.

**Mejora**: Usar `jq -r '.file_path // .input.file_path // empty'` para parsear JSON correctamente.

### B4. stop-check.sh: contador de bloqueos en archivo, no en sesion
**Impacto**: Bajo | **Esfuerzo**: S

El counter file (`.stop-block-count`) persiste en `memory/current-task/`. Si la sesion se cierra y abre de nuevo, el contador no se resetea. Puede causar que el hook permita stop prematuramente en una nueva sesion.

**Mejora**: Incluir timestamp o session ID en el counter para distinguir sesiones.

### B5. Codigo duplicado entre hooks
**Impacto**: Medio | **Esfuerzo**: M

`session-init.sh` y `post-compact.sh` tienen logica identica para:
- Parsear insights de alta influencia
- Cargar task meta
- Generar JSON de salida

**Mejora**: Extraer funciones comunes a un archivo `hooks/lib.sh` y hacer `source` desde cada hook.

---

## C. UX del Plugin

### C1. No hay feedback visible del routing
**Impacto**: Medio | **Esfuerzo**: S

Cuando Claude clasifica una tarea como gravedad N, el usuario no ve esta decision. Solo se entera si algo sale mal. No hay transparencia sobre por que se eligio un flow.

**Mejora**: Hacer que Claude comunique al usuario la gravedad clasificada y la razon, antes de ejecutar el flow.

### C2. Onboarding requiere conocimiento previo
**Impacto**: Medio | **Esfuerzo**: M

El README.md dice "Just ask Claude to do something" pero:
- No hay guia de que pasa si los hooks fallan
- No hay troubleshooting
- No explica como saber si el plugin se activo correctamente
- No menciona requisitos (python3, yaml module)

**Mejora**: Agregar seccion de troubleshooting y requisitos al README.

### C3. Skills invocables no tienen `--help`
**Impacto**: Bajo | **Esfuerzo**: S

No hay forma de que el usuario vea opciones disponibles sin leer el SKILL.md. Un `--help` inline mejoraria la descubribilidad.

**Mejora**: Documentar opciones inline como primer parrafo del SKILL.md o crear un skill `help`.

### C4. No hay mecanismo de "dry run"
**Impacto**: Medio | **Esfuerzo**: M

No se puede ver que haria el plugin sin ejecutarlo. Util para:
- Verificar que el routing es correcto
- Pre-visualizar que artefactos se crearian
- Debug de problemas

**Mejora**: Agregar opcion `--dry-run` o skill de diagnostico que muestre el flow que se ejecutaria.

---

## D. Sistema de Memoria

### D1. No hay versionado de memoria
**Impacto**: Medio | **Esfuerzo**: M

Si un insight se retira o modifica, no hay historial. Si un learning resulta incorrecto, no hay rollback.

**Mejora**: Mantener un changelog en cada archivo YAML o usar git diff como historial natural.

### D2. Insights starter son genericos
**Impacto**: Medio | **Esfuerzo**: S

Los 8 insights iniciales son universales ("TDD produces better code", "small functions"). No estan adaptados al stack del usuario.

**Mejora**: Hacer que `discover --seed` reemplace los insights genericos con insights especificos al stack. O marcar los starter como `influence: low` por defecto hasta que el usuario los valide.

### D3. No hay mecanismo de busqueda en memoria
**Impacto**: Bajo | **Esfuerzo**: M

Con muchos learnings/patterns, no hay forma de buscar por tag, fecha, o relevancia. Solo se puede leer el archivo completo.

**Mejora**: Agregar filtrado en `insights-manager --list --tag=security` o similar.

### D4. next-briefing.md se sobreescribe
**Impacto**: Bajo | **Esfuerzo**: S

Cada compound-capture sobreescribe `next-briefing.md`. El briefing anterior se pierde.

**Mejora**: Acumular briefings o guardar historico en un directorio `memory/briefings/`.

---

## E. Integracion con Claude Code

### E1. No usa MCP servers
**Impacto**: Alto | **Esfuerzo**: L

Claude Code soporta MCP (Model Context Protocol) servers. El plugin podria exponer la memoria como un MCP server, permitiendo queries estructuradas en lugar de cargar archivos.

**Mejora**: Crear un MCP server para la memoria del plugin (insights, learnings, patterns).

### E2. No usa custom slash commands nativos
**Impacto**: Medio | **Esfuerzo**: M

Los skills invocables (`/adaptive-flow:compound-capture`) dependen de que Claude descubra los SKILL.md. Claude Code ahora soporta custom slash commands nativos que son mas rapidos y confiables.

**Mejora**: Evaluar migracion a slash commands nativos si la API lo soporta.

### E3. Hooks no aprovechan PreToolUse para mas herramientas
**Impacto**: Medio | **Esfuerzo**: S

Solo se intercepta Write|Edit. Podria ser util interceptar:
- Bash (para detectar comandos peligrosos como `rm -rf`, `DROP TABLE`)
- Agent (para inyectar contexto a subagentes)
- WebFetch (para logging de recursos externos consultados)

**Mejora**: Agregar hooks para Bash y Agent cuando sea beneficioso.

### E4. No hay integracion con git hooks nativos
**Impacto**: Bajo | **Esfuerzo**: S

El plugin menciona "pre-commit" y "post-commit" pero no instala git hooks reales. El hook stop-check verifica compound-capture pero no hay validacion pre-commit real.

**Mejora**: Opcional: integrar con husky/lefthook para quality gates a nivel git.

---

## F. Calidad del Contenido

### F1. Guias core son genericas
**Impacto**: Medio | **Esfuerzo**: M

Las 4 guias (SOLID, API, Testing, Security) suman 401 lineas de contenido generico. No mencionan el stack del proyecto ni ejemplos concretos.

**Mejora**: Hacer que `discover --seed` genere guias adaptadas al stack, o permitir que el usuario las personalice. Alternativamente, dividir en "core principles" (siempre) + "stack-specific practices" (generadas).

### F2. Templates no son adaptativos
**Impacto**: Bajo | **Esfuerzo**: S

Los templates (spec, design, tasks, retrospective) son identicos para cualquier proyecto. Podrian adaptarse al stack detectado.

**Mejora**: Templates con secciones opcionales segun el tipo de proyecto (frontend, backend, fullstack, CLI).

### F3. SOLID reference monopoliza el analisis de diseno
**Impacto**: Medio | **Esfuerzo**: M

Todo el analisis de diseno gira en torno a SOLID. Esto es valido para OOP pero limita para:
- Functional programming (composition over inheritance)
- Microservices (bounded contexts, saga patterns)
- Frontend (component architecture, state management)
- Data engineering (pipeline patterns)

**Mejora**: Hacer el framework de analisis de diseno pluggable: SOLID para OOP, otros principios para otros paradigmas.

---

## G. Arquitectura del Plugin

### G1. No hay tests del plugin
**Impacto**: Alto | **Esfuerzo**: M

Los hooks son scripts bash sin tests. Los skills son markdown sin verificacion. No hay forma automatizada de saber si un cambio rompe el plugin.

**Mejora**: Crear tests para hooks (bats o shellcheck + test scripts) y validacion de estructura para skills (schema validation).

### G2. No hay CI/CD
**Impacto**: Medio | **Esfuerzo**: M

No hay GitHub Actions ni similar. Los hooks podrian tener errores de sintaxis sin que nadie se entere.

**Mejora**: GitHub Actions con shellcheck, YAML validation, y markdown lint.

### G3. Skills no tienen schema de validacion
**Impacto**: Medio | **Esfuerzo**: M

Los skills definen inputs/outputs en markdown pero no hay validacion real. Un skill podria no recibir el contexto esperado sin error.

**Mejora**: Definir un JSON Schema para los inputs/outputs de cada skill.

### G4. plugin.json es minimalista
**Impacto**: Bajo | **Esfuerzo**: S

Solo tiene name, version, description. No define:
- Requisitos (python3, yaml module)
- Compatibilidad con versiones de Claude Code
- Licencia
- Author

**Mejora**: Enriquecer metadata del plugin.

---

## Matriz de Priorizacion

| ID | Mejora | Impacto | Esfuerzo | Prioridad |
|----|--------|---------|----------|-----------|
| A2 | Cold start de memoria | Alto | M | **1** |
| B1 | Parser YAML robusto | Alto | M | **2** |
| G1 | Tests del plugin | Alto | M | **3** |
| E1 | MCP server para memoria | Alto | L | **4** |
| B2 | Escape JSON con jq | Medio | S | **5** |
| B3 | Parse JSON con jq | Medio | S | **5** |
| B5 | Extraer lib.sh comun | Medio | M | **6** |
| C1 | Feedback visible del routing | Medio | S | **7** |
| C4 | Dry run / diagnostico | Medio | M | **8** |
| F3 | Analisis de diseno pluggable | Medio | M | **9** |
| D2 | Insights starter adaptivos | Medio | S | **10** |
| G2 | CI/CD con GitHub Actions | Medio | M | **11** |
| E3 | Hooks para mas herramientas | Medio | S | **12** |
| A1 | Completar guide triggers | Medio | S | **13** |
| C2 | Onboarding y troubleshooting | Medio | M | **14** |
| F1 | Guias core adaptativas | Medio | M | **15** |
| E2 | Slash commands nativos | Medio | M | **16** |
| G3 | Schema de validacion para skills | Medio | M | **17** |
| D1 | Versionado de memoria | Medio | M | **18** |
| D4 | Historial de briefings | Bajo | S | **19** |
| B4 | Counter de stop con session ID | Bajo | S | **20** |
| A3 | Limpiar framework-analysis.md | Bajo | S | **21** |
| C3 | --help en skills | Bajo | S | **22** |
| F2 | Templates adaptativos | Bajo | S | **23** |
| G4 | Plugin.json enriquecido | Bajo | S | **24** |
| E4 | Git hooks nativos | Bajo | S | **25** |
| D3 | Busqueda en memoria | Bajo | M | **26** |
| E1 | MCP server (alternativa) | Alto | L | **27** |
