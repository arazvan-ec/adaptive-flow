# Fase 4: Plan de Implementacion por Fases Paralelas

> Estado: `DRAFT` | Ultima actualizacion: 2026-03-05
> Pendiente de validacion en Fase 5

---

## Estructura: 6 Tracks Independientes

Cada track es **implementable en paralelo** con los demas. Dentro de cada track, las tareas son secuenciales. Esto permite que multiples sesiones de Claude Code trabajen en tracks diferentes simultaneamente.

```
Track A: Robustez Hooks ─────────────────────►
Track B: Sistema de Memoria ─────────────────►
Track C: UX y Onboarding ───────────────────►
Track D: Integracion Claude Code ────────────►
Track E: Contenido y Guias ──────────────────►
Track F: Testing y CI/CD ───────────────────►
                                              ▼
                                        Integracion Final
```

### Dependencias entre tracks

```
Track F (Testing) ← debe ir primero o en paralelo, para validar cambios de otros tracks
Track A (Hooks) ← Track D depende parcialmente (nuevos eventos de hooks)
Track B (Memoria) ← independiente
Track C (UX) ← independiente
Track E (Contenido) ← independiente
```

---

## Track A: Robustez de Hooks

> **Objetivo**: Hacer los hooks confiables, mantenibles y robustos
> **Mejoras cubiertas**: B1, B2, B3, B4, B5 de 02-improvements.md
> **Impacto**: Alto | **Esfuerzo total**: M

### A1. Extraer libreria comun hooks/lib.sh
**Esfuerzo**: S | **Archivos**: `hooks/lib.sh` (nuevo)
- Extraer funciones compartidas: parse_yaml_insights(), generate_json_context(), parse_json_input()
- session-init.sh y post-compact.sh usan la misma logica de parseo de insights

### A2. Reemplazar escape JSON manual con jq
**Esfuerzo**: S | **Archivos**: todos los hooks (5 scripts)
- Cambiar `sed/tr` escape manual por `jq -n --arg ctx "$COMBINED" '{additionalContext: $ctx}'`
- Requiere: verificar que jq esta disponible, o incluir fallback

### A3. Reemplazar parse JSON con jq en pre-write-guard.sh
**Esfuerzo**: S | **Archivos**: `hooks/pre-write-guard.sh`, `hooks/post-write-check.sh`
- Cambiar grep de file_path por `jq -r '.file_path // .input.file_path // empty'`

### A4. Mejorar parser YAML con fallback robusto
**Esfuerzo**: M | **Archivos**: `hooks/lib.sh`
- Intentar python3+yaml → yq → grep (3 niveles de fallback)
- Documentar requisitos minimos en README

### A5. Arreglar counter de stop-check.sh con session ID
**Esfuerzo**: S | **Archivos**: `hooks/stop-check.sh`
- Incluir timestamp o session ID en counter file para distinguir sesiones

### A6. Refactorizar hooks para usar lib.sh
**Esfuerzo**: M | **Archivos**: `hooks/session-init.sh`, `hooks/post-compact.sh`
- Reemplazar codigo duplicado con llamadas a funciones de lib.sh

---

## Track B: Sistema de Memoria

> **Objetivo**: Hacer la memoria funcional, queryable y con cold start
> **Mejoras cubiertas**: A2, D1, D2, D4 de 02-improvements.md + best practices de memoria
> **Impacto**: Alto | **Esfuerzo total**: L

### B1. Cold start: generar datos iniciales de memoria
**Esfuerzo**: M | **Archivos**: `memory/learnings.yaml`, `memory/patterns.yaml`
- Crear learnings basados en el desarrollo del propio plugin (v1→v2)
- Crear patterns basados en patrones reales usados en el plugin
- Dar vida al sistema compound con datos reales

### B2. Adaptar insights starter al contexto
**Esfuerzo**: S | **Archivos**: `memory/user-insights.yaml`, `skills/discover/SKILL.md`
- Marcar insights genericos como `influence: low` por defecto
- Que discover --seed los reemplace con insights especificos al stack

### B3. Historial de briefings
**Esfuerzo**: S | **Archivos**: `skills/compound-capture/SKILL.md`
- En vez de sobreescribir next-briefing.md, mover el anterior a memory/briefings/{date}.md
- Crear directorio memory/briefings/

### B4. Clasificar memoria por taxonomia
**Esfuerzo**: M | **Archivos**: documentacion + restructuracion de memory/
- Aplicar taxonomia: episodic (briefings, retrospectives), semantic (learnings, patterns), entity (user-insights)
- Documentar que tipo es cada archivo y como se usa

### B5. Implementar decay gradual
**Esfuerzo**: M | **Archivos**: `skills/compound-capture/SKILL.md`, `skills/insights-manager/SKILL.md`
- TTL por tipo de memoria: insights (validar cada 5 features), learnings (decay a 90 dias), patterns (sin decay)
- Automatizar en compound-capture

---

## Track C: UX y Onboarding

> **Objetivo**: Mejorar la experiencia del usuario y la descubribilidad
> **Mejoras cubiertas**: C1, C2, C3, C4, G4 de 02-improvements.md
> **Impacto**: Medio | **Esfuerzo total**: M

### C1. Feedback visible del routing
**Esfuerzo**: S | **Archivos**: `CLAUDE.md`, `flows/*.md`
- Agregar instruccion en CLAUDE.md: "Al clasificar, comunicar al usuario: Gravedad N porque X"
- Breve, una linea antes de ejecutar el flow

### C2. Seccion de troubleshooting en README
**Esfuerzo**: S | **Archivos**: `README.md`
- Requisitos: python3 + yaml module (o jq tras Track A)
- Como verificar que el plugin se activo
- Errores comunes y soluciones

### C3. Enriquecer plugin.json
**Esfuerzo**: S | **Archivos**: `.claude-plugin/plugin.json`
- Agregar: author, license, requirements, claude_code_version_min

### C4. Skill de diagnostico / dry-run
**Esfuerzo**: M | **Archivos**: `skills/diagnostics/SKILL.md` (nuevo)
- `/adaptive-flow:diagnostics` muestra: gravedad estimada, flow que se ejecutaria, insights que se aplicarian, estado de la memoria
- Util para debug y verificacion

### C5. Agregar --help a skills invocables
**Esfuerzo**: S | **Archivos**: `skills/*/SKILL.md` (4 invocables)
- Primer parrafo de cada SKILL.md como help inline

---

## Track D: Integracion con Claude Code Moderno

> **Objetivo**: Aprovechar features nuevas de Claude Code (2026)
> **Mejoras cubiertas**: E1, E2, E3 de 02-improvements.md + best practices de hooks y Agent Teams
> **Impacto**: Alto | **Esfuerzo total**: L

### D1. Usar CLAUDE_ENV_FILE para persistir estado de sesion
**Esfuerzo**: S | **Archivos**: `hooks/session-init.sh`
- Usar CLAUDE_ENV_FILE para variables de sesion en vez de archivos temporales
- Persistir: gravity, flow activo, task name

### D2. Agregar hooks para eventos nuevos
**Esfuerzo**: M | **Archivos**: `hooks/hooks.json`, scripts nuevos
- SubagentStart: inyectar contexto relevante a subagentes (insights, task meta)
- PostToolUseFailure: reaccionar a fallos de tools (logging, sugerencias)
- TaskCompleted: trigger para actualizar estado

### D3. Evaluar Prompt hooks para pre-write-guard
**Esfuerzo**: M | **Archivos**: `hooks/pre-write-guard.sh` o nuevo prompt hook
- En vez de pattern matching con grep, usar evaluacion semantica
- Decidir: prompt hook vs command hook mejorado

### D4. Disenar integracion con Agent Teams para G3+
**Esfuerzo**: L | **Archivos**: `flows/full-cycle.md`, `flows/shape-first.md`
- Evaluar: planner + implementer + reviewer como teammates
- Disenar shared task list y coordinacion
- Solo para gravedad 3+, donde el paralelismo tiene sentido

### D5. Review multi-perspectiva (inspirado en EveryInc)
**Esfuerzo**: L | **Archivos**: `skills/reviewer/SKILL.md`
- Dividir reviewer monolitico en sub-reviews paralelos
- Perspectivas: security, performance, SOLID, over-engineering, tests, API consistency
- Sintetizar resultados en un QA report unificado

---

## Track E: Contenido y Guias

> **Objetivo**: Hacer el contenido adaptativo y mas util
> **Mejoras cubiertas**: F1, F2, F3, A1, A3 de 02-improvements.md
> **Impacto**: Medio | **Esfuerzo total**: M

### E1. Completar guide triggers (P2-3 pendiente)
**Esfuerzo**: S | **Archivos**: `hooks/pre-write-guard.sh`
- Completar y probar detecciones de auth/security, controller/route/api, test files
- Verificar que additionalContext se inyecta correctamente

### E2. Limpiar framework-analysis.md obsoleto
**Esfuerzo**: S | **Archivos**: `memory/framework-analysis.md`
- Eliminar o reemplazar con referencia a docs/improvement-v3/01-analysis.md

### E3. Hacer analisis de diseno pluggable
**Esfuerzo**: M | **Archivos**: `skills/solid-analyzer/SKILL.md`, `core/`
- Mantener SOLID como default para OOP
- Agregar principios alternativos: composicion (FP), bounded contexts (microservices), component architecture (frontend)
- El analyzer detecta el paradigma y aplica el framework correcto

### E4. Templates adaptativos por tipo de proyecto
**Esfuerzo**: S | **Archivos**: `templates/*.md`
- Agregar secciones opcionales segun tipo (frontend, backend, fullstack, CLI)
- Marcadas con condicionales: "Si el proyecto es frontend, incluir..."

### E5. Verificar closed compound loop
**Esfuerzo**: S | **Archivos**: `flows/plan-execute.md`, `flows/full-cycle.md`
- Verificar que planner y reviewer leen learnings.yaml y patterns.yaml
- Si no, agregar instrucciones explicitas de lectura

---

## Track F: Testing y CI/CD

> **Objetivo**: Asegurar que el plugin no se rompe con cambios
> **Mejoras cubiertas**: G1, G2, G3 de 02-improvements.md
> **Impacto**: Alto | **Esfuerzo total**: M

### F1. Shellcheck para todos los hooks
**Esfuerzo**: S | **Archivos**: todos los hooks
- Correr shellcheck y corregir warnings
- Agregar como pre-commit check

### F2. Tests funcionales para hooks (bats)
**Esfuerzo**: M | **Archivos**: `tests/` (nuevo directorio)
- Tests con bats-core para cada hook
- Mocks para YAML files, JSON input, environment variables
- Verificar outputs JSON validos

### F3. Validacion de estructura de skills
**Esfuerzo**: S | **Archivos**: `tests/validate-skills.sh` (nuevo)
- Verificar que todos los SKILL.md tienen frontmatter correcto
- Verificar que context: fork y allowed-tools estan presentes

### F4. GitHub Actions CI
**Esfuerzo**: M | **Archivos**: `.github/workflows/ci.yml` (nuevo)
- shellcheck para hooks
- YAML validation para memory files
- Markdown lint
- Tests bats
- Schema validation para skills

### F5. Validacion YAML de archivos de memoria
**Esfuerzo**: S | **Archivos**: `tests/validate-memory.sh` (nuevo)
- Verificar que todos los YAML son validos
- Verificar schemas (campos requeridos, tipos)

---

## Resumen de Tracks

| Track | Tareas | Esfuerzo | Impacto | Dependencias |
|-------|--------|----------|---------|--------------|
| A: Hooks | 6 | M | Alto | Ninguna |
| B: Memoria | 5 | L | Alto | Ninguna |
| C: UX | 5 | M | Medio | Ninguna |
| D: Claude Code | 5 | L | Alto | Parcial de A (hooks) |
| E: Contenido | 5 | M | Medio | Ninguna |
| F: Testing | 5 | M | Alto | Idealmente primero |

**Total tareas**: 31
**Recomendacion de orden**: F (testing) primero/paralelo → A + B + C + E en paralelo → D al final

---

## Criterio de Completitud por Track

- **Track completo** cuando: todas las tareas implementadas, tests pasan (si aplica), documentacion actualizada
- **Tarea completa** cuando: codigo implementado, probado, documentado en commit message
- **Integracion final**: verificar que todos los tracks funcionan juntos, actualizar CLAUDE.md/README si necesario, bumpar version en plugin.json
