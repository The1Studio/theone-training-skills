# Brainstorm Report: PR Review Skill Enhancement

**Date:** 2025-12-01
**Topic:** Comprehensive PR Review Skill for Claude Code

---

## Problem Statement

Create a dedicated PR-review skill that enables Claude to run comprehensive reviews with actionable suggestions developers can apply directly. Must NOT duplicate technology-specific skills (Unity, C#, React Native - already exist).

## Current State Analysis

### Existing Assets

| Asset | Purpose | Gap |
|-------|---------|-----|
| `github-pr-review` skill | GitHub API integration, suggestion syntax | Limited review logic, no comprehensive checklist |
| `code-review` skill | Review philosophy, verification gates | Process-focused, not PR-specific |
| `code-reviewer` agent | Executes reviews | General code quality, not PR workflow |
| `theone-unity-standards` | Unity/C# standards | Language-specific (correct separation) |

### Key Insight

**You already have `github-pr-review` skill!** But it focuses on GitHub API mechanics (how to post suggestions) rather than comprehensive review methodology (what to look for).

## Evaluated Approaches

### Approach 1: Enhance Existing `github-pr-review` Skill

**Pros:**
- No skill proliferation
- Single source of truth for PR reviews
- Already has API integration

**Cons:**
- Skill becomes too large
- Mixes API mechanics with review methodology
- Hard to maintain

**Verdict:** ❌ Violates KISS - mixing concerns

---

### Approach 2: Create New `pr-review` Skill (Pure Review Methodology)

**Concept:** Comprehensive review checklist/methodology that works WITH other skills.

**Structure:**
```
.claude/skills/pr-review/
├── SKILL.md                    # Main skill doc
├── references/
│   ├── review-checklist.md     # Comprehensive what-to-check
│   ├── severity-classification.md
│   ├── review-workflow.md      # Step-by-step process
│   └── approval-criteria.md    # When to approve/request changes
```

**Pros:**
- Clean separation: methodology vs API mechanics
- Composable with technology-specific skills
- Single responsibility

**Cons:**
- Another skill to maintain
- Potential overlap with `code-review` skill

**Verdict:** ⚠️ Close, but review overlap with `code-review`

---

### Approach 3: Merge `code-review` + `github-pr-review` into Enhanced `pr-review` ⭐

**Concept:** Single comprehensive skill that covers:
1. Review methodology (from `code-review`)
2. GitHub PR mechanics (from `github-pr-review`)
3. Approval/request-changes decision logic (NEW)
4. Technology-agnostic checklists (NEW)

**Structure:**
```
.claude/skills/pr-review/
├── SKILL.md                    # Unified entry point
├── README.md                   # Extended docs
├── references/
│   ├── methodology/
│   │   ├── review-process.md       # Full workflow
│   │   ├── receiving-feedback.md   # From code-review
│   │   ├── verification-gates.md   # From code-review
│   │   └── approval-criteria.md    # NEW: when to approve
│   ├── checklists/
│   │   ├── security-checklist.md   # OWASP, secrets, etc.
│   │   ├── quality-checklist.md    # Code quality
│   │   ├── performance-checklist.md
│   │   ├── testing-checklist.md
│   │   └── documentation-checklist.md
│   └── github/
│       ├── api-reference.md        # From github-pr-review
│       ├── workflow-examples.md    # From github-pr-review
│       └── suggestion-syntax.md
```

**Pros:**
- Single source of truth for PR reviews
- Eliminates duplication between `code-review` and `github-pr-review`
- Clear separation from technology-specific skills
- Comprehensive approval/rejection logic

**Cons:**
- Migration effort
- Need to deprecate two skills

**Verdict:** ✅ RECOMMENDED - cleaner architecture

---

### Approach 4: Minimal Enhancement (Just Add Approval Logic)

**Concept:** Keep existing skills, just add `approval-criteria.md` to `github-pr-review`.

**Pros:**
- Minimal changes
- Quick to implement

**Cons:**
- Doesn't fix skill proliferation
- Leaves `code-review` and `github-pr-review` overlap

**Verdict:** ⚠️ Short-term fix, not long-term solution

---

## Final Recommendation: Approach 3 (Merged `pr-review` Skill)

### Rationale

1. **YAGNI:** We don't need 3 separate skills for review functionality
2. **DRY:** Eliminates duplication between `code-review` and `github-pr-review`
3. **KISS:** One skill to rule all PR reviews

### Implementation Architecture

```
pr-review/
├── SKILL.md                    # Trigger conditions, overview
├── references/
│   ├── 01-workflow.md          # Full review process
│   ├── 02-checklists/
│   │   ├── security.md         # OWASP Top 10, secrets detection
│   │   ├── quality.md          # Code smells, maintainability
│   │   ├── performance.md      # N+1, allocations, hot paths
│   │   ├── testing.md          # Coverage, edge cases
│   │   └── docs.md             # API docs, README updates
│   ├── 03-severity.md          # Critical/High/Medium/Low
│   ├── 04-approval-criteria.md # Decision tree for APPROVE/REQUEST_CHANGES
│   ├── 05-github-api.md        # API reference (from existing)
│   └── 06-suggestion-syntax.md # GitHub suggestion blocks
```

### Key Features

#### 1. Comprehensive Review Checklist (Technology-Agnostic)

```markdown
## Security
- [ ] No hardcoded secrets/credentials
- [ ] Input validation on all boundaries
- [ ] SQL/NoSQL injection prevention
- [ ] XSS prevention (output encoding)
- [ ] CSRF tokens on state-changing operations
- [ ] Auth/authz checks present
- [ ] Sensitive data not logged

## Quality
- [ ] Single responsibility principle
- [ ] No code duplication
- [ ] Error handling present
- [ ] Edge cases covered
- [ ] Consistent naming conventions
- [ ] No dead code

## Performance
- [ ] No N+1 queries
- [ ] Appropriate caching
- [ ] No memory leaks
- [ ] Async operations where appropriate

## Testing
- [ ] Unit tests for new logic
- [ ] Integration tests for APIs
- [ ] Edge cases tested
- [ ] Test coverage maintained

## Documentation
- [ ] API changes documented
- [ ] Breaking changes noted
- [ ] README updated if needed
```

#### 2. Approval Decision Tree (NEW - Critical Missing Feature)

```
START
  │
  ├─ Has CRITICAL issues (security, data loss)?
  │    YES → REQUEST_CHANGES + block merge
  │    NO  → continue
  │
  ├─ Has HIGH issues (breaking changes, missing tests)?
  │    YES → REQUEST_CHANGES
  │    NO  → continue
  │
  ├─ Has MEDIUM issues (code quality)?
  │    YES → COMMENT (allow merge with fixes)
  │    NO  → continue
  │
  └─ Only LOW issues or none?
       YES → APPROVE
```

#### 3. GitHub API Integration

```bash
# Approve PR
gh pr review $PR_NUMBER --repo $REPO --approve --body "LGTM! ..."

# Request changes
gh pr review $PR_NUMBER --repo $REPO --request-changes --body "..."

# Comment only (for medium issues)
gh pr review $PR_NUMBER --repo $REPO --comment --body "..."
```

#### 4. Integration with Technology Skills

```
PR Review triggers:
  1. pr-review skill (methodology + GitHub API)
  2. IF Unity/C# → theone-unity-standards (tech-specific rules)
  3. IF React Native → theone-react-native-standards
  4. IF Cocos → theone-cocos-standards

Review output combines ALL findings.
```

### Migration Path

1. Create new `pr-review` skill with merged content
2. Update `github-pr-review/SKILL.md` to redirect: "Use `pr-review` skill instead"
3. Update `code-review/SKILL.md` to focus on "receiving feedback" only (or merge entirely)
4. Update `code-reviewer` agent to use new `pr-review` skill

### Success Metrics

- [ ] Single skill handles all PR review needs
- [ ] Clear approval/rejection criteria documented
- [ ] Technology-agnostic (works with any language)
- [ ] Integrates with GitHub API for suggestions AND review decisions
- [ ] Doesn't duplicate technology-specific skills

---

## Implementation Considerations

### Must Have
1. Approval decision tree (APPROVE vs REQUEST_CHANGES)
2. Security checklist (OWASP Top 10)
3. Quality checklist (language-agnostic)
4. GitHub API integration for review submission

### Nice to Have
1. Auto-detection of file types to trigger tech-specific skills
2. Batch suggestion optimization
3. Review templates per PR type (feature, bugfix, refactor)

### Risks
1. **Skill size:** Merged skill might be too large → mitigate with modular references
2. **Migration:** Breaking existing workflows → provide redirect in deprecated skills

---

## Next Steps

1. **Create skill structure** with new `pr-review/` directory
2. **Migrate content** from `github-pr-review` and `code-review`
3. **Add approval criteria** (decision tree)
4. **Add comprehensive checklists** (security, quality, performance, testing)
5. **Test with real PRs** to validate workflow
6. **Deprecate** old skills with redirects

---

## Unresolved Questions

1. Should `code-review` skill remain for "receiving feedback" scenarios, or fully merge?
2. What's the preferred severity threshold for auto-approval (e.g., allow MEDIUM issues)?
3. Should the skill auto-detect repo language and trigger appropriate tech skill?

---

## Sources

- [GitHub Copilot Code Review](https://github.blog/changelog/2024-10-29-github-copilot-code-review-in-github-com-private-preview/)
- [AI Code Review Action - GitHub Marketplace](https://github.com/marketplace/actions/ai-code-review-action)
- [Graphite AI Code Review](https://graphite.dev/guides/ai-code-review-on-github)
- [Best GitHub AI Code Review Tools](https://www.codeant.ai/blogs/best-github-ai-code-review-tools-2025)
- [Copilot Code Review Instructions](https://github.blog/ai-and-ml/unlocking-the-full-power-of-copilot-code-review-master-your-instructions-files/)
