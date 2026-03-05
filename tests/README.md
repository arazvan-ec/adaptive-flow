# Tests — Adaptive Flow Plugin

## Estructura

```
tests/
├── hooks/          # Tests bats-core para los 5 hooks bash
├── validation/     # Scripts de validacion (skills, memory YAML)
└── README.md
```

## Requisitos

- [shellcheck](https://www.shellcheck.net/) — analisis estatico de bash
- [bats-core](https://github.com/bats-core/bats-core) — framework de tests para bash
- python3 + PyYAML — para validacion de YAML

## Ejecutar

```bash
# Shellcheck (analisis estatico)
shellcheck hooks/*.sh

# Tests bats (cuando esten creados)
bats tests/hooks/

# Validacion de skills
bash tests/validation/validate-skills.sh

# Validacion de memoria YAML
bash tests/validation/validate-memory.sh
```

## Convenciones

- Un archivo `.bats` por hook
- Mocks en funciones `setup()` / `teardown()` de cada test
- Tests verifican JSON output valido y contenido esperado
