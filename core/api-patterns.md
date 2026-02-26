# API Patterns Guide

Referencia compacta de patrones de arquitectura API.
Se carga bajo demanda cuando la tarea involucra disenar o modificar APIs.

## REST Conventions

### URL Structure

```
GET    /resources          → List (with pagination)
GET    /resources/:id      → Get one
POST   /resources          → Create
PUT    /resources/:id      → Full update
PATCH  /resources/:id      → Partial update
DELETE /resources/:id      → Delete
```

### Status Codes

| Code | Cuando |
|------|--------|
| 200 | OK (con body) |
| 201 | Created (POST exitoso) |
| 204 | No Content (DELETE exitoso) |
| 400 | Bad Request (input invalido) |
| 401 | Unauthorized (no autenticado) |
| 403 | Forbidden (no autorizado) |
| 404 | Not Found |
| 409 | Conflict (duplicado, race condition) |
| 422 | Unprocessable Entity (validacion de negocio) |
| 500 | Internal Server Error |

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  }
}
```

## Pagination

### Cursor-based (preferido)

```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "abc123",
    "has_more": true
  }
}
```

### Offset-based (simple)

```
GET /resources?page=2&per_page=20
```

```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

## API Architecture Patterns

### Layered Architecture

```
Controller → Service → Repository → Database
   (HTTP)    (Logic)   (Data Access)  (Storage)
```

- Controller: routing, input validation, response formatting
- Service: business logic, orchestration
- Repository: data access abstraction

### DTO Pattern

```
Request DTO → Validate → Domain Model → Process → Response DTO
```

Nunca exponer domain models directamente en la API.

### API Versioning

Prefijo de URL (simple y explicito):
```
/api/v1/resources
/api/v2/resources
```

### Rate Limiting

Headers estandar:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
Retry-After: 60
```

## Contract Testing

Cuando multiples servicios dependen de una API:

1. Definir contrato (OpenAPI/Swagger)
2. Test del producer: "mi API cumple el contrato"
3. Test del consumer: "uso la API segun el contrato"
4. CI verifica que no hay breaking changes

## Design Decisions Checklist

Al disenar una API nueva:

- [ ] Recursos identificados (sustantivos, no verbos)
- [ ] Relaciones entre recursos claras
- [ ] Paginacion definida
- [ ] Error format consistente
- [ ] Autenticacion/autorizacion definida
- [ ] Rate limiting considerado
- [ ] Versionado definido (si es publica)
