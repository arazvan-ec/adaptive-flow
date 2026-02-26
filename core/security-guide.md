# Security Guide

Referencia compacta de patrones de seguridad.
Se carga bajo demanda durante review o cuando la tarea involucra auth/pagos.

## OWASP Top 10 — Quick Reference

| # | Vulnerabilidad | Prevencion |
|---|---------------|-----------|
| 1 | Broken Access Control | Verificar authz en cada endpoint. Deny by default. |
| 2 | Cryptographic Failures | TLS everywhere. No secrets en codigo. bcrypt/argon2 para passwords. |
| 3 | Injection | Parametrized queries. Validar input. No eval(). |
| 4 | Insecure Design | Threat model en design phase. Trust boundaries claros. |
| 5 | Security Misconfiguration | Defaults seguros. No debug en prod. Headers de seguridad. |
| 6 | Vulnerable Components | Dependencias actualizadas. Audit regular. |
| 7 | Auth Failures | MFA. Rate limiting. Session management seguro. |
| 8 | Data Integrity Failures | Verificar firma de datos. CI/CD seguro. |
| 9 | Logging Failures | Log eventos de seguridad. No log secrets. |
| 10 | SSRF | Whitelist URLs. No fetch de input del usuario sin validar. |

## Checklist por tipo de cambio

### API Endpoint

- [ ] Autenticacion requerida (o explicitamente publico)
- [ ] Autorizacion verificada (role/permission check)
- [ ] Input validado (schema validation en boundary)
- [ ] Output sanitizado (no leak de datos internos)
- [ ] Rate limiting configurado
- [ ] Logging de acceso

### Base de Datos

- [ ] Queries parametrizadas (no string concatenation)
- [ ] Minimo privilegio en DB user
- [ ] Datos sensibles encriptados at rest
- [ ] No PII en logs

### Autenticacion

- [ ] Passwords con bcrypt/argon2 (cost factor >= 10)
- [ ] Tokens con expiracion
- [ ] Refresh token rotation
- [ ] Session invalidation on logout
- [ ] Brute force protection

### File Upload

- [ ] Validar tipo MIME (no solo extension)
- [ ] Limitar tamano
- [ ] No ejecutar archivos subidos
- [ ] Almacenar fuera del webroot

## Patrones Seguros

### Validacion en Boundaries

```
Entrada (HTTP/CLI/Event)
  → Validar schema (zod, joi, etc.)
  → Convertir a tipo interno (DTO → Domain)
  → Procesar con tipos seguros
  → Serializar para salida
```

Validar en la frontera, confiar internamente.

### Secrets Management

- Variables de entorno para secrets (no hardcoded)
- .env en .gitignore (siempre)
- Diferentes secrets per environment
- Rotacion periodica

### Trust Boundaries

```
Internet → [Firewall] → API Gateway → [Auth] → Service → [Authz] → Data
          untrusted        boundary      trusted      boundary    trusted
```

Cada cruce de boundary requiere validacion.
