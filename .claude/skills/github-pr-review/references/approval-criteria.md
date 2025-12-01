# PR Approval Decision Criteria

## Decision Tree

```
START: Review Complete
  │
  ├─ Has CRITICAL issues?
  │   (security vulnerabilities, data loss risk, breaking production)
  │    │
  │    YES → REQUEST_CHANGES + Block Merge
  │    │     Message: "🔴 CRITICAL issues found. Must fix before merge."
  │    │
  │    NO  → Continue
  │
  ├─ Has HIGH issues?
  │   (breaking changes, missing tests for new logic, major bugs)
  │    │
  │    YES → REQUEST_CHANGES
  │    │     Message: "🟠 Important issues require attention."
  │    │
  │    NO  → Continue
  │
  ├─ Has MEDIUM issues?
  │   (code quality, minor bugs, missing docs)
  │    │
  │    YES → COMMENT (allow merge, suggest fixes)
  │    │     Message: "🟡 Suggestions for improvement. Can merge after addressing."
  │    │
  │    NO  → Continue
  │
  └─ Only LOW issues or none?
     (style, minor refactoring suggestions)
      │
      YES → APPROVE
            Message: "✅ LGTM! [Optional minor suggestions]"
```

## Severity Classification

### 🔴 CRITICAL (Block Merge)

**Security:**
- Hardcoded secrets/credentials
- SQL/NoSQL injection vulnerability
- XSS vulnerability (unescaped output)
- Auth bypass possible
- Sensitive data exposed in logs
- Missing input validation on public endpoints

**Stability:**
- Null pointer exceptions in critical paths
- Unhandled exceptions that crash app
- Data corruption risk
- Memory leaks in hot paths
- Race conditions in concurrent code

**Breaking:**
- API contract broken without version bump
- Database schema change without migration
- Removal of public interface without deprecation

### 🟠 HIGH (Request Changes)

**Testing:**
- New feature without tests
- Deleted tests without replacement
- Test coverage dropped significantly
- Tests don't cover edge cases

**Quality:**
- Obvious logic bugs
- Missing error handling
- N+1 query patterns
- Significant code duplication
- Breaking SOLID principles badly

**Documentation:**
- Breaking API change without docs update
- New public API without docs

### 🟡 MEDIUM (Comment)

**Quality:**
- Code smells (long methods, god classes)
- Minor code duplication
- Could use better abstractions
- Inconsistent naming
- Missing optional validation

**Performance:**
- Suboptimal but working algorithm
- Could benefit from caching
- Unnecessary allocations (non-hot path)

**Documentation:**
- Missing inline docs for complex logic
- README could use update

### 🟢 LOW (Approve with Suggestions)

**Style:**
- Formatting inconsistencies
- Could use more descriptive names
- Verbose code could be simplified
- Could use modern language features

**Suggestions:**
- Minor refactoring opportunities
- Optional improvements

## GitHub Commands

### Approve PR

```bash
gh pr review $PR_NUMBER --repo $REPO --approve --body "$(cat <<'EOF'
## ✅ Approved

LGTM! Code looks good.

### Minor Suggestions (optional)
- Consider renaming `x` to `userId` for clarity
- Line 45: could use optional chaining
EOF
)"
```

### Request Changes

```bash
gh pr review $PR_NUMBER --repo $REPO --request-changes --body "$(cat <<'EOF'
## 🔴 Changes Required

### Critical Issues
1. **Security:** Hardcoded API key at line 23
2. **Bug:** Null check missing at line 45

### How to Fix
See inline suggestions on Files Changed tab.

After fixing, request re-review.
EOF
)"
```

### Comment Only (Medium Issues)

```bash
gh pr review $PR_NUMBER --repo $REPO --comment --body "$(cat <<'EOF'
## 🟡 Review Complete

No blocking issues. A few suggestions for improvement.

### Suggestions
1. Consider extracting method at line 30-50
2. Could add error logging at line 67

You can merge and address these in follow-up, or fix now.
EOF
)"
```

## Review Summary Template

```markdown
## PR Review Summary

**Decision:** [APPROVE / REQUEST_CHANGES / COMMENT]

### Issues by Severity

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 Critical | 0 | - |
| 🟠 High | 0 | - |
| 🟡 Medium | 2 | Suggested |
| 🟢 Low | 1 | Optional |

### Critical Issues
[None / List]

### High Priority
[None / List]

### Suggestions
- [List medium/low priority items]

### Next Steps
- [ ] Address critical/high issues
- [ ] Re-request review when ready
```

## Edge Cases

### Conflicting with Tech-Specific Standards

If issue conflicts with tech-specific skill (e.g., `theone-unity-standards`):
1. Tech-specific skill takes precedence
2. Reference the specific standard
3. Mark as appropriate severity per that standard

### Reviewer Disagreement

If tech-specific review and general review conflict:
1. General security issues always take precedence
2. Tech-specific patterns win for architecture
3. Escalate to human if unclear

### Partial Fix Acceptable

Some HIGH issues can be marked as MEDIUM if:
- Author commits to follow-up PR
- Issue is tracked in ticket system
- Doesn't affect current feature scope

Document in review: "Approving with follow-up required for [issue]"
