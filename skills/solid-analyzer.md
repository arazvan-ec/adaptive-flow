# Skill: solid-analyzer

Analisis SOLID contextual con multiples modos de operacion.

## Invocacion

```
/adaptive-flow:solid-analyzer                    # default: mode=baseline
/adaptive-flow:solid-analyzer --mode=baseline    # Analiza estado actual
/adaptive-flow:solid-analyzer --mode=design      # Valida un diseno propuesto
/adaptive-flow:solid-analyzer --mode=verify      # Verifica codigo vs diseno
```

## Modos

### baseline — Analiza el estado actual

Entrada: paths de archivos o modulos a analizar
Salida: SOLID scorecard del codigo existente

```markdown
# SOLID Baseline: {Module}

| Componente | S | R | P | I | D | Score |
|-----------|---|---|---|---|---|-------|
| {comp 1} | OK | WARN | OK | OK | OK | 4/5 |
| {comp 2} | OK | OK | OK | FAIL | OK | 4/5 |

## Detalle

### {Componente con WARN/FAIL}
- **Principio**: {cual}
- **Evidencia**: {archivo:linea} — {descripcion del problema}
- **Sugerencia**: {como mejorar}

## Summary
- Score global: {X/5}
- Prioridad de mejora: {componente} ({principio})
```

### design — Valida un diseno propuesto

Entrada: design.md de una feature
Salida: validacion de las decisiones SOLID del diseno

```markdown
# SOLID Design Review: {Feature}

| Decision | Principio | Verdict | Notas |
|----------|-----------|---------|-------|
| {decision 1} | SRP | OK | |
| {decision 2} | OCP | WARN | {sugerencia} |

## Recommendations
- {Si hay WARNs o FAILs, que ajustar}
```

### verify — Verifica codigo vs diseno

Entrada: design.md + codigo implementado (diff o paths)
Salida: comparacion de lo disenado vs lo implementado

```markdown
# SOLID Verification: {Feature}

| Componente | Designed | Implemented | Match |
|-----------|----------|-------------|-------|
| {comp 1} | Strategy pattern | Strategy pattern | YES |
| {comp 2} | Interface segregation | God interface | NO |

## Mismatches
### {Componente con NO}
- **Disenado**: {que se planeo}
- **Implementado**: {que se hizo}
- **Impacto**: {consecuencias}
- **Accion**: {corregir o justificar}
```

## Principios SOLID — Referencia rapida

| Principio | Pregunta clave | Red flag |
|-----------|---------------|----------|
| **S**ingle Responsibility | Tiene mas de una razon para cambiar? | Clase >200 lineas, >5 metodos publicos |
| **O**pen/Closed | Hay que modificar existente para anadir nuevo? | switch/if-else creciente, modifying base class |
| **L**iskov Substitution | Los subtipos son intercambiables? | Override que cambia semantica, throws unexpected |
| **I**nterface Segregation | Clientes dependen de metodos que no usan? | Interface >5 metodos, implements con no-op |
| **D**ependency Inversion | Se depende de concreto en vez de abstracto? | new ConcreteClass() en logica, import de infra en domain |

Referencia completa: `core/solid-reference.md`
