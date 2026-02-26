# Flow: Direct (Gravedad 1)

Ejecucion directa para cambios triviales.

## Cuando

- ≤3 archivos afectados
- Cambio claro, sin ambiguedad
- Fix obvio, adicion simple, rename, typo

## Proceso

```
1. Cargar insights (solo influence: high, when_to_apply incluye "implementation")
2. Ejecutar el cambio directamente
3. Verificar: tests pasan, lint limpio
4. Commit
```

## Que NO hacer

- No crear spec ni design
- No spawneear planner worker
- No pedir confirmacion (salvo archivos de alto riesgo: auth, pagos, config)

## Insights aplicables

```yaml
filter:
  influence: high
  when_to_apply: [implementation]
```

Solo se aplican insights de alta influencia. No se cargan insights de planning ni review.

## Quality Gate

- Tests pasan (hook: pre-commit)
- Lint limpio (hook: pre-commit)

## Ejemplo

```
Usuario: "Anade campo email a UserDTO"
→ Gravedad 1 (1 archivo, cambio claro)
→ Cargar insights high de implementation
→ Anadir campo + test unitario
→ Verificar tests
→ Commit
```
