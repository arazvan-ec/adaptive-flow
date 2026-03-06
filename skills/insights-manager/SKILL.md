---
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
---

# Skill: insights-manager

> **Help**: Manage your AI working insights. Add, review, search, pause, retire, or promote insights. Usage: `/adaptive-flow:insights-manager [--add|--review|--list|--search|--pause ID|--retire ID|--promote ID]`

CRUD de insights del usuario. Permite gestionar el meta-conocimiento
sobre como trabajar con IA de forma efectiva.

## Invocacion

```
/adaptive-flow:insights-manager                                  # Listar insights activos
/adaptive-flow:insights-manager --add                            # Anadir nuevo insight
/adaptive-flow:insights-manager --review                         # Revisar discovered insights pendientes
/adaptive-flow:insights-manager --pause {id}                     # Pausar un insight
/adaptive-flow:insights-manager --retire {id}                    # Retirar un insight
/adaptive-flow:insights-manager --promote {id}                   # Promover discovered → user
/adaptive-flow:insights-manager --list --tag={tag}               # Filtrar insights por tag
/adaptive-flow:insights-manager --list --influence={high|medium|low}  # Filtrar por influencia
/adaptive-flow:insights-manager --search {query}                 # Buscar en insights, learnings y patterns
```

## Operaciones

### list (default)

Muestra todos los insights activos agrupados por influence:

```markdown
# Active Insights

## High Influence (applied proactively)
- `{id}`: {observation} — [{tags}]

## Medium Influence (suggested if relevant)
- `{id}`: {observation} — [{tags}]

## Low Influence (on demand)
- `{id}`: {observation} — [{tags}]

## Paused
- `{id}`: {observation} — paused since {date}

---
Discovered pending review: {count}
Stale insights: {count}
```

### add

Guia interactiva para anadir un nuevo insight:

```
1. "Que has observado que funciona (o no funciona) cuando trabajas con IA?"
   → observation

2. "Por que crees que funciona?"
   → reasoning

3. "En que fases deberia aplicarse?"
   → when_to_apply: [planning, design, implementation, review, routing]

4. "Que nivel de influencia?"
   → influence: high | medium | low

5. "Tags para categorizar?"
   → tags: [string]
```

Genera el YAML y lo anade a `memory/user-insights.yaml`.

### review

Muestra discovered insights con status: proposed para que el usuario decida:

```
Para cada insight propuesto:
  "La IA descubrio: {observation}"
  "Evidencia: {evidence}"
  "Confianza: {confidence}"

  Opciones:
  [1] Aceptar (se marca status: accepted, influence: medium)
  [2] Rechazar (se marca status: rejected)
  [3] Modificar (el usuario ajusta observation/influence)
  [4] Promover a user-insight (si confidence >= 0.7)
  [5] Saltar (mantener como proposed)
```

### pause {id}

Marca un insight como `status: paused`. Se deja de aplicar pero no se elimina.
Util cuando un insight no es relevante temporalmente.

### retire {id}

Marca un insight como `status: retired`. Se archiva permanentemente.
Util cuando un insight ya no es valido.

### promote {id}

Mueve un discovered insight a user-insights.yaml:
1. Lee el insight de discovered-insights.yaml
2. Lo formatea como user insight (observation → observation, confidence → influence mapping)
3. Lo anade a user-insights.yaml
4. Marca el original como `status: promoted`

Mapping de confidence a influence:
- confidence >= 0.8 → influence: high
- confidence >= 0.6 → influence: medium
- confidence < 0.6 → influence: low

### list --tag={tag} / --influence={level}

Filtra insights activos por criterios:

```
--tag={tag}:        Solo muestra insights que tengan ese tag
--influence={level}: Solo muestra insights con ese nivel de influencia (high, medium, low)
--since={date}:     Solo muestra insights añadidos desde esa fecha (YYYY-MM-DD)

Se pueden combinar:
  --list --tag=testing --influence=high
```

Output: misma tabla que `list` pero filtrada.

### search {query}

Busca texto en TODA la memoria del plugin:

```
1. Buscar en memory/user-insights.yaml (observation, reasoning, tags)
2. Buscar en memory/learnings.yaml (description, context, tags)
3. Buscar en memory/patterns.yaml (name, description, tags)
4. Buscar en memory/discovered-insights.yaml (observation, evidence)
```

Output:

```markdown
# Search Results for "{query}"

## Insights ({N} matches)
- `{id}` [{influence}]: {observation}

## Learnings ({N} matches)
- `{id}` [{type}]: {description}

## Patterns ({N} matches)
- `{id}`: {name} — {description}

## Discovered Insights ({N} matches)
- `{id}` [{status}]: {observation}

Total: {N} results across {N} memory files
```

La busqueda es case-insensitive y busca en todos los campos de texto.

## Archivos que lee

- `memory/user-insights.yaml` — list, search
- `memory/learnings.yaml` — search
- `memory/patterns.yaml` — search
- `memory/discovered-insights.yaml` — review, search

## Archivos que modifica

- `memory/user-insights.yaml` — add, promote, pause, retire
- `memory/discovered-insights.yaml` — review, promote
