# Skill: compound-capture

Captura de conocimiento post-feature. Extrae patterns, learnings, insights
y genera briefing para la siguiente tarea.

## Invocacion

```
/adaptive-flow:compound-capture
```

## Cuando ejecutar

- Automaticamente despues de completar una tarea de gravedad 3+
- Manualmente cuando el usuario quiere capturar learnings de cualquier tarea

## Proceso

```
1. Leer los artefactos de la feature completada:
   - spec.md, design.md, tasks.md (de openspec/changes/{slug}/)
   - Git diff de todos los commits de la feature
   - QA report del reviewer (si existe)

2. Analizar en 4 dimensiones:

   a. PATTERNS — Que patterns de codigo se usaron con exito?
      → Anadir a memory/patterns.yaml
      Formato: { id, name, description, example_file, tags, captured }

   b. LEARNINGS — Que se aprendio? Que fue mas complejo de lo esperado?
      → Anadir a memory/learnings.yaml
      Tipos: pattern | anti-pattern | boundary
      Formato: { id, type, description, context, impact, tags, captured }

   c. DISCOVERED INSIGHTS — Hay patrones cross-feature?
      → Anadir a memory/discovered-insights.yaml
      Solo si confidence >= 0.5
      Formato: { id, observation, evidence, confidence, when_to_apply, status: proposed }

   d. RETROSPECTIVE — Que fue bien, que mejorar?
      → Escribir openspec/changes/{slug}/retrospective.md

3. Generar briefing para proxima tarea:
   → Escribir memory/next-briefing.md
   Contenido: top 3 learnings relevantes + patterns reutilizables + warnings
```

## Template de retrospective.md

```markdown
# Retrospective: {Feature Name}

## Date: YYYY-MM-DD

## What Went Well
- {item 1}
- {item 2}

## What Could Improve
- {item 1}
- {item 2}

## Surprises (70% Boundary)
- {Donde la complejidad real difirió de la esperada}

## Patterns Extracted
- {pattern 1}: {breve descripcion}

## Learnings Captured
- {learning 1}: {breve descripcion}

## Discovered Insights Proposed
- {insight 1}: {observation} (confidence: {score})
```

## Template de next-briefing.md

```markdown
# Briefing for Next Feature

Generated: YYYY-MM-DD
Source: {feature slug}

## Top Learnings
1. {learning mas relevante para futuras features}
2. {segundo learning}
3. {tercero}

## Reusable Patterns
- {pattern}: {donde encontrar el ejemplo}

## Warnings
- {anti-pattern a evitar}
- {boundary a tener en cuenta}
```

## Insight Decay Check

Durante compound capture, tambien revisar insights existentes:

```
Para cada insight en user-insights.yaml con status: active:
  Si last_validated tiene mas de 5 features de antiguedad:
    Marcar como stale
    Informar al usuario: "Insight {id} no se ha validado recientemente"
```

## Output

```yaml
output:
  patterns_added: int
  learnings_added: int
  insights_proposed: int
  retrospective_path: string
  briefing_path: string
  stale_insights: list       # IDs de insights marcados como stale
```
