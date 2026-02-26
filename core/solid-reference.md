# SOLID Reference Guide

Referencia compacta de principios SOLID para el planner y reviewer workers.
Se carga bajo demanda durante las fases de design y review.

## Single Responsibility Principle (SRP)

**Regla**: Una clase/modulo debe tener una sola razon para cambiar.

**Aplicacion practica**:
- Separar logica de negocio de infra (DB, HTTP, filesystem)
- Un servicio por dominio, no God services
- Controllers: solo routing + validation. No logica de negocio.

**Red flags**:
- Clase >200 lineas
- >5 metodos publicos
- Nombre con "And" o "Manager" (UserAndOrderManager)
- Imports de 3+ capas diferentes

**Pattern**: Extract Class, Move Method

## Open/Closed Principle (OCP)

**Regla**: Abierto para extension, cerrado para modificacion.

**Aplicacion practica**:
- Strategy pattern para variantes de comportamiento
- Plugin architecture para extensibilidad
- Event-driven para reaccionar sin modificar

**Red flags**:
- switch/case o if-else creciente para tipos
- Modificar clase base cada vez que se anade un caso
- Feature flags dentro de logica de negocio

**Pattern**: Strategy, Template Method, Observer

## Liskov Substitution Principle (LSP)

**Regla**: Los subtipos deben ser intercambiables sin alterar la correccion.

**Aplicacion practica**:
- Si hereda, debe cumplir el contrato completo
- No override con semantica diferente
- Preferir composicion sobre herencia

**Red flags**:
- Override que lanza NotImplementedError
- Subtipo que ignora parametros del padre
- instanceof/typeof checks despues de polimorfismo

**Pattern**: Composition over Inheritance, Interface extraction

## Interface Segregation Principle (ISP)

**Regla**: Los clientes no deben depender de interfaces que no usan.

**Aplicacion practica**:
- Interfaces pequenas y cohesivas (3-5 metodos max)
- Multiples interfaces especificas > una general
- En TS/JS: tipos parciales con Pick/Omit

**Red flags**:
- Interface >5 metodos
- Implementaciones con metodos no-op
- Parametros opcionales que siempre son undefined

**Pattern**: Role Interface, Interface Segregation

## Dependency Inversion Principle (DIP)

**Regla**: Depender de abstracciones, no de implementaciones concretas.

**Aplicacion practica**:
- Inyeccion de dependencias (constructor injection preferido)
- Domain no importa infra directamente
- Repositories como abstraccion de persistencia

**Red flags**:
- `new ConcreteService()` en logica de negocio
- Import de modulo de infra en domain layer
- Hardcoded URLs, connection strings en logica

**Pattern**: Dependency Injection, Repository, Port/Adapter

## Scoring

Cada componente se evalua por principio:

| Score | Significado |
|-------|------------|
| **OK** | Cumple el principio |
| **WARN** | Mejorable pero funcional |
| **FAIL** | Viola el principio, requiere correccion |
