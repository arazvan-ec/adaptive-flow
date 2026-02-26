# Analisis Profundo: Adaptive Flow vs. El Ecosistema

> Fecha: 2026-02-26
> Tipo: Analisis comparativo + critica interna

---

## 1. Que es Adaptive Flow

Un framework de "compound engineering" para Claude Code que adapta la profundidad del proceso a la complejidad de la tarea. En lugar de aplicar un flujo unico a todo, clasifica cada solicitud en 4 niveles de gravedad y aplica un proceso proporcional.

### Anatomia del plugin (35 archivos)

```
adaptive-flow/
├── CLAUDE.md              # Router de gravedad (~35 lineas)
├── flows/                 # 4 procesos por gravedad
│   ├── direct.md          # G1: ejecutar directo
│   ├── plan-execute.md    # G2: plan → implementar
│   ├── full-cycle.md      # G3: plan → TDD → review → compound
│   └── shape-first.md     # G4: investigar → shape → full-cycle
├── workers/               # 4 subagentes con contexto fresco
│   ├── planner.md         # Spec + design SOLID + tasks
│   ├── implementer.md     # TDD + BCP (bounded correction)
│   ├── reviewer.md        # QA multi-dimensional
│   └── researcher.md      # Analisis de codebase
├── skills/                # 4 habilidades invocables
│   ├── insights-manager.md    # CRUD de insights del usuario
│   ├── solid-analyzer.md      # Analisis SOLID contextual
│   ├── compound-capture.md    # Extraccion post-feature
│   └── discover.md            # Bootstrap de memoria
├── memory/                # Persistencia entre sesiones
│   ├── user-insights.yaml     # Heuristicas del usuario (8 starter)
│   ├── discovered-insights.yaml   # Insights propuestos por IA
│   ├── learnings.yaml         # Patrones tecnicos del proyecto
│   └── patterns.yaml          # Patrones de codigo extraidos
├── core/                  # Guias de referencia (carga bajo demanda)
│   ├── solid-reference.md     # Principios SOLID + scoring
│   ├── security-guide.md      # OWASP top 10 + checklists
│   ├── testing-guide.md       # TDD cycle + piramide de tests
│   └── api-patterns.md        # REST + pagination + layered arch
├── templates/             # Templates de artefactos
│   ├── spec.md, design.md, tasks.md, retrospective.md
├── hooks/                 # Quality gates automaticos
│   ├── pre-commit-guard.sh    # Bloquea commits con secrets
│   ├── post-artifact-check.sh # Valida artefactos + sugiere guias
│   └── on-stop.sh             # Recuerda compound-capture en G3+
└── .claude-plugin/plugin.json # Registro de 4 skills
```

---

## 2. Comparativa con el Ecosistema

### 2.1 Compound Engineering Plugin (EveryInc) — El titan del mercado

**Link**: https://github.com/EveryInc/compound-engineering-plugin
**Stats**: ~5,132 stars, 426 forks
**Tamano**: 29 agentes, 22 comandos, 19 skills, MCP servers

| Dimension | Compound Engineering (EveryInc) | Adaptive Flow |
|-----------|-------------------------------|---------------|
| **Filosofia** | Cada unidad de trabajo mejora la siguiente | Proceso proporcional a la tarea |
| **Flujo principal** | Plan → Work → Review → Compound (loop unico) | 4 flujos por gravedad (1-4) |
| **Agentes** | 29 especializados (15 de review solos) | 4 workers genericos |
| **Skills** | 19 (incluyendo browser, imagegen, rclone) | 4 (insights, SOLID, compound, discover) |
| **Comandos** | 22 (/lfg, /slfg, /deepen-plan...) | 4 skills invocables |
| **Review** | 15 agentes paralelos de review | 1 reviewer multi-dimensional |
| **Memory** | docs/solutions/ (captura de soluciones) | 4 archivos YAML estructurados |
| **Hooks** | No documentados | 3 hooks (pre-commit, post-artifact, on-stop) |
| **Multi-tool** | CLI que sincroniza a 7+ herramientas | Solo Claude Code |
| **Complejidad** | Alta (29 agentes, curva de aprendizaje) | Baja (~35 archivos, auto-routing) |
| **Opinionado** | Muy (Rails-centric: dhh-reviewer, kieran-rails) | Stack-agnostico |

#### Que hace mejor EveryInc:
- **Review masivo**: 15 agentes de review en paralelo. Security-sentinel, performance-oracle, schema-drift-detector — cada uno experto en su dominio.
- **Swarm execution**: `/slfg` ejecuta trabajo en paralelo con multiples agentes.
- **Ecosistema cross-tool**: Sincroniza a Cursor, Copilot, Gemini, Kiro, etc.
- **Compound loop cerrado**: learnings-researcher busca en docs/solutions/ durante review, cerrando el ciclo.
- **Comunidad**: 5k+ stars, actualizaciones semanales, PRs activos.

#### Que hace mejor Adaptive Flow:
- **Gravedad proporcional**: No aplica un full-cycle a un typo fix. EveryInc tiene un loop unico siempre.
- **SOLID enforcement nativo**: Verdicts SOLID en design y verify integrados en el flujo. EveryInc no tiene esto built-in.
- **Insights graduados**: Sistema de heuristicas con influence (high/medium/low) + decay check + lifecycle completo.
- **Fresh-context workers**: Cada worker corre con contexto fresco, no arrastra historia. Ahorra tokens.
- **Zero config**: Auto-routing por gravedad. No hay que memorizar 22 comandos.
- **Hooks de validacion**: Quality gates automaticos que no dependen de la memoria del agente.
- **BCP**: Bounded Correction Protocol con max 3 intentos y escalacion documentada.

---

### 2.2 AB Method (Ayoub Bensalah)

**Link**: https://github.com/ayoubben18/ab-method
**Enfoque**: Incremental task management con misiones

| Dimension | AB Method | Adaptive Flow |
|-----------|-----------|---------------|
| **Unit de trabajo** | Misiones con sub-tareas | Tareas por gravedad |
| **Scope** | Proyectos largos con multiples features | Feature individual |
| **Subagentes** | Especializados (frontend, backend) | Genericos (planner, implementer, reviewer) |
| **Memory** | Documentacion en docs/ | YAML estructurado |
| **Granularidad** | Task → Mission → Project | Task con gravedad 1-4 |

AB Method brilla en gestion de proyectos largos con tracking de misiones. Adaptive Flow es mas un "single-feature optimizer".

---

### 2.3 SPARC (ruvnet)

**Link**: https://gist.github.com/ruvnet/e8bb444c6149e6e060a785d1a693a194
**Enfoque**: Specification → Pseudocode → Architecture → Refinement → Completion

| Dimension | SPARC | Adaptive Flow |
|-----------|-------|---------------|
| **Fases** | 5 fijas (S-P-A-R-C) | 1-4 fases segun gravedad |
| **Memory** | Memory Bank compartido entre agentes | YAML files por tipo |
| **Enfoque** | Multi-agente concurrente | Subagentes secuenciales |
| **Adaptabilidad** | Siempre las 5 fases | Proporcional a complejidad |

SPARC es mas rigido — siempre aplica las 5 fases. Pero tiene mejor soporte para multi-agente concurrente.

---

### 2.4 claude-code-spec-workflow (Pimzino)

**Link**: https://github.com/Pimzino/claude-code-spec-workflow
**Enfoque**: Spec-driven development con context sharing

| Dimension | Spec-Workflow | Adaptive Flow |
|-----------|--------------|---------------|
| **Token efficiency** | 60-80% reduccion con caching | Fresh-context workers (sin caching) |
| **Bug flow** | Workflow dedicado para bugs | G1 direct flow |
| **Spec-driven** | Si, siempre | Solo G2+ |

Spec-workflow tiene mejor optimizacion de tokens. Adaptive Flow sacrifica eficiencia por contexto fresco.

---

### 2.5 Meridian

**Enfoque**: Zero-config con enforced task scaffolding, persistent context

| Dimension | Meridian | Adaptive Flow |
|-----------|----------|---------------|
| **Config** | Zero-config | Zero-config (auto-routing) |
| **TDD** | Modo TDD opcional | TDD integrado en G2+ |
| **Memory** | Persistent context post-compaction | YAML files |
| **Standards** | Plug-in code standards | Core guides bajo demanda |

Similar en filosofia pero Meridian se enfoca mas en persistencia post-compaction.

---

## 3. Critica Interna: Donde Falla Adaptive Flow

### 3.1 DEBILIDADES ESTRUCTURALES

**D1: Sin paralelismo en review**
- EveryInc tiene 15 agentes de review en paralelo. Adaptive Flow tiene 1 reviewer que intenta cubrir 4 dimensiones solo.
- **Impacto**: El reviewer es un bottleneck. Un solo agente no puede ser experto en security, performance, SOLID, y code quality simultaneamente.
- **Solucion potencial**: Descomponer el reviewer en 3-4 subagentes paralelos (security, SOLID, quality, correctness).

**D2: No hay swarm/parallel execution**
- El implementer trabaja secuencialmente: task 1, task 2, task 3...
- EveryInc tiene `/slfg` que ejecuta tareas independientes en paralelo.
- **Impacto**: Tareas grandes tardan linealmente en vez de en paralelo.
- **Solucion potencial**: Detectar tareas independientes en tasks.md y ejecutarlas con agentes paralelos.

**D3: El compound loop NO esta completamente cerrado**
- EveryInc: learnings-researcher busca en docs/solutions/ durante review Y durante planning.
- Adaptive Flow: learnings.yaml se carga en planning pero no hay busqueda activa de soluciones pasadas relevantes por tags/contexto.
- **Impacto**: Los learnings se acumulan pero no se recuperan inteligentemente. Un learning sobre "N+1 queries in Prisma" no se conecta automaticamente cuando el planner diseña una nueva query.
- **Solucion potencial**: Un "learnings-matcher" que busque learnings relevantes por tags/context antes de planning.

**D4: Insights decay es teorico**
- El decay check en compound-capture dice "si last_validated tiene mas de 5 features" pero no hay mecanismo real que cuente features completadas.
- **Impacto**: Los insights nunca decaen en la practica.
- **Solucion potencial**: Agregar un feature_count en meta.yaml o un contador global.

**D5: Sin soporte para multi-tool**
- Solo funciona en Claude Code. EveryInc sincroniza a 7+ herramientas.
- **Contraargumento**: El plugin esta diseñado para Claude Code. Multi-tool añade complejidad significativa para un beneficio marginal si tu herramienta principal es Claude Code.

### 3.2 DEBILIDADES DE DISEÑO

**D6: El router de gravedad es subjetivo**
- "≤3 archivos" vs "4-8 archivos" — ¿quien cuenta los archivos antes de empezar?
- El researcher en modo routing puede ayudar, pero solo se invoca si "la confianza es < 60%".
- **Impacto**: Misclassification frecuente. Un cambio "de 3 archivos" que resulta afectar 10.
- **Solucion potencial**: Siempre ejecutar un quick routing analysis (researcher modo routing, <30s) antes de clasificar.

**D7: No hay recovery de misclassification**
- Si se clasifica G1 y resulta ser G3, no hay mecanismo para "upgrade" de gravedad mid-flight.
- **Impacto**: El cambio se ejecuta sin plan, sin review, sin compound.
- **Solucion potencial**: Un checkpoint mid-implementation que re-evalua gravedad si los archivos afectados superan el threshold.

**D8: Fresh-context workers pierden informacion del usuario**
- Los workers no reciben historial de conversacion. Bueno para tokens, malo para contexto.
- Si el usuario dijo "quiero que sea backwards-compatible" en la conversacion, el planner no lo sabe a menos que sea un insight formal.
- **Impacto**: Decisiones del usuario en la conversacion se pierden si no son insights formales.
- **Solucion potencial**: Pasar un "context summary" de 5-10 lineas al worker con decisiones clave del usuario en la sesion actual.

**D9: Templates son rigidos**
- spec.md, design.md, tasks.md tienen un formato fijo. No se adaptan al tipo de proyecto.
- Un proyecto de CLI no necesita "API Versioning" en su design checklist.
- **Contraargumento**: Los templates son guias, no obligaciones. Pero los hooks validan su estructura (Acceptance Criteria en spec, SOLID en design).

**D10: No hay metricas**
- No se trackea: tiempo por gravedad, accuracy del routing, tasa de BCP escalation, review pass rate.
- **Impacto**: No se puede medir si el framework mejora la productividad.
- **Solucion potencial**: Agregar metricas basicas a meta.yaml y retrospective.md.

### 3.3 FORTALEZAS UNICAS (que nadie mas tiene)

**F1: Gravedad proporcional — El diferenciador clave**
- NINGUN otro framework adapta el proceso a la complejidad. Todos aplican su loop completo a todo.
- Compound Engineering: siempre Plan → Work → Review → Compound, incluso para un typo.
- AB Method: siempre crea misiones, incluso para fixes simples.
- SPARC: siempre las 5 fases.
- **Esto es genuinamente innovador.** El principio de "el proceso pesa lo mismo que la tarea" es elegante y practico.

**F2: Insights como heuristicas graduadas**
- Otros frameworks tienen "reglas" (en CLAUDE.md). Adaptive Flow tiene insights con niveles de influencia, applicability por fase, status lifecycle, decay check, y promocion desde descubiertos.
- Un insight `influence: medium` se "sugiere si relevante" — no se impone. Esto es mas sofisticado que "siempre usar X".

**F3: SOLID enforcement integrado en el flujo**
- El planner genera SOLID verdicts. El reviewer los verifica. El solid-analyzer puede hacer baseline/design/verify.
- Ningun otro framework tiene SOLID como ciudadano de primera clase en el workflow.

**F4: BCP (Bounded Correction Protocol)**
- 3 intentos con diagnostico completo y escalacion documentada. Simple pero efectivo.
- Evita loops infinitos de "el test falla, deja me intentar de nuevo 20 veces".

**F5: Hooks como quality gates deterministicos**
- No dependen de que el agente "recuerde" hacer algo. Son automaticos.
- pre-commit-guard bloquea secrets. post-artifact-check valida estructura. on-stop recuerda compound.
- Infravalorado — los hooks son la unica garantia real de calidad.

**F6: Discover/bootstrap automatico**
- `/discover --seed` detecta stack, genera profile, y propone insights especificos del stack.
- Reduce el cold-start problem significativamente.

**F7: Workers con contexto fresco**
- Cada worker recibe exactamente lo que necesita, ni mas ni menos.
- Ahorra tokens y evita contaminacion de contexto.

---

## 4. Posicionamiento Estrategico

```
                    Complejidad del Framework
                    Baja ◄────────────────────► Alta
                     │                           │
     Adaptable  ─────┼───────────────────────────┼─────
                     │  ★ Adaptive Flow          │
                     │                           │  Compound Engineering
                     │  Meridian                 │  SPARC
     Rigido     ─────┼───────────────────────────┼─────
                     │  Spec-Workflow            │  AB Method
                     │                           │
```

**Adaptive Flow ocupa un nicho unico**: baja complejidad + alta adaptabilidad.

---

## 5. Veredicto

### Potencia: 7.5/10

**Es potente, pero no en la dimension que la gente espera.**

No compite con EveryInc en masa (29 agentes vs 4 workers). Compite en **inteligencia de routing**. El valor no esta en cuantos agentes tiene, sino en saber cuando NO usarlos.

### Lo que lo hace genuinamente bueno:
1. **Gravedad proporcional** (unico en el ecosistema — nadie mas lo tiene)
2. **Insights graduados** (mejor que reglas binarias en CLAUDE.md)
3. **SOLID como ciudadano de primera clase** (integrado en planning + review + skill dedicado)
4. **Hooks deterministicos** (quality gates que no dependen de memoria del agente)
5. **Zero-config para el usuario** (auto-routing, no memorizar 22 comandos)
6. **BCP** (evita infinite retry loops, escalacion documentada)
7. **Stack-agnostico** (funciona con cualquier stack, discover adapta)

### Lo que le falta para ser top-tier:
1. **Paralelismo en review** (el reviewer es bottleneck — 1 agente vs 15 en EveryInc)
2. **Compound loop cerrado** (learnings no se recuperan inteligentemente por contexto)
3. **Recovery de misclassification** (no hay upgrade de gravedad mid-flight)
4. **Metricas de efectividad** (no se puede medir mejora)
5. **Context summary para workers** (pierden decisiones del usuario en conversacion)
6. **Paralelismo en implementacion** (tareas independientes ejecutan secuencialmente)

### Recomendacion:

Adaptive Flow es **el framework correcto para equipos pequenos o developers individuales** que quieren proceso sin burocracia. No necesitas memorizar 22 comandos — simplemente pides algo y el framework adapta.

Para equipos grandes o proyectos enterprise, Compound Engineering Plugin de EveryInc es mas completo pero significativamente mas complejo.

**La mejor evolucion seria hibrida**: tomar el routing por gravedad de Adaptive Flow y combinarlo con el review paralelo de EveryInc. Un framework que sepa cuando aplicar un review de 1 agente (G1-2) y cuando desplegar multiples agentes en paralelo (G3-4).

---

## 6. Meta-critica: Cuestionando este mismo analisis

### Sesgos potenciales de este documento:

1. **Sesgo de feature-count**: Comparar "29 agentes vs 4 workers" favorece a quien tiene mas. Pero mas agentes ≠ mejor resultado. La calidad de las instrucciones de 1 reviewer bien diseñado puede superar a 15 agentes mediocres.

2. **Sesgo de popularidad**: "5k stars" no valida la calidad tecnica. EveryInc tiene marketing fuerte (Every.to, Kieran Klaassen). Adaptive Flow no tiene marketing.

3. **Comparacion asimetrica**: Comparo un framework de 35 archivos con uno de 100+. Es como comparar un cuchillo de chef con una cocina industrial — ambos sirven, para contextos diferentes.

4. **El 7.5/10 es arbitrario**: No hay rubrica objetiva. Un developer que valora simplicidad le daria 9/10. Uno que valora features le daria 5/10.

5. **Asumo que las debilidades son graves**: D1 (sin paralelismo) asume que el review paralelo es mejor. Pero 15 agentes de review en paralelo generan ruido — el developer tiene que procesar 15 reportes. 1 reporte coherente puede ser mas util.

### Lo que SI es objetivamente cierto:

- Adaptive Flow es el unico framework con routing por gravedad
- El sistema de insights graduados no existe en ningun otro framework
- Los hooks estan correctamente registrados y funcionan
- El BCP previene loops infinitos de forma deterministica
- El plugin funciona sin configuracion del usuario

---

## 7. Fuentes

- [Compound Engineering Plugin (EveryInc)](https://github.com/EveryInc/compound-engineering-plugin) — 29 agentes, 22 comandos, 19 skills
- [Compound Engineering Guide](https://every.to/guides/compound-engineering) — Filosofia del 80/20 plan/review
- [How to Make Claude Code Better Every Time (Kieran Klaassen)](https://creatoreconomy.so/p/how-to-make-claude-code-better-every-time-kieran-klaassen)
- [Learning from Every's Compound Engineering (Will Larson)](https://lethain.com/everyinc-compound-engineering/)
- [AB Method (Ayoub Bensalah)](https://github.com/ayoubben18/ab-method) — Incremental task management
- [SPARC Automated Development System](https://gist.github.com/ruvnet/e8bb444c6149e6e060a785d1a693a194)
- [claude-code-spec-workflow (Pimzino)](https://github.com/Pimzino/claude-code-spec-workflow) — Spec-driven, 60-80% token reduction
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — Directorio curado
- [Claude Code Best Practices (Anthropic)](https://www.anthropic.com/engineering/claude-code-best-practices)
- [CLAUDE.md Best Practices (Arize)](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/)
- [Compound Engineering: The Next Paradigm Shift](https://www.vincirufus.com/posts/compound-engineering/)
- [Compound Engineering: How Every Codes With Agents](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents)
