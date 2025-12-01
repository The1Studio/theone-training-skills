# Comprehensive PR Review Checklists

Technology-agnostic checklists. Use WITH tech-specific skills for complete review.

## Quick Review Order

1. **Security** (blocks merge if failed)
2. **Correctness** (blocks merge if failed)
3. **Testing** (usually blocks merge)
4. **Quality** (suggestions)
5. **Performance** (context-dependent)
6. **Documentation** (usually suggestions)

---

## 🔒 Security Checklist

### Secrets & Credentials
- [ ] No hardcoded API keys, passwords, tokens
- [ ] No secrets in logs or error messages
- [ ] .env files not committed
- [ ] Secrets accessed via environment variables

### Input Validation
- [ ] All user input validated
- [ ] Input sanitized before use
- [ ] File uploads restricted (type, size)
- [ ] Path traversal prevented

### Injection Prevention
- [ ] SQL: Parameterized queries only
- [ ] NoSQL: Query operators sanitized
- [ ] XSS: Output encoded/escaped
- [ ] Command injection: No shell with user input
- [ ] Template injection: Safe templating

### Authentication & Authorization
- [ ] Auth checks on protected routes
- [ ] Role/permission checks present
- [ ] Session management secure
- [ ] Password handling proper (hashing, not logging)

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced for sensitive operations
- [ ] PII handling compliant
- [ ] Proper data retention

---

## ✅ Correctness Checklist

### Logic
- [ ] Business logic matches requirements
- [ ] Edge cases handled
- [ ] Null/undefined checks present
- [ ] Error paths handled
- [ ] Return values correct

### State Management
- [ ] State transitions valid
- [ ] Race conditions prevented
- [ ] Concurrent access safe
- [ ] Cleanup on error/exit

### Data Integrity
- [ ] Database transactions where needed
- [ ] Rollback on failure
- [ ] Data validation before persist
- [ ] Referential integrity maintained

### API Contracts
- [ ] Request validation present
- [ ] Response format consistent
- [ ] Error responses informative
- [ ] Status codes appropriate

---

## 🧪 Testing Checklist

### Coverage
- [ ] New code has tests
- [ ] Modified code tests updated
- [ ] Edge cases tested
- [ ] Error paths tested

### Quality
- [ ] Tests actually assert behavior
- [ ] Tests isolated (no shared state)
- [ ] Tests deterministic (no flaky)
- [ ] Test names descriptive

### Types
- [ ] Unit tests for logic
- [ ] Integration tests for boundaries
- [ ] E2E for critical paths (if applicable)

### Regression
- [ ] Bug fix has regression test
- [ ] Test fails without fix (red-green)

---

## 🧹 Code Quality Checklist

### Structure
- [ ] Single responsibility followed
- [ ] Functions reasonably sized (<30 lines)
- [ ] Nesting depth reasonable (<4 levels)
- [ ] No god classes/functions

### Maintainability
- [ ] Code self-documenting
- [ ] No magic numbers/strings
- [ ] No dead code
- [ ] No commented-out code

### Patterns
- [ ] Consistent with codebase style
- [ ] No reinventing existing utilities
- [ ] Proper abstraction level
- [ ] Dependencies injected (not hardcoded)

### Naming
- [ ] Variables descriptive
- [ ] Functions describe action
- [ ] Consistent naming convention
- [ ] No abbreviations (except common: id, url, etc.)

### DRY
- [ ] No copy-paste code
- [ ] Shared logic extracted
- [ ] Constants defined once

---

## ⚡ Performance Checklist

### Database
- [ ] No N+1 queries
- [ ] Proper indexes for queries
- [ ] Queries not fetching unnecessary data
- [ ] Batch operations where appropriate

### Memory
- [ ] No memory leaks (listeners, subscriptions)
- [ ] Large objects disposed properly
- [ ] Streaming for large data
- [ ] Caching appropriate

### Computation
- [ ] No expensive operations in loops
- [ ] Async for I/O operations
- [ ] No blocking main thread
- [ ] Appropriate data structures

### Network
- [ ] Minimal API calls
- [ ] Batching requests where possible
- [ ] Proper caching headers
- [ ] Pagination for large datasets

---

## 📚 Documentation Checklist

### Code Documentation
- [ ] Complex logic explained
- [ ] Public APIs documented
- [ ] Non-obvious decisions commented
- [ ] TODO items have ticket references

### External Documentation
- [ ] README updated if needed
- [ ] API docs updated for changes
- [ ] Breaking changes documented
- [ ] Migration guide if needed

### Changelog
- [ ] User-facing changes noted
- [ ] Breaking changes highlighted
- [ ] Version bump appropriate

---

## Integration with Tech-Specific Skills

After general checklist, apply tech-specific:

| Technology | Skill | Focus |
|------------|-------|-------|
| Unity/C# | `theone-unity-standards` | VContainer, SignalBus, nullable, logging |
| React Native | `theone-react-native-standards` | Hooks, navigation, state |
| Cocos | `theone-cocos-standards` | Component lifecycle, assets |
| General TypeScript | `frontend-development` | Types, patterns |
| Backend | `backend-development` | API patterns, DB |

**Workflow:**
1. Run general checklist (this file)
2. Detect primary technology from PR files
3. Apply tech-specific skill checklist
4. Combine findings into single review

---

## Checklist Application

### For Small PRs (<50 lines)
Focus on: Security, Correctness, Testing

### For Medium PRs (50-300 lines)
Full checklist, but prioritize by file type

### For Large PRs (>300 lines)
- Request split if possible
- If can't split: focus on public interfaces first
- Flag areas needing deeper review

### For Refactoring PRs
Focus on: Testing (before/after), Quality, Performance (no regression)

### For Bug Fix PRs
Focus on: Correctness, Testing (regression test), Root cause addressed
