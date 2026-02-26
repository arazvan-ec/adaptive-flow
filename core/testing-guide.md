# Testing Guide

Referencia compacta para TDD y estrategia de testing.
Se carga bajo demanda durante la fase de implementation.

## TDD Cycle

```
RED    → Escribir test que falla (captura comportamiento esperado)
GREEN  → Escribir minimo codigo para que pase
REFACTOR → Mejorar sin cambiar comportamiento
```

**Regla clave**: El test se escribe ANTES que el codigo. Nunca al reves.

## Piramide de Tests

```
        /  E2E  \          Pocos, lentos, fragiles
       / Integration \     Moderados, verifican conexiones
      /    Unit Tests  \   Muchos, rapidos, aislados
```

| Tipo | Que verifica | Cuando escribir |
|------|-------------|-----------------|
| **Unit** | Logica de negocio aislada | Siempre (cada funcion publica) |
| **Integration** | Conexiones entre modulos | Cuando hay DB, APIs, o servicios externos |
| **E2E** | Flujo completo del usuario | Solo para happy paths criticos |

## Que testear

- **Siempre**: Logica de negocio, validaciones, transformaciones, edge cases
- **A veces**: Integraciones, API contracts, DB queries
- **Nunca**: Implementacion interna, getters/setters triviales, libreria de terceros

## Que hace un buen test

1. **Independiente**: No depende de otros tests ni de estado global
2. **Determinista**: Mismo resultado cada vez (no flaky)
3. **Rapido**: <100ms para unit tests
4. **Descriptivo**: El nombre describe el comportamiento, no la implementacion
5. **Unico**: Testea UN comportamiento, no multiples

## Naming Convention

```
describe('{Subject}', () => {
  it('should {behavior} when {condition}', () => {
    // Arrange → Act → Assert
  });
});
```

Ejemplo: `it('should reject email without @ symbol when validating')`

## Arrange-Act-Assert (AAA)

```typescript
// Arrange: setup datos y dependencias
const user = createUser({ email: 'test@example.com' });

// Act: ejecutar la accion a testear
const result = validateEmail(user.email);

// Assert: verificar el resultado
expect(result.isValid).toBe(true);
```

## Test Doubles

| Tipo | Cuando usar |
|------|------------|
| **Stub** | Retornar datos predefinidos (DB, API) |
| **Mock** | Verificar que se llamo a algo (events, notifications) |
| **Spy** | Observar llamadas sin reemplazar implementacion |
| **Fake** | Implementacion simplificada (in-memory DB) |

Preferir stubs sobre mocks. Verificar estado sobre interaccion.

## BCP + Tests

Cuando un test falla durante BCP:
1. Leer el error con atencion
2. No cambiar el test (salvo que la spec haya cambiado)
3. Cambiar la implementacion para que pase
4. Si 3 intentos fallan → escalar con diagnostico
