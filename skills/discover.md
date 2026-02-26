# Skill: discover

Analiza el stack del proyecto y genera memoria inicial.
Ideal para onboarding en un proyecto nuevo.

## Invocacion

```
/adaptive-flow:discover --seed     # Analiza stack + genera insights sugeridos
/adaptive-flow:discover --profile  # Solo genera architecture profile
/adaptive-flow:discover --status   # Muestra estado actual de la memoria
```

## Modos

### --seed (onboarding completo)

Ejecuta los 3 pasos de bootstrap:

```
1. ANALYZE — Detectar stack tecnologico
   - Leer package.json / Cargo.toml / pyproject.toml / go.mod / etc.
   - Detectar framework (Next.js, Express, Django, etc.)
   - Detectar ORM (Prisma, TypeORM, SQLAlchemy, etc.)
   - Detectar test framework (Jest, Vitest, Pytest, etc.)
   - Detectar linter (ESLint, Ruff, Clippy, etc.)

2. PROFILE — Generar architecture profile
   → Escribir memory/architecture-profile.yaml

3. SUGGEST — Proponer insights especificos del stack
   → Anadir a memory/discovered-insights.yaml con status: proposed
   El usuario revisa con /adaptive-flow:insights-manager --review
```

### --profile (solo analisis)

Ejecuta solo los pasos 1 y 2. Util para actualizar el profile despues de
cambios significativos en el stack.

### --status (ver estado)

Muestra resumen de la memoria actual:

```markdown
# Adaptive Flow — Memory Status

## Insights
- User insights: {N} active, {N} paused
- Discovered insights: {N} proposed, {N} accepted

## Learnings
- Patterns: {N}
- Anti-patterns: {N}
- Boundaries: {N}

## Code Patterns
- Registered: {N}

## Architecture Profile
- {Exists / Not generated yet}
- Stack: {language} + {framework} + {orm}
```

## Architecture Profile Format

```yaml
# memory/architecture-profile.yaml

stack:
  language: typescript
  runtime: node
  framework: express
  orm: prisma
  test_framework: vitest
  linter: eslint
  package_manager: npm

structure:
  source_dir: src/
  test_dir: tests/
  config_dir: config/
  entry_point: src/index.ts

conventions:
  naming: camelCase
  file_organization: feature-based  # or layer-based
  test_pattern: "*.test.ts"         # or "*.spec.ts"

detected_patterns:
  - name: repository-pattern
    evidence: "src/repositories/*.ts"
  - name: service-layer
    evidence: "src/services/*.ts"
  - name: dto-pattern
    evidence: "src/dtos/*.ts"

generated: 2026-02-26
```

## Stack-Specific Suggested Insights

El discover genera insights adaptados al stack detectado. Ejemplos:

### TypeScript + Express
```yaml
- id: express-middleware-order
  observation: "Middleware order matters in Express — auth before route handlers, error handler last"
  when_to_apply: [implementation]
  confidence: 0.8

- id: prisma-transaction-boundaries
  observation: "Prisma transactions should wrap the entire business operation, not individual queries"
  when_to_apply: [implementation, design]
  confidence: 0.7
```

### Python + Django
```yaml
- id: django-fat-models
  observation: "Keep business logic in models or services, not in views"
  when_to_apply: [implementation, design]
  confidence: 0.8

- id: django-querysets-lazy
  observation: "Django querysets are lazy — chain filters freely but be aware of N+1 with select_related"
  when_to_apply: [implementation, review]
  confidence: 0.7
```

### Rust
```yaml
- id: rust-ownership-design
  observation: "Design data ownership before coding — who owns, who borrows, who clones"
  when_to_apply: [design, planning]
  confidence: 0.8
```

## Output

```yaml
output:
  profile_generated: boolean
  stack_detected: string          # "typescript + express + prisma"
  insights_suggested: int         # Numero de insights propuestos
  profile_path: string            # Path al architecture profile
  next_step: string               # Sugerencia de que hacer despues
```

## Integration con plugin.json

Este skill se registra en `.claude-plugin/plugin.json` para ser invocable
como `/adaptive-flow:discover`.
