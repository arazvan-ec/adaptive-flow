# D4: Prompt Hooks Evaluation for pre-write-guard

**Date**: 2026-03-06
**Decision**: Keep pattern matching for v3, evaluate prompt hooks for v4

## Current Approach: Pattern Matching (pre-write-guard.sh)

**How it works**: Shell script with regex pattern matching on file paths.
Detects auth/security, API, and test file patterns → suggests core guides.

**Pros**:
- Deterministic: same file always triggers same suggestion
- Fast: no token cost, no latency
- Debuggable: grep patterns easy to test
- No false positives from ambiguous naming

**Cons**:
- Brittle: new patterns require manual addition
- Can't understand intent/context (writing auth code vs reading auth config)
- Limited to file path matching (can't inspect file content)

## Alternative: Prompt Hooks (Semantic Evaluation)

**How it would work**: Claude evaluates whether the file being written contains security-sensitive code, API contracts, etc.

**Pros**:
- Understands context and intent
- Can detect subtle issues (e.g., hardcoded secrets in non-obvious files)
- Adapts automatically to new patterns

**Cons**:
- Token cost on every Write/Edit operation (high frequency hook)
- Latency added to every file write
- Non-deterministic: may produce different results for same input
- Harder to debug and test
- Overkill for simple file-path-based routing

## Recommendation

**v3: Keep pattern matching**. The current approach is fast, free, and deterministic. The file path patterns cover >90% of cases for guide suggestions.

**v4 consideration**: Prompt hooks would be valuable for a "content-aware guard" that inspects file contents for:
- Hardcoded secrets in arbitrary files
- SQL injection patterns
- Insecure crypto usage

This is a separate, higher-value use case than guide suggestions.
