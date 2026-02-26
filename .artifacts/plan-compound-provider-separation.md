# Plan: Separacion de dominios — Compound como Provider

**Branch:** `claude/improve-workflow-analysis-yzaLn`
**Fecha:** 2026-02-26
**Gravedad estimada:** 4 (scope requiere shaping, afecta arquitectura completa)

---

## 1. Diagnostico: Por que separar

### El problema

adaptive-flow tiene dos responsabilidades mezcladas:

**Dominio A — Orquestacion:**
- Clasificar gravedad (routing)
- Ejecutar flows (direct, plan-execute, full-cycle, shape-first)
- Coordinar workers (planner, implementer, reviewer, researcher)
- Quality gates (hooks)

**Dominio B — Conocimiento compuesto (compound):**
- Persistir memoria (patterns, learnings, insights, briefings)
- Extraer conocimiento post-feature (compound-capture)
- Gestionar lifecycle de insights (proponer, aceptar, promover, decay)
- Detectar stack y bootstrap de memoria (discover)
- Generar briefings para la siguiente tarea

Actualmente, el Dominio B esta **reimplementado** dentro de adaptive-flow en vez de
consumido como servicio externo. Esto viola SRP y acopla la persistencia de
conocimiento con la orquestacion de trabajo.

### Evidencia del acoplamiento

| Archivo | Dominio real | Donde vive ahora |
|---------|-------------|-------------------|
| `skills/compound-capture.md` | Compound | adaptive-flow |
| `skills/insights-manager.md` | Compound | adaptive-flow |
| `skills/discover.md` | Mixto (stack=orquestacion, insights=compound) | adaptive-flow |
| `memory/user-insights.yaml` | Compound | adaptive-flow |
| `memory/discovered-insights.yaml` | Compound | adaptive-flow |
| `memory/learnings.yaml` | Compound | adaptive-flow |
| `memory/patterns.yaml` | Compound | adaptive-flow |
| `memory/next-briefing.md` | Compound | adaptive-flow |
| `memory/architecture-profile.yaml` | Mixto | adaptive-flow |

9 de 31 archivos (29%) pertenecen al dominio compound, no al de orquestacion.

### Mapa de dependencias actual

```
flows/ ──READ──→ memory/*.yaml (compound data)
workers/ ──READ──→ memory/*.yaml (compound data)
hooks/on-stop.sh ──READ──→ .artifacts/meta.yaml + retrospective.md
skills/compound-capture ──WRITE──→ memory/*.yaml
skills/insights-manager ──WRITE──→ memory/*.yaml
skills/discover ──WRITE──→ memory/*.yaml
```

Todos los flows y workers estan hardcodeados a leer `memory/learnings.yaml`,
`memory/user-insights.yaml`, etc. Si cambia el provider, hay que tocar todo.

---

## 2. Propuesta: Interface + Provider

### Arquitectura objetivo

```
adaptive-flow (orquestador)
│
├── CLAUDE.md          → Routing (sin cambios)
├── flows/             → Procesos por gravedad
│     └── Referencian: providers/compound-interface.md
├── workers/           → Subagentes
│     └── Reciben contexto via interface, no paths directos
├── hooks/             → Quality gates
├── templates/         → Scaffolds
├── core/              → Guias de referencia
│
├── providers/
│     └── compound-interface.md   → CONTRATO (que necesita adaptive-flow)
│
└── providers/compound-local/     → IMPLEMENTACION por defecto
      ├── provider.md             → Como cumple el contrato
      ├── skills/
      │     ├── compound-capture.md
      │     ├── insights-manager.md
      │     └── discover.md
      └── memory/                 → Persistencia (YAML files)
            ├── user-insights.yaml
            ├── discovered-insights.yaml
            ├── learnings.yaml
            ├── patterns.yaml
            └── architecture-profile.yaml
```

### 2.1 El contrato: `providers/compound-interface.md`

Define QUE necesita adaptive-flow del compound, sin decir COMO:

```markdown
# Compound Provider Interface

El orquestador necesita estas operaciones del provider de conocimiento:

## Operaciones de lectura (consumidas por flows y workers)

### load-context(gravity, phase) → CompoundContext
Carga el contexto de conocimiento filtrado por gravedad y fase.
- gravity 1: solo insights high-influence de implementation
- gravity 2: insights (planning+impl) + learnings
- gravity 3: insights (all phases) + learnings + briefing
- gravity 4: insights (planning+design) [+ full via gravity 3]

Retorna:
- insights: lista filtrada de insights activos
- learnings: lista de learnings del proyecto (si gravity >= 2)
- briefing: contenido del next-briefing (si gravity >= 3)
- patterns: lista de patterns del proyecto (si relevant)

### get-insights(filter) → Insight[]
Retorna insights filtrados por:
- influence: high | medium | low
- when_to_apply: planning | design | implementation | review
- status: active | accepted

## Operaciones de escritura (consumidas por skills)

### capture-knowledge(artifacts, diff) → CaptureResult
Post-feature: extrae patterns, learnings, insights, genera retrospective y briefing.
Input: spec.md, design.md, tasks.md, git diff, QA report
Output: counts de lo extraido + paths

### manage-insight(action, id?, data?) → void
CRUD de insights: add, review, pause, retire, promote

### discover-stack(mode) → DiscoverResult
Analiza stack del proyecto y genera/actualiza memoria.
Modes: seed, profile, status
```

### 2.2 La implementacion local: `providers/compound-local/`

La implementacion por defecto usa YAML files en disco (lo que ya tenemos).
Pero ahora esta **aislada** detras del contrato.

Si manana alguien quiere:
- Un provider que use una DB en vez de YAML
- Un provider que conecte con un servicio externo de knowledge management
- Un provider que consuma el plugin compound original
...solo necesita implementar el contrato.

### 2.3 Cambios en flows y workers

ANTES (acoplado):
```markdown
1. Cargar insights de memory/user-insights.yaml
2. Cargar memory/learnings.yaml (si existe)
```

DESPUES (via interface):
```markdown
1. Cargar contexto compound via provider:
   Operacion: load-context(gravity=3, phase=planning)
   Provider: ver providers/compound-interface.md
   Implementacion actual: providers/compound-local/provider.md
```

Los workers reciben el contexto como input ya resuelto, no paths a archivos.
El flow es quien consulta al provider y pasa los datos a los workers.

---

## 3. Tasklist detallada

### Fase 1: Crear interface y restructurar (8 tareas)

| # | Tarea | Archivos afectados | Complejidad |
|---|-------|--------------------|-------------|
| 1.1 | Crear `providers/compound-interface.md` con el contrato completo | Nuevo archivo | Medium |
| 1.2 | Crear `providers/compound-local/provider.md` describiendo la impl local | Nuevo archivo | Medium |
| 1.3 | Mover `skills/compound-capture.md` → `providers/compound-local/skills/` | Move + update refs | Low |
| 1.4 | Mover `skills/insights-manager.md` → `providers/compound-local/skills/` | Move + update refs | Low |
| 1.5 | Separar `skills/discover.md` en dos: stack-detection (queda) + insight-suggest (se mueve) | Split + move | High |
| 1.6 | Mover `memory/` → `providers/compound-local/memory/` | Move + update all refs | Medium |
| 1.7 | Actualizar `.claude-plugin/plugin.json` con nuevos paths de skills | Config update | Low |
| 1.8 | Actualizar `CLAUDE.md` con referencia al provider | Edit | Low |

### Fase 2: Desacoplar flows y workers (6 tareas)

| # | Tarea | Archivos afectados | Complejidad |
|---|-------|--------------------|-------------|
| 2.1 | Refactor `flows/direct.md` — reemplazar paths directos por referencia a interface | Edit | Low |
| 2.2 | Refactor `flows/plan-execute.md` — idem | Edit | Low |
| 2.3 | Refactor `flows/full-cycle.md` — idem + carga de compound data via provider | Edit | Medium |
| 2.4 | Refactor `flows/shape-first.md` — idem | Edit | Low |
| 2.5 | Refactor workers (planner, implementer, reviewer) — inputs via contexto, no paths | Edit x3 | Medium |
| 2.6 | Refactor `hooks/on-stop.sh` — path a meta.yaml y retrospective via provider config | Edit | Low |

### Fase 3: Documentacion y registro (3 tareas)

| # | Tarea | Archivos afectados | Complejidad |
|---|-------|--------------------|-------------|
| 3.1 | Actualizar `README.md` con nueva arquitectura provider | Edit | Medium |
| 3.2 | Crear `providers/README.md` explicando como crear un provider custom | Nuevo | Medium |
| 3.3 | Actualizar templates si referencian paths de memory directamente | Edit (si aplica) | Low |

**Total: 17 tareas, ~25 archivos afectados**

---

## 4. Cuestionamiento critico del plan

### Pregunta 1: ¿Esto es over-engineering?

**Argumento a favor de NO hacerlo:**
- El framework tiene 31 archivos. Agregar una capa de abstraccion provider
  a un sistema de 31 archivos markdown es como poner una API REST delante de
  un archivo de texto.
- No hay runtime. Todo es instrucciones en markdown para un LLM. El "provider"
  no es codigo ejecutable — es una convencion de organizacion de archivos.
- Si solo va a haber un provider (YAML local), la abstraccion es prematura.
  "Three similar lines are better than a premature abstraction" — es un
  insight del propio framework.

**Argumento a favor de SI hacerlo:**
- La separacion de dominios es real, independientemente de si hay abstraccion.
  Hoy, un cambio en como se persisten insights requiere tocar flows, workers,
  hooks, y skills. Eso es acoplamiento real.
- La "interface" no es codigo — es documentacion que clarifica responsabilidades.
  Cuesta poco y aporta claridad conceptual.
- Si el compound viene de otro repo, integrarse via interface permite swappear
  el provider sin reescribir el orquestador.

**Veredicto:** Hay riesgo de over-engineering. La mitigacion es mantener la
interface minima (1 archivo, <100 lineas) y no crear abstracciones innecesarias.

### Pregunta 2: ¿Claude Code plugins pueden depender de otros plugins?

**Realidad actual:**
- Claude Code plugins se registran via `.claude-plugin/plugin.json`
- No existe un mecanismo nativo de "plugin dependencies" o "plugin providers"
- Un plugin no puede declarar "requiero plugin X"
- La integracion entre plugins seria manual: un plugin lee archivos del otro

**Implicacion para el plan:**
- El "provider" no es un plugin de Claude Code — es una convencion interna
  de adaptive-flow para organizar sus archivos.
- No podemos hacer `require('compound-plugin')`. Lo que podemos hacer es
  documentar que "el directorio `providers/compound-local/` implementa el
  contrato de `providers/compound-interface.md`".
- Si alguien quiere usar otro compound, copia sus archivos a
  `providers/compound-custom/` y actualiza el pointer.

**Veredicto:** La limitacion es real. El "provider pattern" aqui es
organizacional, no mecanico. Hay que ser honestos sobre eso en la docs.

### Pregunta 3: ¿Tiene sentido el pattern "interface" en un sistema de prompts?

**El problema:**
- En codigo, una interface tiene enforcement: el compilador verifica que la
  implementacion cumple el contrato.
- En markdown, no hay enforcement. La "interface" es un documento que dice
  "deberias hacer X", pero nada impide que la implementacion diverja.
- Los flows y workers son instrucciones para un LLM, no codigo ejecutable.
  El LLM lee la interface, lee la implementacion, y conecta los dos en
  runtime (su contexto). No hay binding mecanico.

**Contraargumento:**
- La interface sirve como documentacion de contrato, incluso sin enforcement
  mecanico. Es como un README que dice "si quieres crear un provider, necesitas
  implementar estas operaciones".
- Para el LLM que ejecuta el framework, la interface ES el binding. El LLM
  lee el contrato, lee la implementacion, y sabe que hacer. Es "duck typing"
  a nivel de prompt.

**Veredicto:** La interface tiene valor como documentacion y guia para el LLM,
pero no hay que pretender que es un contrato "enforced". Ser honestos.

### Pregunta 4: ¿No seria mejor simplemente reorganizar directorios sin interface?

**Alternativa mas simple:**
```
adaptive-flow/
├── orchestration/    ← flows, workers, hooks (Dominio A)
├── compound/         ← skills, memory (Dominio B)
├── core/             ← guias de referencia
└── templates/        ← scaffolds
```

Esto logra la separacion de dominios sin la complejidad de interface/provider.
Los flows siguen referenciando paths directos a `compound/memory/*.yaml`, pero
al menos es claro que son dominios separados.

**Pros:**
- Mas simple (solo mover archivos, no crear abstracciones)
- Mismo beneficio de claridad conceptual
- No pretende ser algo que no es (no hay "providers" falsos)

**Contras:**
- No prepara para swappear el compound
- Sigue acoplado a paths concretos
- No documenta el contrato entre dominios

**Veredicto:** Esta alternativa es mas honesta y posiblemente mas practica.
Pero pierde el beneficio de documentar explicitamente que necesita cada
dominio del otro.

### Pregunta 5: ¿Cuanto cuesta el acoplamiento actual realmente?

**Costo real actual:**
- Si quieres cambiar como se persisten insights (YAML → DB), tocas: 4 flows
  + 3 workers + 3 skills + 1 hook = 11 archivos
- Si quieres cambiar el schema de learnings, tocas: compound-capture +
  planner + implementer + flows = 6 archivos
- Si quieres swappear el compound por otro plugin: reescribes todo

**Costo del refactor propuesto:**
- 17 tareas, ~25 archivos, estimacion realista de 2-3 horas de trabajo LLM
- Complejidad adicional: 2-3 archivos nuevos de interface/provider
- Riesgo: romper flows existentes durante el refactor

**¿Vale la pena?**
- Si el compound es un concepto estable que no va a cambiar: NO, el costo
  del refactor supera el costo del acoplamiento.
- Si planeas iterar sobre el compound, probar alternatives, o reusar
  adaptive-flow sin compound: SI, el refactor se paga solo.

### Pregunta 6: ¿Y si en vez de todo esto, simplemente definimos la
interface como documentacion y dejamos los archivos donde estan?

**Propuesta minima viable:**
1. Crear `providers/compound-interface.md` — documenta que necesita adaptive-flow
2. Agregar comentarios en los flows: "// este bloque consume compound data"
3. NO mover archivos
4. NO crear `providers/compound-local/`

**Beneficios:**
- Cero riesgo de romper nada
- Documenta el contrato para futuro refactor
- Si manana quieres extraer el compound, ya sabes que cortar

**Costo:**
- Solo 1 archivo nuevo + comentarios en 7 archivos existentes
- ~20 minutos de trabajo

---

## 5. Recomendacion final

Propongo un **approach incremental en 2 niveles**:

### Nivel 1 (hacer ahora): Interface como documentacion

- Crear `providers/compound-interface.md` con el contrato
- Agregar marcadores `## Compound Provider` en flows y workers donde se
  consume compound data
- NO mover archivos, NO crear subdirectorios provider
- **Esfuerzo: ~1 hora, riesgo: cero**

### Nivel 2 (hacer cuando haya evidencia de que se necesita):

- Mover archivos a `providers/compound-local/`
- Refactorizar flows y workers para referenciar via interface
- Solo si: (a) se quiere swappear el compound, o (b) se crea un segundo
  provider, o (c) el compound crece tanto que estorba la orquestacion

**Razon:** Seguir el propio principio del framework: "no premature abstraction".
Si la necesidad de swappear el compound es real, se hara. Si no, tenemos la
documentacion del contrato lista para cuando llegue el momento.

---

## 6. Decision pendiente del usuario

¿Cual approach prefieres?

- **A) Plan completo (17 tareas)**: Interface + mover archivos + refactorizar flows
- **B) Interface + marcadores (Nivel 1)**: Solo documentar el contrato, no mover nada
- **C) Reorganizar directorios sin interface (Pregunta 4)**: Mover a `compound/` sin abstracciones
- **D) No hacer nada**: El acoplamiento actual es aceptable para el tamano del proyecto

Mi recomendacion: **B** — documentar el contrato ahora, refactorizar despues si hay evidencia.
