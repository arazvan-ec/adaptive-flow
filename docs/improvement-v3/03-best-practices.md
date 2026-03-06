# Fase 3: Mejores Practicas de Herramientas Similares

> Fecha: 2026-03-05 | Basado en investigacion web de frameworks y plugins comparables

---

## 1. EveryInc/compound-engineering-plugin

El plugin de referencia en el ecosistema Claude Code para ingenieria compuesta.

### Arquitectura

- **4 fases**: Plan → Work → Assess → Compound (similar a adaptive-flow)
- **80/20 rule**: 80% del valor esta en plan y review, 20% en work y compound
- **12 subagentes de review en paralelo**: Cada uno revisa desde una perspectiva diferente (seguridad, performance, over-engineering, etc.)
- **Cross-provider sync**: CLI en Bun/TypeScript que convierte plugins a OpenCode, Codex, Gemini CLI, GitHub Copilot, Kiro, Windsurf, etc.
- **Closed compound loop**: `/workflows:compound` escribe soluciones → `/workflows:plan` las lee → `/workflows:review` las lee

### Que tomar para adaptive-flow

| Practica | Aplicabilidad | Prioridad |
|----------|---------------|-----------|
| Review con multiples perspectivas en paralelo | Alta — nuestro reviewer es monolitico, podria dividirse en sub-reviews | Alta |
| Cross-provider sync | Media — haria el plugin portable a otros editores | Baja |
| Closed compound loop (write → read → review) | Alta — nuestro compound genera datos pero no se verifica que se lean | Alta |
| 80/20 en plan y review | Alta — confirma nuestra arquitectura de flows G2+ | Validacion |

### Fuente
- [GitHub: EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)
- [Compound Engineering: How Every Codes With Agents](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents)
- [Learning from Every's Compound Engineering (Will Larson)](https://lethain.com/everyinc-compound-engineering/)

---

## 2. Otros Plugins Populares del Ecosistema

### Superpowers (Jesse Vincent)
- Bundle de competencias core para SDLC completo: planning, reviewing, testing, debugging
- Descrito como "consolidating engineering best practices — which sometimes does feel like a superpower"
- **Aplicabilidad**: Validacion de que un bundle cohesivo de skills es el approach correcto

### Context Engineering Kit (Vlad Goncharov)
- Coleccion de tecnicas avanzadas de context engineering con minimo footprint de tokens
- Enfoque en calidad de resultados del agente
- **Aplicabilidad**: Nuestro sistema de tiers de memoria alinea con este enfoque; podriamos optimizar aun mas el token footprint

### Claude-Mem
- Memoria a largo plazo para Claude Code: contexto y preferencias persisten entre sesiones
- **Aplicabilidad**: Complementa nuestro sistema de insights/learnings; podriamos integrar o aprender de su approach de persistencia

### context-mode
- Procesa outputs grandes en subprocesos sandboxed, manteniendo solo resumenes en el contexto
- Logra "98% context savings" en benchmarks
- **Aplicabilidad**: Podriamos aplicar tecnica similar para skills que generan mucho output

### Continuous-Claude-v2 (2.2k stars)
- Hooks mantienen estado via ledgers y handoffs
- MCP execution sin contaminacion de contexto
- Orquestacion de agentes con context windows aislados
- **Aplicabilidad**: El patron de ledgers para mantener estado entre hooks es interesante para nuestro sistema de memoria

### skill-bus
- "The skill for connecting skills": conecta contexto, condiciones y otros skills declarativamente
- Zero dependencies
- **Aplicabilidad**: Podriamos crear un mecanismo declarativo para conectar nuestros skills entre si

### Fuentes
- [awesome-claude-code (hesreallyhim)](https://github.com/hesreallyhim/awesome-claude-code)
- [10 top Claude Code plugins (Composio)](https://composio.dev/blog/top-claude-code-plugins)
- [awesome-claude-code-toolkit (rohitg00)](https://github.com/rohitg00/awesome-claude-code-toolkit)
- [Awesome Claude Skills](https://awesome-skills.com/)

---

## 3. Mejores Practicas de Hooks (Claude Code 2026)

### Los 14 Lifecycle Events (Feb 2026)

Claude Code ahora tiene 14 eventos de lifecycle (no solo 5 como nosotros usamos):
- SessionStart, SessionEnd
- UserPromptSubmit
- PreToolUse, PostToolUse, PostToolUseFailure
- PermissionRequest
- Notification
- Stop
- SubagentStart
- TeammateIdle, TaskCompleted

### 3 Tipos de Handler

| Tipo | Para que | Ejemplo |
|------|----------|---------|
| Command | Checks deterministicos | Lint, format, validacion de schema |
| Prompt | Evaluacion semantica | "Es este archivo sensible?" |
| Agent | Analisis profundo con tools | Review de seguridad con acceso a codebase |

**Nuestros hooks son todos Command**. Podriamos usar Prompt hooks para evaluaciones mas inteligentes.

### Patrones Clave

1. **PreToolUse puede modificar inputs** (desde v2.0.10): En lugar de bloquear y forzar retry, interceptar y corregir parametros. Invisible para Claude.
2. **Exit code 2 = bloqueo con feedback**: Stop hook que sale 2 fuerza a Claude a seguir trabajando (ya usamos esto en stop-check.sh).
3. **Async hooks** (`async: true`): Hooks en background sin bloquear ejecucion. Util para logging, telemetria.
4. **Smart dispatching**: Un solo entry point con routing inteligente para evitar penalizaciones de performance.
5. **CLAUDE_ENV_FILE**: SessionStart puede persistir variables de entorno para toda la sesion.

### Que tomar para adaptive-flow

| Practica | Aplicabilidad | Prioridad |
|----------|---------------|-----------|
| Usar eventos nuevos (SubagentStart, TaskCompleted, PostToolUseFailure) | Alta — podriamos inyectar contexto a subagentes y reaccionar a fallos | Media |
| Prompt hooks para evaluacion semantica | Alta — pre-write-guard podria evaluar semanticamente, no solo por patron | Media |
| Agent hooks para review profundo | Media — podria reemplazar parte del reviewer skill | Baja |
| Async hooks para logging | Media — telemetria sin bloquear | Baja |
| PreToolUse input modification | Alta — corregir parametros en vez de bloquear | Media |
| CLAUDE_ENV_FILE para persistir estado | Alta — alternativa robusta a nuestros archivos de estado | Alta |

### Fuentes
- [Hooks reference — Claude Code Docs](https://code.claude.com/docs/en/hooks)
- [Claude Code Hooks Guide: All 12 Lifecycle Events (Pixelmojo)](https://www.pixelmojo.io/blogs/claude-code-hooks-production-quality-ci-cd-patterns)
- [Claude Code Hooks: A Practical Guide (DataCamp)](https://www.datacamp.com/tutorial/claude-code-hooks)
- [claude-code-hooks-mastery (disler)](https://github.com/disler/claude-code-hooks-mastery)

---

## 4. Agent Teams y Coordinacion Multi-Agente

### Arquitectura de Agent Teams (Feb 2026, Opus 4.6)

- **Team Lead**: Sesion principal que analiza, crea equipos, orquesta
- **Teammates**: Procesos independientes con contexto fresco y acceso completo a tools
- **Shared Task List**: Tareas con estados (pending, in_progress, completed) y dependencias
- **Mailbox System**: JSON en disco (`~/.claude/<teamName>/inboxes/<agentName>.json`), peer-to-peer

### Diferencia con Subagentes

| | Subagentes | Agent Teams |
|-|-----------|-------------|
| Comunicacion | Solo con padre | Entre peers (via mailbox) |
| Coordinacion | Padre como intermediario | Task list compartida |
| Contexto | Fork del padre | Fresco (solo CLAUDE.md + task) |
| Coste | ~1x | ~5-7x tokens |

### Que tomar para adaptive-flow

| Practica | Aplicabilidad | Prioridad |
|----------|---------------|-----------|
| Adaptar flows G3+ para usar Agent Teams | Alta — planner, implementer, reviewer podrian ser teammates, no subagentes secuenciales | Media |
| CLAUDE.md con seccion para agent teams | Media — "When working as teammate, check TaskList first" | Baja |
| Shift+Tab para restringir lead a coordinacion | Alta — evita que el lead se distraiga implementando | Validacion |
| Reserve teams para tareas que genuinamente necesitan parallelismo | Alta — no todo necesita Agent Teams | Validacion |

### Fuentes
- [Agent Teams — Claude Code Docs](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Agent Teams: Complete Guide (claudefast)](https://claudefa.st/blog/guide/agents/agent-teams)
- [Claude Code Swarms (Addy Osmani)](https://addyosmani.com/blog/claude-code-agent-teams/)

---

## 5. Sistemas de Memoria para Agentes IA

### Taxonomia de Memoria (Investigacion 2025-2026)

| Tipo | Que almacena | Ejemplo en adaptive-flow |
|------|-------------|-------------------------|
| **Working/Short-Term** | Contexto actual, prompt, tool outputs | Context window de Claude |
| **Long-Term** | Conocimiento persistente entre sesiones | user-insights.yaml, learnings.yaml |
| **Entity** | Hechos sobre el usuario (preferencias, relaciones) | user-insights.yaml (parcialmente) |
| **Episodic** | "Historia hasta ahora" — resumenes de interacciones | next-briefing.md (parcialmente) |
| **Semantic** | Conocimiento factual estructurado | patterns.yaml, learnings.yaml |
| **Procedural** | Skills aprendidos, procesos operativos | flows/*.md (estatico, no aprendido) |

### Decisiones Criticas de Diseño

1. **Cuando leer memoria**: Antes de planificar? Antes de tool calls? Siempre?
   - adaptive-flow usa tiers (1: siempre, 2: al activar flow, 3: al escribir)
   - Best practice: leer antes de planificar, no en cada tool call

2. **Cuando escribir memoria**: Despues de cada mensaje? Solo al completar tarea?
   - adaptive-flow escribe solo en compound-capture (post-feature)
   - Best practice: escribir al completar tarea, no en cada interaccion

3. **Decay y higiene**: Que olvidar? Cuando?
   - adaptive-flow tiene insight decay check (5+ features sin validar)
   - Best practice: TTL por tipo de memoria, decay gradual

### Herramientas de Referencia

| Herramienta | Enfoque | Relevancia |
|-------------|---------|------------|
| **Mem0** | Capa de memoria dedicada, extrae "memories" de interacciones | Alta — su modelo de extraccion automatica aplica a compound-capture |
| **Zep** | Memoria episodica y temporal, secuencias significativas | Media — podriamos estructurar retrospectives como episodios |
| **Letta (MemGPT)** | Memoria como componente first-class del estado del agente | Alta — podriamos tratar memoria como estado mutable del agente |
| **LangMem** | Memorias como JSON en store estructurado | Media — nuestro YAML es similar pero menos query-able |

### Que tomar para adaptive-flow

| Practica | Aplicabilidad | Prioridad |
|----------|---------------|-----------|
| Clasificar memoria por taxonomia (episodic, semantic, procedural) | Alta — clarifica que almacenar y donde | Media |
| Implementar decay gradual con TTL por tipo | Alta — evita acumular memoria irrelevante | Media |
| Hacer memoria queryable (no solo archivos planos) | Alta — con muchos learnings, necesitamos busqueda | Media |
| Separar entity memory (preferencias usuario) de semantic (conocimiento proyecto) | Media — user-insights mezcla ambos | Baja |

### Fuentes
- [Memory for AI Agents (The New Stack)](https://thenewstack.io/memory-for-ai-agents-a-new-paradigm-of-context-engineering/)
- [Agent Memory Paper List (Shichun-Liu)](https://github.com/Shichun-Liu/Agent-Memory-Paper-List)
- [What Is AI Agent Memory? (IBM)](https://www.ibm.com/think/topics/ai-agent-memory)
- [Top 10 AI Memory Products 2026 (Medium)](https://medium.com/@bumurzaqov2/top-10-ai-memory-products-2026-09d7900b5ab1)
- [Amazon Bedrock AgentCore Memory](https://aws.amazon.com/blogs/machine-learning/amazon-bedrock-agentcore-memory-building-context-aware-agents/)

---

## 6. Context Engineering: CLAUDE.md vs Cursor Rules

### CLAUDE.md Best Practices (2026)

- **"Tan importante como .gitignore"**: Consenso de la comunidad en 2026
- **50-100 lineas max** en root, con `@imports` para secciones detalladas
- **Test de utilidad**: "Si quito esta linea, Claude cometera errores?" — si no, eliminar
- **Contenido**: Build commands, code style, architectural decisions, gotchas
- **No meter contenido estatico que no cambia**: Usar CLAUDE.md para contexto dinamico

### Cursor Rules

- `.cursorrules` para convenciones de proyecto (similar a CLAUDE.md)
- `.mdc` files tienen precedencia sobre `.cursorrules`
- Notepad feature para contexto persistente entre chat sessions
- `@codebase`, `@file`, `@folder` para inclusion selectiva de contexto

### Diferencias Clave

| Aspecto | CLAUDE.md | Cursor Rules |
|---------|-----------|-------------|
| Formato | Markdown libre | YAML/MDC con frontmatter |
| Scope | Proyecto | Proyecto + global |
| Inclusion | Automatica (siempre cargado) | Selectiva (@mentions) |
| Plugins | Si (skills, hooks) | No (solo rules) |
| Agentes | Subagentes y teams | Agent mode limitado |

### Que tomar para adaptive-flow

| Practica | Aplicabilidad | Prioridad |
|----------|---------------|-----------|
| Mantener CLAUDE.md ≤50 lineas (actualmente 34, bien) | Ya cumplimos | Validacion |
| @imports para secciones detalladas | Alta — podriamos usar para cargar flows bajo demanda | Media |
| Test de utilidad por linea | Alta — aplicar a cada archivo del plugin | Baja |
| Session hygiene (fresh sessions, /clear, compact at 70%) | Alta — documentar en README como recomendacion | Baja |
| Subagentes para aislamiento de contexto | Ya cumplimos (context: fork) | Validacion |

### Fuentes
- [Claude Code Best Practices: 2026 Guide (Morph)](https://www.morphllm.com/claude-code-best-practices)
- [Claude Code vs Cursor (Builder.io)](https://www.builder.io/blog/cursor-vs-claude-code)
- [Cursor vs Windsurf vs Claude Code (DEV Community)](https://dev.to/pockit_tools/cursor-vs-windsurf-vs-claude-code-in-2026-the-honest-comparison-after-using-all-three-3gof)

---

## 7. Resumen de Practicas Priorizadas para Adaptive Flow

### Prioridad Alta (implementar)

1. **Review multi-perspectiva** — Dividir reviewer en sub-reviews paralelos (EveryInc)
2. **Closed compound loop** — Verificar que compound data se lee en planning/review (EveryInc)
3. **Prompt hooks** — Evaluacion semantica en pre-write-guard (Claude Code hooks)
4. **CLAUDE_ENV_FILE** — Persistir estado de sesion sin archivos temporales (Claude Code hooks)
5. **Memoria queryable** — Hacer learnings/patterns buscables, no solo archivos planos (AI memory research)

### Prioridad Media (evaluar)

6. **Eventos nuevos de hooks** — SubagentStart, TaskCompleted, PostToolUseFailure
7. **Agent Teams para G3+** — Teammates en vez de subagentes secuenciales
8. **Taxonomia de memoria** — Clasificar por tipo (episodic, semantic, procedural)
9. **Decay con TTL** — Expirar memoria por tipo y antiguedad
10. **PreToolUse input modification** — Corregir parametros en vez de bloquear

### Prioridad Baja (futuro)

11. **Cross-provider sync** — Portabilidad a otros editores
12. **Agent hooks** — Review profundo con acceso a codebase
13. **Async hooks** — Telemetria sin bloquear
14. **@imports en CLAUDE.md** — Carga selectiva de secciones
